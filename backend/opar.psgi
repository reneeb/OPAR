#!/usr/bin/env perl

use Mojo::Base -strict;
use Mojolicious::Commands;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib';

my $dir = File::Spec->rel2abs( dirname __FILE__ );
$ENV{OPAR_APP} = File::Spec->catdir( $dir, '..' );
$ENV{MOJO_MODE} = 'development';

# Start commands
Mojolicious::Commands->start_app( 'OTRS::OPR::Web::OPAR' );
