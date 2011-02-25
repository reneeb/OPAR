package Data::Validate::WithYAML::Plugin::EMail;

use warnings;
use strict; 

use Carp;
use Regexp::Common qw[Email::Address];

=head1 NAME

Data::Validate::WithYAML::Plugin::EMail - Plugin to check Mail-Adresses

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::EMail;

    my $foo = Data::Validate::WithYAML::Plugin::EMail->check( 'test@exampl.com' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $email     = 'test@exampl.com';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'email', $email );

test.yml

  ---
  step1:
      email:
          plugin: EMail
          type: required
  

=head1 SUBROUTINES

=head2 check

=cut

sub check {
    my ($class, $value) = @_;
    
    croak "no value to check" unless defined $value;
    
    my $return = 0;
    if( $value =~ /($RE{Email}{Address})/ ){
        $return = 1;
    }
    return $return;
}

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-validate-withyaml-plugin-email at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-WithYAML-Plugin-EMail>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::WithYAML::Plugin::EMail

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data::Validate::WithYAML::Plugin::EMail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data::Validate::WithYAML::Plugin::EMail>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Validate::WithYAML::Plugin::EMail>

=item * Search CPAN

L<http://search.cpan.org/dist/Data::Validate::WithYAML::Plugin::EMail>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::Validate::WithYAML::Plugin::EMail
