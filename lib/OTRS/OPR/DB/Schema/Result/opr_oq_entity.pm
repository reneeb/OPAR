package OTRS::OPR::DB::Schema::Result::opr_oq_entity;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 4;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_oq_entity' );
__PACKAGE__->add_columns(
    oq_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    oq_label => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    priority => {
        data_type          => 'INT',
        is_numeric         => 1,
    },
    module => {
        data_type          => 'VARCHAR',
        size               => 255,
    },

);
__PACKAGE__->set_primary_key( qw/ oq_id / );


__PACKAGE__->has_many(opr_oq_result => 'OTRS::OPR::DB::Schema::Result::opr_oq_result',
             { 'foreign.oq_id' => 'self.oq_id' });



1;