package ReneeB::Session;

use strict;
use warnings;
use Digest::MD5;
use ReneeB::Session::Store;
use ReneeB::Session::State;

our $VERSION = '0.05';

my $generate = sub{
    my ($self) = @_;
    
    my @valid_token = ('a'..'z','A'..'Z',0..9,'$','%','§','?','&','_');
    my $string = '';
    for(0..30){
        $string .= $valid_token[rand(scalar(@valid_token))];
    }

    my $md5 = Digest::MD5->new;
    $md5->add($string);
    my $id = $md5->hexdigest;
  
    $self->_state->save( $id );
    $self->_storage->save( $id );
  
    return $id;
};

sub new{
    my ($class,%args) = @_;
    my $self    = bless {}, $class;
    
    my %storage = ( type => 'file', %{$args{storage_args}} );
    my %state   = ( type => 'file', %{$args{state_args}} );
    
    $self->storage_args( \%storage );
    $self->state_args( \%state );
    
    if ( $args{expire} and $args{expire} !~ m{ \A [0-9]+ \z }xms ) {
        $args{expire} = 1200;
    }
    
    $self->expire( $args{expire} || 1200 );
    $self->_state->expire( $self->expire );
    $self->_state->cookiename( $args{cookiename} );
    
    $self->id( $self->_state->id || ' ' );
    
    $self->_storage->delete_old( $self->expire );
    
    return $self;
}

sub update{
    my ($self) = @_;
    $self->_storage->update( $self->id );
    $self->_state->update( $self->id );
}

sub expire{
    my ($self,$value) = @_;
    
    $self->{_expire} = $value if defined $value;
    
    return $self->{_expire};
}

sub id{
    my ($self, $value) = @_;
    
    $self->{_id} = $value if defined $value;
    
    return $self->{_id};
}

sub force_new{
    my ($self) = @_;
    my $id = $generate->( $self );
    $self->id( $id );
}

sub delete{
    my ($self) = @_;
    $self->_storage->delete_id( $self->id );
}

sub logout{
    my ($self) = @_;
    $self->_storage->delete_id( $self->id );
    $self->_state->delete( $self->id );
}

sub is_valid{
    my ($self) = @_;
    
    my $is_valid = 0;
    
    my $store = $self->_storage;
    my ($id,$time) = $store->get( $self->id );
    
    if( $time and $id and time <= ($time + $self->expire) ){
        $is_valid = 1;
        $store->update( $self->id );
    }

    return $is_valid;
}

sub is_expired{
    return !shift->is_valid;
}

sub storage_args{
    my ($self,$args) = @_;
    
    if( defined $args ){
        my $type = $args->{type} || $self->{_storage_args}->{type};
        $args->{type} = $type;
        $self->{_storage_args} = $args;
    }
    
    return $self->{_storage_args};
}

sub state_args{
    my ($self,$args) = @_;
    
    my $type = $args->{type} || $self->{_state_args}->{type};
    $args->{type} = $type;
    $self->{_state_args} = $args if defined $args;
    
    return $self->{_state_args};
}

sub _storage{
    my ($self) = @_;
    
    my $ref = ref $self->{_storage};
    unless( $ref and $ref =~ /^ReneeB::Session::Store/ ){
        $self->{_storage} = ReneeB::Session::Store->new( $self->storage_args );
    }

    return $self->{_storage};
}

sub _state{
    my ($self) = @_;
    
    my $ref = ref $self->{_state};
    unless( $ref and $ref =~ /^ReneeB::Session::State/ ){
        $self->{_state} = ReneeB::Session::State->new( $self->state_args );
    }

    return $self->{_state};
}


1;