package Doxygen::Item::Function;

=head1 NAME

Doxygen::Item::Function - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $cls = new Doxygen::Item::Function;

=head1 ABSTRACT

A Doxygen::Item::Function object represents C/C++ function/method
from a source file processing by the Doxygen documentation system.
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

my  $stripArg = qr(^\\?[\$\@\%\&]);

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Item-specific massage sequences.

=cut

sub massage     # $self, $context
{
    my  $self = shift;
    
#   print STDERR __PACKAGE__, "::massage($_[0])\n";
    
    if ($self->argClear('class')) {
        $self->{static} = 1;
    } elsif ($self->argClear('self') || $self->argClear('this')) {
        delete $self->{static}
            if exists $self->{static}
    }
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate    # $self , %flags
{
    my ($self, %flags) = @_;
    
    $flags{indent} = '' unless defined $flags{indent};
    
    print "$flags{indent}/**\n";
    $self->genComment(%flags);
    
    for (@{$self->{arguments}}) {
        next
            if $_ eq 'self'
            || $_ eq 'this'
            || $_ eq 'class';
        
        my  $arg = $self->{argument}->{$_};
            
        next
            unless isa $arg, 'HASH';
        
        print "$flags{indent} *  \\param $arg->{image} $arg->{comment}\n"
            if $arg->{comment};
    }
    
    print "$flags{indent} */\n\n";
    
    # The function declaration is all one one line:
    my  $first = 1;
    
    print "$flags{indent}static\n" if $self->{static};
    
    $self->genBody(%flags);
}

###########################################################################

=item   C<genBody($self, %flags)>

Generate the body of the function.

Default version just appends a semicolon (no body).

=cut

sub genBody
{
    my ($self, %flags) = @_;
    
    print "$flags{indent}", $self->image, ";\n\n";
}

###########################################################################
###########################################################################

=item   C<argument($self, $arg, $comment)>

Sets the value of (commented associated with) a single function argument.

=cut

sub argument    # $self, $arg, $comment
{
    my ($self, $arg, $comment) = @_;
    
    $self->arguments($arg);    # makes sure arg exists for function
    
    $arg =~ s/$stripArg//o;
    
    $self->{argument}->{$arg}->{comment} = $comment
        if defined $comment;
}

###########################################################################

=item   C<argClear($self, $arg)>

Clears named argument so it doesn't exist anymore.
Returns previous value or argument name if argument existed.
Doesn't do anything but return undef if argument didn't exist.

=cut

#=| @param  $arg    Argument name to be cleared (removed)

sub argClear
{
    my ($self, $arg) = @_;
    
#   print STDERR __PACKAGE__, "::argClear($arg)\n";
    
    my  @args = ( );
    my  $fnd  = undef;
    
    $arg =~ s/$stripArg//o;
    
    for (@{$self->{arguments}}) {
        if ($_ eq $arg) {
            $fnd = 1;
        } else {
            push @args, $_;
        }
    }
    
    $self->{arguments} = \@args
        if $fnd;
    
    my  $result = $fnd && ($self->{argument}->{$arg}->{comment} || $arg);
    
    delete $self->{argument}->{$arg}
        if exists $self->{argument}->{$arg};
        
    $result
}

###########################################################################

=item   C<arguments($self, $arguments)>

Sets arguments for item.

Just creates basic arguments,
doesn't add comments but does add option flags
based on initial (removed) C<'?'> in argument name.

=cut

sub arguments
{
    my ($self, $arguments) = @_;
    
#   print STDERR __PACKAGE__, "::arguments($arguments)\n";
    
    my  $optional = undef;
    
    for (split(/\s+|[,\[\]]/, $arguments)) {
        next unless /\S/s;
        next if     /,/;
        
        if (/[\[\]]/) {
            if    (/\[/)        {   $optional++;    }
            elsif ($optional)   {   $optional--;    }
            next;
        }
        
        # Strip down argument name:
        my  $arg = $_;
        
        $arg =~ s/$stripArg//o;
        
        my  $fnd = undef;
        
        for (@{$self->{arguments}}) {
            next unless $_ eq $arg;
            $fnd = 1;
            last;
        }
        
        push @{$self->{arguments}}, $arg
            unless $fnd;
        
        $self->{argument}->{$arg} = { }
            unless isa $self->{argument}->{$arg}, 'HASH';
            
        $self->{argument}->{$arg}->{image} = $_
            unless $self->{argument}->{$arg}->{image};
        
        $self->{argument}->{$arg}->{optional} = 1
            if $optional;
    }
}

###########################################################################
###########################################################################

=item   C<image($self, %flags)>

Return 'image' of the function call.

=cut

sub image
{
    my ($self, %flags) = @_;
    my  $first = 1;
    my  $image = ''; # 'void';
    
    $image .= "\\link $self->{name}() " if $flags{linked};
    $image .= "$self->{name}";
    $image .= ' \endlink' if $flags{linked};
    $image .= ' (';

    for my $arg (@{$self->{arguments}}) {
        next
            if $arg eq 'self'
            || $arg eq 'this'
            || $arg eq 'class';
        
        if ($first) {
            undef $first;
        } else {
            $image .= ', ';
        }
        
        my  $argImg = $self->{argument}->{$arg}->{image} || $arg;
        
        $argImg =~ s|([%\\\@])|\\$1|g if $flags{escaped};
        $image .=  $argImg;
    }
    
    $image .= ')';
    $image
}

###########################################################################
###########################################################################

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
