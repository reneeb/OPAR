package OTRS::OPR::DB::Schema::Result::opr_functions;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_functions' );
__PACKAGE__->add_columns( qw/
    function_id
    component_id
    function_name
    function_label
/);
__PACKAGE__->set_primary_key( qw/ function_id / );


__PACKAGE__->has_many( opr_group_functions => 'OTRS::OPR::DB::Schema::Result::opr_group_functions',
             { 'foreign.function_id' => 'self.function_id' });


__PACKAGE__->belongs_to(opr_component => 'OTRS::OPR::DB::Schema::Result::opr_component',
             { 'foreign.component_id' => 'self.component_id' });


1;