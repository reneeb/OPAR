package OTRS::OPR::App::EventListener::SendTwitterUpdateOnNewPackage;

use strict;
use warnings;

use File::Basename;
use Net::Twitter;

use OTRS::OPR::App::EventHandler;

on 'package_indexed' => sub {
    my $package_id = shift;
    my $schema     = shift;
    my $config     = shift;

    my $package = $schema->resultset( 'opr_package' )->search({ package_id => $package_id })->first;

    return if !$package;
    
    my $nt = Net::Twitter->new(
        traits   => [qw/API::RESTv1_1/],
        consumer_key        => $config{twitter}->{consumer_key},
        consumer_secret     => $config{twitter}->{consumer_secret},
        access_token        => $config{twitter}->{token},
        access_token_secret => $config{twitter}->{token_secret},
    );
 
    my $name    = $package->opr_package_names->name;
    my $message = sprintf 'A new module on #OPAR: %s %s %s%s #OTRS',
        $name,
        $package->version
        $config->{twitter}->{url},
        $name;
     
    my $result  = $nt->update($message);
};

1;
