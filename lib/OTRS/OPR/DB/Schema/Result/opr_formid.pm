package OTRS::OPR::DB::Schema::Result::opr_formid;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 3;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_formid' );
__PACKAGE__->add_columns(
    formid => {
        data_type          => 'VARCHAR',
        size               => 255,
        retrieve_on_insert => 1,
    },
    used => {
        data_type          => 'TINYINT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    expire => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ formid / );




1;