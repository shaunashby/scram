#=| @note   This tests comments for files

package Doxygen::Perl::Filter;

=head1 NAME

Doxygen::Perl::Filter - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $filter = new Doxygen::Perl::Filter($path);

=head1 ABSTRACT

The basic Perl script filter, or parser.
Processes a Perl script or module looking
for subroutines and class inheritance.
Creates appropriate Doxygen::Item and subclass
objects to represent the file,
any package (class) defined within the file,
functions or methods defined in the file,
and other miscellaneous comments.
Stores the data on itself (single use only)
and generates Doxygen-parseable output as required.

=head1 DESCRIPTION

Some comments are ignored by BOD but can be used to push data straight
through to Doxygen, so use Doxygen markup symbology.
The comments are recognized by the comment pattern registered
with the Doxygen::Source package, defaulting to the constant
C<COMMENT> defined in this module.
    
Octothorpe bars:

    ##################################################################

Must have at least 64 octothorpes (not settable at this time).
Octothorpe bars may begin with any of the comment sequences,
in which case the total must contain no spaces and be at least
64 characters long.

Octothorpe bars are immune to Doxygen pass-through.  If you want to
pass one through, make it with a comment trigraph (as above) followed
by a space followed by whatever you want to pass through.
    
=head1 METHODS

=over

=cut

#=| @note   This tests comments for classes

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Carp;

# Test this pattern:
our     @ISA;
BEGIN   {
    push @ISA, qw(Doxygen::Filter);
}

use     Doxygen::Item::Class;
use     Doxygen::Item::Function;
use     Doxygen::POD::Filter;

our $VERSION = '0.01';

use     constant    COMMENT =>  qr(^\s*#(?:##(?!#)|=\|) ?(.*)$)m;

###########################################################################
###########################################################################

=item   C<new($class, %flags)>

Constructor for Doxygen::Perl::Filter objects.

=cut

### @param  %flags  flags to become object's fields

sub new
{
    Doxygen::Filter::new(@_)
}


###########################################################################
###########################################################################

=item   C<parse($self, \$text, $context)>

Parse a source file.

Attach results (Doxygen::Item objects) to Doxygen::Source object.

=cut

### \param  \$text      reference to text of entire file
### @param  $context    source object for parse,
###                     contains persistent data for parse

sub parse
{
    my ($self, $text, $context) = @_;
    
#   $context->log('T', __PACKAGE__, '::parse()');
    
    # First yank out all the nasty POD,
    #   which will be handled by a different filter:
    my  $copy = $$text; $text = \$copy; # must copy it or POD gone for good
    
    Doxygen::POD::Filter::CleanText($text);
    
    # Remove any __END__ and/or __DATA__ from the end:
    $$text =~ s/\n\s*__(?:END|DATA)__.*$//s;
    
    # Now count the lines:
    
    $self->{lines} = {
        blank   => 0,
        code    => 0,
        comment => 0,
        total   => 0
    };
    
    for (split(/\n/, $$text)) {
        $self->{lines}->{total}++;
        
        if (/^\s*#/) {          # comment line
            $self->{lines}->{comment}++;
        } elsif (! /\S/) {    # blank line
            $self->{lines}->{blank}++;
        } else {                # code line
            $self->{lines}->{code}++;
        }
    }
    
    # Paranoia runs deep...
    
    if ($$text =~ /\n=/) {
        $context->log('E', "POD still in 'cleaned' text in ",
                     __PACKAGE__, "::parse():\n", $$text);
        exit;
    }
    
    # Break up the source text by package (class):
    my  @chunks = split m%(?:^|(?<=[\n|;|\}]))                  \s*
                          package                               \s+
                          (\w+(?:::\w+)*)                       \s*
                          ;
                         %sx,
                  $$text;
    
#   $context->log('T', 'There are ', scalar(@chunks), ' class chunks');
    
    # Adjust chunks according to arcane rituals:
    
    my  $last1 = @chunks - 2;
    
    for (my $i = 0; $i < $last1; $i++) {
        # Is there comment data at the end of the previous block?
        if (my $block = EndBlock(\$chunks[$i])) {
            substr($chunks[$i+2], 0, 0, $block);
        }
    }
    
    # Parse the parts according to their predilections:
    
    $self->parseHeader(shift(@chunks), $context);
    
    $self->parseClass(splice(@chunks, 0, 2), $context)
        while @chunks > 1;
}

###########################################################################
###########################################################################

=item   C<parseClass($self, $class, $text, $context)>

Parse a section of source text beginning with a package declaration
and ending before the next package declaration (or end of file).

=cut

### @internal

sub parseClass  # $self, $class, $text, $context
{
    my ($self, $class, $text, $context) = @_;
    my  $item = new Doxygen::Item::Class(name => $class);
    
#   $context->log('T', __PACKAGE__, '::parseClass(', $class, ')');
    
    $context->focus->itemSet('class', $item, $class);
    $context->entityPush($item);
    
    eval {
#       $context->log('T', 'Parsing class ', $class)->pushLog;
        
        eval {
            $self->parseFuncs($text, $context);
        };
        
#       $context->popLog;

        die $@ if $@;
    };
    
    $context->entityPop($item);
        
    die $@ if $@;
}

###########################################################################
###########################################################################

=item   C<parseFunc($self, $function, $text, $context)>

Parse a section of source text beginning with a subroutine
declaration and ending before the next subroutine declaration
(or end of file).

=cut

### @internal

sub parseFunc
{
    my ($self, $function, $text, $context) = @_;
    my  %flags  = ( name => $function);
    my  $entity = $context->entity;
    
    $flags{class} = $entity
        if isa $entity, 'Doxygen::Item::Class';
    
    my  $item = new Doxygen::Item::Function(%flags);
    
    $entity->itemSet('function', $item, $function);
    $context->entityPush($item);
    
    eval {  # Parse text associated with function:
#       $context->log('T', 'Parsing sub ', $function, "()\n")->pushLog;
        
        eval {
#           Took this out for the moment,
#             it seems to pick up ### comments passing @param
#             through to Doxygen...
#           $item->arguments($1) if $text =~ /^[#\s]*(\\?[\$\@\%]\w.*?)\n/s;
            $self->parseCmnts(\$text, $context);
        };
        
        $context->popLog;
        
        die $@ if $@;
    };
    
    $context->entityPop($item);
    
    die $@ if $@;
}

###########################################################################
###########################################################################

=item   C<parseFuncs($self, $text, $context)>

Parse text associated with file or class.

Break out functions and act appropriately.

=cut

sub parseFuncs
{
    my ($self, $text, $context) = @_;
    
    # Break up the source text by function declaration:
    my  @chunks = split /(?:^|(?<=[\n|;|\}]))\s*sub\s+(\w+)\s*/s, $text;

    # Adjust chunks according to arcane rituals:

    my  $last1 = @chunks - 2;

    for (my $i = 0; $i < $last1; $i++) {
        # Is there comment data at the end of the previous block?
        if (my $block = EndBlock(\$chunks[$i])) {
            substr($chunks[$i+2], 0, 0, $block);
        }
    }

    # Parse the parts according to their predilections:

    $self->parsePlain(shift(@chunks), $context);

    $self->parseFunc(splice(@chunks, 0, 2), $context)
        while @chunks > 1;
}

###########################################################################
###########################################################################

=item   C<parseHeader($self, $text, $context)>

Parse a section of source text containing no package declarations.

=cut

### @internal

sub parseHeader  # $self, $text, $context
{
    my  $self = shift;
    
    $self->parseFuncs(@_)
}

###########################################################################
###########################################################################

=item   C<parsePlain($self, $text, $context)>

Parse a section of source text containing no package or
function declarations.

### @internal

=cut

sub parsePlain  # $self, $text, $context
{
    my ($self, $text, $context) = @_;
    my  $entity = $context->entity;
    
#   $context->log('T', 'parsePlain(', $context, ' [', $entity, '] )');
#   $context->log('T', $text);
    
    $entity->textAppend('notes', "\@version $1\n")
        if $text
        && $text =~ /\n\s*(?:(?:our|my)\s*)?\$VERSION\s*=\s*(.+?)\s*;/s;
    
    if (isa($entity, 'Doxygen::Item::Class')) {
#       $context->log('T', 'Look for class inheritance:');
        
        #   @ISA = qw(  <class>  {    <class>  }* )
        #   @ISA =   ( '<class>' { , '<class>' }* )
        #   @ISA =     '<class>' { , '<class>' }*
        $self->parseAnc_x(1, $context, split /\@ISA\s*=\s*/s, $text);
        
        #   use base qw(  <class>  {    <class>  }* )
        #   use base   ( '<class>' { , '<class>' }* )
        #   use base     '<class>' { , '<class>' }*
        $self->parseAnc_x(2, $context, split /\buse\s+base\s+/s, $text);

        #   push   @INC, qw(  <class>  {   <class> } )
        #   push   @INC,   ( '<class>' { , <class> } )
        #   push   @INC,     '<class>' { , <class> } )
        #   push ( @INC, qw(  <class>  {   <class> } ) )
        #   push ( @INC,   ( '<class>' { , <class> } ) )
        #   push ( @INC,     '<class>' { , <class> }   )
        $self->parseAnc_x
            (3, $context,
             split /(?:push|unshift)\s*(?:\(\s*)?\@ISA\s*,\s*/s, $text);
    }

    $self->parseCmnts(\$text, $context);
}

###########################################################################
###########################################################################

=item   C<parseAnc_x($self, $which, $context, @chunks)>

Parse a set of chunks from breaking out ancestor declarations.

=cut

### @internal

sub parseAnc_x  # $self, $which, $context, @chunks
{
    return
        unless @_ > 4;
    
    my ($self, $which, $context) = splice @_, 0, 4;
    
#   $context->log('T', 'parseAnc_x(', $which, ', ', scalar(@_), ') ');
    
    $self->parseAnc_s($which, $context, $_)
        for @_;
}

###########################################################################

=item   C<parseAnc_s($self, $context, $ancestors)>

Parse a list of ancestors from C<@ISA> or C<use base>.

=cut

### @internal

sub parseAnc_s  # $self, $context, $ancestors
{
    my ($self, $which, $context, $ancestors) = @_;
    my  @ancs = ( );
    
    unless ($ancestors && $ancestors =~ /\S/s) {
        $context->log('W', 'Null ancestor in ', __PACKAGE__, '::parseAnc_s()');
        return;
    }
    
#   $context->log('T', 'parseAnc_s(', $which, ', ', substr($ancestors, 0, 127), ') ');
    
    if ($ancestors =~ /^\s*qw\(\s*([^\)]*?)\s*\)/s) {
        # qw( <class> { <class> } )
        @ancs = split /\s+/s, $1;
    } else {
        $ancestors = $1
            if $ancestors =~ /^\s*\(\s*([^\)]*?)\s*\)/s;
        
        
        if ($ancestors =~ s/^\s*([\'\"])(.*?)\1//s) {
            push @ancs, $2;
            push @ancs, $2
                while $ancestors =~ /^\s*,\s*([\'\"])(.*?)\1/gs;
        }
    }
    
    my  $entity = $context->entity;
    
    undef $entity
        unless isa $entity, 'Doxygen::Item::Class';
    
    for my $include (@ancs) {
        next
            unless $include
                && $include =~ /\S/;
        
#       $context->log('+', '  ', $$include);
        
        $entity->ancestor($include)
            if $entity;
        
        $include  =~ s|::|/|g;
        $include .= '.pm'
            unless $include =~ /\.[^\.]+$/;
                
        $context->getFile->Include($include);
    }
    
}

###########################################################################
###########################################################################

=item   C<EndBlock(\$text)>

Peels a last block of comments from a referenced chunk of text.

Defined essentially as one or more octothorpe separator bars followed
by nothing but 'special' DoxyFilt comment lines (or blank lines)
to the end of the text block:

    #########################################################
    #########################################################
    #
    #   Some comment text...
    #
    =EOT=

Remove the text block if it is found, otherwise undef.

=cut

### @internal

sub EndBlock    # \$text
{
    my  $text = shift;
    my  $good = undef;
    my  @text = split /\n+/, $$text;
    my  @rslt = ( );
    
    while (my $line = pop(@text)) {
        unless ($line || $line =~ /\S/) {
            # Track the blank lines in case we find something good,
            #   but they're not sufficient in themselves:
            unshift @rslt, $line, 
            next;
        }
        
        if ($line =~ /^\s*#/) {
            # Comments should re-attach down in case
            #   they're special Doxygen comments:
            $good++ if $line =~ /\S/;
            unshift @rslt, $line;
            next;
        }
        
        # At this point we're dealing with a code line
        #   (it's not blank and it's not a comment, eh?)
        #   so the search is done:
        
        push @text, $line;  # don't lose last line!
        last;
    }
    
    if ($good) {
        # Found something we think should go down to the next block:
        $$text = join "\n", @text;
        return   join "\n", @rslt, '';
    }
    
    undef
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
