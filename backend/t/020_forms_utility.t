#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;

use Test::More tests => 6;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;
use lib $dir;

my $error;
eval {
    require OTRS::OPR::Web::App::Forms;
    OTRS::OPR::Web::App::Forms->import( 'check_formid', 'get_formid' );
    1;
} or $error = $@;

SKIP: {
    skip 'Cannot load Forms module', 5 if $error;

    {
        package MockObject;
        use MyUnittests;
        use OTRS::OPR::Web::App::Config;
        
        require OTRS::OPR::Web::App::Forms;
        
        sub new { bless {}, shift }
        sub table { shift; schema()->resultset( shift ); }
        sub config { OTRS::OPR::Web::App::Config->new( $dir . '/tests.yml' ) }
        
        sub check_formid { OTRS::OPR::Web::App::Forms::check_formid( @_ ) };
        sub get_formid { OTRS::OPR::Web::App::Forms::get_formid( @_ ) }
    }

    #MockObject::schema()->storage->debug( 1 );

    my $object = MockObject->new;
    ok $object->check_formid( '123456' ), 'inserted formid is ok';
    ok !$object->check_formid( '123456' ), 'formid was used, so cannot use it again';

    my $formid = $object->get_formid();
    ok $formid, 'new formid returned';
    ok $object->check_formid( $formid ), 'new formid is ok';
    ok !$object->check_formid( $formid ), 'new formid was already used';

    my $another_formid = $object->get_formid();
    my $schema = MockObject::schema();
    my ($formid_object) = $schema->resultset( 'opr_formid' )->find( $another_formid );
    $formid_object->expire( time + 2 );
    $formid_object->update;

    sleep 3;
    ok !$object->check_formid( $another_formid ), 'third formid timed out';
}