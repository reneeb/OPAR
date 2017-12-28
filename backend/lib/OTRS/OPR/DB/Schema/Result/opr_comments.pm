package OTRS::OPR::DB::Schema::Result::opr_comments;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 5;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_comments' );
__PACKAGE__->add_columns(
    comment_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    username => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    packagename => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    packageversion => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    comments => {
        data_type          => 'TEXT',
    },
    rating => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    deletion_flag => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    headline => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    published => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    created => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ comment_id / );




1;