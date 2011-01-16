package OTRS::OPR::Web::App;

use strict;
use warnings;

use parent qw(CGI::Application OTRS::OPR::App::Attributes);
use CGI::Application::Plugin::Redirect;

use Data::Dumper;
use DBIx::Class;
use File::Basename;
use Log::Log4perl;
use Path::Class;

use OTRS::OPR::DAO::User;
use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;
use OTRS::OPR::Web::App::Session;
use OTRS::OPR::Web::App::View qw(view);

our $VERSION = 1.0;

my @subdirs = split /::/, __PACKAGE__;
my $libdir  = Path::Class::Dir->new(
    dirname( __FILE__ ),
    ('..') x @subdirs,
);

sub notify {
    my ($self,$params) = @_;
    
    if ( $params and ref $params eq 'HASH' ) {
        push @{$self->{__notifications}}, $params;
    }
    
    return $self->{__notifications};
    
    if ( !$params ) {
        $self->{__notifications} = [];
    }
}

sub base_url {
    my ($self) = @_;
}

sub session {
    my ($self) = @_;
    
    unless( $self->{___session} ) {
        my $config = $self->config;
        my $expire = $config->get( 'session_expire' ) || 20; # this is in minutes
        
        $expire *= 60; # but we need it in seconds
        
        $self->{___session} = OTRS::OPR::Web::App::Session->new( $expire );
    }

    $self->{___session};
}

sub json_method {
    my ($self,$value) = @_;
    
    $self->{__is_json_method} = $value if @_ == 2;
    return $self->{__is_json_method};
}

sub user {
    my ($self,$session) = @_;
    
    unless( $self->{___user} ) {
        my $session_id = $session->id;
        if( $session_id and not $session->is_expired ){
            my ($user) = OTRS::OPR::DAO::User->new( session_id => $session_id );
            
            if( $user ) {
                $self->{___user} = $user;
            }
        }
    }

    $self->{___user};
}

sub template {
    my ($self,$template) = @_;
    
    $self->{_my_template} = $template if defined $template;
    return $self->{_my_template};
}

sub main_tmpl{
    my ($self,$template) = @_;
    $self->{_main_tmpl}  = $template if defined $template;
    return $self->{_main_tmpl};
}

sub cgiapp_postrun{
    my ($self,$outref) = @_;
    
    if ( $self->json_method ) {
        # set http header for json output
        # create json output
    }
    elsif ( $self->get_current_runmode ne 'dummy_redirect' ){
        my $string = $self->view;
        $$outref   = $string;
    }
}

sub config{
    my ($self) = @_;
    
    unless( $self->{config} ){        
        my $configfile = Path::Class::File->new( $libdir, 'conf', 'base.yml' );
        
        $self->{_config} = OTRS::OPR::Web::App::Config->new(
            $configfile->stringify,
        );
    }
    
    return $self->{_config};
}

sub stash {
    my ($self,%params) = @_;
    
    $self->{__stash} = {} unless $self->{__stash};
    
    for my $key ( keys %params ) {
        $self->{__stash}->{$key} = $params{$key};
    }

    $self->{__stash};
}

sub logger {
    my ($self) = @_;
    
    unless( $self->{logging} ){
        my $conf_file = $self->config->get( 'logging' );
        Log::Log4perl->init( $conf_file );
        $self->{logging} = Log::Log4perl->get_logger;
    }

    $self->{logging};
}

sub schema {
    my ($self) = @_;
    
    unless( $self->{_schema} ){
        my $config = $self->config;
        $self->logger->debug( 'connect to db' );
        my $db     = $config->get( 'db.name' );
        my $host   = $config->get( 'db.host' );
        my $type   = $config->get( 'db.type' );
        my $schema = $config->get( 'db.schema' );
        $self->{_schema} = OTRS::OPR::DB::Schema->connect( 
            "DBI:$type:$db:$host", 
            $config->get( 'db.user' ),
            $config->get( 'db.pass' ),
            $schema,
        );
    }

    $self->{_schema};
}

sub table {
    my ($self,$name) = @_;
    
    return if !$name;
    return $self->schema->resultset($name);
}

sub no_permission {
    my ($self,$value) = @_;
    
    $self->{__has_no_permission} = $value if @_ == 2;
    return $self->{__has_no_permission};
}

1;
