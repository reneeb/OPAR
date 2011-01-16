package OPR::DAO::Author;

use Moose;

use Scalar::Util;

extends 'OPR::DAO::Base';

has _create_package_objects => ();

has username => ();
has userid   => ();
has packages => ();
has email    => ();
has website  => ();
has active   => ();

sub init {
    my ( $self, $id ) = @_;
    
    return if !$id;
    return if !looks_like_number( $id );
    
    my $author = $self->_schema->();
    
    $self->_after_init;
}

no Moose;

1;