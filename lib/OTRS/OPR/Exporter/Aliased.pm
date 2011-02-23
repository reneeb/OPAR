package OTRS::OPR::Exporter::Aliased;

use strict;
use warnings;

sub import {
    my ($class,@methods) = @_;
    
    no strict 'refs';
    
    my $caller = caller();
    my @ok = @{ $class . '::EXPORT_OK' };
    
    METHOD:
    for my $method ( @methods ) {
        
        my $ref = ref $method;
        if ( $ref and $ref eq 'HASH' ) {
            
            KEY:
            for my $key ( keys %{$method} ) {
                next KEY if !grep{ $key eq $_ }@ok;
                
                my $new_name = $method->{$key};
                *{ $caller . '::' . $new_name } = *{ $class . '::' . $key };
            }
        }
        
        next METHOD if $ref;
        
        if ( $method eq ':all' ) {
            for my $name ( @ok ) {
                *{ $caller . '::' . $name } = *{ $class . '::' . $name };
            }
            
            last METHOD;
        }
        
        next METHOD if !grep{ $_ eq $method }@ok;
        *{ $caller . '::' . $method } = *{ $class . '::' . $method };
    }
}

1;