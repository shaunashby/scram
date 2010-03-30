package Doxygen::Item::Class;

=head1 NAME

Doxygen::Item::Class - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

    my  $cls = new Doxygen::Item::Class;

=head1 ABSTRACT

A Doxygen::Item::Class object represents an imaginary C++ class for
processing by the Doxygen documentation system.
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

use     base    qw(Doxygen::Item);

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<new($class, %fields)>

Construct falls through to Doxygen::Item::new().

=cut

sub new         # $class, %fields
{
    Doxygen::Item::new(@_)
}

###########################################################################
###########################################################################

=item   C<massage($self, $context)>

Massage all functions in the class.

=cut

sub massage     # $self, $context
{
    my ($self, $context) = @_;
    
    for my $function ($self->items('function')) {
        $function->massage($context);
    }
}

###########################################################################
###########################################################################

=item   C<generate($self, %flags)>

Generates output understandable by doxygen to standard output.

=cut

sub generate    # $self, %flags
{
    my ($self, %flags) = @_;
    my  $name = $self->{name};
    my  @name = split /:+/, $name;
    my  $tail = "};\n\n";
    
    $name = pop @name;
    
    $flags{indent} = '' unless defined $flags{indent};
    
    for (@name) {
        print "$flags{indent}namespace $_\n";
        print "$flags{indent}\{\n";
        $tail = "\};\n$flags{indent}$tail";
        $flags{indent} .= '    ';
    }
    
    $tail = "$flags{indent}$tail";

    print "$flags{indent}/**\n";
    $self->genComment(%flags);
    print "$flags{indent} */\n\n";
    
    print "$flags{indent}class $name";
    
    my  $sep = "\n$flags{indent}: ";
    
#   print STDERR "Ancestors:  ", $self->{ancestors}, "\n";
    
    for ($self->ancestors) {
        print "${sep}public $_";
        
        $sep = ",\n$flags{indent}  "
            if $sep =~ /:/;
    }
    
    print "\n$flags{indent}\{\n";
    print "$flags{indent}  public:\n";
    
    my  $first = 1;
    
    for my $arg (@{$self->{arguments}}) {
        next
            if $arg eq 'self'
            || $arg eq 'this'
            || $arg eq 'class';
        
        if ($first) {
            undef $first;
        } else {
            print ', ';
        }
        
        print "void * $arg";
    }
    
    $flags{indent} .= '    ';
    $self->SUPER::generate(%flags);
    print $tail;
}

###########################################################################
###########################################################################

=item   C<ancestor($self, @ancestors)>

Set ancestor for class object.

=cut

sub ancestor    # $self, $ancestor
{
    my  $self = shift;
    
#   print STDERR __PACKAGE__, '::ancestor(', scalar(@_), ")\n";
    
  ancestor:
    for my $anc (@_) {
        next
            unless $anc
                && $anc =~ /\S/;
        
        for my $have (@{$self->{ancestors}}) {
            next ancestor
                if $have eq $anc;
        }
        
        push @{$self->{ancestors}}, $anc;
    }
}

###########################################################################

=item   C<ancestors($self)>

Return ancestor list for class.

=cut

sub ancestors
{
    my  $self = shift;
    
#   print STDERR __PACKAGE__, "::ancestors()\n";
    
    isa($self->{ancestors}, 'ARRAY') ? @{$self->{ancestors}} : ( )
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
