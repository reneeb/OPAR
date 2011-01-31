package MyUnittests;

use strict;
use warnings;
use parent 'Exporter';
use DBI;
use File::Basename;
use File::Spec;

our @EXPORT = qw(fill_db populate_db delete_db dbh schema);

my ($dir, $configfile, $config);
BEGIN {
    $dir        = File::Spec->rel2abs( dirname __FILE__ );
}

use lib "$dir/../lib";

use OTRS::OPR::DB::Schema;
use OTRS::OPR::Web::App::Config;

BEGIN {
    $configfile = File::Spec->catfile( $dir, 'tests.yml' );
    $config     = OTRS::OPR::Web::App::Config->new( $configfile );
}

my $schema_obj;

sub fill_db {
    my $db_file    = File::Spec->catfile( $dir, $config->get( 'files.inserts' ) );
    my $db_inserts = OTRS::OPR::Web::App::Config->new( $db_file );
    
    my $dbh = dbh();
    
    my $db_data    = $db_inserts->get( 'inserts' ) || [];
    
    return if !@{$db_data};
    
    for my $insert ( @{ $db_data } ) {
        my $table   = delete $insert->{table_name};
        my @columns = keys %{ $insert };
        my $col_str = join ', ', @columns;
        my @values  = @{ $insert }{@columns};
        my $binds   = join ', ', ('?') x @values;
        my $sql     = "INSERT INTO $table ( $col_str ) VALUES ( $binds )";
        my $error;
        
        my $sth = $dbh->prepare( $sql ) or $error = $dbh->errstr;
        if ( $error ) {
            warn $error;
            return 0;
        }
        
        $error = undef;
        $sth->execute( @values ) or $error = $dbh->errstr;
        if ( $error ) {
            warn $error;
            return 0;
        }
    }
    
    1;
}

sub populate_db {
    my $db_file = $config->get( 'db.file' );
    if ( -e $db_file ) {
        unlink $db_file or return 0;
    }
    
    my $schema_file = File::Spec->catfile( $dir, $config->get( 'files.schema' ) );
    my $schema_conf = OTRS::OPR::Web::App::Config->new( $schema_file );
    my $dbh         = dbh();
    
    my $tables      = $schema_conf->get( 'schema' ) || {};
    my $last;
    for my $table ( keys %{ $tables } ) {
        my $sql  = 'CREATE TABLE ' . $table . ' (';
           $sql .= join ', ', map{ $_ . ' ' . $tables->{$table}->{$_} }keys %{ $tables->{$table} };
           $sql .= ')';
        $dbh->do( $sql ) or $last = 1;
        if ( $last ) {
            warn $sql . ': ' . $dbh->errstr;
            return 0;
        }
    }
    
    $dbh->disconnect();
    
    1;
}

sub schema {
    
    if ( !$schema_obj ) {
        my $db     = $config->get( 'db.name' );
        my $host   = $config->get( 'db.host' );
        my $type   = $config->get( 'db.type' );
        my $schema = $config->get( 'db.schema' );
        $schema_obj = OTRS::OPR::DB::Schema->connect( 
            "DBI:$type:$db", 
            $config->get( 'db.user' ),
            $config->get( 'db.pass' ),
            $schema,
        );
    }
    
    return $schema_obj;
}

sub table {
    my ($name) = @_;
    
}

sub dbh {
    my $db     = $config->get( 'db.name' );
    my $host   = $config->get( 'db.host' );
    my $type   = $config->get( 'db.type' );
    my $dbh = DBI->connect(
        "DBI:$type:$db", 
        $config->get( 'db.user' ),
        $config->get( 'db.pass' ),
    );
    
    return $dbh;
}

sub delete_db {
    my $db_file = $config->get( 'db.file' );
    if ( -e $db_file ) {
        unlink $db_file or return 0;
    }
    
    1;
}

1;