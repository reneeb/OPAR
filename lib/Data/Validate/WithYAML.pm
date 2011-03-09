package Data::Validate::WithYAML;

use strict;
use warnings;

use Carp;
use YAML::Tiny;

=head1 NAME

Data::Validate::WithYAML - Validate Data with YAML configuration

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
my (%required,%optional);
our $errstr = '';

=head1 SYNOPSIS

Perhaps a little code snippet.

    use Data::Validate::WithYAML;

    my $foo = Data::Validate::WithYAML->new( 'test.yml' );
    my %map = (
        name     => 'Test Person',
        password => 'xasdfjakslr453$',
        plz      => 64569,
        word     => 'Herr',
        age      => 55,
    );
    
    for my $field ( keys %map ){
        print "ok: ",$map{$field},"\n" if $foo->check( $field, $map{$field} );
    }

data.yml

  ---
  step1:
      name:
          type: required
          length: 8,122
      password:
          type: required
          length: 10,
      plz:
          regex: ^\d{4,5}$
          type: optional
      word:
          enum:
              - Herr
              - Frau
              - Firma
      age:
          type: required
          min: 18
          max: 65
  

=head1 METHODS

=head2 new

  my $foo = Data::Validate::WithYAML->new( 'filename' );

creates a new object.

=cut

sub new{
    my ($class,$filename) = @_;
    
    my $self = {};
    bless $self,$class;
    
    $self->_yaml_config($filename) or return undef;
    
    return $self;
}

=head2 set_optional

This method makes a field optional if it was required

=cut

sub set_optional {
    my ($self,$field) = @_;
    
    my $value = delete $required{$field};
    if( $value ) {
        $optional{$field} = $value;
    }
}

=head2 set_required

This method makes a field required if it was optional

=cut

sub set_required {
    my ($self,$field) = @_;
    
    my $value = delete $optional{$field};
    if( $value ) {
        $required{$field} = $value;
    }
}

=head2 validate

This subroutine validates one form. You have to pass the form name (key in the
config file), a hash with fieldnames and its values

    my %fields = (
        username => $cgi->param('user'),
        password => $password,
    );
    $foo->validate( 'step1', %fields );

=cut

sub validate{
    my ($self,$part,%hash) = @_;
}

=head2 fieldnames

=cut

sub fieldnames{
    my ($self,$step) = @_;
    
    my @names;
    if( defined $step ){
        @names = @{ $self->{fieldnames}->{$step} };
    }
    else{
        for my $step ( keys %{ $self->{fieldnames} } ){
            push @names, @{ $self->{fieldnames}->{$step} };
        }
    }
    

    return @names;
}

=head2 errstr

=cut

sub errstr{
    my ($self) = @_;
    return $errstr;
}

=head2 message

returns the message if specified in YAML

  $obj->message( 'fieldname' );

=cut

sub message {
    my ($self,$field) = @_;
    
    my $subhash = $required{$field} || $optional{$field};
    my $message = "";
    
    if ( $subhash->{message} ) {
        $message = $subhash->{message};
    }

    $message;
}

=head2 check

  $obj->check('fieldname','value');

checks if a value is valid. returns 1 if the value is valid, otherwise it
returns 0.

=cut

sub check{
    my ($self,$field,$value) = @_;
    
    my %dispatch = (
        min    => \&_min,
        max    => \&_max,
        regex  => \&_regex,
        length => \&_length,
        enum   => \&_enum,
    );
                    
    my $subhash = $required{$field} || $optional{$field};
    
    if( exists $required{$field} ){
        return 0 unless defined $value and length $value;
    }
    elsif( exists $optional{$field} and (not defined $value or not length $value) ){
        return 1;
    }
    
    my $bool = 1;
    
    for my $key( keys %$subhash ){
        if( exists $dispatch{$key} ){
            unless($dispatch{$key}->($value,$subhash->{$key})){
                $bool = 0;
                last;
            }
        }
        elsif( $key eq 'plugin' ){
            my $name     = $subhash->{$key};
            my $module   = 'Data::Validate::WithYAML::Plugin::' . $name;
            eval "use $module";
            
            if( not $@ and $module->can('check') ){
                my $retval = $module->check($value);
                $bool = 0 unless $retval;
            }
            else{
                croak "Can't check with $module";
            }
        }
    }
    
    return $bool;
}

# read config file and parse required and optional fields
sub _yaml_config{
    my ($self,$file) = @_;
    
    if(defined $file and -e $file){
        $self->{config} = YAML::Tiny->read( $file ) or 
                (($errstr = YAML::Tiny->errstr()) && return undef);

        for my $section(keys %{$self->{config}->[0]}){
            my $sec_hash = $self->{config}->[0]->{$section};
            for my $field(keys %$sec_hash){
                if(exists $sec_hash->{$field}->{type} and 
                          $sec_hash->{$field}->{type} eq 'required'){
                    $required{$field} = $sec_hash->{$field};
                    if( exists $optional{$field} ){
                        delete $optional{$field};
                    }
                }
                elsif( not exists $required{$field} ){
                    $optional{$field} = $sec_hash->{$field};
                }

                push @{$self->{fieldnames}->{$section}}, $field;
            }
        }
    }
    elsif(defined $file){
        $errstr = 'file does not exist';
        return undef;
    }
    
    return $self->{config};
}

sub _min{
    my ($value,$min) = @_;
    return $value >= $min;
}

sub _max{
    my ($value,$max) = @_;
    return $value <= $max;    
}

sub _regex{
    my ($value,$regex) = @_;
    my $re = qr/$regex/;
    return ($value =~ $re);
}

sub _length{
    my ($value,$check) = @_;
    
    if($check =~ /,/){
        my ($min,$max) = $check =~ /\s*(\d+)?\s*,\s*(\d+)?/;
        my $bool = 1;
        if(defined $min and length $value < $min){
            $bool = 0;
        }
        if(defined $max and length $value > $max){
            $bool = 0;
        }
        return $bool;
    }
    else{
        return length $value > $check;
    }
}

sub _enum{
    my ($value,$list) = @_;
    return grep{ $_ eq $value }@$list;
}

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-validate-withyaml at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data::Validate::WithYAML>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::WithYAML

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data::Validate::WithYAML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data::Validate::WithYAML>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Validate::WithYAML>

=item * Search CPAN

L<http://search.cpan.org/dist/Data::Validate::WithYAML>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007  - 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=cut

1; # End of Data::Validate::WithYAML
