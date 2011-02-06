package OTRS::OPR::DAO::Package;

use Moose;
use OTRS::OPR::App::AttributeInformation;

use OTRS::OPR::DAO::Author;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    uploaded_by description version name_id
    framework path virtual_path is_in_index website bugtracker upload_time
    deletion_flag
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
        ($package) = $self->ask_table( 'opr_package' )->search(
            {
                'opr_package_names.package_name' => $self->package_name,
            },
            {
                'join'   => 'opr_package_names',
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
        my ($package_name_obj) = $self->ask_table( 'opr_package_names' )->find( $self->name_id );
        if ( $package_name_obj ) {
            $self->add_object( package_name => $package_name_obj );
            $self->package_name( $package_name_obj->package_name );
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
    
    if ( !$package ) {
        $package = $self->ask_table( 'opr_package' )->create({
            uploaded_by => 0,
            name_id     => 0,
        });
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
        
        $package->$attr( $self->$attr() );
    }
    
    $package->in_storage ? $package->update : $package->insert;
}

no Moose;

1;