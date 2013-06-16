package Mojolicious::Plugin::OPARRenderer;

# ABSTRACT: OPAR config class

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use HTML::Template::Compiled;

our $VERSION = 0.02;

sub register {
    my $self = shift;
    my $app  = shift;

    $app->helper( notify => sub {
        my ($self,$params) = @_;

        if ( $params and ref $params eq 'HASH' ) {
            push @{$self->{__notifications}}, $params;
        }

        return $self->{__notifications};
    });

    $app->helper( render_opar   => sub {
        my ($obj, $template) = @_;
        $self->_my_renderer( $app, $obj, $template );
    });
}

sub _my_renderer {
    my ($self, $app, $obj, $template) = @_;

    my $main_tmpl = $obj->stash->{main_template};
    my $config    = $app->opar_config;

    my $test      = defined $main_tmpl ? $main_tmpl : $config->get('templates.base');

    my $tmpl_path = $config->get( 'paths.base' ) . $config->get( 'paths.templates' );
    my $basetmpl  = $tmpl_path . $test;

    my $tmpl = HTML::Template::Compiled->new(
        filename       => $basetmpl,
        default_escape => 'html',
        use_query      => 1,
    );

    my %notifications;
    my $registered_notifications = $obj->notify;

    $notifications{NOTIFICATIONS} = $registered_notifications || [];

    for my $notification ( @{ $notifications{NOTIFICATIONS} } ) {
        $notification->{include} = $tmpl_path . $notification->{include} . '.tmpl';
    }

    $template .= '.tmpl' if $template !~ m{\.tmpl\z}xms;

    my $username = '';
    #$username = $self->user->user_name if $self->user;

    my @version_list = $app->table( 'opr_framework_versions' )->search(
        {},
        { order_by => 'framework', }
    );

    my @frameworks = map{ { VERSION => $_->framework } }@version_list;

    $tmpl->param(
        BODY         => $tmpl_path . $template,
        __AUTHOR__   => '/author',
        __ADMIN__    => '/admin',
        __LOGGEDIN__ => $username,
        frameworks   => \@frameworks,
        %{$obj->stash},
        %notifications,
    );

    $app->log->error( 'params set' );
    my $html = $tmpl->output;
    $app->log->error( 'output generated' );

    return $html;
}

1;
__END__

=head1 SYNOPSIS

    use Mojolicious::Plugin::OPARRenderer;

    sub startup {
        my $self = shift;

        $self->plugin('OPARRenderer' => $config_file);
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
