=head1 NAME

Utilities::DataItem - A data container with a list of lookup keys.

=head1 SYNOPSIS

	my $obj = Utilities::DataItem->new();

=head1 DESCRIPTION

A data container with a list of lookup keys.

=head1 METHODS

=over

=cut

=item C<new(data,@key)
   A new DataItem object with the data matched to a keylist (See also restore).
   
=item C<keys()>
   Return a list of the fundamental keys for the data object.

=item C<data()>
   Return the data for the object.

=item C<match(@keys)>
   Return 1 if @keys matches those of the data item, else 0.

=item C<alias(@keys)>
   Provide an alternative set of keys for matching.

=item C<unalias(@keys)>
   Remove any aliases. Original keys cannot be removed.
   Returns 1 if successful, 0 otherwise.
   
=item C<store(fh)>
   Store to the given stream.

=item C<restore(fh)>
   Returns a new dataitem, initialised to the data found in fh.

=back

=head1 AUTHOR
   
Originally Written by Christopher Williams.

=head1 MAINTAINER

Shaun ASHBY 

=cut
   
package Utilities::DataItem;
require 5.001;

sub new {
	my $class=shift;
	my $data=shift;
	my @keys=@_;

	$self={};
	bless $self, $class;
	$self->{data}=$data;
	push @{$self->{keys}[0]},@keys; # fundamental keys
	return $self;
}

sub keys {
	my $self=shift;
	return @{$self->{keys}[0]};
}

sub data {
	my $self=shift;
	return $self->{data};
}

sub match {
	my $self=shift;
	my @keys=@_;

	my $nm;

	# search over all key aliases
	foreach $keyset ( @{$self->{keys}} ) {
	 $nm=0;
	 for ( $i=0; (($i <= $#keys) && ($i <=$#{$keyset} )); $i++ ) {
	   if ( $$keyset[$i] eq $keys[$i] ) {
		$nm++;
	   }
	 }
	 return 1 , if ( $nm > $#keys ); # Succesful match
	}
	return 0;
}

sub alias {
	my $self=shift;
	my @keys=@_;

	if ( $#keys<0 ) {
	  die "Utilities::DataItem: Unable to set an alias with no keys\n";
	}
	push @{$self->{keys}},[@keys];
}

sub unalias {
	my $self=shift;
	my @keys=@_;

	my $rv=0;
	for ( my $i=1; $i<=$#{$self->{keys}}; $i++ ) {
	 if ( "@{$self->{keys}[$i]}" eq "@keys" ) {
	   undef $self->{keys}[$i];
	   splice( @{$self->{keys}}, $i, 1);
	   $rv=1;
	 }
	}
	return $rv;
}

sub store {
	my $self=shift;
	my $fh=shift;

	# print the keys first, aliases, then the data
	foreach $keyset ( @{$self->{keys}} ) {
	 foreach $key ( @{$keyset} ) {
	   print $fh "#".$key."\n";
	 }
	 print $fh "#\n"; # alias marker
	}
	print $fh ">".$self->data()."\n";
}

sub restore {
	my $class=shift;
        my $fh=shift;
	$self={};
	bless $self, $class;

	my @arr=();

	while ( <$fh> ) {
	  chomp;
	  if ( $_ eq "#") { # set aliases
	    $self->alias(@arr);
	    @arr=();
	  }
	  elsif ( $_=~/^#(.*)/ ) {
            push @arr, $1;
          }
	  elsif ( $_=~/^>(.*)/ ) { # load in data
            $data=$1;
            $self->{data}=$data;
	    last;
          }
	  else {
	    print "Data corruption detected\n";
	    last;
	  }
	}
	return $self;
}
