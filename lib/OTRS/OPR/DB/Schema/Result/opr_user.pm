package OTRS::OPR::DB::Schema::Result::opr_user;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_user' );
__PACKAGE__->add_columns( qw/
    user_id
    user_name
    user_password
    session_id
    website
    mail
    active
    registered
/);
__PACKAGE__->set_primary_key( qw/ user_id / );


__PACKAGE__->has_many( opr_package_author => 'OTRS::OPR::DB::Schema::Result::opr_package_author',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->has_many( opr_group_user => 'OTRS::OPR::DB::Schema::Result::opr_group_user',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->has_many( opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.uploaded_by' => 'self.user_id' });



1;