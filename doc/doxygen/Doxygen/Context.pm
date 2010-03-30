package Doxygen::Context;

=head1 NAME

Doxygen::Context - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $context = new Doxygen::Context($path);
    
    $context->generate;

=head1 ABSTRACT

Represents a filter context for a single source file to be
filtered for inclusion into a Doxygen job.

A newly created instance requires a pathname, from which text is read.
Zero or more filters will be passed against the source text,
storing interim state (Doxygen::Item objects) on the Context object.

This handles situations where filters must cooperate.  Other situations,
where filters need not share data, can be handled by creating a shell
script that calls multiple top-level filter scripts.

When the parsing is complete, use the object to generate Doxygen-enabled
output.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Doxygen::Item::File;

use     base    qw(Doxygen::Item);

our $VERSION = '0.01';

our %loaded = ( );

###########################################################################
###########################################################################

=item   C<new($class, %flags)>

Constructor for Doxygen::Context objects.

Useful flags:

=over

=item   C<flag>

Hash reference to flags to use for filters.
Each key may be of the form C<I<filter>::I<name>>
for a filter-specific flag or C<I<name>> for a
global flag to be applied to all filters.

=item   C<info>

If set to false will turn I<off> the
generation of 'informational' ([I])
log messages.

=item   C<trace>

Turns on generation of tracing ([T]) and hacking
([H]) messages.

=item   C<filter>

Array reference to list of filter filters to apply.

=back

=cut

sub new
{
    my ($class, %flags) = @_;
    
    bless \%flags, $class
}
    
###########################################################################

sub DESTROY     # $self
{
    $_[0]->popLog;
}

###########################################################################
###########################################################################

=item   C<parse($self, $path)>

Parse the specified source file.

Applies all appropriate filters the the source file.
Each parser is able to store information on itself
or this C<Doxygen::Source> object.

=cut

sub parse
{
    my  $self = shift;
    my  $path = shift;
    
#   $self->log('T', __PACKAGE__, '::parse()');
    
    unless (isa($self->{filter}, 'ARRAY') && @{$self->{filter}}) {
        $self->log('E', 'No filters to apply!');
        return undef;
    }
    
    unless ($path && -f $path) {
        $self->log('E', 'No viable source path to be parsed!',
                   ($path ? "\n  $path" : ''));
        return undef;
    }
    
    unless (-r $path) {
        $self->log('E', "Source path is read-only!\n  $path");
        return undef;
    }
    
    # Create the file object immediately:
    local   $/ = undef; # slurp file

    unless (open(SOURCE, '<', $path)) {
        $self->log('E', "Unable to open source file:\n    $path\n  $!\n");
        return undef;
    }

    my  $text = <SOURCE>;
    
    close SOURCE;
    
    unless ($text && $text =~ /\S/) {
        $self->log('E', "Empty source file:\n    $path\n");
        return undef;
    }
    
    my  $lines = 0;
    
    $lines++
        while $text =~ /\n/gs;
    
    # OK, the file exists,
    #   create the first entity to represent the file:
    
    local   $SIG{__WARN__} = sub {  $self->_warning_(shift) };

    $self->log('I', "File:  $path\n")->pushLog;
    
    my  $found = 0;
        
    eval {
#       $self->log('T', 'Parse filters');
            
        $self->{entity} = [ $self->getFile($path) ];
        
#       $self->log('T', 'File:  ', $self->getFile);

        # Check for all kinds of parsers that might match the document:
        
        for my $type (@{$self->{filter}}) {
#           $self->log('T', "Filter $type")->pushLog;
            
            eval {
                # Safely create a filter for that document filter:
                my  $class = "Doxygen::${type}::Filter";
                
                unless ($loaded{$type}) {
                    return undef    # previous failure to load filter
                        if defined $loaded{$type};
                    
                    $loaded{$type} = eval "require $class";
                        
                    unless ($loaded{$type} && ! $@) {
                        $self->log('E', "Unable to load class $class",
                                   ($@ ? ( "\n  $@" ) : ( )));
                        $loaded{$type} = 0;
                        return undef;
                    }
                }
                
                # Create appropriate flags for new filter:
                my  %flags  = ( path => $path );
                
                if (isa($self->{flag}, 'HASH')) {
                    for my $flag (keys %{$self->{flag}}) {
                        $flags{$flag} = _flagValue_($self->{flag}->{$flag})
                            unless $flag =~ /:+/;
                    }
                    
                    for my $flag (keys %{$self->{flag}}) {
                        $flags{$1} = _flagValue_($self->{flag}->{$flag})
                            if     $flag =~ /^${type}:+(.*)$/;
                    }
                }

#               $self->log('T', 'Flags passed in:')->pushLog;
#               $self->log('+', $_, ' => ', $self->{flag}->{$_}) for keys %{$self->{flag}};
#               $self->popLog;
                
#               $self->log('T', 'Flags for filter:')->pushLog;
#               $self->log('+', $_, ' => ', $flags{$_}) for keys %flags;
#               $self->popLog;
                
                my  $filter = $class->new(%flags);
                
                unless (isa($filter, 'Doxygen::Filter')) {
                    $self->log('E', "Unable to allocate $type filter:\n  $!");
                    return undef;
                }
                
                # Parse file with the filter for this document type:
                $filter->parse(\$text, $self);
                $found = 1 if $filter->statistics($self);
                $self->{_filters_}->{$type} = $filter;
            };

            $@ && $self->log
                    ('E', "Error parsing $type document:\n    $path\n  $@");
            
#           $self->popLog;
        }
        
        unless (keys %{$self->{_filters_}}) {
            ($path =~ $_ && return undef)
                for @{$self->{_filters_}->{pass}};
            
            $self->log('W', "Don\'t know how to filter document:\n    $path\n");
            
            return undef
        }
    };
    
#   $self->log('T', 'Found ', $found, ' filters');

    die $@ if $@;
    
    $self->log('.', 'Source total(', $lines, ')')
        if $found;
    
    $self
}

###########################################################################
###########################################################################

=item   C<massage($self)>

Massage items in file after parsing and before generating.

Each filter may have a C<massage> method and/or a C<parse> method.
The order of parsing and massaging is undefined except that
I<all> parsing will complete prior to I<any> massaging being done.

For the C<Source> object, C<massage> must iterate through the
set of filters created during the C<parse> phase and call the
C<massage> method on each one.

=cut

sub massage
{
    my  $self = shift;
    
    return if $self->{spawned};
    
    local   $SIG{__WARN__} = sub {  $self->_warning_(shift) };
    
    # Massage all of the filters:
    for my $filter (values %{$self->{_filters_}}) {
#       $self->log('T', "Filter $filter");
        $filter->massage($self);
    }
    
    # Massage the file:
    $self->getFile->massage($self);
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

Prior to generation, invokes the massage() function to do preparatory
manipulation of objects.

Must be overloaded by derived subclasses.

=cut

sub generate
{
    my  $self = shift;
    
    return if $self->{spawned};
    
    local   $SIG{__WARN__} = sub {  $self->_warning_(shift) };
    
    $self->getFile->generate(@_, source => $self);
    $self->SUPER::generate  (@_, source => $self);
}

###########################################################################
###########################################################################

=item   C<entity($self)>

Return the top node from the entity stack.

The entity stack is for source entities.
The stack always starts with a Doxygen::Item::File object to
represent the file being parsed.
Other objects that may be placed on the stack :

<ul>
<li>Doxygen::Item::Class
<li>Doxygen::Item::Function
</ul>

In general a file object will be on the bottom,
then a class object (if applicable) and finally
a function object.

=cut

sub entity
{
    $_[0]->{entity}->[0]
}

###########################################################################

=item   C<entityPop($self [ , $entity ] )>

Pop the top entity from the entity stack.

If the C<$entity> argument is defined,
pop all entities down to and including that specified.

=cut

sub entityPop    # $self [ , $entity ]
{
    my ($self, $entity) = @_;
    
    if ($entity) {
        while (my $popped = shift @{$self->{entity}}) {
            last if $popped == $entity;
        }
    } else {
        shift @{$self->{entity}};
    }
}

###########################################################################

=item   C<entityPush($self, $entity)>

Push a new current entity on the stack.

The stack starts with just the file object.

=cut

#=| \param  $entity The entity to be pushed onto the stack.

sub entityPush   # $self, $entity
{
    my  $self = shift;
    
    unshift @{$self->{entity}}, shift
}

###########################################################################
###########################################################################

=item   C<flag($self, $name [ , $filter ])>

Return value of named flag in source context.

Flags are specified at source creation.
Flags are named either C<I<filter>::I<flagName>> or C<I<flagName>>.
The former describe flags specific to document filters
and only visible to filters of the specified document type.
In addition, the former, where applicable, override the latter.
The latter are global to all filters and act as global flags
and/or default values for specific flags.

When a flag is requested by name, if a C<$filter>
is specified it will be used to check for a filter-specific
value first, then for the global value.
The argument should be either the name of a filter class
or an object of a filter class.

The C<$name> argument should never specify names
of the form C<I<filter>::I<flagName>>, as that is specified
via the optional C<$filter> parameter.

=cut

sub flag
{
    my ($self, $name, $filter) = @_;
    
#   $self->log('T', __PACKAGE__, '::flag(', $name, ', ', $filter, ')');
    
    if ($filter && isa($filter, 'Doxygen::Filter')) {
        my  $filtype = ref($filter) || $filter;
        
#       $self->log('T', 'fTyp:  ', $filType);
        
        if ($filtype =~ /Doxygen::(.*)::Filter/) {
            my  $name = "$1::$name";
            
#           $self->log('T', 'name:  ', $name);

            return $self->{flag}->{$name}
                if exists $self->{flag}->{$name};
        }
        
        if (ref($filter)) {
            my  $flag = $filter->flags;
            
#           $self->log('T', 'flag:  ', $flag);
#           $self->log('T', '  ', $_, ' => ', $flag->{$_}) for keys %$flag;
#           $self->log('T', 'valu:  ', $flag->{$name});
            
            return $flag->{$name}
                if exists $flag->{$name};
        }
    }
    
#   $self->log('T', 'valu=  ', $self->{filter}->{flag}->{$name});
    
    $self->{flag}->{$name}
}

###########################################################################
###########################################################################

=item   C<focus($self)>

Return the current focus for adding comment lines.

Defaults to the value for the current source entity,
but may be overridden by descendant classes modelling
language-specific documentation entities.

=cut

#=| \return A doxy::Item object.

sub focus
{
    $_[0]->entity
}

###########################################################################
###########################################################################

=item   C<getFile($self [ , $path ] )>

Get file object for this filter object,
creating object if necessary.

    my  $file = $target->getFile($path);

The file object should be created early using the path so that it can
be referred to freely without the pathname later:

    $doc->file->append($text);

=cut

sub getFile
{
    my  $self = shift;
    
    unless (isa($self->{file}, 'Doxygen::Item::File')) {
        my  $path = shift;
        
        return
            unless $path
                && $path =~ /\S/;

        # This makes Doxygen::Test work,
        #   but it could be considered non-optimal
        #   (then again, why would we ever need it otherwise?):
        $path =~ s|\.\./||g;

        $self->{file} = new Doxygen::Item::File(path => $path);
        
#       $self->log('T', 'File path:  ', $self->{file}->{path});
    }
    
    $self->{file}
}

###########################################################################
###########################################################################

=item   C<log($self, $code, @stuff)>

Formatted logging function.

The C<$code> is a single-character from the following set:

=over

=item   I

Info

=item   T

Trace

=item   W

Warning

=item   E

Error

=back

=cut

sub log
{
    my  $self = shift;
    my  $code = shift || 'T';
    
    return $self    # hacking and tracing messages default off
        if ($code eq 'H' || $code eq 'T')
        && ! $self->{trace};
    
    return $self    # information messages default on
        if $code eq 'I'
        && exists $self->{info}
        && ! $self->{info};
    
    my  $indent = isa($self->{logIndent}, 'ARRAY') && @{$self->{logIndent}}
                ? $self->{logIndent}->[0]
                : '';
    
    for (split(/\n/, join('', map {
                defined($_) ? $_ : '<undef>'
            } @_, "\n"))) {
        print STDERR "[$code]$indent $_\n";
        $code = '+' unless $code eq '+';
    }
    
    $self
}

###########################################################################

=item   C<popLog($self)>

Pop the last indentation level from the logging stream.

=cut

sub popLog      # $self
{
    my  $self = shift;
    
    shift @{$self->{logIndent}}
        if isa($self->{logIndent}, 'ARRAY')
        && @{$self->{logIndent}};
    
    $self
}

###########################################################################

=item   C<pushLog($self [ , $spaces ] )>

Indent the logging functionality accessible via log().

Specify the C<$spaces> (as the actual indentation string) or it defaults to 2.

=cut

sub pushLog     # $self [ , $spaces ]
{
    my  $self = shift;
    
    $self->{logIndent} = [ ]
        unless isa $self->{logIndent}, 'ARRAY';
    
    unshift @{$self->{logIndent}},
            ((@{$self->{logIndent}} ? $self->{logIndent}->[0] : '')
             . (shift || '  '));
    
    $self
}

###########################################################################

=item   C<_warning_($self, $stuff)>

Special logging call used for trapping warnings.

Breaks up standard warning text so it doesn't overwrite lines in log.

=cut

#=| @internal

sub _warning_
{
    my ($self, $stuff) = @_;
    
    $stuff =~ s/\b(at\s+[\w\.\\\/]+\s*line\s+\d+)/\n $1/;
    
    $self->log('W', $stuff)
}

###########################################################################
###########################################################################

=item   C<_commentPattern_($string)>

Convert a string into a pattern for recognizing a comment.

=cut

#=| @todo   handle qr()im flags

sub _commentPattern_
{
    isa($_[0], 'Regexp')    ? $_[0]  :
    $_[0] =~ /^qr\((.*)\)$/ ? qr($1) : qr(^\s*$_[0] ?(.*)$)m
}

###########################################################################

=item   C<_filterPattern_($string)>

Convert a string into a pattern for recognizing a comment.

=cut

#=| @todo   handle qr()im flags

sub _filterPattern_
{
    isa($_[0], 'Regexp')    ? $_[0]  :
    $_[0] =~ /^qr\((.*)\)$/ ? qr($1) : qr(^$1)
}

###########################################################################

=item   C<_flagValue_($string)>

Evaluate a string (or pattern) representing a flag value.

=cut

#=| @todo   handle qr()im flags

sub _flagValue_
{
    my  $string = shift;
    
    $string = shift
        if isa $string, __PACKAGE__;
    
    return $string
        if isa $string, 'Regexp';
    
    return qr($1)i
        if $string =~ /^qr\((.*)\)i$/;
    
    return qr($1)
        if $string =~ /^qr\((.*)\)$/;
    
    $string
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
