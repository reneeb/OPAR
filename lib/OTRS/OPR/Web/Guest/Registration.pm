package OTRS::OPR::Web::Guest::Registration;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use Captcha::reCAPTCHA;
use OTRS::OPR::DAO::User;
use OTRS::OPR::DB::Helper::Passwd qw(:all);
use OTRS::OPR::Web::App::Forms qw(:all);

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
        AUTOLOAD       => \&start,
        start          => \&start,
        send           => \&send,
        confirm        => \&confirm,
        forgot_passwd  => \&forgot_password,
        send_passwd    => \&send_new_password,
        change_passwd  => \&change_passwd,
        confirm_passwd => \&confirm_password_change,
    );
}

sub start {
    my ($self) = @_;
    
    $self->logger->trace( 'Registration form' );
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key = $self->config->get( 'recaptcha.public_key' );
    my $html       = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;

    my @js_help;    
    for my $key ( qw(username email) ) {
        my $config_key = 'registration.' . $key;
        push @js_help, {
            NAME  => $config_key,
            VALUE => $self->config->get( 'help.' . $config_key ),
        };
    }
    
    $self->template( 'index_registration' );
    $self->stash(
        CAPTCHA => $html,
        FORMID  => $formid,
        JSHELP  => \@js_help,
    );
}

sub send {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    
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
            ERROR_HEADLINE => $self->config->get( 'errors.username_exists.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.username_exists.message' ),
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
    
    $self->template( 'blank' );
    
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
}

sub forgot_password {
    my ($self) = @_;
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key = $self->config->get( 'recaptcha.public_key' );
    my $html       = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;
    $self->template( 'index_forgot_password' );
    $self->stash(
        FORMID  => $formid,
        CAPTCHA => $html,
    );
}

sub send_new_password {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    
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
    
    my $config = $self->config;
    
    my $mail_sent = $self->_send_mail_to_user( $user );
    
    $self->template( 'blank' );
    
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
}

sub change_passwd {
    my ($self, %params) = @_;
    
    %params = $self->query->Vars if !%params;
    
    if ( !$params{token} ) {
        return $self->start;
    }
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key = $self->config->get( 'recaptcha.public_key' );
    my $html       = $captcha->get_html( $public_key );
    
    my $formid = $self->get_formid;
    
    $self->template( 'index_change_password' );
    $self->stash(
        TOKEN   => $params{token},
        FORMID  => $formid,
        #CAPTCHA => $html,
        %params,
    );
}

sub confirm_password_change {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    
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
    
    my $crypted_passwd = crypt $params{password}, $self->config->get( 'password.salt' );
    $user->user_password( $crypted_passwd );
    $user->active( 1 );
    $user->add_group( 'author' => 1 );
    
    $self->delete_temp_passwd( \%params );
    
    $self->template( 'blank' );
    $self->notify({
        type             => 'success',
        include          => 'notifications/generic_success',
        SUCCESS_HEADLINE => 'Your changes were applied!',
        SUCCESS_MESSAGE  => 'New password was set!',
    });
}

sub _send_mail_to_user {
    my ($self,$user,$opt) = @_;
    
    my $config = $self->config;
    
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