package OTRS::OPM::Analyzer;

use Moose;
use Moose::Util::TypeConstraints;

use OTRS::OPM::Analyzer::Utils::OPMFile;
use OTRS::OPM::Analyzer::Utils::Config;


# define types
subtype 'OPMFile' =>
  as 'Object' =>
  where { $_->isa( 'OTRS::OPM::Analyzer::Utils::OPMFile' ) };

# declare attributes
has opm => (
    is  => 'rw',
    isa => 'OPMFile',
);

has configfile => (
    is  => 'ro',
    isa => 'Str',
);

has roles => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef]',
    default => sub {
        +{
            file => [qw/
                SystemCall
                PerlCritic
                TemplateCheck
                BasicXMLCheck
                PerlTidy
            /],
            opm  => [qw/
                UnitTests
                Documentation
                Dependencies
                License
            /],
        };
    },
    auto_deref => 1,
);

sub load_roles {
    my ($self) = @_;
    
    my %roles = $self->roles;
    
    for my $area ( keys %roles ) {
        for my $role ( @{ $roles{$area} } ) {
            with __PACKAGE__ . '::Role::' . $role;
        }
    }
}

sub analyze {
    my ($self,$opm) = @_;
    
    $self->load_roles;
    
    my $opm_object = OTRS::OPM::Analyzer::Utils::OPMFile->new(
        opm_file => $opm,
    );
    my $success    = $opm_object->parse;
    
    return if !$success;
    
    $self->opm( $opm_object );
    
    my %analysis_data;
    
    # do all the checks that are based on the content of files
    my %roles   = $self->roles;
    my $counter = 1;
    
    for my $file ( $opm_object->files ) {
        
        ROLE:
        for my $role ( @{ $roles{file} || [] } ) {
            my ($sub) = $self->can( 'analyze_' . lc $role );
            next ROLE if !$sub;
            
            my $result   = $self->$sub( $file );
            my $filename = $file->{filename};
            
            $analysis_data{$role}->{$filename} = $result;
        }
        #last if $counter++ == 4;
    }
    
    # do the opm check - some checks have to be performed on the opm itself
    # as these checks are no checks of the content
    ROLE:
    for my $role ( @{ $roles{opm} || [] } ) {
        my ($sub) = $self->can( 'analyze_' . lc $role );
        next ROLE if !$sub;
        
        my $result   = $self->$sub( $opm_object );
        $analysis_data{$role} = $result;
    }
    
    # return analysis data
    return \%analysis_data;
}

sub config {
    my ($self) = @_;
    
    if ( !$self->{__config} ) {
        $self->{__config} = OTRS::OPM::Analyzer::Utils::Config->new(
            $self->configfile,
        );
    }
    
    return $self->{__config};
}

no Moose;

1;
