#____________________________________________________________________ 
# File: DataCollector.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2004-06-30 11:13:06+0200
# Revision: $Id: DataCollector.pm,v 1.8 2006/09/11 14:53:39 sashby Exp $ 
#
# Copyright: 2004 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package BuildSystem::DataCollector;
require 5.004;

# A transient cache for tracking frequency of packages:
my $TRANSIENTCACHE = {};

use Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw( );

sub new()
   ###############################################################
   # new                                                         #
   ###############################################################
   # modified : Wed Jun 30 11:13:20 2004 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   {
   my $proto=shift;
   my $class=ref($proto) || $proto;
   my $self={};              
   my ($buildcache,$toolmgr,$path,$scramprojects,$sprojectbases,$scramgrapher)=@_;
   
   bless $self,$class;
   
   $self->{BUILDCACHE} = $buildcache;
   $self->{TOOLMGR} = $toolmgr;
   $self->{BRANCH} = $path;
   
   $self->{SPROJECTS} = $scramprojects;
   $self->{SPROJECTBASES} = $sprojectbases;
   
   $self->{SEEN_LOCAL_PACKAGES}={};
   $self->{SEEN_RELEASE_PACKAGES}={};
   $self->{SEEN_REMOTE_PACKAGES}={};   
   $self->{SEEN_TOOLS}={};

   $self->{G} = $scramgrapher;

   # Somewhere to store the real data:
   $self->{content} = {};
   
   return $self;
   }

sub prepare_meta()
   {
   my $self=shift;
   my ($packdir)=@_;
   my @itemnames=qw( INCLUDE LIBDIR LIB LIBTYPE MAKEFILE FLAGS ); # the list of tags to be collected
   my $showgraphs = 1; # We assume we have packages as deps so can show graphs if enabled
   
   # See if we can do a topological sort:
   $self->{BUILD_ORDER} = $self->{G}->sort();
   $self->{METADATA_ORDER} = [ reverse(@{$self->{BUILD_ORDER}}) ];

   # Also need to collect other data e.g. INCLUDE LIBDIR LIB LIBTYPE MAKEFILE FLAGS, from
   # inside product tags:
   if (exists($self->{content}->{$packdir}))
      {
      foreach my $item (@itemnames)
	 {
	 $self->datacollector($item, $self->{content}->{$packdir}->{$item});
	 }
      }
   
   # Check to see if there were any packages:
   if ($#{$self->{METADATA_ORDER}} >= 0)
      {
      # Here is where we actually prepare the INCLUDE, LIB, LIBDIR, FLAGS data for
      # all tools and packages needed by this package:
      foreach my $mdobject (@{$self->{METADATA_ORDER}})
	 {
	 if (exists($self->{content}->{$mdobject}))
	    {
	    # We have a local, release or remote package:
	    foreach my $item (@itemnames)
	       {
	       $self->datacollector($item, $self->{content}->{$mdobject}->{$item});
	       }
	    }
	 elsif (exists($self->{SEEN_TOOLS}->{$mdobject}) && $self->{SEEN_TOOLS}->{$mdobject} ne 'SCRAM')
	    {
	    # Check tools
	    # Make a copy of the tool object:
	    my $t = $self->{SEEN_TOOLS}->{$mdobject}; 
	    $self->tooldatacollector($t);
	    }
	 elsif ($self->{TOOLMGR}->definedtool(lc($mdobject)))
	    {
	    # Maybe this is a tool picked up from another package. We check to see if it's in
	    # our toolbox:
	    my $t=$self->{TOOLMGR}->checkifsetup(lc($mdobject));
	    $self->tooldatacollector($t);
	    }
	 }           
      }
   else
      {
      # There were no entries in METADATA_ORDER but we might have some other data,
      # especially INCLUDE: handle that here
      print "SCRAM debug: No packages in our data dir (\"",$packdir,"\")\n",if ($ENV{SCRAM_DEBUG});
      # Check to see if there's data and collect it:
      if (exists($self->{content}->{$packdir}))
	 {
	 # We have a local, release or remote package:
	 foreach my $item (@itemnames)
	    {
	    $self->datacollector($item, $self->{content}->{$packdir}->{$item});
	    }
	 }
      # We don't show graphs:
      $showgraphs = 0;
      }
   # return:
   return $showgraphs;
   }

sub tooldatacollector()
   {
   my $self=shift;
   my ($tool)=@_;
   my $TS=[ qw( LIB LIBDIR INCLUDE ) ];
   
   # Deal with any variables first .Store directly into the hash
   # that will be exposed to the template engine:
   foreach my $toolvar ($tool->list_variables())
      {
      $self->{DATA}->{VARIABLES}->{$toolvar} = $tool->variable_data($toolvar); 
      }
   
   # Collect Makefile tags and store directly in DATA:
   $self->storedata(MAKEFILE,[ $tool->makefile() ],''); # No referring name needed:
   
   # Store the flags into the DATA hash:
   if (defined (my $fhash=$tool->allflags()))
      {
      while (my ($flag, $flagvalue) = each %{$fhash})
	 {
	 $self->flags($flag,$flagvalue);
	 }
      }
   
   # Finally we get the LIB/LIBDIR/INCLUDE:
   foreach my $T (@{$TS})
      {
      my $sub=lc($T);
      $self->datacollector($T, [ $tool->$sub() ]);
      }
   }

sub datacollector()
   {
   my $self=shift;
   my ($tag,$data)=@_;

   if ($tag eq 'FLAGS') # This data is a hash
      {
      $self->storedata($tag,$data);
      return;
      }

   # We need somewhere to store the data:
   if (! exists($self->{DATA}))
      {
      $self->{DATA} = {};
      }
   
   # For libs, we need to check to see if we have a library that should
   # appear first in list of libs:
   if ($tag eq 'LIB')
      {           
      # Now we take the data passed to us and squirrel it away: 
      if (exists($self->{DATA}->{$tag}))
	 {
	 # Only add the item if it doesn't already exist:
	 foreach my $d (@$data)
	    {
	    # If there is a match to F:<lib>, extract the lib name
	    # and store it in a FIRSTLIBS array:
	    if ($d =~ /^F:(.*)?/)
	       {
	       my $libname=$1;	       
	       if (exists($self->{DATA}->{FIRSTLIB}))
		  {
		  # Check to see if the library already appears in the LIB 
		  if (! grep($libname eq $_, @{$self->{DATA}->{FIRSTLIB}}))
		     {
		     push(@{$self->{DATA}->{FIRSTLIB}}, $libname);
		     }		  		  
		  }
	       else
		  {
		  # Create the firstlib array:
		  $self->{DATA}->{FIRSTLIB} = [ $libname ];
		  }	       
	       }
	    else
	       {	    	  	    
	       if (! grep($d eq $_, @{$self->{DATA}->{$tag}}))
		  {
		  push(@{$self->{DATA}->{$tag}},$d);
		  }
	       }
	    }	    
	 }
      else
	 {
	 # The storage for lib doesn't exist yet so create it here:
	 $self->{DATA}->{$tag} = [];
	 
	 foreach my $d (@$data)
	    {
	    # If there is a match to F:<lib>, extract the lib name
	    # and store it in a FIRSTLIBS array:
	    if ($d =~ /^F:(.*)?/)
	       {
	       my $libname=$1;	       
	       if (exists($self->{DATA}->{FIRSTLIB}))
		  {
		  # Check to see if the library already appears in the LIB 
		  if (! grep($libname eq $_, @{$self->{DATA}->{FIRSTLIB}}))
		     {
		     push(@{$self->{DATA}->{FIRSTLIB}}, $libname);
		     }		  		  
		  }
	       else
		  {
		  # Create the firstlib array:
		  $self->{DATA}->{FIRSTLIB} = [ $libname ];
		  }
	       }
	    else
	       {
	       push(@{$self->{DATA}->{$tag}},$d);
	       }
	    }
	 }
      }
   else
      {
      # Now we take the data passed to us and squirrel it away: 
      if (exists($self->{DATA}->{$tag}))
	 {
	 # Only add the item if it doesn't already exist:
	 foreach my $d (@$data)
	    {
	    if (! grep($d eq $_, @{$self->{DATA}->{$tag}}))
	       {
	       push(@{$self->{DATA}->{$tag}},$d);
	       }
	    }
	 }
      else
	 {
	 $self->{DATA}->{$tag} = [ @$data ];
	 }
      }
   }

sub storedata()
   {
   my $self=shift;
   my ($tag,$value,$referrer)=@_;

   if ($tag eq 'PRODUCTSTORE')
      {
      # Handle productstore variables. Store in a hash with "SCRAMSTORE_x" as the key
      # pointing to correct path as it should appear in the Makefiles:
      foreach my $H (@{$value})
	 {
	 my $storename="";
	 # Probably want the store value to be set to <name/<arch> or <arch>/<name> with
	 # <path> only prepending to this value rather than replacing <name>: FIXME...
	 if ($$H{'type'} eq 'arch')
	    {
	    if ($$H{'swap'} eq 'true')
	       {
	       $storename .= $$H{'name'}."/".$ENV{SCRAM_ARCH};
	       }
	    else
	       {
	       $storename .= $ENV{SCRAM_ARCH}."/".$$H{'name'};
	       }
	    }
	 else
	    {
	    $storename .= $$H{'name'};
	    }
	 
	 $self->addstore("SCRAMSTORENAME_".uc($$H{'name'}),$storename);
	 }
      }
   elsif ($tag eq 'FLAGS')
      {
      while (my ($flag,$flagvalue) = each %{$value})
	 {
	 $self->flags($flag,$flagvalue);
	 }
      }
   elsif ($tag eq 'MAKEFILE')
      {
      if (! exists($self->{DATA}->{MAKEFILE}))
	 {
	 $self->{DATA}->{MAKEFILE} = [ @$value ];
	 }
      else
	 {
	 push(@{$self->{DATA}->{MAKEFILE}},@$value);	 
	 }
      }
   else
      {
      if (exists($self->{content}->{$referrer}))
	 {
	 if (! exists($self->{content}->{$referrer}->{$tag}))
	    {
	    $self->{content}->{$referrer}->{$tag} = [ @$value ];
	    }
	 else
	    {
	    push(@{$self->{content}->{$referrer}->{$tag}},@$value);
	    }
	 }
      else
	 {
	 $self->{content}->{$referrer} = {};
	 $self->{content}->{$referrer}->{$tag} = [ @$value ];
	 }
      }
   }

sub check_export()
   {
   my $self=shift;
   my ($pkdata,$package)=@_;
   
   if (! $pkdata->hasexport())
      {
      # No export so we return:
      return(0);
      }
   else
      {
      my $exported = $pkdata->exported();

      # We've seen this package: make a note
      $TRANSIENTCACHE->{$package} = 1;

      # Collect the exported data:
      $self->{G}->vertex($package);
      $self->process_export($exported,$package);
      return(1);
      }
   }

sub process_export()
   {
   my $self=shift;
   my ($export,$package)=@_;
   
   while (my ($tag,$tagvalue) = each %{$export})
      {
      # We check for <use> and pull in this data too:
      if ($tag eq 'USE')
	 {
	 foreach my $TV (@$tagvalue)
	    {
	    $self->{G}->edge($package, $TV);
	    }
	 # Resolve the list of uses:
	 $self->resolve_use($tagvalue);
	 }
      elsif ($tag eq 'GROUP')
	 {
	 $self->resolve_groups($tagvalue,$package);
	 }
      else
	 {
	 $self->storedata($tag,$tagvalue,$package);
	 }
      }
   }

sub check_remote_export()
   {
   my $self=shift; 
   my ($projectname, $pkdata, $package)=@_;

   if (! $pkdata->hasexport())
      {
      # No export so we return:
      return(0);
      }
   else
      {
      my $exported = $pkdata->exported();

      # We've seen this release/remote package: make a note
      $TRANSIENTCACHE->{$package} = 1;

      # Collect the exported data:
      $self->{G}->vertex($package);
      $self->process_remote_export($projectname, $exported, $package);
      return(1);
      }
   }

sub process_remote_export()
   {
   my $self=shift;
   my ($projectname,$export,$package)=@_;

   while (my ($tag,$tagvalue) = each %{$export})
      {
      # We check for s <use> and pull in this data too:
      if ($tag eq 'USE')
	 {
	 foreach my $TV (@$tagvalue)
	    {
	    $self->{G}->edge($package, $TV);
	    }
	 # Resolve the list of uses:
	 $self->resolve_use($tagvalue);
	 }
      elsif ($tag eq 'GROUP')
	 {
	 $self->resolve_groups($tagvalue,$package);
	 }
      elsif ($tag eq 'MAKEFILE' || $tag eq 'FLAGS')
	 {
	 $self->storedata($tag, $tagvalue, $package);
	 }
      else
	 {
	 my $newltop;
	 my $pjname=uc($projectname);
	 # Replace any occurrence of LOCALTOP in variables with <tool>_LOCALTOP unless
	 # the "project" is the release area, in which case we want RELEASETOP:
	 if ($pjname eq 'RELEASE')
	    {
	    $newltop = 'RELEASETOP';
	    }
	 else
	    {
	    $newltop=$pjname."_BASE";
	    }
	 
	 foreach my $val (@{$tagvalue})
	    {
	    $val =~ s/LOCALTOP/$newltop/g;
	    }
	 
	 # Now we store the modified data for variables:
	 $self->storedata($tag,$tagvalue,$package);
	 }
      }
   }

sub resolve_arch()
   {
   my $self=shift;
   my ($archdata,$referrer)=@_;
   
   while (my ($tagname, $tagvalue) = each %{$archdata})
      {
      # Look for group tags:
      if ($tagname eq 'GROUP')
	 {   
	 $self->resolve_groups($tagvalue,$referrer);
	 }
      # Look for <use> tags:
      elsif ($tagname eq 'USE')
	 {
	 # Add edges to our dep graph for packages needed
	 # by the referring package:
	 foreach my $TV (@{$tagvalue})
	    {
	    $self->{G}->edge($referrer, $TV);
	    }	 
	 # resolve the USE:
	 $self->resolve_use($tagvalue);
	 }
      else
	 {
	 # We have another type of data:
	 $self->storedata($tagname,$tagvalue,$referrer);
	 }
      }      
   }

sub resolve_use()
   {
   my $self=shift; 
   my ($data) = @_;

   foreach my $use (@{$data})
      {
      # Look for the data object for the path (locally first):
      if ($self->check_local_use($use))
	 {
	 print "- Found ",$use," locally:","\n", if ($ENV{SCRAM_DEBUG});
	 # Also store full package path for our build rules:
	 $self->local_package($use);
	 }
      elsif ($self->check_release_use($use))
	 {
	 print "- Found ",$use," in release area:","\n", if ($ENV{SCRAM_DEBUG});
	 $self->release_package($use);
	 }
      elsif ($self->check_remote_use($use))
	 {
	 print "- Found ",$use," in a scram-managed project:","\n", if ($ENV{SCRAM_DEBUG});
	 $self->remote_package($use);
	 }
      # Check to see if it's an external tool. Convert the $use to lower-case first:
      elsif ($self->{TOOLMGR}->definedtool(lc($use))
	     && (my $td=$self->{TOOLMGR}->checkifsetup(lc($use))))
	 {
	 my $toolname = $td->toolname();
	 my @tooldeps = $td->use();
	 
	 print "- Found ",$use," (an external tool):","\n", if ($ENV{SCRAM_DEBUG});
	 # We have a setup tool ($td is a ToolData object). Store the data:
	 $self->tool($td->toolname(), $td); # Store the tool data too to save retrieving again later;
	 $self->{G}->vertex(lc($toolname));

	 foreach my $TD (@tooldeps)	 
	    {
	    # Make sure all tool refs are lowercase:
	    $self->{G}->edge(lc($toolname), lc($TD));
	    }
	 
	 # We also resolve the dependencies that this tool has on other tools:
	 $self->resolve_use(\@tooldeps);	 
	 }
      else
	 {
	 # Check in the toolbox for this tool. If it doesn't
	 # exist, complain:
	 print "\n";
	 print "WARNING: Unable to find package/tool called ",$use,"\n";
	 print "         in current project area (declared at ",$self->{BRANCH},")","\n";

	 # Record that this package is not found for the current location:
	 $self->{BUILDCACHE}->unresolved($self->{BRANCH}, $use);	 
	 
	 if ($ENV{SCRAM_DEBUG}) # Print more details if debug mode on
	    {
	    print "It might be that ",$use," is a relic of SCRAM V0_x series BuildFile syntax.","\n";
	    print "If so, ",$use," refers to a SubSystem: the corresponding <use name=",$use,">\n";
	    print "must be removed to get rid of this message.","\n";
	    }
	 }
      }
   }

sub resolve_groups()
   {
   my $self=shift;
   my ($inputgroups,$referrer)=@_;
   my $data={};
   $data->{USE} = [];
   
   # First of all, resolve group requirements in this BuildFile:
   foreach my $n_group (@{$inputgroups})
      {
      # Recursively check for groups and resolve them to lowest common denom (used packages):
      $self->recursive_group_check($n_group,$data,$referrer); 
      }
   
   # Resolve the $data contents:
   while (my ($tagname, $tagvalue) = each %{$data})
      {
      if ($tagname eq 'USE')
	 {
	 # Add edges to our dep graph for packages needed
	 # by the referring package:
	 foreach my $TV (@{$tagvalue})
	    {
	    $self->{G}->edge($referrer, $TV);
	    }
	 # resolve the USE:
	 $self->resolve_use($tagvalue);
	 }
      else
	 {
	 # We have another type of data in the resolved group:
	 $self->storedata($tagname,$tagvalue,$referrer);
	 }
      }
   }

sub recursive_group_check()
   {
   my $self=shift;
   my ($groupname,$data,$referrer)=@_;
   my ($location);

   # See if we find the group locally:
   if ($location = $self->{BUILDCACHE}->findgroup($groupname))
      {
      print "- Found group ",$groupname," locally:","\n", if ($ENV{SCRAM_DEBUG});      
      # Get the BuildFile object for the BuildFile where the group is defined;
      my $groupbuildobject = $self->{BUILDCACHE}->buildobject($location);
      # Get the data contained in the defined group:
      my %dataingroup = %{$groupbuildobject->dataforgroup($groupname)};
      
      # For this group, check to see if there are groups required (i.e. check for any
      # groups in data of defined group):
      while (my ($groupdatakey, $groupdatavalue) = each %dataingroup)
	 {
	 # If we have another group, call ourselves again:
	 if ($groupdatakey eq 'GROUP')
	    {
	    # NB: probably should become recursive by invoking resolve_groups() again
	    # since we might have more than one group to resolve:
	    $self->resolve_groups($groupdatavalue,$referrer);
	    }
	 else
	    {
	    if (ref($groupdatavalue) eq 'ARRAY')
	       {
	       push(@{$data->{$groupdatakey}},@{$groupdatavalue});
	       }
	    else
	       {
	       $data->{$groupdatakey} = $groupdatavalue;
	       }
	    }
	 }
      }
   # Check in the release area:
   elsif ($self->groupsearchinrelease($groupname))
      {
      my ($releasegroupdataobject) = $self->groupsearchinrelease($groupname);
      print "- Found group ",$groupname," in release area of current project:","\n", if ($ENV{SCRAM_DEBUG});
      
      # Get the data contained in the defined group:
      my %datainrelgroup = %{$releasegroupdataobject->dataforgroup($groupname)};
      
      # For this group, check to see if there are groups required (i.e. check for any
      # groups in data of defined group):
      while (my ($relgroupdatakey, $relgroupdatavalue) = each %datainrelgroup)
	 {
	 # If we have another group, call ourselves again:
	 if ($relgroupdatakey eq 'GROUP')
	    {
	    $self->resolve_groups($relgroupdatavalue,$referrer);
	    }
	 else
	    {
	    if (ref($relgroupdatavalue) eq 'ARRAY')
	       {
	       push(@{$data->{$relgroupdatakey}},@{$relgroupdatavalue});
	       }
	    else
	       {
	       $data->{$relgroupdatakey} = $relgroupdatavalue;
	       }
	    }
	 }
      }
   # Look in SCRAM-managed projects:
   elsif ($self->groupsearchinscramprojects($groupname))
      {
      my ($remotegroupdataobject) = $self->groupsearchinscramprojects($groupname);
      print "- Found group ",$groupname," in remote project:","\n", if ($ENV{SCRAM_DEBUG});
      
      # Get the data contained in the defined group:
      my %datainremgroup = %{$remotegroupdataobject->dataforgroup($groupname)};
      
      # For this group, check to see if there are groups required (i.e. check for any
      # groups in data of defined group):
      while (my ($rgroupdatakey, $rgroupdatavalue) = each %datainremgroup)
	 {
	 # If we have another group, call ourselves again:
	 if ($rgroupdatakey eq 'GROUP')
	    {
	    # NB: probably should become recursive by invoking resolve_groups() again
	    # since we might have more than one group to resolve:
	    $self->resolve_groups($rgroupdatavalue,$referrer);
	    }
	 else
	    {
	    if (ref($rgroupdatavalue) eq 'ARRAY')
	       {
	       push(@{$data->{$rgroupdatakey}},@{$rgroupdatavalue});
	       }
	    else
	       {
	       $data->{$rgroupdatakey} = $rgroupdatavalue;
	       }
	    }
	 }
      }
   else
      {
      print "WARNING: Group ",$groupname," not defined. Edit BuildFile at ",$self->{BRANCH},"\n";
      return(0);
      }
   
   return $data; 
   }

sub check_local_use()
   {
   my $self=shift;
   my ($dataposition)=@_;

   # See if this is a local package that has already been seen. We must check that the package is really
   # local before we return true if it exists in TRANSIENTCACHE:
   if (exists ($TRANSIENTCACHE->{$dataposition}) && exists($self->{SEEN_LOCAL_PACKAGES}->{$dataposition}))
      {
      # Found and data has already been handled so return OK:
      return(1);
      }
   
   # Look for the data object for the path locally:
   if (my $pkdata=$self->{BUILDCACHE}->buildobject($dataposition))
      {
      # We check to see if this package exported something and parse/store the data
      # if true:
      if (! $self->check_export($pkdata,$dataposition))
	 {
	 print "\n";
	 print "WARNING: $dataposition/BuildFile does not export anything:\n";
	 print "    **** $dataposition dependency dropped.","\n";
	 print "You must edit the BuildFile at ",$self->{BRANCH}," to add an <export>.\n";
	 print "\n";
	 }
      # Found so return OK:
      return(1);
      }
   # Otherwise, not found locally:
   return(0);
   }

sub check_release_use()
   {
   my $self=shift;
   my ($dataposition)=@_;

   # See if this is a release package that has already been seen. We must check that the package is really
   # in the release before we return true if it exists in TRANSIENTCACHE:
   if (exists ($TRANSIENTCACHE->{$dataposition}) && exists($self->{SEEN_RELEASE_PACKAGES}->{$dataposition}))
      {
      # Found and data has already been handled so return OK:
      return(1);
      }

   if (my ($sproject,$scramppkgdata)=@{$self->searchinrelease($dataposition)})
      {
      if (! $self->check_remote_export($sproject,$scramppkgdata,$dataposition))
	 {
	 print "\n";
	 print "WARNING: $dataposition/BuildFile in release area of current project does not export anything:\n";
	 print "**** $dataposition dependency dropped.","\n";
	 }
      # Found so return OK:
      return(1);
      }
   # Otherwise, not found in release area:
   return(0);
   }

sub check_remote_use()
   {
   my $self=shift;
   my ($dataposition)=@_;
   
   # See if this is a package from a SCRAM project that has already been seen. We must check that
   # the package is really in a remote project before we return true if it exists in TRANSIENTCACHE:
   if (exists ($TRANSIENTCACHE->{$dataposition}) && exists($self->{SEEN_REMOTE_PACKAGES}->{$dataposition}))
      {
      # Found and data has already been handled so return OK:
      return(1);
      }

   if (my ($sproject,$scramppkgdata)=@{$self->searchinscramprojects($dataposition)})
      {
      if (! $self->check_remote_export($sproject,$scramppkgdata,$dataposition))
	 {
	 print "\n";
	 print "WARNING: $dataposition/BuildFile in scram project \"",$sproject,"\" does not export anything:\n";
	 print "**** $dataposition dependency dropped.","\n";
	 }
      # Found so return OK:
      return(1);
      }
   return(0);
   }

sub searchinscramprojects()
   {
   my $self=shift;
   my ($dataposition)=@_;

   foreach my $pobj (keys %{$self->{SPROJECTS}})
      {
      if ($self->{SPROJECTS}->{$pobj}->buildobject($dataposition))
	 {
	 # Add the dependency on this tool (even though it's a scram project, we need the
	 # other settings that the tool provides):
	 $self->{G}->vertex($pobj);
	 $self->tool($pobj,'SCRAM');
	 
	 # Return the data object (tool name, data object):
	 return [$pobj,$self->{SPROJECTS}->{$pobj}->buildobject($dataposition)];
	 }
      }
    
   # If we got here, there were no matches:
   return (0);
   }

sub groupsearchinscramprojects()
   {
   my $self=shift;
   my ($groupname)=@_;

   foreach my $pobj (keys %{$self->{SPROJECTS}})
      {
      if (my $grouplocation = $self->{SPROJECTS}->{$pobj}->findgroup($groupname))
	 {
	 return $self->{SPROJECTS}->{$pobj}->buildobject($grouplocation);
	 }
      }
   
   # If we got here, there were no matches:
   return (0);
   }

sub searchinrelease()
   {
   my $self=shift;
   my ($dataposition)=@_;
   
   if (exists ($self->{SPROJECTS}->{RELEASE}) && 
       $self->{SPROJECTS}->{RELEASE}->buildobject($dataposition))
      {
      # Return the data object (tool name, data object):
      return ['RELEASE',$self->{SPROJECTS}->{RELEASE}->buildobject($dataposition)];
      }
   
   # If we got here, there were no matches:
   return (0);
   }

sub groupsearchinrelease()
   {
   my $self=shift;
   my ($groupname)=@_;

   if (exists($self->{SPROJECTS}->{RELEASE}))
      {
      if (my $grouplocation = $self->{SPROJECTS}->{RELEASE}->findgroup($groupname))
	 {
	 return $self->{SPROJECTS}->{RELEASE}->buildobject($grouplocation);
	 }
      }
   
   # If we got here, there were no matches:
   return (0);
   }

sub local_package()
   {
   my $self=shift;
   my ($package)=@_;
   
   if (exists ($self->{SEEN_LOCAL_PACKAGES}->{$package}))
      {
      $self->{SEEN_LOCAL_PACKAGES}->{$package}++;
      }
   else
      {
      $self->{SEEN_LOCAL_PACKAGES}->{$package} = 1;
      }
   }

sub release_package()
   {
   my $self=shift;
   my ($package)=@_;
   
   if (exists ($self->{SEEN_RELEASE_PACKAGES}->{$package}))
      {
      $self->{SEEN_RELEASE_PACKAGES}->{$package}++;
      }
   else
      {
      $self->{SEEN_RELEASE_PACKAGES}->{$package} = 1;
      }
   }

sub remote_package()
   {
   my $self=shift;
   my ($package)=@_;
   
   if (exists ($self->{SEEN_REMOTE_PACKAGES}->{$package}))
      {
      $self->{SEEN_REMOTE_PACKAGES}->{$package}++;
      }
   else
      {
      $self->{SEEN_REMOTE_PACKAGES}->{$package} = 1;
      }
   }

sub tool()
   {
   my $self=shift;
   my ($tool,$td) = @_;
   
   if (! exists($self->{SEEN_TOOLS}->{$tool}))
      {
      $self->{SEEN_TOOLS}->{$tool} = $td;
      }
   }

sub local_package_deps()
   {
   my $self=shift;
   my $orderedpackages=[];
   # Check the BUILD_ORDER array and store all local
   # packages found:
   foreach my $LP (@{$self->{BUILD_ORDER}})
      {
      if (exists($self->{SEEN_LOCAL_PACKAGES}->{$LP}))
	 {	 
	 # If there's not a src dir in this package, don't append
	 # the build rule (since there's nothing to build):
	 if ( -d $ENV{SCRAM_SOURCEDIR}."/".$LP."/src")
	    {
	    push(@$orderedpackages, $LP);
	    }
	 }
      }
   
   return $orderedpackages;
   }

####### Now some interface routines ########
sub addstore()
   {
   my $self=shift;
   my ($name,$value)=@_;

   # Make sure that the name of the store can be used as a
   # variable, i.e. for paths, replace "/" with "_":
   $name =~ s|/|_|g;
   # Add a new SCRAMSTORE. First we check to see if there
   # is already a store with the same name. If there is, we
   # do nothing since the buildfiles are parsed in the order
   # LOCAL->PARENT->PROJECT so the first one to be set will be
   # obtained locally. We want this behaviour so we can override
   # the main product storage locations locally:
   if (!exists($self->{SCRAMSTORE}->{$name}))
      {
      $self->{SCRAMSTORE}->{$name} = $value;
      }
   else
      {
      print "INFO: Product storage area \"",$self->{SCRAMSTORE}->{$name},"\" has been redefined locally.","\n"
	 if ($ENV{SCRAM_DEBUG});
      }
   }

sub scramstore()
   {
   my $self=shift;
   my ($name) = @_;
   (exists $self->{SCRAMSTORE}->{"SCRAMSTORENAME_".$name}) ?
      return $self->{SCRAMSTORE}->{"SCRAMSTORENAME_".$name}
   : return "";
   }

sub allscramstores()
   {
   my $self=shift;
   # Return a hash of scram stores:
   return $self->{SCRAMSTORE};
   }

sub flags()
   {
   my $self=shift;
   my ($flag,$flagvalue) = @_;

   if ($flag && $flagvalue)
      {
      # If FLAGS already exist, append:
      if (exists ($self->{DATA}->{FLAGS}->{$flag}))
	 {
	 # Add each flag ONLY if it doesn't already exist:
	 foreach my $F (@$flagvalue)
	    {
	    push(@{$self->{DATA}->{FLAGS}->{$flag}},$F),
	    if (! grep($F eq $_, @{$self->{DATA}->{FLAGS}->{$flag}}));
	    }
	 }
      else
	 {
	 # Create a new array of flags:
	 $self->{DATA}->{FLAGS}->{$flag} = [ @$flagvalue ];
	 }
      }
   elsif ($flag && $self->{DATA}->{FLAGS}->{$flag}->[0] ne '')
      {
      return @{$self->{DATA}->{FLAGS}->{$flag}};
      }
   else
      {
      return "";
      }
   }

sub allflags()
   {
   my $self=shift;
   my $flags={};
   
   # Return a hash containing FLAGNAME, FLAGSTRING pairs:
   while (my ($flagname,$flagvalue) = each %{$self->{DATA}->{FLAGS}})
      {
      $flags->{$flagname} = join(" ",@{$flagvalue});
      }
   
   return $flags;
   }

sub variables()
   {
   my $self=shift;
   # Return a hash of variables:
   return $self->{DATA}->{VARIABLES};
   }

sub data()
   {
   my $self=shift;
   my ($tag)=@_;
   my $sep;
   my $datastring="";

   if (exists($self->{DATA}->{$tag}))
      {
      ($tag eq 'MAKEFILE') ? $sep="\n" : $sep=" ";
      # Special treatment for LIB to handle libs that must
      # appear first in link list:
      if ($tag eq 'LIB')
	 {
	 if (exists($self->{DATA}->{FIRSTLIB}))
	    {
	    $datastring .= join($sep, @{$self->{DATA}->{FIRSTLIB}})." ";
	    $datastring .= join($sep, @{$self->{DATA}->{LIB}});
	    }
	 else
	    {
	    $datastring .= join($sep,@{$self->{DATA}->{LIB}});
	    }
	 }
      else
	 {
	 # All other tags just join:
	 $datastring .= join($sep, @{$self->{DATA}->{$tag}});
	 }

      # return the data string:
      return $datastring;
      }
   
   return "";
   }

sub copy()
   {
   my $self=shift;
   my ($localg)=@_;
   my $copy;
   # We copy the DataCollector. We only clone the grapher if
   # local graphing is being used, otherwise we leave the
   # original graph present:
   if ($localg) # Working at package-level
      {
      # Create a copy of our graph:
      my $gcopy = $self->{G}->copy();      
      # Create a new DataCollector object, initialised with same settings as we have
      # in our current object:
      $copy = ref($self)->new($self->{BUILDCACHE},
			      $self->{TOOLMGR},
			      $self->{BRANCH},
			      $self->{SPROJECTS},
			      $self->{SPROJECTBASES},
			      $gcopy); # The copy of the grapher
      }
   elsif ($localg == 0)
      {
      # Create a new DataCollector object, initialised with same settings as we have
      # in our current object:
      $copy = ref($self)->new($self->{BUILDCACHE},
			      $self->{TOOLMGR},
			      $self->{BRANCH},
			      $self->{SPROJECTS},
			      $self->{SPROJECTBASES},
			      $self->{G}); # The GLOBAL grapher
      }
   else
      {
      # Unknown value:
      return undef;
      }
   
   # Copy other counters/tracking vars:
   $copy->{SEEN_LOCAL_PACKAGES} = { %{$self->{SEEN_LOCAL_PACKAGES}} };
   $copy->{SEEN_RELEASE_PACKAGES} = { %{$self->{SEEN_RELEASE_PACKAGES}} };
   $copy->{SEEN_REMOTE_PACKAGES} = { %{$self->{SEEN_REMOTE_PACKAGES}} };
   $copy->{SEEN_TOOLS} = { %{$self->{SEEN_TOOLS}} };
   
   # Copy the "content":
   use Data::Dumper;
   $Data::Dumper::Purity = 1;
   $Data::Dumper::Terse = 1;
   my $newcontent=eval(Dumper($self->{content}));
   
   if (@!)
      {
      print "SCRAM error [DataCollector]: problems copying content...","\n";
      }

   # Now copy the data:
   my $newdata=eval(Dumper($self->{DATA}));

   if (@!)
      {
      print "SCRAM error [DataCollector]: problems copying DATA content...","\n";
      }
   
   # Store the new content:
   $copy->{content} = $newcontent;
   # Store the new data content:
   $copy->{DATA} = $newdata;
   # Bless the object:
   bless $copy, ref($self);
   # Return the copy object:
   return $copy;   
   }

sub localgraph()
   {
   my $self=shift;
   return $self->{G};
   }

sub attribute_data()
   {
   my $self=shift;
   # Prepare some data which says which packages are local,
   # release, remote or tools. This is needed for setting
   # graph attributes in SCRAMGrapher:
   my $attrdata =
      {
      LOCAL   => [ keys %{ $self->{SEEN_LOCAL_PACKAGES}}   ],
      RELEASE => [ keys %{ $self->{SEEN_RELEASE_PACKAGES}} ],
      REMOTE  => [ keys %{ $self->{SEEN_REMOTE_PACKAGES}}  ],
      TOOLS   => [ keys %{ $self->{SEEN_TOOLS}} ]
	 };
   
   return $attrdata;
   }

sub clean4storage()
   {
   my $self=shift;
   # Delete all keys except those in KEEP:
   my @KEEP = qw( DATA BUILD_ORDER SEEN_LOCAL_PACKAGES SCRAMSTORE ); 
   
   foreach my $key (keys %$self)
      {
      # If this key isn't listed in KEEP, delete it:
      if (! grep($key eq $_, @KEEP))
	 {
	 delete $self->{$key};
	 }
      }
   }

1;
