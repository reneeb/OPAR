package OTRS::OPR::Web::Author::Package;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Basename;
use File::Spec;
use Path::Class;

use OTRS::OPR::DAO::Author;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DAO::Maintainer;
use OTRS::OPR::DAO::Package;
use OTRS::OPR::DB::Helper::Job     qw(create_job find_job);
use OTRS::OPR::DB::Helper::Package (qw(page user_is_maintainer package_exists), { version_list => 'versions' } );
use OTRS::OPR::Web::App::Forms     qw(:all);
use OTRS::OPR::Web::App::Prerun    qw(cgiapp_prerun);
use OTRS::OPR::Web::Utils          qw(prepare_select page_list time_to_date);

sub setup {
    my ($self) = @_;

    $self->main_tmpl( $self->config->get('templates.author') );
    
    my $startmode = 'start';
    my $param     = $self->param( 'run' );
    if( $param ){
        $startmode = $param;
    }

    $self->start_mode( $startmode );
    $self->mode_param( 'rm' );
    $self->run_modes(
        AUTOLOAD     => \&list,
        list         => \&list,
        upload       => \&upload,
        do_upload    => \&do_upload,
        delete       => \&delete_package,
        undelete     => \&undelete_package,
        maintainer   => \&maintainer,
        edit_maintainer => \&edit_maintainer,
        versions     => \&version_list,
        show         => \&show,
        comments          => \&comments,
        publish_comment   => \&publish_comment,
        unpublish_comment => \&unpublish_comment,
    );
}

sub delete_package : Permission( 'author' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'id' );
    
    if ( $package =~ m{\D}x or $package <= 0 ) {
        return {};
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return { ERROR => 'User is not maintainer' };
    }
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
        _schema    => $self->schema,
    );
    
    my $deletion = time + $self->config->get( 'time.deletion' );
    $package_dao->deletion_flag( $deletion );
        
    my $job_id = $self->create_job({
        id   => $package,
        type => 'delete',
    });
    
    return { deletionTime => $self->time_to_date( $deletion ) };
}

sub undelete_package : Permission( 'author' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'id' );
    
    if ( $package =~ m{\D} or $package <= 0 ) {
        return { ERROR => 'Invalid package ID' };
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return { ERROR => 'User is not maintainer' };
    }
    
    my $job = $self->find_job({
        id   => $package,
        type => 'delete',
    });
    
    return { ERROR => 'Cannot find deletion job' } if !$job;
    
    $job->delete;
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
        _schema    => $self->schema,
    );
    
    $package_dao->deletion_flag( 0 );
    return { Success => 1 };
}

sub upload : Permission( 'author' ) {
    my ($self) = @_;
    
    my $formid = $self->get_formid;
    $self->template( 'author_upload' );
    $self->stash(
        FORMID => $formid,
    );
}

sub do_upload : Permission( 'author' ) {
    my ($self) = @_;
    
    my %params = $self->query->Vars;
    my %errors;
    
    $self->template( 'blank' );
    
    # check formid
    $errors{formid} = 1 if !$self->check_formid( $params{formid} );
    
    if ( %errors ) {
        $self->notify({
            type    => 'error',
            include => 'notifications/generic_error',
            ERROR_HEADLINE => 'The form ID was invalid',
            ERROR_MESSAGE  => 'The form ID was invalid',
        });
        
        return;
    }
    
    # upload file. This file is needed anyways.
    my ($code, $file) = $self->_upload_file;
    
    if ( !$code ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'Upload error',
            ERROR_MESSAGE  => $file,
        });
        
        return;
    }
    
    # quickcheck for package name:
    # extract (<Name>.*</Name>) from .opm validate against opr_package_names
    # if user is the main author or co-maintainer, then upload is ok.
    my $package_name = $self->_get_package_name( $file );
    $self->logger->trace( "Uploaded package: $package_name" );
    my $name_id      = $self->user_is_maintainer( $self->user, { name => $package_name, add => 1 } );
    if ( !$name_id ) {
        $self->logger->debug( sprintf "UserID: %d -> Package: %s", $self->user->user_id, $package_name );
        
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'User is not maintainer',
            ERROR_MESSAGE  => 'You are not the maintainer',
        });
        
        unlink $file;
        
        return;
    }
    
    # create new object and save basic information (uploaded_by, name_id, path and virtual path)
    my $package = OTRS::OPR::DAO::Package->new(
        _schema => $self->schema,
    );
    
    my $user_name    = $self->user->user_name;
    my $virtual_path = uc
        substr( $user_name, 0, 1 ) . '/' .
        substr( $user_name, 0, 2 ) . '/' .
        $user_name . '/';
    $virtual_path .= $package_name;
    
    $package->uploaded_by( $self->user->user_id );
    $package->path( $file );
    $package->virtual_path( $virtual_path );
    $package->name_id( $name_id );
    $package->upload_time( time );
    
    $package->save;
    
    $self->logger->trace( 'created package id ' . $package->package_id );
    
    # create an entry in job queue that the package
    # should be analyzed    
    my $job_id = $self->create_job({
        id   => $package->package_id,
        type => 'analyze',
    });
    
    $self->notify({
        type             => 'success',
        include          => 'notifications/generic_success',
        SUCCESS_HEADLINE => 'OPM upload successful',
        SUCCESS_MESSAGE  => 'OPM file uploaded and ready for analysis',
    });
}

sub edit_maintainer : Permission( 'author' ) {
    my ($self) = @_;
    my %params = $self->query->Vars;
 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        #return $self->forgot_password( %uppercase );
    }

    my ($package_name, $package_version) = split /\-/, $self->param( 'id' );    
    $package_name = $self->schema->resultset('opr_package_names')->find({ package_name => $package_name });	
    my $name_id = $package_name->get_column("name_id");

    if ($params{'add'}) {
        my $maintainer = OTRS::OPR::DAO::Maintainer->new(
            _schema => $self->schema,
        );
        
        $maintainer->user_id( $params{'add'} );
        $maintainer->name_id( $package_name->get_column('name_id') );
        $maintainer->is_main_author( 0 );
    }

    if ($params{'remove'}) {
        my $maintainer = $self->schema->resultset('opr_package_author')->find({ 
            user_id => $params{'remove'},
            name_id => $package_name->name_id
        });	
		
        $maintainer->delete() if $maintainer;
    }

    $self->maintainer;
}

sub goto_comments : Permission( 'author' ) {
    my ($self) = @_;
	
    my $comment_id = $self->param( 'id' );
    my $comment = $self->schema->resultset('opr_comments')->find({ comment_id => $comment_id });
    my $package_name = $self->schema->resultset('opr_package_names')->find({ package_name => $comment->packagename });
    my $package = $self->schema->resultset('opr_package')->find({ name_id => $package_name->name_id });
  
    $self->param('id', $package_name->package_name);
    $self->comments();
}

sub publish_comment : Permission( 'author' ) {
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

sub unpublish_comment : Permission( 'author' ) {
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

sub comments : Permission( 'author' ) {
    my ($self) = @_;

    my ($package_name, $package_version) = split /\-/, $self->param( 'id' );    

    my @packages = (); # all packages of author OR the single one requested
    my @comments = ();

    if (defined $package_name) {
        my $package_dao = OTRS::OPR::DAO::Package->new(
            package_name => $package_name,
            _schema      => $self->schema,
        );
        
        push @packages, $package_dao;
    }
    else {
        for my $author ($self->table('opr_package_author')->find({ user_id => $self->user->user_id })) {
            for my $package ($self->table('opr_package')->search({ name_id => $author->name_id })) {
                my $package_dao = OTRS::OPR::DAO::Package->new(
                    package_id => $package->package_id,
                    _schema      => $self->schema,
                );

                push @packages, $package_dao;
            }
        }
    }
    
    for my $package ( @packages ) {
        push @comments, $package->comments;
    }

    my $formid = $self->get_formid;
    $self->template( 'author_package_comments' );
    $self->stash(
        FORMID => $formid,
        NAME => $package_name,
        HAS_COMMENTS => (scalar @comments > 0),
        COMMENTS => \@comments,
    );
}

sub maintainer : Permission( 'author' ) {
    my ($self) = @_;
    
    my ($package_name, $package_version) = split /\-/, $self->param( 'id' );        
    my $package = OTRS::OPR::DAO::Package->new(
    	package_name => $package_name,
    	version      => $package_version,
        _schema      => $self->schema,
    );
    
    my @co_maintainers = $package->maintainer_list();
    my $maintainer = shift @co_maintainers;
    
    # get possible co maintainers
    my @possible_co_maintainers = ();
    for my $user ($self->schema->resultset('opr_user')->all()) {
    	my $user_id = $user->get_column('user_id');
        push @possible_co_maintainers, {
            USER_NAME => $user->get_column('user_name'),
            USER_ID   => $user_id,
        } unless scalar grep { $_->{'USER_ID'} == $user_id } ($maintainer, @co_maintainers);
    }
    
    my $is_main_author = ($maintainer->{'USER_ID'} == $self->user->user_id);
    
    my $formid = $self->get_formid;
    $self->template( 'author_package_maintainer' );
    $self->stash(
        FORMID => $formid,
        MAINTAINER => $maintainer,
        IS_MAIN_AUTHOR => $is_main_author,
        HAS_CO_MAINTAINERS => (scalar @co_maintainers > 0),
        CO_MAINTAINERS => \@co_maintainers,
        POSSIBLE_CO_MAINTAINERS => \@possible_co_maintainers,
        HAS_POSSIBLE_CO_MAINTAINERS => (scalar @possible_co_maintainers > 0),
        PACKAGE_NAME => $package_name,
    );
}

sub list : Permission( 'author' ) {
    my ($self) = @_;
    
    my $config = $self->config;
    
    my %params      = $self->query->Vars;
    my $search_term = $params{search_term};
    my $page        = $params{page} || 1;
    
    if ( $page =~ m{\D} or $page <= 0 ) {
        $page = 1;
    }
    
    my ($packages,$pages) = $self->page(
        $page,
        {
            search   => $search_term,
            uploader => $self->user->user_id,
            all      => 1,
        }
    );
    my $pagelist = $self->page_list( $pages, $page );
    
    $self->template( 'author_package_list' );
    $self->stash(
        PACKAGES => $packages,
        PAGES    => $pagelist,
    );
}

sub version_list : Permission( 'author' ) {
    my ($self) = @_;
    
    my $package = $self->param( 'id' );
    
    $self->template( 'blank' );
    
    $self->logger->trace( 'Version list for ' . $package );
    
    if ( !$self->package_exists( $package ) ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'No versionlist available',
            ERROR_MESSAGE  => 'The package does not exist, so there is no version list',
        });
        return;
    }
    
    if ( !$self->user_is_maintainer( $self->user, { name => $package } ) ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'No versionlist available',
            ERROR_MESSAGE  => 'You are not maintainer of this package, so you cannot see the list of all versions',
        });
        return;
    }
    
    my $version_list = $self->versions( $package, { all => 1 } ) || [];
    
    for my $version ( @{ $version_list } ) {
       $version->{CLASS} = $version->{DELETION} ? 'visible' : 'hidden'
    }
        
    $self->template( 'author_package_version_list' );
    $self->stash(
        VERSIONS     => $version_list,
        PACKAGE_NAME => $package,
    );
}

sub _get_package_name {
    my ($self,$file) = @_;
    
    my $package_name = '';
    if ( open my $fh, '<', $file ) {
        my $content = '';
        
        while ( my $line = <$fh> ) {
            if ( $line =~ m{ <Name.*?> }x .. $line =~ m{ </Name> }x ) {
                $content .= $line;
            }
        }
        
        ($package_name) = $content =~ m{ <Name.*?> \s* ([\w-]+) \s* </Name> }xms;
    }
    
    return $package_name || '';
}

sub _upload_file {
    my ($self) = @_;
    
    my $field_name = 'opm_file';
    
    my $fh = $self->query->upload( $field_name );
    
    if ( !$fh ) {
        return 0, 'Cannot open filehandle to read upload';
    }
    
    my $name = $self->query->param( $field_name );
    
    my ($file,$version,$suffix) = $name =~ m{
        ([^\\\/]+)       # filename
        (?:              # begin version
          -(                # dash
            \d+             # major number of version
            (?:\.\d+)?      # optional minor number of version
            (?:\.\d+)?      # optional patch number of version
           )             # version
        )?               # version is optional
        (\.opm)          # file suffix
        \z               # string end
    }xms;
    
    $file =~ s{[^A-Za-z0-9.-]}{}g;
    
    return (0, 'No .opm suffix' ) if !$file;
    
    my $user_name = $self->user->user_name;
    
    my $path = Path::Class::Dir->new(
        $self->config->get( 'paths.uploads' ),
        $user_name,
    );
    
    my $v_string = $version ? '-' . $version : '';
    
    my $file_path = Path::Class::File->new(
        $path,
        $$ . '-' . $file . $version . '.opm',
    );
    
    $self->logger->debug( "Target file: $file_path" );
    
    if ( -e $file_path ) {
        return 0, 'File already exists';
    }
    
    my $path_stringified = $path->stringify;
    
    mkdir $path_stringified unless -e $path_stringified;
    
    $self->logger->warn( "Directory $path_stringified does not exist" ) unless -e $path_stringified;

    my $buffer;
    my $something_read = '';
    
    if(open my $wfh, '>', $file_path->stringify ){
        binmode $wfh;
        while ( read $name, $buffer, 1024 ) {
            print $wfh $buffer;
            $something_read .= $buffer;
        }
        close $wfh;
        
        if ( !$something_read ) {
            $self->logger->warn( "File seems to be empty!" );
            return 0, 'file seems to be empty';
        }
    }
    else {
        $self->logger->warn( "Cannot open target file $file_path" );
        return 0, 'Cannot open target file';
    }
    
    return 1, $file_path->stringify;
}

1;