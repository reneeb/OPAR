package Mojolicious::Plugin::OPARSchema;

# ABSTRACT: "proper" handling of DBI based connections in Mojolicious

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use OTRS::OPR::DB::Schema;

our $VERSION = 0.02;

sub register {
    my $self   = shift;
    my $app    = shift;
    my $config = shift;

    die ref($self), ': didn\'t get config object' unless $config->{config} and ref $config->{config};

    my $local_config = $config->{config}->get( 'db' );

    die ref($self), ': missing db parameter or db does not exist', "\n" unless $local_config;

    $app->attr(
        'db_schema' => sub {
            $app->log->debug( 'connect to db' );
            my $db           = $local_config->{name};
            my $host         = $local_config->{host};
            my $type         = $local_config->{type};
            my $schema_class = $local_config->{schema};
            my $schema       = OTRS::OPR::DB::Schema->connect(
                "DBI:$type:$db:$host",
                $local_config->{user},
                $local_config->{pass},
                $schema_class,
            );

            #$schema->storage->debug(1);
            $schema->storage->debugcb( sub {
                $app->log->debug( "@_" );
            });

            $schema;
        },
    );

    $app->helper( schema => sub { return shift->app->db_schema } );
    $app->helper( table  => sub { 
        return if @_ != 2;
        return shift->app->db_schema->resultset( shift );
    });
}

1;
__END__

=head1 SYNOPSIS

Provides "sane" handling of DBI connections so problems with pre-forking (Hypnotoad, etc.) will not occur. 

    use Mojolicious::Plugin::OPARSchema;

    sub startup {
        my $self = shift;

        $self->plugin('OPARSchema', { 
            dsn      => '/home/user/db.sqlite',
            helper   => 'schema',
        });
    }

=head1 CONFIGURATION

The only required option is the 'db' one, which should contain the path to the database.

=head1 METHODS/HELPERS

A helper is created with a name you specified (or 'schema' by default) that can be used to get the schema object. 

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Renee Baecker

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://dev.perl.org/licenses/ for more information.

=cut
