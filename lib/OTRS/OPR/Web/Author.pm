package OTRS::OPR::Web::Author;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Spec;
use OTRS::OPR::Web::App::Forms qw(check_formid get_formid);
use OTRS::OPR::Web::App::Login;
use OTRS::OPR::Web::App::Prerun;

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.author') );
    
    my $startmode = 'start';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD    => \&start,
        start       => \&start,
        register    => \&register,
        do_register => \&do_register,
        
        # imported subroutines
        login       => sub{ shift->login( 'author_login' ) },
        do_login    => sub{ shift->do_login( 'author.startpage' ) },
        logout      => \&logout,
    );
}

sub start {
    my ($self) = @_;
    
    $self->template( 'author_home' );
}

1;