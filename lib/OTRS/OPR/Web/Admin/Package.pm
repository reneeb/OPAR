package OTRS::OPR::Web::Admin::Package;

use strict;
use warnings;

use base qw(OTRS::OPR::Web::App);
use CGI::Application::Plugin::Redirect;
use Scalar::Util qw(looks_like_number);

use OTRS::OPR::DAO::Package;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DB::Helper::Comment {page => 'cpage'};
use OTRS::OPR::DB::Helper::Job     qw(create_job find_job);
use OTRS::OPR::DB::Helper::Package qw(page);
use OTRS::OPR::DB::Helper::User    {list => 'user_list'};
use OTRS::OPR::Web::App::Prerun    qw(cgiapp_prerun);
use OTRS::OPR::Web::App::Session;
use OTRS::OPR::Web::Utils          qw(prepare_select page_list time_to_date);

sub setup{
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.admin') );
    
    my $startmode = 'list';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD          => \&list_packages,
        list              => \&list_packages,
        delete_package    => \&delete_package,
        undelete_package  => \&undelete_package,
        co_maint          => \&set_comaintainer,
        save_co_maint     => \&save_comaintainer,
        comments          => \&comments,
        publish_comment   => \&publish_comment,
        unpublish_comment => \&unpublish_comment,
        reanalyze					=> \&reanalyze,
    );
}

sub list_packages : Permission('admin') {
    my ($self) = @_;
    
    my $config = $self->config;
    
    my %params      = $self->query->Vars;
    my $search_term = $params{search_term};
    my $page        = $params{page} || 1;
    
    if ( !looks_like_number($page) or $page <= 0 ) {
        $page = 1;
    }
    
    my ($packages,$pages) = $self->page( $page, { search => $search_term, all => 1 } );
    my $pagelist          = $self->page_list( $pages, $page );
    
    $self->template( 'admin_package_list' );
    $self->stash(
        PACKAGES => $packages,
        PAGES    => $pagelist,
    );
}

sub delete_package : Permission( 'admin' ) {
    my ($self) = @_;
    
    # the package is not deleted, it's just marked to be deleted and
    # a new job is created
    my $config  = $self->config;
    my $package = $self->param( 'id' ) || '';
    
    if ( $package =~ m{\D}x or $package <= 0 ) {
        #return { error => 'invalid package' };
    }
    else {    
        my $package_dao = OTRS::OPR::DAO::Package->new(
            package_id => $package,
            _schema    => $self->schema,
        );

        my $delete_until = time + $config->get( 'time.deletion_admin' );
        $package_dao->deletion_flag( $delete_until );
                        
        my $job_id = $self->create_job({
            id => $package,
            type => 'delete',
        });
                        
        #return { delete_until => $delete_until };
    }
    $self->list_packages;
}

sub undelete_package : Permission( 'admin' ) {
    my ($self) = @_;
    
    my $package = $self->param( 'id' ) || '';
    
    if ( $package =~ m{\D}x or $package <= 0 ) {
        #return { error => 'invalid package' };
    }
    else {
        my $job = $self->find_job({
            id   => $package,
            type => 'delete',
        });
                        
        $job->delete;
                        
        my ($package_obj) = $self->table( 'opr_package' )->find( $package );
        if ( $package_obj ) {
            $package_obj->deletion_flag( undef );
            $package_obj->update;
        }
                        
        #return { success => 1 };
    }
    $self->list_packages;
}

=head2 set_comaintainer

This method displays the form where the admin can select the co-maintainer
of the given package.

=cut

sub set_comaintainer : Permission( 'admin' ) {
    my ($self) = @_;
    
    # get package id passed to app
    my $package = $self->param( 'package' );
    
    # check if a number was passed
    if ( !looks_like_number($package) or $package <= 0 ) {
        return { error => 'invalid package' };
    }
    
    # create a DAO object
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
    );
    
    # create hash that can be used in template
    my %package_info = $package_dao->for_template;
    
    # get all users of the system
    my @users = $self->user_list;
    
    # get an array that can be used in the template
    my @users_for_template = $self->prepare_select(
        data     => \@users,
        selected => [ $package_dao->co_maintainer ],
        exclude  => $package_dao->author,
    );
    
    $self->template( 'admin_set_comaintainer' );
    $self->stash(
        %package_info,
    );
}

=head2 save_comaintainer

=cut

sub save_comaintainer : Permission( 'admin' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    my @users   = $self->query->param( 'comaintainer' );
    
    if ( !looks_like_number($package) or $package <= 0 ) {
        return { error => 'invalid package' };
    }
    
    @users = grep{ m{ \A \d+ \z }xms }@users;
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
    );
    
    $package_dao->co_maintainer( \@users );
    $package_dao->save;
    
    return { success => 1 };
}

sub comments : Permission( 'admin' ) {
    my ($self) = @_;
    
    # get the package name
    my $package_name = $self->param( 'id' );
    
   # check if a valid package name was given
    my ($valid_package_name) = ($package_name =~ m{
        \A
            (?:[A-Za-z0-9]+)   # first word
            (?:-[A-Za-z0-9]+)* # following words
        \z
    }xms);
    
    # show error if no valid package name was given
    if ( !$valid_package_name ) {
        $self->template( 'notifications/generic_error' );
        $self->stash(
            ERROR => 'Invalid Package Name',
        );
        return;
    }
    
    my %params = $self->query->Vars;
    my $page   = $params{page} || 1;
    
    if ( !looks_like_number($page) or $page <= 0 ) {
        $page = 1;
    }
    
    my ($comments,$pages) = $self->cpage( $page, { package_name => $package_name, all => 1 } );
    my $pagelist          = $self->page_list( $pages, $page );
    
    $self->template( 'admin_package_comments' );
    $self->stash(
        NAME         => $package_name,
        HAS_COMMENTS => scalar(@{$comments}),
        COMMENTS     => $comments,
        PAGES        => $pagelist,
    );
}

sub goto_comments : Permission( 'admin' ) {
    my ($self) = @_;
        
    my $comment_id = $self->param( 'id' );
    
    my $comment = $self->schema->resultset('opr_comments')->find({ comment_id => $comment_id });
    
    return $self->comments if !$comment;
      
    $self->param('id', $comment->packagename);
    $self->comments;
}

sub publish_comment : Permission( 'admin' ) {
    my ($self) = @_;

    my $comment_id = $self->param( 'id' );
    my $comment = OTRS::OPR::DAO::Comment->new(
        comment_id => $comment_id,
        _schema      => $self->schema,
    );
    $comment->published( time );
    $comment = undef;

    $self->goto_comments;
}

sub unpublish_comment : Permission( 'admin' ) {
    my ($self) = @_;

    my $comment_id = $self->param( 'id' );
    my $comment    = OTRS::OPR::DAO::Comment->new(
        comment_id => $comment_id,
        _schema    => $self->schema,
    );
    $comment->published( 0 );
    $comment = undef;

    $self->goto_comments;
}

sub reanalyze : Permission( 'admin' ) {
	my ($self) = @_;
	
	my ($package_id) = $self->param('id');

	# check if an analyzation job for that package is already scheduled
  my $job = $self->find_job({
			id   => $package_id,
			type => 'analyze',
	});
	if ($job) {
		return $self->list_packages();
	}

	# create an entry in job queue that the package
	# should be analyzed    
	my $job_id = $self->create_job({
			id   => $package_id,
			type => 'analyze',
	});
	
	$self->notify({
			type             => 'success',
			include          => 'notifications/generic_success',
			SUCCESS_HEADLINE => 'OPM reanalyzation has been scheduled',
			SUCCESS_MESSAGE  => 'OPM will be reanalyzed during the next analyzation run',
	});
	
	return $self->list_packages();
}

1;