package OTRS::OPR::DB::Schema::Result::opr_group;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_group' );
__PACKAGE__->add_columns( qw/
    group_id
    group_name
/);
__PACKAGE__->set_primary_key( qw/ group_id / );


__PACKAGE__->has_many( opr_group_user => 'OTRS::OPR::DB::Schema::Result::opr_group_user',
             { 'foreign.group_id' => 'self.group_id' });



1;