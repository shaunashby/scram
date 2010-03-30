=head1 NAME

SCRAM::ScramFunctions - Access to functions for creating projects.

=head1 SYNOPSIS

	my $obj = SCRAM::ScramFunctions->new();

=head1 METHODS

=over

=cut

=item C<new()>

A new SCRAM::ScramFunctions object.

=item C<project($urlfile,$dir [, $areaname ])>

Create a project from the given URL $file and return the area (with
optional change of name to $areaname).

=item C<satellite($name,$version,$installdirectory [, $areaname ])>

Create a satellite project from the specified name and version.

=item C<addareatoDB(new Configuration::ConfigArea[,$name[,$version]])>

Add an area to the db.

=item C<globalcache([$cachedirectory]))>

Return the global cache object or set the cache directory.

=item C<scramprojectdb()>

Return the SCRAM::ScramProjectDB object.

=item C<areatoolbox($area)>

Return the toolbox of the specified area. This is
obsolete (toolbox replaced by tool manager).

=item C<setuptoolsinarea($area[,$toolname[,$toolversion[,toolfile])>

Set up all selected tools in the current area or, if a tool name and version are provided,
set up only the specified tool.

=item C<arch()>

Return or set the architecture string.

=item C<webget($area,$url)>

Get the url into the cache of the specified area.

=item C<getversion()>

Return the current SCRAM version.

=item C<spawnversion($version,@args)>

Spawn the SCRAM version $version with the given args.

=item C<classverbose(classstring,setting)>

Set the class verbosity level.

=back

=head1 AUTHOR

Originally written by Christopher Williams.

=head1 MAINTAINER

Shaun ASHBY 

=cut

package SCRAM::ScramFunctions;
use URL::URLcache;
use Utilities::Verbose;
use Utilities::IndexedFileStore;

require 5.004;

@ISA=qw(Utilities::Verbose);

sub new
   {
   my $class=shift;
   $self={};
   bless $self, $class;
   # -- default settings
   $self->{cachedir}=$ENV{HOME}."/.scramrc/globalcache";
   $self->{scramprojectsdbdir}=$ENV{SCRAM_LOOKUPDB};
   ($self->{scram_top})=( $ENV{SCRAM_HOME}=~/(.*)\//) ;
   return $self;
   }

sub classverbose {
	my $self=shift;
	my $class=shift;
	my $val=shift;

	$ENV{"VERBOSE_".$class}=$val;
}

sub project {
	my $self=shift;
	my $url=shift;
	my $installarea=shift;

	my $areaname="";
	if ( @_ ) {
	  $areaname=shift;
	}
	require Configuration::BootStrapProject;
	my $bs=Configuration::BootStrapProject->
			new($self->globalcache(),$installarea);
	$self->verbose("BootStrapping $url");
	my $area=$bs->boot($url,$areaname);
	if ( ! defined $area ) {
		$self->error("Unable to create project area");
	}
	$area->archname($self->arch());

	# -- download all tool description files
	my $req=$self->arearequirements($area);
	$area->toolboxversion($req->{configversion});

	if ( defined $req ) {
	  $req->download($self->areatoolbox($area));
	}  

	return $area;
}

sub satellite
   {
   #
   # Modified to suit new structure
   #
   my $self=shift;
   my $name=shift;
   my $version=shift;
   my $installarea=shift; # Where to install (-dir option in project cmd);
   my $areaname=undef;    # Name of the area (comes from -name option in project cmd);

   use Utilities::AddDir;

   if ( @_ )
      {
      $areaname=shift;
      }

   # Get location from SCRAMDB:
   my $relarea=$self->_lookupareaindb($name,$version);

   if ( ! defined $relarea )
      {
      $self->error("Unable to Find Project $name $version");
      }
   
   # Create a satellite area:
   my $area=$relarea->satellite($installarea,$areaname);
   $area->archname($self->arch());

   # Copy the admin dir (and with it, the ToolCache):   
   $relarea->copywithskip($area->location(),'ProjectCache.db');

   # Also, we need to copy .SCRAM/cache from the release area. This eliminates the need
   # to download tools again from CVS:
   $relarea->copyurlcache($area->location());
   
   # Copy configuration directory contents:
   if ( ! -d $area->location()."/".$area->configurationdir() )
      {
      AddDir::copydir($relarea->location()."/".$relarea->configurationdir(),
		      $area->location()."/".$area->configurationdir() );
      }

   # Make sourcecode dir:
   if ( ! -d $area->location()."/".$area->sourcedir() )
      {
      AddDir::adddir($area->location()."/".$area->sourcedir());
      }

   # Copy RequirementsDoc:
   if ( ! -f $area->requirementsdoc() )
      {
      use File::Copy;
      copy( $relarea->requirementsdoc() , $area->requirementsdoc());
      }

   return $area;
   }

sub webget {
        my $self=shift;
        my $area=shift;
        my $url=shift;

	require URL::URLhandler;
        my $handler=URL::URLhandler->new($area->cache());
        return ($handler->download($url));
}

sub addareatoDB {
	my $self=shift;
	my $flag=shift;
	my $area=shift;
	my $tagname=shift;
        my $version=shift;

	# -- create defaults if necessary
	if ( (! defined $version)  || ( $version eq "") ) {
	   $version=$area->version();
	}
	if ( (! defined $tagname)  || ( $tagname eq "") ) {
	   $tagname=$area->name();
	}
	# -- Add to the DB
	$self->scramprojectdb()->addarea($flag,$tagname,$version,$area);
}


sub removeareafromDB
   {
   ###############################################################
   # removearefromDB()                                           #
   ###############################################################
   # modified : Thu Jun 14 10:46:22 2001 / SFA                   #
   # params   : projectname, projectversion                      #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Remove project <projectname> from DB file.       #
   #          :                                                  #
   #          :                                                  #
   ###############################################################
   my $self=shift;
   my $flag=shift;
   my $projname=shift;
   my $version=shift;
   
   # -- Remove from the DB:
   $self->scramprojectdb()->removearea($flag,$projname,$version);
   }


sub spawnversion
   {
   ###############################################################
   # spawnversion                                                #
   ###############################################################
   # modified : Fri Aug 10 15:42:08 2001 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   #          :                                                  #
   #          :                                                  #
   # function : Check for version of scram to run, and run it.   #
   #          :                                                  #
   #          :                                                  #
   ###############################################################
   my $self=shift;
   my $version=shift;
   my $rv=0;

   # getversion() returns the value of the SCRAM_VERSION environment
   # or otherwise figures it out from the path to SCRAM_HOME:
   my $thisversion=$self->getversion();
   if ( defined $version )
      {
      if ( $version ne $thisversion )
	 {
	 # first try to use the correct version
	 if ( -d $self->{scram_top}."/".$version )
	    {
	    $ENV{SCRAM_HOME}=$self->{scram_top}."/".$version;
	    $ENV{SCRAM_TOOL_HOME}="$ENV{SCRAM_HOME}/src";
	    $self->verbose("Spawning SCRAM version $version");
	    my $rv=system($ENV{SCRAM_HOME}."/src/main/scram.pl", @_)/256;
	    exit $rv;
	    }
	 else
	    {
	    # if not then simply warn. Send output to STDERR:
	    if ( -t STDERR )
	       {
	       print STDERR "******* Warning : scram version inconsistent ********\n";
	       print STDERR "This version: $thisversion; Required version: $version\n";
	       print STDERR "No SCRAM installation found under ".$self->{scram_top}."/$version\n";
	       print STDERR "*****************************************************\n";
	       print STDERR "\n";
	       }    
	    }
	 }
      }
   else
      {
      $self->error("Undefined value for version requested");
      $rv=1;
      }
   return $rv;
   }

sub globalcache {
	my $self=shift;
	if ( @_ ) {
	  $self->{cachedir}=shift;
	}
	if ( ! defined $self->{globalcache} ) {
	  $self->{globalcache}=URL::URLcache->new($self->{cachedir});
	}
	return $self->{globalcache};
}


sub scramprojectdb {
	my $self=shift;
	if ( @_ ) {
	  $self->{scramprojectsdbdir}=shift;
	}
        if ( ! defined $self->{scramprojectsdb} ) {
          require SCRAM::ScramProjectDB;
          $self->{scramprojectsdb}=SCRAM::ScramProjectDB->new(
    		           $self->{scramprojectsdbdir} );
	  $self->{scramprojectsdb}->verbosity($self->verbosity());
        }
        return $self->{scramprojectsdb};
}

sub getversion {
    my $self=shift;
    # Take the version from the environment var, set by assuming
    # that the version is the same as the CVS tag applied to SCRAM.pm
    # (a fair assumption, I'd say). If this isn't set or is empty
    # then extract a version from the SCRAM_HOME path:
    if (exists($ENV{SCRAM_VERSION}) && $ENV{SCRAM_VERSION} ne '') {
	return $ENV{SCRAM_VERSION};
    } else {
	my ($version,$scram_version);
	($scram_version=$ENV{SCRAM_HOME})=~s/(.*)\///;
	# deal with links
	my $version=readlink $ENV{SCRAM_HOME};
	if ( defined $version)  {
	    $scram_version=$version;
	}
	return $scram_version;
    }
}

sub scram_topdir() {
    my $self=shift;
    return $self->{scram_top};
}

sub areatoolmanager
   {
   my $self=shift;
   my $area=shift;
   
   my $name=$area->location();

   if ( ! defined $self->{toolmanagers}{$name} )
      {
      use BuildSystem::ToolManager;
      $self->{toolmanagers}{$name}=ToolManager->new($area,$self->arch());
      }
   
   return $self->{toolmanagers}{$name};
   }

sub arearequirements {
	my $self=shift;
	my $area=shift;

	my $name=$area->location();
	if ( ! defined $self->{requirements}{$name} ) {
	  # -- create a new toolbox object
	  require BuildSystem::Requirements;
	  my $doc=$area->requirementsdoc();
	  my $cache=$area->cache();
	  my $db=$area->objectstore();
	  require ActiveDoc::ActiveStore;
	  my $astore=ActiveDoc::ActiveStore->new($db,$cache);
	  $self->{requirements}{$name}=
		BuildSystem::Requirements->new($astore,"file:".$doc, 
			$ENV{SCRAM_ARCH});
	  $self->{requirements}{$name}->verbosity($self->verbosity());
	  $self->verbose("Requirements Doc (".$self->{requirements}{$name}.
				  ") for area :\n $name\n initiated from $doc");
	}
	else {
	  $self->verbose("Requirements Doc (".$self->{requirements}{$name}.")");
	}
	return $self->{requirements}{$name};
}

sub arch {
	my $self=shift;

	@_?$self->{arch}=shift
	  :$self->{arch};
}

sub _lookupareaindb {
        my $self=shift;

        my $area=undef;
        # -- Look up the area in the databse
        my @areas=$self->scramprojectdb()->getarea(@_);
        if ( $#areas > 0 ) { #ambigous
                # could ask user - for now just error
          $self->error("Ambigous request - please be more specific");
        }
        elsif ( $#areas != 0 ) { #not found
          $self->error("The project requested has not been found");
        }
        else {
          $area=$areas[0];
        }
        return $area;
}
