package Doxygen::POD::Item::Code;

=head1 NAME

Doxygen::POD::Item::Code - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $item = new Doxygen::POD::Item::Code;

=head1 ABSTRACT

A block of source code in a POD source file.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     base    qw(Doxygen::POD::Item);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Convert all the comment text in this block from POD formatting
sequences into Doxygen formatting sequences.

=cut

sub massage     # $self, $context
{
    my ($self, $context) = @_;
    
    return unless isa $self->text('comment'), 'ARRAY';
    
    my  $indent = -1;
    
    for (@{$self->text('comment')}) {
        next if ref($_);
        next unless /\S/;
        
        my ($space) = /^( *)\S/;
        
        next unless defined $space;
        
        my  $len = length($space);
        
        if ($indent < 0) {
            $indent = $len;
        } elsif ($indent > $len) {
            $indent = $len;
        }
    }
    
    return if $indent < 0;
    
    my  @text = ( );
    
    for (@{$self->text('comment')}) {
        if (ref($_)) {
            push @text, $_;
        } else {
            push @text, length($_) > $indent ? substr($_, $indent) : $_;
        }
    }
    
    while (@text && $text[0]      && $text[0]      !~ /\S/) {
        $self->{prelines}++;
        shift @text;
    }
    
    while (@text && $text[$#text] && $text[$#text] !~ /\S/) {
        $self->{postlines}++;
        pop @text;
    }
    
    $self->textClear ('comment');
    $self->textAppend('comment', @text);
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate    # $self, %flags
{
    my  $self = shift;
    
    if ($self->{prelines}) {
        Doxygen::Item::genThing("\n", @_)
            for 1..$self->{prelines};
    }
    
    Doxygen::Item::genThing("\@code\n", @_);
    $self->SUPER::generate(@_);
    Doxygen::Item::genThing("\@endcode\n", @_);
    
    if ($self->{postlines}) {
        Doxygen::Item::genThing("\n", @_)
            for 1..$self->{postlines};
    }
        
    die $@ if $@
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
