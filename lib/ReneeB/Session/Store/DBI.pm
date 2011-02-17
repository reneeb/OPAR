package ReneeB::Session::Store::DBI;

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
    
    my $table  = $self->_table;
    my $id_col = $self->_id;
    my $start  = $self->_start;

    my $stmt   = qq~INSERT INTO $table ($id_col, $start) VALUES (?,?)~;
    $self->_schema->do( $stmt, undef, $id, time );
}

sub get{
    my ($self,$id) = @_;
    
    my $table  = $self->_table;
    my $id_col = $self->_id;
    my $start  = $self->_start;

    my $stmt   = qq~SELECT $id_col,$start FROM $table WHERE $id_col = ?~;
    my $sth    = $self->_schema->prepare( $stmt );
    $sth->execute( $id );

    my ($tmp_id,$time) = $sth->fetchrow_array;
    
    return ($tmp_id, $time);
}

sub update{
    my ($self,$id) = @_;

    my $table  = $self->_table;
    my $id_col = $self->_id;
    my $start  = $self->_start;

    my $stmt   = qq~UPDATE $table SET $start = ? WHERE $id_col = ?~;
    $self->_schema->do( $stmt, undef, time, $id );
}

sub delete_id{
    my ($self,$id) = @_;

    my $table  = $self->_table;
    my $id_col = $self->_id;

    my $stmt   = qq~DELETE FROM $table WHERE $id_col = ?~;
    
    $self->_schema->do( $stmt, undef, $id );
}

sub delete_old{
    my ($self,$expire) = @_;
    
    my $min    = time - $expire;
    my $table  = $self->_table;
    my $start  = $self->_start;

    my $stmt   = qq~DELETE FROM $table WHERE $start < $min~;
    $self->_schema->do( $stmt );
}

sub _schema{
    my ($self,$args) = @_;
    
    unless( $self->{_schema} ){
        $self->_table( $args->{table}        || 'Session'   );
        $self->_id(    $args->{id_column}    || 'SessionID' );
        $self->_start( $args->{start_column} || 'Start'     );
        $self->{_schema} = $args->{dbh};
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