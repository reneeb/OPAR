#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 7;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;
use lib $dir;

use MyUnittests;
use OTRS::OPR::DAO::Package;

my $schema = schema();

ok $schema, 'schema was created';

{
    # check package 1
    my $package = OTRS::OPR::DAO::Package->new(
        package_id => 1,
        _schema => $schema,
    );

    ok $package, 'package object created';

    ok !$package->_has_changed, 'package data have not been changed';
    is $package->package_name, 'Test', 'name of package 1';
    is $package->uploaded_by, 1, 'uploaded by of package 1';
    
    my $user = $package->author;
    ok $user->isa( 'OTRS::OPR::DAO::Author' ), 'author is instance of correct class';
    is $user->user_name, 'reneeb', 'author name';
}