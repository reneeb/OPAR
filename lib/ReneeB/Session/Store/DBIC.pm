package ReneeB::Session::Store::DBIC;

use strict;
use warnings;

sub new{
    my ($class, $args) = @_;
    my $self    = bless {}, $class;
        
    $self->_schema( $args );
    
    return $self;
}

sub save{
    my ($self, $id) = @_;
    
    my ($entry) = $self->_schema->resultset( $self->_table )->create({
        $self->_id    => $id,
        $self->_start => time,
    });
    
    $entry->update;
}

sub get{
    my ($self,$id) = @_;
    
    my ($entry) = $self->_schema->resultset( $self->_table )->search({
        $self->_id => $id,
    });
    
    my ($tmp_id, $time);
    if( $entry ){
        $tmp_id = $entry->get_column( $self->_id );
        $time   = $entry->get_column( $self->_start );
    }

    return ($tmp_id, $time);
}

sub update{
    my ($self,$id) = @_;
    
    my ($entry) = $self->_schema->resultset( $self->_table )->search({
        $self->_id => $id,
    });
    
    $entry->update({
        $self->_start => time,
    });
}

sub delete_id{
    my ($self,$id) = @_;
    
    my ($session) = $self->_schema->resultset( $self->_table )->search({
        $self->_id => $id,
    });
    
    if( $session ){
        $session->delete;
    }
}

sub delete_old{
    my ($self,$expire) = @_;
    
    my $min  = time - $expire;
    my @sessions = $self->_schema->resultset( $self->_table )->search;
    for my $session ( @sessions ){
        if( $session->get_column( $self->_start ) < $min ){
            $session->delete;
        }
    }
}

sub _schema{
    my ($self,$args) = @_;
    
    unless( $self->{_schema} ){
        $self->_table( $args->{table}        || 'Session'   );
        $self->_id(    $args->{id_column}    || 'SessionID' );
        $self->_start( $args->{start_column} || 'Start'     );
        $self->{_schema} = $args->{schema};
    }

    return $self->{_schema};
}

sub _table{
    my ($self,$value) = @_;
    $self->{_table} = $value if defined $value;
    return $self->{_table};
}

sub _id{
    my ($self,$value) = @_;
    $self->{_id} = $value if defined $value;
    return $self->{_id};
}

sub _start{
    my ($self,$value) = @_;
    $self->{_start} = $value if defined $value;
    return $self->{_start};
}

1;