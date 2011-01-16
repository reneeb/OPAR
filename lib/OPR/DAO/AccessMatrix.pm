package OPR::DAO::AccessMatrix;

use Moose;

extends 'OPR::DAO::Base';

has userid => ();
has matrix => ();

sub has_access {
    my ($self,$func,$perm) = @_;
    
    my $matrix = $self->matrix;
    return if !$matrix;
    
    return if !exists $matrix->{$func};
}

sub set_permission {
    my ($self,$func,$perm) = @_;
    
    $perm ||= 0;
    
    return if !$func;
}

sub init {
    my ($self) = @_;
    
    return if !$self->userid;
    
    # try to get precompiled matrix from db
    
    # if it does not exist, init with empty hash
    
    # try to compile matrix from db
}

sub save {
    my ($self) = @_;
    
    # save matrix in db
}

no Moose;

1;