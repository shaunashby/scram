package Doxygen::Filter;

=head1 NAME

Doxygen::Filter - Base class for Doxygen filter classes.

=head1 SYNOPSIS

Inherited by subclass:

    use base qw(Doxygen::Filter);

Used in DoxyFilt.pl:

=head1 ABSTRACT

Provides a root class for a source filter for the Doxygen documentation tool.
This class should be inherited by source-specific subclasses, which will in
turn be used by the DoxyFilt.pl script, called by the Doxygen program to
process source files other than C and C++.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Carp;

use     Doxygen::Item::Class;
#se     Doxygen::Item::File;

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<new($class, %fields)>

Constructor for Doxygen::Filter objects.

Collects the C<%fields> as a hash and blesses a
reference there, making it easy to set up
initial field values.

=cut

#=| @param  %flags  Flags used in object creation

sub new
{
    my ($class, %fields) = @_;
    
    bless \%fields, $class
}

###########################################################################
###########################################################################

=item   C<parse($text, $target)>

Parse source text.

Pick out whatever is important for the language or source type.
Collect information on Doxygen::Filter object passed in as the
C<$filter> argument.

Returns true if parsing was successful, otherwise undef or die.

=cut

#=| \param  $text       text of entire file, passed by value
#=|                     so it is copied and can be mutilated
#=|                     as necessary by the filter
#=| \param  \$target    target object for parsing results,
#=|                     which are Doxygen::Item instances

sub parse       # $self, $text, $target
{
    carp ref($_[0]), "::parse not yet implemented\n";
    
    undef
}

###########################################################################
###########################################################################

=item   C<parseCmnts($self, $text, $context)>

Parse comments from a source file.

Attach results (C<Doxygen::Item> objects) to C<Doxygen::Context> object.

=cut

sub parseCmnts
{
    my ($self, $text, $context) = @_;
    
#   $context->log('T', 'parseCmnts(', $text, ', ', $context, ')');
    
    if (my $comment = $self->{comment}) {
#       $context->log('T', 'cmnt: ', $comment);
        
        my  $data = ref($text) ? $text : \$text;
        
        return
            unless $data
                && $$data;
        
#       $context->log('T', $data, '/', $$data);
        
        my  $pattern = $comment;
        
        if (isa($pattern, 'ARRAY')) {
            $context->log('W', 'Not handling multiple patterns at this time');
            return;
        }

        while ($$data =~ /$pattern/g) {
            $context->entity->textAppend('notes', "$1\n")
                if defined $1;
        }
    }
}

###########################################################################
###########################################################################

=item   C<massage($self)>

Massage items in file after parsing and before generating.

Each filter may have a C<massage> method and/or a C<parse> method.
The order of parsing and massaging is undefined except that
I<all> parsing will complete prior to I<any> massaging being done.

This method is the default and therefore does nothing.

=cut

sub massage     # $self
{
}

###########################################################################
###########################################################################

=item   C<coding($self, @text)>

Queue up a line of code to be shown in a box.

Lines of code are collected prior to output.
This method collects then,
the codeFlush() method flushes them as output for doxygen.

=cut

#=| \param  @text  Lines of code to be queued.

sub coding      # $self, @text
{
    my  $self = shift;
    
    push @{$self->{code}}, @_
}

###########################################################################

=item   C<codeFlush($self)>

Flush all pending code lines.

Code lines are collected via the coding() method.
This method is called to flush the collected lines
in a marked block and clear the collection mechanism.

=cut

sub codeFlush   # $self
{
    my  $self = shift;
    
    return
        unless isa($self->{code}, 'ARRAY')
            && @{$self->{code}};
    
    $self->focus->comment("\\code");
    
    my  @blank = ( );
    
    for (@{$self->{code}}) {
        if (/\S/) {
            $self->focus->comment(@blank, $_);
            @blank = ( );
        } else {
            push @blank, $_;
        }
    }
    
    $self->focus->comment("\\endcode");
    $self->focus->comment(@blank);
    
    delete $self->{code};
}

###########################################################################
###########################################################################

=item   C<flags($self)>

Return reference to flags hash for filter.

In general these will be flag default values, and could be
set as a class method.
However, it is easier to code this as an instance method,
and may lend itself to other weirdness later on that account.

The default version returns an empty hash reference.
Filters intending to use this must overload it.

=cut

sub flags
{
    { }
}

###########################################################################
###########################################################################

=item   C<focus($self)>

Return the current focus for adding comment lines.

Defaults to the value for the current source entity,
but may be overridden by descendant classes modelling
language-specific documentation entities.

=cut

#=| \return A Doxygen::Item object.

sub focus        # $self
{
    $_[0]->entity
}

###########################################################################
###########################################################################

=item   C<statistics($self, $context)>

Show simple statistics where available.

=cut

sub statistics
{
    my ($self, $context) = @_;
    my  $class = ref $self;
    my  $found = 0;
    
    $class =~ s|^Doxygen::(.*)::Filter$|$1|;
    
    if (isa($self->{lines}, 'HASH')) {
        $context->log('.', join(' ', $class,
                                    map {
                                        "$_($self->{lines}->{$_})"
                                    } sort keys %{$self->{lines}}));
        $found = 1;
    }
    
    $found
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl

=head1 AUTHOR

Marc M. Adkins, F<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
