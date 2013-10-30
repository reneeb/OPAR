package OTRS::OPR::DAO::User;

use Moose;
use OTRS::OPR::App::AttributeInformation;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(session_id user_name user_password website mail active registered realname);
for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}


has user_id => (
    is  => 'rw',
);

has user_object => (
    is  => 'rw',
    isa => 'Object',
);

sub save {
    my ($self) = @_;
    
    $self->DEMOLISH;
}

sub BUILD {
    my ($self) = @_;
    
    my $user;
    if ( !$self->user_id && $self->session_id ) {
        ($user) = $self->ask_table( 'opr_user' )->search({
            session_id => $self->session_id,
         });
    }
    elsif ( $self->user_name ) {
        ($user) = $self->ask_table( 'opr_user' )->search({
            user_name => $self->user_name,
        });
    }
    elsif ( $self->user_id ) {
        ($user) = $self->ask_table( 'opr_user' )->find( $self->user_id );
    }
    
    return if !$user;
    
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $user->$attr() );
    }
    
    $self->user_id( $user->user_id );
    $self->user_object( $user );
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    
    return if !$self->_has_changed;
    return if !($self->user_name and $self->mail);
        
    my @changed_attrs = $self->changed_attrs;
    my $user          = $self->user_object;
    
    if ( !$user ) {
        ($user) = $self->ask_table( 'opr_user' )->create( {} );
        
    
        $self->user_object( $user );
    }
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'user_id';
        
        $user->$attr( $self->$attr() );
    }
    
    $user->update;
    $self->user_id( $user->user_id );
}

no Moose;

1;
