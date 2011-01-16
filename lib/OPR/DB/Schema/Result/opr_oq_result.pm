package OPR::DB::Schema::Result::opr_oq_result;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_oq_result' );
__PACKAGE__->add_columns( qw/
    result_id
    oq_id
    package_id
    oq_result
    filename
/);
__PACKAGE__->set_primary_key( qw/ result_id / );



__PACKAGE__->belongs_to(opr_oq_entity => 'OPR::DB::Schema::Result::opr_oq_entity',
             { 'foreign.oq_id' => 'self.oq_id' });

__PACKAGE__->belongs_to(opr_package => 'OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;