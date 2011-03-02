#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(../lib ../perllib);
use CGI::Application::Dispatch;

CGI::Application::Dispatch->dispatch(
    prefix => 'OTRS::OPR::Web',
    table  => [
        '' => {
            app => 'Guest',
            rm  => 'start',
        },
        'recent/:page?' => {
            app => 'Guest',
            rm  => 'recent',
        },
        'static/:page' => {
            app => 'Guest',
            rm  => 'static',
        },
        'dist/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        'search/:page?' => {
            app => 'Guest',
            rm  => 'search',
        },
        'registration/:rm?' => {
            app => 'Guest::Registration',
        },
        '/package/:initial/:short/:author/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        '/package/:run/:id' => {
            app => 'Guest::Package',
        },
        '/authors/:initial?/:short?' => {
            app => 'Guest',
            rm  => 'authors',
        },
        ':run' => {
            app => 'Guest',
        },
    ],
);
