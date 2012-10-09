package OTRS::OPR::Web::Guest::Package;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Spec;
use OTRS::OPR::DAO::Author;
use OTRS::OPR::DAO::Package;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DB::Helper::Author  qw(id_by_uppercase);
use OTRS::OPR::DB::Helper::Package qw(:all);
use OTRS::OPR::Web::App::Forms     qw(:all);

use XML::RSS;

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
        AUTOLOAD        => \&start,
        comment         => \&comment,
        send_comment    => \&send_comment,
        dist            => \&dist,
        author          => \&author,
        oq              => \&oq,
        download        => \&download,
        recent_packages => \&recent_packages,
    );
}

sub start {
    my ($self) = @_;
    
    $self->forward( '/' );
}

sub recent_packages {
    my ($self) = @_;

    my $rss = XML::RSS->new( version => '1.0' );
    
    my $config = $self->config;
	
    $rss->channel(
        title        => 'OPAR Recent Packages',
        link         => $self->script_url( 'index' ) . '/rss/recent/',
        description  => 'The most recent packages in the OTRS package archive (OPAR).',
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

sub comment {
    my ($self) = @_;
        
    my $captcha = Captcha::reCAPTCHA->new;
	 
    my $public_key        = $self->config->get( 'recaptcha.public_key' );
    my $html              = $captcha->get_html( $public_key );
    my $package_full_name = $self->param( 'id' );

    my $form_id = $self->get_formid;    
    $self->template( 'index_comment_form' );
    $self->stash(
        FORMID            => $form_id,
        PACKAGE_NAME      => ${[split /\-/, $package_full_name]}[0],
        PACKAGE_FULL_NAME => $package_full_name,
        CAPTCHA           => $html,
    );
}

sub send_comment {    
    my ($self) = @_;
    
    my %params = $self->query->Vars();
    my %errors;
    my $notification_type = 'success';
    
    my %uppercase = map { uc $_ => $params{$_} }keys %params;
				 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        #return $self->forgot_password( %uppercase );
    }
 
    # check captcha
    my $success = $self->validate_captcha( \%params );
    if ( !$success ) {
        #return $self->forgot_password( %uppercase );
    }

    $self->template( 'index_comment_sent' );

    if ($formid_ok && $success) {
        # save data object to db
        my $comment = OTRS::OPR::DAO::Comment->new(
            _schema => $self->schema,
        );
			
        my ($package_name, $package_version) = split /\-/, $self->param( 'id' );
        my $username = ($self->user ? $self->user->user_name : 'anonymous');

        $comment->username( $username );
        $comment->packagename( $package_name );
        $comment->packageversion( $package_version );
        $comment->comments( $params{'comments'} || '' );
        $comment->rating( $params{'rating'} || 0 );
        $comment->deletion_flag( 0 );
        $comment->headline( $params{'headline'} || '' );
        $comment->published( 0 );

        $notification_type = 'error' if keys %errors;
        $self->notify({
            type             => $notification_type,
            include          => 'notifications/comment_' . $notification_type,
            SUCCESS_HEADLINE => 'Your comment was saved',
            SUCCESS_MESSAGE  => 'The comment was saved for review and will be published soon.',
        });

        my %template_params;
        for my $error_key ( keys %errors ) {
            $template_params{ 'ERROR_' . uc $error_key } = $self->config->get( 'errors.' . $error_key );
	}

        $self->stash(
            %template_params,
        );
    }		
}

sub dist {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    my ($name,$version) = $package =~ m{
        \A              # string begin
        ([\w\s-]+)           # package name
        
        (?:                 # do not save match
            -               # dash
            (
                (?:[0-9]+)         # major number
                (?:\.[0-9]+){0,2}  # minor and patch number
            )               # version number
        )?                  # this is optional
        
        \z              # string end
    }xms;
    
    if ( !$name ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'No Package Name Given',
            ERROR_MESSAGE  => $self->config->get( 'error.package_not_given' ),
        });
        
        $self->template( 'blank' );
        return;
    }
    
    my %version;
    
    $version{version} = $version if $version;
    
    my $dao = OTRS::OPR::DAO::Package->new(
        package_name => $name,
        %version,
        _schema         => $self->schema,
        _last_published => 1,
    );

    # if package can't be found show error message
    if ( $dao->not_in_db || !$dao->is_in_index ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Package Not Found',
            ERROR_MESSAGE  => $self->config->get( 'error.package_not_found' ),
        });
        
        $self->template( 'blank' );
        return;
    }
    
    my %stash = $dao->to_hash;

    my $versions = $self->version_list( $name, { not_framework => $dao->framework } );
    
    $self->template( 'index_package' );
    $self->stash(
        %stash,
        OK_GRADE           => 'red',
        OTHER_VERSIONS     => $versions,
        HAS_OTHER_VERSIONS => scalar( @{$versions} ),
    );
}

sub download : Stream('text/xml') {
    my ($self) = @_;
    
    my $package_id = $self->param( 'id' );
    
    if ( !$package_id || $package_id =~ m{\D}x or $package_id <= 0 ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.package_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.package_not_found.message' ),
        });
        
        $self->template( 'blank' );
        return;
    }
    
    my $dao = OTRS::OPR::DAO::Package->new(
        package_id => $package_id,
        _schema    => $self->schema,
    );
    
    # if package can't be found show error message
    if ( $dao->not_in_db or !$dao->is_in_index ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.package_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.package_not_found.message' ),
        });
        
        $self->template( 'blank' );
        return;
    }
    
    return [ $dao->path ];
}

sub author {
    my ($self) = @_;
    
    my ($name) = $self->param( 'id' );
    
    if ( !$name ) {
        $self->template( 'blank' );
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.author_not_found.message' ),
        });
        return;
    }
    
    my $id = $self->id_by_uppercase( $name );
    if ( !$id ) {
        $self->template( 'blank' );
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.author_not_found.message' ),
        });
        return;
    }
    
    my $dao = OTRS::OPR::DAO::Author->new(
        user_id => $id,
        _schema => $self->schema,
    );
    
    if ( $dao->not_in_db || !$dao->active ) {
        $self->template( 'blank' );
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.author_not_found.message' ),
        });
        return;
    }
    
    my @packages = $dao->packages( is_in_index => 1, latest => 1 );
    my @for_tmpl = map{ $self->package_to_hash( $_ ) }@packages;
    
    my %info = $dao->to_hash;
    
    $self->template( 'index_author_packages' );
    $self->stash(
        %info,
        PACKAGES => \@for_tmpl,
    );
}

sub ok {
}

1;
