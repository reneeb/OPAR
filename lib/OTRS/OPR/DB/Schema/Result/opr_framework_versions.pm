package OTRS::OPR::DB::Schema::Result::opr_framework_versions;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_framework_versions' );
__PACKAGE__->add_columns(
    framework => {
        data_type          => 'VARCHAR',
        size               => 8,
        retrieve_on_insert => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ framework / );




1;