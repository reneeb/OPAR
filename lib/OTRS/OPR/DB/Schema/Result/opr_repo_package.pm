package OTRS::OPR::DB::Schema::Result::opr_repo_package;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 2;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_repo_package' );
__PACKAGE__->add_columns(
    name_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },
    repo_id => {
        data_type          => 'VARCHAR',
        size               => 100,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ name_id repo_id / );



__PACKAGE__->belongs_to(opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->belongs_to(opr_repo => 'OTRS::OPR::DB::Schema::Result::opr_repo',
             { 'foreign.repo_id' => 'self.repo_id' });


1;
