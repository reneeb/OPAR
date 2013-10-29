#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use MySQL::Workbench::DBIC;

use lib dirname(__FILE__)."/../lib";

my $base_dir = File::Spec->rel2abs( File::Spec->catdir( dirname( __FILE__ ), '..' ) );
my $mwb_file = File::Spec->catfile( $base_dir, 'documents', 'db.mwb' );
my $out_dir  = File::Spec->catdir( $base_dir, 'lib' );
 
my $foo = MySQL::Workbench::DBIC->new(
    file           => $mwb_file,
    output_path    => $out_dir,
    namespace      => 'OTRS::OPR::DB',
    version_add    => 1,
    schema_name    => 'Schema',
    column_details => 1, # default 1
);
 
$foo->create_schema;
