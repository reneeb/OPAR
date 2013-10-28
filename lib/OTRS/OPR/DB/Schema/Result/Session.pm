package OTRS::OPR::DB::Schema::Result::Session;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Session' );
__PACKAGE__->add_columns(
    SessionID => {
        data_type          => 'VARCHAR',
        size               => 255,
        retrieve_on_insert => 1,
    },
    Start => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    Expire => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ SessionID / );




1;