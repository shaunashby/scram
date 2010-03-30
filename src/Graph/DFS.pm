package Graph::DFS;
use strict;
local $^W = 1;
use Graph::Traversal;
use vars qw(@ISA);
@ISA = qw(Graph::Traversal);

sub new
   {
   my $class = shift;
   my $graph = shift;
   
   Graph::Traversal::new( $class,
			  $graph,
			  current =>
			  sub { $_[0]->{ active_list }->[ -1 ] },
			  finish  =>
			  sub { pop @{ $_[0]->{ active_list } } },
			  @_);
   }

1;
