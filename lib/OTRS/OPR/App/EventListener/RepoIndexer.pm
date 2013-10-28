package OTRS::OPR::App::EventListener::RepoIndexer;

use strict;
use warnings;

use File::Basename;

use OTRS::OPR::App::EventHandler;
use OTRS::OPR::App::Utils::Repo qw(create_index);

on 'repo_saved' => sub {
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
};

1;
