package OTRS::OPR::DB::Schema::Result::opr_package_author;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_package_author' );
__PACKAGE__->add_columns( qw/
    user_id
    package_id
    is_main_author
/);
__PACKAGE__->set_primary_key( qw/ user_id package_id / );



__PACKAGE__->belongs_to(opr_user => 'OTRS::OPR::DB::Schema::Result::opr_user',
             { 'foreign.user_id' => 'self.user_id' });

__PACKAGE__->belongs_to(opr_package => 'OTRS::OPR::DB::Schema::Result::opr_package',
             { 'foreign.package_id' => 'self.package_id' });


1;