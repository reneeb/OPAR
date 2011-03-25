#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(../lib ../perllib);
use CGI::Application::Dispatch;

CGI::Application::Dispatch->dispatch(
    prefix => 'OTRS::OPR::Web',
    table  => [
        '' => {
            app => 'Admin',
            rm  => 'login',
        },
        'misc/:run?/:id?' => {
            app => 'Admin::Misc',
        },
        'packages' => {
            app => 'Admin::Package',
            rm  => 'list',
        },
        'packages/:run/:package/:id?' => {
            app => 'Admin::Package',
        },
        'packages/:run?/:id?' => {
            app => 'Admin::Package',
        },
        'system/:run?/:id?' => {
            app => 'Admin::System',
        },
        'user/:run?/:id?' => {
            app => 'Admin::Author',
        },
        ':run' => {
            app => 'Admin',
        },
    ],
);
