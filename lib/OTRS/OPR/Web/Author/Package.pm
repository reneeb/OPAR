package OTRS::OPR::Web::Author::Package;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Basename;
use File::Spec;
use Path::Class;

use OTRS::OPR::DAO::Package;
use OTRS::OPR::DAO::Author;
use OTRS::OPR::DB::Helper::Job     qw(create_job find_job);
use OTRS::OPR::DB::Helper::Package qw(page user_is_maintainer);
use OTRS::OPR::Web::App::Forms     qw(check_formid get_formid);
use OTRS::OPR::Web::App::Prerun    qw(cgiapp_prerun);
use OTRS::OPR::Web::Utils          qw(prepare_select page_list);

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
        version_list => \&version_list,
        show         => \&show,
    );
}

sub delete_package : Permission( 'author' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    
    if ( $package =~ m{\D}x or $package <= 0 ) {
        return {};
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return { ERROR => 'User is not mainteiner' };
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
    
    return { delete_until => $deletion };
}

sub undelete_package : Permission( 'author' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
    
    if ( $package =~ m{\D} or $package <= 0 ) {
        return {};
    }
    
    if ( !$self->user_is_maintainer( $self->user, { id => $package } ) ) {
        return { ERROR => 'User is not mainteiner' };
    }
    
    my $job = $self->find_job(
        id   => $package,
        type => 'delete',
    );
    
    $job->delete;
    
    my $package_dao = OTRS::OPR::DAO::Package->new(
        package_id => $package,
        _schema    => $self->schema,
    );
    
    $package_dao->deletion_flag( 0 );
    return { deletion_flag => 0 };
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

sub maintainer : Permission( 'author' ) {
    my ($self) = @_;
    
    my $formid = $self->get_formid;
    
    $self->template( 'author_package_maintainer' );
    $self->stash(
        FORMID => $formid,
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
    my $pagelist          = $self->page_list( $pages, $page );
    
    $self->template( 'author_package_list' );
    $self->stash(
        PACKAGES => $packages,
        PAGES    => $pagelist,
    );
}

sub version_list : Permission( 'author' ) : Json {
    my ($self) = @_;
    
    my $package = $self->param( 'package' );
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
        
        ($package_name) = $content =~ m{ <Name.*?> \s* (\w+) \s* </Name> }xms;
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
        -(\d+\.\d+\.\d+) # version
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
    
    my $file_path = Path::Class::File->new(
        $path,
        $file . '-' . $version . '.opm',
    );
    
    $self->logger->debug( "Target file: $file_path" );
    
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