package OTRS::OPR::DB::Schema::Result::opr_group_user;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_group_user' );
__PACKAGE__->add_columns(
    user_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },
    group_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
        is_foreign_key     => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ user_id group_id / );



__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->belongs_to(opr_group => 'OTRS::OPR::DB::Schema::Result::opr_group',
             { 'foreign.group_id' => 'self.group_id' });


1;