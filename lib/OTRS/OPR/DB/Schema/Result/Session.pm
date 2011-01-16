package OTRS::OPR::DB::Schema::Result::Session;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Session' );
__PACKAGE__->add_columns( qw/
    SessionID
    Start
    Expire
/);
__PACKAGE__->set_primary_key( qw/ SessionID / );




1;