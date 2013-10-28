package OTRS::OPR::DB::Schema::Result::opr_group;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 2;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_group' );
__PACKAGE__->add_columns(
    group_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    group_name => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ group_id / );


__PACKAGE__->has_many(opr_group_user => 'OTRS::OPR::DB::Schema::Result::opr_group_user',
             { 'foreign.group_id' => 'self.group_id' });



1;
