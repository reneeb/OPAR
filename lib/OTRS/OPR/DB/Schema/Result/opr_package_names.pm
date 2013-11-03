package OTRS::OPR::DB::Schema::Result::opr_package_names;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 5;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_names' );
__PACKAGE__->add_columns(
    name_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    package_name => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ name_id / );


__PACKAGE__->has_many(opr_package_tags => 'OTRS::OPR::DB::Schema::Result::opr_package_tags',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many(opr_package_author => 'OTRS::OPR::DB::Schema::Result::opr_package_author',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many(opr_repo_package => 'OTRS::OPR::DB::Schema::Result::opr_repo_package',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->has_many(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.name_id' => 'self.name_id' });



1;