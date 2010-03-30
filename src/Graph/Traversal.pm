package Graph::Traversal;
use strict;
local $^W = 1;
use Graph::Base;
use vars qw(@ISA);
@ISA = qw(Graph::Base);

sub new
   {
   my $class  = shift;
   my $G      = shift;
   my $S = { G => $G }; 
   bless $S, $class;
   $S->reset(@_);
   return $S;
   }

sub reset
   {
   my $S = shift;
   my $G = $S->{ G };
   
   @{ $S->{ pool } }{ $G->vertices } = ( );
   $S->{ active_list       }         = [ ];
   $S->{ root_list         }         = [ ];
   $S->{ preorder_list     }         = [ ];
   $S->{ postorder_list    }         = [ ];
   $S->{ active_pool       }         = { };
   $S->{ vertex_found      }         = { };
   $S->{ vertex_root       }         = { };
   $S->{ vertex_successors }         = { };
   $S->{ param             }         = { @_ };
   $S->{ when              }         = 0;
   }

sub _get_next_root_vertex
   {
   my $S      = shift;
   my %param  = ( %{ $S->{ param } }, @_ ? %{ $_[0] } : ( ));
   my $G      = $S->{ G };
   
   if ( exists $param{ get_next_root } )
      {
      if ( ref $param{ get_next_root } eq 'CODE' )
	 {
	 return $param{ get_next_root }->( $S, %param ); # Dynamic.
	 }
      else
	 {
	 my $get_next_root = $param{ get_next_root };	# Static.

	 # Use only once.
	 delete $S->{ param }->{ get_next_root };
	 delete $_[0]->{ get_next_root } if @_;
	 
	 return $get_next_root;
	 }
      }
   else
      {
      return $G->largest_out_degree( keys %{ $S->{ pool } } );
      }
   }

sub _mark_vertex_found
   {
   my ( $S, $u ) = @_;
   
   $S->{ vertex_found }->{ $u } = $S->{ when }++;
   delete $S->{ pool }->{ $u };
   }

sub _next_state
   {
   my $S = shift;	# The current state.
   my $G = $S->{ G };	# The current graph.
   my %param = ( %{ $S->{ param } }, @_);
   my ($u, $v);	# The current vertex and its successor.
   my $return = 0;	# Return when this becomes true.
   
   until ( $return )
      {
      # Initialize our search when needed.
      # (Start up a new tree.)
      unless ( @{ $S->{ active_list } } )
	 {
	 do
	    {
	    $u = $S->_get_next_root_vertex(\%param);
	    return wantarray ? ( ) : $u unless defined $u;
	    } while exists $S->{ vertex_found }->{ $u };

	 # A new root vertex found.
	 push @{ $S->{ active_list } }, $u;
	 $S->{ active_pool }->{ $u } = 1;
	 push @{ $S->{ root_list   } }, $u;
	 $S->{ vertex_root }->{ $u } = $#{ $S->{ root_list } };
	 }

      # Get the current vertex.
      $u = $param{ current }->( $S );
      return wantarray ? () : $u unless defined $u;
      
      # Record the vertex if necessary.
      unless ( exists $S->{ vertex_found }->{ $u } )
	 {
	 $S->_mark_vertex_found( $u );
	 push @{ $S->{ preorder_list } }, $u;
	 # Time to return?
	 $return++ if $param{ return_next_preorder };
	 }

      # Initialized the list successors if necessary.
      $S->{ vertex_successors }->{ $u } = [ $G->successors( $u ) ]
	 unless exists $S->{ vertex_successors }->{ $u };

      # Get the next successor vertex.
      $v = shift @{ $S->{ vertex_successors }->{ $u } };
      
      if ( defined $v )
	 {
	 # Something to do for each successor?
	 $param{ successor }->( $u, $v, $S )
	    if exists $param{ successor };

	 unless ( exists $S->{ vertex_found }->{ $v } )
	    {
	    # An unseen successor.
	    $S->_mark_vertex_found( $v );
	    push @{ $S->{ preorder_list } }, $v;
	    $S->{ vertex_root }->{ $v } = $S->{ vertex_root }->{ $u };
	    push @{ $S->{ active_list } }, $v;
	    $S->{ active_pool }->{ $v } = 1;
	    
	    # Something to for each unseen edge?
	    # For multiedges, triggered only for the first edge.
	    $param{ unseen_successor }->( $u, $v, $S )
	       if exists $param{ unseen_successor };
	    }
	 else
	    {
	    # Something to do for each seen edge?
	    # For multiedges, triggered for the 2nd, etc, edges.
	    $param{ seen_successor }->( $u, $v, $S )
	       if exists $param{ seen_successor };
	    }
	 
	 # Time to return?
	 $return++ if $param{ return_next_edge };
	 
	 }
      elsif ( not exists $S->{ vertex_finished }->{ $u } )
	 {
	 # Finish off with this vertex (we run out of descendants).
	 $param{ finish }->( $S );
	 $S->{ vertex_finished }->{ $u } = $S->{ when }++;
	 push @{ $S->{ postorder_list } }, $u;
	 delete $S->{ active_pool }->{ $u };
	 
	 # Time to return?
	 $return++ if $param{ return_next_postorder };
	 }
      }
   
   # Return an edge if so asked.
   return ( $u, $v ) if $param{ return_next_edge };
   
   # Return a vertex.
   return $u;
   }

sub next_preorder
   {
   my $S = shift;
   $S->_next_state( return_next_preorder => 1, @_ );
   }

sub next_postorder
   {
   my $S = shift;
   $S->_next_state( return_next_postorder => 1, @_ );
   }

sub next_edge
   {
   my $S = shift;
   $S->_next_state( return_next_edge => 1, @_ );
   }

sub preorder
   {
   my $S = shift;
   1 while defined $S->next_preorder;  # Process entire graph.
   return @{ $S->{ preorder_list } };
   }

sub postorder
   {
   my $S = shift;
   1 while defined $S->next_postorder; # Process entire graph.
   return @{ $S->{ postorder_list } };
   }

sub edges
   {
   my $S = shift;
   my (@E, $u, $v);
   push @E, $u, $v while ($u, $v) = $S->next_edge;
   return @E;
   }

sub roots
   {
   my $S = shift;
   
   $S->preorder
	unless exists $S->{ preorder_list } and
	       @{ $S->{ preorder_list } } == $S->{ G }->vertices;
   return @{ $S->{ root_list } };
   }

sub vertex_roots
   {
   my $S = shift;
   my $G = $S->{ G };
   
   $S->preorder
      unless exists $S->{ preorder_list } and
	       @{ $S->{ preorder_list } } == $G->vertices;
   return 
      map { ( $_, $S->{ vertex_root }->{ $_ } ) } $G->vertices;
   }

sub DELETE
   {
   my $S = shift;
   delete $S->{ G }; # Release the graph.
   }

1;
