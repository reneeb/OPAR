#!/usr/bin/perl

use strict;
use warnings;
use lib qw(lib);

use OTRS::OPR::Daemon;

my $daemon = OTRS::OPR::Daemon->new;
$daemon->run;