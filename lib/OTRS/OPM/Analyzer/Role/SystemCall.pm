package OTRS::OPM::Analyzer::Role::SystemCall;

use Moose::Role;
use PPI;

sub analyze_systemcall {
    my ($self,$document) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm|pod|t) \z }xms;
    
    my $ppi = PPI::Document->new( \$document->{content} );
    
    my @system_calls;
    
    # get all backtick-commands
    my $backticks = $ppi->find( 'PPI::Token::QuoteLike::Backtick' );
    push @system_calls, map{ $_->content }@{$backticks || []};
    
    # get all qx-commands 
    my $qx = $ppi->find( 'PPI::Token::QuoteLike::Command' );
    push @system_calls, map{ $_->content }@{$qx || []};
    
    my $words = $ppi->find( 'PPI::Token::Word' );
    
    my %dispatcher = (
        system => \&_system,
        open   => \&_open,
        exec   => \&_exec,
    );
    
    WORD:
    for my $word ( @{$words} ) {
        my $content = $word->content;
        my $sub     = $dispatcher{$content};
        
        next WORD if !$sub;
        
        # if it is a statement get content
        my $parent = $word->parent;
        if ( ref $parent eq 'PPI::Statement' ) {
            push @system_calls, $parent->content;
            next WORD;
        }
        
        # if not statement, check  next tokens -> list or word or quote -> I want it
        
        my $next_significant = $word->snext_sibling;
        my $ssibling_type    = ref $next_significant;
        
        next WORD if $ssibling_type !~ m{ \A
            PPI:: (?:
                Token::Word |
                Structure::List |
                Token::Quote::(?:Double|Single) |
                Token::QuoteLike::Words
            ) \z }xms;
            
        push @system_calls, $parent->content;
    }
    
    return join "\n", @system_calls;
}

no Moose::Role;

1;