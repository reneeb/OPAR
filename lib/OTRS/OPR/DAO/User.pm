package OTRS::OPR::DAO::User;

use Moose;

extends 'OTRS::OPR::DAO::Base';

has session_id    => ( is => 'rw' );
has user_name     => ( is => 'rw' );
has user_id       => ( is => 'ro' );
has website       => ( is => 'rw' );
has user_password => ( is => 'rw' );
has mail          => ( is => 'rw' );
has groups        => ( is => 'rw', isa => 'ArrayRef[Str]', auto_deref => 1 );

sub BUILD {
    my ($self) = @_;
    my ($user) = $self->ask_table( 'opr_user' )->find( $self->user_id );
    $self->user_name( $user->user_name );
    $self->website( $user->website );
    $self->mail( $user->mail );
    #$self->after_init();
}

no Moose;

1;