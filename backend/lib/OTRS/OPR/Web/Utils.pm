package OTRS::OPR::Web::Utils;

use strict;
use warnings;

use parent 'OTRS::OPR::Exporter::Aliased';

use DateTime;
use DateTime::TimeZone;

our @EXPORT_OK = qw(
    prepare_select
    page_list
    time_to_date
    validate_opm_name
    looks_like_number
    looks_empty
);

sub prepare_select {
    my ($self,$params) = @_;
    
    return if not exists $params->{data} or ref $params->{data} ne 'HASH';
    return if exists $params->{excluded} and ref $params->{excluded} ne 'ARRAY';
    return if exists $params->{selected} and ref $params->{selected};
    
    my $data     = $params->{data}     || {};
    my $excluded = $params->{excluded} || [];
    my $selected = $params->{selected};
    
    my @options;
    
    my $not_numeric = grep{ /\D/ }keys %{$data};
    my @sorted_keys = $not_numeric ?
        sort{ $a cmp $b }keys %{$data} :
        sort{ $a <=> $b }keys %{$data};
    
    OPTIONVALUE:
    for my $option_key ( @sorted_keys ) {
        my $option_value = $data->{$option_key};
        
        next OPTIONVALUE if grep{ $option_value eq $_ }@{$excluded};
        
        my $is_selected = 0;
           $is_selected = 1 if $selected and $option_value eq $selected;
        
        push @options, {
            SELECTED => $is_selected,
            VALUE    => $option_value,
            KEY      => $option_key,
        };
    }
    
    return \@options;
}

sub page_list {
    my ($self,$max,$page,$tmpl_params) = @_;
    
    $tmpl_params ||= {};
    
    my $pages = [ map{ { 
        PAGE     => $_, 
        SELECTED => ( $page and $_ == $page ) ? 1 : 0,
        %{ $tmpl_params },
    } }(1..$max) ];
    
    return $pages if scalar @{$pages} < 7;
    
    my $nr_orig = scalar @{$pages};
    
    my @begin = @{$pages}[0..2];
    my @end   = @{$pages}[-3..-1];
    my @rest  = @{$pages}[3..$nr_orig-4];
    
    my @middle;
    
    my $nr = scalar @rest;
    
    if( $page < 3 || $page >= $nr_orig-3 ) {
        @middle = ({});
    }
    elsif( $page <= 5 ) {
        @middle = $nr > 3 ? (@rest[0..2], {}) : @rest;
    }
    elsif( $page >= $nr_orig-4 ) {
        @middle = $nr > 3 ? ( {}, @rest[-3..-1] ) : @rest;
    }
    else {
        @middle = $nr > 3 ? ( {}, @rest[ $page-5 .. $page-3 ], {} ) : @rest;
    }
    
    return [@begin,@middle,@end];
}

sub time_to_date {
    my ($self,$time,$params) = @_;
    
    return '' if !$time or $time !~ m{ \A \d+ \z }xms;
    
    # check if a time zone is given and if it is a valid name
    my $tz = $params->{time_zone} || 'Europe/London';
    if ( !DateTime::TimeZone->is_valid_name( $tz ) ) {
        $tz = 'Europe/London';
    }
    
    # create DateTime object with given epoch seconds for the given time zone
    my $date_time = DateTime->from_epoch(
        epoch     => $time,
        time_zone => $tz,
    );
    
    my @parts;
    
    # the user wants to get the date
    # format => dd month_abbr YYYY
    if ( not exists $params->{date} or $params->{date} ) {
        my $day   = sprintf "%02d", $date_time->day;
        my $month = $date_time->month_abbr;
        my $year  = $date_time->year;

        push @parts, $day . ' ' . $month . ' ' . $year;
    }
    
    # the user wants to get the time
    # format => hh:mm:ss
    if ( $params->{time} ) {
        push @parts, $date_time->hms(':');
    }
    
    return join ' ', @parts;
}

sub validate_opm_name {
    my ($class,$file,$without_suffix) = @_;
    
    my ($basename) = $file =~ m{ \A .*? ([^\\\/]+) \z }xms;
    
    $basename = '' if !defined $basename;
    
    my $suffix = '(\.opm)';
    
    if ( $without_suffix ) {
        $suffix = '';
    }
    
    my $success = $basename =~ m{
        \A
        ([\w\s-]+?)      # filename
        (?:              # begin version
          -(                # dash
            \d+             # major number of version
            (?:\.\d+)?      # optional minor number of version
            (?:\.\d+)?      # optional patch number of version
           )             # version
        )?               # version is optional
        $suffix
        \z               # string end
    }xms;
    
    return if !$success;
    return ($1,$2,$3);
}

sub looks_like_number {
	my ($s) = @_;
	#return /^\d+(\.\d*)?(e\^\d*)?$/;
	return ($s =~ /^\d+$/);
}

sub looks_empty {
	my ($s) = @_;
	return ($s =~ /^[\s\t\n\r]*$/);
}

1;

=head1 NAME

OTRS::OPR::Web::Utils - some utility functions for the whole OPR application

=head1 SYNOPSIS

  use OTRS::OPR::Web::Utils qw(prepare_select);

  use OTRS::OPR::Web::Utils qw(page_list);

  use OTRS::OPR::Web::Utils qw(time_to_date);

=head1 METHODS

=head2 page_list

=head2 prepare_select

=head2 time_to_date

converts epoch seconds to a date

    my $date = $object->time_to_date(
      $time,
      $params,
    );

params can be:

=over 4

=item * time_zone

The time zone for which the date is calculated. E.g. Europe/Berlin

Default: Europe/London

=item * date

0 | 1 (default 1) - show the date

=item * time

0 | 1 (default 0) - show the time

=back

Examples:

  my $time = $object->time_to_date(
      1284456789,
      {
          time_zone => 'Asia/Tokyo',
          time      => 1,
          date      => 0,
      }
  );

prints

  18:33:09

  my $date = $object->time_to_date(
      1284456789,
      {
          time_zone => 'Europe/Berlin',
      }
  );

prints

  14 Sep 2010

  my $date_and_date = $object->time_to_date(
      1284456789,
      {
          time_zone => 'Europe/Berlin',
          time      => 1,
      }
  );

prints

  14 Sep 2010 11:33:09

=cut
