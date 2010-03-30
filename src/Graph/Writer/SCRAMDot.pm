#____________________________________________________________________ 
# File: SCRAMDot.pm
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2004-07-21 13:50:11+0200
# Revision: $Id: SCRAMDot.pm,v 1.3 2005/02/02 16:31:12 sashby Exp $ 
#
# Copyright: 2004 (C) Shaun Ashby
#
#--------------------------------------------------------------------
package Graph::Writer::SCRAMDot;
use strict;
use vars qw(@ISA $VERSION);

sub new()
   ###############################################################
   # new                                                         #
   ###############################################################
   # modified : Thu Sep 30 16:38:31 2004 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   {
   my $proto=shift;
   my $class=ref($proto) || $proto;
   my $self={};
   bless $self,$class;
   return $self;
   }

sub write_graph()
   {
   my $self=shift;
   my ($data, $name) =@_;

   open(GRAPH, "> $name.dot") || die "$!","\n";
   
   print GRAPH "digraph G\n";
   print GRAPH "{\n\n";
   print GRAPH "ratio=compress;\n";
   print GRAPH "/* list of nodes */\n";
   print GRAPH "\n\n";

   foreach my $p ( keys %{$data} )
      {
      if (exists($self->{ATTRIBUTES}->{$p}))
	 {
	 print GRAPH "\"$p\"".$self->{ATTRIBUTES}->{$p}.";","\n";
	 }
      else
	 {
	 print GRAPH "\"$p\"".$self->{ATTRIBUTES}->{GLOBALDEFAULT}($p).";","\n";
	 }
      }
   
   print GRAPH "\n\n";   
   print GRAPH "/* list of edges */\n\n";
   
   foreach my $p ( keys %{$data} )
      {
      foreach my $d ( keys %{$data->{$p}} )
	 {
	 print GRAPH "\"$p\" -> \"$d\";","\n";
	 }
      }
   
   print GRAPH "}\n";
   
   if ($ENV{SCRAM_WRITEGRAPHS})
      {
      my $type=$ENV{SCRAM_WRITEGRAPHS};
      $type =~ tr[A-Z][a-z];
      
      if ($type =~ /jp/) # JPEG gives ttfont warnings
	 {
	 print "write_graph(): The following output is from AT&T Graphvizs \"DOT\" program. These","\n";
	 print "write_graph(): are probably not serious messages...","\n";
	 }
      
      # Run dot to actually produce the diagrams:
      system("dot","-T".$type,"-o",$name.".$type",$name.".dot");
      }
   }

sub attribute_data()
   {
   my $self=shift;
   my ($data)=@_;
   my ($type,$p);
   $self->{ATTRIBUTES} = {};
   my $style =
      {
      LOCAL   => { 'color' => 'yellow', 'shape' => 'box', 'style' => 'filled', 'label' => '' },
      RELEASE => { 'color' => 'yellow4', 'shape' => 'box', 'style' => 'filled', 'label' => '' },
      REMOTE  => { 'color' => 'goldenrod2', 'shape' => 'box', 'style' => 'filled', 'label' => '' },
      TOOLS   => { 'color' => 'lightsalmon', 'shape' => 'ellipse', 'style' => 'filled', 'label' => '' }
      };

   # Set a default attribute string:
   $self->{ATTRIBUTES}->{GLOBALDEFAULT} = sub
      {
      return  " [style = \"filled\", label = \"".$_[0]."\", shape = \"box\", color = \"yellow\"]";
      };
   
   foreach $type (qw( LOCAL RELEASE REMOTE TOOLS ))
      {
      foreach $p (@{$data->{$type}})
	 {
	 $style->{$type}->{'label'} = "$p";
	 $self->{ATTRIBUTES}->{$p} = " [".join(",", map { "$_ = \"$style->{$type}->{$_}\"" } keys %{$style->{$type}})."]";
	 }
      }
   }

1;
