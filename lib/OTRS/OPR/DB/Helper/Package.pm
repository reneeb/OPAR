package OTRS::OPR::DB::Helper::Package;

use strict;
use warnings;

use parent 'OTRS::OPR::Exporter::Aliased';

use OTRS::OPR::Web::Utils qw(time_to_date);

our @EXPORT_OK = qw(
    page
    user_is_maintainer
    package_exists
    version_list
);

sub package_exists {
    my ( $self, $name, $params ) = @_;
    
    return if !$name;
    
    my %where = (
        package_name => $name,
    );
    
    if ( $params->{version} ) {
        $where{'opr_package.version'} = $params->{version};
    }
    
    my ($package) = $self->table( 'opr_package_names' )->search(
        \%where,
        {
            join => 'opr_package',
        },
    );
    
    return $package;
}

sub page {
    my ($self,$page,$params) = @_;
    
    my $rows = $self->config->get( 'rows.search' );
    
    my %search_clauses;
    if ( exists $params->{search} ) {
        my $term = $params->{search} || '';
        $term    =~ tr/*/%/;
        for my $field ( 'opr_package_names.package_name', 'description' ) {
            next unless $term;
            $search_clauses{$field} = { LIKE => '%' . $term . '%' };
        }
    }
    
    if ( exists $params->{uploader} ) {
        $search_clauses{uploaded_by} = $params->{uploader};
    }
    
    if ( !$params->{all} ) {
        $search_clauses{is_in_index} = 1;
    }
    
    my $resultset = $self->table( 'opr_package' )->search(
        {
            %search_clauses,
        },
        {
            page      => $page,
            rows      => $rows,
            order_by  => 'package_id',
            group_by  => [ 'opr_package_names.package_name' ],
            join      => 'opr_package_names',
            '+select' => [ 'opr_package_names.package_name' ],
        },
    );
    
    my @packages = $resultset->all;    
    my $pages    = $resultset->pager->last_page || 1;
        
    my @packages_for_template;
    for my $package ( @packages ) {
        
        # create the infos for the template
        push @packages_for_template, _package_to_hash( $self, $package, $params );
    }
    
    return ( \@packages_for_template, $pages );
}

sub version_list {
    my ($self,$name,$params) = @_;
    
    return unless $name;
    
    my %search_clauses = (
        'opr_package_names.package_name' => $name,
    );
        
    if ( exists $params->{uploader} ) {
        $search_clauses{uploaded_by} = $params->{uploader};
    }
    
    if ( !$params->{all} ) {
        $search_clauses{is_in_index} = 1;
    }
    
    my $resultset = $self->table( 'opr_package' )->search(
        {
            %search_clauses,
        },
        {
            order_by  => 'package_id',
            join      => 'opr_package_names',
            '+select' => [ 'opr_package_names.package_name' ],
        },
    );
    
    my @packages = $resultset->all;
        
    my @packages_for_template;
    for my $package ( @packages ) {
        
        my $info = _package_to_hash( $self, $package, $params );
        
        if ( $package->deletion_flag ) {
            $info->{DELETION_PRE}  = 'un';
            $info->{DELETION_DATE} = time_to_date( $self, $package->deletion_flag );
        }
        
        # create the infos for the template
        push @packages_for_template, $info;
    }
    
    return \@packages_for_template;
}

sub user_is_maintainer {
    my ($self,$user_dao,$package_params) = @_;
    
    if ( !exists $package_params->{name} and !exists $package_params->{id} ) {
        return;
    }
    
    if ( $package_params->{name} ) {
        my ($package_name_exists) = $self->table( 'opr_package_names' )->search({
            package_name => $package_params->{name},
        });
        
        if ( !$package_name_exists ) {
             if ( $package_params->{add} ) {
                 my ($package_name) = $self->table( 'opr_package_names' )->create({
                     package_name => $package_params->{name},
                 });
                 
                 $package_name->update;
                 
                 my ($package_author) = $self->table( 'opr_package_author' )->create({
                     user_id        => $user_dao->user_id,
                     name_id        => $package_name->name_id,
                     is_main_author => 1,
                 });
                 
                 return $package_name->name_id;
             }
             
             return 0;
        }
        
        
        my ($exists) = $self->table( 'opr_package_author' )->search(
            {
                user_id                          => $user_dao->user_id,
                'opr_package_names.package_name' => $package_params->{name},
            },
            {
                'join'    => 'opr_package_names',
                '+select' => [ 'is_main_author', 'opr_package_names.name_id' ],
            },
        );
        
        return if !$exists;
        
        if ( $package_params->{main_author} ) {
            return $exists->is_main_author ? $exists->name_id : 0;
        }
        
        return $exists->name_id if $exists;
    }
    elsif ( $package_params->{id} ) {
        my ($exists) = $self->table( 'opr_package_author' )->search(
            {
                'user_id'                => $user_dao->user_id,
                'opr_package.package_id' => $package_params->{id},
            },
            {
                'join'    => { 'opr_package_names' => 'opr_package' },
                '+select' => [ 'is_main_author', 'opr_package_names.name_id' ],
            },
        );
        
        return if !$exists;
        
        if ( $package_params->{main_author} ) {
            return $exists->is_main_author ? $exists->name_id : 0;;
        }
        
        return 1;
    }
    
    return;
}

sub _package_to_hash {
    my ($self,$package,$params) = @_;
        
    # show just a short excerpt of the text if it is too long
    my ($text) = $package->opr_package_names->package_name;
    $text      = substr( $text, 0, 37 ) . '...' if $params->{short} and 40 < length $text;
        
    # show just a short excerpt of the description if it is too long
    my $desc = $package->description;
    $desc    = substr( $desc, 0, 57 ) . '...' if $params->{short} and 60 < length $desc;
        
    my ($author) = $package->opr_user;
        
    # create the infos for the template
    my $info = {
        NAME        => $text,
        VERSION     => $package->version,
        DESCRIPTION => $desc,
        AUTHOR      => ($author ? $author->user_name : '' ),
        __SCRIPT__  => $self->base_url,
        DATE        => time_to_date( $self, $package->upload_time ),
        PACKAGE_ID  => $package->package_id,
    };
    
    return $info;
}

1;