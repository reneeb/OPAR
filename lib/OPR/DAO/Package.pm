package OPR::DAO::Package;

use Moose;

extends 'OPR::DAO::Base';

has _create_author_object => ( is => 'ro', isa => 'Bool' );

has package_id    => ( is => 'rw', isa => 'Int' );
has name          => ( is => 'rw', isa => 'Str' );
has framework     => ( is => 'rw', isa => 'VersionString' );
has vendor        => ( is => 'rw', isa => 'Str' );
has comments      => ( is => 'rw', isa => 'ArrayRef[HashRef]' );
has version       => ( is => 'rw', isa => 'VersionString' );
has path          => ( is => 'rw', isa => 'Str' );
has is_in_index   => ( is => 'rw', isa => 'Bool' );
has website       => ( is => 'rw', isa => 'Url' );
has bugtracker    => ( is => 'rw', isa => 'Url' );
has upload_time   => ( is => 'rw', isa => 'Int' );
has virtual_path  => ( is => 'rw', isa => 'Str' );
has description   => ( is => 'rw', isa => 'Str' );
has documentation => ( is => 'rw', isa => 'Str' );

has oq_results   => (
);

has dependencies => (
);

has author => (
);

has co_maintainer => (
);

sub init {
    my ($self) = @_;
    
    $self->_after_init;
}

no Moose;

1;