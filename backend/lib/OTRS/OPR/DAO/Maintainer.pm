package OTRS::OPR::DAO::Maintainer;

use Moose;
use OTRS::OPR::App::AttributeInformation;

use OTRS::OPR::DAO::Author;
use OTRS::OPR::Web::Utils qw(time_to_date);

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    user_id name_id is_main_author
);

for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}

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
    return ();
}

sub delete {
    my ($self) = @_;
    
    my $object = $self->get_object( 'maintainer' );
    return if !$object;
    
    $object->delete;
    return 1;
}

sub BUILD {
    my ($self) = @_;
    
    my $maintainer;
    if ( $self->user_id && $self->name_id ) {
        ($maintainer) = $self->ask_table( 'opr_package_author' )->search({ 
            user_id => $self->user_id,
            name_id => $self->name_id,
        });
    }
        
    return if !$maintainer;
        
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $maintainer->$attr() );
    }
    
    $self->add_object( maintainer => $maintainer );
    
    $self->_after_init;
}

sub DEMOLISH {
    my ($self) = @_;
    return if !$self->_has_changed;
        
    my @changed_attrs = $self->changed_attrs;
    my $maintainer    = $self->get_object( 'maintainer' );
    
    if ( !$maintainer ) {
        $maintainer = $self->ask_table( 'opr_package_author' )->create({
            user_id => $self->user_id,
            name_id => $self->name_id,
            is_main_author => 0,
        });
    }
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'user_id';
        next ATTRELEMENT if $attr eq 'name_id';
        
        $maintainer->$attr( $self->$attr() );
    }
    
    $maintainer->in_storage ? $maintainer->update : $maintainer->insert;
}

no Moose;

1;