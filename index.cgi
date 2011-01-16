#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(./lib ../perllib);
use CGI::Application::Dispatch;

CGI::Application::Dispatch->dispatch(
    prefix => 'OTRS::OPR::Web',
    table  => [
        '' => {
            app => 'Guest',
            rm  => 'start',
        },
        'static/:page' => {
            app => 'Guest',
            rm  => 'static',
        },
        'dist/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        'oq/:package' => {
            app => 'Guest::Package',
            rm  => 'oq',
        },
        ':initial/:short/:author/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        ':initial/:short/:author' => {
            app => 'Guest::Package',
            rm  => 'author',
        },
        ':rm' => {
            app => 'Guest',
        },
    ],
);
