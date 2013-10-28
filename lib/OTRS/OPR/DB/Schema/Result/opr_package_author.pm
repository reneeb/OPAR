package OTRS::OPR::DB::Schema::Result::opr_package_author;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.02;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_author' );
__PACKAGE__->add_columns(
    user_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },
    name_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },
    is_main_author => {
        data_type          => 'TINYINT',
    },

);
__PACKAGE__->set_primary_key( qw/ user_id / );



__PACKAGE__->belongs_to(opr_package_names => 'OTRS::OPR::DB::Schema::Result::opr_package_names',
             { 'foreign.name_id' => 'self.name_id' });

__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });


1;