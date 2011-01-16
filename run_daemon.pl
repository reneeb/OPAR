#!/usr/bin/perl

use strict;
use warnings;
use lib qw(lib);

use OPR::Backend::Daemon;

my $daemon = OPR::Backend::Daemon->new;
$daemon->run;