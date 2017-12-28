#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 2;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;
use lib $dir;

my $error;

eval {
    require MyUnittests;
    MyUnittests->import();
    1;
} or $error = $@;

SKIP: {
    skip "error while loading MyUnittests ($error)", 2 if $error;
    ok( populate_db(), 'create db needed for unittests' );
    ok( fill_db(), 'fill db for unittests' );
}