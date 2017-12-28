#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 20;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;
use lib $dir;

use MyUnittests;
use OTRS::OPR::DAO::User;

my $schema = schema();

ok $schema, 'schema was created';

my $max_id = get_inserts( 'opr_job_queue' );
is $max_id, 1, 'Inserted package names in "job_queue"';

my $job_types = get_inserts( 'opr_job_type' );
is $job_types, 2, 'Inserted job types in "job_types"';

{

    {
        package MockObject;
        use MyUnittests;
        use OTRS::OPR::Web::App::Config;
        use OTRS::OPR::DB::Helper::Job qw(create_job find_job);
        
        sub new { bless {}, shift }
        sub table { shift; schema()->resultset( shift ); }
        sub config { OTRS::OPR::Web::App::Config->new( $dir . '/tests.yml' ) }
        
    }
    
    my $mock = MockObject->new;

    my $job_id = $mock->create_job({ type => 'analyze', id => 1 });  
    ok $job_id, 'Analyze package 1 - job created';
    is $job_id, $max_id+1, 'correct job_id';
    
    my $job = $mock->find_job({ type => 'analyze', id => 1 });
    is $job->job_id, $job_id, 'found job to analyze package 1';
    
    ok $job->created, 'created attr set';
    ok $job->changed, 'changed attr set';
    is $job->package_id, 1, 'package_id: 1';
    is $job->job_state, 'open', 'state: open';
    
    ok !$mock->find_job({type => 'hello'}), 'no id given';
    ok !$mock->find_job(), 'no params given';
    ok !$mock->find_job({id => 9999999}), 'no type given';
    ok !$mock->find_job({type => 'hello', id => 1}), 'invalid type';
    ok !$mock->find_job({type => 'analyze', id => 999999999}), 'invalid id';
    
    my $prepared_job = $mock->find_job({ type => 'delete', id => 2 });
    ok $prepared_job, 'found prepared job';
    is $prepared_job->job_id, 1, 'correct id of prepared job';
    is $prepared_job->created, 12345, 'correct created timestamp';
    is $prepared_job->changed, 67890, 'correct changed timestamp';
    is $prepared_job->job_state, 'in progress', 'correct job state';
}