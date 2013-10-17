package OTRS::OPR::Daemon;

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Temp qw(tempdir);
use Log::Log4perl;
use Parallel::ForkManager;
use Path::Class;

use OTRS::OPR::Daemon::Job;
use OTRS::OPM::Analyzer;
use OTRS::OPM::Analyzer::Utils::Config;
use OTRS::OPR::DB::Schema;
use OTRS::OPR::App::Activity;

sub new {
    my ( $class, %args ) = @_;
    
    my $self = bless {}, $class;
    
    # set config directory
    $self->_conf_dir( $args{config} );
    
    # initialize logging
    $self->_init_logging;
    
    # initialize db connection
    $self->_init_db;
    
    return $self;
}

sub run {
    my ($self) = @_;
    
    # get logger
    my $logger = Log::Log4perl->get_logger;
    
    # set all jobs with state 'running' to 'stalled' if they were started long time ago
    my @running_jobs = $self->table( 'opr_job_queue' )->search({
        job_state => [qw/running/],
    });
    
    my $max_time = $self->config->get( 'analyzer.max_time' );
    for my $job ( @running_jobs ) {
        if ( time - $job->changed > $max_time ) {
            $job->job_state( 'stalled' );
            $logger->info( 'set state of job ' . $job->job_id . ' to "stalled"' );
        }
    }
        
    # get 'open' and 'stalled' jobs
    my @jobs_to_run = $self->table( 'opr_job_queue' )->search({
        job_state => [qw(open stalled)],
    });
    
    $logger->info( 'found ' . @jobs_to_run . ' jobs to run!' );
    
    my $local_config = $self->_analyzer_conf->stringify;
    
    # set state to 'running' this is done so early to avoid race conditions
    my @job_info;
    
    for my $job ( @jobs_to_run ) {
        push @job_info, {
            old_state       => $job->job_state,
            job_id          => $job->job_id,
            analyzer_config => $local_config,
            config          => $self->config,
        };
        
        $job->job_state( 'running' );
        $job->changed( time );
        $job->update;
        
        $logger->trace( 'set job state (job id=' . $job->job_id . ') to running' );
    }
    
    # init fork manager
    my $tempdir       = tempdir( CLEANUP => 1 );
    my $max_processes = $self->config->get( 'fork.max' );
    my $fork_manager  = Parallel::ForkManager->new( $max_processes, $tempdir );
    $logger->trace( 'init fork manager with max ' . $max_processes . ' processes' );

    my @activity_graphs;
    $fork_manager->run_on_finish( sub {
        push @activity_graphs, $_[5];
    });
    
    $self->{__schema__}->storage->disconnect;
    
    for my $tmpjob ( @job_info ) {
        
        # do the fork
        $fork_manager->start and next;

        $logger->trace( 'start handling job ' . $tmpjob->{job_id} );
        
        # create job and run it
        my $job = OTRS::OPR::Daemon::Job->new(
            %{$tmpjob},
        );
        my $graphs = {};
        $graphs = $job->run if $job;

        $logger->trace( 'created daemon_job object for job ' . $tmpjob->{job_id} . ' (' . ($job ? 'success' : 'fail') . ')' );
        $logger->trace( 'Graphs info: ' . Dumper $graphs );
 
        # exit the forked process
        $fork_manager->finish(0, $graphs);
    }
    
    $fork_manager->wait_all_children;
    $logger->trace( 'Graphs info (all): ' . Dumper \@activity_graphs );

    $self->_init_db;

    my $activity = OTRS::OPR::App::Activity->new(
        schema     => $self->{__schema__},
        output_dir => File::Spec->catdir( $self->_base_conf->get( 'paths.base' ), 'public', 'img', 'activities' ),
        #logger     => $logger,
    );

    for my $graphs ( @activity_graphs ) {
        $logger->info( 'create activity graph for user ' . $graphs->{user} );
        $activity->create_activity( type => 'author',  id => $graphs->{user} );

        $logger->info( 'create activity graph for package ' . $graphs->{package} );
        $activity->create_activity( type => 'package', id => $graphs->{package} );
    }
}

sub config {
    my ($self) = @_;
    
    if ( !$self->{__config__} ) {
        $self->_init_config;
    }
    
    return $self->{__config__};
}

sub table {
    my ( $self, $name ) = @_;
    
    return $self->{__schema__}->resultset( $name );
}

sub _conf_dir {
    my ($self,$value) = @_;

    if ( $ENV{OPAR_CONFIG} && $value ) {
        $value = dirname $ENV{OPAR_CONFIG};
    }
    
    if ( $value ) {
        $self->{__config_dir__} = Path::Class::Dir->new( $value );
    }
    
    return $self->{__config_dir__};
}

sub _analyzer_conf {
    my ($self) = @_;
    
    unless ( $self->{__analyzer_config__} ) {
        $self->{__analyzer_config__} = Path::Class::File->new(
            $self->_conf_dir,
            'base.yml',
        );
    }
    
    return $self->{__analyzer_config__};
}

sub _base_conf {
    my ($self) = @_;
    
    $self->{__base_config__} ||= OTRS::OPM::Analyzer::Utils::Config->new(
        $self->_analyzer_conf->stringify,
    );

    $self->{__base_config__};
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

sub _init_config {
    my ($self) = @_;
    
    my $config_file = Path::Class::File->new(
        $self->_conf_dir,
        'daemon.yml',
    );
    
    if ( !-e "$config_file" ) {
        $config_file = Path::Class::File->new(
            $self->_base_conf->get( 'paths.conf' ),
            'daemon.yml',
        );
    }
    
    $self->{__config__} = OTRS::OPM::Analyzer::Utils::Config->new(
        "$config_file",
    );
}

sub _init_logging {
    my ($self) = @_;
    
    my $logging_conf = Path::Class::File->new(
        $self->_conf_dir,
        'logging.conf',
    );

    if ( !-e "$logging_conf" ) {
        $logging_conf = Path::Class::File->new(
            $self->_base_conf->get( 'paths.conf' ),
            'logging.conf',
        );
    }
    
    Log::Log4perl->init( "$logging_conf" );
}

1;
