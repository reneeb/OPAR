package OTRS::OPR::Web::Admin::Misc;

use strict;
use warnings;

use base qw(OTRS::OPR::Web::App);
use CGI::Application::Plugin::Redirect;

use OTRS::OPR::DAO::User;

use OTRS::OPR::Web::App::Session;

sub cgiapp_prerun{
    my ($self) = @_;

    my $session = OTRS::OPR::Web::App::Session->new;
    if( $session->is_expired ){
        $session->delete;
        if( $self->get_current_runmode eq 'logout' ){
            $session->logout;
        }
        my $index    = $self->_config->{admin};
        $ENV{HTTP_HOST} ||= 'perlnews';
        my $url      = 'http://' . $ENV{HTTP_HOST} . $index . '/login';
        unless( $self->get_current_runmode eq 'login' ){
            $self->redirect( $url ) ;
        }
    }
    else{
        $session->update_session;
        $self->user( $session );
    }
}

1;