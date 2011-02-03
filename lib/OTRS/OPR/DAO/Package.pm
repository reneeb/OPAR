package OTRS::OPR::DAO::Package;

use Moose;
use OTRS::OPR::App::AttributeInformation;

use OTRS::OPR::DAO::Author;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    uploaded_by package_name description version
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


has package_id => (
    is  => 'rw',
);

has package_object => (
    is  => 'rw',
    isa => 'Object',
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

sub author {
    my ($self) = @_;
    
    my $author = OTRS::OPR::DAO::Author->new(
        user_id => $self->uploaded_by,
        _schema => $self->_schema,
    );
    
    return $author;
}

sub BUILD {
    my ($self) = @_;
        
    return if !$self->package_id;
    
    my ($package) = $self->ask_table( 'opr_package' )->find( $self->package_id );
    
    if ( !$package ) {
        return;
    }
        
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $package->$attr() );
    }
    
    $self->package_object( $package );
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    return if !$self->_has_changed;
        
    my @changed_attrs = $self->changed_attrs;
    my $package       = $self->package_object;
    
    if ( !$package ) {
        $package = $self->ask_table( 'opr_package' )->create({
            uploaded_by => 0,
        });
    }
    
    #$self->_schema->storage->debug( 1 );
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'package_id';
        
        $package->$attr( $self->$attr() );
    }
    
    $package->in_storage ? $package->update : $package->insert;
}

no Moose;

1;