package OTRS::OPR::DB::Helper::User;

use strict;
use warnings;

use Crypt::SaltedHash;

use parent 'OTRS::OPR::Exporter::Aliased';
use OTRS::OPR::Web::Utils qw(time_to_date looks_empty looks_like_number);

our @EXPORT_OK = qw(
    check_credentials
    page
    user_to_hash
);

sub check_credentials {
    my ($self,$params) = @_;
    
    my $logger = $self->app->log;
    
    return if !($params->{user} and $params->{password});
    
    my $username = $params->{user};
    
    my ($user) = $self->table( 'opr_user' )->search({
        user_name     => $username,
        active        => 1,
    })->all;
    
    if ( !$user ) {
        $logger->info( "Login for $username not successful" );
        return;
    }

    if ( !Crypt::SaltedHash->validate( $user->user_password, $params->{password} ) {
        $logger->info( "Login for $username not successful (wrong password)" );
        return;
    }
    
    $logger->debug( "Login $username successful" );
    
    my $session = $self->opar_session;
    $session->force_new;
    
    my $session_id = $session->id;
    $user->session_id( $session_id );
    $user->update;
    
    $logger->debug( "Session ID for $user: $session_id" );
    
    return 1;
}

sub page {
    my ($self, $page, $params) = @_;

    my $rows = $params->{rows} || $self->opar_config->get( 'rows.search' );
    
    my %search_clauses;
    if ( exists $params->{search} ) {
        my $term = $params->{search} || '';
        $term    =~ tr/*/%/;
        my @ors;
        for my $field ( 'opr_user.user_name', 'opr_user.realname' ) {
            next unless $term;
            push @ors, { $field => { LIKE => '%' . $term . '%' } };
            $search_clauses{'-or'} = \@ors;
        }
    }
    
    #if ( !$params->{all} ) {
    #    $search_clauses{is_in_index} = 1;
    #}
    
    my $resultset = $self->table( 'opr_user' )->search(
        {
            %search_clauses,
        },
        {
            page      => $page,
            rows      => $rows,
            order_by  => 'user_id',
        },
    );

    my @users = $resultset->all;    
    my $pages = $resultset->pager->last_page || 1;
        
    my @users_for_template;
    for my $user ( @users ) {        
        push @users_for_template, user_to_hash( $self, $user, $params );
    }
    
    return ( \@users_for_template, $pages );
}

sub user_to_hash {
    my ($self, $user, $params) = @_;
        
    # create the infos for the template
    my $info = {
        USER_ID      => $user->user_id,
        NAME         => $user->user_name,
        WEBSITE      => $user->website,
        MAIL         => $user->mail,
        ACTIVE       => $user->active,
        REGISTERED   => time_to_date( $self, $user->registered ),
        REALNAME     => $user->realname,
    };
    
    return $info;
}

1;
