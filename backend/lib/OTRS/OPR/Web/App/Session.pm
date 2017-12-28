package OTRS::OPR::Web::App::Session;

use strict;
use warnings;

use Crypt::SaltedHash;

our $VERSION = 0.02;

my $generate = sub{
    my ($self) = @_;

    my @valid_token = ('a'..'z','A'..'Z',0..9,'$', '_', '/','\\', '(', ')', '{', '}');
    my $string = '';
    $string .= $valid_token[rand @valid_token] for ( 0 .. 30 );

    my $salted_ip = Crypt::SaltedHash->new->add( $self->app->tx->remote_address )->generate;
    my $id        = sprintf "%s%s%s", $string, time(), $salted_ip;

    return $id;
};

sub new{
    my ($class,%args) = @_;
    my $self = bless {},$class;
    
    $self->app( $args{app} );
    $self->app->app->sessions->default_expiration( $args{expire} || 3600 );

    return $self;
}

sub app {
    my ($self,$value) = @_;

    $self->{__app__} = $value if @_ == 2;
    return $self->{__app__};
}

sub force_new {
    my ($self) = @_;

    $self->app->session( OPAR => $generate->($self) );
}

sub is_expired{
    my ($self) = @_;
    my $id = $self->app->session( 'OPAR' );

    $self->app->app->log->debug( $id );

    return 1 if !$id;

    my $ip         = $self->app->tx->remote_address;
    my $session_ip = substr $id, -38;

    my $valid = Crypt::SaltedHash->validate( $session_ip, $ip ) || '';
    $self->app->app->log->debug( "$ip // $session_ip // $valid" );

    return !$valid;
}

sub delete {
    shift->app->session( OPAR => 'undef' );
}

sub update_session{
    return 1;
}

sub id{
    my ($self) = @_;

    my $id = $self->app->session( 'OPAR' );

    $self->app->app->log->debug( $id );

    return $id;
}

1;

