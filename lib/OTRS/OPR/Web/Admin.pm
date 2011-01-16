package OTRS::OPR::Web::Admin;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use OTRS::OPR::DB::Helper::User qw(check_credentials);
use OTRS::OPR::Web::App::Prerun;

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.admin') );
    
    my $startmode = 'start';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD => \&start,
        start    => \&start,
        login    => \&login,
        logout   => \&logout,
        do_login => \&do_login,
        menu     => \&menu,
    );
}

sub menu {
    my ($self) = @_;
    
    $self->template( 'admin_menu' );
}

sub start {
    my ($self) = @_;
    
    # redirect to page configured in admin.startpage
    $self->forward( '/' . $self->config->get( 'admin.startpage' ) );
}

sub login {
    my ($self) = @_;
    
    # show the login form
    $self->template( 'admin_login' );
}

sub do_login {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    my $user   = $self->check_credentials( \%params );

    # successful login    
    if( $user ) {
    
        # redirect to page configured in admin.startpage
        $self->forward( '/' . $self->config->get( 'admin.startpage' ) );
        return;
    }
    else {
        
        # show login form and show error message
        $self->notify({
            type    => 'error',
            include => 'notifications/login_unsuccessful',
        });
        $self->login;
    }
}

sub logout {
    my ($self) = @_;
    
    $self->session->logout;
    
    $self->notify({
        type    => 'success',
        include => 'notifications/logout_successful',
    });
    
    $self->login;
}

1;