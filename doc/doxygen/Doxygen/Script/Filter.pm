package Doxygen::Script::Filter;

=head1 NAME

Doxygen::Script::Filter - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

Generally this class will be instantiated:
    
    my  $filter = new Doxygen::Script::Filter($path);

and used within one of the other Doxygen:: internal classes.

DoxyFilt.pl command-line arguments might be:

    # DOS batch files:
    DoxyFilt.pl --filter  Script
                '--flag=comment=qr(^\s*rem ?(.*)$)im'
    
    # Generic *NIX shell script:
    DoxyFilt.pl --filter  Script
                '--flag=comment=qr(^\s*#{2,3}(?!#) ?(.*)$)m'

=head1 ABSTRACT

Simplistic filter for scripts:

=head1 DESCRIPTION

Generates a Doxygen file comment block.
Pulls out whatever comments are marked via the
basic comment pattern mechanism supported by C<Doxygen::Source>.

May at some point create a script group and mark therein.

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;

use     base qw(Doxygen::Filter);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<parse($self, $text, $context)>

Parse a source file.

Attach results (C<Doxygen::Item> objects) to C<Doxygen::Source> object.

=cut

sub parse       # $self, $text, $context
{
    my  $self = shift;
    
    $self->parseCmnts(@_);
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl Doxygen::Filter

=head1 AUTHOR

Marc M. Adkins, L<mailTo:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
