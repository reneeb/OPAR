package OTRS::OPM::Analyzer::Role::License;

use Moose::Role;
use Software::License;
use Software::LicenseUtils;

sub analyze_license {
    my ($self,$opm) = @_;
    
    my $license  = $opm->license;
    my $name     = $opm->name;
    return "Could not find any license for $name." if !$license;
    
    # software::licenseutils expect pod, so we have to fake
    # a small pod section
    my $pod = qq~
    =head1 License
    
    $license
    ~;
    
    # try to find the appropriate license
    my @licenses_found = Software::LicenseUtils->guess_license_from_pod( $pod );
    
    my $warning = '';
    if ( !@licenses_found ) {
        $warning = "Could not find the open source license in Software::License for $license.";
    }
    
    return $warning;
}

no Moose::Role;

1;