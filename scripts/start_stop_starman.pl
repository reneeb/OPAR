#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Getopt::Long;

GetOptions(
    'workers:s'  => \my $workers,
    'requests:s' => \my $max_requests,
    'ip:s'       => \my $ip,
    'port:s'     => \my $port,
);

$workers      //= 10;
$max_requests //= 200;
$ip           //= '';
$port         //= 3050;

my @ps        = `ps auwx`;
my @processes = grep{ m[starman .*? --listen .*? opar\.psgi]xms }@ps;

if ( @processes ) {
    ($ip,$port) =~ m{ --listen  .*? ([0-9]+\.[0-9]+\.[0-9]+\.[0-9])?:([0-9]+) }xms;

    my @pids = map{ m/ \A .*? (\d+) /xms; $1 }@processes;

    if ( @pids ) {
        kill 9, @pids;
    }
}

my $dir = File::Spec->rel2abs( dirname __FILE__ );

chdir $dir;

my $app = File::Spec->rel2abs(
    File::Spec->catfile( $dir, '..', 'opar', 'opar.psgi' )
);

my $config = $ENV{OPAR_CONFIG};
my $mode   = $ENV{MOJO_MODE};

my @exports;

if ($config) {
    push @exports, "export OPAR_CONFIG=$config";
}
if ($mode) {
    push @exports, "export MOJO_MODE=$mode";
}

# reminder for how to start the application
print <<"TELL";

Running app with the following settings:
\tAPP=$app
\tOPAR_CONFIG=$config\t# path to config
\tMOJO_MODE=$mode\t\t# production | development
\tLISTEN="$ip:$port"
\tWORKERS=$workers
\tMAX REQUESTS=$max_requests
TELL

my $exports = join '', map{ $_ . ' && ' }@exports;

my $command = 'starman --listen :3050 --workers ' . $workers . ' --max-requests ' . $max_requests . ' --preload-app ' . $app;
#exec( $command );
exec( "$exports nohup $command &" );
