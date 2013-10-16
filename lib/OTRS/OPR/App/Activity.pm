package OTRS::OPR::App::Activity;

use strict;
use warnings;

use Moose;

use Chart::Clicker;
use Chart::Clicker::Renderer::Bar;
use File::Spec;
use List::Util qw(first);

use OTRS::OPR::DB::Helper::Package { activity => 'package_activity' };
use OTRS::OPR::DB::Helper::Author  { activity => 'author_activity' };

my $TWO_YEARS = 2 * 365 * 24 * 60 * 60;
my $MONTH     = 30.5 * 24 * 60 * 60;

has schema     => (is => 'ro', required => 1);
has output_dir => (is => 'ro', isa => 'Str', required => 1);
has width      => (is => 'ro', isa => 'Int', default => 160);
has height     => (is => 'ro', isa => 'Int', default => 80);
has x_hidden   => (is => 'ro', isa => 'Bool', default => 1);
has y_hidden   => (is => 'ro', isa => 'Bool', default => 1);
has legend     => (is => 'ro', isa => 'Bool', default => 0);
has title      => (is => 'ro', isa => 'Str', default => 'Activity (24 months)');
has start      => (is => 'ro', isa => 'Int', default => sub { time - $TWO_YEARS });

sub table {
    my ($self, $table) = @_;
    return $self->schema->resultset( $table );
}

sub create_activity {
    my ($self, %params) = @_;

    return if !$params{type};

    $params{type} = lc $params{type};
    return if $params{type} ne 'author' && $params{type} ne 'package';

    return if !$params{id};

    my $activity = Chart::Clicker->new(
        width  => $self->width,
        height => $self->height,
    );

    # we want bar diagrams
    my $renderer = Chart::Clicker::Renderer::Bar->new;
    $activity->set_renderer( $renderer );

    # set some basic stuff
    $activity->legend->visible( $self->legend );
    $activity->get_context('default')->domain_axis->hidden( $self->x_hidden );
    $activity->get_context('default')->range_axis->hidden( $self->y_hidden );

    $activity->title->text( $self->title );

    # push an extra 0 to make the graph look nicer. Without that push
    # the last bar is too small...
    my @activity_data = $self->_get_activity_data( %params );

    if ( @activity_data && first { $_ != 0 }@activity_data ) {
        push @activity_data, 0;
        $activity->add_data( 'Uploads', \@activity_data );
    }

    $activity->write_output(
        File::Spec->catfile(
            $self->output_dir,
            sprintf "%s_%s.png", $params{type}, $params{id}
        )
    );
}

sub _get_activity_data {
    my ($self, %params) = @_;

    my $method   = $params{type} . '_activity';
    my @raw_data = $self->$method(
        id    => $params{id},
        start => $self->start,
    );
    
    my %hashed_data;

    # initialize months values with 0 to get 24 values
    my $time = $self->start;
    while ( $time <= time ) {
        my ($month,$year)  = (localtime $time)[4,5];
        my $key            = sprintf "%04d%02d", $year, $month;
        $hashed_data{$key} = 0;
    }

    # get activity values
    for my $upload_time ( @raw_data ) {
        my ($month,$year) = (localtime $upload_time)[4,5];
        my $key           = sprintf "%04d%02d", $year, $month;
        $hashed_data{$key}++;
    }

    my @activity_data = map{ $hashed_data{$_} } sort keys %hashed_data;
    return @activity_data;
}

1;
