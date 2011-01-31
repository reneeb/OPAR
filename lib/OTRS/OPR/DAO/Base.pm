package OTRS::OPR::DAO::Base;

use Moose;

has _schema => (
    is => 'rw',
);
has _config => (
    is => 'rw',
);

sub _after_init {
    my ($self) = @_;
    
    # get all attributes of object and save initial value
    # this is used to find out, if the object should be saved on destruction
    
}

sub _has_changed {
}

sub _save {
}

sub BUILD {
    my ( $self ) = @_;
    # establish DB connection iff necessary
    if ( !$self->_schema ) {
        warn 'establish DB connection';
    }
}

sub ask_table {
    my ($self, $name) = @_;
    
    return $self->_schema->resultset( $name );
}

no Moose;

1;