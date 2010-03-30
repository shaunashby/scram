package Doxygen::Line::Filter;

=head1 NAME

Doxygen::Line::Filter - Perl extension for generating Doxygen documentation

=head1 SYNOPSIS

Generally this class will be instantiated:
    
    my  $filter = new Doxygen::Line::Filter($path);

and used within one of the other Doxygen:: internal classes.

=head1 ABSTRACT

Filter for pulling line counts from the log file for a previous
run of DoxyFilt.pl.

=head1 EXAMPLE

    --------------------------------------------------------------
          Perl / code               1516
               / comment             311
               / blank               768
           POD / POD                1632
    --------------------------------------------------------------
           Sub / Total              4227
         Grand / Total              4243
    --------------------------------------------------------------
               / (uncounted           16)

=head1 DESCRIPTION

Generates a Doxygen file comment block.

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     base qw(Doxygen::Filter);

use     constant    LINE_LENGTH =>  62;
use     constant    SEPARATOR   =>  '=' x LINE_LENGTH . "\n";
use     constant    DASHEDSEP   =>  '-' x LINE_LENGTH . "\n";

our $VERSION = '0.01';

###########################################################################
###########################################################################

=item   C<parse($self, $text, $context)>

Parse a source file.

Attach results (C<Doxygen::Item> objects) to C<Doxygen::Source> object.

=cut

sub parse       # $self, $text, $context
{
    my  $self = shift;
    my  $text = shift;
    my  $ctxt = shift;
    my  $file = $ctxt->getFile;
    
    $file->textAppend
        ('brief', 'Contains the documentation page \@ref codecnts.');
    
    my  %count = ( );
    
    if (isa($self->{count}, 'ARRAY')) {
        $count{$_} = 0
            for @{$self->{count}};
    } elsif ($self->{count}) {
        $count{$self->{count}} = 0;
    }
    
    for my $line (split /\n+/s, $$text) {
        next
            unless $line =~ /\[\.\]\s*(\w+)\s+(.*)/;
        
        my ($type, $facets) = ($1, $2);
        
        while ($facets =~ /(\w+)\((\d+)\)/g) {
            my  $count = "$type/$1";
            
            if (exists $count{$count}) {
                $count{$count} += $2;
            } elsif ($1 eq 'total') {
                $count{$count}  = $2;
            }
        }
    }
    
    my  $page = <<FILE_HEADER;
\@page   codecnts    Code Counts

The DoxyLine.pl script can collect statistics from DoxyFilt.pl.

In particular we can count lines in certain broadly-defined
categories.
These categories are specified on the DoxyLine.pl command
line as arguments.

The following numbers are from the \@e last run of Doxygen,
not the one that generated the pages you're actually reading.
If you run it twice in a row it'll be accurate.

\@code
FILE_HEADER
    
    $page .= SEPARATOR;
    
    my  $lines = 0;
    my  $total = 0;
    my  $templ = "%10s / %-15s %7d%s\n";
    my  @want  = @ARGV;
    my  $start = '';

    @want = sort keys %count
        unless @want;

    for my $count (@want) {
        my ($parent, $child) = split '/', $count;
        
        next
            if $count eq 'Source/total';
        
        unless ($parent eq $start) {
            $page  .= DASHEDSEP
                if $start;
            
            $start  = $parent;
        } else {
            $parent = '';
        }

        $child = 0
            unless defined $child;
        
        $count{$count} = 0
            unless defined $count{$count};
        
        next
            if $count =~ m|/total$|;
        
        $total += $count{$count};
        $page  .= sprintf $templ, $parent, $child, $count{$count}, '';
    }

    $page .= SEPARATOR;
    $page .= sprintf $templ, 'Total', 'Sub', $total, '';

    if (defined($count{'Source/total'})) {
        $page .= sprintf $templ, '', 'Grand', $count{'Source/total'}, '';
        
        if (my $weird = $count{'Source/total'} - $total) {
            $page .= DASHEDSEP;
            $page .= sprintf $templ, '', 'Uncounted',
                             $count{'Source/total'} - $total,
                             sprintf ' ( %6.2f%% )',
                                     100.0 * abs($weird)
                                           / $count{'Source/total'};
        }
    }

    $page .= SEPARATOR;
    
    $file->textAppend('pages', "$page\@endcode\n");
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
