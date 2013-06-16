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
        'repo/add' => {
            app => 'Guest::Repo',
            rm  => 'add',
        },
        'repo/search' => {
            app => 'Guest::Repo',
            rm  => 'search',
        },
        'repo/manage' => {
            app => 'Guest::Repo',
            rm  => 'manage',
        },
        'repo/:id/manage' => {
            app => 'Guest::Repo',
            rm  => 'manage',
        },
        'repo/:id/save' => {
            app => 'Guest::Repo',
            rm  => 'save',
        },
        'repo/:id/file/:file' => {
            app => 'Guest::Repo',
            rm  => 'file',
        },
        'repo/' => {
            app => 'Guest::Repo',
            rm  => 'add_form',
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
        '/rss/recent' => {
            app => 'Guest::Package',
            rm  => 'recent_packages',
        },
        ':run' => {
            app => 'Guest',
        },
    ],
);
