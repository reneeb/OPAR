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

    $self->helper( mailer   => sub { OTRS::OPR::Web::App::Mailer->new( $self->opar_config ) } );
    $self->helper( base_url => sub {
        my $c   = shift;
        my $url = $c->req->url->to_abs;

        return sprintf "%s://%s/", $url->protocol || 'http', $url->host || 'localhost';
    } );

    $self->helper( opar_session => sub {
        my ($c) = @_;
    
        unless( $c->{___session} ) {
            my $config = $c->opar_config;
            my $expire = $config->get( 'session_expire' ) || 20; # this is in minutes
    
            $expire *= 60; # but we need it in seconds
    
            $c->{___session} = OTRS::OPR::Web::App::Session->new(
                config => $config,
                expire => $expire,
                app    => $c,
                schema => $c->schema,
            );
        }
    
        $c->{___session};
    });

    $self->helper( user => sub {
        my ($c,$session) = @_;
    
        $session ||= $c->opar_session;
    
        unless( $c->{___user} ) {
            my $session_id = $session->id;
$c->app->log->debug( "SessionID: $session_id" );
            if( $session_id and not $session->is_expired ){
                $c->app->log->debug( 'Get User by Session: ' . $session_id );
                my ($user) = OTRS::OPR::DAO::User->new(
                    session_id => $session_id,
                    _schema    => $c->schema,
                );
    
                if( $user ) {
                    $c->{___user} = $user;
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
            '/registration/change_passwd'               => [ 'Guest::Registration', 'change_password'         ],
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
            '/author/package/comments/publish/:id'   => [ 'Author::Package', 'publish_comment'   ], 
            '/author/package/comments/unpublish/:id' => [ 'Author::Package', 'publish_comment'   ], 
            '/author/package/comments/delete/:id'    => [ 'Author::Package', 'delete_comment'    ],
            '/author/package/delete'                 => [ 'Author::Package', 'delete_package'    ],
            '/author/package/undelete'               => [ 'Author::Package', 'undelete_package'  ],
            '/author/package/reanalyze'              => [ 'Author::Package', 'reanalyze_package' ],
            '/author/package/versions/:package'      => [ 'Author::Package', 'version_list'      ],
            '/author/package/:id/show'               => [ 'Author::Package', 'package_show'      ],
            '/author/package/list'                   => [ 'Author::Package', 'list_packages'     ],
            '/author/package/upload'                 => [ 'Author::Package', 'upload_package'    ],
            '/author/package/do_upload'              => [ 'Author::Package', 'do_upload_package' ],
            '/author/tags'                           => [ 'Author::Package', 'get_tags'          ],
            '/author/maintainer/:id'                 => [ 'Author::Package', 'maintainer'        ],
            '/author/maintainer/:id/edit'            => [ 'Author::Package', 'maintainer_edit'   ],
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
}

1;
