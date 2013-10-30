package OTRS::OPR::DB::Schema::Result::opr_user;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 4;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_user' );
__PACKAGE__->add_columns(
    user_id => {
        data_type          => 'INT',
        is_auto_increment  => 1,
        is_numeric         => 1,
        retrieve_on_insert => 1,
    },
    user_name => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    user_password => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    session_id => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    website => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },
    mail => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
    active => {
        data_type          => 'TINYINT',
        is_nullable        => 1,
        default_value      => 'NULL',
    },
    registered => {
        data_type          => 'INT',
        is_nullable        => 1,
        default_value      => 'NULL',
        is_numeric         => 1,
    },
    realname => {
        data_type          => 'VARCHAR',
        is_nullable        => 1,
        size               => 255,
        default_value      => 'NULL',
    },

);
__PACKAGE__->set_primary_key( qw/ user_id / );


__PACKAGE__->has_many(opr_package_author => 'OTRS::OPR::DB::Schema::Result::opr_package_author',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->has_many(opr_notifications => 'OTRS::OPR::DB::Schema::Result::opr_notifications',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->has_many(opr_temp_passwd => 'OTRS::OPR::DB::Schema::Result::opr_temp_passwd',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->has_many(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.uploaded_by' => 'self.user_id' });



1;