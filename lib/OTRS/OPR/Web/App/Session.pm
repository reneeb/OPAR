package OTRS::OPR::Web::App::Session;

use strict;
use warnings;
use DBI;

use ReneeB::Session;
use OTRS::OPR::Web::App::Config;

our $VERSION = 0.01;

sub new{
    my ($class,%args) = @_;
    my $self = bless {},$class;
    
    $self->_config( $args{config} );
    $self->expire( $args{expire} );

    $self->app( $args{app} );
    $self->_dbh( $args{schema} );

    {
        no warnings 'redefine';
        *ReneeB::Session::State::Cookie::save = sub {
            my ($session,$id) = @_;

            my $cookie = CGI::Cookie->new(
                -name   => $session->cookiename,
                -value  => $id,
                -expire => $session->expire,
            );

            $self->app->header_add( -cookie => $cookie );
        };
    }

    return $self;
}# new

sub app {
    my ($self,$value) = @_;

    $self->{__app__} = $value if @_ == 2;
    return $self->{__app__};
}

sub session{
    my ($self) = @_;
    
    unless( $self->{_session} ){
        $self->{_session} = ReneeB::Session->new(
            storage_args => {
                type   => 'dbh',
                dbh    => $self->_dbh,
            },
            state_args   => {
                type => 'cookie',
            },
            expire       => $self->expire,
            cookiename   => 'OPAR',
        );
    }

    return $self->{_session};
}

sub _dbh {
    my ($self,$schema) = @_;
    
    if ( !$self->{_schema} && $schema ) {
        $self->{_schema} = $schema->storage->dbh;
    }

    $self->{_schema};
}

sub expire{
  my ($self,$time) = @_;
  $self->{expire} = $time if defined $time;
  return $self->{expire};
}

sub delete{
    my ($self) = @_;
    $self->session->delete( $self->session->id );
}

sub logout{
    my ($self) = @_;
    $self->session->logout;
}

sub is_expired{
    my ($self) = @_;
    my $ex = $self->session->is_expired;
    #$self->session->force_new if $ex;
    return $ex;
}# is_expired

sub force_db{}

sub update_session{
    my ($self) = @_;    
    return $self->session->update;
}

sub id{
  my ($self) = @_;
  return $self->session->id;
}# id

sub _config{
    my ($self,$config) = @_;
    
    $self->{__config__} = $config if @_ == 2;
    return $self->{__config__};
}

1;

