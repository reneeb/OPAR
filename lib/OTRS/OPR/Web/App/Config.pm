package OTRS::OPR::Web::App::Config;

use strict;
use warnings;

use Carp;
use YAML::Tiny;

our $VERSION = 0.01;

sub new{
    my ($class,$file) = @_;
    
    my $self = {};
    bless $self,$class;
    
    $self->load( $file );
    return $self;
}

sub load{
    my ($self,$file) = @_;
    
    croak "no config file given" unless defined $file;
    
    my $yaml = YAML::Tiny->read( $file ) || [];
    $self->{_config} = $yaml->[0] || {};
    
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

}

1;
