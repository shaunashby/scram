package Doxygen::Item;

=head1 NAME

Doxygen::Item - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

Inherited by subclass:

    use base qw(Doxygen::Filter);

=head1 ABSTRACT

Provides a root class for a source object for the Doxygen documentation tool.
This class should be inherited by source-specific subclasses, which will in
turn be used by the DoxyFilt.pl script, called by the Doxygen program to
process source files other than C and C++.

A Doxygen::Item is an object that will be recognized by Doxygen when rendered
as a combination of C/C++ source code and Doxygen-enabled comments.
Known subclasses of Doxygen::Item include Doxygen::Item::Class,
Doxygen::Item::Class and Doxygen::Item::Function.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(can isa);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<new($class, %fields)>

Generic constructor for Doxygen::Item interprets all arguments
as a hash object and blesses a reference thereto, making it easy
to set initial field values.

=cut

sub new         # $class, %fields
{
    my ($class, %fields) = @_;
    
    $fields{_sort_}->{Class}    = 'order'
        unless defined $fields{_sort_}->{Class};
    
    $fields{_sort_}->{Function} = 'alpha'
        unless defined $fields{_sort_}->{Function};
    
    bless \%fields, $class
}

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Item-specific massage sequences.

=cut

sub massage     # $self, $context
{
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate    # $self, %flags
{
    my  $self = shift;
    
    $_->generate(@_)
        for $self->items('class');
    
    $_->generate(@_)
        for $self->items('function');
}

###########################################################################

=item   C<genComment($self, %flags)>

Generates comment lines for the item.

=cut

sub genComment  # $self, %flags
{
    my  $self = shift;
    
    for my $which (qw(brief comment notes)) {
        next unless $self->text($which);
        
        unless (isa($self->text($which), 'ARRAY')) {
            warn "*** $which items for $self not an array reference\n";
            next;
        }
        
        genThing($_, @_, comment => 1, which => $which)
            for @{$self->text($which)};
    }
}

###########################################################################

=item   C<genThing($thing, %flags)>

Generate a thing, which may be an object, an array reference, or a string.

When the thing is an object of type Doxygen::Item it is generated
using the C<generate> method.

Recursive.

=cut

sub genThing    # $thing, %flags
{
    my  $thing = shift;
    
    return unless defined $thing;
    
    if (isa($thing, 'Doxygen::Item') && ref($thing)) {
        $thing->generate(@_)
            unless $thing->{disabled};
    } elsif (isa($thing, 'ARRAY')) {
        # Wrapped in an array, strings not to be in comment chars:
        genThing($_ , @_) for @$thing;
    } else {
        # Should just be a string:
        my  %flags  = @_;
        my  $indent = $flags{indent} || '';
        
        if ($flags{comment}) {
            $indent .= ' * ';
            $indent .= $flags{over} if $flags{over};
            $indent .= ' ';
        }
        
        return
            unless defined $thing;
        
        print $indent, $thing;
        print "\n"
            unless $thing =~ /\n$/;
    }
}

###########################################################################
###########################################################################

=item   C<image($self)>

Return image for item.

=cut

sub image      # $self
{
    $_[0]->{name} || '<|' . ref($_[0]) . '|>'
}

###########################################################################
###########################################################################

=item   C<itemSet($self, $which, $entity [ , $name ])>

Set a named item of the specified type (C<$which>).

=cut

sub itemSet     # $self, $which, $entity [ , $name ]
{
    my  $self   = shift;
    my  $which  = shift;
    my  $entity = shift;
    my  $name   = shift || $entity->{name};
    my  $orig   = $self->{which}->{lookup}->{$name};
    
#   print STDERR "itemSet($which, $entity, $name)\n";
    
    if ($orig) {
        warn "*** $which $name defined twice, using last definition\n";
        $self->{$which}->{order} =
            grep { $_ != $name } @{$self->{$which}->{order}};
    }
    
    push @{$self->{$which}->{order}}, $name;
    $self->{$which}->{lookup}->{$name} = $entity;
    
#   print STDERR "itemSet done\n";
    
    $orig || $entity
}

###########################################################################

=item   C<item($self, $which, $name)>

Return a named item of the specified type (C<$which>).

=cut

sub item        # $self, $which, $name
{
    $_[0]->{$_[1]}->{lookup}->{$_[2]}
}

###########################################################################

=item   C<items($self, $which)>

Returns all named items of a specified type.

=cut

sub items       # $self, $which
{
    map { $_[0]->{$_[1]}->{lookup}->{$_} } @{$_[0]->{$_[1]}->{order}}
}

###########################################################################
###########################################################################

=item   C<text($self [ , $which ])>

Returns array reference of array representing named text block.

Text blocks might include C<brief>, C<comment>, C<text>.
If no text block name (C<$which>) is specified, the default
C<'text'> block is used.

=cut

sub text        # $self [ , $which ]
{
    my  $self  = shift;
    my  $which = shift || 'text';
    
    $self->{text}->{$which}
}

###########################################################################

=item   C<textAppend($self, $which, @stuff)>

Appends stuff to the named text block.
If no text block name (C<$which>) is specified
(in which case C<undef> must be used as a placeholder),
the default C<'text'> block is used.

=cut

sub textAppend  # $self, $which, @stuff
{
    my  $self  = shift;
    my  $which = shift || 'text';
    
    push @{$self->{text}->{$which}}, @_
}

###########################################################################

=item   C<textPop($self, $which)>

Pops the last thing appended to the named text block.
If no text block name (C<$which>) is specified
the default C<'text'> block is used.

The opposite of textAppend().

=cut

sub textPop     # $self, $which
{
    my  $self  = shift;
    my  $which = shift || 'text';
    
    pop @{$self->{text}->{$which}}
}

###########################################################################

=item   C<textClear($self, $which, @stuff)>

Clears everything from the specified (C<$which>) text block,
leaving it empty.

Text blocks might include C<brief>, C<comment>, C<notes>.
If no text block name (C<$which>) is specified
(in which case C<undef> must be used as a placeholder),
the default C<'text'> block is used.

=cut

sub textClear   # $self, $which, @stuff
{
    my  $self  = shift;
    my  $which = shift || 'text';
    
    delete $self->{text}->{$which}
        if exists $self->{text}->{$which}
}

###########################################################################

=item   C<textString($self, $which)>

Returns text string with flattened (stringified) named text block.

Text blocks might include C<brief>, C<comment>, C<text>.
If no text block name (C<$which>) is specified, the default
C<'text'> block is used.

=cut

sub textString  # $self, $which
{
    my  $self  = shift;
    my  $which = shift || 'text';
    my  $this  = $self->{text}->{$which};
    
    isa($this, 'ARRAY') ? map { textThing() } @$this : textThing($this)
}

###########################################################################

=item   C<textThing($self, $which)>

Returns the text string for an item of unknown provenance.

Internal use.

=cut

sub textThing   # [ $this ]
{
    my  $this = shift || $_;
    
    can($this, 'textString') ? $this->textString :
    can($this, 'image')      ? $this->image      : $this || ''
}

###########################################################################
###########################################################################

=item   C<entities($self, $kind)>

Return all of the entities of a specific kind (e.g. classes, functions)
from this item and all items it contains.

sub entities    # $self, $kind
{
    my ($self, $kind) = @_;
    my  %result = ( );

    if (isa($self->{$kind}, 'ARRAY')) {
        $result{$_->{name}} = $_ for @{$self->{$kind}};
    } elsif (isa($self->{$kind}, 'HASH')) {
        $result{$_} = $self->{$kind}->{$_} for keys %{$self->{$kind}};
    }
    
#   for (@{$self->{brief}}, @{$self->{comment}}, @{$self->{notation}}) {
#       next unless isa $_, 'doxy::Item';
#       
#       $result{$_->{name}} = $_
#           for $_->entities($kind);
#   }

    # Fixed perl RLaager's email,   [2004/01/17]
    #   should have different values by command line argument,
    #   to support at least:
    #   - alphabetical behavior         [alpha]
    #   - "as ordered" in source file   [order]
    #   so $self->{_sort_}->{$kind} may be one of the two bracketed
    #   keywords (a string thereof).  Will add setting mechanism,
    #   but for now set to decent values in new().
#   %result = sort %result
#       if $self->{_sort_}->{$kind};
                             
    values %result
}

=cut

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl

=head1 AUTHOR

Marc M. Adkins, L<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
