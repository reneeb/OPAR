package OTRS::OPR::Web::App::Prerun;

use strict;
use warnings;
use CGI::Application;

use base 'OTRS::OPR::Exporter::Aliased';

our @EXPORT_OK = qw(
    cgiapp_prerun
);

sub cgiapp_prerun {
    my ($self) = @_;

    my $session = $self->session;
    my $runmode = $self->get_current_runmode;
    
    if( $session->is_expired ){
        
        $session->delete;
        
        if( $runmode eq 'logout' ){
            $session->logout;
        }
                
        unless( $runmode =~ m{ \A (?:do_)? login \z }xms ){
            $self->forward( '/login' ) ;
        }
    }
    else{
        my %runmodes = $self->run_modes();
        my $code     = $runmodes{ $runmode};
        
        my $needed_permission = $CGI::Application::__permissions{$code};
        
        # load specific javascript files for each area
        if ( $needed_permission ) {
            $self->stash(
                JS_FILE => ucfirst $needed_permission,
            );
        }
        
        # check if user is allowed to run modes for a specific area
        if ( $needed_permission && !$self->user->has_group( $needed_permission ) ) {
            $self->forward( '/login' );
        }
        
        $session->update_session;
    }
}

1;