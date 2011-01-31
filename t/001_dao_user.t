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
use OTRS::OPR::DAO::User;

my $schema = schema();

ok $schema, 'schema was created';

my $user = OTRS::OPR::DAO::User->new(
    user_id => 1,
    _schema => $schema,
);

ok $user, 'user object created';