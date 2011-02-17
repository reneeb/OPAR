package ReneeB::Session::Store;

use strict;
use warnings;

our $VERSION = 0.01;

my %modules = (
    file => 'ReneeB::Session::Store::File',
    dbic => 'ReneeB::Session::Store::DBIC',
    dbh  => 'ReneeB::Session::Store::DBI',
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
        $self = $module->new( $args );
    }
    
    return $self;
}

1;