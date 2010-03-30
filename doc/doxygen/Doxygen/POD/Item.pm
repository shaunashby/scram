package Doxygen::POD::Item;

=head1 NAME

Doxygen::POD::Item - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $item = new Doxygen::POD::Item;

=head1 ABSTRACT

A simple item in a POD source file.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(can isa);

use     base    'Doxygen::Item';

our $VERSION = '0.01';

use     constant    HTML_CONVERT    =>  1;

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Convert all the comment text in this block from POD formatting
sequences into Doxygen formatting sequences.

=over

=item   filename

F<filename.txt>

=item   italics

I<italicized>

=item   boldface

B<boldface>

=item   fixed pitch

C<typewriter>

=item   special characters

Numeric characters 'E<49>', 'E<062>', 'EZ<><0x33>>'.
Named characters 'E<lt>', 'E<gt>', 'E<sol>',
'E<verbar>', 'E<amp>'.

=item   spaces

Non-breaking spacing:
S<good boys drink milk until it comes out of their ears>.

=item   null sequence

Dreaded 'Z' sequence:  BZ<><null>.

=item   links

L<simple>, L<more|complex>, L<to/section>,
L<more I<complex> yet|linkage>, L<text|/local>,
L<http://www.web.link/somewhere.htm>.

=back

=cut

sub massage     # $self, $context
{
    my ($self, $context) = @_;
    
    return unless isa $self->text('comment'), 'ARRAY';
    
    my  $text = '';
    my  @text = ( );
    
    $self->{name} = _doxify_($context, $self->{name})
        if $self->{name};
    
    for (@{$self->text('comment')}) {
        if (ref($_)) {
            if ($text) {
                $text = _doxify_($context, $text);
                push @text, map { "$_\n" } split /\n/, $text;
                $text = '';
            }
            
            $_->massage($context) if can $_, 'massage';
            
            push @text, $_;
        } else {
            $text .= $_;
        }
    }
    
    if ($text) {
        $text = _doxify_($context, $text);
        push @text, map { "$_\n" } split /\n/, $text;
    }
    
    $self->textClear('comment');
    $self->textAppend('comment', @text);
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate    # $self, %flags
{
    my ($self, %flags) = @_;
    my  $which = $flags{which} || 'text';
    
    return
        unless $self->text($which)
            || ($which ne 'text' &&
                $self->text($which = 'text'));

    unless (isa($self->text($which), 'ARRAY')) {
        warn "$which items for $self not an array reference\n";
        next;
    }

    $flags{which} = $which unless $flags{which};
    
    unless ($self->{name}) {
        # No name, not a list item
    } elsif ($flags{named}) {
        # This is part of a set of named definitions:
        Doxygen::Item::genThing("<dt>$self->{name}</dt><dd>\n",  %flags)
    } else {
        # Just a plain ole' list item:
        Doxygen::Item::genThing("<li>\n",  %flags)
    }
    
    # The goop inside the item:
    my  $first = 1;
    
    for (@{$self->text($which)}) {
        next
            if $first
            && ! ref($_)
            && ! ($_ && $_ =~ /\S/);
        
        Doxygen::Item::genThing($_, %flags);
        undef $first;
    }
    
    # Terminate definition if necessary:
    Doxygen::Item::genThing("</dd>\n",  %flags)
        if $self->{name}
        && $flags{named};
}

###########################################################################
###########################################################################

=item   C<_doxify_($context, $text)>

Convert POD escape sequences to HTML escape sequences.

Also protects Doxygen escape sequences.

=cut

sub _doxify_
{
    my ($context, $text) = @_;
    my  $result = '';
    
#   $context->log('W', '_doxify_(', $context, ', ', $text, ')');
#   $context->pushLog;
    
    # Protect Doxygen escape sequences:
    
    $text =~ s/([\\\@])/$1$1/gs;
    
    # Convert POD escape sequences:
    
    while ($text =~ s/^(.*?)([BCEFILSZ])<//s) {
        $result .= $1;
        
        my  $code = $2;
        my  $cnt  = 1;
        
        $cnt++
            while $text =~ s/^<//s;
        
        my  $end  = index $text, '>' x $cnt;
        
        if ($end < 0) {
            $context->log('W', 'Unterminated POD escape sequence ',
                         $code, '<' x $cnt, substr($text, 0, 15), '...');
            next;
        }
        
        my  $inner = substr($text, 0, $end, '');
        
        substr($text, 0, $cnt) = '';
        
        if ($code eq 'B') {
            $result .= HTML_CONVERT
                     ? "<strong>$inner</strong>"
                     : _glom_('@b', $inner);
        } elsif ($code eq 'C' || $code eq 'F') {
            $result .= HTML_CONVERT
                     ? "<tt>$inner</tt>"
                     : _glom_('@c', $inner);
        } elsif ($code eq 'E') {
            $result .= _escape_($inner);
        } elsif ($code eq 'I') {
            $result .= HTML_CONVERT
                     ? "<em>$inner</em>"
                     : _glom_('@e', $inner);
        } elsif ($code eq 'L') {
            $result .= _linkage_($inner);
        } elsif ($code eq 'S') {
            $result .= _spaces_($inner);
        } elsif ($code eq 'Z') {
            $result .= $inner;
        } else {
            my  $orig = "$code<$inner>";
            
            $context->log('W', 'Unknown POD escape sequence ', $orig);
            $result .= $orig;
        }
    }
    
    $result .= $text;
    
#   $context->log('T', 'Result:  ', $result);
#   $context->popLog;
    
    $result
}

###########################################################################

my  %_html_ = (
    gt      =>  '&gt;',
    lt      =>  '&lt;',
    sol     =>  '/',
    verbar  =>  '|',
);
my  %_doxy_ = (
    %_html_,    # defaults, where necessary, overridden by:
    gt      =>  '\\>',
    lt      =>  '\\<',
#   sol     =>  '/',
#   verbar  =>  '|',
);

sub _escape_    # $which
{
    my  $which  = shift;
    my  $char   = undef;

    if ($which =~ m|^0[0-7]+$|) {
        # Character with specified number in octal:
        $char = oct($which);
    } elsif ($which =~ m|^0x[0-9A-F]+$|) {
        # Character with specified number in hex:
        $char = hex($which);
    } elsif ($which =~ m|^\d+$|i) {
        # Character with specified number in decimal:
        $char = int($which);
    }

    return ($char >= 32 && $char < 255) ? chr($char) : "&#$char;"
        if defined $char;

    my  $lookup = HTML_CONVERT ? \%_html_ : \%_doxy_;

    $lookup->{$which} || "&$which;"
}

###########################################################################

sub _glom_      # $prefix, $text
{
    my ($prefix, $text) = @_;

    join '', map {
        /\S/ ? "$prefix $_" : $_
    } split m|(\s+)|, $text
}

###########################################################################

sub _linkage_   # $link
{
    my  $link = shift;
    
    return $link;

    return HTML_CONVERT ? "<a href='$link'>$link</a>" : $link
        if $link =~ m{^\w+:};

    my  $sect = undef;
    my  $text = undef;

    ($link, $text) = ($2, $1)
        if $link =~ m{^(.*?)\|(.*)$};

    ($link, $sect) = ($1, $2)
        if $link =~ m{^(.*?)/(.*)$};

    $text = $sect || $link
        unless $text;

    $link = "$link#$sect"
        if $sect;

    HTML_CONVERT ? "\{(a href='$link')\}$text\{(/a)\}" : $text
}

###########################################################################

sub _spaces_    # $text
{
    my ($text) = @_;

    join '', map {
        $_ ne ' '    ? $_ :
        HTML_CONVERT ? '&nbsp;'
                     : chr(0xA0)
    } split m|( )|, $text
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl Doxygen::Item

=head1 AUTHOR

Marc M. Adkins, L<mailTo:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
