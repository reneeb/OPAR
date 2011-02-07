#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 13;

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

{

    {
        package MockObject;
        use MyUnittests;
        use OTRS::OPR::Web::App::Config;
        use OTRS::OPR::DB::Helper::Package qw(user_is_maintainer);
        
        sub new { bless {}, shift }
        sub table { shift; schema()->resultset( shift ); }
        sub config { OTRS::OPR::Web::App::Config->new( $dir . '/tests.yml' ) }
        
    }
    
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
    
    ok $mock->user_is_maintainer( $user, { name => 'NotMainAuthor' } ), 'User is maintainer (NotMainAuthor)';
    ok $mock->user_is_maintainer( $user, { id   => 2 } ), 'User is maintainer (2)';
    ok !$mock->user_is_maintainer( $user, { name => 'NotMainAuthor', main_author => 1 } ), 'User is not maintainer (NotMainAuthor, main_author)';
    #schema->storage->debug(1);
    ok !$mock->user_is_maintainer( $user, { id => 2, main_author => 1 } ), 'User is not maintainer (2, main_author)';
    #schema->storage->debug(0);
    
    ok !$mock->user_is_maintainer( $user, { name => 'NotMaintainer' } ), 'User is not maintainer (NotMaintainer)';
    ok !$mock->user_is_maintainer( $user, { id   => 3 } ), 'User is not maintainer (3)';
    ok !$mock->user_is_maintainer( $user, { name => 'NotMaintainer', main_author => 1 } ), 'User is not maintainer (NotMaintainer, main_author)';
    ok !$mock->user_is_maintainer( $user, { id => 3, main_author => 1 } ), 'User is not maintainer (3, main_author)';
    
    ok $mock->user_is_maintainer( $user, { name => 'NotUsedYet' } ), 'User is maintainer (new name)';
}