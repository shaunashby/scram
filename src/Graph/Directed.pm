package Graph::Directed;
use strict;
local $^W = 1;
use Graph::Base;
use vars qw(@ISA);
@ISA = qw(Graph::Base);

sub new
   {
   my $class = shift;
   my $G = Graph::Base->new(@_);
   
   bless $G, $class;
   $G->directed(1);
   return $G;
   }

sub _edges
   {
   my ($G, $u, $v) = @_;
   my @e;
   
   if (defined $u and defined $v)
      {
      @e = ($u, $v)
	 if exists $G->{ Succ }->{ $u }->{ $v };
      }
   elsif (defined $u)
      {
      foreach $v ($G->successors($u))
	 {
	 push @e, $G->_edges($u, $v);
	 }
      }
   elsif (defined $v)
      {	# not defined $u and defined $v
      foreach $u ($G->predecessors($v))
	 {
	 push @e, $G->_edges($u, $v);
	 }
      }
   else
      { 			# not defined $u and not defined $v
      foreach $u ($G->vertices)
	 {
	 push @e, $G->_edges($u);
	 }
      }
   
   return @e;
   }

1;
