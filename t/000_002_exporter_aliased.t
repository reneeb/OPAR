#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Spec;
use Test::More tests => 26;

my $dir;
my $lib;
BEGIN {
    $dir = File::Spec->rel2abs( dirname __FILE__ );
    $lib = File::Spec->catdir( $dir, '..', 'lib' );
}

use lib $lib;

my $error;
eval{
    require OTRS::OPR::Exporter::Aliased;
    1;
} or $error = $@;

ok !$error, 'Can load module';
diag $error if $error;

SKIP: {
    
    skip 'cannot load OTRS::OPR::Exporter::Aliased', 15 if $error;
    
    {
        package AliasedTest;
        
        require OTRS::OPR::Exporter::Aliased;
        @AliasedTest::ISA = qw(OTRS::OPR::Exporter::Aliased);
        @AliasedTest::EXPORT_OK = qw(hello test mysub);
        
        sub hello {}
        sub test  {}
        sub mysub {}
    }

    {
        # test simple import
        package SimpleImport;
        
        AliasedTest->import( qw(hello mysub) );
        
        sub new { return bless {}, shift };
    }
    
    my $simple = SimpleImport->new;
    ok $simple, '$simple object created';
    ok $simple->isa( 'SimpleImport' ), '$simple isa SimpleImport';
    ok $simple->can( 'hello' ), 'SimpleImport can "hello"';
    ok !$simple->can( 'test' ), 'SimpleImport cannot "test"';
    
    {
        # test aliased import
        package AliasedImport;
        
        AliasedTest->import( { hello => 'servus', test => 'prove' } );
        sub new { return bless {}, shift };
    }
    
    my $aliased = AliasedImport->new;
    ok $aliased, '$aliased object created';
    ok $aliased->isa( 'AliasedImport' ), '$aliased isa AliasedImport';
    ok $aliased->can( 'servus' ), 'AliasedImport can "servus"';
    ok $aliased->can( 'prove' ),  'AliasedImport can "prove"';
    ok !$aliased->can( 'hello' ), 'AliasedImport cannot "hello"';
    ok !$aliased->can( 'test' ),  'AliasedImport cannot "test"';
    ok !$aliased->can( 'mysub' ), 'AliasedImport cannot "mysub"';
    
    {
        # test mixed import - simple and aliased
        package MixedImport;
        
        AliasedTest->import( { hello => 'ciao' }, 'test' );
        sub new { return bless {}, shift };
    }
    
    my $mixed = MixedImport->new;
    ok $mixed, '$mixed object created';
    ok $mixed->isa( 'MixedImport' ), '$mixed isa MixedImport';
    ok $mixed->can( 'ciao' ), 'MixedImport can "ciao"';
    ok $mixed->can( 'test' ), 'MixedImport can "test"';
    ok !$mixed->can( 'hello' ), 'MixedImport cannot "hello"';
    ok !$mixed->can( 'mysub' ), 'MixedImport cannot "mysub"';
    
    {
        # test ':all'
        package AllImport;
        
        AliasedTest->import( ':all' );
        sub new { return bless {}, shift };
    }
    
    my $all = AllImport->new;
    ok $all, '$all object created';
    ok $all->isa( 'AllImport' ), '$all isa AllImport';
    ok $all->can( 'hello' ), 'AllImport can "hello"';
    ok $all->can( 'test' ),  'AllImport can "test"';
    ok $all->can( 'mysub' ), 'AllImport can "mysub"';
    
    {
        # test non-existing methods
        package NoImport;
        AliasedTest->import( qw(nothing) );
        sub new { return bless {}, shift };
    }
    
    my $no = NoImport->new;
    ok $no, '$no object created';
    ok $no->isa( 'NoImport' ), '$no isa NoImport';
    ok !NoImport->can( 'nothing' ), 'NoImport cannot "nothing"';
}