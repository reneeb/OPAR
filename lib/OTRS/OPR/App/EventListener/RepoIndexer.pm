package OTRS::OPR::App::EventListener::RepoIndexer;

use strict;
use warnings;

use File::Basename;

use OTRS::OPR::App::EventHandler;
use OTRS::OPR::App::Utils::Repo qw(create_index);

on repo_saved      => \&_index_repo;
on package_indexed => sub {
    my $package_id = shift;
    my $schema     = shift;

    my $package    = $schema->resultset( 'opr_package' )->search({ package_id => $package_id })->first;
    my @frameworks = map{ $_ =~ s/\.x//g; $_ }split /, /, $package->framework;
    my $name_id    = $package->opr_package_names->name_id;

    my @repos = $schema->resultset( 'opr_repo' )->search(
        {
            name_id   => $name_id,
            framework => [ @frameworks ], 
        },
        {
            join => 'opr_repo_package',
        },
    );

    for my $repo ( @repos ) {
        _index_repo( $repo->repo_id, $schema );
    }
};


sub _index_repo {
    my $repo_id = shift;
    my $schema  = shift;

    my $repo          = $schema->resultset( 'opr_repo' )->search({ repo_id => $repo_id })->first;
    my @repo_packages = $repo->opr_repo_package; 

    my $framework_version = '%' . $repo->framework . '%';
    my @name_ids          = map{ $_->name_id }@repo_packages;

    my @packages = $schema->resultset( 'opr_package' )->search(
        {
            'me.framework'  => { LIKE => $framework_version },
            'me.name_id'    => [ @name_ids ],
            'me.package_id' => {
                '=' => \"(SELECT package_id FROM opr_package WHERE name_id = me.name_id AND framework LIKE '$framework_version' ORDER BY upload_time DESC LIMIT 1)"
            },
        },
        {
            order_by  => 'max(upload_time) DESC',
            group_by  => [ 'name_id' ],
            join      => 'opr_package_names',
            '+select' => [
                { max => 'version', '-as' => 'max_version' },
                { max => 'upload_time', '-as' => 'latest_time' },
            ],
        },
    )->all;

    my @opm_files = map{ $_->path }@packages;
    my %paths     = map{ $_->path => basename $_->virtual_path }@packages;
    my $index     = create_index( \@opm_files, \%paths );

    $repo->update({ index_file => $index });
}

1;
