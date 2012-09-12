package OTRS::OPR::DAO::Author;

use Moose;
use OTRS::OPR::App::AttributeInformation;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(user_name user_id website active realname);
for my $attribute ( @attributes ) {
    has $attribute => (
        metaclass    => 'OTRS::OPR::App::AttributeInformation',
        is_trackable => 1,
        is           => 'rw',
        trigger      => sub{ shift->_dirty_flag( $attribute ) },
    );
}

has user_object => (
    is  => 'rw',
    isa => 'Object',
);

has user_dao => (
    is  => 'rw',
    isa => 'Object',
);

has package_dao => (
    is  => 'rw',
    isa => 'Object',
);

has maintainer => (
    is  => 'rw',
    isa => 'ArrayRef[Int]',
);

has comaintainer => (
    is  => 'rw',
    isa => 'ArrayRef[Int]',
);

sub packages {
    my ($self, %params) = @_;
    
    my ($object) = $self->user_object;
    
    return if !$object;
    
    my @packages = $object->opr_package;
    
    if ( $params{is_in_index} ) {
        @packages = grep{ $_->is_in_index }@packages;
    }

    if ( $params{latest} ) {
        my %latest;

        for my $package ( @packages ) {
            my $name_id = $package->name_id;
            my $version = $package->version;
            my $name    = $package->opr_package_names->package_name;

            if ( !exists $latest{$name_id} || _is_version_greater( $version, $latest{$name_id}->{version} ) ) {
                $latest{$name_id} = {
                    version  => $version,
                    package  => $package,
                    name     => $name,
                };
            }
        }

        @packages = map{ $_->{package} } sort { $a->{name} cmp $b->{name} }values %latest;
    }
    
    return @packages;
};

sub _is_version_greater {
    my ($new,$old) = @_;

    my ($new_major, $new_minor, $new_patch) = split /\./, $new;
    my ($old_major, $old_minor, $old_patch) = split /\./, $old;

    return 1 if $new_major > $old_major;
    return 1 if $new_major == $old_major and $new_minor > $old_minor;
    return 1 if $new_major == $old_major and $new_minor == $old_minor and $new_patch > $old_patch;
    return 0;
}

sub to_hash {
    my ($self) = @_;
    
    my %info = (
        USER     => $self->user_name || '',
        WEBSITE  => $self->website   || '',
        REALNAME => $self->realname  || '',
    );
}

sub BUILD {
    my ($self) = @_;
    
    $self->delete_flag( 'user_id' );
    
    return if !$self->user_id;
    
    my ($user) = $self->ask_table( 'opr_user' )->find( $self->user_id );
    
    if ( !$user ) {
        $self->user_id( undef );
        return;
    }
    
    $self->not_in_db( 0 );
    
    $self->user_object( $user );
    
    for my $attr ( @attributes ) {
        $self->$attr( $user->$attr() );
    }
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;
    
    return if !$self->_has_changed;
        
    my @changed_attrs = $self->changed_attrs;
    my $user          = $self->user_object;
    
    if ( !$user ) {
        ($user) = $self->ask_table( 'opr_user' )->create( {} );
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
}

no Moose;

1;
