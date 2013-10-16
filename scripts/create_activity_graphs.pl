#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Temp;
use Mail::Sender;
use Path::Class;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
}

use lib "$dir/../lib";

use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;
use OTRS::OPR::App::Activity;

my $configfile = $ENV{OPAR_CONFIG} || Path::Class::File->new( $dir, 'conf', 'base.yml' )->stringify;
my $config     = OTRS::OPR::Web::App::Config->new(
    $configfile,
);

my $db           = $config->get( 'db.name' );
my $host         = $config->get( 'db.host' );
my $type         = $config->get( 'db.type' );
my $schema_class = $config->get( 'db.schema' );
my $schema       = OTRS::OPR::DB::Schema->connect(
    "DBI:$type:$db:$host",
    $config->get( 'db.user' ),
    $config->get( 'db.pass' ),
    $schema_class,
);

#$schema->storage->debug(1);

my $activity = OTRS::OPR::App::Activity->new(
    schema     => $schema,
    output_dir => File::Spec->catdir( $config->get( 'paths.base' ), 'public', 'img', 'activities' ),
);

my @users = $schema->resultset( 'opr_user' )->search();
for my $user ( @users ) {
    print STDERR sprintf "Create activity graph for user %s\n", $user->user_name;
    $activity->create_activity(
        type => 'author',
        id   => $user->user_name,
    );
}

my @packages = $schema->resultset( 'opr_package_names' )->search();
for my $package ( @packages ) {
    print STDERR sprintf "Create activity graph for package %s\n", $package->package_name;
    $activity->create_activity(
        type => 'package',
        id   => $package->package_name,
    );
}

