#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 12;

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