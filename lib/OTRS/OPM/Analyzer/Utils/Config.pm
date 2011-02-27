package OTRS::OPM::Analyzer::Utils::Config;

use strict;
use warnings;

use Carp;
use YAML::Tiny;
use File::Spec;
use File::Basename;

sub new{
    my ($class,$file) = @_;
    
    my $self = {};
    bless $self,$class;

    my $default_dir  = File::Spec->rel2abs( File::Basename::dirname( $0 ) );
    my $default_file = File::Spec->catfile( $default_dir,  'conf', 'base.yml' );
       $default_file = File::Spec->rel2abs( $default_file );
    
    $file ||= $default_file;
    $self->load( $file ) if defined $file;
    return $self;
}

sub load{
    my ($self,$file) = @_;
    croak "no config file given" unless defined $file;
    $self->{_config} = (YAML::Tiny->read( $file ) || [] )->[0] || {};
    return $self->{_config};
}

sub get {
    my ($self,$key) = @_;

    my $return;

    if( defined $key ){
        my $config = $self->{_config};

        my @keys = split /(?<!\\)\./, $key;
        for my $subkey ( @keys ){
            $subkey =~ s/\\\././g;
            return if not exists $config->{$subkey};
            $config = $config->{$subkey};
        }

        $return = $config;
    }

    $return;
}

1;
