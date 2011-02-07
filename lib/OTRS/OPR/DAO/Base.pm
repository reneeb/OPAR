package OTRS::OPR::DAO::Base;

use Moose;

has not_in_db => (
    is      => 'rw',
    isa     => 'Int',
    default => sub{ 1 },
);

has _schema => (
    is => 'rw',
);

has _config => (
    is => 'rw',
);

has _errors => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    default => sub{ {} },
    traits  => ['Hash'],
    handles => {
        set_error => 'set',
    },
);

has _flags => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        delete_flag    => 'delete',
        set_flag       => 'set',
        count_flags    => 'count',
        changed_attrs  => 'kv',
        reject_changes => 'clear',
    },
);

sub _after_init {
    my ($self) = @_;
    
    # get all attributes of object and save initial value
    # this is used to find out, if the object should be saved on destruction
    my $meta       = $self->meta;
    my @attributes = $meta->get_attribute_list;
    my @trackable  = map{ $meta->get_attribute( $_ ) }@attributes;
    
    my %original_values;
    for my $attribute ( @trackable ) {
        if (
            $attribute->isa( 'OTRS::OPR::App::AttributeInformation' ) &&
            $attribute->is_trackable
        ) {
            my $name = $attribute->name;
            $self->delete_flag( $name );
        }
    }
}

sub _dirty_flag {
    my ($self,$name) = @_;
    
    $self->set_flag( $name => 1 );
}

sub _has_changed {
    my ($self) = @_;
    $self->count_flags;
}

sub BUILD {
    my ( $self ) = @_;
    # establish DB connection iff necessary
    if ( !$self->_schema ) {
        warn 'establish DB connection';
    }
}

sub ask_table {
    my ($self, $name) = @_;
    
    return $self->_schema->resultset( $name );
}

no Moose;

1;