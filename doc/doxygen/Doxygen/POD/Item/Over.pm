package Doxygen::POD::Item::Over;

=head1 NAME

Doxygen::POD::Item::Over - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $item = new Doxygen::POD::Item::Over;

=head1 ABSTRACT

A block of source code in a POD source file.

=head1 DESCRIPTION

Represents a list of items which is indented in the displayed format.
Provides three choices:

=over

=item   *

Bulleted

=item   *

Numbered

=item   *

Named definitions

=back

This has three advantages:

=over

=item   1

First advantage

=item   2

Second advantage

=item   3

Third advantage

=back

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     base    qw(Doxygen::POD::Item);

our $VERSION = '0.01';

use     constant    {
    TYPE_BULLET =>  1,
    TYPE_NUMBER =>  2,
    TYPE_NAMED  =>  3
};

use     constant    TYPE_TAG    =>  [
    undef,
    'ul',
    'ol',
    'dl'
];

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

In order to determine what type of list to generate,
it is necessary to look at all of the contained items and
figure out how they are supposed to be displayed.
There are three cases we recognize:

=over

=item   C<TYPE_BULLET>

The items in the list are bulleted.
This corresponds to HTML C<ul> tags.

=item   C<TYPE_NUMBER>

The items in the list are all numbered.
This corresponds to HTML C<ol> tags.

=item   C<TYPE_NAMED>

The items in the list are named,
as defined terms.
This corresponds to HTML C<dl> tags.

=back

These are conceived of as ordered, so that the presence of
C<TYPE_NUMBER> will outrank C<TYPE_BULLET> and C<TYPE_NAMED>
outranks both.
It is not currently possible to mix them in the same list.

=cut

sub generate    # $self, %flags
{
    my ($self, %flags) = @_;
    my  $text = $self->text($flags{which});
    
    return  # nothing there...
        unless isa($text, 'ARRAY')
            && @$text;
        
    unless ($self->{type}) {
        # Need to figure out what type of list we represent:
        $self->{_item_count_} = 0;
        
        for (@$text) {
            unless (isa($_, 'Doxygen::POD::Item')) {
                $flags{source}->log
                    ('W', "Non-POD::Item in Over list:  ", $_, "\n");
                next;
            }
            
            next
                if $_->{disabled};
            
            $self->{_item_count_}++;
                
            my  $type = TYPE_NAMED;

            if ($_->{name} =~ /\s*[\*\+\-]\s*$/) {
                # Simple bullet type:
                $type = TYPE_BULLET;
            } elsif ($_->{name} =~ /\s*\d+\s*$/) {
                # Numbered item list:
                $type = TYPE_NUMBER;
            }

            $self->{type} = $type
                unless $self->{type}
                    && $self->{type} >= $type;
        }
    }
    
    return
        unless $self->{_item_count_};
    
    $flags{comment} = 1;
    $flags{named}   = $self->{type} == TYPE_NAMED;
    
    Doxygen::Item::genThing('<' .  TYPE_TAG->[$self->{type}] . ">\n", %flags)
        if $self->{type};
    
    $self->SUPER::generate
        (%flags, over => ($flags{over} ? "  $flags{over}" : '  '));
        
    Doxygen::Item::genThing('</' . TYPE_TAG->[$self->{type}] . ">\n", %flags)
        if $self->{type};
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
