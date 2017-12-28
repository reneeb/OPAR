package Mojolicious::Plugin::OPARConfig;

# ABSTRACT: OPAR config class

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use OTRS::OPR::Web::App::Config;

our $VERSION = 0.02;

sub register {
    my $self = shift;
    my $app  = shift;
    my $conf = shift;

    die ref($self), ': missing file name' if !$conf || !$conf->{file} || !-f $conf->{file};

    $app->attr(
        'config_obj' => sub {
            OTRS::OPR::Web::App::Config->new( $conf->{file} );
        },
    );

    $app->helper( opar_config => sub { return shift->app->config_obj } );
}

1;
__END__

=head1 SYNOPSIS

    use Mojolicious::Plugin::OPARConfig;

    sub startup {
        my $self = shift;

        $self->plugin('OPARConfig' => $config_file);
    }

=head1 CONFIGURATION

=head1 METHODS/HELPERS

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Renee Baecker

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://dev.perl.org/licenses/ for more information.

=cut
