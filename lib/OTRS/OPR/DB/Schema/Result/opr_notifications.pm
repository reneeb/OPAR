package OTRS::OPR::DB::Schema::Result::opr_notifications;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 3;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_notifications' );
__PACKAGE__->add_columns(
    notification_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    notification_type => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
    },
    notification_name => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 45,
    },
    user_id => {
        data_type          => 'INT',
        is_numeric         => 1,
        is_foreign_key     => 1,
    },

);
__PACKAGE__->set_primary_key( qw/ notification_id / );



__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });


1;