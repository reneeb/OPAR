package OTRS::OPM::Analyzer::Utils::OPMFile;

use Moose;
use Moose::Util::TypeConstraints;

use MIME::Base64 ();
use Path::Class;
use Try::Tiny;
use XML::LibXML;

# define types
subtype 'VersionString' =>
  as 'Str' =>
  where { $_ =~ m{ \A (?:[0-9]+) (?:\.[0-9]+){1,2} \z }xms };

subtype 'FrameworkVersionString' =>
  as 'Str' =>
  where { $_ =~ m{ \A (?:[0-9]+\.){2} (?:[0-9]+|x) \z }xms };

# declare attributes
has name         => ( is  => 'rw', isa => 'Str', );
has framework    => ( is  => 'rw', isa => 'FrameworkVersionString', );
has version      => ( is  => 'rw', isa => 'VersionString', );
has vendor       => ( is  => 'rw', isa => 'Str', );
has url          => ( is  => 'rw', isa => 'Str', );
has license      => ( is  => 'rw', isa => 'Str', );
has description  => ( is  => 'rw', isa => 'Str', );
has error_string => ( is  => 'rw', isa => 'Str', );

has opm_file => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has files => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[HashRef]',
    auto_deref => 1,
    default    => sub{ [] },
    handles    => {
        add_file => 'push',
    },
);

has dependencies => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[HashRef[Str]]',
    auto_deref => 1,
    default    => sub { [] },
    handles    => {
        add_dependency => 'push',
    },
);

sub documentation {
    my ($self,%params) = @_;
    
    my $doc_file;
    my $found_file;
    
    for my $file ( $self->files ) {
        my $filename = $file->{filename};
        next if $filename !~ m{ \A doc/ }x;
        
        if ( !$doc_file ) {
            $doc_file   = $file;
            $found_file = $filename;
        }
        
        my $lang = $params{lang} || '';
        next if $lang && $filename !~ m{ \A doc/$lang/ }x;
        
        if ( $lang && $found_file !~ m{ \A doc/$lang/ }x ) {
            $doc_file   = $file;
            $found_file = $filename;
        }
        
        my $type = $params{type} || '';
        next if $type && $filename !~ m{ \A doc/[^/]+/.*\.$type \z }x;
        
        if ( $type && $found_file !~ m{ \A doc/$lang/ }x ) {
            $doc_file   = $file;
            $found_file = $filename;
            
            if ( !$lang || ( $lang && $found_file !~ m{ \A doc/$lang/ }x ) ) {                
                last;
            }
        }
    }
    
    return $doc_file;
}

sub parse {
    my ($self) = @_;
    
    if ( !-e $self->opm_file ) {
        $self->error_string( 'File does not exist' );
        return;
    }
    
    my $parser = XML::LibXML->new;
    my $tree   = $parser->parse_file( $self->opm_file );
    
    # check if the opm file is valid.
    #try {
    #    my $xsd = do{ local $/; <DATA> };
    #    XML::LibXML::Schema->new( string => $xsd )
    #}
    #catch {
    #    $self->error_string( 'Could not validate against XML schema: ' . $_ );
    #    return;
    #};
    
    my $root = $tree->getDocumentElement;
    
    # collect basic data
    $self->vendor(    $root->findvalue( 'Vendor' ) );
    $self->name(      $root->findvalue( 'Name' ) );
    $self->license(   $root->findvalue( 'License' ) );
    $self->framework( $root->findvalue( 'Framework' ) );
    $self->version(   $root->findvalue( 'Version' ) );
    $self->url(       $root->findvalue( 'URL' ) );
    
    # retrieve file information
    my @files = $root->findnodes( 'Filelist/File' );
    
    FILE:
    for my $file ( @files ) {
        my $name = $file->findvalue( '@Location' );
        
        #next FILE if $name !~ m{ \. (?:pl|pm|pod|t) \z }xms;
        my $encode         = $file->findvalue( '@Encode' );
        next FILE if $encode ne 'Base64';
        
        my $content_base64 = $file->textContent;
        my $content        = MIME::Base64::decode( $content_base64 );
        
        # push file info to attribute
        $self->add_file({
            filename => $name,
            content  => $content,
        });
    }
    
    # get description - english if available, any other language otherwise
    my @descriptions = $root->findnodes( 'Description' );
    my $description_string;
    
    DESCRIPTION:
    for my $description ( @descriptions ) {
        $description_string = $description->textContent;
        my $language        = $description->findvalue( '@Lang' );
        
        last DESCRIPTION if $language eq 'en';
    }
    
    $self->description( $description_string );
    
    # get OTRS and CPAN dependencies
    my @otrs_deps = $root->findnodes( 'PackageRequired' );
    my @cpan_deps = $root->findnodes( 'ModuleRequired' );
    
    my %types     = (
        PackageRequired => 'OTRS',
        ModuleRequired  => 'CPAN',
    );
    
    for my $dep ( @otrs_deps, @cpan_deps ) {
        my $node_type = $dep->nodeName;
        my $version   = $dep->findvalue( '@Version' );
        my $dep_name  = $dep->textContent;
        my $dep_type  = $types{$node_type};
        
        $self->add_dependency({
            type    => $dep_type,
            version => $version,
            name    => $dep_name,
        });
    }
    
    return 1;
}

no Moose;

1;

__DATA__
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
    <xs:import namespace="http://www.w3.org/XML/1998/namespace"/>
    
    <xs:element name="otrs_package">
        <xs:complexType>
            <xs:attribute name="version" use="required" type="xs:anySimpleType"/>
            <xs:sequence>
                <xs:element ref="Name"/>
                <xs:element ref="Version"/>
                <xs:element ref="Framework"/>
                <xs:element ref="Vendor"/>
                <xs:element ref="URL"/>
                <xs:element ref="License"/>
                <xs:element ref="ChangeLog" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Description" maxOccurs="unbounded" />
                <xs:element ref="BuildHost" minOccurs="0" />
                <xs:element ref="BuildDate" minOccurs="0" />
                <xs:element ref="PackageRequired" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="ModuleRequired" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="OS" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="Filelist"/>
                <xs:element ref="DatabaseInstall" minOccurs="0" />
                <xs:element ref="DatabaseUpgrade" minOccurs="0" />
                <xs:element ref="DatabaseReinstall" minOccurs="0" />
                <xs:element ref="DatabaseUninstall" minOccurs="0" />
                <xs:element ref="CodeInstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeUpgrade" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeReinstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="CodeUninstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroInstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroUpgrade" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroReinstall" minOccurs="0" maxOccurs="unbounded" />
                <xs:element ref="IntroUninstall" minOccurs="0" maxOccurs="unbounded" />
            </xs:sequence>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="Filelist">
        <xs:complexType>
            <xs:sequence>
                <xs:element ref="File" maxOccurs="unbounded" />
            </xs:sequence>
        </xs:complexType>
    </xs:element>
    
    <xs:element name="PackageRequired">
    </xs:element>
    
    <xs:element name="Name" type="xs:token"/>
    <xs:element name="Vendor" type="xs:token"/>
    <xs:element name="URL" type="xs:token"/>
    <xs:element name="Framework" type="xs:token"/>
    <xs:element name="Version" type="xs:token"/>
    <xs:element name="License" type="xs:token"/>
    <xs:element name="OS" type="xs:token"/>
    <xs:element name="BuildDate" type="xs:token"/>
    <xs:element name="BuildHost" type="xs:token"/>
    
</xs:schema>