package OTRS::OPR::App::EventListener::RepoIndexer;

use strict;
use warnings;

use Moo;

has repo_id     => (is => 'ro', required => 1 );
has schema      => (is => 'ro', required => 1);

sub create_index {
    my $self = shift;

    my $packages = $self->packages;
    if ( !$packages && $self->package_ids ) {
        $packages = $self->schema->resultset('opr_package')->search({ package_id => $self->package_ids })->all;
    }
}

1;
