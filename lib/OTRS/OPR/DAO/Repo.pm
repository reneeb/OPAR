package OTRS::OPR::DAO::Repo;

use Moose;
use OTRS::OPR::App::AttributeInformation;

extends 'OTRS::OPR::DAO::Base';

my @attributes = qw(
    framework email repo_id
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

has packages => (
    metaclass    => 'OTRS::OPR::App::AttributeInformation',
    is_trackable => 1,
    traits       => [ 'Array' ],
    is           => 'rw',
    isa          => 'ArrayRef[Int]',
    default      => sub{ [] },
    handles      => {
        add_package => 'push',
    },
    auto_deref   => 1,
    trigger      => sub{ shift->_dirty_flag( 'packages' ) },
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
    
    my $repo = $self->get_object( 'repo' );
    
    return if !$repo;
    
    my @package_ids = $self->packages;
    my @packages    = map{ {
        NAME_ID => $_->name_id,
        NAME    => $_->package_name,
    } } $self->ask_table( 'opr_package_names' )->search({
        name_id => \@package_ids,
    });
        
    # create the infos for the template
    my %info = (
        REPO_ID       => $repo->repo_id,
        FRAMEWORK     => $repo->framework,
        EMAIL         => $repo->email,
        PACKAGES      => \@packages,
    );
    
    return %info;
}

sub save {
    my ($self) = @_;
    
    $self->DEMOLISH;
}

sub BUILD {
    my ($self) = @_;
    
    my $repo;
    if ( $self->repo_id ) {
        ($repo) = $self->ask_table( 'opr_repo' )->find( $self->repo_id );
    }
        
    return if !$repo;
        
    $self->not_in_db( 0 );
    
    for my $attr ( @attributes ) {
        $self->$attr( $repo->$attr() );
    }

    my @packages = $self->ask_table( 'opr_repo_package' )->search({
        repo_id => $repo->repo_id,
    });

    $self->packages( [ map{ $_->name_id }@packages ] );
    
    $self->add_object( repo => $repo );
    
    $self->_after_init();
}

sub DEMOLISH {
    my ($self) = @_;

    return if !$self->_has_changed;
        
    my @changed_attrs = $self->changed_attrs;
    my $repo          = $self->get_object( 'repo' );
    
    if ( !$repo and $self->repo_id ) {
        $repo = $self->ask_table( 'opr_repo' )->create({
            repo_id => $self->repo_id
        });
        $repo->update;
    
        $self->add_object( repo => $repo );
    }

    return if !$repo;
    
    #$self->_schema->storage->debug( 1 );
    
    ATTRELEMENT:
    for my $attr_element ( @changed_attrs ) {
        my $attr = $attr_element->[0];
        
        next ATTRELEMENT if $attr eq 'repo_id';
        
        if ( $attr eq 'packages' ) {
            my @package_ids = $self->packages;

            $self->ask_table( 'opr_repo_package' )->delete({ repo_id => $self->repo_id });

            for my $name_id ( @package_ids ) {
                $self->ask_table( 'opr_repo_package' )->find_or_create({
                    repo_id => $self->repo_id,
                    name_id => $name_id,
                });
            }

            next ATTRELEMENT;
        }
        
        $repo->$attr( $self->$attr() );
    }
    
    $repo->in_storage ? $repo->update : $repo->insert;
}

no Moose;

1;
