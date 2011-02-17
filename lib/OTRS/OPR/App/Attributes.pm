package OTRS::OPR::App::Attributes;

use strict;
use warnings;

use Attribute::Handlers;
use CGI::Application;
use Data::Dumper;

%CGI::Application::__permissions = ();
%CGI::Application::__json        = ();

sub Permission : ATTR(BEGIN) {
    my ($pkg,$sym,$code,$attrname,$params,$phase) = @_;
    
    my $permission = $params->[0];
    $CGI::Application::__permissions{$code} = $permission;
}

sub Json : ATTR(BEGIN) {
    my ($pkg,$sym,$code) = @_;
    
    $CGI::Application::__json{$code} = 1;
}

1;