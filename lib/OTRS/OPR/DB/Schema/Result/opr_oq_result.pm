package OTRS::OPR::DB::Schema::Result::opr_oq_result;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_oq_result' );
__PACKAGE__->add_columns(
    result_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    oq_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    package_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    oq_result => {
        data_type          => 'TEXT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    filename => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ result_id / );



__PACKAGE__->belongs_to(opr_oq_entity => 'OTRS::OPR::DB::Schema::Result::opr_oq_entity',
             { 'foreign.oq_id' => 'self.oq_id' });

__PACKAGE__->belongs_to(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;