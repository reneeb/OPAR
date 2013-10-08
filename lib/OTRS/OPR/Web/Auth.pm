package OTRS::OPR::Web::Auth;

# ABSTRACT: Bridges for actions that need authentication

use Mojo::Base 'Mojolicious::Controller';

sub author {
    my $self = shift;

    my $user  = $self->user;

    if ( $user and $user->has_group( 'author' ) ) {
        $self->opar_session->update_session;
        $self->stash( main_template => $self->opar_config->get( 'templates.author' ) );
        return 1;
    }

    my $current_path = $self->req->url->path;
    $current_path    =~ s{^/}{};

    $self->redirect_to( '/login?redirect_to=' . $current_path );
    return 0;
}

1;

