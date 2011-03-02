package OTRS::OPR::DAO::Comment;

use Moose;
use OTRS::OPR::App::AttributeInformation;

use OTRS::OPR::Web::Utils qw(time_to_date);

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    username packagename packageversion comments rating
    deletion_flag headline published
);

for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}

has comment_id => (
    is  => 'rw',
);

has objects => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Object]',
    default => sub{ {} },
    handles => {
        add_object => 'set',
        get_object => 'get',
    },
);

sub to_hash {
    my ($self) = @_;
    
    my $comment = $self->get_object( 'comment' );
    
    return if !$comment;
    
    # create the infos for the template
    my %info = (
    		COMMENT_ID			=> $comment->comment_id,
    		USERNAME				=> $comment->username,
    		PACKAGENAME 		=> $comment->packagename,
    		PACKAGEVERSION 	=> $comment->packageversion,
    		COMMENTS 				=> $comment->comments,
    		RATING 					=> $comment->rating,
    		HEADLINE 				=> $comment->headline,
    		PUBLSHED 				=> time_to_date( $self, $comment->published ),    
    );
    
    return %info;
}

sub BUILD {
    my ($self) = @_;
    
    my $comment;
    if ( $self->comment_id ) {
        ($comment) = $self->ask_table( 'opr_comments' )->find( $self->comment_id );
    }
    return if !$comment;
        
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $comment->$attr() );
    }
    
    # ???
    #$self->add_object( comment => $comment );
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    return if !$self->_has_changed;
    
    my @changed_attrs = $self->changed_attrs;
    my $comment       = $self->get_object( 'comment' );
    
    if ( !$comment ) {
        $comment = $self->ask_table( 'opr_comments' )->create({
            username     		=> '',
            packagename			=> '',
            packageversion	=> '',
            comments     		=> '',
        });
    }

    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'comment_id';
        
        $comment->$attr( $self->$attr() );
    }
    
    $comment->in_storage ? $comment->update : $comment->insert;
}

no Moose;

1;