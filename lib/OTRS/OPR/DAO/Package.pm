package OTRS::OPR::DAO::Package;

use Moose;
use OTRS::OPR::App::AttributeInformation;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    package_id uploaded_by package_name description version
    framework path virtual_path is_in_index website bugtracker upload_time
);

for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}

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
    
    require OTRS::OPR::DAO::Author;
    my $author = OTRS::OPR::DAO::Author->new(
        user_id => $self->uploaded_by,
        _schema => $self->_schema,
    );
    
    return $author;
}

sub BUILD {
    my ($self) = @_;
    
    $self->delete_flag( 'package_id' );
    
    return if !$self->package_id;
    
    my ($package) = $self->ask_table( 'opr_package' )->find( $self->package_id );
    
    if ( !$package ) {
        $self->package_id( undef );
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
        $package = $self->ask_table( 'opr_package' )->create( {} );
    }
    
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
    }
    
    $package->update;
}

no Moose;

1;