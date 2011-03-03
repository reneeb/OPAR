package OTRS::OPR::Web::App;

use strict;
use warnings;

use parent qw(CGI::Application OTRS::OPR::App::Attributes);
use CGI::Application::Plugin::Redirect;

use Data::Dumper;
use DBIx::Class;
use File::Basename;
use JSON;
use Log::Log4perl;
use Path::Class;

use OTRS::OPR::DAO::User;
use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;
use OTRS::OPR::Web::App::Mailer;
use OTRS::OPR::Web::App::Session;
use OTRS::OPR::Web::App::View qw(view);

our $VERSION = 1.0;

my @subdirs = split /::/, __PACKAGE__;
my $libdir  = Path::Class::Dir->new(
    dirname( __FILE__ ),
    ('..') x @subdirs,
);

sub forward {
    my ($self,$uri) = @_;
    
    if ( $uri !~ m{ \A https?: }xms ) {
        $uri = $self->base_url . $uri;
    }
    
    $self->{___is_redirect___} = 1;
    $self->redirect( $uri );
}

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
    
    my $uri = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";
    
    return $uri;
}

sub script_url {
    my ($self,$name) = @_;
    
    $name ||= 'index';
    
    my $script = $ENV{SCRIPT_NAME};
    $script    =~ s{[a-z]*\.cgi}{$name.cgi};
    my $uri    = "http://$ENV{HTTP_HOST}$script";
    
    return $uri;
}

sub session {
    my ($self) = @_;
    
    unless( $self->{___session} ) {
        my $config = $self->config;
        my $expire = $config->get( 'session_expire' ) || 20; # this is in minutes
        
        $expire *= 60; # but we need it in seconds
        
        $self->{___session} = OTRS::OPR::Web::App::Session->new(
            config => $self->config,
            expire => $expire,
            app    => $self,
        );
    }

    $self->{___session};
}

sub json_method {
    my ($self) = @_;
    
    my $runmode  = $self->get_current_runmode;
    my %runmodes = $self->run_modes;
    
    my $code = $runmodes{$runmode};
    return $CGI::Application::__json{$code};
}

sub is_stream {
    my ($self) = @_;
    
    my $runmode  = $self->get_current_runmode;
    my %runmodes = $self->run_modes;
    
    my $code = $runmodes{$runmode};
    return $CGI::Application::__streams{$code};
}

sub user {
    my ($self,$session) = @_;
    
    $session ||= $self->session;
    
    unless( $self->{___user} ) {
        my $session_id = $session->id;
        if( $session_id and not $session->is_expired ){
            $self->logger->trace( 'Get User by Session: ' . $session_id );
            my ($user) = OTRS::OPR::DAO::User->new(
                session_id => $session_id,
                _schema    => $self->schema,
            );
            
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
    
    #print STDERR ">>RUNMODE: ", $self->get_current_runmode,"<<\n";
    
    if ( $self->json_method ) {
        
        # set http header for json output
        $self->header_type( 'none' );
        print $self->query->header( -type => 'application/json' );
        
        # we need a JSON object
        my $json = JSON->new;
        
        # create json output
        $$outref = $json->encode( $$outref );
    }
    elsif ( $self->is_stream and $$outref ) {
        my $type                 = $self->is_stream;
        my $arrayref             = $$outref;
        my ($file_to_read,$name) = @{$arrayref};
        
        $name ||= basename( $file_to_read );
        
        $self->header_type( 'none' );
        print $self->query->header(
            -type                => $type,
            -Content_length      => -s $file_to_read,
            -Content_disposition => 'attachment; filename="' . $name . '"',
        );
        
        if ( open my $fh, '<', $file_to_read ) {
            binmode $fh;
            $$outref = '';
            while ( my $line = <$fh> ) {
                $$outref .= $line;
            }
        }
    }
    elsif (
        $self->get_current_runmode ne 'dummy_redirect' &&
        !$self->{___is_redirect___} ){
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

sub mailer {
    my ($self) = @_;
    
    unless( $self->{__mailer__} ){        
        my $config = $self->config;
        $self->{__mailer__} = OTRS::OPR::Web::App::Mailer->new($config);
    }
    
    return $self->{__mailer__};
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
        my $conf_file = Path::Class::File->new(
            $self->config->get( 'paths.conf' ),
            $self->config->get( 'logging' ),
        );
        Log::Log4perl->init( $conf_file->stringify );
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

1;
