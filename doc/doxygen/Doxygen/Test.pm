package Doxygen::Test;

=head1 NAME

Doxygen::Test - Test module, used only in Doxygen:: test files (.t files).

=head1 SYNOPSIS

    use Doxygen::Test   path  => '../../DoxyFilt',
                        tests => 2;
    
    like(qr(\n\s*   #ifndef\s+DoxyFilt
            \n\s*   #define\s+DoxyFilt
            .*?
            \n\s*   #endif)sx,
         're-definition macro');

=head1 DESCRIPTION

This module exists only to support automated testing of the other
C<Doxygen> modules.
It is used inside of C<t.#> files instead of C<Test::Simple> or
C<Test::More>.

In addition to specifying the number of tests,
instantiation specifies a source file to be processed.
This is done using the normal C<Doxygen::Source> mechanism.
The output is captured and stored in the object,
so that subsequent C<like()> calls can match against it.

=head1 METHODS

=over

=cut

use     5.005;  # just to pick something, but not really tested
use     strict;
use     warnings;
use     UNIVERSAL   qw(isa);

use     Test::Builder;
require Exporter;

use     Doxygen::Source;

our @ISA     = qw(Exporter);
our @EXPORT  = qw(ok like unlike show);
our $VERSION = '0.01';

my  $ok   = undef;
my  $path = undef;
my  $src  = undef;
my  $test = new Test::Builder;
my  $text = undef;

###########################################################################
###########################################################################

=item   C<import(%self, %flags)>

The import protocol for the package is used to setup conditions
for testing.

=cut

sub import
{
    my ($self, %flags) = @_;
    
    $test->exported_to(scalar(caller));
    
    $flags{tests} += 3
        if defined $flags{tests};
    
    delete $flags{path}
        if $path = $flags{path};
    
    $test->plan(%flags);
    
    $ok = $path && -f $path;
    $test->ok($ok, 'path  ' . ($path  || ''));
    
    $ok = isa($src = new Doxygen::Source($path), 'Doxygen::Source')
        if $ok;
    
    $test->ok($ok, "create source");
    
    if ($ok) {
        local   $/ = 1; # file slurp mode
        
        if (pipe(READ, WRITE)) {
            my  $pid;

            if ($pid = fork()) {
                # Parent reads from child:
                close WRITE;
                $text = <READ>; # slurp
                close READ;
            } elsif (defined $pid) {
                # Child writes to parent:
                close READ;
                open STDOUT, ">&WRITE";
                $src->generate;
                close WRITE;
                
                # Child just exits, without tallying tests:
                $test->no_ending(1);
                exit;
            }

        }
        
        $ok = $text && length($text);
    }
    
    $test->ok($ok, "filter text");
    
    $self->export_to_level(1, $self, @EXPORT);
}

###########################################################################
###########################################################################

=item   C<show()>

=cut

sub show
{
    $ok && print $text;
}

###########################################################################
###########################################################################

=item   C<ok($text, $name)>

=cut

sub ok
{
    $ok && $test->ok(@_)
}

###########################################################################

=item   C<like($pattern, $name)>

=cut

sub like
{
    $ok && $test->like($text, @_)
}

###########################################################################

=item   C<unlike($pattern, $name)>

=cut

sub unlike
{
    $ok && $test->unlike($text, @_)
}

###########################################################################
###########################################################################

1

__END__

=back

=head1 SEE ALSO

DoxyFilt.pl

=head1 AUTHOR

Marc M. Adkins, L<mailto:Perl@Doorways.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Marc M. Adkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
