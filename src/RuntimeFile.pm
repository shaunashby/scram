#____________________________________________________________________ 
# File: RuntimeFile.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2004-05-19 15:40:10+0200
# Revision: $Id: RuntimeFile.pm,v 1.2 2004/12/10 13:41:36 sashby Exp $ 
#
# Copyright: 2004 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package RuntimeFile;
require 5.004;
use ActiveDoc::SimpleDoc;
use Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw( );

sub new()
  ###############################################################
  # new()                                                       #
  ###############################################################
  # modified : Wed May 19 15:40:33 2004 / SFA                   #
  # params   :                                                  #
  #          :                                                  #
  # function :                                                  #
  #          :                                                  #
  ###############################################################
  {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self={};

  $self->{runtimefile} = shift;
  $self->{content} = {};
  $self->{varstore} = {};
  $self->{thisrtinfo} = [];
  
  bless $self,$class;
  return $self;
  }

sub read()
   {
   my $self=shift;
   use Cwd;
   
   # Check to see that the rt file exists:
   if ( ! -f cwd()."/".$self->{runtimefile} )
      {
      $::scram->scramfatal("Runtime file \"".$self->{runtimefile}."\" does not exist or is not readable!.");
      }
   else
      {
      print "Reading RT environment from file ",$self->{runtimefile},"\n", if ($ENV{SCRAM_DEBUG}); 
      }
   
   # A new SimpleDoc object to parse the file:
   $self->{simpledoc} = ActiveDoc::SimpleDoc->new();
   
   $self->{simpledoc}->newparse("RUNTIME");
   $self->{simpledoc}->filetoparse($self->{runtimefile});
   $self->{simpledoc}->addtag("RUNTIME","Runtime",
			      \&runtimetagOpen, $self,	
			      \&runtimetagInfo, $self,
			      \&runtimetagClose, $self);
   
   # Parse the file:
   $self->{simpledoc}->parse("RUNTIME");
   delete $self->{simpledoc};
   }

sub content()
   {
   my $self = shift;
   return $self->{content};
   }

sub info()
   {
   my $self=shift;
   my ($rtname) = @_;

   if (exists ($self->{content}->{$rtname}))
      {
      if (exists ($self->{content}->{$rtname}->{'info'}))
	 {
	 print $rtname,":\n";
	 foreach my $iline (@{$self->{content}->{$rtname}->{'info'}})
	    {
	    print $iline,"\n"; 
	    }
	 }
      else
	 {
	 print "No description for runtime variable \"",$rtname,"\" in file ".$self->{runtimefile}."!\n";
	 }
      }
   else
      {
      $::scram->scramerror("Runtime variable ".$rtname." is not defined in ".$self->{runtimefile}."!");
      exit(1);
      }
   }

sub runtimetagOpen()
   {
   my ($self, $name, $hashref) = @_;
   $self->{simpledoc}->checktag($name, $hashref, "name");
   $self->{thisrtname} = $hashref->{'name'};
   
   # Check for values (as value or default):
   foreach my $t (qw(value)) # Only support "value"
      {
      if (exists ($hashref->{$t}))
	 {
	 # Try to expand the value:
	 my $thisvalue = $self->_expandvars($self->{varstore},$hashref->{$t});
	 # There were no dollar signs so we can assume
	 # that everything was evaluated properly:
	 if ($thisvalue !~ /\$/)
	    {
	    $self->{varstore}->{$hashref->{'name'}} = $thisvalue;
	    $self->{content}->{$hashref->{'name'}} = { value => $thisvalue };
	    }
	 }
      }
   }

sub runtimetagInfo()
   {
   my ($self, $name, @infotext) = @_;
   push(@{$self->{thisrtinfo}},@infotext);
   }

sub runtimetagClose()
   {
   my ($self, $name, $hashref) = @_;
   $self->{content}->{$self->{thisrtname}}->{'info'} = $self->{thisrtinfo};
   delete $self->{thisrtname};
   $self->{thisrtinfo} = [];
   }

sub _expandvars
   {
   my $self=shift;
   # $dataenvref is the store of tags already parsed (e.g., X_BASE, LIBDIR etc.):
   my ($dataenvref,$string) = @_;
   
   return "" , if ( ! defined $string );
   # To evaluate variables in brackets, like $(X):
   $string =~ s{\$\((\w+)\)}
      {
      if (defined $dataenvref->{$1})
	 {
	 $self->_expandvars($dataenvref, $dataenvref->{$1});
	 }
      elsif (defined $ENV{$1})
	 {
	 $self->_expandvars($dataenvref, $ENV{$1});
	 }
      else
	 {
	 "\$$1";
	 }
      }egx;
   
   # To evaluate variables like $X:
   $string =~ s{\$(\w+)}
      {
      if (defined $dataenvref->{$1})
	 {
	 $self->_expandvars($dataenvref, $dataenvref->{$1});
	 }
      elsif (defined $ENV{$1})
	 {
	 $self->_expandvars($dataenvref, $ENV{$1});
	 }
      else
	 {
	 "\$$1";
	 }
      }egx;

   # Now return false if the string wasn't properly evaluated (i.e. some $ remain), otherwise
   # return the expanded string:
   ($string =~ /\$/) ? return undef : return $string;

   }

1;
