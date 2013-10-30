package OTRS::OPR::DB::Schema::Result::opr_tags;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 4;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_tags' );
__PACKAGE__->add_columns(
    tag_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    tag_name => {
        data_type          => 'VARCHAR',
        size               => 255,
    },

);
__PACKAGE__->set_primary_key( qw/ tag_id / );


__PACKAGE__->has_many(opr_package_tags => 'OTRS::OPR::DB::Schema::Result::opr_package_tags',
             { 'foreign.tag_id' => 'self.tag_id' });



1;