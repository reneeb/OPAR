package OTRS::OPR::DB::Schema::Result::opr_package;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package' );
__PACKAGE__->add_columns( qw/
    package_id
    name_id
    uploaded_by
    description
    version
    framework
    path
    is_in_index
    website
    bugtracker
    upload_time
    virtual_path
    deletion_flag
    documentation
/);
__PACKAGE__->set_primary_key( qw/ package_id / );


__PACKAGE__->has_many( opr_oq_result => 'OTRS::OPR::DB::Schema::Result::opr_oq_result',
             { 'foreign.package_id' => 'self.package_id' });

__PACKAGE__->has_many( opr_package_dependencies => 'OTRS::OPR::DB::Schema::Result::opr_package_dependencies',
             { 'foreign.package_id' => 'self.package_id' });


__PACKAGE__->belongs_to(opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.uploaded_by' });


1;