#!/usr/bin/perl

use strict;
use warnings;

use Archive::Tar;
use File::Spec;
use File::Temp;
use Net::FTP;
use Data::Dumper;

my $ftp_host  = 'ftp.otrs.org';
my $local_dir = File::Temp::tempdir();
my @dirs      = qw(pub otrs);

my $ftp = Net::FTP->new( $ftp_host, Debug => 1 );
$ftp->login();

for my $dir ( @dirs ) {
    $ftp->cwd( $dir );
}

my @files   = $ftp->ls;
my @tar_gz  = grep{ m{ \.tar\.gz \z }xms }@files;
my @no_beta = grep{ !m{ -beta }xms }@tar_gz;

my %hash;

FILE:
for my $file ( @no_beta ) {
    my ($major,$minor) = $file =~ m{ \A otrs - (\d+) \. (\d+) \. }xms;
    
    next FILE if !(defined $major and defined $minor);
    
    next FILE if $major < 2;
    next FILE if $major == 2 and $minor < 3;
    
    my $local_path = File::Spec->catfile( $local_dir, $file );
    
    $ftp->binary;
    $ftp->get( $file, $local_path );
    
    my $tar              = Archive::Tar->new( $local_path, 1 );
    my @files_in_archive = $tar->list_files;
    my @modules          = grep{ m{ \.pm \z }xms }@files_in_archive;
    
    MODULE:
    for my $module ( @modules ) {
        next MODULE if $module =~ m{/scripts/};
    
        my ($otrs,$modfile) = $module =~ m{ \A otrs-(\d+\.\d+\.\d+)/(.*) }xms;
        my $is_cpan = $modfile =~ m{cpan-lib}xms;
        
        my $key = $is_cpan ? 'cpan' : 'core';
        
        (my $modulename = $modfile) =~ s{/}{::}g;
        $modulename =~ s{\.pm}{}g;
        $modulename =~ s{Kernel::cpan-lib::}{}g if $is_cpan;
        
        $hash{$otrs}->{$key}->{$modulename} = 1;
    }
}

if ( open my $fh, '>', 'corelist' ) {
    print $fh Dumper \%hash;
}