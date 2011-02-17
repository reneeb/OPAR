package ReneeB::Session::State::File;

use strict;
use warnings;

my $file = 'session.file';

sub new{
    my ($class) = @_;
    my $self    = bless {}, $class;
    
    return $self;
}

sub save{
    my ($self, $id) = @_;
    
    if( open my $save, '>', $file ){
        print $save $id;
        close $save;
    }
}

sub id{
    my ($self) = @_;
    
    my ($id);
    
    if(open my $fh, '<', $file){
        chomp( $id = <$fh> );
        close $fh;
    }
    
    return $id;
}

sub delete{
    unlink $file;
}

1;