package ReneeB::Session::State;

use strict;
use warnings;

our $VERSION = 0.01;

my %modules = (
    file   => 'ReneeB::Session::State::File',
    cookie => 'ReneeB::Session::State::Cookie',
);

sub new{
    my ($class,$args) = @_;
    my $self = bless {}, $class;
    
    my $type = $args->{type};
    
    if( exists $modules{ $type } ){
        my $module = $modules{$type};
        (my $file = $module) =~ s!::!/!g;
        $file .= '.pm';
        require $file;
        $self = $module->new;
    }
    
    return $self;
}

1;