package OTRS::OPR::Web::Guest::Package;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Spec;
use OTRS::OPR::Web::App::Forms qw(check_formid get_formid);

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.guest') );
    
    my $startmode = 'start';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD      => \&start,
        comment       => \&feedback,
        send_comment  => \&send_feedback,
        dist          => \&dist,
        author        => \&author,
        oq            => \&oq,
    );
}

sub start {
    my ($self) = @_;
    
    $self->forward( '/' );
}

sub comment {
    my ($self) = @_;
    
    my $form_id = $self->get_formid;
    
    $self->template( 'index_comment_form' );
    $self->stash(
        FORMID => $form_id,
    );
}

sub send_comment {
    my ($self) = @_;
    
    my %params = $self->query->Vars();
    my %errors;
    my $notification_type = 'success';
    
    $errors{formid} = $self->check_formid( $params{formid} );
    
    $notification_type = 'error' if keys %errors;
    $self->notify({
        type    => $notification_type,
        include => 'notifications/comment_' . $notification_type,
    });
    
    my %template_params;
    for my $error_key ( keys %errors ) {
        $template_params{ 'ERROR_' . uc $error_key } = $self->config->get( 'errors.' . $error_key );
    }
    
    $self->template( 'index_comment_sent' );
    $self->stash(
        %template_params,
    );
}

sub dist {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    my ($name,$version) = $package =~ m{
        \A              # string begin
        (\w+)           # package name
        
        (?:                 # do not save match
            -               # dash
            (\d+\.\d+\.\d+) # version number
        )?                  # this is optional
        
        \z              # string end
    }xms;
    
    my $dao = OTRS::OPR::DAO::Package->new(
        package_name => $name,
        version      => $version,
    );
    
    # if package can't be found show error message
    if ( $dao->not_in_db ) {
        $self->notify({
            type    => 'error',
            include => 'notifications/generic_error',
        });
        
        $self->template( '404' );
        $self->stash(
            MESSAGE => $self->config->get( 'error.package_not_found' );
        );
    }
    
    my %stash = $dao->to_hash;
    
    $self->template( 'index_package' );
    $self->stash(
        %stash,
    );
}

sub author {
}

sub oq {
}

1;