package Doxygen::POD::Filter;

=head1 NAME

Doxygen::POD::Filter - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $filter = new Doxygen::POD::Filter($path);

=head1 ABSTRACT

The basic POD filter, or parser.
Processes a file of data looking for POD statements.
Stores the data on itself (single use only)
and generates Doxygen-parseable output as required.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(can isa);

use     Carp;

use     Doxygen::POD::Item;
use     Doxygen::POD::Item::Code;
use     Doxygen::POD::Item::Format;
use     Doxygen::POD::Item::Head;
use     Doxygen::POD::Item::Over;

# Test this pattern (on behalf of Doxygen::Perl::Filter):
use     Doxygen::Filter;
our @ISA = ( 'Doxygen::Filter' );

our $VERSION = '0.01';

use     constant    TYPE_FLAG   =>  (
    skipHead    =>  qr(^(?:METHOD|FUNCTION)S?$)
);

###########################################################################

=item   C<CleanText(\$text)>

Remove all POD from the text referenced.

Removes the number of blocks removed.

=cut

sub CleanText   # $text
{
   ${$_[0]} =~ s/(?:\n|^)=.*?\n=cut.*?(?=\n|$)//gs
}

###########################################################################
###########################################################################

=item   C<parse(\$text, $context)>

Parse a source file.

Attach results (Doxygen::Item objects) to Doxygen::Source object.

=begin doxygen
@note This is a line-by-line state machine.
Works OK just on the POD,
since now the Perl parsing has been removed to another file.
Was really complicated before when they were combined into
one parser.
=end

=cut

sub parse       # $self, \$text, $context
{
    my  $self = shift;
    my ($text, $context) = @_;
    
#   $context->log('T', __PACKAGE__, '::parse()');
    
    my  @focus = ( $self->{root} = new Doxygen::POD::Item );
    my  $atEND = 0;
    my  $depth = 0;
    my  $inPOD = 0;
    
    $self->{lines} = {
        Perl    =>  0,
        total   =>  0
    };
    
    for (split /\n/, $$text) {
        $self->{lines}->{total}++;
        
#       $context->log('T', 'Line ', $self->{lines}->{total}, ' (', scalar(@focus), ') ', $_);
        
        unless (defined) {
            $self->{lines}->{Perl}++ unless $inPOD;
            next;
        }
        
        if (isa($focus[0], 'Doxygen::POD::Item::Format')) {
            # Currently in formatting mode:
            if (/^=end/) {
                shift @focus;
                next;
            }
            
            if ($atEND && /^\@page\b/) {
                # If we find an @page beyond __END__
                #   reset the focus to the current file:
                my  $format = shift @focus;
                
                $focus[0]->textPop('comment');
                @focus = ( $format );
                $context->getFile->textAppend('pages', $format);
            }
            
            $focus[0]->textAppend('comment', "$_\n");
            next;
        }
        
        next
            if /^=pod\b/;
        
        my  $line = \$_;
            
        if (/^=cut\b/) {
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
            
            $inPOD = 0;
            next;
        } elsif (/^=head([1234])\s*(.*?)\s*$/) {
            # Documentation header level:
            my ($level, $name) = (int($1), $2);
            
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
            
            # Need to pop headers that are less than or equal
            #   to the level of this new header:
            my  $popTo = undef;
            
            for (my $i = 0; $i < @focus; $i++) {
                next unless isa $focus[$i], 'Doxygen::POD::Item::Head';
                $popTo = $i+1 if $focus[$i]->{level} >= $level;
                last if $focus[$i]->{level} <= $level;
            }
            
            splice @focus, 0, $popTo if defined $popTo;
            
            my  $item = new Doxygen::POD::Item::Head
                                (level => $level,
                                 name  => $name);
            
            if (isa $item, 'Doxygen::POD::Item::Head') {
                $focus[0]->textAppend('comment', $item);
                unshift @focus, $item;
                push @{$self->{heads}}, $item if $level == 1;
            } else {
                $context->log('W', 'Unable to create head ', $level, ' ', $name);
            }
            
            $inPOD = 1;
            next;
        } elsif (/^=over\b/) {
#           $context->log('T', '=over at line ', $self->{lines}->{total});
            
            # Move in one list/indentation level:
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
            
            my  $item = new Doxygen::POD::Item::Over;
            
            if (isa $item, 'Doxygen::POD::Item::Over') {
                $focus[0]->textAppend('comment', $item);
                unshift @focus, $item;
            } else {
                $context->log('W', 'Unable to create indentation (over) object');
            }
            
            $inPOD = 1;
            $depth++;
            next;
        } elsif (/^=back\b/) {
#           $context->log('T', '=back at line ', $self->{lines}->{total});
            
            # Back out one list/indentation level:
            shift @focus
                while $focus[0]
                   &&   isa($focus[0], 'Doxygen::POD::Item')
                   && ! isa($focus[0], 'Doxygen::POD::Item::Over')
                   && $focus[0] != $self->{root};
            
            if (isa($focus[0], 'Doxygen::POD::Item::Over')) {
                shift @focus;
                $depth--;
            } else {
                $context->log('W', "No =over to match =back\nFocus:  ",
                             $focus[0], ' of ', scalar(@focus), "\nRoot:   ",
                             $self->{root});
            }
            $inPOD = 1;
            next;
        } elsif (/^=item\s+(.*?)\s*$/) {
            my  $name = $1;
            
#           $context->log('T', '=item ', $name, ' at line ', $self->{lines}->{total});
            
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
            
            shift @focus
                while $focus[0]
                   && ref($focus[0]) eq 'Doxygen::POD::Item'
                   && $focus[0] != $self->{root};
            
            my  $item = new Doxygen::POD::Item(name => $name);
            
            if (isa $item, 'Doxygen::POD::Item') {
                $focus[0]->textAppend('comment', $item);
                unshift @focus, $item;
            } else {
                $context->log('W', 'Unable to create item ', $name);
            }
                   
            push @{$self->{items}}, $focus[0]
                if $depth == 1
                && $name !~ /^[*+=-]$/
                && $name !~ /^[A-Z]$/
                && $name !~ /^-?\d+(?:\.\d*)?$/;
            
            $inPOD = 1;
            next;
        } elsif (/^=(for|begin)\s+(\w+)(?:\s+(.*?))?\s*$/) {
            # Go into special 'format' mode:
            my ($cmd, $fmt, $stuff) = ($1, $2, $3);
            
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
            
            my  $format = new Doxygen::POD::Item::Format(_fmt_ => $fmt);
            
            unless (isa($format, 'Doxygen::POD::Item::Format')) {
                $context->log('W', 'Unable to create format object');
            } elsif ($cmd eq 'for') {
                # Special single-line mode:
                $focus[0]->textAppend('comment', $format);
                $format->textAppend('text', "$stuff\n");
            } else {
                # Normal multi-line mode:
                $focus[0]->textAppend('comment', $format);
                unshift @focus, $format;
            }
            
            $inPOD = 1;
            next;
        } elsif (/^=[a-zA-Z]/) {
            $context->log('W', "Unknown POD directive:\n", $_);
            $inPOD = 1;
            next;
        } elsif (! $inPOD) {
            # Tripping through the Perl,
            #   don't fall through to text copy:
            $self->{lines}->{Perl}++;
            
            $atEND = 1
                if /^__END__\s*$/;
            
            next;
        } elsif (/^Doxygen(?:::\w+)+\s*-\s*(.*?)\s*$/) {
            # Attempt to match common first-line practice:
            my  $brief = $1;    $line = \$brief;
        } elsif (/^\s+\S/) {
            # Indented CODE object:
            unless (isa $focus[0], 'Doxygen::POD::Item::Code') {
                my  $item = new Doxygen::POD::Item::Code;

                if (isa $item, 'Doxygen::POD::Item::Code') {
                    $focus[0]->textAppend('comment', $item);
                    unshift @focus, $item;
                } else {
                    $context->log('W', 'Unable to create code block');
                }
            }
        } elsif (/^\S/) {
            # Just some POD code:
            shift @focus
                if isa $focus[0], 'Doxygen::POD::Item::Code';
        }
        
        # For all the cases above that still needed to append
        #   some stuff to the comments collecting for the focus:
        
        $focus[0]->textAppend('comment', "$$line\n");
    }
    
    # Somewhat clumsy, but easier than really keeping track:
    $self->{lines}->{POD} =
        $self->{lines}->{total} - $self->{lines}->{Perl};
}

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Massage items in file after parsing and before generating.

Each filter may have a C<massage> method and/or a C<parse> method.
The order of parsing and massaging is undefined except that
I<all> parsing will complete prior to I<any> massaging being done.

This overload of C<massage> is used to connect POD items on this object to
applicable Doxygen items on the source object, thereby enriching the latter.

Basically it looks for items named the same as functions that have
been defined during the parse.
If a match is found, the comment lines from the item are copied to
the comment lines on the function and the item is changed to show
a link to the function itself.

=begin doxygen

@note

This code was rewritten to use the names of functions as the search
space and match items.
This way if there are no functions, because the source is a PDO file
and has no actual code in it, the search will end quickly and result
in not accidental matchups.

We originally tried to move much of this method to
Doxygen::Perl::Filter, but it just didn't know where the POD was,
and rightfully so, whereas from here the functions (which are of
class Doxygen::Item::Function, and thus neither POD-specific nor
Perl-specific) are easily accessible.

=end

=cut

sub massage     # $self, $context
{
    my ($self, $context) = @_;
    
#   $context->log('T', __PACKAGE__, ':"massage(', $context, ')')->pushLog;
    
    my  $root  = $self->{root};
    
    $root->massage($context);
    
    my  $file  = $context->getFile;
    my  $focus = $file->focus;
    
    $focus->textAppend('comment', $root->text('comment'))
        if $root->text('comment');
    
    $focus->textAppend('notes', $root->text('notes'))
        if $root->text('notes');
    
    my  $skip = $context->flag('skipHead', $self);
    
    for my $head (@{$self->{heads}}) {
        if ($head->{name} eq 'NAME') {
            my $cmnt = $head->text('comment');
            
            if (isa($cmnt, 'ARRAY')) {
                for (@$cmnt) {
                    if (/^\s*<tt>.*?<\/tt>\s*(?:-\s*)?(.*)$/) {
                        $focus->textAppend('brief', $1)
                            if $1;
                    } else {
                        $focus->textAppend('brief', $_);
                    }
                }
            }
            
            $head->{disabled} = 1;
        } elsif (isa($skip, 'Regexp') && $head->{name} =~ $skip) {
            $head->{disabled} = 1;
        } elsif ($head->{name} =~ /^NOTES?$/) {
            $focus->textAppend('notes', "\@note\n", $head->text('comment'));
            $head->{disabled} = 1;
        } elsif ($head->{name} =~ /^AUTHORS?$/) {
            for my $item (@{$head->text('comment')}) {
                $focus->textAppend('notes', "\@author $item")
                    if $item
                    && $item =~ /\S/;
            }
            $head->{disabled} = 1;
        }
    }
    
    my  @funcs = $file->items('function');
    
    unless ($file == $focus) {
      focusFunc:
        for my $func ($focus->items('function')) {
            ($_ == $func && next focusFunc) for @funcs;
            push @funcs, $func;
        }
    }
    
    my  %items = ( );
    my  %args  = ( );
    
    for my $item (@{$self->{items}}) {
        next
            unless $item->{name}
                && $item->{name} =~ /(\w+)\s*\((.*?)\)/;

        $args {$1} = $2;
        $items{$1} = $item;
    }
        
    for my $func (@funcs) {
        unless (isa($func, 'Doxygen::Item::Function')) {
            $context->log('W', "Function item not a function:\n  ", $func);
            next;
        }
    
        my  $name = $func->{name};
        
        unless ($name) {
            $context->log('W', 'Function without name');
            next;
        }
        
        my  $item = $items{$name};
        
        unless ($item) {
            $context->log('W', 'No item for function ', $name)
                unless $name =~ /^(?:DESTROY)$/
                    || $name =~ /^_/;
            
            next;
        }
        
        unless (isa($item, 'Doxygen::Item')) {
            $context->log('W', 'Item for function ', $name,
                              ' not a Doxygen::Item');
            next;
        }
        
        # Copy arguments to function object:
        #=| @todo   when copying arguments from item to function,
        #=|         compare them and generate warnings on mismatch
        $func->arguments($args{$name});
        
        # Copy comments to function object:
        $func->textAppend('comment', $item->text('comment'))
            if $item->text('comment');
        
        $func->textAppend('notes',   $item->text('notes'))
            if $item->text('notes');
        
#       # Instead of disabling item,
#       #   replace its comments and make it a bullet item
#       #   (usually the containing METHODS or FUNCTIONS =head1
#       #    will have been removed anyway):
#       $item->textClear ('comment');
#       $item->textAppend('comment',
#                         $func->image(linked => 1, escaped => 1));
#       $item->{name} = '*';
        
        # Disable the item,
        #   Doxygen provides a TOC to functions so we
        #   don't need to do our own:
        $item->{disabled} = 1
    }
    
    $context->popLog;
}

###########################################################################
###########################################################################

=item   C<flags($self, $name)>

Return reference to flags hash for filter.

These are default values.

=cut

sub flags
{
    my ($self, $name) = @_;
    
    unless ($self->{_POD_flags_}) {
        my  %flags = TYPE_FLAG;
        
        $self->{_POD_flags_} = \%flags;
    }
    
    $self->{_POD_flags_}
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
