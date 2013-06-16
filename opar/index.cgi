#!/usr/bin/perl 

use strict;
use warnings;

use File::Basename;

my $dir;
BEGIN { $dir = dirname __FILE__ }

use lib ("$dir/../lib", "$dir/../perllib");
use CGI::Application::Dispatch::PSGI;

use OTRS::OPR::Web::Guest;
use OTRS::OPR::Web::Guest::Registration;
use OTRS::OPR::Web::Guest::Package;
use OTRS::OPR::Web::Guest::Repo;

$ENV{SCRIPT_NAME} = 'index.cgi';

CGI::Application::Dispatch::PSGI->as_psgi(
    prefix => 'OTRS::OPR::Web',
    table  => [
        '' => {
            app => 'Guest',
            rm  => 'start',
        },
        '/index.cgi' => {
            app => 'Guest',
            rm  => 'start',
        },
        '/index.cgi/repo/add' => {
            app => 'Guest::Repo',
            rm  => 'add',
        },
        '/index.cgi/repo/search' => {
            app => 'Guest::Repo',
            rm  => 'search',
        },
        '/index.cgi/repo/manage' => {
            app => 'Guest::Repo',
            rm  => 'manage',
        },
        '/index.cgi/repo/:id/manage' => {
            app => 'Guest::Repo',
            rm  => 'manage',
        },
        '/index.cgi/repo/:id/save' => {
            app => 'Guest::Repo',
            rm  => 'save',
        },
        '/index.cgi/repo/:id/file/:file' => {
            app => 'Guest::Repo',
            rm  => 'file',
        },
        '/index.cgi/repo/' => {
            app => 'Guest::Repo',
            rm  => 'add_form',
        },
        '/index.cgi/static/:page' => {
            app => 'Guest',
            rm  => 'static',
        },
        '/index.cgi/dist/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        '/index.cgi/search/:page?' => {
            app => 'Guest',
            rm  => 'search',
        },
        '/index.cgi/registration/:rm?' => {
            app => 'Guest::Registration',
        },
        '/index.cgi/package/:initial/:short/:author/:package' => {
            app => 'Guest::Package',
            rm  => 'dist',
        },
        '/index.cgi/package/:run/:id' => {
            app => 'Guest::Package',
        },
        '/index.cgi/authors/:initial?/:short?' => {
            app => 'Guest',
            rm  => 'authors',
        },
        '/index.cgi/rss/recent' => {
            app => 'Guest::Package',
            rm  => 'recent_packages',
        },
        '/index.cgi/:run' => {
            app => 'Guest',
        },
    ],
);
