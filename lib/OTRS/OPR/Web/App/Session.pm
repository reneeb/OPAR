package OTRS::OPR::Web::App::Session;

use strict;
use warnings;
use DBI;

use ReneeB::Session;
use OTRS::OPR::Web::App::Config;

our $VERSION = 0.01;

sub new{
    my ($class,$expire_time) = @_;
    my $self = bless {},$class;
    
    $self->expire( $expire_time );

    return $self;
}# new

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
            cookiename   => 'ActiveCatering',
        );
    }

    return $self->{_session};
}

sub _dbh {
    my ($self) = @_;
    
    unless( $self->{_schema} ){
        my $config = $self->_config;
        my $db   = $config->get( 'db.name' );
        my $host = $config->get( 'db.host' );
        my $type = $config->get( 'db.type' );
        $self->{_schema} = DBI->connect( 
            "DBI:$type:$db:$host", 
            $config->get( 'db.user' ),
            $config->get( 'db.pass' ),
        );
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
    my ($self) = @_;
    
    unless( defined $self->{_config} ){
        $self->{_config} = OTRS::OPR::Web::App::Config->new;
    }

    return $self->{_config};
}

1;

