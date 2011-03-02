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
use OTRS::OPR::Web::App::Forms     qw(check_formid get_formid);

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
        comment       => \&comment,
        send_comment  => \&send_comment,
        dist          => \&dist,
        author        => \&author,
        oq            => \&oq,
        download      => \&download
    );
}

sub start {
    my ($self) = @_;
    
    $self->forward( '/' );
}

sub comment {
    my ($self) = @_;
        
    my $package_full_name = $self->param( 'id' );
    my $form_id = $self->get_formid;
    
    $self->template( 'index_comment_form' );
    $self->stash(
        FORMID => $form_id,
        PACKAGE_NAME => @{[split /\-/, $package_full_name]}[0],
        PACKAGE_FULL_NAME => $package_full_name,
    );
}

sub send_comment {    
    my ($self) = @_;
    
    my %params = $self->query->Vars();
    my %errors;
    my $notification_type = 'success';
    
    $errors{formid} = $self->check_formid( $params{formid} );
    
    # save data object to db
    my $comment = OTRS::OPR::DAO::Comment->new(
        _schema => $self->schema,
    );
    
    $comment->username( '' );
    $comment->packagename( '' );
    $comment->packageversion( '' );
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
    
    $self->template( 'index_comment_sent' );
    $self->stash(
        %template_params,
    );
}

sub dist {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    my ($name,$version) = $package =~ m{
        \A              # string begin
        (\w+)           # package name
        
        (?:                 # do not save match
            -               # dash
            (\d+\.\d+\.\d+) # version number
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
        _schema      => $self->schema,
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
    
    $self->template( 'index_package' );
    $self->stash(
        %stash,
        OK_GRADE => 'red',
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
    
    my @packages = $dao->packages( is_in_index => 1 );
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