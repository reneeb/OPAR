package OTRS::OPR::DB::Schema::Result::opr_job_queue;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 5;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_job_queue' );
__PACKAGE__->add_columns(
    job_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    type_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    package_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    created => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    job_state => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    changed => {
        data_type          => 'BIGINT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ job_id / );



__PACKAGE__->belongs_to(opr_job_type => 'OTRS::OPR::DB::Schema::Result::opr_job_type',
             { 'foreign.type_id' => 'self.type_id' });

__PACKAGE__->belongs_to(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;