package OTRS::OPR::App::Attributes;

use strict;
use warnings;

use Attribute::Handlers;
use CGI::Application;
use Data::Dumper;

%CGI::Application::__permissions = ();
%CGI::Application::__json        = ();
%CGI::Application::__streams     = ();

sub Permission : ATTR(BEGIN) {
    my ($pkg,$sym,$code,$attrname,$params,$phase) = @_;
    
    my $permission = ref $params ? $params->[0] : $params;

    $CGI::Application::__permissions{"${$sym}"} = $permission;
}

sub Json : ATTR(BEGIN) {
    my ($pkg,$sym,$code,$attrname,$params,$phase) = @_;

    $CGI::Application::__json{"${$sym}"} = 1;
}

sub Stream : ATTR(BEGIN) {
    my ($pkg,$sym,$code,$attrname,$params,$phase) = @_;
    
    my $type = ref $params ? $params->[0] : $params;
    $CGI::Application::__streams{"${$sym}"} = $type;
}

1;
