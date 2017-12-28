#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 4;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;

my $error;

eval {
    require OTRS::OPR::Web::App::Config;
    1;
} or $error = $@;

SKIP: {
    skip 'error while loading config module', 4 if $error;
    
    my $configfile = File::Spec->catfile( $dir, 'tests.yml' );
    my $config     = OTRS::OPR::Web::App::Config->new( $configfile );
    
    my $config_hash = $config->get('');
    
    ok ref $config_hash eq 'HASH', 'get a hashreference';
    ok keys %{$config_hash} == 3, 'hash has two keys';
    ok $config_hash->{db}->{file} eq 'test', 'check db filename';
    ok $config->get( 'db.file' ) eq 'test', 'check get( "file" )';
}