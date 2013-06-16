package OTRS::OPR::Web::App::Prerun;

use strict;
use warnings;

use B;
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

        my $name     = _coderef2name( $code );
        
        my $needed_permission = $CGI::Application::__permissions{$name};
        
        # check if user is allowed to run modes for a specific area
        if ( $needed_permission && !$self->user->has_group( $needed_permission ) ) {
            $self->forward( '/login' );
        }
        
        $session->update_session;
    }
}

sub _coderef2name {
    my ($ref) = @_;

    eval {
        my $obj = B::svref_2object( $ref );
        '*' . $obj->GV->STASH->NAME . '::' . $obj->GV->NAME;
    } || undef;
}

1;
