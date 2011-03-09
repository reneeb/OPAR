#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 31;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;

my $error;
eval{
    require OTRS::OPR::Web::Utils;
    1;
} or $error = $@;

ok !$error, 'Can load module';
diag $error if $error;

{
    sub OTRS::OPR::Web::Utils::new { bless {}, shift }
    sub OTRS::OPR::Web::Utils::base_url { 'test' }
}

SKIP: {
    
    skip 'cannot load OTRS::OPR::Web::Utils', 10 if $error;

    {
        # check time_to_date
        
        for my $time ( '', '1a', 'b6', 'test' ) {
            my $nothing = OTRS::OPR::Web::Utils->time_to_date( '' );
            is $nothing, '', "Pass an invalid time ($time) to function";
        }
        
        # 1234567890 => Sat Feb 14 00:31:30 2009 (Berlin/Europe)
        # 1234567890 => Sat Feb 13 23:31:30 2009 (London/Europe)
        my $time = 1234567890;
        
        # nothing
        my $nothing = OTRS::OPR::Web::Utils->time_to_date( $time, { date => 0 } );
        is $nothing, '', 'deactivated time and date';
        
        # just date
        my $date = OTRS::OPR::Web::Utils->time_to_date( $time );
        is $date, '13 Feb 2009', 'Get "13 Feb 2009"';
        
        # date and time
        my $date_time = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1 } );
        is $date_time, '13 Feb 2009 23:31:30', 'Get "13 Feb 2009 23:31:30"';
        
        # just time
        my $only_time = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1, date => 0 } );
        is $only_time, '23:31:30', 'Get "23:31:30"';
        
        # just date (Berlin)
        my $date_berlin = OTRS::OPR::Web::Utils->time_to_date( $time, { time_zone => 'Europe/Berlin' } );
        is $date_berlin, '14 Feb 2009', 'Get "14 Feb 2009" (Berlin)';
        
        # date and time (Berlin)
        my $date_time_berlin = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1, time_zone => 'Europe/Berlin' } );
        is $date_time_berlin, '14 Feb 2009 00:31:30', 'Get "14 Feb 2009 00:31:30" (Berlin)';
        
        # just time
        my $only_time_berlin = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1, date => 0, time_zone => 'Europe/Berlin' } );
        is $only_time_berlin, '00:31:30', 'Get "00:31:30" (Berlin)';
        
        # just date
        my $date_invalid_tz = OTRS::OPR::Web::Utils->time_to_date( $time, { time_zone => 'invalid' } );
        is $date_invalid_tz, '13 Feb 2009', 'Get "13 Feb 2009" (invalid tz)';
        
        # date and time
        my $date_time_invalid_tz = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1, time_zone => 'invalid' } );
        is $date_time_invalid_tz, '13 Feb 2009 23:31:30', 'Get "13 Feb 2009 23:31:30" (invalid tz)';
        
        # just time
        my $only_time_invalid_tz = OTRS::OPR::Web::Utils->time_to_date( $time, { time => 1, date => 0, time_zone => 'invalid' } );
        is $only_time_invalid_tz, '23:31:30', 'Get "23:31:30" (invalid tz)';
    }

    {
        # check page_list        
        my @check_1 = (
            {
                PAGE       => 1,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 2,
                SELECTED   => 1,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 3,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 4,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $page_list_1 = OTRS::OPR::Web::Utils->page_list( 4, 2 );
        is_deeply $page_list_1, \@check_1, 'page 2 selected';
        
        # 10 pages
        my @check_2 = (
            {
                PAGE       => 1,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 2,
                SELECTED   => 1,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 3,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
            },
            {
                PAGE       => 8,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 9,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 10,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $page_list_2 = OTRS::OPR::Web::Utils->page_list( 10, 2 );
        is_deeply $page_list_2, \@check_2, '10 pages, page 2 selected';
        
        # 10 pages, page 6 selected
        my @check_3 = (
            {
                PAGE       => 1,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 2,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 3,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
            },
            {
                PAGE       => 5,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 6,
                SELECTED   => 1,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 7,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 8,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 9,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 10,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $page_list_3 = OTRS::OPR::Web::Utils->page_list( 10, 6 );
        is_deeply $page_list_3, \@check_3, '10 pages, page 6 selected';
        
        # 20 pages, page 6 selected
        my @check_4 = (
            {
                PAGE       => 1,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 2,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 3,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
            },
            {
                PAGE       => 5,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 6,
                SELECTED   => 1,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 7,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
            },
            {
                PAGE       => 18,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 19,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                PAGE       => 20,
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $page_list_4 = OTRS::OPR::Web::Utils->page_list( 20, 6 );
        is_deeply $page_list_4, \@check_4, '20 pages, page 6 selected';
    }
    
    {
        # check prepare select
        my @options_1 = (
            {
                KEY        => 'hallo',
                VALUE      => 'test',
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
            {
                KEY        => 'key2',
                VALUE      => 'test2',
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $select_options_1 = OTRS::OPR::Web::Utils->prepare_select({data => { hallo => 'test', key2 => 'test2' }});
        is_deeply $select_options_1, \@options_1, 'prepare_select test 1';
        
        # check prepare select and exclude 1
        my @options_2 = (
            {
                KEY        => 'key2',
                VALUE      => 'test2',
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $select_options_2 = OTRS::OPR::Web::Utils->prepare_select({data => { hallo => 'test', key2 => 'test2' }, excluded => [ 'test' ]});
        is_deeply $select_options_2, \@options_2, 'prepare_select test 2';
        
        # check prepare select and select 1
        my @options_3 = (
            {
                KEY        => 'hallo',
                VALUE      => 'test',
                SELECTED   => 1,
                __SCRIPT__ => 'test',
            },
            {
                KEY        => 'key2',
                VALUE      => 'test2',
                SELECTED   => 0,
                __SCRIPT__ => 'test',
            },
        );
        
        my $select_options_3 = OTRS::OPR::Web::Utils->prepare_select({data => { hallo => 'test', key2 => 'test2' }, selected => 'test' });
        is_deeply $select_options_3, \@options_3, 'prepare_select test 2';
    }
    
    {
        # check validate_opm_name
        
        my @valid = qw(
            DashboardMOTDPlus-0.1.1.opm
            Out-of-Office-0.1.opm
            TicketTemplate-1.opm
            Test.opm
            /Dashboard2.opm
            /test/TicketTest-0.1.1.opm
        );
        
        for my $name ( @valid ) {
            my $success = OTRS::OPR::Web::Utils->validate_opm_name( $name );
            ok $success, "$name is valid";
        }
        
        my @invalid = qw(
            Test$.opm
            1^z-0.1.1.opm
            /Test$.opm
        );
        
        for my $name ( @invalid ) {
            my $success = OTRS::OPR::Web::Utils->validate_opm_name( $name );
            ok !$success, "$name is invalid";
        }
    }
}