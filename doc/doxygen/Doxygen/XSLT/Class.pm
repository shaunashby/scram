package Doxygen::XSLT::Class;

=head1 NAME

Doxygen::XSLT::Class - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $cls = new Doxygen::XSLT::Class;

=head1 ABSTRACT

A Doxygen::XSLT::Class object represents an imaginary C++ class for
processing by the Doxygen documentation system.
These objects should be created by a specific source-language filter
(subclass of Doxygen::Filter, named Doxygen::I<language>::Filter)
when processing a source file.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     base qw(Doxygen::Item::Class);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<new($class, %fields)>

Construct falls through to Doxygen::Item::Class::new().

=cut

sub new         # $class, %fields
{
    Doxygen::Item::Class::new(@_, includes => [ ], imports => [ ])
}

###########################################################################
###########################################################################

=item   C<xsl_import($self, $name)>

Set include 'class' name for class class ancestor.

This list is subsidiary to the include() list.

=cut

sub xsl_import
{
    my  $self = shift;
    
    unshift @{$self->{imports}}, shift
}

###########################################################################

=item   C<xsl_include($self, $name)>

Set include 'class' name for class ancestor.

This is the primary ancestor list.

=cut

sub xsl_include
{
    my  $self = shift;
    
    unshift @{$self->{includes}}, shift
}

###########################################################################
###########################################################################

=item   C<ancestors($self)>

Return ancestor list for class.

Returns a list of the included and then the imported class names.

=cut

sub ancestors
{
    my  $self = shift;
    
#   print STDERR __PACKAGE__, "::ancestors()\n";
    
    ( @{$self->{includes}}, @{$self->{imports}} )
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl, Doxygen::XSLT, Doxygen::Filter

=head1 AUTHOR

Marc M. Adkins, L<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
