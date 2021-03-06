package OTRS::OPR::Web::OPAR;

use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use MojoX::GlobalEvents;
use MojoX::Renderer::HTC;
use MojoX::Log::Log4perl;

use Data::Dumper;
use DBIx::Class;
use File::Basename;
use Path::Class;

use OTRS::OPR::DAO::User;
use OTRS::OPR::Web::App::Mailer;
use OTRS::OPR::Web::App::Session;

our $VERSION = 1.0;

sub startup {
    my ($self) = @_;

    $self->home->parse( $ENV{OPAR_APP} );
    $self->static->paths([ $self->home->rel_dir( 'public' )] );
    $self->renderer->paths([ $self->home->rel_dir( 'templates') ]);

    MojoX::GlobalEvents->init( 'OTRS::OPR::App::EventListener' );

    $self->plugin( 
        OPARConfig => {
            file => $ENV{OPAR_CONFIG} ||
                Path::Class->file( $self->home, 'conf', 'base.yml' )->stringify,
        },
    );

    if ( $self->opar_config->get( 'app.reverse_proxy' ) ) {
        $ENV{MOJO_REVERSE_PROXY} = 1;
    }

    $self->secret( $self->opar_config->get( 'app.secret' )  || 'la28gj1o110890582euf9u2$!"HASH{MD5}' );
    $self->app->mode( $self->opar_config->get( 'app.mode' ) || 'development' );

    $self->log(
        MojoX::Log::Log4perl->new(
            File::Spec->catfile(
                $self->opar_config->get( 'paths.conf' ),
                $self->opar_config->get( 'logging' ),
            )
        )
    );

    $self->plugin(
        OPARSchema => { config => $self->opar_config },
    );

    $self->plugin( 'OPARRenderer' );
    $self->plugin( 'RenderFile' );

    $self->helper( mailer   => sub { OTRS::OPR::Web::App::Mailer->new( $self->opar_config ) } );
    $self->helper( base_url => sub {
        my $c   = shift;
        my $url = $c->req->url->to_abs;

        return sprintf "%s://%s", $url->protocol || 'http', $url->host || 'localhost';
    } );

    $self->helper( opar_session => sub {
        my ($c) = @_;
    
        unless( $c->{___session} ) {
            my $config = $c->opar_config;
            my $expire = $config->get( 'session_expire' ) || 20; # this is in minutes
    
            $expire *= 60; # but we need it in seconds
    
            $c->{___session} = OTRS::OPR::Web::App::Session->new(
                expire => $expire,
                app    => $c,
            );
        }
    
        $c->{___session};
    });

    $self->helper( user => sub {
        my ($c,$session) = @_;
    
        $session ||= $c->opar_session;
    
        unless( $c->{___user} ) {
            my $session_id = $session->id;
            if( $session_id and not $session->is_expired ){
                $c->app->log->debug( 'Get User by Session: ' . $session_id );
                my ($user) = OTRS::OPR::DAO::User->new(
                    session_id => $session_id,
                    _schema    => $c->schema,
                );
    
                if( $user ) {
                    $c->{___user} = $user;
                    $c->stash( __LOGGEDIN__ => $user->user_name );
                }
            }
        }
    
        $c->{___user};
    });

    $self->types->type(tmpl => 'text/html');
 
    # a map of the routes we have. The key is the controller module
    # that handles the request. the key in the subhash is the "URL"
    # the visitor requests and the value for those URLs is the
    # subroutine in the controller module.
    my %routes = (
        'guest' => {
            '/'                                         => [ 'Guest',               'start'                   ],
            '/repo'                                     => [ 'Guest::Repo',         'add_form'                ],
            '/repo/add'                                 => [ 'Guest::Repo',         'add'                     ],
            '/repo/search'                              => [ 'Guest::Repo',         'search'                  ],
            '/repo/:id/manage'                          => [ 'Guest::Repo',         'manage'                  ],
            '/repo/manage'                              => [ 'Guest::Repo',         'manage'                  ],
            '/repo/:id/save'                            => [ 'Guest::Repo',         'save'                    ],
            '/repo/:id/file'                            => [ 'Guest::Repo',         'file'                    ],
            '/repo/:id/file/*file'                      => [ 'Guest::Repo',         'file'                    ],
            '/dist/*package'                            => [ 'Guest::Package',      'dist'                    ],
            '/package/:initial/:short/:author/*package' => [ 'Guest::Package',      'dist'                    ],
            '/package/comment/*id'                      => [ 'Guest::Package',      'comment'                 ],
            '/package/send_comment/*id'                 => [ 'Guest::Package',      'send_comment'            ],
            '/package/download/*id'                     => [ 'Guest::Package',      'download'                ],
            '/package/author/*id'                       => [ 'Guest::Package',      'author'                  ],
            '/recent'                                   => [ 'Guest::Package',      'recent_packages'         ],
            '/registration/'                            => [ 'Guest::Registration', 'start'                   ],
            '/registration/send'                        => [ 'Guest::Registration', 'send_registration'       ],
            '/registration/confirm'                     => [ 'Guest::Registration', 'confirm'                 ],
            '/registration/forgot_passwd'               => [ 'Guest::Registration', 'forgot_password'         ],
            '/registration/send_passwd'                 => [ 'Guest::Registration', 'send_new_password'       ],
            '/registration/change_passwd'               => [ 'Guest::Registration', 'change_passwd'           ],
            '/registration/confirm_passwd'              => [ 'Guest::Registration', 'confirm_password_change' ],
            '/static/:page'                             => [ 'Guest',               'static'                  ],
            '/search/:page'                             => [ 'Guest',               'search'                  ],
            '/search/'                                  => [ 'Guest',               'search'                  ],
            '/authors/:initial/:short'                  => [ 'Guest',               'authors'                 ],
            '/authors/:initial'                         => [ 'Guest',               'authors'                 ],
            '/authors/'                                 => [ 'Guest',               'authors'                 ],
            '/feedback'                                 => [ 'Guest',               'feedback'                ],
            '/login'                                    => [ 'Guest',               'login'                   ],
            '/do_login'                                 => [ 'Guest',               'do_login'                ],
            '/logout'                                   => [ 'Guest',               'logout'                  ],
            '/send_feedback'                            => [ 'Guest',               'send_feedback'           ],
        },
        'author' => {
            '/author'                                => [ 'Author::Package', 'list_packages'     ],
            '/author/package/comments/'              => [ 'Author::Package', 'comments'          ],
            '/author/package/comments/:package'      => [ 'Author::Package', 'comments'          ],
            '/author/package/comment/publish/:id'    => [ 'Author::Package', 'publish_comment'   ], 
            '/author/package/comment/unpublish/:id'  => [ 'Author::Package', 'unpublish_comment' ], 
            '/author/package/comment/delete/:id'     => [ 'Author::Package', 'delete_comment'    ],
            '/author/package/delete/:id'             => [ 'Author::Package', 'delete_package'    ],
            '/author/package/meta/:id'               => [ 'Author::Package', 'edit_package_meta' ],
            '/author/package/meta/:id/save'          => [ 'Author::Package', 'save_package_meta' ],
            '/author/package/undelete/:id'           => [ 'Author::Package', 'undelete_package'  ],
            '/author/package/reanalyze/:id'          => [ 'Author::Package', 'reanalyze_package' ],
            '/author/package/versions/:package'      => [ 'Author::Package', 'version_list'      ],
            '/author/package/:id/show'               => [ 'Author::Package', 'package_show'      ],
            '/author/package/list'                   => [ 'Author::Package', 'list_packages'     ],
            '/author/package/list/:page'             => [ 'Author::Package', 'list_packages'     ],
            '/author/package/upload'                 => [ 'Author::Package', 'upload_package'    ],
            '/author/package/do_upload'              => [ 'Author::Package', 'do_upload_package' ],
            '/author/tags'                           => [ 'Author::Package', 'get_tags'          ],
            '/author/package/maintainer/:id'         => [ 'Author::Package', 'maintainer'        ],
            '/author/package/maintainer/:id/edit'    => [ 'Author::Package', 'edit_maintainer'   ],
            '/author/profile'                        => [ 'Author::Profile', 'show'              ],
            '/author/profile/edit'                   => [ 'Author::Profile', 'edit'              ],
            '/author/profile/save'                   => [ 'Author::Profile', 'save'              ],
        },
    );

    $self->routes->namespaces( [ 'OTRS::OPR::Web' ] );

    # we need different route handlers as some areas need a login
    # so we have bridges to the Auth-Controller that checks if the
    # user is logged in before the final runmode is executed
    my %route_handler = (
        guest  => $self->routes->bridge( '/' )->to( cb => sub{ return 1 } ),
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

    # add hook to show own error pages
    $self->hook( after_dispatch => sub {
        my $c = shift;
        my $code = $c->res->code;

        my %templates = (
            404 => 'not_found',
            500 => 'exception',
        );

        my $template = $templates{ $c->res->code };
        if ( $template && $self->app->mode ne 'development' ) {
            $c->notify({
                type           => 'error',
                include        => 'notifications/generic_error',
                ERROR_HEADLINE => $c->opar_config->get( 'errors.' . $code . '.headline' ),
                ERROR_MESSAGE  => $c->opar_config->get( 'errors.' . $code . '.message' ),
            });

            my $html = $c->render_opar( 'blank' );
            $c->render( text => $html, format => 'html' );
        }
    } );
}

1;
