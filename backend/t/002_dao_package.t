#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 48;

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


my $max_id = get_inserts( 'opr_package' );
is $max_id, 3;

{
    # check API
    my @methods = qw(
        uploaded_by description version name_id
        framework path virtual_path is_in_index website bugtracker upload_time
        deletion_flag objects package_name package_id oq_results
        dependencies author
    );
    
    can_ok 'OTRS::OPR::DAO::Package', @methods;
}

{
    # check package 1
    my $package = OTRS::OPR::DAO::Package->new(
        package_id => 1,
        _schema => $schema,
    );

    ok $package, 'package object created';
    
    ok !$package->not_in_db, 'package 1 is in database';

    ok !$package->_has_changed, 'package data have not been changed';
    is $package->package_name, 'Test', 'name of package 1';
    is $package->version, '0.0.0', 'version of package 1';
    is $package->website, 'http://www.perl-services.de', 'website of package 1';
    is $package->bugtracker, 'http://git.perl-services.de/issues', 'bugtracker of package 1';
    is $package->path, 'reneeb/Test-0.0.0.opm', 'path of package 1';
    ok !$package->is_in_index, 'package 1 is currently not in index';
    
    # change some settings
    $package->version( '0.0.1' );
    ok $package->_has_changed, 'package data have been changed';
    is $package->version, '0.0.1', 'changed version number of package 1';
}

{
    # check package 1 with giving package_name
    my $package = OTRS::OPR::DAO::Package->new(
        package_name => 'Test',
        _schema => $schema,
    );

    ok $package, 'package object created (2)';
    
    ok !$package->not_in_db, 'package 1 is in database (2)';

    ok !$package->_has_changed, 'package data have not been changed (2)';
    is $package->package_name, 'Test', 'name of package 1 (2)';
    is $package->version, '0.0.1', 'version of package 1 (2)';
    is $package->website, 'http://www.perl-services.de', 'website of package 1 (2)';
    is $package->bugtracker, 'http://git.perl-services.de/issues', 'bugtracker of package 1 (2)';
    is $package->path, 'reneeb/Test-0.0.0.opm', 'path of package 1 (2)';
}

{
    # check package 1 with giving package_name and version
    my $package = OTRS::OPR::DAO::Package->new(
        package_name => 'Test',
        version      => '0.0.1',
        _schema => $schema,
    );

    ok $package, 'package object created (3)';
    
    ok !$package->not_in_db, 'package 1 is in database (3)';

    ok !$package->_has_changed, 'package data have not been changed (3)';
    is $package->package_name, 'Test', 'name of package 1 (3)';
    is $package->version, '0.0.1', 'version of package 1 (3)';
    is $package->website, 'http://www.perl-services.de', 'website of package 1 (3)';
    is $package->bugtracker, 'http://git.perl-services.de/issues', 'bugtracker of package 1 (3)';
    is $package->path, 'reneeb/Test-0.0.0.opm', 'path of package 1 (3)';
}

{
    # add new package
    my $package = OTRS::OPR::DAO::Package->new(
        _schema => $schema,
    );
    
    ok $package, 'new package object created';
    ok $package->not_in_db, 'new package not in db yet';
    ok !$package->package_id, 'no package id yet (new package)';
    ok !$package->package_name, 'no package name yet (new package)';
    ok !$package->_has_changed, 'new package not changed yet';
    $package->package_name( 'DynamicAdminMenu' );
    is $package->package_name, 'DynamicAdminMenu', 'set "package_name"';
    $package->version( '1.0.0' );
    is $package->version, '1.0.0', 'set "version"';
    $package->framework( '2.4.x' );
    is $package->framework, '2.4.x', 'set "framework"';
    $package->uploaded_by( 1 );
    is $package->uploaded_by, 1, 'set "uploaded_by"';
    ok $package->_has_changed, 'new package was changed';
    
    my @changed = $package->changed_attrs;
    is scalar( @changed ), 4, 'changed 4 attributes';
}

{
    # check package that was just created
    my $package = OTRS::OPR::DAO::Package->new(
        package_id => $max_id + 1,
        _schema    => $schema,
    );
    
    ok $package, 'package object created';
    ok !$package->not_in_db, 'now the new object is in db';
    is $package->package_name, 'DynamicAdminMenu', 'package name of new package';
    is $package->version, '1.0.0', 'version of new package';
    ok !$package->_has_changed, 'package has not been changed';
}

{
    # check package that does no exist in db
    my $package = OTRS::OPR::DAO::Package->new(
        package_id => $max_id + 2,
        _schema    => $schema,
    );
    
    ok $package, 'object for non-existant package created';
    ok $package->not_in_db, 'non-existant package is not in db';
}