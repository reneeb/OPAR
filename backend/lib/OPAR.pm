package OPAR;

use strict;
use warnings;

use Mojolicious;


sub startup {
    my ($app) = shift;

    $app->plugin(
        OpenAPI => 
    );
}

1;
