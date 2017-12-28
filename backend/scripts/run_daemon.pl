#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Path::Class;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
}

use lib "$dir/../lib";

use OTRS::OPR::Daemon;

my $conf_dir = Path::Class::Dir->new( $dir, 'conf' );
my $daemon   = OTRS::OPR::Daemon->new(
    config => $conf_dir,
);
$daemon->run;
