package OTRS::OPR::Web::OPAR;

use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use MojoX::Renderer::HTC;

use Data::Dumper;
use DBIx::Class;
use File::Basename;
use Log::Log4perl;
use Path::Class;

use OTRS::OPR::DAO::User;
use OTRS::OPR::Web::App::Mailer;
use OTRS::OPR::Web::App::Session;
use OTRS::OPR::Web::App::View qw(view);

our $VERSION = 1.0;

sub startup {
    my ($self) = @_;

    $self->home->parse( $ENV{OPAR_APP} );
    $self->static->paths([ $self->home->rel_dir( 'public' )] );
    $self->renderer->paths([ $self->home->rel_dir( 'templates') ]);

    $self->plugin( 
        OPARConfig => {
            file => $ENV{OPAR_CONFIG} ||
                Path::Class->file( $self->home, 'conf', 'base.yml' )->stringify,
        },
    );

    $self->plugin(
        OPARSchema => { config => $self->opar_config },
    );

    $self->plugin( 'OPARRenderer' );
    $self->plugin( 'RenderFile' );

    $self->types->type(tmpl => 'text/html');
 
    # a map of the routes we have. The key is the controller module
    # that handles the request. the key in the subhash is the "URL"
    # the visitor requests and the value for those URLs is the
    # subroutine in the controller module.
    my %routes = (
        'guest' => {
            '/'                                         => [ 'Guest', 'start' ],
            '/repo'                                     => [ 'Guest::Repo', 'add_form' ],
            '/repo/add'                                 => [ 'Guest::Repo', 'add' ],
            '/repo/:id/manage'                          => [ 'Guest::Repo', 'manage' ],
            '/repo/:id/save'                            => [ 'Guest::Repo', 'save' ],
            '/repo/:id/file/:file'                      => [ 'Guest::Repo', 'file' ],
            '/static/:page'                             => [ 'Guest', 'static' ],
            '/dist/:package'                            => [ 'Guest::Package', 'dist' ],
            '/package/:initial/:short/:author/:package' => [ 'Guest::Package', 'dist' ],
            '/package/comment/:id'                      => [ 'Guest::Package', 'comment' ],
            '/package/send_comment/:id'                 => [ 'Guest::Package', 'send_comment' ],
            '/package/download/:id'                     => [ 'Guest::Package', 'download' ],
            '/package/author/:id'                       => [ 'Guest::Package', 'author' ],
            '/recent'                                   => [ 'Guest::Package', 'recent_packages' ],
            '/search/:page'                             => [ 'Guest', 'search' ],
            '/search/'                                  => [ 'Guest', 'search' ],
            '/registration/'                            => [ 'Guest::Registration', 'start' ],
            '/registration/send'                        => [ 'Guest::Registration', 'send' ],
            '/registration/confirm'                     => [ 'Guest::Registration', 'confirm' ],
            '/registration/forgot_passwd'               => [ 'Guest::Registration', 'forgot_password' ],
            '/registration/send_passwd'                 => [ 'Guest::Registration', 'send_new_password' ],
            '/registration/change_passwd'               => [ 'Guest::Registration', 'change_password' ],
            '/registration/confirm_passwd'              => [ 'Guest::Registration', 'confirm_password_change' ],
            '/authors/:initial/:short'                  => [ 'Guest', 'authors' ],
            '/authors/:initial'                         => [ 'Guest', 'authors' ],
            '/authors/'                                 => [ 'Guest', 'authors' ],
            '/feedback'                                 => [ 'Guest', 'feedback' ],
            '/send_feedback'                            => [ 'Guest', 'send_feedback' ],
        },
    );

    $self->routes->namespaces( [ 'OTRS::OPR::Web' ] );

    # we need different route handlers as some areas need a login
    # so we have bridges to the Auth-Controller that checks if the
    # user is logged in before the final runmode is executed
    my %route_handler = (
        guest  => $self->routes->bridge( '/' )->to( cb => sub{ return 1 } ),
        admin  => $self->routes->bridge( '/' )->to( 'auth#admin' ),
        author => $self->routes->bridge( '/' )->to( 'auth#author' ),
    );

    # create the routes in Mojolicious for each route defined in the map
    for my $area ( keys %routes ) {
        for my $url ( keys %{ $routes{$area} } ) {
            my ($module, $action) = @{ $routes{$area}->{$url} };
            my $handler           = $route_handler{$area};
            $handler->route($url)->to( controller => $module, action => $action );
        }
    }

    # add content-type for xml data
    $self->types->type( xml => 'application/octet-stream' );
}

sub opar_session {
    my ($self) = @_;
    
    unless( $self->{___session} ) {
        my $config = $self->config;
        my $expire = $config->get( 'session_expire' ) || 20; # this is in minutes
        
        $expire *= 60; # but we need it in seconds
        
        $self->{___session} = OTRS::OPR::Web::App::Session->new(
            config => $self->config,
            expire => $expire,
            app    => $self,
            schema => $self->schema,
        );
    }

    $self->{___session};
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

sub mailer {
    my ($self) = @_;
    
    unless( $self->{__mailer__} ){        
        my $config = $self->config;
        $self->{__mailer__} = OTRS::OPR::Web::App::Mailer->new($config);
    }
    
    return $self->{__mailer__};
}

1;
