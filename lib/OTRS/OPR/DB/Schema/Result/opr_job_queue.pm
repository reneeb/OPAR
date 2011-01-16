package OTRS::OPR::DB::Schema::Result::opr_job_queue;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_job_queue' );
__PACKAGE__->add_columns( qw/
    job_id
    type_id
    package_id
    created
    job_state
    changed
/);
__PACKAGE__->set_primary_key( qw/ job_id / );



__PACKAGE__->belongs_to(opr_job_type => 'OTRS::OPR::DB::Schema::Result::opr_job_type',
             { 'foreign.type_id' => 'self.type_id' });


1;