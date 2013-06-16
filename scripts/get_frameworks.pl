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

use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;

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

my @packages = $schema->resultset( 'opr_package' )->search();
my %frameworks;

for my $package ( @packages ) {
    my $framework    = $package->framework;

    next if !$framework;

    my @version_list = split /\s*,\s*/, $framework;
    my @shortened    = map{ my ($new) = $_ =~ m/(\d+\.\d+)/; $new }@version_list;

    @frameworks{@shortened} = (1) x @shortened;
}

for my $version ( keys %frameworks ) {
    $schema->resultset( 'opr_framework_versions' )->find_or_create( { framework => $version } );
}
