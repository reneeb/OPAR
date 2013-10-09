package OTRS::OPR::Web::Guest::Registration;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use Captcha::reCAPTCHA;
use Crypt::SaltedHash;

use OTRS::OPR::DAO::User;
use OTRS::OPR::DB::Helper::Passwd qw(:all);
use OTRS::OPR::Web::App::Forms qw(:all);

sub start {
    my ($self) = @_;
    
    $self->app->log->debug( 'Registration form' );
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key   = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;

    my @js_help;    
    for my $key ( qw(username email) ) {
        my $config_key = 'registration.' . $key;
        push @js_help, {
            NAME  => $config_key,
            VALUE => $self->opar_config->get( 'help.' . $config_key ),
        };
    }
    
    $self->stash(
        CAPTCHA => $captcha_html,
        FORMID  => $formid,
        JSHELP  => \@js_help,
    );

    my $html = $self->render_opar( 'index_registration' );
    $self->render( text => $html, format => 'html' );
}

sub send_registration {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    
    # check captcha
    my $success = $self->validate_captcha( \%params );
    if ( !$success ) {
        return $self->start;
    }
    
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        return $self->start;
    }
    
    # validate user input
    my %errors = $self->validate_fields( 'registration.yml', \%params );
    if ( %errors ) {
        return $self->start( %params, %errors );
    }
    
    if ( $params{email} ne $params{emailcheck} ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Mail addresses not identical',
            ERROR_MESSAGE  => 'The mail address you submitted are not identical.',
        });
        return $self->start( %params );
    }
    
    # create user
    my $user = OTRS::OPR::DAO::User->new(
        user_name => $params{username},
        _schema   => $self->schema,
    );
    
    # show error if username already exists
    if ( !$user->not_in_db ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.username_exists.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.username_exists.message' ),
        });
        return $self->start( %params, %errors );
    }
    
    # set attributes
    $user->user_name( $params{username} );
    $user->mail( $params{email} );
    $user->registered( time );
    
    $user->save;
    
    # send mail to user with token to set password ({register => 1})
    my $mail_sent = $self->_send_mail_to_user( $user, {register => 1} );
    
    if ( $mail_sent ) {
        $self->notify({
            type             => 'success',
            include          => 'notifications/generic_success',
            SUCCESS_HEADLINE => 'Sent Mail!',
            SUCCESS_MESSAGE  => 'We have sent an email to you with further instructions',
        });
    }
    else {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Cannot send mail!',
            ERROR_MESSAGE  => 'Some problems with our mailsystem occured. Please try later again.',
        });
    }

    my $html = $self->render_opar( 'blank' );
    $self->render( text => $html, format => 'html' );
}

sub forgot_password {
    my ($self) = @_;
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key   = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;
    $self->stash(
        FORMID  => $formid,
        CAPTCHA => $captcha_html,
    );

    my $html = $self->render_opar( 'index_forgot_password' );
    $self->render( text => $html, format => 'html' );
}

sub send_new_password {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        return $self->forgot_password;
    }
    
    # check captcha
    my $success = $self->validate_captcha( \%params );
    if ( !$success ) {
        return $self->forgot_password;
    }
    
    # check username
    my $user = OTRS::OPR::DAO::User->new(
        user_name => $params{username},
        _schema   => $self->schema,
    );
    
    if ( $user->not_in_db ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Error',
            ERROR_MESSAGE  => 'The username does not exist',
        });
        return $self->forgot_password;
    }
    
    my $config = $self->opar_config;
    
    my $mail_sent = $self->_send_mail_to_user( $user );
    
    
    if ( $mail_sent ) {
        $self->notify({
            type             => 'success',
            include          => 'notifications/generic_success',
            SUCCESS_HEADLINE => 'Sent Mail!',
            SUCCESS_MESSAGE  => 'We have sent an email to you with further instructions',
        });
    }
    else {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Cannot send mail!',
            ERROR_MESSAGE  => 'Some problems with our mailsystem occured. Please try later again.',
        });
    }

    my $html = $self->render_opar( 'blank' );
    $self->render( text => $html, format => 'html' );
}

sub change_passwd {
    my ($self, %params) = @_;
    
    %params = %{ $self->req->params->to_hash || {} } if !%params;
    
    if ( !$params{token} ) {
        return $self->start;
    }
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key   = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;
    
    $self->stash(
        TOKEN   => $params{token},
        FORMID  => $formid,
        #CAPTCHA => $captcha_html,
        %params,
    );

    my $html = $self->render_opar( 'index_change_password' );
    $self->render( text => $html, format => 'html' );
}

sub confirm_password_change {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        return $self->start;
    }
    
    # check userinput
    my %errors = $self->validate_fields( 'confirm_password_change.yml', \%params );
    if ( %errors ) {
        return $self->change_passwd( %params, %errors );
    }
    
    if ( $params{password} ne $params{password_check} ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'New Password needed!',
            ERROR_MESSAGE  => 'The given password and the password check were not identical!',
        });
        return $self->change_passwd( %params, 'ERROR_PASSWORD' => 'error' );
    }
    
    # check token
    my $is_valid = $self->check_temp_passwd( \%params );
    if ( !$is_valid ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Invalid Token!',
            ERROR_MESSAGE  => 'The token is no longer valid or it was given to some other user!',
        });
        return $self->change_passwd( %params, 'ERROR_TOKEN' => 'error' );;
    }
    
    # change password and set active = 1
    my $user = OTRS::OPR::DAO::User->new(
        user_id => $is_valid,,
        _schema => $self->schema,
    );
    
    my $crypted_passwd = Crypt::SaltedHash->new(
        algorithm => 'SHA-256',
    )->add( $params{password} )->generate;

    $user->user_password( $crypted_passwd );
    $user->active( 1 );
    $user->add_group( 'author' => 1 );
    
    $self->delete_temp_passwd( \%params );
    
    $self->notify({
        type             => 'success',
        include          => 'notifications/generic_success',
        SUCCESS_HEADLINE => 'Your changes were applied!',
        SUCCESS_MESSAGE  => 'New password was set!',
    });

    my $html = $self->render_opar( 'blank' );
    $self->render( text => $html, format => 'html' );
}

sub _send_mail_to_user {
    my ($self,$user,$opt) = @_;
    
    my $config = $self->opar_config;
    
    # generate temp password with get_formid
    # but expiration time is longer than for simple forms
    my $expire = $config->get( 'formid.passwd_expire' ) || 1200;
    my $formid = $self->get_formid;
    
    # add entry to db
    $self->temp_passwd({
        token   => $formid,
        created => time,
        user_id => $user->user_id,
    });
    
    my $template_name = ( $opt and $opt->{register} ) ? 'registration' : 'forgot_password';
    
    # send mail to user
    my $mailer = $self->mailer;
    $mailer->prepare_mail(
        $template_name,
        TOKEN  => $formid,
        URL    => $self->base_url,
        USER   => $user->user_name,
    );
    
    my $subject = 
        $config->get( 'mail.tag' ) . ' ' . 
        $config->get( 'mail.subjects.' . $template_name );
    
    my $success = $mailer->send_mail(
        to      => $user->mail,
        subject => $subject,
    );
}

1;
