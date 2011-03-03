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
use OTRS::OPR::Web::App::Forms     qw(:all);

use XML::RSS;

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
        download      => \&download,
        recent_packages => \&recent_packages,
    );
}

sub start {
    my ($self) = @_;
    
    $self->forward( '/' );
}

sub recent_packages {
	my ($self) = @_;
	
	my $rss = XML::RSS->new(version => '1.0');
	my $host = 'http://localhost';
	
	$rss->channel(
		 title        => "OPAR Recent Packages",
		 link         => $host."/bin/index.cgi/rss/recent/packages",
		 description  => "The most recent packages in the OTRS package directory (OPAR).",
		 dc => {
			 date       => '2011-01-01T07:00+00:00',
			 subject    => "OTRS Packages",
			 creator    => 'info@perl-services.de',
			 publisher  => 'info@perl-services.de',
			 rights     => 'Copyright 2011, Perl-Services',
			 language   => 'en-us',
		 },
		 syn => {
			 updatePeriod     => "hourly",
			 updateFrequency  => "1",
			 updateBase       => "1901-01-01T00:00+00:00",
		 },
		 #taxo => [
		 #	 'http://dmoz.org/Computers/Internet',
		 #	 'http://dmoz.org/Computers/PC'
		 #],
	);

	my @packages = ();
	foreach my $package ($self->schema->resultset('opr_package')->all()) {
		push @packages, $package;
	}
	@packages = sort { $a->get_column('upload_time') <=> $b->get_column('upload_time') } @packages;

	foreach my $package (@packages) {
		my $package_name = $self->schema->resultset('opr_package_names')->find({ name_id => $package->get_column('name_id') });
		my $author = $self->schema->resultset('opr_package_author')->find({
										name_id => $package->get_column('name_id'),
										is_main_author => 1,
									});
		if ($author) {
			my $user = $self->schema->resultset('opr_user')->find({ user_id => $author->get_column('user_id') });
		
			$rss->add_item(
				 title       => $package_name->get_column('package_name'),
				 link        => $host."/bin/index.cgi/dist/".$package_name->get_column('package_name'),
				 description => $package->get_column('description'),
				 dc => {
					 subject  => "X11/Utilities",
					 creator  => $user->get_column('user_name')." (".$user->get_column('mail').")",
				 },
				 #taxo => [
				 #	 'http://dmoz.org/Computers/Internet',
				 #	 'http://dmoz.org/Computers/PC'
				 #]
			 );
		}
	}
	
  $self->main_tmpl( 'rss.tmpl' );
	$self->template( 'rss' );
	$self->stash(
			RSS_STRING => $rss->as_string,
	);
}

sub comment {
    my ($self) = @_;
        
		my $captcha = Captcha::reCAPTCHA->new;
	 
		my $public_key        = $self->config->get( 'recaptcha.public_key' );
		my $html              = $captcha->get_html( $public_key );
    my $package_full_name = $self->param( 'id' );

    my $form_id = $self->get_formid;    
    $self->template( 'index_comment_form' );
    $self->stash(
        FORMID => $form_id,
        PACKAGE_NAME => @{[split /\-/, $package_full_name]}[0],
        PACKAGE_FULL_NAME => $package_full_name,
				CAPTCHA => $html,
    );
}

sub send_comment {    
		my ($self) = @_;
    
    my %params = $self->query->Vars();
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
    
    if ( $dao->not_in_db || !$dao->active ) {
        $self->template( 'blank' );
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => $self->config->get( 'errors.author_not_found.headline' ),
            ERROR_MESSAGE  => $self->config->get( 'errors.author_not_found.message' ),
        });
        return;
    }
    
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