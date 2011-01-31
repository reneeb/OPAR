package OTRS::OPR::Web::Admin::Author;

use strict;
use warnings;

use base qw(OTRS::OPR::Web::App);
use CGI::Application::Plugin::Redirect;

use OTRS::OPR::DAO::User;
use OTRS::OPR::DB::Helper::User    {list => 'user_list', delete => 'user_delete', page => 'page'};
use OTRS::OPR::Web::App::Prerun    qw(cgiapp_prerun);
use OTRS::OPR::Web::App::Session;
use OTRS::OPR::Web::Utils          qw(prepare_select page_list);

sub setup{
    my ($self) = @_;

    $self->main_tmpl( $self->_config->get('templates.admin') );
    
    my $startmode = 'list';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD          => \&list_users,
        list              => \&list_users,
        delete_user       => \&delete_user,
        undelete_user     => \&undelete_user,
        set_password      => \&set_password,
        send_message      => \&send_message,
        user_info         => \&user_info,
    );
}

sub list_users : Permission('admin') {
    my ($self) = @_;
    
    my $config = $self->config;
    
    my %params      = $self->query->Vars;
    my $search_term = $params{search_term};
    my $page        = $params{page} || 1;
    
    if ( !looks_like_number($page) or $page <= 0 ) {
        $page = 1;
    }
    
    my ($users,$pages) = $self->page( $page, $search_term );
    my $pagelist       = $self->page_list( $pages, $page );
    
    $self->template( 'admin_user_list' );
    $self->stash(
        PACKAGES => $packages,
        PAGES    => $pagelist,
    );
}

# get more info about a user, e.g. name
sub user_info : Permission( 'admin' ) : Json {
    my ($self) = @_;
    
    my $user_id = $self->param( 'user' );
    
    if ( !looks_like_number($user_id) or $user_id <= 0 ) {
        return { error => 'invalid user id' };
    }
}

sub delete_user : Permission( 'admin' ) {
    my ($self) = @_;
    
    my $config  = $self->config;
    my $user_id = $self->param( 'user' );
    
    if ( !looks_like_number($user_id) or $user_id <= 0 ) {
        return { error => 'invalid user id' };
    }
    
    # when a user is deleted, these things have to be deleted, too:
    #  * packages where the user is the author
    #      * a new maintainer has to be chosen
    #  * user <-> group relationships

    my ($user_obj) = $self->table( 'opr_user' )->find( $user_id );
    if ( $user_obj ) {
    }
    
    $self->forward( );
}

1;