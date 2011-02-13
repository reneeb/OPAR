package OTRS::OPR::Web::App::Login;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT = qw(login do_login logout);

sub logout {
    my ($self) = @_;
    
    $self->session->logout;
    
    $self->notify({
        type    => 'success',
        include => 'notifications/logout_successful',
    });
    
    $self->login;
}

sub login {
    my ($self,$template) = @_;
    
    $self->logger->trace( 'Loginform' );
    
    # show the login form
    $self->template( $template );
}

sub do_login {
    my ($self,$forward,$template) = @_;
    
    $self->logger->trace( 'do_login' );
    
    my %params = $self->query->Vars;
    
    $self->logger->debug( "$params{user} tries to login" );
    my $user   = $self->check_credentials( \%params );

    # successful login    
    if( $user ) {
    
        # redirect to page configured in admin.startpage
        $self->logger->trace( "Forward to $forward" );
        $self->forward( '/' . $self->config->get( $forward ) );
        return;
    }
    else {
        
        # show login form and show error message
        $self->notify({
            type    => 'error',
            include => 'notifications/login_unsuccessful',
        });
        $self->login( $template );
    }
}

1;