#=| @note   This tests comments for files

package Doxygen::XSLT::Filter;

=head1 NAME

Doxygen::XSLT::Filter - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $filter = new Doxygen::XSLT::Filter($path);

=head1 ABSTRACT

The basic XSLT script filter, or parser.
Processes a XSLT script or module looking
for subroutines and class inheritance.
Creates appropriate Doxygen::Item and subclass
objects to represent the file,
any package (class) defined within the file,
functions or methods defined in the file,
and other miscellaneous comments.
Stores the data on itself (single use only)
and generates Doxygen-parseable output as required.

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Carp;
use     Cwd;
use     File::Basename;
use     File::Spec;
use     XML::Parser;

use     base qw(Doxygen::Filter);

use     Doxygen::XSLT::Class;
use     Doxygen::XSLT::Function;

our $VERSION = '0.01';

our $context;
our $self;
our %status;
our %nodeClass = (
    class       =>  'Doxygen::XSLT::Class',
    function    =>  'Doxygen::XSLT::Function'
);

###########################################################################
###########################################################################

=item   C<new($class, %fields)>

Constructor for Doxygen::XSLT::Filter objects.

Fields of note:

=over

=item   C<path>

The full pathname for the source file.
May be used to construct the class name.

=item   C<roots>

Array reference to list of root directories.
The longest matching root directory is removed
from the filename before converting it to the
class name for the file's style sheet in the
default case.

=back

=cut

### @param  %fields  flags to become object's fields

sub new
{
    Doxygen::Filter::new(@_)
}

###########################################################################
###########################################################################

=item   C<parse($self, $text, $context)>

Parse a source file.$filter

Attach results (Doxygen::Item objects) to Doxygen::Source object.

=cut

### \param  $text   reference to text of entire file
### @param  $context source object for parse,
###                 contains persistent data for parse

sub parse
{
    local   $self    = shift;
    my      $text    = shift;
    local   $context = shift;
    local   %status  = ( );
    
#   $context->log('T', __PACKAGE__, '::parse()');
    
    my  $prsr = new XML::Parser(Style => __PACKAGE__);
    
    unless (isa($prsr, 'XML::Parser')) {
        $context->log('E', 'Unable to allocate new XML::Parser object');
        return undef;
    }
    
    my  $result = undef;
    
#   $context->log('T', 'About to parse file')->pushLog;
    
    eval    {
        $result = $prsr->parse($$text);
    };
    
    if ($@) {
        $context->log('W', 'Error during XML parse')->pushLog;
        $context->log('+', $@)->popLog;
        $result = undef;
    }
    
#   $context->popLog;

    $result
}

###########################################################################

=item   C<className($self [ , $path ] )>

Return class name for style sheet.

Since style sheets don't have names, this will ordinarily
be constructed from the path name.

=cut

sub className
{
    my  $self = shift;
    my  $path = shift || $self->{path};
    
#   $context->log('T', 'className(', $path, ')');
    
    return '<noPath>'
        unless $path;
    
    $path = $self->_fixPath_($path);
    
    my  $name = $path;
    my  $nLen = 0;
    my  $root = isa($self->{root}, 'ARRAY') ?   $self->{root}   :
                $self->{root}               ? [ $self->{root} ] : [ ];

#   $context->log('T', 'Path: ', $path);
#   $context->log('T', 'Roots:');

    for (@$root) {
        my  $root = $self->_fixPath_($_);
        my  $tail = index $path, $root;
        
#       $context->log('+', '  ', $root);

        next
            if $tail;

        $tail = substr($path, length($root));
        $tail =~ s|^/+||;

        next
            unless length($root) > $nLen;

        $name = $tail;
        $nLen = length($root);
    }

#   $context->log('T', 'Name  is ', $name);
    
    $name =~ s|^/*|$self->{namespace}/|
        if $self->{namespace};
    
    $name =~ s|\.[^\.]*$||;
    $name =~ s|/+|::|g;
    
#   $context->log('T', 'Class is ', $name);
    
    fixName($name)
}

###########################################################################

sub _fixPath_
{
    my  $self = shift;
    my  $path = shift;
    
    unless (File::Spec->file_name_is_absolute($path)) {
        my  @base = ( );
        
        push @base, dirname($self->{path})
            if $self->{path};
        
        $path = File::Spec->rel2abs($path, @base);
    }
    
    $path =~ s!/[^/]+/\.\.(?=/|$)!!g;
    $path =~ s!/\.(?=/|$)!!g;
    File::Spec->canonpath($path)
}

###########################################################################
###########################################################################
###########################################################################

=item   C<Start($expat, $element, %attributes)>

Called when a start tag is found.

=cut

### @param  $parser     expat parser object during parse
### @param  $element    tag name
### @param  %attributes tag attributes

sub Start
{
    my  $xpat = shift;
    my ($tag, %attr) = @_;
    
#   $context->log('T', '<', $tag, '>');
    
    if ($tag eq 'xsl:stylesheet') {
        # <xsl:stylesheet
        my  $name = $self->className;
        my  $item = $nodeClass{class}->new(name => $name);

#       $context->log('T', 'Class:  ', $nodeClass{class});
#       $context->log('T', 'Class=  ', $item);
        $context->focus->itemSet('class', $item, $name);
        $context->entityPush($item);
#       $context->log('T', 'Parsing stylesheet ', $name)->pushLog;
#       $context->log('T', 'Class=  ', $item);
        $status{class} = $item;
    } elsif ($tag eq 'xsl:import') {
        # <xsl:import
        my  $name = $attr{href};
        
        unless ($name) {
            $context->log('W', 'No ancestor name in <xsl:import>');
        } elsif ($status{class}) {
#           $context->log('T', 'Class=  ', $status{class});
            $status{class}->xsl_import($self->className($name));
        } else {
            $context->log('W', 'No style sheet for <xsl:import>');
        }
    } elsif ($tag eq 'xsl:include') {
        # <xsl:include
        my  $name = $attr{href};
        
        unless ($name) {
            $context->log('W', 'No ancestor name in <xsl:include>');
        } elsif ($status{class}) {
            $status{class}->xsl_include($self->className($name));
        } else {
            $context->log('W', 'No style sheet for <xsl:include>');
        }
    } elsif ($tag eq 'xsl:template') {
        # <xsl:template
        unless ($attr{name}) {
            $context->log('T', 'Unnamed template');
        } elsif ($status{class}) {
            # This template is named, pretend it is a method:
            my  $item = $nodeClass{function}->new(name => fixName($attr{name}));

            $status{class}->itemSet('function', $item, $attr{name});
            $context->entityPush($item);
#           $context->log('T', 'Parsing template ', $attr{name})->pushLog;
            $status{function} = $item;
        } else {
            $context->log('W', 'No style sheet for named template');
        }
    } elsif ($tag eq 'xsl:param') {
        # <xsl:param
        my  $name = $attr{name};
        
        unless ($name) {
            $context->log('W', 'No name for <xsl:param>');
        } elsif ($status{function}) {
            $context->entity->arguments($name);
        } elsif ($status{class}) {
            $context->log('W', 'TBD:  style sheet <xsl:param>s');
        } else {
            $context->log('W', 'No style sheet or named template for <xsl:param>');
        }
    } elsif ($tag eq 'xsl:call-template') {
        # <xsl:call-template
        my  $name = fixName($attr{name});
        
        unless ($name) {
            $context->log('W', 'No name for <xsl:call-template>');
        } elsif ($status{function}) {
            $context->entity->references($name);
#           $context->log('T', 'Call template ', $attr{name});
        } else {
            $context->log('W', 'No named template for <xsl:call-template>');
        }
    }
}

###########################################################################

=item   C<End($expat, $element)>

Called when an end tag is found.

=cut

### @param  $parser     expat parser object during parse
### @param  $element    tag name

sub End
{
    my  $xpat = shift;
    my ($tag, %attr) = @_;
    
#   $context->log('T', '</', $tag, '>');
    
    if ($tag eq 'xsl:stylesheet') {
        # </xsl:stylesheet>
        if (defined $status{class}) {
            $context->entityPop($status{class});
#           $context->popLog;
            delete $status{class};
        } else {
            $context->log('W', 'No style sheet to pop in end tag');
        }
    } elsif ($tag eq 'xsl:template') {
        # </xsl:template>
        if (defined $status{function}) {
            $context->entityPop($status{function});
#           $context->popLog;
            delete $status{function};
#       } else {
#           may be naming unnamed template
        }
    }
}

###########################################################################

sub Comment
{
#   $context->log('T', __PACKAGE__, '::Comment()');
    
    my  $xpat = shift;
    my  $data = shift;
    
    return
        unless $data
            && $data =~ /\S/s;
    
    my  $which = undef;
    
#   $context->log('T', 'Flags:');
#   $context->log('+', $_, ' => ', $self->{$_})
#       for keys %$self;
    
    if ($data =~ /^\s*\*\s+(.*?)\s*$/s) {
        $data  = $1;
        $which = 'comment';
    } elsif ($self->{comments} && $self->{comments} =~ /^\s*all\s*$/i) {
        $which = 'notes';
    } else {
        return;
    }
    
    my  $item = $status{function}
             || $status{class}
             || $context->getFile;
    
    $which = 'brief'
        if $which eq 'comment'
        && ! $item->text($which);
    
    $item->textAppend($which, "$data\n");
}

###########################################################################
###########################################################################

sub fixName
{
    my  $name = shift;
    
    $name =~ s|[^/:\w]+|_|g;
    $name
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
