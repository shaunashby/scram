=head1 NAME

Utilities::HashDB - A type of database object.

=head1 SYNOPSIS

	my $obj = Utilities::HashDB->new();

=head1 METHODS

=over

=cut
   
=item C<new()>

   Create a new HashDB object.
   
=item C<setdata(data, @keys)>

   set a data item to the given keys.
   
=item  C<getdata(@keys)>

   return all data items that match the given keys.
   
=item  C<deletedata(@keys)>

   detete all data items that match the given keys.
   
=item  C<match(@keys)>

   return the full DataItem object refs that match keys.
   
=item  C<items()>

   return the number of seperate items in the store.
   
=item  C<store(filename)>

   dump to file.

=item  C<restore(filename)>

   restore from file.

=item  C<alias(\@refofkeys,\@aliaskeys)>

   attatch another set of keys to items that 
   match the refopfkeys	(note that these are
   references to the arrays).

=item  unalias(@aliaskeys)

   remove an alias.

=back

=head1 AUTHOR

Originally Written by Christopher Williams.

=head1 MAINTAINER

Shaun ASHBY 

=cut
   
package Utilities::HashDB;
use Utilities::DataItem;
use FileHandle;
require 5.004;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->{dataitems}=();
	return $self;
}

sub setdata {
	my $self=shift;
	my $data=shift;
	my @keys=@_;
	
 	push @{$self->{dataitems}}, Utilities::DataItem->new($data, @keys);
}

sub alias {
	my $self=shift;
	my $keyref=shift;
	my $aliaskeys=shift;

	my @objs=$self->match(@{$keyref});
	foreach $obj ( @objs ) {
	  $obj->alias(@{$aliaskeys});
	}
}

sub unalias {
	my $self=shift;
	my @keys=@_;

        my @objs=$self->match(@keys);
        foreach $obj ( @objs ) {
          $obj->unalias(@_);
        }
}

sub items {
	my $self=shift;
	return $#{$self->{dataitems}};
}

sub deletedata {
	my $self=shift;
	my @keys=@_;

	# first get all the keys we want to delete
	my @match=$self->_match(@keys);
	foreach $i ( @match ) {
	  splice (@{$self->{dataitems}}, $i, 1 );
	}
}

sub match {
	my $self=shift;
	my @keys=@_;
	
	my @data=();
	my @match=$self->_match(@keys);
	foreach $i ( @match ) {
	  push @data, $self->{dataitems}[$i];
	}
	return @data;
}

sub getdata {
	my $self=shift;
	my @keys=@_;
	
	my @data=();
	my @match=$self->_match(@keys);
	my $i;
	foreach $i ( @match ) {
	  push @data, ($self->{dataitems}[$i]->data());
	}
	return @data;
}

sub store {
	my $self=shift;
	my $filename=shift;

	use FileHandle;      
	my $fh=FileHandle->new();
	$fh->autoflush(1);	

	open ($fh, "> $filename") or die "Unable to open file $filename\n $!\n";
	foreach $object ( @{$self->{dataitems}} ) {
	  print $fh "\n";
	  $object->store($fh);
        }	
        close $fh;
	}

sub restore {
	my $self=shift;
        my $filename=shift;
	my @arr=();
	my $data;
	# Make $_ local so it's writable, otherwise you get errors like this:
	# Modification of a read-only value attempted at
	# /afs/cern.ch/user/s/sashby/w2/SCRAM/V1_0_3/src/Utilities/HashDB.pm line 178.
	local $_;

	my $fh=FileHandle->new();
	open ($fh, "< $filename") or die "Unable to open file $filename\n $!\n";
	while (<$fh>)
	   {
	   push @{$self->{dataitems}}, Utilities::DataItem->restore($fh);
	   }

	close $fh;
}

# ------------------- Support Routines ------------
# returns list of array indices of items matching the keys

sub _match {
	my $self=shift;
	my @keys=@_;

	my @matches=();
	my $data;
	for ( $i=0; $i<=$#{$self->{dataitems}}; $i++ ) {
	  $data=$self->{dataitems}[$i];
	  if ( $data->match(@keys) ) {
	    push @matches, $i;
	  }
	}
	return @matches;
}
