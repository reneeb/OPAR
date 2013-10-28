#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Temp;
use File::Copy qw(move);
use Path::Class;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
}

use lib "$dir/../lib";

use OTRS::OPR::App::Utils::Repo qw(create_index);
use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;

my $configfile = $ENV{OPAR_CONFIG} || Path::Class::File->new( $dir, '..', 'conf', 'base.yml' )->stringify;
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

$schema->storage->debug(1);

my @frameworks = $schema->resultset( 'opr_framework_versions' )->search();

my @names    = $schema->resultset( 'opr_package_names' )->search();
my @name_ids = map{ my $id = $_->name_id; $id ? $id : () }@names;

my %files;
my %paths;

for my $framework ( @frameworks ) {

    my $version = $framework->framework;

    my $resultset = $schema->resultset( 'opr_package' )->search(
        {
            framework => { like => '%' . $version . '%' },
        },
        {
            order_by  => 'max(upload_time) DESC',
            group_by  => [ 'name_id' ],
            '+select' => [
                { max => 'version', '-as' => 'max_version' },
            ],
        },
    );

    my @packages = $resultset->all;

    for my $package ( @packages ) {
        my ($local_package) = $schema->resultset( 'opr_package' )->search( {
            version => $package->get_column( 'max_version' ),
            name_id => $package->name_id,
        });

        $files{$version}->{ $package->name_id } = $local_package->path;
        $paths{ $local_package->path }          = basename $local_package->virtual_path;
    }
}

my %repos_to_create = (
    'otrs' => [ keys %paths ],
);

my @repos = $schema->resultset( 'opr_repo' )->search();
my %all_repos;
for my $repo ( @repos ) {
    my @repo_packages = $repo->opr_repo_package;
    my @name_ids      = map{ $_->name_id }@repo_packages;

use Data::Dumper;
print Dumper [ \@name_ids, $files{$repo->framework}, $repo->framework, \%files ];

    $repos_to_create{ $repo->repo_id } = [ @{ $files{ $repo->framework } }{@name_ids} ];
    $all_repos{ $repo->repo_id }       = $repo;
}

for my $repo ( keys %repos_to_create ) {
    my $index = create_index( $repos_to_create{$repo} );

    if ( $repo eq 'otrs' ) {
        my $fh = File::Temp->new( UNLINK => 0 );
        print $fh $index;

        my $filename = $fh->filename;

        close $fh;

        my $index_file = $config->get( 'otrs.index' );
        move $filename, $index_file;
    }
    else {
        $all_repos{$repo}->update({ index_file => $index });
    }
}
