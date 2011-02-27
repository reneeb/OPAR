package OTRS::OPM::Analyzer::Role::BasicXMLCheck;

use Moose::Role;
use HTML::Lint;

sub analyze_basicxmlcheck {
    my ( $self, $document ) = @_;
    
    return if $document->{filename} !~ m{ \.xml \z }xms;
    
    my $content = $document->{content};    
    my $check_result = '';
    
    eval {
        my $parser = XML::LibXML->new;
        $parser->parse_string( $content );
    } or $check_result = $@;
    
    return $check_result;
}

no Moose::Role;

1;