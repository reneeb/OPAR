#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use feature qw/ switch /;

use DBIx::Class::DeploymentHandler;
use File::Basename;
use File::Spec;
use Getopt::Long;
use YAML::Tiny;

use OTRS::OPR::DB::Schema;

no warnings 'experimental';

GetOptions(
    'command|cmd|c=s' => \my $cmd,
    'from-version=n'  => \my $from_version,
    'to-version=n'    => \my $to_version,
    'version=n'       => \my $version,
);

sub usage {
    say <<'HERE';
usage:
  database.pl --cmd init
  database.pl --cmd prepare [ --from-version $from --to-version $to ]
  database.pl --cmd install [ --version $version ]
  database.pl --cmd upgrade
  database.pl --cmd database-version
  database.pl --cmd schema-version
HERE
    exit(0);
}

$cmd || usage();

my $base_dir               = File::Spec->rel2abs( File::Spec->catdir( dirname( __FILE__ ), '..' ) );
my $deployment_handler_dir = File::Spec->catdir( $base_dir, 'db_upgrades' );
my $yaml_file              = $ENV{OPAR_CONFIG} || File::Spec->catfile( $base_dir, 'conf', 'base.yml' );
my $config                 = YAML::Tiny->read( $yaml_file )->[0];

my $dh;
if( $config->{db}->{name} ) {
    my $db           = $config->{db}->{name};
    my $host         = $config->{db}->{host};
    my $type         = $config->{db}->{type};
    my $schema       = OTRS::OPR::DB::Schema->connect(
        "DBI:$type:$db:$host",
        $config->{db}->{user},
        $config->{db}->{pass},
    );

    my %type_remapping = ( mysql => 'MySQL', Pg => 'PostgreSQL' );

    $dh     = DBIx::Class::DeploymentHandler->new(
        {   schema           => $schema,
            script_directory => $deployment_handler_dir,
            databases        => $type_remapping{$type},
            force_overwrite  => 1,
        }
    );

    die 'We only support versions of format \d+\.\d+.'
        unless $dh->schema_version =~ /^\d+\.\d+$/;
}

if ( $cmd ne 'init' and !$dh ) {
   die "you need to initialize the database first! (database.pl --cmd init)";
}

for ($cmd) {
    when ('init')             { init() }
    when ('prepare')          { prepare() }
    when ('install')          { install() }
    when ('upgrade')          { upgrade() }
    when ('database-version') { database_version() }
    when ('schema-version')   { schema_version() }
    default                   { usage() }
}

sub init {
    print "Init database for OPAR...\n";
    print "Database type (mysql or PostgreSQL): ";
    my $type = <STDIN>;
    chomp $type;

    my %type_mapping = ( postgresql => 'Pg', mysql => 'mysql' );
    my $real_type    = $type_mapping{ lc $type };

    if ( !$real_type ) {
        die "Currently there is only support for mysql and PostgreSQL";
    }

    print "Host: ";
    my $host = <STDIN>;

    print "Database name: ";
    my $name = <STDIN>;

    print "\nThe root data are necessary to create the database and the user!\n";
    print "DB root user: ";
    my $root = <STDIN>;

    print "DB root password: ";
    my $root_pw = <STDIN>;

    print "\nDatabase settings for AuthorDB\n";
    print "DB user: ";
    my $user = <STDIN>;

    print "DB user password: ";
    my $pass = <STDIN>;

    chomp( $type, $host, $name, $root, $root_pw, $user, $pass);

    my $dbh = DBI->connect( "DBI:$real_type:host=$host", $root, $root_pw );
    if ( $real_type eq 'mysql' ) {
        $dbh->do( "CREATE DATABASE `$name` CHARSET utf8" );
        $dbh->do( "GRANT ALL PRIVILEGES ON `$name`.* TO '$user'\@'$host' IDENTIFIED BY '$pass'" );
        $dbh->do( "FLUSH PRIVILEGES" );
    }
    else {
        $dbh->do( "CREATE ROLE \"$user\" WITH LOGIN PASSWORD \"$pass\"" );
        $dbh->do( "CREATE DATABASE \"$name\" OWNER=\"$user\" ENCODING 'utf-8'" );
    }

    $config->{db} = {
        type => $real_type,
        host => $host,
        name => $name,
        user => $user,
        pass => $pass,
    };

    my $yaml_write = YAML::Tiny->new;
    $yaml_write->[0] = $config;
    $yaml_write->write( $yaml_file );
}

sub prepare {
    say "running prepare_install()";
    $dh->prepare_install;

    if ( defined $from_version && defined $to_version ) {
        say
            "running prepare_upgrade({ from_version => $from_version, to_version => $to_version })";
        $dh->prepare_upgrade(
            {   from_version => $from_version,
                to_version   => $to_version,
            }
        );
    }
}

sub install {
    if ( defined $version ) {
        $dh->install({ version => $version });
    }
    else {
        $dh->install;
    }
}

sub upgrade {
    $dh->upgrade;
}

sub database_version {
    say $dh->database_version;
}

sub schema_version {
    say $dh->schema_version;
}

