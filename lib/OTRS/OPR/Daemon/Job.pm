package OTRS::OPR::Daemon::Job;

use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Log::Log4perl;

use OTRS::OPM::Analyzer;
use OTRS::OPR::DB::Schema;
use OTRS::OPR::Doc::Converter;

sub new {
    my ( $class, %args ) = @_;
    
    my $self = bless {}, $class;
    
    for my $needed ( qw(job_id old_state analyzer_config config) ) {
        return if !$args{$needed};
    }
    
    # set some basic attributes
    $self->job_id( $args{job_id} );
    $self->old_state( $args{old_state} );
    $self->analyzer_config( $args{analyzer_config} );
    $self->config( $args{config} );
    
    # initialize db connection
    $self->_init_db;
    
    return $self;
}

sub analyzer_config {
    my ( $self, $config ) = @_;
    
    $self->{__analyzer_config__} = $config if @_ == 2;
    return $self->{__analyzer_config__};
}

sub run {
    my ($self) = @_;
    
    # get logger
    my $logger = Log::Log4perl->get_logger;
    
    my ($job) = $self->table( 'opr_job_queue' )->find( $self->job_id );
    $logger->trace( 'forked for job ' . $job->job_id );
    
    # run job
    my $result;
    my $job_type = $job->opr_job_type->type_label;
    
    if ( $job_type eq 'analyze' ) {
        $result = $self->analyze_package( $job );
    }
    elsif ( $job_type eq 'delete' ) {
        $result = $self->delete_package( $job );
    }
    elsif ( $job_type eq 'comment' ) {
        $result = $self->delete_comment( $job );
    }
    else {
        $logger->warn( "unknown job type: " . $job_type );
    }
    
    # delete job from queue if successful
    if ( $result ) {
        $job->delete;
        $logger->info( 'deleted job ' . $job->job_id );
    }
    
    $self->_teardown;

    my $graphs = $self->create_activity_graphs( $job ) || {};
    return $graphs;
}

sub create_activity_graphs {
    my ( $self, $job ) = @_;

    my $logger = Log::Log4perl->get_logger;

    $logger->info( 'create activity graph for job ' . $job->job_id );

    # get the package object that belongs to the job
    my $package = $self->table( 'opr_package' )->find( $job->package_id );
    return if !$package;

    my $user = $self->table( 'opr_user' )->search({ user_id => $package->uploaded_by })->first;
    my $name = $self->table( 'opr_package_names' )->search({ name_id => $package->name_id })->first;

    $logger->info( 'user found (id ' . $package->uploaded_by . ') - ' . ($user ? 'success' : 'fail') );
    $logger->info( 'name found (id ' . $package->name_id . ') - ' . ($name ? 'success' : 'fail') );

    return if !$user || !$name;

    return { user => $user->user_name, package => $name->package_name, package_id => $job->package_id };
}

sub analyze_package {
    my ( $self, $job ) = @_;
    
    # if job state was 'stalled', delete possibly existing info about the package
    if ( $self->old_state eq 'stalled' ) {
        $self->table( 'opr_oq_result' )->search({
            package_id => $job->package_id,
        })->delete;
    }
    
    # get the package object that belongs to the job
    my $package = $self->table( 'opr_package' )->find( $job->package_id );
    return if !$package;
    
    # analyse package
    my $analyzer = OTRS::OPM::Analyzer->new(
        configfile => $self->analyzer_config,
    );
    
    my $result = $analyzer->analyze( $package->path );
    return if !$result;
    
    # save basic data of file
    $self->_save_basic_info( $package, $analyzer->opm );
    
    # convert documentation to html
    $self->_save_documentation( $package, $analyzer->opm );
        
    # save analysis data in db
    # double check that there is no data about that package in the database
    $self->_save_analysis_data( $package, $result );
    
    return 1;
}

sub _save_basic_info {
    my ( $self, $package, $opm ) = @_;
    
    my $logger = Log::Log4perl->get_logger;
    
    my $name = $opm->name;
    
    for my $attr ( qw/description version/ ) {
        if ( $package->can( $attr ) && $opm->can( $attr ) ) {
            $package->$attr( $opm->$attr() );
            $logger->trace( "set $attr for $name" );
        }
    }

    # ---
    # save framework version in extra table for dropdown
    for my $version ( $opm->framework ) {
        (my $otrs) = $version =~ m{(\d+\.\d+)};
        $self->table( 'opr_framework_versions' )->find_or_create( { framework => $otrs } );
    }
    # ---

    $package->framework( join ', ', $opm->framework );
    $logger->trace( "set framework for $name" );
    
    $package->website( $opm->url );
    $logger->trace( "set website for $name" );
    
    $package->is_in_index( 1 );
    
    # save the updates
    $package->update;
    
    # delete dependencies that already exist for the given package
    $self->table( 'opr_package_dependencies' )->search({
        package_id => $package->package_id,
    })->delete;
    
    # save dependencies
    for my $dep ( $opm->dependencies ) {
        my $dep_row = $self->table( 'opr_package_dependencies' )->create({
            package_id         => $package->package_id,
            dependency         => $dep->{name},
            dependency_type    => lc( $dep->{type} ),
            dependency_version => $dep->{version},
        })->update;
        
        $logger->trace( 'added dependency ' . $dep->{name} . ' for package ' . $name );
    }
    
    return 1;
}

sub _save_documentation {
    my ( $self, $package, $opm ) = @_;
    
    my $logger = Log::Log4perl->get_logger;
    
    # find documentation
    my $docu = $opm->documentation( type => 'pod' ) || {};
    
    return if $docu->{filename} !~ m{\.pod \z }x;
    
    my $converter = OTRS::OPR::Doc::Converter->new(
        raw => $docu->{content},
    );
    
    my $html = $converter->convert;
    $logger->trace( "HTML-Documentation: " . $html );
    
    return if !$html;
    
    $package->documentation( $html );
    $package->documentation_raw( $docu->{content} );
    
    # save the updates
    $package->update;
    
    return 1;
}

sub _save_analysis_data {
    my ( $self, $package, $results ) = @_;
    
    my $logger = Log::Log4perl->get_logger;
    $logger->info( 'save analysis results' );
    
    $logger->trace( Dumper $results );
    
    if ( !$results || ref $results ne 'HASH' ) {
        $logger->warn( 'no results found' );
    }
    
    my $package_id = $package->package_id;
    
    # delete old oq results for the package
    $self->table( 'opr_oq_result' )->search({
        package_id => $package_id,
    })->delete;
    
    
    my @entities   = $self->table( 'opr_oq_entity' )->all;
    my %entity_map = map { $_->module => $_->oq_id }@entities;
    
    MODULE:
    for my $module ( keys %{$results} ) {
        my $oq_id = $entity_map{$module};
        if ( !$oq_id ) {
            $logger->warn( "did not found an ID for OQ module $module" );
            next MODULE;
        }
        
        if ( !ref $results->{$module} ) {
            $self->table( 'opr_oq_result' )->create({
                package_id => $package_id,
                oq_id      => $oq_id,
                oq_result  => $results->{$module},
            })->update;
            
            $logger->info( "set oq result for module $module and package $package_id" );
            next MODULE;
        }
        
        for my $file ( keys %{ $results->{$module} } ) {
            my $text = $results->{$module}->{$file};
            $self->table( 'opr_oq_result' )->create({
                package_id => $package_id,
                oq_id      => $oq_id,
                oq_result  => $text,
                filename   => $file,
            })->update;
            
            $logger->info( "set oq result for module $module and package $package_id" );
        }
    }
    
    return 1;
}

sub delete_package {
    my ( $self, $job ) = @_;
    
    # get package that belongs to the job
    my ($package) = $self->table( 'opr_package' )->search({
        package_id => $job->package_id,
    });
    
    my $logger  = Log::Log4perl->get_logger;
    my $message = sprintf "delete all information about package %s version %s",
        $package->opr_package_names->package_name, $package->version;

    $logger->info( $message );
    
    # delete all information about the package
    # this includes authorship, main info, job queue, dependencies, oq values
    $package->opr_oq_result->delete;
    $package->opr_package_dependencies->delete;
    
    # if this is the last package of the given name delete the authors, too.
    my @packages = $package->opr_package_names->opr_package;
    if ( !@packages ) {
        $package->opr_package_author->delete;
    }
    
    $package->delete;
    
    return 1;
}

sub delete_comment {
    my ($self,$job) = @_;
    
    $self->table( 'opr_comments' )->search({
        comment_id => $job->package_id,
    })->delete;
    
    return 1;
}

sub config {
    my ($self,$config) = @_;
    
    $self->{__config__} = $config if @_ == 2;
    return $self->{__config__};
}

sub table {
    my ( $self, $name ) = @_;
    
    return $self->{__schema__}->resultset( $name );
}

sub job_id {
    my ( $self, $id ) = @_;
    
    $self->{__job_id__} = $id if @_ == 2;
    return $self->{__job_id__};
}

sub old_state {
    my ( $self, $state ) = @_;
    
    $self->{__old_state__} = $state if @_ == 2;
    return $self->{__old_state__};
}

sub _init_db {
    my ( $self ) = @_;
    
    my $config = $self->config;
    my $user   = $config->get( 'db.user' );
    my $passwd = $config->get( 'db.passwd' );
    my $host   = $config->get( 'db.host' );
    my $db     = $config->get( 'db.name' );
    my $type   = $config->get( 'db.type' );
    
    $self->{__schema__} = OTRS::OPR::DB::Schema->connect(
        "DBI:$type:$db:$host",
        $user,
        $passwd,
    );
}

sub _teardown {
    my ($self) = @_;
    
    $self->{__schema__}->storage->disconnect;
}

1;
