package OTRS::OPR::DB::Schema::Result::opr_package_names;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_names' );
__PACKAGE__->add_columns( qw/
    name_id
    package_name
/);
__PACKAGE__->set_primary_key( qw/ name_id / );


__PACKAGE__->has_many( opr_package_tags => 'OTRS::OPR::DB::Schema::Result::opr_package_tags',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many( opr_package_author => 'OTRS::OPR::DB::Schema::Result::opr_package_author',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many( opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many( opr_repo_package => 'OTRS::OPR::DB::Schema::Result::opr_repo_package',
             { 'foreign.name_id' => 'self.name_id' });


1;
