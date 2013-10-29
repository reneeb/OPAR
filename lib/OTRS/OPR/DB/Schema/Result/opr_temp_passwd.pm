package OTRS::OPR::DB::Schema::Result::opr_temp_passwd;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 3;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_temp_passwd' );
__PACKAGE__->add_columns(
    id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    user_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    token => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    created => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ id / );



__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });


1;