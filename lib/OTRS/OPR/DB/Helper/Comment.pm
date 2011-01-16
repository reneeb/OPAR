package OTRS::OPR::DB::Helper::Comment;

use base 'OTRS::OPR::Exporter::Aliased';

use OTRS::OPR::Web::App::Utils qw(time_to_date);

our @EXPORT_OK = qw(
    page
);

sub page {
    my ($self,$page,$search_term,$params) = @_;
    
    my $rows = $self->config->get( 'rows.search' );
    
    my $resultset = $self->table( 'opr_comments' )->search(
        {},
        {
            page     => $page,
            rows     => $rows,
            order_by => 'comment_id',
        },
    );
    
    my @comments = $resultset->all;    
    my $pages    = $resultset->pager->last_page;
    
    my @comments_for_template;
    for my $comment ( @comments ) {
        
        # show just a short excerpt of the text if it is too long
        my $text = $comment->comments;
        $text = substr( $text, 0, 57 ) . '...' if $params{short} and 60 < length $text;
        
        # show just a short excerpt of the headline if it is too long
        my $head = $comment->headline;
        $head = substr( $head, 0, 17 ) . '...' if $params{short} and 20 < length $head;
        
        # create the infos for the template
        push @comments_for_template, {
            TEXT    => $text,
            ID      => $comment->comment_id,
            HEAD    => $head,
            RATING  => $comment->rating,
            USER    => $comment->username,
            DATE    => $self->time_to_date( $comment->published ),
            PACKAGE => $comment->packagename,
            VERSION => $comment->packageversion,
        };
    }
    
    return ( \@comments_for_template, $pages );
}

1;