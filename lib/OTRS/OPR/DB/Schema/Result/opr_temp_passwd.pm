package OTRS::OPR::DB::Schema::Result::opr_temp_passwd;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_temp_passwd' );
__PACKAGE__->add_columns( qw/
    id
    token
    created
    user_id
/);
__PACKAGE__->set_primary_key( qw/ id / );




1;
