package OTRS::OPR::Web::Guest::Repo;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Spec;
use OTRS::OPR::DAO::Repo;
use OTRS::OPR::DB::Helper::Repo    qw(page);
use OTRS::OPR::Web::App::Forms     qw(:all);

use XML::RSS;

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.guest') );
    
    my $startmode = 'add';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD => \&add,
        manage   => \&manage,
        recent   => \&recent,
        file     => \&file,
    );
}

sub file {
    my ($self) = @_;

    my $file = $self->param('file');

    my $index_dir = $self->config->get( 'repos.index_dir' );

}

sub recent {
    my ($self) = @_;

    my $rss     = XML::RSS->new( version => '1.0' );
    my $config  = $self->config;
    my $repo_id =
	
    $rss->channel(
        title        => 'OPAR Recent Packages',
        link         => $self->script_url( 'index' ) . '/repo/' . '/recent/',
        description  => 'The most recent packages in your OPAR repository',
        dc => {
            date       => '2011-01-01T07:00+00:00',
            subject    => 'OTRS Packages',
            creator    => $config->get( 'rss.creator' ),
            publisher  => $config->get( 'rss.publisher' ),
            rights     => 'Copyright 2011, ' . $config->get( 'rss.rights' ),
            language   => 'en-us',
        },
        syn => {
            updatePeriod     => 'hourly',
            updateFrequency  => 1,
            updateBase       => '1901-01-01T00:00+00:00',
        },
    );

    my ($package_ref) = $self->page( 1, { rows => 30 } );
    my @packages      = @{$package_ref};

    for my $package (@packages) {
        $rss->add_item(
            title       => $package->{NAME},
            link        => $self->script_url( 'index' ) . '/dist/' . $package->{NAME},
            description => $package->{DESCRIPTION},
            dc => {
                subject  => $package->{NAME},
                creator  => $package->{AUTHOR},
            },
        );
    }
	
    $self->main_tmpl( 'rss.tmpl' );
    $self->template( 'rss' );
    $self->stash(
        RSS_STRING => $rss->as_string,
    );
}

sub add_form {
    my ($self) = @_;
        
    my $captcha = Captcha::reCAPTCHA->new;
	 
    my $public_key        = $self->config->get( 'recaptcha.public_key' );
    my $html              = $captcha->get_html( $public_key );

    my $form_id = $self->get_formid;    
    $self->template( 'index_add_repo' );
    $self->stash(
        FORMID            => $form_id,
        CAPTCHA           => $html,
    );
}

sub add {    
    my ($self) = @_;
    
    my %params = $self->query->Vars();
    my %errors;
    my $notification_type = 'success';
    
    my %uppercase = map { uc $_ => $params{$_} }keys %params;
				 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
 
    # check captcha
    my $success = $self->validate_captcha( \%params );

    $self->template( 'index_add_repo' );

    if ($formid_ok && $success) {

        # save data object to db
        my $repo = OTRS::OPR::DAO::Repo->new(
            _schema => $self->schema,
        );

        $repo->repo_id( $uuid );

        if ( !keys %errors ) {
            return $self->forward( '/repo/' . $uuid . '/manage' );
        }
			
        my %template_params;
        for my $error_key ( keys %errors ) {
            $template_params{ 'ERROR_' . uc $error_key } = $self->config->get( 'errors.' . $error_key );
	}

        $self->stash(
            %template_params,
        );
    }		
}

1;
