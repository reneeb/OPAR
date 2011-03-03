package OTRS::OPR::Web::Author::Profile;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use OTRS::OPR::DAO::User;
use OTRS::OPR::Web::App::Forms  qw(:all);
use OTRS::OPR::Web::App::Prerun qw(cgiapp_prerun);

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.author') );
    
    my $startmode = 'show';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'run' );
    $self->run_modes(
        AUTOLOAD => \&show,
        show     => \&show,
        edit     => \&edit,
        save     => \&save,
    );
}

sub show : Permission( 'author' ) {
    my ($self) = @_;
    
    my %info = $self->_user_to_hash;
    
    $self->template( 'author_profile' );
    $self->stash(
        %info,
    );
}

sub edit : Permission( 'author' ) {
    my ($self, %params) = @_;
    
    my $formid = $self->get_formid;
    
    my %info = $self->_user_to_hash;
    
    $self->template( 'author_profile_edit' );
    $self->stash(
        %info,
        %params,
        FORMID => $formid,
    );
}

sub save : Permission( 'author' ) {
    my ($self) = @_;
    
    # get user input
    my %params = $self->query->Vars;
    
    # validate user input
    my %errors = $self->validate_fields( 'profile.yml', \%params );
    if ( %errors ) {
        return $self->edit( %params, %errors );
    }
    
    # save values - only a few fields can be changed
    my $dao = OTRS::OPR::DAO::User->new(
        user_id => $self->user->user_id,
        _schema => $self->schema,
    );
    
    my $password = '';
    
    $dao->user_password( $password ) if $password;
    $dao->website( $params{website} );
    $dao->mail( $params{mail} );
    $dao->realname( $params{realname} );
    
    my %info = $self->_user_to_hash( $dao );
    
    $self->template( 'author_profile_edit' );
    $self->stash(
        %info,
    );
    
    # show success notification
    $self->notify({
        type             => 'success',
        include          => 'notifications/generic_success',
        SUCCESS_HEADLINE => 'Your changes have been saved',
        SUCCESS_MESSAGE  => 'Your profile changes have been saved',
    });
}

sub _user_to_hash {
    my ( $self, $dao ) = @_;
    
    $dao ||= $self->user;
    
    my %info;
    
    for my $attr ( qw(user_name website mail realname) ) {
        $info{$attr} = $dao->$attr();
    }
    
    return %info;
}

1;