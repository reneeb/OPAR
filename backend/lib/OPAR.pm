package OPAR;

use strict;
use warnings;

use Mojolicious;


sub startup {
    my ($app) = shift;

    $app->plugin(
        JSONConfig => {
            file => $app->home->rel_file( 'conf/opar.json' ),
    });

    $app->plugin(
        OpenAPI => {
            file => $app->home->rel_file( $app->config->{openapi} ),
    });

    $app->plugin( 'RenderFile' );
}

1;
