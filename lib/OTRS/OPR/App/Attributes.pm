package OTRS::OPR::App::Attributes;

use strict;
use warnings;
use Attribute::Handlers;
use Data::Dumper;

sub Permission : ATTR(CODE) {
    my ($pkg,$sym,$code,$attrname,$params) = @_;
    
    my $name = *{$sym}{NAME};
    
    no warnings 'redefine';
    
    *{$sym} = sub {
        my ($self) = @_;
        unless( $self->user->has_group( $params->[0] ) ) {
            $self->logger->info(
                $self->user->user_name . 
                ' has no sufficient permission for ' .
                $params->[0]
            );
            $self->no_permission(1);
            return;
        }
        $code->(@_);
    };
}

sub Json : ATTR(CODE) {
    my ($pkg,$sym,$code) = @_;
    
    my $name = *{$sym}{NAME};
    
    no warnings 'redefine';
    
    *{$sym} = sub {
        $_[0]->json_method(1);
        $code->(@_);
    };
}

1;