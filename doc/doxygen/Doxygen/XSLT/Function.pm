package Doxygen::XSLT::Function;

=head1 NAME

Doxygen::XSLT::Function - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $func = new Doxygen::XSLT::Function;

=head1 ABSTRACT

A Doxygen::XSLT::Function object represents C/C++ function/method
from a source file processing by the Doxygen documentation system.

Overload the usual Doxygen::Item::Function class to add references
and alter comment generation to show them.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     base qw(Doxygen::Item::Function);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<references($self, $function)>

Sets reference (callout) to another function.

=cut

sub references
{
    my ($self, $function) = @_;
    
    $self->{reference}->{$function}++;
}
    
###########################################################################
###########################################################################

=item   C<genComment($self, %flags)>

Generates comment lines for the item.

Overloaded to show function references.

=cut

sub genComment  # $self, %flags
{
    my ($self, %flags) = @_;
    
    $self->SUPER::genComment(%flags);
    
    if (isa($self->{reference}, 'HASH')) {
        print "\n$flags{indent} * <strong>Calls Templates:</strong>\n";
        
        print   "$flags{indent} * \\li $_()\n"
            for keys %{$self->{reference}};
        
        print "\n";
    }
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl, Doxygen::Item, Doxygen::Filter

=head1 AUTHOR

Marc M. Adkins, L<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
