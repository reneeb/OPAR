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
                
        unless( $self->get_current_runmode =~ m{ \A (?:do_)? login \z }xms ){
            $self->forward( '/login' ) ;
        }
    }
    else{
        $session->update_session;
    }
}

1;