#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 2;

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
is $max_id, undef, 'Inserted package names in "job_queue"';

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
    
}