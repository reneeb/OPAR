package OTRS::OPR::DB::Schema::Result::opr_job_type;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.02;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_job_type' );
__PACKAGE__->add_columns(
    type_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    type_label => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ type_id / );


__PACKAGE__->has_many(opr_job_queue => 'OTRS::OPR::DB::Schema::Result::opr_job_queue',
             { 'foreign.type_id' => 'self.type_id' });



1;