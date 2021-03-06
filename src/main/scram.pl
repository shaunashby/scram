#!/usr/bin/env perl
# -*-perl-*-
#____________________________________________________________________ 
# File: scram.pl
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2003-06-18 18:05:46+0200
# Revision: $Id: scram.pl.in,v 1.7 2007/02/27 17:02:14 sashby Exp $ 
#
# Copyright: 2003 (C) Shaun Ashby
#
#--------------------------------------------------------------------

=head1 NAME

scram.pl - The main SCRAM script.

=head1 SYNOPSIS

SCRAM is normally executed using the command "scram", which is a link from
the installation area to this script. Customisations like location of SCRAM
database, local architecture definition functions are defined during the
install process (see the documentation for Installation::SCRAM_SITE.pm.in).

=head1 DESCRIPTION

  
The recognised scram commands are

         scram version
         scram arch
         scram runtime
         scram config
         scram list
         scram db
         scram urlget
         scram project
         scram setup
         scram tool
         scram gui
         scram build
         scram install
         scram remove

Help on individual commands is available through

        scram <command> -help


Other commands:

=over

=item B<-help>

   Show this help page.

=item B<-verbose CLASS>

   Activate the verbose function on the specified class or list of classes.
   
=item B<-debug>
   
   Activate the verbose function on all SCRAM classes.    
   
=item B<-arch ARCHITECTURE>
   
   Set the architecture ID to that specified.             

=item B<-noreturn>

   Pause after command execution rather than just exitting.

=back

=head1 COMMAND HELP

The recognised SCRAM commands are described below.
   
=over
   
=item B<version>

With no version argument given, this command will simply show
the current version number.
If a version argument is supplied, that version will be downloaded and
installed, if not already locally available.

Usage:
        B<scram version [-c] [-i] [-h] [<version>]>

The -i option shows CVS commit info (the value of the CVS Id variable).
The -c option prints site CVS parameters to STDOUT. These parameters are used
when downloading and installing new SCRAM versions.
   
=item B<arch>

Print out the architecture flag for the current machine.

Usage:
        B<scram arch>
or
        B<scram -arch <architecture>>

to set the architecture to that specified.
   
=item B<runtime>

Print the runtime environment for the current development area
in csh, sh or Windows flavours. 

Usage:
         B<scram runtime [-csh -sh -win]>
         B<scram runtime [-csh -sh -win] -file filename>
         B<scram runtime [-csh -sh -win] -file filename -info variable>
         B<scram runtime [-csh -sh -win] -dump filename>

=head3 Examples

Set up to include the project runtime settings
in the current TCSH shell environment:

        eval scram runtime -csh

Set up to include the project runtime settings
in a BASH/SH environment:-

        eval scram runtime -sh

To dump this environment to a file which can be sourced later, use

        scram runtime -sh -dump env.sh

=item B<config>
   
Dump configuration information for the current project area.

Usage:
        B<scram config [--tools] [--full]>

The --tools option will dump a list of configured tools, rather like "tool info",
but in a format parseable by external scripts. This could be used to create RPM/TAR files
of external products required by the project.

The format of each line of output is:

<tool name>:<tool version>:scram project[0/1]:<base path>:<dependencies>

<base path> can have the value <SYSTEM> if located in system directories (e.g., /lib).

<dependencies> will be set to <NONE> if there are no external dependencies for this tool.

The --full option will list the tool info and project information too.

=item B<list>

List the available projects and versions installed in the
local SCRAM database (see "scram install help").

Usage:
        B<scram list [-c] [-h] [--oldstyle] [<projectname>]>

Use the -c option to list the available projects and versions installed in the local
SCRAM database without fancy formatting or header strings.
The project name, version and installation directory are printed on STDOUT, separated
by spaces for use in scripts.

Use the --oldstyle option to show all projects from all versions (i.e. pre-V1) of SCRAM
(by default, only projects built and installed with V1x will be listed).

=item B<db>

SCRAM database administration command.

Usage:
        B<scram db <subcommand>>

Valid subcommands are:

-link
        Make available an additional database for project and
        list operations, e.g.

        scram db link  /a/directory/path/project.lookup

-unlink
        Remove a database from the link list. Note this does
        not remove the database, just the link to it in SCRAM.

        scram db unlink  /a/directory/path/project.lookup

-show
        List the databases that are linked in.

   
=item B<urlget>

Retrieve URL information. For example, show location in the cache
of a local copy of a Tool Document.

Usage:
        B<scram urlget [-h] <url>>
   
=item B<project>

Set up a new project development area or update an existing one. A new area
will appear in the current working directory by default.

Usage:
	B<scram project [-t] [-d <area>] [-n <dir>] [-f <tools.conf>] <projecturl> [<projectversion>]>

	B<scram project -update [<projectversion>]>

Options:

<projecturl>:
	The URL of a SCRAM bootstrap file.

<projectversion>:
	Only for use with a database label.

-d <area>:
	Indicate a project installation area into which the new
	project area should appear. Default is the current working
	directory.

-n <dir>:
	Specify the name of the SCRAM development area you wish to
	create.


Currently supported URL types are:

database label	Labels can be assigned to installed releases of projects for easy
                access (See "scram install" command). If you specify a label you
                must also specify a project version. This command is normally used
                to create cloned developer areas.

-b <file>	A bootstrap file on an accessible file system. This command would
                be used to create a project area from scratch on a laptop or to
                create a release area.

=head3 Examples

	scram project XX XX_9_0

	scram project -b ~/myprojects/projecta/config/boot.xml 


Use the "-f" flag followed by a valid filename (which MUST end in ".conf") to
allow auto setup to proceed without reading files from a repository (STANDALONE mode).

Some project template files can be obtained using the command:

	scram project -template

The templates will be copied to a directory called "config" in the current directory.

An existing developer area for a project can be updated to a more recent version of
the SAME project by running "scram project -update <VERSION>" in the developer area.
If no VERSION is given, the command is considered like a query and will return a list
of project versions which are compatible with the configuration of the current area.

A subsequent invocation of the command with a valid VERSION will then update the area
to that version.

   
=item B<setup>

Allows installation/re-installation of a new tool/external package into an
already existing development area. If no toolname is specified,
the complete installation process is initiated.

Usage:
        B<scram setup [-i] [toolname] [[version] [url]] [-f tools.conf]>

toolname:
        The name of the tool to be set up.

version:
        The version of the tool to set up.

url:
        URL (file: or http:) of the tool document describing the tool being set up.

The -i option turns off the automatic search mechanism allowing for more
user interaction during setup.

The -f option allows the user to specify a tools file (the filename MUST end
in ".conf"). This file contains values to be used for settings of the tool.

   
=item B<tool>

Manage the tools in the current SCRAM project area.

Usage:

        B<scram tool <subcommand> >

where valid tool subcommands and arguments are:

list 
        List of configured tools available in the current SCRAM area.

info <tool_name> 
        Print out information on the specified tool in the current area.

tag <tool_name> <tag_name> 
        Print out the value of a variable (tag) for the specified tool in the
        current area configuration. If no tag name is given, then all known tag
        names are printed to STDOUT.

remove <tool_name> 
        Remove the specified tool from the current project area.

template <TYPE> 
        Create a template tool description file of type <TYPE>,
        where <TYPE> can be either "compiler" or "basic" depending on whether the
        template is for a compiler or for a basic tool.
        The template will be created in the current directory.

   
=item B<gui>

Allow user interaction with the build Metadata.

Usage:
        B<scram gui -edit [class]>
        B<scram gui -show [meta type]>

=item B<build>

Run compilation in the current project area.

Usage:
        B<scram [--debug] build [options] [makeopts] <TARGET>>

--debug can be used to turn on full SCRAM debug output.

The following long options are supported (can be abbreviated to '-x'):

--help               show this help message.
--verbose            verbose mode. Show cache scan progress and compilation cmds (will
                     automatically set SCRAM_BUILDVERBOSE to TRUE)
--testrun            do everything except run gmake.
--reset              reset the project caches and rescan/rebuild.
--fast               skip checking the cache and go straight to building.
--writegraphs=<g|p>  enable creation of dependency graphs. Set this to 'global' (g)
                     if you want to create project-wide dependency graphs or
                     'package' (p) for package-level graphs. The graphs will be
                     stored in the project working directory. If you set the environment
                     variable SCRAM_WRITEGRAPHS=X (where X is PS/JPEG/GIF), SCRAM will
                     automatically create the graphs in format X.

                     Note that you must have AT&T's Dot program installed and in
                     your path to be able to use this feature.

=head3 Example

To refresh the current area cache, produce global dependency graphs but not run gmake

        scram build -r -w=g -t

Make option flags can be passed to gmake at build-time: the supported options are

 -n               print the commands that would be executed but do not run them
 --printdir       print the working directory before and after entering it
 --printdb        print the data base of rules after scanning makefiles, then build as normal
 -j <n>           the number of processes to run simultaneously
 -k               continue for as long as possible after an error
 -s               do not print any output
 -d               run gmake in debug mode

=item B<install>

Associates a label with the current release in the SCRAM database.
This allows other users to refer to a centrally installed project by
this label rather than a remote url reference.

Usage:
        B<scram install [-f] [<project_tag> [<version_tag>]] >

The -f flag can be used to force an installation of a project, overwriting any entries
with the same project name and version (useful in batch processing).

<project_tag>:

        override default label (the project name of the current release)

<version_tag>:

        the version tag of the current release. If version is not
        specified the base release version will be taken by default.

=item B<remove>

Remove a project entry from SCRAM database file ("project.lookup").

Usage:
        B<scram remove [-f] [<projectname>] [projectversion]>

The -f flag can be used to force removal of a project, not prompting the user for
confirmation (useful in batch processing).

=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY 

=cut

BEGIN
   {
   # Set the path to local modules. Install dir is usually
   # SCRAM_HOME/src:
   unshift @INC,'/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0', '/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0/src';
   }

use Installation::SCRAM_SITE;
use SCRAM::SCRAM;
use Getopt::Long ();

#### Core settings ####
$main::bold = "";
$main::normal = "";
$main::line = "-"x80;
$main::lookupdb = "";
$main::error = "";
$main::good = "";
$main::prompt="";

# Test whether the output from SCRAM is being redirected, or
# not (prevents escape signals from being printed to STDOUT if
# STDOUT is redirected to a file or piped):
if ( -t STDIN && -t STDOUT && $^O !~ /MSWin32|cygwin/ )
   {
   $bold = "\033[1m";
   $normal = "\033[0m";
   $prompt = "\033[0;32;1m";
   $fail = "\033[0;31;1m"; # Red
   $pass = "\033[0;33;1m"; # Yellow
   $good = $bold.$pass;    # Status messages ([OK])
   $error = $bold.$fail;   #                 ([ERROR])
   }

# Start a SCRAM session:
$scram = SCRAM::SCRAM->new();

# Getopt option variables:
my %opts;
my %options =
   ("verbose=s"	        => sub { $ENV{SCRAM_VERBOSE} = $ENV{SCRAM_DEBUG} = 1; $scram->classverbosity($_[1]) },
    "debug"		=> sub { $ENV{SCRAM_DEBUG} = 1; $scram->fullverbosity() },
    "arch=s"		=> sub { $ENV{SCRAM_ARCH} = $_[1]; $scram->architecture($ENV{SCRAM_ARCH}) },
    "noreturn"          => sub { $opts{SCRAM_NORETURN} = 1 }, # Pause after returning (for download in NS)
    "force"             => sub { $opts{SCRAM_FORCE} = 1 }, # A force flag for commands that might need it
    "help"		=> sub { $opts{SCRAM_HELP} = 1 }
    );

# Get the options using Getopt:
Getopt::Long::config qw(default no_ignore_case require_order);

if (! Getopt::Long::GetOptions(\%opts, %options))
   {
   $scram->scramfatal("Error parsing arguments. See \"scram help\" for usage info.");
   exit(1);
   }

# Check for a valid command and execute it or show an error message:
my $command=shift(@ARGV);

# Handle help option:
if ($opts{SCRAM_HELP} || ! $command)
   {
   print $scram->usage();
   exit(0);
   }

# Now execute the desired command (the routine automatically
# checks to make sure the command is valid):
my $retval = $scram->execcommand($command,@ARGV);

# Check to see if we have --noreturn set. If so, we may be running
# as a helper application in a web browser:
if ($opts{SCRAM_NORETURN})
   {
   print "\n";
   my $dummy = <STDIN>;
   }

exit($retval);
#### End of SCRAM script ####
