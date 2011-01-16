#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(./lib ../perllib);
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
        'package/:run/:package/:id?' => {
            app => 'Admin::Package',
        },
        'package/:run?/:id?' => {
            app => 'Admin::Package',
        },
        'system/:run?/:id?' => {
            app => 'Admin::System',
        },
        'user/:run?/:id?' => {
            app => 'Admin::User',
        },
        ':rm' => {
            app => 'Admin',
        },
    ],
);
