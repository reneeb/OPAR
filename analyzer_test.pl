#!/usr/bin/perl

use strict;
use warnings;
use lib qw(lib);

use OPR::Backend::OPMAnalyzer;

use Data::Dumper;

my $file     = 'C:\Users\Entwicklung\WIDSpecialEdition-0.0.1.opm';
my $config   = 'D:\SVNRepo\PerlServices\software\OPR\Sources\conf\base.yml';
my $analyzer = OPR::Backend::OPMAnalyzer->new(
    configfile => $config,
);
my $results  = $analyzer->analyze( $file );

print Dumper $results;