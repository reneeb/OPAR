#!/usr/bin/perl

use strict;
use warnings;

my $ini_file = '/var/www/perl-services/opar/dist.ini';
open my $fh, '<', $ini_file or die $!;
while ( my $line = <$fh> ) {
    chomp $line;
    (my $file = $line) =~ s{::}{/}g;
    $file .= '.pm';
    eval{ require $file } or print "No $line: $@";
}
close $fh;
