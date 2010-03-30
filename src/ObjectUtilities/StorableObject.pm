#
# StorableObject.pm
#
# Originally Written by Christopher Williams
#
# Description
#
# Interface
# ---------
# new(ObjectStore)	: A new object
# openfile(filename)	:  return a filhandle object opened on the file filename
# ObjectStore()		: Get/Set ObjectStore object
# sequencenumber()	: return the sequence number
# meta()		: return a descriptive string of the object
# store(location)
# restore(location)
# savevar(fh,name,value)	: save a var to a fielhandle
# restorevars(fh, hashref)	: restore variables form a filehandle into
#				  the supplied hash
# savevararray(fh,"label",@array)	: save the contents of the given array
# restorevararray(fh,\@array)	: Restore the array values into array
#				  returns label
package ObjectUtilities::StorableObject;
require 5.004;

sub new {
	my $class=shift;
	my $Os=shift;
	$self={};
	bless $self, $class;
	$self->{ObjectStore}=$Os;
	$self->_init();
	return $self;
}

sub openfile {
        my $self=shift;
        my $filename=shift;

        local $fh=FileHandle->new();
        open ( $fh, $filename) or die "Unable to open $filename\n $!\n";
        return $fh;
}

sub ObjectStore {
	my $self=shift;
	@_ ? $self->{ObjectStore}=shift	
	   : $self->{ObjectStore};
}

sub _init {
	# dummy - override
}

sub store {
	print "Store Dummy not overridden"
}

sub restore {
	print "restore Dummy not overridden"
}

sub meta {
	my $self=shift;

	# by default just the class type
	return ref($self);
}

sub savevar {
	my $self=shift;
	my $fh=shift;
	my $name=shift;
	my $val=shift;
	print $fh "#".$name."\n";
	print $fh $val."\n";
}

sub savevararray {
	my $self=shift;
        my $fh=shift;
	my $label=shift;

	print $fh "_##$label\n";
	foreach $val ( @_ ) {
	 print $fh $val."\n";
	}
	print $fh "_##\n";
}

sub restorevararray {
	my $self=shift;
        my $fh=shift;
	my $arr=shift;

	my ($label, $value);
	($label=<$fh>)=~s/^_##(.*)/$1/;
	chomp $label;
	while ( ($value=<$fh>)!~/^_##/ ) {
	  chomp $value;
	  push @$arr, $value;
	}
	return $label;
}

sub restorevars {
	my $self=shift;
	my $fh=shift;
	my $varhash=shift;

	while ( <$fh>=~/^#(.*)/ ) {
	 $name=$1;
	 chomp $name;
	 $value=<$fh>;
	 chomp $value;
	 $$varhash{$name}=$value;
	}
}

