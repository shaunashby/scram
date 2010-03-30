#____________________________________________________________________ 
# File: SCRAMGrapher.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2004-06-30 11:01:02+0200
# Revision: $Id: SCRAMGrapher.pm,v 1.2 2004/12/10 13:41:37 sashby Exp $ 
#
# Copyright: 2004 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package BuildSystem::SCRAMGrapher;
require 5.004;
use Exporter;

@ISA=qw(Exporter);
@EXPORT_OK=qw();

sub new()
  ###############################################################
  # new                                                         #
  ###############################################################
  # modified : Wed Jun 30 11:01:31 2004 / SFA                   #
  # params   :                                                  #
  #          :                                                  #
  # function :                                                  #
  #          :                                                  #
  ###############################################################
  {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my ($depdata)=@_;
  my $self={};                            
  bless $self,$class;
  # The dependencies will either be collected via methods in this object or
  # as input:
  $self->{DEPENDENCIES} = $depdata;
  $self->{DEPENDENCIES} ||= {};
  return $self;
  }

sub vertex()
   {
   my $self=shift;
   my ($start) = @_;
   $self->{DEPENDENCIES}->{$start} = {};
   return $self;
   }

sub edge()
   {
   my $self=shift;
   my ($start,$end)=@_;
   # $start is a VERTEX. Add package $end to the hash of deps in
   # the DEPENDENCIES hash:
   $self->{DEPENDENCIES}->{$start}->{$end} = 1;
   }

sub _graph_init()
   {
   my $self=shift;
   # If a graph object already exists (e.g. when SCRAMGrapher has
   # been cloned), add new vertices/edges. Otherwise, start with
   # a new Graph object:
   if (exists ($self->{GRAPH}))
      {
      my $vertices = [ keys %{$self->{DEPENDENCIES}} ];

      # Loop over vertices:
      foreach my $package (@$vertices)
	 {
	 # Add this vertex:
	 $self->{GRAPH}->add_vertex($package);
	 # For each edge from this vertex, add an edge:
	 foreach my $dep (keys %{$self->{DEPENDENCIES}->{$package}})
	    {
	    $self->{GRAPH}->add_edge($package,$dep);
	    }
	 }
      }
   else
      {
      # Init the graph with the array of vertices:
      my $vertices = [ keys %{$self->{DEPENDENCIES}} ];
      use Graph::Graph;
      # Init a Graph object passing the list of vertices (this saves
      # N_vertex calls to add_vertex()):
      my $g = Graph->new(@$vertices);
      
      # Loop over vertices:
      foreach my $package (@$vertices)
	 {
	 # For each edge from this vertex, add an edge:
	 foreach my $dep (keys %{$self->{DEPENDENCIES}->{$package}})
	    {
	    $g->add_edge($package,$dep);
	    }
	 }
      # Store the Graph object:
      $self->{GRAPH} = $g;
      }
   }

sub sort()
   {
   my $self=shift;
   # Get a graph object:
   $self->_graph_init();
   # Perform topological (depth-first) sort and return:
   $self->{SORTED} = [ $self->{GRAPH}->toposort() ];
   return $self->{SORTED};
   }

sub graph_write()
   {
   my $self=shift;
   my ($data,$name)=@_;
   my $dir = $ENV{LOCALTOP}.'/'.$ENV{SCRAM_INTwork};
   
   use Graph::Writer::SCRAMDot;
   my $writer = Graph::Writer::SCRAMDot->new();

   $name =~ s|/|_|g;
   # Filename (without the .dot):
   $filename = $dir.'/'.$name;
   # Set attributes where there's data available from
   # a DataCollector (in local graphing only)
   # In globale graphing we set a default colour, shape etc.
   # in the SCRAMDot::write_graph() routine:
   $writer->attribute_data($data);
   $writer->write_graph($self->{DEPENDENCIES}, $filename);

   return $self;
   }

sub copy()
   {
   my $self=shift;
   # First, we need to translate the DEPENDENCIES into a Graph object which
   # will be stored in $self->{GRAPH}:
   $self->_graph_init();
   # Need to return new SCRAMGrapher object with copy of G:
   my $sgcopy = ref($self)->new();
   # Make a copy of the graph and set G to point to this:
   $sgcopy->{GRAPH} = $self->{GRAPH}->copy();
   # Reset the DEPENDENCIES store (we already have the copied vertices/edges stored):
   $sgcopy->{DEPENDENCIES} = {};
   # Return the new SCRAMGrapher object:
   return $sgcopy;
   }

1;
