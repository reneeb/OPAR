#!/usr/bin/perl

use strict;
use warnings;
use lib qw(lib);
use File::Basename;
use Path::Class;

use OTRS::OPR::Daemon;

my $dir      = dirname __FILE__;
my $conf_dir = Path::Class::Dir->new( $dir, 'conf' );
my $daemon   = OTRS::OPR::Daemon->new(
    config => $conf_dir,
);
$daemon->run;
