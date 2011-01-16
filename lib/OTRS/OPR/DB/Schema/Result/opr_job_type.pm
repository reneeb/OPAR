package OTRS::OPR::DB::Schema::Result::opr_job_type;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_job_type' );
__PACKAGE__->add_columns( qw/
    type_id
    type_label
/);
__PACKAGE__->set_primary_key( qw/ type_id / );


__PACKAGE__->has_many( opr_job_queue => 'OTRS::OPR::DB::Schema::Result::opr_job_queue',
             { 'foreign.type_id' => 'self.type_id' });



1;