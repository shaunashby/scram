#____________________________________________________________________ 
# File: Architecture.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2003-10-23 17:20:41+0200
# Revision: $Id: Architecture.pm,v 1.6 2006/05/15 15:52:28 sashby Exp $ 
#
# Copyright: 2003 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package Architecture;

=head1 NAME
   
Architecture - Utilities to determine the architecture name.

=head1 SYNOPSIS

   if (! defined $self->{SCRAM_ARCH})
      {
      my $arch = Architecture->new();
      $self->architecture($a->arch());
      $self->system_architecture($a->system_arch_stem());
      $ENV{SCRAM_ARCH} = $self->architecture();
      }

=head1 DESCRIPTION

A mechanism to extract the current system architecture. The full arch
and system (short) arch strings can be returned in the application using
the methods in this package.

=head1 METHODS

=over
   
=cut
   
require 5.004;
use Exporter;

@ISA=qw(Exporter);
@EXPORT_OK=qw( );

=item   C<new()>

Constructor for Architecture objects.

=cut

sub new()
   {
   ###############################################################
   # new()                                                       #
   ###############################################################
   # modified : Thu Oct 23 17:21:05 2003 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   my $proto=shift;
   my $class=ref($proto) || $proto;
   my $self={};
   
   bless $self,$class;
   
   $self->_initarch();

   return $self;
   }

=item   C<arch()>

Method to set or return the architecture name.

=cut

sub arch()
   {
   my $self=shift;
   
   @_ ? $self->{arch} = shift
      : $self->{arch};
   }

=item   C<system_arch_stem()>

Method to set or return the system architecture name stem. The
architecture stem is the full architecture without any compiler dependence.
For example, the architecture B<slc3_ia32_gcc323> has a system architecture
name stem of B<slc3_ia32>.

=cut

sub system_arch_stem()
   {
   my $self=shift;
   
   @_ ? $self->{archstem} = shift
      : $self->{archstem};
   }

=item   C<_initarch()>
   
A subroutine to determine the architecture. This
is done by parsing the architecture map contained as
data inside B<SCRAM_SITE.pm> and looking for an appropriate
match for our platform.

=cut
   
sub _initarch()
   {
   my $self=shift;
   $self->parse_architecture_map();
   return $self;
   }

=item   C<parse_architecture_map()>

Read the architecture map file defined in the site package B<SCRAM_SITE.pm>.
   
=cut
   
sub parse_architecture_map()
   {
   my $self=shift;
   my $matches={};
   
   require Installation::SCRAM_SITE;
   my $architectures = &Installation::SCRAM_SITE::read_architecture_map();
   
   while (my ($archstring,$archtest) = each %{$architectures})
      {
      my $rval = eval join(" ",@$archtest);
      
      if ($rval)
	 {
	 # Store the matched string:
	 $matches->{$archstring}=1;
	 # Store the match. We take the first match then return:
	 $self->arch($archstring);
	 # Also take the arch stem from the arch string. E.g. for a string
	 # "slc3_ia32_xxx", keep the "slc3_ia32" part:
	 if (my ($sysname,$cpuarch) = ($archstring =~ /(.*?)\_(.*?)\_.*?$/))
	    {
	    my $stem = $sysname."_".$cpuarch;
	    $self->system_arch_stem($stem);
	    }
	 else
	    {
	    # Just set the stem to be the same as the main arch string:
	    $self->system_arch_stem($archstring);
	    }
	 return;
	 }
      else
	 {
	 next;
	 }
      }
   }

1;

__END__

=back

=head1 AUTHOR/MAINTAINER

Shaun Ashby

=cut
