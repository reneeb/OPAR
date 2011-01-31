#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 1;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;
use lib $dir;

use MyUnittests;

ok delete_db(), 'delete test db';