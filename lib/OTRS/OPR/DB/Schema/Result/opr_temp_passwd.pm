package OTRS::OPR::DB::Schema::Result::opr_temp_passwd;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_temp_passwd' );
__PACKAGE__->add_columns( qw/
    id
    user_id
    token
    created
/);
__PACKAGE__->set_primary_key( qw/ id / );



__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });


1;