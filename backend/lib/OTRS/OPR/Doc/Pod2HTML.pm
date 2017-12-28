package OTRS::OPR::Doc::Pod2HTML;

use Moose;
use Moose::Util::TypeConstraints;

use Pod::Simple;
use Pod::Simple::XHTML;

# define types
subtype 'PodString' =>
    as 'Str' =>
    where { $_ };

coerce 'PodString' => 
    from 'Str' =>
    via {
        my $checker = Pod::Simple->new;
        
        # ignore output
        $checker->output_string( \my $trash );
        
        # try to parse
        $checker->parse_string( $_ );
        
        !$checker->any_errata_seen ? 
            $_ :
            "=head1 ERROR\n\nThe given Pod was not valid";
    };

has pod => (
    is       => 'ro',
    isa      => 'PodString',
    coerce   => 1,
);

has html => (
    is  => 'rw',
    isa => 'Str',
);

sub convert {
    my ($self) = @_;
    
    return if !$self->pod;
    return 1 if $self->html;
    
    my $html = '';
    
    my $parser = Pod::Simple::XHTML->new;
    
    $parser->html_header( '' );
    $parser->html_footer( '' );
    $parser->index( 0 );
    
    $parser->output_string( \$html );
    $parser->parse_string_document( $self->pod );
    
    $self->html( $html );
}

no Moose;

1;