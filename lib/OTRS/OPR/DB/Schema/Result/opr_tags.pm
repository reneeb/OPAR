package OTRS::OPR::DB::Schema::Result::opr_tags;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_tags' );
__PACKAGE__->add_columns( qw/
    tag_id
    tag_name
/);
__PACKAGE__->set_primary_key( qw/ tag_id / );


__PACKAGE__->has_many( package_tags => 'OTRS::OPR::DB::Schema::Result::package_tags',
             { 'foreign.tag_id' => 'self.tag_id' });



1;