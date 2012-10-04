package OTRS::OPR::DB::Schema::Result::opr_repo_package;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_repo_package' );
__PACKAGE__->add_columns( qw/
    name_id
    repo_id
/);
__PACKAGE__->set_primary_key( qw/ name_id / );


__PACKAGE__->belongs_to( opr_repo => 'OTRS::OPR::DB::Schema::Result::opr_repo',
             { 'foreign.repo_id' => 'self.repo_id' });

__PACKAGE__->belongs_to( opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });



1;
