package OPR::DB::Schema::Result::opr_comments;
    
use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'opr_comments' );
__PACKAGE__->add_columns( qw/
    comment_id
    username
    packagename
    packageversion
    comments
    rating
/);
__PACKAGE__->set_primary_key( qw/ comment_id / );




1;