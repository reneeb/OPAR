package OTRS::OPR::Web::Guest::Package;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use File::Basename;
use File::Spec;
use XML::RSS;

use OTRS::OPR::DAO::Author;
use OTRS::OPR::DAO::Package;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DB::Helper::Author  qw(id_by_uppercase);
use OTRS::OPR::DB::Helper::Package qw(:all);
use OTRS::OPR::Web::App::Forms     qw(:all);

sub recent_packages {
    my ($self) = @_;

    my $rss = XML::RSS->new( version => '1.0' );
    
    my $config = $self->opar_config;
	
    $rss->channel(
        title        => 'OPAR Recent Packages',
        link         => $self->base_url . '/recent/',
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
            title       => $package->{NAME} . ' (' . $package->{MAX_VERSION} . ')',
            link        => $self->base_url . '/dist/' . $package->{NAME},
            description => $package->{DESCRIPTION},
            dc => {
                subject  => $package->{NAME},
                creator  => $package->{AUTHOR},
            },
        );
    }
	
    $self->stash(
        main_template => 'rss.tmpl',
        RSS_STRING => $rss->as_string,
    );

    my $rss_text = $self->render_opar( 'rss' );
    $self->render( text => $rss_text, format => 'xml' );
}

sub comment {
    my ($self) = @_;
        
    my $captcha = Captcha::reCAPTCHA->new;
	 
    my $public_key        = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html      = $captcha->get_html( $public_key );
    my $package_full_name = $self->param( 'id' );

    my $form_id = $self->get_formid;    
    $self->stash(
        FORMID            => $form_id,
        PACKAGE_NAME      => ${[split /\-/, $package_full_name]}[0],
        PACKAGE_FULL_NAME => $package_full_name,
        CAPTCHA           => $captcha_html,
    );

    my $html = $self->render_opar( 'index_comment_form' );
    $self->render( text => $html, format => 'html' );
}

sub send_comment {    
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
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

    if ($formid_ok && $success) {
        # save data object to db
        my $comment = OTRS::OPR::DAO::Comment->new(
            _schema => $self->schema,
        );
			
        my ($package_name, $package_version) = split /\-/, $self->param( 'id' );
        my $username = ($self->user ? $self->user->user_name : $params{username} . ' (guest)' );

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
            $template_params{ 'ERROR_' . uc $error_key } = $self->opar_config->get( 'errors.' . $error_key );
	}

        $self->stash(
            %template_params,
        );
    }

    my $html = $self->render_opar( 'index_comment_sent' );
    $self->render( text => $html, format => 'html' );
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
            ERROR_MESSAGE  => $self->opar_config->get( 'error.package_not_given' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
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
            ERROR_MESSAGE  => ( $self->opar_config->get( 'error.package_not_found' ) || '' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
    }
    
    # if method is called by route /package/:initial/:short/:author/*package the author settings should be checked
    if ( $self->param( 'short' ) ) {
        my $author_requested  = $self->param( 'author' );
        my $short_requested   = $self->param( 'short' );
        my $initial_requested = $self->param( 'initial' );
        my @maintainers       = $dao->maintainer_list;

        if (
            $short_requested ne substr($author_requested, 0, 2) ||
            $initial_requested ne substr($author_requested, 0, 1) ||
            !grep{ uc $_->{USER_NAME} eq $author_requested }@maintainers
        ) {
            $self->notify({
                type           => 'error',
                include        => 'notifications/generic_error',
                ERROR_HEADLINE => $self->opar_config->get( 'errors.author_not_found.headline' ) || '',
                ERROR_MESSAGE  => $self->opar_config->get( 'errors.author_not_found.message' ) || '',
            });
        
            my $html = $self->render_opar( 'blank' );
            return $self->render( text => $html, format => 'html' ); ;
        }
    }
    
    my %stash = $dao->to_hash;

    my $versions = $self->version_list( $name, { not_framework => $dao->framework } );
    
    $self->stash(
        %stash,
        OK_GRADE           => 'red',
        OTHER_VERSIONS     => $versions,
        HAS_OTHER_VERSIONS => scalar( @{$versions} ),
    );
        
    my $html = $self->render_opar( 'index_package' );
    return $self->render( text => $html, format => 'html' ); ;
}

sub download {
    my ($self) = @_;
    
    my $package_id = $self->param( 'id' );
    
    if ( !$package_id || $package_id =~ m{\D}x or $package_id <= 0 ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.package_not_found.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.package_not_found.message' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
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
            ERROR_HEADLINE => $self->opar_config->get( 'errors.package_not_found.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.package_not_found.message' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
    }

    $self->render_file( filepath => $dao->path, filename => sprintf "%s-%s.opm", $dao->package_name, $dao->version );
}

sub author {
    my ($self) = @_;
    
    my ($name) = $self->param( 'id' );
    
    if ( !$name ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.author_not_found.message' ),
        });
    }
    
    my $id = $self->id_by_uppercase( $name );
    if ( !$id ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.author_not_found.message' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
    }
    
    my $dao = OTRS::OPR::DAO::Author->new(
        user_id => $id,
        _schema => $self->schema,
    );
    
    if ( $dao->not_in_db || !$dao->active ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->opar_config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->opar_config->get( 'errors.author_not_found.message' ),
        });
        
        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' ); ;
    }
    
    my @packages = $dao->packages( is_in_index => 1, latest => 1 );
    my @for_tmpl = map{ $self->package_to_hash( $_ ) }@packages;
    
    my %info = $dao->to_hash;
    
    $self->stash(
        %info,
        PACKAGES => \@for_tmpl,
    );
    
    my $html = $self->render_opar( 'index_author_packages' );
    return $self->render( text => $html, format => 'html' ); ;
}

sub ok {
}

1;
