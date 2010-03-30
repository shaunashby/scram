#===========================================================================#
# NAME: AutoToolSetup.pm                                                    #
#===========================================================================#
#                                                                           #
# DATE: Thu Aug 30 09:54:23 2001                                            #
#                                                                           #
# AUTHOR: Shaun Ashby                                                       #
#                                                                           #
# MOD LOG:                                                                  #
#                                                                           #
#                                                                           #
#===========================================================================#
# DESCRIPTION: Package for automated tool setup.                            #
#===========================================================================#

=head1 NAME

SCRAM::AutoToolSetup - A package to provide hints when setting up tools.

=head1 SYNOPSIS

        my $toolsconf = $ENV{LOCALTOP}."/".$ENV{SCRAM_CONFIGDIR}."/site/tools.conf";
	my $obj = SCRAM::AutoToolSetup->new($toolsconf);

or via a global object:
   
        $ENV{'SCRAM_SITENAME'} = $area->sitename();
        $ENV{'SCRAM_PROJECTDIR'} = $area->location();

        $::lookupdb = SCRAM::AutoToolSetup->new($toolsconf); 

=head1 DESCRIPTION

An SCRAM::AutoToolSetup object provides access to methods allowing values
to be read from a tool config in the project which are then used when setting
up tools. 

=head1 METHODS

=over

=cut

package SCRAM::AutoToolSetup;
use Utilities::Verbose;
use Exporter;
require 5.004;

@ISA = ('Exporter','Utilities::Verbose');
@EXPORT_OK = ('lookupTag','checkTool','infoDump','defaultPath','printData');

=item   C<new($toolconf)>

Create a new object and populate it with the contents of file $toolconf.

=cut

sub new()
   {
   ###############################################################
   # new()                                                       #
   ###############################################################
   # modified : Thu Aug 30 17:08:33 2001 / SFA                   #
   # params   : No args have to be passed to this routine.       #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Creates a new AutoToolSetup object and returns a #
   #          : reference to it.                                 #
   #          :                                                  #
   ###############################################################
   my $class=shift;
   my ($toolconf) = @_;
   my $self =
      {
      ARCHITECTURE => '',
      SCRAM_BASEPATH => '',
      SCRAM_DEFAULTPATH => '',
      TOOL => {},	       
      };
   
   bless $self, $class;

   # Be verbose when object created:
   $self->verbose(">> Creating a new lookup object: $self");   

   # Initialize the lookup table:
   $self->_LookupInit($toolconf);
   
   return $self;
   }

=item   C<_LookupInit($toolconf)>

Initialize the database. This is only used by the new() method.

=cut

sub _LookupInit()
   {
   ###############################################################
   # _LookupInit()                                               #
   ###############################################################
   # modified : Wed Nov 14 12:52:42 2001 / SFA                   #
   # params   : none.                                            #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Initialize lookup table for tools.               #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   ###############################################################
   my $self = shift;
   my ($toolconf) = @_;
   
   # Check that we have a sitename (just use verbose):
   $self->verbose(">> Using ".$ENV{'SCRAM_SITENAME'}." as the name for this site");

   # If the user supplied a tool conf file to read, we use that:
   if ($toolconf)
      {
      print "SCRAM: Using ",$toolconf," as the lookup file.","\n", if ($ENV{SCRAM_DEBUG});
      $self->{TOOLCONFIG} = $toolconf;
      }
   else
      {
      # Set the name of the config file to read. First we look for a
      # file in the default location given by LOCTOOLS variable. Assume the filename
      # has the usual format (tools-SITENAME.conf):
      if ($ENV{SCRAM_LOCTOOLS} ne 'NODEFAULT')
	 {
	 # Replace ~ with $HOME:
	 if ($ENV{SCRAM_LOCTOOLS} =~ /^~/ )
	    {
	    ($tilde,$main) = ($ENV{SCRAM_LOCTOOLS} =~ /(^~)\/(.*$)/);
			      $ENV{SCRAM_LOCTOOLS} = $ENV{HOME}."/".$main;
	    }
	 # Remove the last slash:
	 if ( $ENV{SCRAM_LOCTOOLS} =~ /.*\/$/) { chop($ENV{SCRAM_LOCTOOLS});}
	 
	 $self->verbose(">> LOCTOOLS is set to ".$ENV{SCRAM_LOCTOOLS}." ");
	 # If the value of the LOCTOOLS variable looks like a
	 # complete filename ending in .conf:
	 if ( -f $ENV{SCRAM_LOCTOOLS} && $ENV{SCRAM_LOCTOOLS} =~ /\.conf$/)
	    {
	    # Check that it exists. If so, use it:
	    if ( -e "$ENV{SCRAM_LOCTOOLS}")
	       {
	       $self->{TOOLCONFIG}=$ENV{SCRAM_LOCTOOLS};
	       print "Using user tools file ",$self->{TOOLCONFIG}," during tool setup stage:\n";
	       }
	    else
	       {
	       # We'll have to resort to the normal file if this file isn't readable:
	       print $ENV{SCRAM_LOCTOOLS}." file can't be read. Using default tools file.","\n";
	       $self->{TOOLCONFIG}=$ENV{SCRAM_PROJECTDIR}."/".$ENV{SCRAM_CONFIGDIR}."/site/tools-".$ENV{SCRAM_SITENAME}.".conf";
	       }
	    }
	 # Otherwise, check if LOCTOOLS is a directory:
	 elsif ( -d "$ENV{SCRAM_LOCTOOLS}")
	    {
	    # Look for normal tools file under this dir:
	    $self->verbose(">> Looking for tools file under ".$ENV{SCRAM_LOCTOOLS}." ");
	    if ( -e $ENV{SCRAM_LOCTOOLS}."/tools-".$ENV{SCRAM_SITENAME}.".conf")
	       {
	       $self->{TOOLCONFIG}=$ENV{SCRAM_LOCTOOLS}."/tools-".$ENV{SCRAM_SITENAME}.".conf";
	       print "Using user tools file ",$self->{TOOLCONFIG}," during tool setup stage:\n";
	       }
	    else
	       {
	       # Use the normal file:
	       $self->verbose(">> A: No tools file under ".$ENV{SCRAM_LOCTOOLS}.". Using normal location.");
	       $self->{TOOLCONFIG}=$ENV{SCRAM_PROJECTDIR}."/".$ENV{SCRAM_CONFIGDIR}."/site/tools-".$ENV{SCRAM_SITENAME}.".conf";
	       print "Using default tools file during tool setup stage:\n";
	       }
	    }
	 else
	    {
	    # LOCTOOLS was set but is neither a file or directory. Resort to normal behaviour:
	    $self->verbose(">> B: No tools file under ".$ENV{SCRAM_LOCTOOLS}.". Using normal location.");
	    $self->{TOOLCONFIG}=$ENV{SCRAM_PROJECTDIR}."/".$ENV{SCRAM_CONFIGDIR}."/site/tools-".$ENV{SCRAM_SITENAME}.".conf";
	    print "Using default tools file during tool setup stage:\n";
	    }
	 }
      else
	 {
	 # NODEFAULT is set so look for file under normal path:
	 $self->verbose(">> NODEFAULT set. Using normal location.");
	 $self->{TOOLCONFIG}=$ENV{SCRAM_PROJECTDIR}."/".$ENV{SCRAM_CONFIGDIR}."/site/tools-".$ENV{SCRAM_SITENAME}.".conf";
	 }
      }
   
   # Set verbose:
   $self->verbose(">> Initialising lookup table for site tools configuration");
   $self->verbose(">> Tool config file: ".$self->{TOOLCONFIG});
   
   # Read the file:
   $self->_readConfig();
   
   # Dump the info if verbose mode is set:
   $self->infoDump();
   
   # and return:
   return $self;
   }

=item   C<_readConfig()>

Read the configuration file. This is only used inside the package.

=cut

sub _readConfig()
   {
   ###############################################################
   # _readConfig()                                               #
   ###############################################################
   # modified : Wed Nov 14 12:53:26 2001 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Read the site tools configuration file.          #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   ###############################################################
   use FileHandle;
   
   my $self = shift;   
   my $toolname;
   my $tagname;
   my $OS = "";
   
   # Read the configuration file and store all the info in a lookup table:
   $self->verbose(">> Trying to read file: ".$self->{TOOLCONFIG});

   my $fh = FileHandle->new();
   open($fh,$self->{TOOLCONFIG}) || die "Unable to read a site tools configuration file: $!","\n";
   chomp(my @toolconf=<$fh>);
   close($fh);

   # Now loop over the array and extract information:
   foreach (@toolconf)
      {
      # Ignore comments:
      next if ($_ =~ /^#/ );
      # Get OS info:
      /^ARCHITECTURE:(.*)/ && do {($OS) = ($_ =~ /^ARCHITECTURE:(.*)/);};
      # Check that the OS is defined, and that it matches the current
      # architecture as known to SCRAM:
      next until ($OS =~ /$ENV{SCRAM_ARCH}/);

      # Now set the OS:
      $self->{ARCHITECTURE} = $OS;
      
      # Get the path to top of release:
      /^SCRAM_BASEPATH:(.*)/ && do
	 {
	 ($self->{SCRAM_BASEPATH}) = ($_ =~ /^SCRAM_BASEPATH:(.*)/);
	 # Because we use variable expansion in the pattern match below,
	 # SCRAM_BASEPATH must be set as a variable:
	 $SCRAM_BASEPATH = $self->{SCRAM_BASEPATH};
	 next;
	 };
	       
      # Set a default search path for tools:
      /^SCRAM_DEFAULTPATH:(.*)/ && do
	 {
	 ($self->{SCRAM_DEFAULTPATH}) = ($_ =~ /^SCRAM_DEFAULTPATH:(.*)/);
	 $SCRAM_DEFAULTPATH = $self->{SCRAM_DEFAULTPATH};
	 next;
	 };
      
      # Get tool/path info. Perhaps TOOL may be a better
      # name for the tool entry. Mod regexp here to allow multi-project use:
      /^.*?TOOL:(.*):$/ && do
	 {
	 ($toolname) = ($_ =~ /^.*?TOOL:(.*):$/);
	 # Make the tool name lower case:
	 ($toolname) =~ tr[A-Z][a-z];
	 # Add the tool to the hash:
	 $self->addTool($toolname);
	 # 
	 next;
	 };
      # If tool is defined, read the tags/paths
      # and add these to the hash for key "$toolname":
      /\s+\+(.*):(.*)$/ && do
	 {
	 # Check to see if the tool has been recorded:
	 if ($self->checkTool($toolname))
	    {
	    # Do a match and extract what's needed from the line:
	    ($tag,$toolpath) = ($_ =~ /\s+\+(.*?):(.*)$/);
	    # Expand the toolpath to include the value of variable SCRAM_BASEPATH:
	    $toolpath =~ s/(\$\w+)/$1/eeg;
	    # Store these entries:
	    $self->storeTagInfo($toolname,$tag,$toolpath);
	    }
	 next;
	 }
      }
   return $self;
   }
 
=item   C<addTool($toolname)>

Add a tool $toolname to the B<TOOL> hash. The tool name is the key.

=cut

sub addTool()
   {
   ###############################################################
   # addTool()                                                   #
   ###############################################################
   # modified : Thu Sep 13 13:52:28 2001 / SFA                   #
   ###############################################################
   my $self = shift;
   my $toolname = shift;
   
   # Create an anonymous hash to store the tagnames and paths:
   my $NewToolHash = {};
   
   if ($toolname) # Add the tool to the TOOL hash:
      {
      # The value assigned to the hash with key "$toolname"
      # will be a reference to a hash containing TAG:TAGPATH pairs:
      $self->{TOOL}{$toolname} = $NewToolHash;
      }
   else
      {
      # Do nothing. Give a warning and return:
      $self->verbose("Warning: no tool name given in addTool() method call.");
      return $self;
      }   
   }

=item   C<storeTagInfo($toolname,$tagname,$tagvalue)>

Stores the name and value of the tag in the 
hash entry having key $toolname. 

=cut

sub storeTagInfo()
   {
   ###############################################################
   # storeTagInfo()                                              #
   ###############################################################
   # modified : Thu Nov 15 11:55:50 2001 / SFA                   #
   ###############################################################
   my $self = shift;
   my $toolname = shift;
   my $tagname = shift;
   my $tagvalue = shift;
   
   # If the tool is known, add the tags:
   if ($self->checkTool($toolname))
      {
      # Make sure there is both a tag name and a value:
      if (defined($tagname) && defined($tagvalue))
	 {
	 $self->{TOOL}{$toolname}{$tagname}=$tagvalue;
	 }
      else
	 {
	 $self->verbose("Warning: No tagname and/or tag value given during storeTagInfo() method call.");
	 }
      }
   else
      {
      $self->verbose("Warning: Non-existent tool $toolname during storeTagInfo() method call.");
      }
   
   return $self;
   }


=item   C<lookupTag($toolname,$tagname)>

Return a value for the tag path if the tool $toolname has the tag $tagname defined.

=cut


sub lookupTag()
   {
   ###############################################################
   # lookupTag()                                                 #
   ###############################################################
   # modified : Thu Nov 15 14:10:49 2001 / SFA                   #
   ###############################################################
   my $self = shift;
   my $toolname = shift;
   my $tagname = shift;
   my $tagvalue = "";

   # Check that tool is known:
   if ($self->checkTool($toolname))
      {
      # Make sure there is a tag name supplied:
      if (defined($tagname))
	 {
	 # Extract the value for the tag:
	 $tagvalue = $self->{TOOL}{$toolname}{$tagname}
	 }
      else
	 {
	 $self->verbose("Warning: No tagname and/or tag value given during lookupTag() method call.");
	 }
      }
   else
      {
      $self->verbose("Warning: Non-existent tool $toolname during lookupTag() method call.");
      }
   # Return the tagvalue if found:
   return $tagvalue;
   }

=item   C<checkTool($toolname)>

Check whether an entry has been made for the tool $toolname.
   
=cut

sub checkTool()
   {
   ###############################################################
   # checkTool()                                                 #
   ###############################################################
   # modified : Thu Nov 15 11:57:02 2001 / SFA                   #
   ###############################################################
   my $self = shift;
   my $toolname = shift;

   if ($self->{TOOL}{$toolname})
      {
      return (1);
      }
   else
      {
      return (0);
      }
   }

=item   C<defaultPath()>

Return the default path to tools.

=cut

sub defaultPath()
   {
   ###############################################################
   # defaultPath()                                               #
   ###############################################################
   # modified : Fri Nov 16 14:50:11 2001 / SFA                   #
   # params   : None.                                            #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Return the default path to tools.                #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   ###############################################################
   my $self = shift;

   if ($self->{SCRAM_DEFAULTPATH})
      {
      return $self->{SCRAM_DEFAULTPATH};
      }
   else
      {
      return "";
      }
   }

=item   C<infoDump()>

Dump the lookup table contents to STDOUT.
   
=cut

sub infoDump()
   {
   ###############################################################
   # infoDump()                                                  #
   ###############################################################
   # modified : Fri Oct 12 14:31:24 2001 / SFA                   #
   ###############################################################
   my $self = shift;
   my $line = "-"x100;
   my @table="\n\n";

   $self->verbose(">> ARCHITECTURE   : $self->{ARCHITECTURE}");
   $self->verbose(">> SCRAM_BASEPATH  : $self->{SCRAM_BASEPATH}");
   $self->verbose(">> SCRAM_DEFAULTPATH  : $self->{SCRAM_DEFAULTPATH}");

   push @table,$line,"\n";
   push @table,sprintf ("%-5s\t%10s\t\t\t%10s\n","Tool","Tag","Tag Value");
   push @table,$line,"\n";
   
   foreach $tool (keys %{$self->{TOOL}})
      {
      push @table,"\n",$tool,":\n";
      foreach $key (keys %{$self->{TOOL}{$tool}})
	 {
	 push @table,sprintf ("\t\t%-20s:  %s\n",$key,${$self->{TOOL}{$tool}}{$key});
         }
      }
   push @table, "\n\n";

   # If verbose option is set, this will dump the contents:
   $self->verbose("@table");

   return $self;
   }


=item   C<printData()>

Print the current data stored in the lookup table. Mainly for debugging.

=cut

sub printData
   {
   my $self=shift;
   my $line = "-"x100;
   my @table="\n\n";

   print ">> ARCHITECTURE   : $self->{ARCHITECTURE}","\n";
   print ">> SCRAM_BASEPATH  : $self->{SCRAM_BASEPATH}","\n";
   print ">> SCRAM_DEFAULTPATH  : $self->{SCRAM_DEFAULTPATH}","\n";

   push @table,$line,"\n";
   push @table,sprintf ("%-5s\t%10s\t\t\t%10s\n","Tool","Tag","Tag Value");
   push @table,$line,"\n";
   
   foreach $tool (keys %{$self->{TOOL}})
      {
      push @table,"\n",$tool,":\n";
      foreach $key (keys %{$self->{TOOL}{$tool}})
	 {
	 push @table,sprintf ("\t\t%-20s:  %s\n",$key,${$self->{TOOL}{$tool}}{$key});
         }
      }
   push @table, "\n\n";

   print join("",@table),"\n";

   
   }

1;

=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY 

=cut

