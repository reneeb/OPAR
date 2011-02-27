#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

no warnings 'redefine';
no warnings 'prototype';

my $dir      = dirname __FILE__;
my $ini_file = $dir . '/dist.ini';
open my $fh, '<', $ini_file or die $!;
while ( my $line = <$fh> ) {
    chomp $line;

    my ($module,$version) = split /\s*=\s*/, $line;

    $version = 0 if !defined $version;

    my $error;
    eval "use $module $version; 1;" or $error = $@;

    print sprintf "%-40s %s %s\n", $module, '.' x 15, ( $error || 'ok' );
}
close $fh;
