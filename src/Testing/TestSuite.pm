#____________________________________________________________________ 
# File: TestSuite.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2005-08-17 15:49:06+0200
# Revision: $Id: TestSuite.pm,v 1.5 2007/02/27 13:34:49 sashby Exp $ 
#
# Copyright: 2005 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package TestSuite;

=head1 NAME

TestSuite - A package to contain testing routines for each SCRAM command.

=head1 SYNOPSIS

	my $obj = TestSuite->new();
        $obj->run();
        $obj->statusreport();

=head1 DESCRIPTION

A testing utility. This runs the installed scram script B<scram.pl> using
B<system()>, passing whichever arguments are needed. Each command has a
self-contained set of tests in its own subroutine in this package to fully
exercise all supported options.

This package is used only by the test script B<testsuite.pl> found in the
Testing directory.

When a new command or command option is introduced, a subroutine in this package
must be created (or modified, if an option is added) to define a test.

=head1 METHODS

=over

=cut

require 5.004;
use Exporter;
use Installation::SCRAM_SITE;
use SCRAM::SCRAM;
use Cwd;

@ISA=qw(Exporter);
@EXPORT_OK=qw( );


sub new()
   {
   ###############################################################
   # new                                                         #
   ###############################################################
   # modified : Wed Aug 17 15:49:14 2005 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   my $proto=shift;
   my $class=ref($proto) || $proto;
   my $self={};
   bless $self,$class;
   $self->{TESTREPORT}={};
   $self->{SCRAM} = SCRAM::SCRAM->new();
   $self->{COMMANDS} = $self->{SCRAM}->commands();
   $self->{SCRAMMAIN} = $ENV{'SCRAM_HOME'}."/src/main/scram.pl";

   # Check to make sure that SCRAM installation has already been done:
   die "SCRAM TestSuite: Unable to find the installed scram script!","\n"
      if (! -f $self->{SCRAMMAIN});
   $self->init_();
   return $self;
   }

sub init_()
   {
   my $self=shift;
   
   # Set up parameters needed for the tests:
   my $SANDBOX=cwd()."/SandBoxForTestSuite";
   # Get rid of existing dir:
   if ( -d $SANDBOX )
      {
      system("rm","-rf",$SANDBOX);      
      }
   
   # Create new sandbox:
   mkdir($SANDBOX);
   mkdir($SANDBOX."/scramdb");
   $self->{WORKDIR} = $SANDBOX;
   chdir($self->{WORKDIR});
   $self->{PROJECTNAME} = "SCRAMTestSuite";
   $self->{PROJECTVERSION} = "1.0";
   $self->{PROJECTFULLNAME} = $self->{PROJECTNAME}."_".$self->{PROJECTVERSION};
   $self->{PROJECTINSTALLNAME} = "SCRAMtsdev";

   # Override the installation project db:
   $ENV{SCRAM_USERLOOKUPDB} = $self->{WORKDIR}."/scramdb/project.lookup";
   system("touch",$ENV{SCRAM_USERLOOKUPDB});
   }

sub run()
   {
   my $self=shift;
   map { print "-> Running test for \"".$_."\" command\n\n"; $self->$_(); }
   @{$self->{COMMANDS}};
   }

sub statusreport()
   {
   my $self=shift;
   print "\n";
   foreach my $cmd (keys %{$self->{TESTREPORT}})
      {
      print "Report for ".uc($cmd)." tests:","\n";

      foreach my $detail (@{$self->{TESTREPORT}->{$cmd}})
	 {
	 print "\t".$detail->[0]." (status = ".$detail->[1].")","\n";
	 }
      print "\n";
      }
   
   }

sub log()
   {
   my $self=shift;
   my ($cmd,$message,$status)=@_;

   if (exists($self->{TESTREPORT}->{$cmd}))
      {
      push(@{$self->{TESTREPORT}->{$cmd}},[ $message, $status ]);
      }
   else
      {
      $self->{TESTREPORT}->{$cmd} = [ [ $message, $status ] ];
      }
   }


#### Command Routines ####
sub version()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"version","-h");
   $self->log("version","Test of help functionality", $status);
   my $status = system($self->{SCRAMMAIN},"version","-c");
   $self->log("version","Test of \"-c\" argument", $status);
   my $status = system($self->{SCRAMMAIN},"version","-i");
   $self->log("version","Test of \"-i\" argument", $status);
   }

sub arch()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"arch","-h");
   $self->log("arch","Test of help functionality", $status);
   my $status = system($self->{SCRAMMAIN},"-arch","TEST_ARCHITECTURE","arch");
   $self->log("arch","Test of -arch argument", $status);
   }

sub urlget()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"urlget","-h");
   $self->log("urlget","Test of help functionality", $status);
   }

sub list()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"list","-h");
   $self->log("list","Test of help functionality", $status);

      
   $ENV{SCRAM_USERLOOKUPDB} = "";
   }

sub db()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"db","-h");
   $self->log("db","Test of help functionality", $status);

   
   
   }





sub project()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"project","-h");
   $self->log("project","Test of help functionality", $status);

   # Copy the config and toolbox to the sandbox dir:
   system("cp","-r","../config",".");
   system("cp","-r","../SCRAMToolBox",".");
   
   # Create a new project:
   my $status = system($self->{SCRAMMAIN},"project","-b","config/bootfile.test");
   $self->log("project","Test creating new project areas", $status);
   chdir($self->{PROJECTFULLNAME});
   # Install it:
   my $status = system($self->{SCRAMMAIN},"install");
   $self->log("install","Test installing new project areas", $status);

   # Create a developer area, rename it, install it in a different directory:
   
   # Remove project from database:
   

   }

sub runtime()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"runtime","-h");
   $self->log("runtime","Test of help functionality", $status);


   }

sub config()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"config","-h");
   $self->log("config","Test of help functionality", $status);

   
   }

sub setup()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"setup","-h");
   $self->log("setup","Test of help functionality", $status);   
   }

sub tool()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"tool","-h");
   $self->log("tool","Test of help functionality", $status);   

   }

sub gui()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"gui","-h");
   $self->log("gui","Test of help functionality", $status);   
   }

sub build()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"build","-h");
   $self->log("build","Test of help functionality", $status);   
   }

sub install()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"install","-h");
   $self->log("install","Test of help functionality", $status);
   }

sub remove()
   {
   my $self=shift;
   my $status = system($self->{SCRAMMAIN},"remove","-h");
   $self->log("remove","Test of help functionality", $status);
   }


1;

__END__


=back

=head1 AUTHOR/MAINTAINER

Shaun Ashby

=cut

