package Data::Validate::WithYAML::Plugin::URL;

use warnings;
use strict; 

use Carp;
use Regexp::Common;

=head1 NAME

Data::Validate::WithYAML::Plugin::URL - Plugin to check URLs (http, ftp)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Validate::WithYAML::Plugin::URL;

    my $foo = Data::Validate::WithYAML::Plugin::URL->check( 'http://perl-services.de' );
    ...
    
    # use the plugin via Data::Validate::WithYAML
    
    use Data::Validate::WithYAML;
    
    my $url       = 'http://perl-services.de';
    my $validator = Data::Validate::WithYAML->new( 'test.yml' );
    print "yes" if $validator->check( 'website', $url );

test.yml

  ---
  step1:
      website:
          plugin: URL
          type: required
  

=head1 SUBROUTINES

=head2 check

=cut

sub check {
    my ($class, $value) = @_;
    
    croak "no value to check" unless defined $value;
    
    my $return = 0;
    if( $value =~ /(?:$RE{URI}{HTTP}|$RE{URI}{FTP})/ ){
        $return = 1;
    }
    return $return;
}

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-validate-withyaml-plugin-email at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-WithYAML-Plugin-URL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::WithYAML::Plugin::URL

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data::Validate::WithYAML::Plugin::URL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data::Validate::WithYAML::Plugin::URL>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Validate::WithYAML::Plugin::URL>

=item * Search CPAN

L<http://search.cpan.org/dist/Data::Validate::WithYAML::Plugin::URL>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::Validate::WithYAML::Plugin::URL
