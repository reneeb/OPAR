package OTRS::OPR::App::Utils::Repo;

use strict;
use warnings;

use base 'Exporter';

use XML::LibXML;
use XML::LibXML::PrettyPrint;

our @EXPORT_OK = qw(create_index);

sub create_index {
    my ($opm_files, $paths) = @_;

    my $pp = XML::LibXML::PrettyPrint->new(
        indent_string => '  ',
        element       => {
            compact => [qw(
                Vendor Name Description Version Framework 
                ModuleRequired PackageRequired URL License
                File
            )],
        },
    );

    my @packages;
    for my $file ( @{$opm_files} ) {
        my $parser = XML::LibXML->new;
        my $tree   = $parser->parse_file( $file );
        $tree->setStandalone( 0 );

        my $root_elem = $tree->getDocumentElement;
        $root_elem->setNodeName( 'Package' );
        $root_elem->removeAttribute( 'version' );

        # retrieve file information
        my @files = $root_elem->findnodes( 'Filelist/File' );

        FILE:
        for my $file ( @files ) {
            my $location = $file->findvalue( '@Location' );

            # keep only documentation in file list
            if ( $location !~ m{\A doc/}x ) {
                $file->parentNode->removeChild( $file );
            }
            else {
                my @child_nodes = $file->childNodes;

                # clean nodes
                $file->removeChild( $_ ) for @child_nodes;
                $file->removeAttribute( 'Encode' );
                $file->setNodeName( 'FileDoc' );
            }
        }

        # remove unnecessary nodes
        for my $node_name ( qw(Code Intro Database)) {
            for my $phase ( qw(Install Upgrade Reinstall Uninstall) ) {
                my @nodes = $root_elem->findnodes( $node_name . $phase );
                $_->parentNode->removeChild( $_ ) for @nodes;
            }
        }

        for my $node_name ( qw(BuildHost BuildDate)) {
            my @nodes = $root_elem->findnodes( $node_name );
            $_->parentNode->removeChild( $_ ) for @nodes;
        }

        my $file_node  = XML::LibXML::Element->new( 'File' );
        (my $file_path = $paths->{$file}) =~ s!(/[A-Z]/[A-Z]{2}/[A-Z]{3}/.*)!$1!;
        $file_node->appendText( $file_path );
        $root_elem->addChild( $file_node );

        $pp->pretty_print( $tree );

        my $xml = $tree->toString;
        $xml =~ s{<\?xml .*? \?> \s+}{}x;

        push @packages, $xml;
    }

    my $index = sprintf qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package_list version="1.0">
%s
</otrs_package_list>
~, join "", @packages;

    return $index;
}

1;
