package OTRS::OPR::Web::Guest;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use Data::Tabulate;
use File::Spec;
use OTRS::OPR::DB::Helper::Author  { list => 'author_list' };
use OTRS::OPR::DB::Helper::Package qw(page);
use OTRS::OPR::DB::Helper::User    qw(check_credentials);
use OTRS::OPR::Web::App::Forms     qw(:all);
use OTRS::OPR::Web::Utils          qw(prepare_select page_list);

sub start {
    my ($self) = @_;
    
    my $html = $self->render_opar( 'index_home' );
    $self->render( text => $html, format => 'html' )
}

sub authors {
    my ($self) = @_;
    
    my $short   = $self->param( 'short' )   || undef;
    my $initial = $self->param( 'initial' ) || undef;
    
    my @authors   = $self->author_list( initial => $initial, short => $short, active => 1 );
    my $tabulator = Data::Tabulate->new;
    
    $tabulator->max_columns( 6 );
    $tabulator->min_columns( 3 );
    
    @authors = map{ { NAME => $_, LISTURL => $short, INITIAL => $initial } }@authors;

    @authors = $tabulator->tabulate( @authors );
    @authors = map{ { INNER => $_ } }@authors;
    
    $self->stash(
        AUTHORS  => \@authors,
    );

    my $html = $self->render_opar( 'index_authors' );
    $self->render( text => $html, format => 'html' )
}

sub feedback {
    my ($self,%params) = @_;
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key   = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html = $captcha->get_html( $public_key );
    
    my $form_id = $self->get_formid;
    
    $self->stash(
        %params,
        FORMID  => $form_id,
        CAPTCHA => $captcha_html,
    );

    my $html = $self->render_opar( 'index_feedback_form' );
    $self->render( text => $html, format => 'html' )
}

sub send_feedback {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        return $self->feedback( %params );
    }
    
    # check captcha
    my $captcha_valid = $self->validate_captcha( \%params );
    if ( !$captcha_valid ) {
        return $self->feedback( %params );
    }
    
    # check userinput
    my %errors = $self->validate_fields( 'feedback.yml', \%params );
    if ( %errors ) {
        return $self->feedback( %params, %errors );
    }
    
    my $success = $self->_send_feedbackmail( %params );
    if ( $success ) {
        $self->notify({
            type             => 'success',
            include          => 'notifications/generic_success',
            SUCCESS_HEADLINE => 'Sent Mail!',
            SUCCESS_MESSAGE  => 'Thanks for your feedback!',
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
    $self->render( text => $html, format => 'html' )
}

sub static {
    my ($self) = @_;
    
    my $page       = $self->param( 'page' ) || '';
    
    $page =~ s{[^a-z_]}{}g;
    $page .= '.tmpl';
    
    my $opar_config = $self->opar_config;
    
    my $path = File::Spec->catfile(
        $opar_config->get( 'paths.base' ),
        $opar_config->get( 'paths.templates' ),
        'static',
        $page,
    );
    
    if ( !$page or !-f $path ) {
        $page = $self->opar_config->get( 'defaults.static' );
    }
    
    my $html = $self->render_opar( 'static/' . $page );
    $self->render( text => $html, format => 'html' )
}

sub search {
    my ($self) = @_;
    
    my %params      = %{ $self->req->params->to_hash || {} };
    my $search_term = $params{search_term} || $self->param( 'term' ) || '*';
    my $page        = $self->param( 'page' ) || 1;
    my $framework   = $params{framework} || $self->param( 'framework' ) || '';
    
    if ( $page =~ m{\D}x or $page <= 0 ) {
        $page = 1;
    }

    my ($packages,$pages) = $self->page( $page, { search => $search_term, framework => $framework } );
    my $pagelist          = $self->page_list( $pages, $page ) || [];
    
    $_->{SEARCH_TERM} = $search_term for @{$pagelist};
    $_->{FRAMEWORK}   = $framework   for @{$pagelist};
    
    $self->stash(
        PACKAGES    => $packages,
        PAGES       => $pagelist,
        SEARCH_TERM => $search_term,
        FRAMEWORK   => $framework,
    );
    
    my $html = $self->render_opar( 'index_search_result' );
    $self->render( text => $html, format => 'html' )
}

sub login {
    my ($self) = @_;
    
    my $html = $self->render_opar( 'login' );
    $self->render( text => $html, format => 'html' )
}

sub do_login {
    my ($self,$forward,$template) = @_;

    $self->app->log->debug( 'do_login' );

    my %params = %{ $self->req->params->to_hash || {} };
    $forward ||= $params{redirect_to};

    $self->app->log->debug( "$params{user} tries to login" );
    my $user = $self->check_credentials( \%params );

    # successful login    
    if( $user ) {

        # redirect to page configured in admin.startpage
        $self->app->log->debug( "Forward to $forward" );
        $self->redirect_to( '/' . ( $self->opar_config->get( $forward ) || 'author' ) );
    }
    else {

        # show login form and show error message
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.login_incorrect.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.login_incorrect.message' ),
        });
        $self->login( $template );
    }
}

sub _send_feedbackmail {
    my ($self,%params) = @_;
    
    my $opar_config = $self->opar_config;
    
    # send mail to user
    my $mailer = $self->mailer;
    $mailer->prepare_mail(
        'feedback',
        %params
    );
    
    my $subject = 
        $opar_config->get( 'mail.tag' ) . ' ' . 
        $opar_config->get( 'mail.subjects.feedback' ) . ' ' .
        $params{subject};
    
    my $success = $mailer->send_mail(
        to      => $opar_config->get( 'mail.to' ),
        subject => $subject,
    );
    
    return $success;
}

1;
