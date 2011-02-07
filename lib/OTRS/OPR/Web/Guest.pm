package OTRS::OPR::Web::Guest;

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
        start         => \&start,
        feedback      => \&feedback,
        send_feedback => \&send_feedback,
        static        => \&static,
        recent        => \&recent,
    );
}

sub start {
    my ($self) = @_;
    
    $self->template( 'index_home' );
}

sub feedback {
    my ($self) = @_;
    
    my $form_id = $self->get_formid;
    
    $self->template( 'index_feedback_form' );
    $self->stash(
        FORMID => $form_id,
    );
}

sub send_feedback {
    my ($self) = @_;
    
    my %params = $self->query->Vars();
    my %errors;
    my $notification_type = 'success';
    
    # check if form has a valid id
    $errors{formid} = 1 if !$self->check_formid( $params{formid} );
    
    $notification_type = 'error' if keys %errors;
    $self->notify({
        type    => $notification_type,
        include => 'notifications/feedback_' . $notification_type,
    });
    
    # TODO: check userinput
    
    # show errors in template
    my %template_params;
    for my $error_key ( keys %errors ) {
        $template_params{ 'ERROR_' . uc $error_key } = $self->config->get( 'errors.' . $error_key );
    }
    
    $self->template( 'index_feedback_sent' );
    $self->stash(
        %template_params,
    );
}

sub static {
    my ($self) = @_;
    
    my $page       = $self->param( 'page' ) || '';
    
    $page =~ s{[^a-z_]}{}g;
    $page .= '.tmpl';
    
    my $config = $self->config;
    
    my $path = File::Spec->catfile(
        $config->get( 'paths.base' ),
        $config->get( 'paths.templates' ),
        'static',
        $page,
    );
    
    if ( !$page or !-f $path ) {
        $page = $self->config->get( 'defaults.static' );
    }
    
    $self->template( 'static/' . $page );
}

1;