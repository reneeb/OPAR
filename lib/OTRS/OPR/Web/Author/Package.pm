package OTRS::OPR::Web::Author::Package;

use strict;
use warnings;

use Mojo::Base qw(Mojolicious::Controller);

use File::Basename;
use File::Spec;
use Path::Class;

use OTRS::OPR::DAO::Author;
use OTRS::OPR::DAO::Comment;
use OTRS::OPR::DAO::Maintainer;
use OTRS::OPR::DAO::Package;
use OTRS::OPR::DB::Helper::Author  qw(active_authors);
use OTRS::OPR::DB::Helper::Job     qw(create_job find_job);
use OTRS::OPR::DB::Helper::Package (qw(page user_is_maintainer package_exists package_name_object),
                                    { version_list => 'versions' } );
use OTRS::OPR::Web::App::Forms     qw(:all);
use OTRS::OPR::Web::Utils          qw(prepare_select page_list time_to_date);

sub delete_package {
    my ($self) = @_;
    
    my $package = $self->param( 'id' );
    
    if ( $package =~ m{\D}x or $package <= 0 ) {
        return $self->render( json => {} );
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return $self->render( json => { ERROR => 'User is not maintainer' } );
    }
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
        _schema    => $self->schema,
    );
    
    my $deletion = time + $self->opar_config->get( 'time.deletion' );
    $package_dao->deletion_flag( $deletion );
        
    my $job_id = $self->create_job({
        id   => $package,
        type => 'delete',
    });
    
    return $self->render( json => { deletionTime => $self->time_to_date( $deletion ) } );
}

sub undelete_package {
    my ($self) = @_;
    
    my $package = $self->param( 'id' );
    
    if ( $package =~ m{\D} or $package <= 0 ) {
        return $self->render( json => { ERROR => 'Invalid package ID' } );
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return $self->render( json => { ERROR => 'User is not maintainer' } );
    }
    
    my $job = $self->find_job({
        id   => $package,
        type => 'delete',
    });
    
    return $self->render( json => { ERROR => 'Cannot find deletion job' } ) if !$job;
    
    $job->delete;
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
        _schema    => $self->schema,
    );
    
    $package_dao->deletion_flag( 0 );
    return $self->render( json => { Success => 1 } );
}

sub upload_package {
    my ($self,%params) = @_;
    
    my $formid = $self->get_formid;
    $self->stash(
        %params,
        FORMID => $formid,
    );

    my $html = $self->render_opar( 'author_upload' );
    $self->render( text => $html, format => 'html' );
}

sub do_upload_package {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    my %errors;
    
    # check formid
    $errors{formid} = 1 if !$self->check_formid( $params{formid} );
    
    if ( %errors ) {
        $self->notify({
            type    => 'error',
            include => 'notifications/generic_error',
            ERROR_HEADLINE => 'The form ID was invalid',
            ERROR_MESSAGE  => 'The form ID was invalid',
        });
        
        return $self->upload( %params );
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
        
        return $self->upload( %params );
    }
    
    # quickcheck for package name:
    # extract (<Name>.*</Name>) from .opm validate against opr_package_names
    # if user is the main author or co-maintainer, then upload is ok.
    my $package_name = $self->_get_package_name( $file );
    $self->app->log->debug( "Uploaded package: $package_name" );
    my $name_id      = $self->user_is_maintainer( $self->user, { name => $package_name, add => 1 } );

    $self->app->log->debug( "PackageName ID: " . (defined $name_id ? $name_id : '<undef>') );

    if ( !$name_id ) {
        $self->app->log->debug( sprintf "UserID: %d -> Package: %s", $self->user->user_id, $package_name );
        
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'User is not maintainer',
            ERROR_MESSAGE  => 'You are not the maintainer',
        });
        
        unlink $file;
        
        return $self->upload( %params );
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
   
    $package->package_name( $package_name ); 
    $package->uploaded_by( $self->user->user_id );
    $package->path( $file );
    $package->virtual_path( $virtual_path );
    $package->name_id( $name_id );
    $package->upload_time( time );
    $package->description( $params{description} );
    
    for my $tag ( split /\s*,\s*/, $params{tags} ) {
        $package->add_tag( $tag );
    }
    
    $package->save;
    
    $self->app->log->debug( 'created package id ' . $package->package_id );
    
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

    my $html = $self->render_opar( 'blank' );
    $self->render( text => $html, format => 'html' );
}



sub get_tags {
    my ($self) = @_;
    
    my %params = %{ $self->req->params->to_hash || {} };
    my %errors;
    
    return $self->render( json => { tags => '', package => '' } );
    
    # get package name
    my ($file,$version,$suffix) = OTRS::OPR::Web::Utils->validate_opm_name( $params{path} );
    
    if ( !$file ) {
        return $self->render( json => { tags => '' } );
    }
    
    # create new object and save basic information (uploaded_by, name_id, path and virtual path)
    my $package = OTRS::OPR::DAO::Package->new(
        _schema      => $self->schema,
        package_name => $file,
    );
    
    my $tags_string = '';

    if ( !$package->not_in_db ) {
        $tags_string = join ', ', $package->tags;
    }

    return $self->render( json => { tags => $tags_string, package => $file } );
}

sub edit_maintainer {
    my ($self) = @_;

    my %params = %{ $self->req->params->to_hash || {} };
 
    # check formid
    my $formid_ok = $self->validate_formid( \%params );
    if ( !$formid_ok ) {
        #return $self->forgot_password( %uppercase );
    }


    my $id = $self->param( 'id' );
    my ($parsed_name, $package_version) = OTRS::OPR::Web::Utils->validate_opm_name( $id, 1 );
    
    my $package_name = $self->package_name_object( $parsed_name );
    
    return $self->maintainer if !$package_name;
    
    my $name_id      = $package_name->name_id;

    if ( $params{add} ) {
        my $maintainer = OTRS::OPR::DAO::Maintainer->new(
            _schema => $self->schema,
        );
        
        $maintainer->user_id( $params{add} );
        $maintainer->name_id( $package_name->get_column('name_id') );
        $maintainer->is_main_author( 0 );
    }

    if ( $params{remove} ) {
        my $maintainer = OTRS::OPR::DAO::Maintainer->new(
            _schema => $self->schema,
            user_id => $params{remove},
            name_id => $package_name->name_id,
        );
        
        $maintainer->delete if $maintainer;
    }

    $self->maintainer;
}

sub goto_comments {
    my ($self) = @_;
	
    my $comment_id = $self->param( 'id' );

    return $self->comments if !$comment_id;
    
    my $comment = $self->schema->resultset('opr_comments')->find({ comment_id => $comment_id });
    
    return $self->comments if !$comment;
    
    my $package_name = $self->package_name_object( $comment->packagename );
  
    $self->param('package', $package_name->package_name);
    $self->comments;
}

sub publish_comment {
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

sub unpublish_comment {
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

sub delete_comment {
    my ($self) = @_;

    my $comment_id = $self->param( 'id' );
    $self->table( 'opr_comments' )->search({ comment_id => $comment_id})->first->delete;

    $self->goto_comments;
}

sub comments {
    my ($self) = @_;

    my $id = $self->param( 'package' );
    my ($package_name, $package_version) = OTRS::OPR::Web::Utils->validate_opm_name( $id, 1 );

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
        my $author = OTRS::OPR::DAO::Author->new(
            _schema => $self->schema,
            user_id => $self->user->user_id,
        );
        
        for my $package ( $author->packages ) {
            my $package_dao = OTRS::OPR::DAO::Package->new(
                package_id => $package->package_id,
                _schema      => $self->schema,
            );

            push @packages, $package_dao;
        }
    }
    
    for my $package ( @packages ) {
        push @comments, $package->comments;
    }

    @comments = sort{ $b->{COMMENT_ID} <=> $a->{COMMENT_ID} }@comments;

    my $formid = $self->get_formid;
    $self->stash(
        FORMID       => $formid,
        NAME         => $package_name,
        HAS_COMMENTS => (scalar @comments > 0),
        COMMENTS     => \@comments,
    );

    my $html = $self->render_opar( 'author_package_comments' );
    $self->render( text => $html, format => 'html' );
}

sub maintainer {
    my ($self) = @_;
    
    my $id = $self->param( 'id' );
    my ($package_name, $package_version) = OTRS::OPR::Web::Utils->validate_opm_name( $id, 1 );
        
    my $package = OTRS::OPR::DAO::Package->new(
    	package_name => $package_name,
    	version      => $package_version,
        _schema      => $self->schema,
    );
    
    my @co_maintainers = $package->maintainer_list;
    my $maintainer     = shift @co_maintainers;
    
    # get possible co maintainers
    my @possible_co_maintainers;
    my @user = $self->active_authors( sort_by => 'user_name' );
    for my $user ( @user ) {
    	my $user_id = $user->user_id;
        push @possible_co_maintainers, {
            USER_NAME => $user->user_name,
            USER_ID   => $user_id,
        } unless scalar grep { $_ && $_->{USER_ID} == $user_id } ($maintainer, @co_maintainers);
    }
    
    my $is_main_author = ( $maintainer->{USER_ID} == $self->user->user_id );
    
    my $formid = $self->get_formid;
    $self->stash(
        FORMID                      => $formid,
        MAINTAINER                  => $maintainer,
        IS_MAIN_AUTHOR              => $is_main_author,
        HAS_CO_MAINTAINERS          => (scalar @co_maintainers > 0),
        CO_MAINTAINERS              => \@co_maintainers,
        POSSIBLE_CO_MAINTAINERS     => \@possible_co_maintainers,
        HAS_POSSIBLE_CO_MAINTAINERS => (scalar @possible_co_maintainers > 0),
        PACKAGE_NAME                => $package_name,
    );

    my $html = $self->render_opar( 'author_package_maintainer' );
    $self->render( text => $html, format => 'html' );
}

sub list_packages {
    my ($self) = @_;
    
    my $config = $self->opar_config;
    
    my %params      = %{ $self->req->params->to_hash || {} };
    my $search_term = $params{search_term};
    my $page        = $self->param( 'page' ) || 1;
    
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
    
    $self->stash(
        PACKAGES => $packages,
        PAGES    => $pagelist,
    );

    my $html = $self->render_opar( 'author_package_list' );
    $self->render( text => $html, format => 'html' );
}

sub version_list {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    
    $self->app->log->debug( 'Version list for ' . $package );
    
    if ( !$self->package_exists( $package ) ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'No versionlist available',
            ERROR_MESSAGE  => 'The package does not exist, so there is no version list',
        });

        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' );
    }
    
    if ( !$self->user_is_maintainer( $self->user, { name => $package } ) ) {
        $self->notify({
            type           => 'error',
            include        => 'notifications/generic_error',
            ERROR_HEADLINE => 'No versionlist available',
            ERROR_MESSAGE  => 'You are not maintainer of this package, so you cannot see the list of all versions',
        });

        my $html = $self->render_opar( 'blank' );
        return $self->render( text => $html, format => 'html' );
    }
    
    my $version_list = $self->versions( $package, { all => 1 } ) || [];
    
    for my $version ( @{ $version_list } ) {
       $version->{CLASS} = $version->{DELETION} ? 'visible' : 'hidden'
    }
        
    $self->stash(
        VERSIONS     => $version_list,
        PACKAGE_NAME => $package,
    );

    my $html = $self->render_opar( 'author_package_version_list' );
    return $self->render( text => $html, format => 'html' );
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
        
        ($package_name) = $content =~ m{ <Name.*?> \s* ([\w\s-]+) \s* </Name> }xms;
        $package_name =~ s{\s+$}{};
    }
    
    return $package_name || '';
}

sub _upload_file {
    my ($self) = @_;
    
    my $field_name = 'opm_file';
    
    my $upload = $self->req->upload( $field_name );
    
    if ( !$upload ) {
        return 0, 'Cannot open filehandle to read upload';
    }
    
    my $name = $upload->filename;
    
    my ($file,$version,$suffix) = OTRS::OPR::Web::Utils->validate_opm_name( $name );
    
    $file =~ s{[^A-Za-z0-9.-]}{}g;
    
    return (0, 'No valid filename' ) if !$file;
    
    my $user_name = $self->user->user_name;
    
    my $path = Path::Class::Dir->new(
        $self->opar_config->get( 'paths.uploads' ),
        $user_name,
    );
    
    my $v_string = $version ? '-' . $version : '';
    
    my $file_path = Path::Class::File->new(
        $path,
        $$ . '-' . $file . '-' . $version . '.opm',
    );
    
    $self->app->log->debug( "Target file: $file_path" );
    
    if ( -e $file_path ) {
        return 0, 'File already exists';
    }
    
    my $path_stringified = $path->stringify;
    
    mkdir $path_stringified unless -e $path_stringified;
    
    $self->app->log->warn( "Directory $path_stringified does not exist" ) unless -e $path_stringified;

    my $buffer;
    my $something_read = '';

    $upload->move_to( $file_path->stringify );
    if ( !-s $file_path->stringify ) {
        return 0, 'file seems to be empty';
    }
    
    return 1, $file_path->stringify;
}

sub reanalyze_package {
    my ($self) = @_;
	
    my ($package_id) = $self->param('id');

    # check if author is a maintainer of this package
    if ( !$self->user_is_maintainer( $self->user, { id => $package_id } ) ) {
        return $self->list_packages;
    }

    # check if an analyzation job for that package is already scheduled
    my $job = $self->find_job({
        id   => $package_id,
        type => 'analyze',
    });

    if ($job) {
        return $self->list_packages;
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

    return $self->list_packages;
}

1;

