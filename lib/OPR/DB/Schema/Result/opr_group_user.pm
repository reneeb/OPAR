package OPR::DB::Schema::Result::opr_group_user;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_group_user' );
__PACKAGE__->add_columns( qw/
    group_id
    user_id
/);
__PACKAGE__->set_primary_key( qw/ group_id user_id / );



__PACKAGE__->belongs_to(opr_user => 'OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->belongs_to(opr_group => 'OPR::DB::Schema::Result::opr_group',
             { 'foreign.group_id' => 'self.group_id' });


1;