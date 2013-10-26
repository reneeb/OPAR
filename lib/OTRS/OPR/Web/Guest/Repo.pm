package OTRS::OPR::Web::Guest::Repo;

use strict;
use warnings;

use Mojo::Base qw(Mojolicious::Controller);

use Captcha::reCAPTCHA;
use Data::UUID;
use File::Basename;
use File::Spec;

use OTRS::OPR::DAO::Repo;
use OTRS::OPR::Web::App::Forms qw(:all);
use OTRS::OPR::Web::Utils      qw(validate_opm_name);

sub file {
    my ($self) = @_;

    my $file    = $self->param('file');
    my $repo_id = $self->param('id');
    my $config  = $self->opar_config;

    if ( $repo_id eq 'otrs' && $file eq 'otrs.xml' ) {
        return $self->render_file( filepath => $config->get( 'otrs.index' ), filename => 'otrs.xml' );
    }
    elsif ( $file eq 'otrs.xml' ) {
        my ($repo) = $self->table( 'opr_repo' )->find( $repo_id );
        return $self->render_file( data => $repo->index_file, filename => 'otrs.xml' );
    }
    else {
        my ($name,$version) = OTRS::OPR::Web::Utils->validate_opm_name( $file );

        my ($package)       = $self->table( 'opr_package' )->search(
            {
                'opr_package_names.package_name' => $name,
                version                          => $version,
            },
            {
                join => 'opr_package_names',
            }
        );

        return $self->render_file( filepath => $package->path, filename => 'otrs.xml' );
    }
}

sub add_form {
    my ($self) = @_;
        
    my $captcha = Captcha::reCAPTCHA->new;
	 
    my $public_key   = $self->opar_config->get( 'recaptcha.public_key' );
    my $captcha_html = $captcha->get_html( $public_key );

    my $form_id = $self->get_formid;    
    $self->stash(
        FORMID  => $form_id,
        CAPTCHA => $captcha_html,
    );

    my $html = $self->render_opar( 'index_repo_add' );
    $self->render( text => $html, format => 'html' );
}

sub add {    
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    my %errors;
    my $notification_type = 'success';
    my $config            = $self->opar_config;
    
    my %uppercase = map { uc $_ => $params{$_} }keys %params;
				 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
 
    # check captcha
    my $success = $self->validate_captcha( \%params );

    my %errors = $self->validate_fields( 'repo.yml', \%params );
    if ( %errors ) {
        return $self->add_form;
    }

    if ($formid_ok && $success ) {

        # save data object to db
        my $repo = OTRS::OPR::DAO::Repo->new(
            _schema => $self->schema,
        );

        my $uuid = Data::UUID->new->create_str;
        $repo->repo_id( $uuid );
        $repo->email( $params{email} );
        $repo->save;

        if ( !keys %errors ) {

            my $template_name = 'user_repo_created';

            # send mail to user
            my $mailer = $self->mailer;
            $mailer->prepare_mail(
                $template_name,
                URL     => $self->base_url,
                REPO_ID => $uuid,
            );
        
            my $subject =
                $config->get( 'mail.tag' ) . ' ' .
                $config->get( 'mail.subjects.' . $template_name );
        
            my $success = $mailer->send_mail(
                to      => $params{email},
                subject => $subject,
            );

            return $self->redirect_to( '/repo/' . $uuid . '/manage' );
        }
			
        my %template_params;
        for my $error_key ( keys %errors ) {
            $template_params{ 'ERROR_' . uc $error_key } = $config->get( 'errors.' . $error_key );
	}

        $self->stash(
            %template_params,
        );
    }

    $self->add_form();
}

sub manage {
    my ($self) = @_;

    my $repo_id = $self->param( 'id' ) || $self->param('repo_id');

    my ($repo) = $self->table( 'opr_repo' )->find( $repo_id );

    return $self->redirect_to( '/repo' ) if !$repo;

    my $repo_dao = OTRS::OPR::DAO::Repo->new(
        _schema => $self->schema,
        repo_id => $repo_id,
    );

    my @version_list = $self->table( 'opr_framework_versions' )->search(
        {},
        { order_by => 'framework', }
    );

    my $repo_framework = $repo_dao->framework || '';
    my @frameworks = map{ {
        VERSION  => $_->framework,
        SELECTED => ( $repo_framework eq $_->framework ? 'selected="selected"' : '' ), 
    } }@version_list;

    $self->stash(
        __JS_INCLUDES__  => [ { JS_FILE => '/js/bsn.AutoSuggest_2.1.3_comp.js' } ],
        __CSS_INCLUDES__ => [ { CSS_FILE => '/css/autosuggest_inquisitor.css' } ],
        repo_frameworks => \@frameworks,
        $repo_dao->to_hash,
    );

    my $html = $self->render_opar( 'index_repo_manage' );
    $self->render( text => $html, format => 'html' );
}

sub save {
    my ($self) = @_;

    my $repo_id = $self->param( 'id' );

    my ($repo) = $self->table( 'opr_repo' )->find( $repo_id );

    return $self->redirect_to( '/repo' ) if !$repo;

    my %params      = %{ $self->req->params->to_hash || {} };
    my @package_ids = $self->param( 'package' );

    my $repo_dao = OTRS::OPR::DAO::Repo->new(
        _schema => $self->schema,
        repo_id => $repo_id,
    );

    $repo_dao->packages( \@package_ids );
    $repo_dao->framework( $params{framework} );
    $repo_dao->email( $params{email} );
    $repo_dao->save;

    $self->redirect_to( '/repo/' . $repo_id . '/manage' );
}

sub search {
    my $self = shift;

    my %params = %{ $self->req->params->to_hash || {} };
    my %search_clauses;

    my $term = $params{term} || '';
    $term    =~ tr/*/%/;
   
    my @ors;
    for my $field ( 'opr_package_names.package_name', 'description' ) {
        next unless $term;
        push @ors, { $field => { LIKE => '%' . $term . '%' } };
        $search_clauses{'-or'} = \@ors;
    }

    if ( $params{framework} ) {
        $search_clauses{framework} = { LIKE => '%' . $params{framework} . '.%' };
    }

    my $resultset = $self->table( 'opr_package' )->search(
        {
            %search_clauses,
        },
        {
            rows      => 35,
            order_by  => 'max(upload_time) DESC',
            group_by  => [ 'opr_package_names.package_name' ],
            join      => 'opr_package_names',
            '+select' => [
                'opr_package_names.package_name',
                { max => 'version', '-as' => 'max_version' },
                { max => 'upload_time', '-as' => 'latest_time' },
            ],
        },
    );

    my @packages = $resultset->all;
    my @results  = map{ {
        id    => $_->name_id,
        value => $_->opr_package_names->package_name,
        info  => $_->description,
    }} @packages;

    $self->render( json => { results => \@results } );
}


1;
