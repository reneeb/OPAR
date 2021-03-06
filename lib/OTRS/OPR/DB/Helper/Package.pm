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
    package_to_hash
    package_name_object
    activity
);

sub activity {
    my ($self, %params) = @_;

    my $package = $self->table( 'opr_package_names' )->search({ package_name => $params{id} })->first;
    my @uploads = $self->table( 'opr_package' )->search({
        name_id     => $package->name_id,
        upload_time => { '>=', $params{start} || 0 },
    });

    my @upload_times = map{ $_->upload_time }@uploads;
    return @upload_times;
}

sub package_name_object {
    my ( $self, $name ) = @_;
    
    return if !$name;
    
    my ($object) = $self->table( 'opr_package_names' )->search({
        package_name => $name,
    });
    
    return $object;
}

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
    
    my $rows = $params->{rows} || $self->opar_config->get( 'rows.search' );
    
    my %search_clauses;
    if ( exists $params->{search} ) {
        my $term = $params->{search} || '';
        $term    =~ tr/*/%/;
        my @ors;
        for my $field ( 'opr_package_names.package_name', 'description' ) {
            next unless $term;
            push @ors, { $field => { LIKE => '%' . $term . '%' } };
            $search_clauses{'-or'} = \@ors;
        }
    }

    my $framework_version = '%';
    if ( $params->{framework} ) {
        $params->{framework}       =~ s{[^0-9\.x]}{}g;
        $search_clauses{framework} = { LIKE => '%' . $params->{framework} . '.%' };
        $framework_version         = '%' . $params->{framework} . '.%';

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
            'me.package_id' => {
                '=' => \"(SELECT package_id FROM opr_package WHERE name_id = me.name_id AND framework LIKE '$framework_version' ORDER BY upload_time DESC LIMIT 1)"
            },
        },
        {
            page      => $page,
            rows      => $rows,
            order_by  => 'max(upload_time) DESC',
            group_by  => [ 'opr_package_names.package_name' ],
            join      => 'opr_package_names',
            '+select' => [
                'opr_package_names.package_name', 
                { max => 'version', '-as' => 'max_version' },
                { max => 'upload_time', '-as' => 'latest_time' },
            ],
        },
    );
    
    my @packages = $resultset->all;    
    my $pages    = $resultset->pager->last_page || 1;
        
    my @packages_for_template;
    for my $package ( @packages ) {
        my $info = package_to_hash( $self, $package, $params );

        if ( $params->{downloads} ) {
            my $sum_result = $self->table( 'opr_package' )->search(
                { name_id => $package->name_id },
                { select  => [ { sum => 'downloads', '-as' => 'sum_downloads' } ] },
            )->first;
            $info->{DOWNLOADS} = $sum_result->get_column( 'sum_downloads' );
        }
        
        # create the infos for the template
        push @packages_for_template, $info;
    }
    
    return ( \@packages_for_template, $pages );
}

sub version_list {
    my ($self,$name,$params) = @_;
    
    return unless $name;
    
    my %search_clauses = (
        'opr_package_names.package_name' => $name,
    );

    my %other_options;
    my @selects = qw(opr_package_names.package_name);
        
    if ( exists $params->{uploader} ) {
        $search_clauses{uploaded_by} = $params->{uploader};
    }
    
    if ( !$params->{all} ) {
        $search_clauses{is_in_index} = 1;
    }

    if ( $params->{not_framework} ) {
        $search_clauses{framework} = { '!=' => $params->{not_framework} };
        push @selects, { max => 'version', '-as' => 'max_version' };
        push @selects, { max => 'upload_time', '-as' => 'latest_time' };
        $other_options{group_by} = [ 'framework' ];
    }
   
    my $resultset = $self->table( 'opr_package' )->search(
        {
            %search_clauses,
        },
        {
            order_by  => 'package_id',
            join      => 'opr_package_names',
            '+select' => [ @selects ],
            %other_options,
        },
    );
    
    my @packages = $resultset->all;
        
    my @packages_for_template;
    for my $package ( @packages ) {
        
        my $info = package_to_hash( $self, $package, $params );
        
        if ( $package->deletion_flag ) {
            $info->{DELETION_PRE}  = 'Un';
            $info->{DELETION_DATE} = time_to_date( $self, $package->deletion_flag );
        }

        $info->{DOWNLOADS} = $package->downloads;
        
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
        
        my $package_name_id;
        if ( !$package_name_exists ) {
            if ( $package_params->{add} ) {
                my ($package_name) = $self->table( 'opr_package_names' )->create({
                    package_name => $package_params->{name},
                });
                 
                $package_name->update;
                $package_name_id = $package_name->name_id;

                my ($package_author) = $self->table( 'opr_package_author' )->create({
                    user_id        => $user_dao->user_id,
                    name_id        => $package_name_id,
                    is_main_author => 1,
                });

                $package_author->update;
                 
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

sub package_to_hash {
    my ($self,$package,$params) = @_;
        
    # show just a short excerpt of the text if it is too long
    my ($text) = $package->opr_package_names->package_name;
    $text      = substr( $text, 0, 37 ) . '...' if $params->{short} and 40 < length $text;
        
    # show just a short excerpt of the description if it is too long
    my $desc = $package->description;
    $desc    = substr( $desc, 0, 57 ) . '...' if $params->{short} and 60 < length $desc;
        
    my ($author) = $package->opr_user;

    my $max_version = '';
    eval { $max_version = $package->get_column( 'max_version' ); };
        
    my $latest = '';
    eval { $latest = $package->get_column( 'latest_time' ); };

    $latest = time_to_date( $self, $latest ) if $latest;
        
    # create the infos for the template
    my $info = {
        NAME         => $text,
        VERSION      => $package->version,
        DESCRIPTION  => $desc,
        AUTHOR       => ($author ? $author->user_name : '' ),
        DATE         => time_to_date( $self, $package->upload_time ),
        PACKAGE_ID   => $package->package_id,
        DELETION     => $package->deletion_flag,
        VIRTUAL_PATH => $package->virtual_path,
        WEBSITE      => $package->website,
        BUGTRACKER   => $package->bugtracker,
        FRAMEWORK    => $package->framework,
        UPLOAD       => $package->upload_time,
	MAX_VERSION  => $max_version,
        LATEST       => $latest,
    };
    
    return $info;
}

1;
