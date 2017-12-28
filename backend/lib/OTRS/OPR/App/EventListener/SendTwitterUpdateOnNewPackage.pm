package OTRS::OPR::App::EventListener::SendTwitterUpdateOnNewPackage;

use strict;
use warnings;

use File::Basename;
use Net::Twitter;
use MojoX::GlobalEvents;

on 'package_indexed' => sub {
    my $package_id = shift;
    my $schema     = shift;
    my $config     = shift;

    return if !$package_id || !$schema || !$config;

    my $package = $schema->resultset( 'opr_package' )->search({ package_id => $package_id })->first;

    return if !$package;

    my $twitter = $config->get('twitter');

    my $nt = Net::Twitter->new(
        traits   => [qw/API::RESTv1_1/],
        consumer_key        => $twitter->{consumer_key},
        consumer_secret     => $twitter->{consumer_secret},
        access_token        => $twitter->{token},
        access_token_secret => $twitter->{token_secret},
        ssl                 => 1,
    );
 
    my $name    = $package->opr_package_names->package_name;
    my $message = sprintf 'A new module on #OPAR: %s %s %s%s #OTRS',
        $name,
        $package->version,
        $twitter->{url},
        $name;
     
    my $result  = $nt->update($message);
};

1;
