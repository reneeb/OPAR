package OTRS::OPR::DB::Schema::Result::opr_repo;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_repo' );
__PACKAGE__->add_columns( qw/
    repo_id
    framework
    mail
/);
__PACKAGE__->set_primary_key( qw/ repo_id / );


__PACKAGE__->has_many( opr_repo_package => 'OTRS::OPR::DB::Schema::Result::opr_repo_package',
             { 'foreign.repo_id' => 'self.repo_id' });

1;
