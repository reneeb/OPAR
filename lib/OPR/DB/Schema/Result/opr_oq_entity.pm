package OPR::DB::Schema::Result::opr_oq_entity;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_oq_entity' );
__PACKAGE__->add_columns( qw/
    oq_id
    oq_label
    priority
    module
/);
__PACKAGE__->set_primary_key( qw/ oq_id / );


__PACKAGE__->has_many( opr_oq_result => 'OPR::DB::Schema::Result::opr_oq_result',
             { 'foreign.oq_id' => 'self.oq_id' });



1;