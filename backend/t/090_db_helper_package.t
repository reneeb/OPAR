#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 24;

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
use OTRS::OPR::DAO::Package;

my $schema = schema();

ok $schema, 'schema was created';

my $max_id = get_inserts( 'opr_package_names' );
is $max_id, 3, 'Inserted package names in "preconditions"';

{
    package MockObject;
    use MyUnittests;
    use OTRS::OPR::Web::App::Config;
    use OTRS::OPR::DB::Helper::Package qw(user_is_maintainer package_exists);
     
    sub new { bless {}, shift }
    sub table { shift; schema()->resultset( shift ); }
    sub config { OTRS::OPR::Web::App::Config->new( $dir . '/tests.yml' ) }
        
}

{
    
    my $mock = MockObject->new;
    
    # check an existing user
    my $user = OTRS::OPR::DAO::User->new(
        user_id => 1,
        _schema => $schema,
    );
    
    ok $mock->user_is_maintainer( $user, { name => 'Test' } ), 'User is maintainer (Test)';
    ok $mock->user_is_maintainer( $user, { name => 'Test', main_author => 1 } ), 'User is maintainer (Test, main_author)';
    ok $mock->user_is_maintainer( $user, { id => 1 } ), 'User is maintainer (1)';
    ok $mock->user_is_maintainer( $user, { id => 1, main_author => 1 } ), 'User is maintainer (1, main_author)';
    
    my $name_id = $mock->user_is_maintainer( $user, { name => 'Test' } );
    is $name_id, 1, 'NameID for "Test"';
    
    my $name_id_main_author = $mock->user_is_maintainer( $user, { name => 'Test', main_author => 1 } );
    is $name_id_main_author, 1, 'NameID for "Test" (main_author)';
    
    ok $mock->user_is_maintainer( $user, { name => 'NotMainAuthor' } ), 'User is maintainer (NotMainAuthor)';
    ok $mock->user_is_maintainer( $user, { id   => 2 } ), 'User is maintainer (2)';
    ok !$mock->user_is_maintainer( $user, { name => 'NotMainAuthor', main_author => 1 } ), 'User is not maintainer (NotMainAuthor, main_author)';
    #schema->storage->debug(1);
    ok !$mock->user_is_maintainer( $user, { id => 2, main_author => 1 } ), 'User is not maintainer (2, main_author)';
    #schema->storage->debug(0);
    
    my $nma_id = $mock->user_is_maintainer( $user, { name => 'NotMainAuthor' } );
    is $nma_id, 2, 'NameID for "NotMainAuthor"';
    
    ok !$mock->user_is_maintainer( $user, { name => 'NotMaintainer' } ), 'User is not maintainer (NotMaintainer)';
    ok !$mock->user_is_maintainer( $user, { id   => 3 } ), 'User is not maintainer (3)';
    ok !$mock->user_is_maintainer( $user, { name => 'NotMaintainer', main_author => 1 } ), 'User is not maintainer (NotMaintainer, main_author)';
    ok !$mock->user_is_maintainer( $user, { id => 3, main_author => 1 } ), 'User is not maintainer (3, main_author)';
    
    ok !$mock->user_is_maintainer( $user, { name => 'NotUsedYet' } ), 'User is maintainer (new name, no "add")';
    
    my $nuy_id = $mock->user_is_maintainer( $user, { name => 'NotUsedYet', add => 1 } );
    is $nuy_id, $max_id + 2, 'User is maintainer (new name, "add")'; # plus 2 as one name was added in an other test
}

{
    # test "page"
    my $mock = MockObject->new;
}

{
    # test "package_exists"
    
    my $mock = MockObject->new;
    
    my ($package) = OTRS::OPR::DAO::Package->new(
        package_id => 1,
        _schema    => $schema,
    );
    
    ok !$mock->package_exists, 'Empty package name does not exist';
    
    my $package_name = $package->package_name;
    ok $mock->package_exists( $package_name ), "$package_name exists";
    ok $mock->package_exists( $package_name, { version => $package->version } ), sprintf "%s v%s exists", $package_name, $package->version;
    ok !$mock->package_exists( $package_name . 'N' ), sprintf "%s does not exist", $package_name;
    ok !$mock->package_exists( $package_name, { version => '99.99.999' } ), sprintf "%s v99.99.999 does not exist", $package_name;
}