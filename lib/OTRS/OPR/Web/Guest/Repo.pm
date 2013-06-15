package OTRS::OPR::Web::Guest::Repo;

use strict;
use warnings;

use base qw(OTRS::OPR::Web::App);

use Captcha::reCAPTCHA;
use Data::UUID;
use File::Spec;

use OTRS::OPR::DAO::Repo;
use OTRS::OPR::Web::App::Forms     qw(:all);

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
        AUTOLOAD => \&add_form,
        add      => \&add,
        add_form => \&add_form,
        manage   => \&manage,
        file     => \&file,
        search   => \&search,
        save     => \&save,
    );
}

sub file {
    my ($self) = @_;

    my $file = $self->param('file');

    my $index_dir = $self->config->get( 'repos.index_dir' );

}

sub add_form {
    my ($self) = @_;
        
    my $captcha = Captcha::reCAPTCHA->new;
	 
    my $public_key        = $self->config->get( 'recaptcha.public_key' );
    my $html              = $captcha->get_html( $public_key );

    my $form_id = $self->get_formid;    
    $self->template( 'index_repo_add' );
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
    my $config            = $self->config;
    
    my %uppercase = map { uc $_ => $params{$_} }keys %params;
				 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
 
    # check captcha
    #my $success = $self->validate_captcha( \%params );
    my $success = 1;

    $self->template( 'index_repo_add' );

    if ($formid_ok && $success) {

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

            return $self->forward( '/repo/' . $uuid . '/manage' );
        }
			
        my %template_params;
        for my $error_key ( keys %errors ) {
            $template_params{ 'ERROR_' . uc $error_key } = $self->config->get( 'errors.' . $error_key );
	}

        $self->stash(
            %template_params,
        );

        $self->add_form();
    }		
}

sub manage {
    my ($self) = @_;

    my $repo_id = $self->param( 'id' ) || $self->query->param('repo_id');

    my ($repo) = $self->table( 'opr_repo' )->find( $repo_id );

    return $self->forward( '/repo' ) if !$repo;

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

    $self->template( 'index_repo_manage' );
    $self->stash(
        __JS_INCLUDES__  => [ { JS_FILE => '/js/bsn.AutoSuggest_2.1.3_comp.js' } ],
        __CSS_INCLUDES__ => [ { CSS_FILE => '/css/autosuggest_inquisitor.css' } ],
        repo_frameworks => \@frameworks,
        $repo_dao->to_hash,
    );
}

sub save {
    my ($self) = @_;

    my $repo_id = $self->param( 'id' );

    my ($repo) = $self->table( 'opr_repo' )->find( $repo_id );

    return $self->forward( '/repo' ) if !$repo;

    my %params      = $self->query->Vars;
    my @package_ids = $self->query->param( 'package' );

    my $repo_dao = OTRS::OPR::DAO::Repo->new(
        _schema => $self->schema,
        repo_id => $repo_id,
    );

    $repo_dao->packages( \@package_ids );
    $repo_dao->framework( $params{framework} );
    $repo_dao->email( $params{email} );
    $repo_dao->save;

    $self->forward( '/repo/' . $repo_id . '/manage' );
}

sub search : Json {
    my $self = shift;

    my %params = $self->query->Vars;
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

    return { results => \@results }
}


1;
