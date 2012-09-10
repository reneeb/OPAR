#!/usr/bin/perl -w

use strict;
use warnings;

# make sure we are in a sane environment.
$ENV{MOD_PERL} =~ /mod_perl/ or die "MOD_PERL not used!";

# switch to unload_package_xs, the PP version is broken in Perl 5.10.1.
# see http://rt.perl.org/rt3//Public/Bug/Display.html?id=72866
BEGIN {
    $ModPerl::Util::DEFAULT_UNLOAD_METHOD = 'unload_package_xs';
}
use ModPerl::Util;

# set otrs lib path!
use lib "/var/www/perl-services/opar/lib/";

# pull in things we will use in most requests so it is read and compiled
# exactly once

#use CGI (); CGI->compile(':all');
use CGI ();
CGI->compile(':cgi');
use CGI::Carp ();

#use Apache::DBI ();
#Apache::DBI->connect_on_init('DBI:mysql:otrs', 'otrs', 'some-pass');
use DBI ();

# core modules
use Moose;
use DBIx::Class;

use OTRS::OPR::DAO::User;
use OTRS::OPR::DAO::Package;

use OTRS::OPR::DB::Schema;

use OTRS::OPR::Web::App;
use OTRS::OPR::Web::App::Prerun;
use OTRS::OPR::Web::App::Login;
use OTRS::OPR::Web::Author;
use OTRS::OPR::Web::Guest;


1;
