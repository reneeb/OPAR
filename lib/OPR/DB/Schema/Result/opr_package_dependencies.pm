package OPR::DB::Schema::Result::opr_package_dependencies;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_dependencies' );
__PACKAGE__->add_columns( qw/
    dependency_id
    package_id
    dependency
    dependency_type
    dependency_version
/);
__PACKAGE__->set_primary_key( qw/ dependency_id / );



__PACKAGE__->belongs_to(opr_package => 'OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;