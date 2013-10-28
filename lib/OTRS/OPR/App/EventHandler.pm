package OTRS::OPR::App::EventHandler;

# ABSTRACT: A module to handle events

use strict;
use warnings;

use File::Find::Rule;
use File::Spec;

use base 'Exporter';
our @EXPORT = qw(on publish);

our $VERSION = 0.01;

my %subscriber;

sub init {
    my ($class, $namespace) = @_;

    my @spaces = split /::/, $namespace;
    my @dirs   = map{ File::Spec->catdir( $_, @spaces ) }@INC; 
    my @files  = File::Find::Rule->file->name( '*.pm' )->in( @dirs );

    for my $file ( @files ) {
        require $file;
    }
}

sub on {
    my ($event,$sub) = @_;

    return if ref $event or !ref $sub or ref $sub ne 'CODE';

    my $package = caller;
    $subscriber{$event}->{$package} = $sub;
}

sub publish {
    my ($event, @param) = @_;

    for my $package ( sort keys %{ $subscriber{$event} || {} } ) {
        $subscriber{$event}->{$package}->(@param);
    }
}


1;

=head1 SYNOPSIS

Initialize the module once:

  use Local::EventHandler;

  # load all event handlers located in "Name::Space"
  Local::EventHandler->init( 'Name::Space' );

In any Perl module:

  use Local::EventHandler;
  publish event_name => $param1, $param2;

In your event handler modules;

  use Local::EventHandler;
  on event_name => sub {
      print "received event event_name\n";
  };

=head1 FUNCTIONS

=head2 init

=head2 on

=head2 publish
