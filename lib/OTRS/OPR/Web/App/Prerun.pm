package OTRS::OPR::Web::App::Prerun;

use strict;
use warnings;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    cgiapp_prerun
);

sub cgiapp_prerun {
    my ($self) = @_;

    my $session = $self->session;
    
    if( $session->is_expired ){
        
        $session->delete;
        
        if( $self->get_current_runmode eq 'logout' ){
            $session->logout;
        }
        
        my $script   = '';
        
        $ENV{HTTP_HOST} ||= 'perlnews';
        my $url      = 'http://' . $ENV{HTTP_HOST} . $script . '/login';
        
        unless( $self->get_current_runmode eq 'login' ){
            $self->redirect( $url ) ;
        }
    }
    else{
        $session->update_session;
    }
}

1;