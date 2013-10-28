package OTRS::OPR::DB::Schema::Result::opr_package_tags;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.02;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_tags' );
__PACKAGE__->add_columns(
    name_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },
    tag_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ name_id tag_id / );



__PACKAGE__->belongs_to(opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->belongs_to(opr_tags => 'OTRS::OPR::DB::Schema::Result::opr_tags',
             { 'foreign.tag_id' => 'self.tag_id' });


1;