package OTRS::OPM::Analyzer::Role::PerlCritic;

use Moose::Role;

use File::Basename;
use File::Temp ();
use Perl::Critic;

sub analyze_perlcritic {
    my ($self,$document) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm|pod|t) \z }xms;
    
    my ($file,$path,$suffix) = fileparse( $document->{filename}, qr{ \..* \z }xms );
    
    my $fh = File::Temp->new(
        SUFFIX => $suffix,
    );
    
    my $filename = $fh->filename;
    
    print $fh $document->{content};
    close $fh;
    
    my $perlcriticrc = $self->config->get( 'utils.perlcritic.config' );
    my %options;
    $options{-profile} = $perlcriticrc if $perlcriticrc;
    
    my $critic       = Perl::Critic->new(
        -theme    => 'otrs',
        -include  => ['otrs'],
        %options,
    );
    
    my @violations = $critic->critique( $filename );
    my $return     = join '', @violations;
    
    return $return;
}

no Moose::Role;

1;