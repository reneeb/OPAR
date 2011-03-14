#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 35;

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

my $max_id = get_inserts( 'opr_user' );
is $max_id, 2, 'Inserted two users in "preconditions"';

ok $schema, 'schema was created';

{
    # check an existing user
    my $user = OTRS::OPR::DAO::User->new(
        user_id => 1,
        _schema => $schema,
    );

    ok $user, 'user object created';
    
    ok !$user->not_in_db, 'user is in db';
    
    is $user->user_name, 'reneeb', 'username is "reneeb"';
    is $user->website, 'http://perl-services.de', 'website is correct';
    is $user->mail, 'opar@perl-services.de', 'mail address is correct';
    ok $user->has_group( 'admin' ), 'user is an admin';
    ok !$user->has_group( 'author' ), 'user is not an author';

    ok !$user->_has_changed, 'Userdata have not been changed';

    $user->add_group( 'author' => 1 );

    ok $user->has_group( 'author' );
    ok $user->_has_changed, 'Userdata have been changed';

    $user->website( 'http://perl-magazin.de' );
    is $user->website, 'http://perl-magazin.de', 'changed website to perl-magazin.de';

    my @groups = $user->group_list;
    ok @groups == 2, 'User belongs to two groups';
}

{
    # check if we can create "empty" user
    my $new_user = OTRS::OPR::DAO::User->new(
        _schema => $schema,
    );

    ok $new_user, 'object for new user created';
    
    ok $new_user->not_in_db;
    
    ok !$new_user->user_name, 'new user has no name';
    ok !$new_user->_has_changed, 'new user has not been changed yet';

    $new_user->user_name( 'toms' );
    $new_user->mail( 'hallo@test.example' );
    is $new_user->user_name, 'toms', 'user name for new user has been set';
    ok $new_user->_has_changed, 'now the user has been changed';
}

{
    # check if the new user was added to database
    my $check_user = OTRS::OPR::DAO::User->new(
        user_id => $max_id + 1,
        _schema => $schema,
    );
    
    ok $check_user, 'User was created';
    is $check_user->user_name, 'toms', 'correct user name';
}

{
    # check user that does not exist yet
    my $non_existant = OTRS::OPR::DAO::User->new(
        user_id => $max_id + 2,
        _schema => $schema,
    );
    
    ok $non_existant, 'User was created';
    ok !$non_existant->user_name;
    ok !$non_existant->website;
}

{
    # find user by session_id
    my $user = OTRS::OPR::DAO::User->new(
        session_id => 12345,
        _schema    => $schema,
    );
    
    ok $user, 'User created';
    is $user->user_name, 'tester', 'Username ok';
    is $user->session_id, 12345, 'Session ID ok';
    ok !$user->_has_changed, 'User has not been changed';
}

{
    # find user by user name
    my $user = OTRS::OPR::DAO::User->new(
        user_name => 'reneeb',
        _schema   => $schema,
    );
    
    ok $user, 'user object created';
    
    ok !$user->not_in_db, 'user is in db';
    
    is $user->user_name, 'reneeb', 'username is "reneeb"';
    is $user->mail, 'opar@perl-services.de', 'mail address is correct';
    ok $user->has_group( 'admin' ), 'user is an admin';
    ok $user->has_group( 'author' ), 'user is not an author';
}