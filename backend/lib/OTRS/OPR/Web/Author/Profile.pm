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

    my %notifications = map{ $_->{notification_name} => $_->{notification_type} }@{ $self->user->notifications || [] };
    my $config = $self->opar_config;

    my @notification_fields;
    for my $notification_name ( sort keys %{ $config->get('notifications') || {} } ) {
        my @types = map{ {
            value    => $_,
            selected => ( ( $_ eq ( $notifications{$notification_name} || '' ) ) ? 'selected="selected"' : '' ),
        } }@{$config->get('notifications')->{$notification_name}->{types} || []};

        push @notification_fields, {
            NAME     => $notification_name,
            TYPE     => $notifications{$notification_name},
            SELECTED => ( $notifications{$notification_name} ? 'checked="checked"' : '' ),
            LABEL    => $config->get('notifications')->{$notification_name}->{label},
        };
    }

    $self->stash( NOTIFICATION_FIELDS => \@notification_fields );

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

    my %notifications = map{ $_->{notification_name} => $_->{notification_type} }@{ $self->user->notifications || [] };
    my $config = $self->opar_config;

    my @notification_fields;
    for my $notification_name ( sort keys %{ $config->get('notifications') || {} } ) {
        my @types = map{ {
            value    => $_,
            selected => ( ( $_ eq ( $notifications{$notification_name} || '' ) ) ? 'selected="selected"' : '' ),
        } }@{$config->get('notifications')->{$notification_name}->{types} || []};

        push @notification_fields, {
            NAME  => $notification_name,
            TYPES => \@types,
            LABEL => $config->get('notifications')->{$notification_name}->{label},
        };
    }

    $self->stash( NOTIFICATION_FIELDS => \@notification_fields );

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

    my $config = $self->opar_config;
    $dao->clear_notifications;
    for my $notification_name ( keys %{ $config->get('notifications') || {} } ) {
        if ( $params{$notification_name} ) {
            $dao->add_notification({
                notification_name => $notification_name,
                notification_type => $params{ $notification_name . '_type' },
            });
        }
    }
    
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
