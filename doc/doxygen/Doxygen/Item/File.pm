package Doxygen::Item::File;

=head1 NAME

Doxygen::Item::File - Input file to Doxygen and its comments and contents.

=head1 SYNOPSIS

    my  $cls = new Doxygen::Item::File;

=head1 ABSTRACT

A Doxygen::Item::File object represents an imaginary C/C++
source file for processing by the Doxygen documentation system.
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

use     base qw(Doxygen::Item);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<generate($self [ , $indent ])>

Generate Doxygen comments to specify the name of the current file
and any file-level comments.

=cut

sub generate    # $self, %flags
{
    my  $self = shift;
    
    print "/**\n";
    print " * \\file $self->{path}\n";
    print " *\n";
    $self->genComment(@_);
    print " */\n\n";
    
    my  $macro = $self->{path};
    
    $macro =~ s|^.*:[/\\]||;
    $macro =~ s|\W|_|g;
    
    print "#ifndef $macro\n";
    print "#define $macro\n\n";
    
    if (isa($self->{includes}, 'ARRAY')) {
        print "#include <$_>\n"
            for @{$self->{includes}};
    }
    
    print "\n";

    my  $result = $self->SUPER::generate(@_);
    
    print "\n#endif\n\n";
    
    if (my $pages = $self->text('pages')) {
        if (isa($pages, 'ARRAY')) {
            for (@$pages) {
                Doxygen::Item::genThing("/**\n", @_);
                Doxygen::Item::genThing
                    ($_, @_, comment => 1, which => 'comment');
                Doxygen::Item::genThing(" */\n", @_);
            }
        } else {
            warn "*** pages items for $self not an array reference\n";
        }
    }
}

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Make sure there is a brief message for the file,
stealing it from a class if there is one.

=cut

sub massage     # $self, $context
{
    my ($self, $context) = @_;
    
#   $context->log('T', __PACKAGE__, '::massage(', $context, ')');
    
    return
        if $self->text('brief');
    
    my  @classes = $self->items('class');
    
    return
        unless @classes;
    
    my  $brief = undef;
    my  $clhdr = undef;
    
    for (@classes) {
        $_->massage($context);
        
        $self->textAppend('comment', <<CLASSHDR) unless $clhdr++;

<h2 class='POD_head2'>Classes</h2>
<ul>
CLASSHDR
        
        $self->textAppend('comment', "<li>$_->{name}\n");
        
        next
            if $brief;
        
        undef $brief
            if ($brief = $_->text('brief'))
            && ! isa $brief, 'ARRAY';
        
        next
            if $brief;
        
        my  $cmnts = $_->text('comment');
        
        next
            unless $cmnts
                && isa($cmnts, 'ARRAY')
                && @$cmnts;

        undef $brief
            if ($brief = $cmnts->[0])
            && ! isa $brief, 'ARRAY';
    }
    
    $self->textAppend('comment', "</ul>\n")
        if $clhdr;
    
    $self->textAppend('brief', @$brief)
        if ! isa($self->text('brief'), 'ARRAY')
        && isa $brief, 'ARRAY';
}

###########################################################################
###########################################################################

=item   C<Include($self)>

Add one or more 'include' file(s).

=cut

sub Include     # $self, @include
{
    my  $self = shift;
    
#   print STDERR __PACKAGE__, "::Include(", join(', ', @_), ")\n";
    
    push @{$self->{includes}}, @_
}

###########################################################################

=item   C<Includes($self)>

Return pointer to array reference of 'include' files.

=cut

sub Includes    # $self
{
    my  $self = shift;
    
    $self->{includes}
}

###########################################################################
###########################################################################

=item   C<focus($self)>

Return the focus for the file.

If there are classes, the first class is the focus.
Otherwise the focus is the file itself.

=cut

sub focus
{
    my  $self    = shift;
    my  @classes = $self->items('class');
    
    @classes ? $classes[0] : $self
}

###########################################################################
###########################################################################

# [EX-FOOTER]

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl, Doxygen::Item, Doxygen::Filter

=head1 AUTHOR

Marc M. Adkins, L<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=begin  doxygen

@page   filePOD File-level POD Usage

This page describes the way we tend to document our Perl files.

Most of what we do begins with copying two sections of an existing
file to the new file we're generating.
Sometimes we copy an entire file and gut it,
or rename all the functions,
but the general approach is the same.

We'll use the source file for Doxygen::Item::File as our example.

@dontinclude    Item/File/File.pm

@section header File Header

The top of the file, the file's header, looks like:

@until  $VERSION

We begin with the package declaration.
If we place any POD or doxygen comments before the package declaration
it will be attached to the file as a whole, which isn't usually useful.
After the package declaration we place the POD for the module.

Note that at the end we define a <tt>=head1</tt> named
<tt>METHODS</tt>, then an <tt>=over</tt>, then the <tt>=cut</tt>.
This specific sequence is intended to work with POD as well as Doxygen.
When processed by a normal POD tool the it generates a section,
<tt>METHODS</tt>, which has items for each function.
Using Doxygen and DoxyFilt the entire section (because of its
specific name) is removed in favor of the Doxygen table of contents.

After the package's POD we specify the normal beginning of the package
source, <tt>use</tt> statements and so forth.
Then comes the bulk of the source code.

@section header File Footer

At the bottom of the file, the file's footer, we place:

@skip   [EX-FOOTER]
@skip   1
@until  =cut

The <tt>1</tt> is the return value for the package.
Otherwise it won't compile properly.

After that we use an <tt>__END__</tt> to break off compilation.
This isn't strictly necessary because we're going to write more POD
on the end, but it doesn't hurt either, and we just copy this stuff
around so it doesn't much matter.

The first piece of POD is the <tt>=back</tt> line.
Remember the way we ended the header with <tt>=over</tt>
even though we had just started the <tt>METHODS</tt> heading?
Well, now that we've defined all of our functions or methods,
it's time to end that list.

Then we dump in whatever boilerplate we like at the end of each page.
This varies from project to project.

=end    doxygen
