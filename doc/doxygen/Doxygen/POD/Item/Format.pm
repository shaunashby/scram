package Doxygen::POD::Item::Format;

=head1 NAME

Doxygen::POD::Item::Format - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $item = new Doxygen::POD::Item::Format;

=head1 ABSTRACT

A POD =begin/=end/=for block.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;

use     base    qw(Doxygen::POD::Item);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate
{
    my  $self = shift;
    my  $fmt  = $self->{_fmt_};
    
    if ($fmt =~ /^html?$/i) {
        Doxygen::Item::genThing("\@htmlonly\n", @_);
    } elsif ($fmt =~ /^latex$/i) {
        Doxygen::Item::genThing("\@latexonly\n", @_);
    } elsif ($fmt !~ /^doxygen$/i) {
        my  %flags  = @_;
        my  $context = $flags{source};
        
        $context->log('W', 'Unrecognized format:  ', $self->{_fmt_});
        
        return;
    }

    my  %flags = @_;
    my  $which = $flags{which} || 'text';

    $flags{which} = $which unless defined $flags{which};
    
    Doxygen::Item::genThing($_, %flags)
        for @{$self->text($which)};
    
    if ($fmt =~ /^html?$/i) {
        Doxygen::Item::genThing("\@endhtmlonly\n", @_);
    } elsif ($fmt =~ /^latex$/i) {
        Doxygen::Item::genThing("\@endlatexonly\n", @_);
    }
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl Doxygen::Item Doxygen::POD::Item

=head1 AUTHOR

Marc M. Adkins, L<mailTo:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
