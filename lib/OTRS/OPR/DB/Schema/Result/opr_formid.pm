package OTRS::OPR::DB::Schema::Result::opr_formid;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_formid' );
__PACKAGE__->add_columns( qw/
    formid
    used
    expire
/);
__PACKAGE__->set_primary_key( qw/ formid / );




1;