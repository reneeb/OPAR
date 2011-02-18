package OTRS::OPR::Web::Guest::Registration;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use Captcha::reCAPTCHA;
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
        send          => \&send,
        confirm       => \&confirm,
        forgot_passwd => \&forgot_passwd,
        change_passwd => \&change_passwd,
    );
}

sub start {
    my ($self) = @_;
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key = $self->config->get( 'recaptcha.public_key' );
    my $html       = $captcha->get_html( $public_key );
    
    $self->template( 'index_registration' );
    $self->stash(
        CAPTCHA => $html,
    );
}

sub send {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    
    my $captcha = Captcha::reCAPTCHA->new;
    my $result  = $captcha->check_answer(
        $self->config->get( 'recaptcha.private_key' ),
        $ENV{REMOTE_ADDR},
        $params{recaptcha_challenge_field},
        $params{recaptcha_response_field},
    );
    
    if ( !$result->{is_valid} ) {
        
        # show registration form again with error message
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Captcha wrong!',
            ERROR_MESSAGE  => 'Your solution of the captcha was wrong!',
        });
        
        $self->start;
        
        return;
    }
    
    # validate user input
    
    # create user
    my $user = OTRS::OPR::DAO::User->new(
        _schema => $self->schema,
    );
    
    # set attributes
    
    # send mail to user with token to set password
    
    # show success message
}

1;