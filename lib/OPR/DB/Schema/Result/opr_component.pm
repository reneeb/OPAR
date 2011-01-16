package OPR::DB::Schema::Result::opr_component;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_component' );
__PACKAGE__->add_columns( qw/
    component_id
    component_name
    component_label
/);
__PACKAGE__->set_primary_key( qw/ component_id / );


__PACKAGE__->has_many( opr_functions => 'OPR::DB::Schema::Result::opr_functions',
             { 'foreign.component_id' => 'self.component_id' });



1;