package OTRS::OPR::DAO::User;

use Moose;
use OTRS::OPR::App::AttributeInformation;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(session_id user_name user_password website mail active registered realname);
for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}


has user_id => (
    is  => 'rw',
);

has user_object => (
    is  => 'rw',
    isa => 'Object',
);

has groups        => (
    traits       => ['Hash'],
    metaclass    => 'OTRS::OPR::App::AttributeInformation',
    is_trackable => 1,
    is           => 'rw',
    isa          => 'HashRef[Str]',
    auto_deref   => 1,
    default      => sub { {} },
    handles      => {
        add_group    => 'set',
        remove_group => 'delete',
        has_group    => 'get',
        group_list   => 'kv',
    },
    trigger      => sub{ shift->_dirty_flag( 'groups' ) },
);

after 'add_group'    => sub{ shift->_dirty_flag( 'groups' ) };
after 'remove_group' => sub{ shift->_dirty_flag( 'groups' ) };

sub save {
    my ($self) = @_;
    
    $self->DEMOLISH;
}

sub BUILD {
    my ($self) = @_;
    
    my $user;
    if ( !$self->user_id && $self->session_id ) {
        ($user) = $self->ask_table( 'opr_user' )->search({
            session_id => $self->session_id,
         });
    }
    elsif ( $self->user_name ) {
        ($user) = $self->ask_table( 'opr_user' )->search({
            user_name => $self->user_name,
        });
    }
    elsif ( $self->user_id ) {
        ($user) = $self->ask_table( 'opr_user' )->find( $self->user_id );
    }
    
    return if !$user;
    
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $user->$attr() );
    }
    
    my @group_user_objects = $user->opr_group_user;
    my @group_objects;
    
    for my $group_user_object ( @group_user_objects ) {
        push @group_objects, $group_user_object->opr_group;
    }
    
    for my $group_obj ( @group_objects ) {
        $self->add_group( lc $group_obj->group_name, 1 );
    }
    
    $self->user_object( $user );
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    
    return if !$self->_has_changed;
    return if !($self->user_name and $self->mail);
        
    my @changed_attrs = $self->changed_attrs;
    my $user          = $self->user_object;
    
    if ( !$user ) {
        ($user) = $self->ask_table( 'opr_user' )->create( {} );
        
    
        $self->user_object( $user );
    }
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'user_id';
        
        if ( $attr ne 'groups' ) {
            $user->$attr( $self->$attr() );
        }
        elsif ( $attr eq 'groups' ) {
            $self->ask_table( 'opr_group_user' )->search({
                user_id => $self->user_id
            })->delete;
            
            GROUP:
            for my $group ( $self->group_list ) {
                my ($group_object) = $self->ask_table( 'opr_group' )->search({
                    group_name => $group->[0],
                });
                
                next GROUP if !$group_object;
                
                my ($group_user) = $self->ask_table( 'opr_group_user' )->create({
                    group_id => $group_object->group_id,
                    user_id  => $self->user_id,
                });
                $group_user->update;
            }
        }
    }
    
    $user->update;
    $self->user_id( $user->user_id );
}

no Moose;

1;