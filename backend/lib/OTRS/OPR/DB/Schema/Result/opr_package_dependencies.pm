package OTRS::OPR::DB::Schema::Result::opr_package_dependencies;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 5;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_dependencies' );
__PACKAGE__->add_columns(
    dependency_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    package_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    dependency => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    dependency_type => {
        data_type          => 'ENUM',
    },
    dependency_version => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ dependency_id / );



__PACKAGE__->belongs_to(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;