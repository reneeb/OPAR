package OTRS::OPR::DAO::Package;

use Moose;
use OTRS::OPR::App::AttributeInformation;

use OTRS::OPR::DAO::Author;
use OTRS::OPR::Web::Utils qw(time_to_date);

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    uploaded_by description version name_id
    framework path virtual_path is_in_index website bugtracker upload_time
    deletion_flag documentation
);

for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}

has package_name => (
    metaclass    => 'OTRS::OPR::App::AttributeInformation',
    is_trackable => 1,
    is           => 'rw',
    isa          => 'Str',
    trigger      => sub{ shift->_dirty_flag( 'package_name' ) },
);

has tags => (
    metaclass    => 'OTRS::OPR::App::AttributeInformation',
    is_trackable => 1,
    traits       => [ 'Array' ],
    is           => 'rw',
    isa          => 'ArrayRef[Str]',
    default      => sub{ [] },
    handles      => {
        add_tag => 'push',
    },
    auto_deref   => 1,
    trigger      => sub{ shift->_dirty_flag( 'package_name' ) },
);

has package_id => (
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

has oq_results => (
    is  => 'rw',
    isa => 'HashRef',
);

has dependencies => (
    is         => 'rw',
    isa        => 'ArrayRef',
    auto_deref => 1,
);

has _author => (
    is  => 'rw',
    isa => 'Object',
);

has _last_published => (
    is  => 'ro',
    isa => 'Str',
);

has _is_upload => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

sub author {
    my ($self) = @_;
    
    if ( !$self->_author and $self->uploaded_by ) {
        my $author = OTRS::OPR::DAO::Author->new(
            user_id => $self->uploaded_by,
            _schema => $self->_schema,
        );
        
        $self->_author( $author );
    }
    
    return $self->_author;
}

sub maintainer_list {
    my ($self) = @_;
    
    return if $self->not_in_db;
    
    my $package_object = $self->get_object( 'package' );
    return if !$package_object;
    
    # get id of package name
    my ($package_name_object) = $package_object->opr_package_names;
    return if !$package_name_object;
        
    my $maintainer;
    my @co_maintainers;
    
    my @authors = $package_name_object->opr_package_author;
    
    AUTHOR:
    for my $author ( @authors ) {
        
        # get user
        my ($user) = $author->opr_user;
        next AUTHOR if !$user;
        
        if ( $author->is_main_author ) {
            $maintainer = { 
                USER_NAME => $user->user_name,
                USER_ID   => $user->user_id,
            };
        } else {
            push @co_maintainers, { 
                USER_NAME => $user->user_name,
                USER_ID   => $user->user_id,
            };
        }
    }
    
    return ($maintainer, @co_maintainers);
}

sub comments {
    my ($self, %opts) = @_;
        
    my @comments;
    
    my @comments_found = $self->ask_table('opr_comments')->search({
        packagename => $self->package_name,
    });
    
    for my $comment ( @comments_found ) {
        push @comments, {
            #'WEBSITE' => $comment->website,
            'PACKAGE'      => $self->package_name,
            'DATE'         => time_to_date( $self, $comment->published ),
            'SENT_DATE'    => time_to_date( $self, $comment->created || $comment->published ),
            'USERNAME'     => $comment->username,
            'VERSION'      => $comment->packageversion,
            'SCORE'        => $comment->rating,
            'COMMENT'      => $comment->comments,
            'COMMENT_ID'   => $comment->comment_id,
            'IS_PUBLISHED' => ($comment->published > 0),
        };
    }
    
    return @comments;
}

sub to_hash {
    my ($self) = @_;
    
    my $package = $self->get_object( 'package' );
    
    return if !$package;
    
    my ($author) = $package->opr_user;
    my ($text)   = $package->opr_package_names->package_name;
    my $desc     = $package->description;
    my @comments = $self->comments;
        
    # create the infos for the template
    my %info = (
        NAME          => $text,
        VERSION       => $package->version,
        DESCRIPTION   => $desc,
        AUTHOR        => ($author ? $author->user_name : '' ),
        DATE          => time_to_date( $self, $package->upload_time ),
        PACKAGE_ID    => $package->package_id,
        DELETION      => $package->deletion_flag,
        VIRTUAL_PATH  => $package->virtual_path,
        WEBSITE       => $package->website,
        BUGTRACKER    => $package->bugtracker,
        FRAMEWORK     => $package->framework,
        DOCUMENTATION => $package->documentation,
        
        HAS_COMMENTS  => (scalar @comments > 0),
        COMMENTS      => \@comments,
    );
    
    return %info;
}

sub save {
    my ($self) = @_;
    
    $self->DEMOLISH;
}

sub BUILD {
    my ($self) = @_;
    
    my $package;
    if ( $self->package_id ) {
        ($package) = $self->ask_table( 'opr_package' )->find( $self->package_id );
    }
    elsif ( $self->package_name and $self->version ) {
        ($package) = $self->ask_table( 'opr_package' )->search(
            {
                version                          => $self->version,
                'opr_package_names.package_name' => $self->package_name,
            },
            {
                'join' => 'opr_package_names',
            },
        );
    }
    elsif ( $self->package_name ) {
        my %options;

        if ( $self->_last_published ) {
            $options{'me.is_in_index'} = 1;
        }

        ($package) = $self->ask_table( 'opr_package' )->search(
            {
                'opr_package_names.package_name' => $self->package_name,
                %options,
            },
            {
                'join'   => 'opr_package_names',
                order_by => 'package_id DESC',
            },
        );
    }
    elsif ( $self->virtual_path ) {
        ($package) = $self->ask_table( 'opr_package' )->search(
            {
                virtual_path => $self->virtual_path,
            },
            {
                order_by => 'package_id DESC',
            },
        );
    }
        
    return if !$package;
        
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $package->$attr() );
    }
    
    if ( $self->name_id ) {
        my ($package_name_obj) = $self->ask_table( 'opr_package_names' )->search({ name_id => $self->name_id });
        if ( $package_name_obj ) {
            $self->add_object( package_name => $package_name_obj );
            $self->package_name( $package_name_obj->package_name );
            
            # get tags
            my @tags_objects = $package_name_obj->opr_package_tags;
            for my $tag ( @tags_objects ) {
                $self->add_tag( $tag->opr_tags->tag_name );
            }
        }
    }
    
    $self->add_object( package => $package );
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    return if !$self->_has_changed;
        
    my @changed_attrs = $self->changed_attrs;
    my $package       = $self->get_object( 'package' );

    return if !$self->package_id && !$self->_is_upload;
    
    if ( !$package ) {
        $package = $self->ask_table( 'opr_package' )->create({
            uploaded_by => 0,
            name_id     => 0,
        });
    
        $self->add_object( package => $package );
    }
    
    #$self->_schema->storage->debug( 1 );
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'package_id';
        
        if ( $attr eq 'package_name' ) {
            my ($package_name_obj) = $self->get_object( 'package_name' );
            if ( !$package_name_obj ) {
                ($package_name_obj) = $self->ask_table( 'opr_package_names' )->search({
                    package_name => $self->package_name
                });
            }
            if ( !$package_name_obj ) {
                ($package_name_obj) = $self->ask_table( 'opr_package_names' )->create({});
            }
            
            $package_name_obj->package_name( $self->package_name );
            $package_name_obj->in_storage ?
                $package_name_obj->update :
                $package_name_obj->insert;
            
            $self->name_id( $package_name_obj->name_id );
            $package->name_id( $package_name_obj->name_id );
            
            next ATTRELEMENT;
        }
        
        if ( $attr eq 'tags' ) {

            next ATTRELEMENT;
            
            # delete tags from package
            my ($package_name_obj) = $self->get_object( 'package_name' );
            $package_name_obj->opr_package_tags->delete;
            
            # add tags and create tag if it doesn't exist yet
            TAG:
            for my $tag ( $self->tags ) {

                next TAG if !$tag;

                my ($tag_obj) = $self->ask_table( 'opr_tags' )->search({
                    tag_name => $tag,
                });
                
                if ( !$tag_obj ) {
                    ($tag_obj) = $self->ask_table( 'opr_tags' )->create({
                        tag_name => $tag,
                    });
                    $tag_obj->update;
                }
                
                $self->ask_table( 'opr_package_tags' )->create({
                    tag_id  => $tag_obj->tag_id,
                    name_id => $package_name_obj->name_id,
                });
            }
            
            next ATTRELEMENT;
        }
        
        $package->$attr( $self->$attr() );
    }
    
    $package->in_storage ? $package->update : $package->insert;
    $self->package_id( $package->package_id );
}

no Moose;

1;
