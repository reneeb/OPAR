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
        menu     => \&menu,
        
        # imported subroutines
        login    => sub{ shift->login( 'admin_login' ) },
        do_login => sub{ shift->do_login( 'admin.startpage' ) },
        logout   => \&logout,
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

1;