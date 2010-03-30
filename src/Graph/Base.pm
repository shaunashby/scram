package Graph::Base;
use strict;
local $^W = 1;
use vars qw(@ISA);
require Exporter;
@ISA = qw(Exporter);

sub new
   {
   my $class = shift;
   my $G = { };

   bless $G, $class;

   $G->add_vertices(@_) if @_;
   
   return $G;
   }

sub add_vertices
   {
   my ($G, @v) = @_;
   @{ $G->{ V } }{ @v } = @v;
   
   return $G;
   }

sub add_vertex
   {
   my ($G, $v) = @_;
   return $G->add_vertices($v);
   }

sub vertices
   {
   my $G = shift;
   my @V = exists $G->{ V } ? sort values %{ $G->{ V } } : ();
   
   return @V;
   }

sub has_vertex
   {
   my ($G, $v) = @_;
   return exists $G->{V}->{ $v };
   }

sub vertex
   {
   my ($G, $v) = @_;
   
   return $G->{ V }->{ $v };
   }

sub directed
   {
   my ($G, $d) = @_;
   
   if (defined $d)
      {
      if ($d)
	 {
	 my $o = $G->{ D }; # Old directedness.

	 $G->{ D } = $d;
	 if (not $o)
	    {
	    my @E = $G->edges;
	    
	    while (my ($u, $v) = splice(@E, 0, 2))
	       {
	       $G->add_edge($v, $u);
	       }
	    }

	 return bless $G, 'Graph::Directed'; # Re-bless.
	 }
      else
	 {
	 return $G->undirected(not $d);
	 }
      }
   
   return $G->{ D };
   }

sub undirected
   {
   my ($G, $u) = @_;
   $G->{ D } = 1 unless defined $G->{ D };

   if (defined $u)
      {
      if ($u)
	 {
	 my $o = $G->{ D }; # Old directedness.
	 
	 $G->{ D } = not $u;
	 if ($o)
	    {
	    my @E = $G->edges;
	    my %E;
	    
	    while (my ($u, $v) = splice(@E, 0, 2))
	       {
	       # Throw away duplicate edges.
	       $G->delete_edge($u, $v) if exists $E{$v}->{$u};
	       $E{$u}->{$v}++;
	       }
	    }
	 
	 return bless $G, 'Graph::Undirected'; # Re-bless.
	 }
      else
	 {
	 return $G->directed(not $u);
	 }
      }
   
   return not $G->{ D };
   }

sub _union_vertex_set
   {
   my ($G, $u, $v) = @_;
   
   my $su = $G->vertex_set( $u );
   my $sv = $G->vertex_set( $v );
   my $ru = $G->{ VertexSetRank }->{ $su };
   my $rv = $G->{ VertexSetRank }->{ $sv };
   
   if ( $ru < $rv )
      {	# Union by rank (weight balancing).
      $G->{ VertexSetParent }->{ $su } = $sv;
      }
   else
      {
      $G->{ VertexSetParent }->{ $sv } = $su;
      $G->{ VertexSetRank   }->{ $sv }++ if $ru == $rv;
      }
   }

sub vertex_set
   {
   my ($G, $v) = @_;
   
   if ( exists  $G->{ VertexSetParent }->{ $v } )
      {
      # Path compression.
      $G->{ VertexSetParent }->{ $v } =
	 $G->vertex_set( $G->{ VertexSetParent }->{ $v } )
	 if $v ne $G->{ VertexSetParent }->{ $v };
      }
   else
      {
      $G->{ VertexSetParent }->{ $v } = $v;
      $G->{ VertexSetRank   }->{ $v } = 0;
      }
   return $G->{ VertexSetParent }->{ $v };
   }

sub add_edge
   {
   my ($G, $u, $v) = @_;
   
   $G->add_vertex($u);
   $G->add_vertex($v);
   $G->_union_vertex_set( $u, $v );
   push @{ $G->{ Succ }->{ $u }->{ $v } }, $v;
   push @{ $G->{ Pred }->{ $v }->{ $u } }, $u;
   return $G;
   }

sub _successors
   {
   my ($G, $v) = @_;
   my @s =
      defined $G->{ Succ }->{ $v } ?
      map { @{ $G->{ Succ }->{ $v }->{ $_ } } }
      sort keys %{ $G->{ Succ }->{ $v } } :
      ( );
   
   return @s;
   }

sub _predecessors
   {
   my ($G, $v) = @_;
   my @p =
	defined $G->{ Pred }->{ $v } ?
	    map { @{ $G->{ Pred }->{ $v }->{ $_ } } }
                sort keys %{ $G->{ Pred }->{ $v } } :
            ( );

   return @p;
   }

sub neighbors
   {
   my ($G, $v) = @_;
   my @n = ($G->_successors($v), $G->_predecessors($v));
   return @n;
   }

use vars '*neighbours';
*neighbours = \&neighbors; # Keep both sides of the Atlantic happy.

sub successors
   {
   my ($G, $v) = @_;
   return $G->directed ? $G->_successors($v) : $G->neighbors($v);
   }

sub out_edges
   {
   my ($G, $v) = @_;
   return () unless $G->has_vertex($v);
   
   my @e = $G->_edges($v, undef);
   
   return wantarray ? @e : @e / 2;
   }

sub edges
   {
   my ($G, $u, $v) = @_;
   return () if defined $v and not $G->has_vertex($v);
   
   my @e =
      defined $u ?
	    ( defined $v ?
	      $G->_edges($u, $v) :
              ($G->in_edges($u), $G->out_edges($u)) ) :
	      $G->_edges;
   return wantarray ? @e : @e / 2;
   }

sub delete_edge
   {
   my ($G, $u, $v) = @_;
   pop @{ $G->{ Succ }->{ $u }->{ $v } };
   pop @{ $G->{ Pred }->{ $v }->{ $u } };
   
   delete $G->{ Succ }->{ $u }->{ $v }
   unless @{ $G->{ Succ }->{ $u }->{ $v } };
   delete $G->{ Pred }->{ $v }->{ $u }
   unless @{ $G->{ Pred }->{ $v }->{ $u } };
   
   delete $G->{ Succ }->{ $u }
   unless keys %{ $G->{ Succ }->{ $u } };
   delete $G->{ Pred }->{ $v }
   unless keys %{ $G->{ Pred }->{ $v } };
   
   return $G;
   }

sub out_degree
   {
   my ($G, $v) = @_;
   return undef unless $G->has_vertex($v);
   
   if ($G->directed)
      {
      if (defined $v)
	 {
	 return scalar $G->out_edges($v);
	 }
      else
	 {
	 my $out = 0;
	 
	 foreach my $v ($G->vertices)
	    {
	    $out += $G->out_degree($v);
	    }
	 return $out;
	 }
      }
   else
      {
      return scalar $G->edges($v);
      }
   }

sub copy
   {
   my $G = shift;
   my $C = (ref $G)->new($G->vertices);
   
   if (my @E = $G->edges)
      {
      while (my ($u, $v) = splice(@E, 0, 2))
	 {
	 $C->add_edge($u, $v);
	 }
      }
   
   $C->directed($G->directed);
   
   return $C;
   }

sub edge_classify
   {
   my $G = shift;
   my $unseen_successor =
      sub {
            my ($u, $v, $T) = @_;		
	    # Freshly seen successors make for tree edges.
	    push @{ $T->{ edge_class_list } },
	         [ $u, $v, 'tree' ];
	};
   my $seen_successor =
      sub {
	    my ($u, $v, $T) = @_;
			
	    my $class;
	
	    if ( $T->{ G }->directed )
	       {
	       $class = 'cross'; # Default for directed non-tree edges.
	       
	       unless ( exists $T->{ vertex_finished }->{ $v } )
		  {
		  $class = 'back';
		  }
	       elsif ( $T->{ vertex_found }->{ $u } <
			  $T->{ vertex_found }->{ $v })
		  {
		  $class = 'forward';
		  }
	       }
	    else
	       {
	       # No cross nor forward edges in
	       # an undirected graph, by definition.
	       $class = 'back';
	       }
	    
	    push @{ $T->{ edge_class_list } }, [ $u, $v, $class ];
	    };
   use Graph::DFS;
   my $d =
      Graph::DFS->
	    new( $G,
		 unseen_successor => $unseen_successor,
		 seen_successor   => $seen_successor,
		 @_);

   $d->preorder;

   return @{ $d->{ edge_class_list } };
   }

sub toposort
   {
   my $G = shift;
   my $d = Graph::DFS->new($G);
   $d->postorder; # That's it.
   }

sub largest_out_degree
   {
   my $G = shift;
   my @R = map { $_->[ 0 ] } # A Schwartzian Transform.
	        sort { $b->[ 1 ] <=> $a->[ 1 ] || $a cmp $b }
		     map { [ $_, $G->out_degree($_) ] }
			 @_;

   return $R[ 0 ];
   }

1;
