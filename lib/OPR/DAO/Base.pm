package OPR::DAO::Base;

use Moose;

has _schema => ();

sub _after_init {
    my ($self) = @_;
    
    # get all attributes of object and save initial value
    # this is used to find out, if the object should be saved on destruction
    
}

sub _has_changed {
}

sub _save {
}

after 'new' => sub {
    my ($self) = @_;
    
    $self->init if $self->can( 'init' );
};

no Moose;

1;