# -*-perl-*-
#____________________________________________________________________ 
# File: SCRAM_SITE.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2004-03-17 21:19:19+0100
# Revision: $Id: SCRAM_SITE.pm.in,v 1.18 2007/02/27 11:59:39 sashby Exp $ 
#
# Copyright: 2004 (C) Shaun Ashby
#
#--------------------------------------------------------------------
BEGIN
   {
   $ENV{'SCRAM_HOME'}='/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0' if (! $ENV{'SCRAM_HOME'});
   # SCRAM environment variable contains itself (full path):
   $ENV{'SCRAM'}=$0;
   # Location of SCRAM database file:
   $ENV{'SCRAM_LOOKUPDB_DIR'}='/afs/cern.ch/user/s/sashby/w2/SCRAM/scramdb';
   $ENV{'SCRAM_LOOKUPDB'}=$ENV{'SCRAM_LOOKUPDB_DIR'}."/project.lookup"
      if ($ENV{'SCRAM_LOOKUPDB_DIR'});
   # Name of this site:
   $ENV{'SCRAM_SITENAME'}='CERN' if ( ! $ENV{'SCRAM_SITENAME'});
   # Location of tools-<site>.conf if not inside project area config:
   $ENV{'SCRAM_LOCTOOLS'}='NODEFAULT' if ( ! $ENV{'SCRAM_LOCTOOLS'});
   $ENV{'SEARCHOVRD'}='true' if ( ! $ENV{'SEARCHOVRD'});
   $ENV{'SCRAM_PERL'}='/usr/bin/env perl';
   # Location of default site-specific templates:
   $ENV{'SCRAM_SITE_TEMPLATEDIR'} = '@SITETEMPLATEDIR@';
   }

=head1 NAME

Installation::SCRAM_SITE - Define site-specific options.

=head1 DESCRIPTION

This package is included by the main scram script and will be
used to determine the SCRAM_ARCH value, in addition to providing
some other site-specific functions.

=head1 METHODS

=over

=cut

###############################################################################
package Installation::SCRAM_SITE;
use Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw( &site_dump &CVS_site_parameters &read_architecture_map &glibc_check &check_is_rh_linux );

=item   C<site_dump()>

Dump out some local CVS settings.

=cut

sub site_dump()
   {
   print "\n";
   print "Local CVS parameters (for downloads of new SCRAM versions) are: ","\n";
   my $cvs = &Installation::SCRAM_SITE::CVS_site_parameters();
   
   foreach my $cvsp (qw( CVSROOT AUTHMODE USERNAME ))
      {
      print "\t",$cvsp," = ",$cvs->{$cvsp},"\n";
      }
   print "\n";
   exit(0);
   }

=item   C<CVS_site_parameters()>

Return the CVS parameters for the SCRAM download site.

=cut

sub CVS_site_parameters()
   {
   my $cvs =
      {
      CVSROOT  => "isscvs.cern.ch:/local/reps/scram",
      AUTHMODE => "pserver",
      USERNAME => "anonymous",
      PASSKEY  => "AA_:yZZ3eKw"
	 };
   
   return $cvs;
   }

=item   C<read_architecture_map()()>

Read the architecture map file (actually, read from the __DATA__ filehandle).
The format of the file is

   <native architecture>:<test function to run (with args)>:<arch string to return>

For example,
   
linux:&linux_check(2,3,2,"intel"):"slc3_ia32_gcc323"

=cut

sub read_architecture_map()
   {
   my $archlist={};
   my $fullpackagename="&".__PACKAGE__."::";
   my $archevalfunc = [];
   
   # Read from __DATA__ filehandle: 
   while (<DATA>)
      {
      next if /^#/;
      my ($nativearch,$archevalfuncstring,$archstring) = ($_ =~ /^(.*)?:(.*)?:\"(.*)?\".*$/);
      
      # First pass: we collect all lines in the map that are relevant to our
      # native architecture (linux/solaris/win32):
      if ($nativearch =~ $^O)
	 {
	 # Save the arch string as the name and the function
	 # string (as an array)  as the value in the hash:
	 $archlist->{$archstring} = [];
	 # Convert <subroutine_name> into "Installation::SCRAM_SITE::subroutine_name()"
	 # since this is what is required to actually execute the function. Note that we
	 # do the splitting so that "&&" operator is preserved:
	 map
	    {
	    if ($_ !~ /&&/)
	       {
	       $_ =~ s/\&/$fullpackagename/g;
	       }
	    push(@{$archlist->{$archstring}},$_);
	    } split(" ",$archevalfuncstring);
	 }
      }
   return $archlist;
   }

=item   C<glibc_check($major,$minor,$pathlevel)>

Return true or false depending on whether the current system
has a libc version which matches the required major/minor/patchlevel.

=cut

sub glibc_check()
   {
   my ($major,$minor,$patchlevel) = @_;
   my $lddcmd="ldd /bin/ls";
   
   # Open the ldd command as a pipe:
   my $pid = open(LDD,"$lddcmd 2>&1 |");
   
   # Check that we were able to fork:
   if (defined($pid))
      {
      # Loop over lines of output:
      while (<LDD>)
	 {
	 chomp $_;
	 # Grab something that looks like "libc.*":
	 if (my ($libc) = ($_ =~ /\s+libc\.so.*\s.*\s(.*)\s.*/))
	    {
	    # Check if this libc thing is a soft link (it should be), then
	    # find out what the thingy is that the link points to:
	    if ( -l $libc && defined(my $value = readlink $libc))
	       {
	       # Extract the useful numeric info from this:    
	       my ($libcmaj,$libcmin,$libcpatchlvl) = ($value =~ /^libc-([0-9]+)\.([0-9]+)\.([0-9]+)\.so/);
	       if ($libcmaj == $major && $libcmin == $minor && $libcpatchlvl == $patchlevel)
		  {
		  return 1;
		  }
	       }
	    last;
	    }
	 }
      }
   # All other cases we return false:
   return 0;
   }

=item   C<check_is_rh_linux()>

Return true or false depending on whether the current system
is running RedHat Linux.

=cut

sub check_is_rh_linux()
   {
   if ( -f '/etc/redhat-release')
      {
      return 1;
      }
   return 0;
   }

=item   C<is_slc_version()>

Return true or false depending on whether the current system
is running a version of SLC.

=cut
   
sub is_slc_version()
   {
   my ($version)=@_;
   if ( -f "/etc/redhat-release")
      {
      open(RH,"< /etc/redhat-release");
      chomp(my $l = (<RH>));
      close(RH);
      my $mversion;
      if (($mversion) = ($l =~ /Scientific Linux CERN.*?([0-9])\.[0-9].*\(.*?\)/))
	 {
	 if ($mversion == $version)
	    {
	    return 1;
	    }
	 }      
      }
   return 0;
   }

=item   C<linux_check()>

Return true or false depending on whether the current system
is running a flavour of Linux.

=cut

sub linux_check()
   {
   my ($major,$minor,$patchlevel,$cputype) = @_;
   
   if (&glibc_check($major,$minor,$patchlevel))
      {
      my $cpu = `cat /proc/cpuinfo | grep -c -i $cputype`;
      if ($cpu > 0)
	 {
	 return 1;
	 }
      }
   return 0;
   }

=item   C<is_64bit()>

Return true or false depending on whether the current system
is running on 64bot architecture.

=cut

sub is_64bit()
   {
   my $cputype = `uname -a | grep -c -i 64`;
   if ($cputype > 0)
      {
      return 1;
      }
   return 0;
   }

=item   C<check_is_osx_panther()>

Return true or false depending on whether the current system
is running Apple Mac OSX Version 10.3 (\"Panther\").

=cut

sub check_is_osx_panther()                                                         
   {                                                                         
   my $uname=`uname -r -s`;                                                  
   my ($osname, $version) = split / /, $uname;                               

   if ($osname == "Darwin" && $version =~ /^7.*/)                     
      {                                                                         
      return 1;                                                         
      }                                                                         

   return 0;                                                                 
   }

=item   C<check_is_osx_tiger()>

Return true or false depending on whether the current system
is running Apple Mac OSX Version 10.4 (\"Tiger\").

=cut

sub check_is_osx_tiger()
   {                                                                         
   my $uname=`uname -r -s`;                                                  
   my ($osname, $version) = split / /, $uname;                               

   if ($osname == "Darwin" && $version =~ /^8.*/)                     
      {                                                                         
      return 1;                                                         
      }                                                                         

   return 0;                                                                 
   }

=item   C<is_ppc()>

Return true or false depending on whether the current system
is running Apple Mac OSX on Power PC architecture.

=cut

sub is_ppc()
   {                                                                         
   my $uname=`uname -s -p`;                                                  
   my ($osname, $machtype) = split / /, $uname;                               

   if ($osname == "Darwin" && $machtype == "powerpc")
      {
      return 1;                                                         
      }                                                                         

   return 0;                                                                 
   }

#
# End of package
#
__DATA__;
#######################################################################################################
#                                                                                                     #
# These are the architecture mappings for this site                                                   #
#                                                                                                     #
#######################################################################################################
linux:&linux_check(2,3,4,"intel") && &is_slc_version(4) && &is_64bit():"slc4_ia64_gcc345"
linux:&linux_check(2,3,4,"amd") && &is_slc_version(4) && &is_64bit():"slc4_amd64_gcc345"
linux:&linux_check(2,3,2,"amd") && &is_slc_version(3) && &is_64bit():"slc3_amd64_gcc345"
linux:&linux_check(2,3,4,"intel") && &is_slc_version(4):"slc4_ia32_gcc345"
linux:&linux_check(2,3,2,"intel"):"slc3_ia32_gcc323"
darwin:&check_is_osx_panther():"osx103_gcc33"
darwin:&check_is_osx_tiger() && &is_ppc() :"osx104_ppc_gcc40"
darwin:&check_is_osx_tiger():"osx104_ia32_gcc40"
# E.g. linux:&glibc_check(2,3,2) && &check_is_rh_linux():"rh80_gcc33"
# E.g. solaris:&sun_libc_check() && &sun_arch():"SunOS__5.8"
# E.g. win32:&is_cygwin(3) && &MSVC_check(7,1):"cygwin_msvc71"
#######################################################################################################

1;

=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY 

=cut

