#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 16;

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

SKIP: {
    
    skip 'cannot load OTRS::OPR::Web::Utils', 10 if $error;

    {
        # check time_to_date
        
        for my $time ( '', '1a', 'b6', 'test' ) {
            my $nothing = OTRS::OPR::Web::Utils->time_to_date( '' );
            is $nothing, undef, "Pass an $time to function";
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
                PAGE     => 1,
                SELECTED => 0,
            },
            {
                PAGE     => 2,
                SELECTED => 1,
            },
            {
                PAGE     => 3,
                SELECTED => 0,
            },
            {
                PAGE     => 4,
                SELECTED => 0,
            },
        );
        
        my $page_list_1 = OTRS::OPR::Web::Utils->page_list( 4, 2 );
        is_deeply $page_list_1, \@check_1, 'page 2 selected';
    }
}