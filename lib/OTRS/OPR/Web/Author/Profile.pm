package OTRS::OPR::Web::Author::Profile;

use strict;
use warnings;

use Mojo::Base qw(Mojolicious::Controller);

use OTRS::OPR::DAO::User;
use OTRS::OPR::Web::App::Forms qw(:all);

sub show {
    my ($self) = @_;
    
    my %info = $self->_user_to_hash;
    
    $self->stash(
        %info,
    );

    my $html = $self->render_opar( 'author_profile' );
    $self->render( text => $html, format => 'html' );
}

sub edit {
    my ($self, %params) = @_;
    
    my $formid = $self->get_formid;
    my %info   = $self->_user_to_hash;
    
    $self->stash(
        %info,
        %params,
        FORMID => $formid,
    );

    my $html = $self->render_opar( 'author_profile_edit' );
    $self->render( text => $html, format => 'html' );
}

sub save {
    my ($self) = @_;
    
    # get user input
    my %params = %{ $self->req->params->to_hash || {} };
    
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

    my $html = $self->render_opar( 'author_profile_edit' );
    $self->render( text => $html, format => 'html' );
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
