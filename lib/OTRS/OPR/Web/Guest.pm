package OTRS::OPR::Web::Guest;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use Data::Tabulate;
use File::Spec;
use OTRS::OPR::DB::Helper::Author  { list => 'author_list' };
use OTRS::OPR::DB::Helper::Package qw(page);
use OTRS::OPR::Web::App::Forms     qw(:all);
use OTRS::OPR::Web::Utils          qw(prepare_select page_list);

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
        search        => \&search,
        authors       => \&authors,
    );
}

sub start {
    my ($self) = @_;
    
    $self->template( 'index_home' );
}

sub authors {
    my ($self) = @_;
    
    my $short   = $self->param( 'short' )   || undef;
    my $initial = $self->param( 'initial' ) || undef;
    
    my @authors   = $self->author_list( initial => $initial, short => $short, active => 1 );
    my $tabulator = Data::Tabulate->new;
    
    $tabulator->max_columns( 6 );
    $tabulator->min_columns( 3 );
    
    @authors = map{ { NAME => $_, __SCRIPT__ => $self->base_url, LISTURL => $short, INITIAL => $initial } }@authors;
    @authors = $tabulator->tabulate( @authors );
    @authors = map{ { INNER => $_ } }@authors;
    
    $self->template( 'index_authors' );
    $self->stash(
        AUTHORS => \@authors,
    );
}

sub feedback {
    my ($self,%params) = @_;
    
    my $captcha = Captcha::reCAPTCHA->new;
    
    my $public_key = $self->config->get( 'recaptcha.public_key' );
    my $html       = $captcha->get_html( $public_key );
    
    my $form_id = $self->get_formid;
    
    $self->template( 'index_feedback_form' );
    $self->stash(
        %params,
        FORMID  => $form_id,
        CAPTCHA => $html,
    );
}

sub send_feedback {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    
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
    
    $self->template( 'blank' );
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

sub search {
    my ($self) = @_;
    
    my %params      = $self->query->Vars;
    my $search_term = $params{search_term} || $self->param( 'term' ) || '*';
    my $page        = $self->param( 'page' ) || 1;
    
    if ( $page =~ m{\D}x or $page <= 0 ) {
        $page = 1;
    }
    
    my ($packages,$pages) = $self->page( $page, { search => $search_term } );
    my $pagelist          = $self->page_list( $pages, $page ) || [];
    
    $_->{SEARCH_TERM} = $search_term for @{$pagelist};
    
    $self->template( 'index_search_result' );
    $self->stash(
        PACKAGES    => $packages,
        PAGES       => $pagelist,
        SEARCH_TERM => $search_term,
    );
}

sub _send_feedbackmail {
    my ($self,%params) = @_;
    
    my $config = $self->config;
    
    # send mail to user
    my $mailer = $self->mailer;
    $mailer->prepare_mail(
        'feedback',
        %params
    );
    
    my $subject = 
        $config->get( 'mail.tag' ) . ' ' . 
        $config->get( 'mail.subjects.feedback' ) . ' ' .
        $params{subject};
    
    my $success = $mailer->send_mail(
        to      => $config->get( 'mail.to' ),
        subject => $subject,
    );
    
    return $success;
}

1;