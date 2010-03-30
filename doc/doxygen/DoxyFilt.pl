#!/bin/perl

=head1 NAME

C<DoxyFilt.pl> Script for preparing non-C/C++ input documents for Doxygen.

=head1 SYNOPSIS

usage:  $0 <flag>* <path>
        Process file specified by <path> (or via --path flag),
        generating faux C++ and Doxygen comments to standard output
    --filter    <filter>*
                    set filter to be applied to <path>
    --flag      <flag>=<value>
                    set a specified flag for all filters
    --flag      <<filter>::flag>=<value>
                    set a flag for the specified filter filter
    
    --noinfo        deactivate informational logging ([I])
    --trace         activate trace logging ([T] and [H])

In Doxygen configuration file (using Perl as source filter example):

    INPUT_FILTER = DoxyPerl

or:

    FILTER_PATTERNS = *.p?=DoxyPerl
    
The C<DoxyPerl> entry will be a batch file or shell script that in turn
invokes DoxyFilt.pl.  For example (DOS/Windows batch file):

    perl DoxyFilt.pl --filter=Perl --filter=POD %1

or (Linux shell script):

    #!/bin/sh
    perl DoxyFilt.pl --filter=Perl --filter=POD $1

Any command line parameters necessary to DoxyFilt.pl will be invoked in
the batch file.  The batch/shell scripts  (one per language) should be
either local to the execution directory or on the C<PATH>.  If the
DoxyFilt.pl script is not on the C<PATH> the batch/shell scripts
will need to be modified appropriately.

=head1 ABSTRACT

Provides an input filter for the Doxygen documentation generation tool
to convert Perl/POD (and/or other source formats) into C/C++ with
Doxygen-enabled comments.

=head1 DESCRIPTION

The Doxygen documentation processor collects information from source code
files in C and C++ and generates nicely formatted source code documentation.
This can be an important component of any fully documented software project.

Unfortunately, Doxygen doesn't know anything about any other languages.
It does, however, have an input filter setting that allows source files in
other languages to be converted to something that Doxygen I<can> recognize.
This means parsing the source files and converting them into a combination
of C/C++ and Doxygen-enabled comments.

=head1  Command-Line Arguments

The following flags can be specified to affect the
operation of <tt>DoxyFilt.pl</tt>:

=over

=item   C<--flag I<[filter::]name>=I<value>>

Specify a named flag.
Flags can be specified as global or per document filter.
More specific flags (per document filter) override global flags
for the specified document filter and are invisible to other
document filters.

=item   C<--noinfo>

Deactivates informational messages such as those that specify what file is
being processed.
These are the C<[I]> messages.

=item   C<--trace>

Activates tracing and 'hacking' messages.
The former are lower-level debugging messages.
The latter are specific conditions that have been bypassed
in possibly strange ways (if any).
These are the C<[T]> and C<[H]> messages, respectively.

=item   C<--filter>

Specify a filter filter to be applied to the source file.
There may be one or more such filters.  They will be applied
in the specified order.  After all parsing is done, a massage
step will be invoked to merge disparate results in cases where
there are multiple filters.

=back

=cut

#=| \ingroup    scripts

###########################################################################
###########################################################################

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Getopt::Long;
use     Pod::Usage;

use     Doxygen::Context;

# The last version from which this was taken was 0.23.
#   The current directory is a new branch of changes.
#   This could almost be though of as moving to V4,
#   but realistically it would be V3.5 or something,
#   as we keep the same general architecture but try
#   to make it easier to use by taking advantage of
#   new doxygen 1.4.3 features and playing with the
#   instantiation and startup flags.

our $VERSION = '0.83';

###########################################################################
# Command-line arguments:

my  %flags = (
    info   => 1,
    filter => [ ],
    flag   => [ ],
    trace  => 0
);
my  $help = undef;

pod2usage(2)
    unless GetOptions(
            'flag=s'     =>  $flags{flag},
            'info!'      => \$flags{info},
            'trace'      => \$flags{trace},
            'filter=s'   =>  $flags{filter},
            'help'       => \$help
           );

pod2usage('No file filter specified')
    unless @{$flags{filter}};

pod2usage(1)
    if $help;

my  $path = shift @ARGV;

pod2usage('No path specified')
    unless $path;

pod2usage('Input file does not exist')
    unless -f $path;

pod2usage('Input file not readable')
    unless -r $path;

###########################################################################
###########################################################################
#
# Main Program:
#

my  %fixed = ( );

for (@{$flags{flag}}) {
    my ($flag, $value);
    
    if (/^\s*(.*?)\s*=\s*(.*?)\s*$/) {
        ($flag, $value) = ($1, $2);
    } else {
        ($flag, $value) = ($_, 1);
    }
    
    if (isa($fixed{$flag}, 'ARRAY')) {
        push @{$fixed{$flag}}, $value;
    } elsif ($fixed{$flag}) {
        $fixed{$flag} = [ $fixed{$flag}, $value ];
    } else {
        $fixed{$flag} = $value;
    }
}

$flags{flag} = %fixed ? \%fixed : undef;

if (my $context = new Doxygen::Context(%flags)) {
#   $context->log('T', 'Process ', $path)->pushLog;
    $context->parse($path);
    $context->massage;
    $context->generate;
#   $context->log('T', 'Output generated!')->popLog;
} else {
    local   $/ = undef; # slurp entire file

    die "Unable to read (slurp) from file:\n    $path\n  $!\n"
        unless open FILE, '<', $path;

    print <FILE>;
}

###########################################################################
###########################################################################

__END__

=head1 SEE ALSO

Doxygen::Filter, http://www.doxygen.org

=head1 COPYRIGHT

Copyright (C) 2004  Marc M. Adkins

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Marc M. Adkins  L<mailto:Perl@Doorways.org>

=cut
