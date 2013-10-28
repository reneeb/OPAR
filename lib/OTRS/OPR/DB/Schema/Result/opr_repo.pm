package OTRS::OPR::DB::Schema::Result::opr_repo;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.02;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_repo' );
__PACKAGE__->add_columns(
    repo_id => {
        data_type          => 'VARCHAR',
        size               => 100,
        retrieve_on_insert => 1,
    },
    framework => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 8,
        default_value      => 'NULL',
    },
    email => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    index_file => {
        data_type          => 'TEXT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ repo_id / );


__PACKAGE__->has_many(opr_repo_package => 'OTRS::OPR::DB::Schema::Result::opr_repo_package',
             { 'foreign.repo_id' => 'self.repo_id' });



1;