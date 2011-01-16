#!/usr/bin/perl

use strict;
use warnings;
use FabForce::DBDesigner4;
use FabForce::DBDesigner4::DBIC;

my $file = 'D:\SVNRepo\PerlServices\software\OPR\docs\er_modell.xml';
my $sql  = 'D:\SVNRepo\PerlServices\software\OPR\docs\er_modell.sql';

my $dbic = FabForce::DBDesigner4::DBIC->new();
$dbic->namespace( 'OTRS::OPR::DB' );
$dbic->output_path( 'D:\SVNRepo\PerlServices\software\OPR\Sources\lib\\' );
$dbic->schema_name( 'Schema' );
$dbic->create_schema( $file );

my $designer = FabForce::DBDesigner4->new();
$designer->parsefile(xml => $file);
$designer->writeSQL( $sql ,
    { 
        type          => 'mysql', 
        drop_tables   => 1, 
        sql_options   => { 
            engine    => 'InnoDB',
            charset   => 'utf8',
        },
    }
);