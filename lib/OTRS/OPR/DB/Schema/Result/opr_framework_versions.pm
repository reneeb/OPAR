package OTRS::OPR::DB::Schema::Result::opr_framework_versions;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_framework_versions' );
__PACKAGE__->add_columns( qw/
    framework
/);
__PACKAGE__->set_primary_key( qw/framework/ );

1;
