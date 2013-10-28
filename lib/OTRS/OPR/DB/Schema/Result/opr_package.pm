package OTRS::OPR::DB::Schema::Result::opr_package;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package' );
__PACKAGE__->add_columns(
    package_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    name_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    uploaded_by => {
        data_type          => 'INT',
        is_numeric         => 1,
    },
    description => {
        data_type          => 'TEXT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    version => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    framework => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    path => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    is_in_index => {
        data_type          => 'TINYINT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    website => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    bugtracker => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    upload_time => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    virtual_path => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    deletion_flag => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    documentation => {
        data_type          => 'TEXT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    downloads => {
        data_type          => 'INT',
        default_value      => '\'0\'',
        is_numeric         => 1,
    },
    documentation_raw => {
        data_type          => 'TEXT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ package_id / );


__PACKAGE__->has_many(opr_oq_result => 'OTRS::OPR::DB::Schema::Result::opr_oq_result',
             { 'foreign.package_id' => 'self.package_id' });

__PACKAGE__->has_many(opr_job_queue => 'OTRS::OPR::DB::Schema::Result::opr_job_queue',
             { 'foreign.package_id' => 'self.package_id' });

__PACKAGE__->has_many(opr_package_dependencies => 'OTRS::OPR::DB::Schema::Result::opr_package_dependencies',
             { 'foreign.package_id' => 'self.package_id' });


__PACKAGE__->belongs_to(opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });


1;