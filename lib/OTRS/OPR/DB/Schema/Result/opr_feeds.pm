package OTRS::OPR::DB::Schema::Result::opr_feeds;
    
use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = 0.01;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_feeds' );
__PACKAGE__->add_columns(
    feed_id => {
        data_type          => 'VARCHAR',
        size               => 255,
        retrieve_on_insert => 1,
    },
    feed_config => {
        data_type          => 'TEXT',
    },

);
__PACKAGE__->set_primary_key( qw/ feed_id / );




1;