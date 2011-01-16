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
            cookiename   => 'OPAR',
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
    my ($self,$config) = @_;
    
    $self->{__config__} = $config if @_ == 2;
    return $self->{__config__};
}

1;

