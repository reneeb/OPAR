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

use MyUnittests;

#ok 1;
ok delete_db(), 'delete test db';
ok delete_files(), 'delete files created while testing';