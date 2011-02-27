package OTRS::OPM::Analyzer::Role::Documentation;

use Moose::Role;

sub analyze_unittests {
    my ($self,$opm) = @_;
    
    my $has_documentation = 0;
    
    FILE:
    for my $file ( $opm->files ) {
        if ( $file->{filename} =~ m{ /doc/ .*?\.(?:xml|pod) \z } ) {
            $has_documentation = 1;
            last FILE;
        }
    }
    
    return $has_documentation;
}

no Moose::Role;

1;