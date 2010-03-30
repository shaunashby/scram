#____________________________________________________________________ 
# File: DepTracker.pm
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2005-07-18 13:55:27+0200
# Revision: $Id: DepTracker.pm,v 1.5 2006/02/10 18:10:14 sashby Exp $ 
#
# Copyright: 2005 (C) Shaun ASHBY
#
#--------------------------------------------------------------------

=head1 NAME

SCRAM::DepTracker - A package for tracking dependencies in new packages.

=head1 SYNOPSIS

	my $obj = SCRAM::DepTracker->new();

=head1 DESCRIPTION

This package provides functions for reading package sources to determine
which other packages are required (the package dependencies). From this
information, a BuildFile can be produced which can be used as a starting
point.
   
=head1 METHODS

=over

=cut

package SCRAM::DepTracker;
require 5.004;
use Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw( );

=item   C<new($sourcedir, $headerdir)>

Set up a new SCRAM::DepTracker object, reading source files from
$sourcedir and header files from $headerdir.
Runs $self->do_scan() to actually scan all files.

=cut

sub new
  ###############################################################
  # new                                                         #
  ###############################################################
  # modified : Mon Jul 18 13:55:42 2005 / SFA                   #
  # params   :                                                  #
  #          :                                                  #
  # function :                                                  #
  #          :                                                  #
  ###############################################################
  {
  my $proto=shift;  my $class=ref($proto) || $proto;
  my $self={};
  bless $self,$class;
  $self->{SOURCE_DIR} = shift;  
  $self->{HEADER_DIR} = shift;
  $self->{HAVE_SRC} = 0;
  $self->do_scan();
  return $self;
  }

=item   C<do_scan()>

Execute the main function main_() to read the files.

=cut

sub do_scan()
   {
   my $self=shift;
   # Run the main function that does the work:
   $self->main_();
   }

=item   C<main_()>

Set the starting directory to the current directory and then parse all
files found under $self->{SOURCE_DIR} and $self->{HEADER_DIR}.
Determine the package name.

=cut

sub main_()
   {
   my $self=shift;
   my @files;

   $self->setcwd_();

   # Determine the package name:
   my $path;
   ($path = $self->{START_DIR}) =~ s|^\Q$ENV{LOCALTOP}\L/src/||;
   my ($subsystem, $pkg) = split("/",$path);

   # Check for a package name first:
   if ($pkg eq '')
      {
      # There isn't a package where we expect it, therefore the subsystem
      # is actually the package and there's no real subsystem:
      $self->{PACKAGE_NAME} = $subsystem;
      }
   else
      {
      $self->{PACKAGE_NAME} = $pkg;
      }


   # Only do something if there's a src dir. If not, no lib so no BuildFile:
   if (-d $self->{SOURCE_DIR})
      {
      $self->{HAVE_SRC} = 1;
      opendir (DIR,  $self->{SOURCE_DIR}) || die $self->{SOURCE_DIR}.": cannot read: $!\n";
      @files = map { $self->{SOURCE_DIR}."/$_" } grep ($_ ne "." && $_ ne ".." && $_ ne "CVS", readdir(DIR));
      closedir (DIR);
      if (-d $self->{HEADER_DIR})
	 {
	 my @hfiles;
	 opendir (DIR,  $self->{HEADER_DIR}) || die $self->{HEADER_DIR}.": cannot read: $!\n";
	 @hfiles = map { $self->{HEADER_DIR}."/$_" } grep ($_ ne "." && $_ ne ".." && $_ ne "CVS", readdir(DIR));
	 closedir (DIR);
	 push (@files, @hfiles);
	 }      
      
      # Iterate over the file list, extracting the include statements:
      $self->parsefiles_(\@files);
      }
   }

=item   C<setcwd_()>

   Set $self->{STARTDIR} to the current working directory.

=cut

sub setcwd_()
   {
   my $self=shift;
   use Cwd;
   $self->{START_DIR} = cwd();
   }

=item   C<parsefiles_($filelist)>

Parse the list of files $filelist to extract the package names
from include directives.

=cut

sub parsefiles_()
   {
   my $self=shift;
   my ($filelist)=@_;
   my $packagelist={};
   my $externals={};
   
   foreach my $file (@$filelist)
      {
      open(FH, "$file") || die "$!","\n";      
      while (<FH>)
	 {
	 chomp;
	 if ($_ =~ /^\#include "(.*)\/interface.*"$/)
	    {
	    $packagelist->{$1}=1;
	    }
	 elsif ($_ =~ /^\# include "(.*)\/interface.*"$/)
	    {
	    $packagelist->{$1}=1;
	    }
	 elsif ($_ =~ /^\#include "(.*)\/.*"$/) # Should catch the likes of SEAL/Boost
	    {
	    $externals->{$1}=1;
	    }
	 elsif ($_ =~ /^\# include "(.*)\/.*"$/) # Should catch the likes of SEAL/Boost
	    {
	    $externals->{$1}=1;
	    }
	 }
      close(FH);
      }

   # Store this information somewhere:
   $self->{PACKAGE_DATA} =
      {
      PACKAGE_DEPS => [ keys %$packagelist ],
      EXTERNAL_DEPS => [ keys %$externals ],      
      };   
   }

=item   C<show_buildfile()>

Output a generated BuildFile as a text string.

=cut

sub show_buildfile()
   {
   my $self=shift;
   my $buildfile="\n";

   # Only dump a BuildFile if one is really needed:
   if ($self->{HAVE_SRC})
      {
      $buildfile.="<export>\n";
      $buildfile.=" <lib name=".$self->{PACKAGE_NAME}.">\n";
      foreach my $use (@{$self->{PACKAGE_DATA}->{PACKAGE_DEPS}}, @{$self->{PACKAGE_DATA}->{EXTERNAL_DEPS}})
	 {
	 $buildfile.=" <use name=".$use.">\n";
	 }
      $buildfile.="</export>\n";
      $buildfile.="\n";
      foreach my $use (@{$self->{PACKAGE_DATA}->{PACKAGE_DEPS}}, @{$self->{PACKAGE_DATA}->{EXTERNAL_DEPS}})
	 {
	 $buildfile.="<use name=".$use.">\n";
	 }
      $buildfile.="\n";
      return $buildfile;
      }
   else
      {
      return "-- No sources to compile so no BuildFile needed here --\n";
      }
   }

1;

=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY

=cut

