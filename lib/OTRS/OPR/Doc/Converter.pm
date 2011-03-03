package OTRS::OPR::Doc::Converter;

use Moose;

use OTRS::OPR::Doc::Pod2HTML;

has raw => (
    is => 'ro',
);

sub convert {
    my ($self) = @_;
    
    return if !$self->raw;
    
    my $converter = OTRS::OPR::Doc::Pod2HTML->new(
        pod => $self->raw;
    );
    
    $converter->convert;
    return $converter->html;
}

no Moose;

1;