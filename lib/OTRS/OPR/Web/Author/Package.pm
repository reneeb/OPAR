package OTRS::OPR::Web::Author::Package;

use strict;
use warnings;

use parent qw(OTRS::OPR::Web::App);

use File::Basename;
use File::Spec;
use Path::Class;

use OTRS::OPR::DAO::Package;
use OTRS::OPR::Web::App::Forms qw(check_formid get_formid);
use OTRS::OPR::Web::App::Prerun;

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
        AUTOLOAD    => \&list,
        list        => \&list,
        upload      => \&upload,
        do_upload   => \&do_upload,
        delete      => \&delete,
        undelete    => \&undelete,
        maintainer  => \&maintainer,
    );
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
    
    my %params = $self->query->Vars();
    my %errors;
    
    $self->template( 'author_uploaded' );
    
    # check formid
    $errors{formid} = 1 if !$self->check_formid( $params{formid} );
    
    if ( %errors ) {
        $self->notify({
            type    => 'error',
            include => 'notifications/generic_error',
        });
        
        $self->stash(
            ERROR_HEADLINE => 'The form ID was invalid',
            ERROR_MESSAGE  => '',
        );
        
        return;
    }
    
    # upload file. This file is needed anyways.
    my ($file,$virtual_path) = $self->_upload_file;
    
    # quickcheck for package name:
    # extract (<Name>.*</Name>) from .opm validate against opr_package_names
    # if user is the main author or co-maintainer, then upload is ok.
    my $package_name = $self->_get_package_name( $file );
    if ( !$self->user_is_maintainer( $self->user, $package_name ) ) {
        $self->notify({
            type    => 'error',
            include => 'notifications/generic_error',
        });
        
        $self->stash(
            ERROR_HEADLINE => 'User is not maintainer',
            ERROR_MESSAGE  => '',
        );
        
        return;
    }
    
    # create new object and save basic information (uploaded_by, name_id, path and virtual path)
    my $package = OTRS::OPR::DAO::Package->new(
        _schema => $self->schema,
    );
    
    $package->uploaded_by( $self->user->user_id );
    $package->path( $file );
    $package->virtual_path( $virtual_path );
}

sub list : Permission( 'author' ) {
    my ($self) = @_;
    
    $self->template( 'author_home' );
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

sub _upload_file{
    my ($self) = @_;
    
    my $field_name = 'opm_file';
    
    my $fh = $self->query->upload( $field_name );
    binmode $fh;
    
    my $name = $self->query->param( $field_name );
    
    my ($file,$suffix) = $name =~ /([^\\\/]+)(\.[^.]*)$/;
    $file =~ s{[^A-Za-z0-9.-]}{}g;
    $file .= '.opm';
    
    my $user_name = $self->user->user_name;
    
    my $path = Path::Class::Dir->new(
        $self->config->get( 'paths.uploads' ),
        $user_name,
    );
    
    
    
    my $file_path = Path::Class::File->new(
        $path,
        $file,
    );
    
    mkdir $path unless -e $path;

    my $buffer;
    if(open my $wfh, '>', $file_path->stringify ){
        binmode $wfh;
        while(read $fh,$buffer,1024){
            print $wfh $buffer;
        }
        close $wfh;
    }
    
    return $file_path->stringify;
}

1;