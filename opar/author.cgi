#!/usr/bin/perl 

use strict;
use warnings;
use lib qw(../lib ../perllib);
use CGI::Application::Dispatch;

CGI::Application::Dispatch->dispatch(
    prefix => 'OTRS::OPR::Web',
    table  => [
        '' => {
            app => 'Author',
            rm  => 'start',
        },
        
        'comments/:run/:id' => {
            app => 'Author::Comments',
        },
        'package/:run/:id?' => {
            app => 'Author::Package',
        },
        
        'profile/:run?' => {
            app => 'Author::Profile',
        },
        
        ':run' => {
            app => 'Author',
        },
    ],
);
