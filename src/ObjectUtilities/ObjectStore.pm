#
# ObjectStore.pm
#
# Originally Written by Christopher Williams
#
# Description
# -----------
# An very simple object persistency manager for small scale use.
# Objects are saved and recovered on demand
# Objects to be stored in this manager must implement the following interface
#             new(ObjectStore)   : 
#	      store(location)    : dump out to location
#	      restore(location)  : restore from location
#		objects must inherit from StorableObject
#
# Interface
# ---------
# new(store_directory,[object])	: A new ObjectStore object. An alternative
#				  object can be specified with which to
#				  construct the stored objects with by
#				  supplying the object reference
#				  if store_directory begins with "<" - does
#				  not attempt to build it if it dosnt exist
# storeref([object])		: set/return the object store referefnce object
#				  (as passed in new)
# store(oref,@keys)		: store an object - each object must have
#				  a unique key
# find(@keys)			: find and recover object(s) from the store
#				  that match keys. Returned as a list of oref
# sequence(@keys)		: return the sequence number of the object
#				  matching the keys
#				  An object is assigned a new sequence number
#				  with each store.
# delete(@keys)			: Delete the object with the given key
# alias(\@refofkeys,\@aliaskeys) : attatch another set of keys to objects that 
#                                  match the refofkeys
#                                  note that these are references to the arrays
# unalias(@aliaskeys) 		 :remove an alias
# location()			 : return the top directory where the store is
#					located

package ObjectUtilities::ObjectStore;
require 5.004;
use Utilities::AddDir;
use Utilities::HashDB;

sub new {
	my $class=shift;
	my $dir=shift;
	$self={};
	# do we have an alternative object to instantiate objects with
	if ( @_ ) {
	  $self->{storeobject}=shift;
	}
	else {
	  $self->{storeobject}=$self;
	}
	bless $self, $class;
	($self->{location}=$dir)=~s/^\<//;
	$self->{admindir}=$self->{location}."/admin";
	if ( $dir=~"^\<" ) {
	}
	else { 
	  AddDir::adddir($self->{admindir});
	}
	if ( -d $self->{location} ) { 
	   $self->{storage}=$dir."/objects";
	   AddDir::adddir($self->{storage});
	   $self->_init();
	}
	else {
	   return undef;
	}
	#print "ObjectStore  -- $self->{storeobject}\n";
	return $self;
}

sub storeref {
	my $self=shift;
	if ( @_ ) {
	  $self->{storeobject}=shift;
	}
	return $self->{storeobject};
}

sub location {
	my $self=shift;
	return $self->{location};
}

sub store {
	my $self=shift;
	my $oref=shift;
	my @keys=@_;

	my $oreftype=ref($oref);
	#print "$self: Storing an object of type : $oreftype\n";
	my $filename=$self->_filename(@keys);
	$oref->store($self->_fullfilename($filename));
	# Update the sequence number to track changes
	my @seqnumbers=$self->{filehash}->getdata("__seq_number",@keys);
	my $seqnumb=((@seqnumbers)?$seqnumbers[0]:-1)+1;
	$self->{filehash}->deletedata("__seq_number",@keys);
	$self->{filehash}->setdata($seqnumb,"__seq_number",@keys);
	
	$self->{filehash}->deletedata(@keys);
	$self->{filehash}->setdata($filename,@keys); # persistent
	$self->{typehash}->deletedata($filename);
	$self->{typehash}->setdata($oreftype,$filename); # persistent
	$self->{orefhash}->deletedata($filename);
	$self->{orefhash}->setdata($oref,$filename); # transient
	$self->_storedb();
}

sub sequence {
	my $self=shift;
	my @keys=@_;

	my @seq=$self->{filehash}->getdata("__seq_number",@keys);
	return (($#seq == 0)?$seq[0]:-1);
}

sub find {
	my $self=shift;
	my @keys=@_;

	my @oref=();
	my $oref;
	my @types;
	my $type;
	my @validobjs=();
	my $fh;

	#print "$self: Searching for : @keys\n";
	my @datafiles=$self->{filehash}->getdata(@keys);
	foreach $file ( @datafiles ) {
	  @oref=$self->{orefhash}->getdata($file);
	  if ( $#oref < 0 ) {   # we need to instatniate it
	     @types=$self->{typehash}->getdata($file);
	     $type=$types[0];
	     eval "require $type";
	     $oref=$type->new($self->{storeobject});
	     $oref->restore($self->_fullfilename($file));
	  }
	  else {
	    $oref=$oref[0];
	  }
	  push @validobjs, $oref; 
	}
	return @validobjs;
}

sub alias {
	my $self=shift;
	$self->{filehash}->alias(@_);
	$self->_storedb();
}

sub unalias {
	my $self=shift;
	$self->{filehash}->unalias(@_);
	$self->_storedb();
}

sub delete {
	my $self=shift;
	my @keys=@_;

	my $filename=$self->_filename(@keys);
	$self->{filehash}->deletedata("__seq_number",@keys);
	$self->{filehash}->deletedata(@keys);
	$self->{typehash}->deletedata($filename);
	$self->{orefhash}->deletedata($filename);
	$self->_storedb();
	print "Deleting ".$self->_fullfilename($filename)."\n";
	unlink $self->_fullfilename($filename);
}

#
# Private routines
#
sub _filename {
	my $self=shift;
	my @keys=@_;

	my ($file)=$self->{filehash}->getdata(@keys);
	if ( ! defined $file ) {
          # need to generate a new filename - a random number will do
          srand();
          do {
            $file=int(rand 99999999)+1;
          } until ( ! ( -e $self->_fullfilename($file) ) );
        }	
	return $file;
}

sub _fullfilename {
	my $self=shift;
	my $file=shift;

	if ( $file!~/^\//  ) { # return only full path names
	  $file=$self->{storage}."/".$file;
	}
	return $file;
}

sub _storedb {
	my $self=shift;
	$self->{filehash}->store($self->{admindir}."/filedb");
	$self->{typehash}->store($self->{admindir}."/typedb");
}

sub _restoredb {
	my $self=shift;
	if ( -f $self->{admindir}."/filedb" ) {
	  $self->{filehash}->restore($self->{admindir}."/filedb");
          $self->{typehash}->restore($self->{admindir}."/typedb");
	}
}

sub _openfile {
	my $self=shift;
	my $filename=shift;

	local $fh=FileHandle->new();
	open ( $fh, $filename) or die "Unable to open $filename\n $!\n";
	return $fh;
}

sub _init {
	my $self=shift;
	$self->{filehash}=Utilities::HashDB->new();
	$self->{typehash}=Utilities::HashDB->new();
	$self->{orefhash}=Utilities::HashDB->new();
	$self->_restoredb();
}
