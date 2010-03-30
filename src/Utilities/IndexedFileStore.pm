=head1 NAME

Utilities::IndexedFileStore - An indexed file storage object. Used during the project boot process.

=head1 SYNOPSIS

	my $obj = Utilities::IndexedFileStore->new();

=head1 METHODS

=over

=cut

=item C<new(storedir)>

A new IndexedFileStore object based in storedir.

=item C<store(key,file)>

Store a key/file combination.

=item C<filename(key)>

Return the filename corresponding to a given key or
generate one if it doesnt already exist.

=item C<file(key)>

Return the filename only if it already exists.

=item C<delete(key)>

Remove key from cache.

=item C<clear()>

Clear the cache.

=item C<filestore()>

Return the directory to download files to.

=item C<updatenumber(key)>

Return an integer number indicating update sequence.
This number increases by one each time store is called.
  
=back

=head1 AUTHOR
   
Originally Written by Christopher Williams

=head1 MAINTAINER

Shaun ASHBY 

=cut

package Utilities::IndexedFileStore;
require 5.004;
use Utilities::HashDB;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->_init(@_);
	return $self;
}

sub store {
	my $self=shift;
        my $key=shift;
        my $file=shift;

	# store as relative to filestore if applicable - relocatable stores
	my $filestore=$self->filestore();
	$file=~s/^\Q$filestore\E\///;

        $self->{keyDB}->deletedata($key);
        $self->{keyDB}->setdata($file,$key);
        $self->{keyDB}->store($self->{cacheindex});

        # Keep a track of changes
        my ($sequencenumber)=$self->{keyDBupdate}->getdata($key);
        if ( ! defined $sequencenumber ) { $sequencenumber=0 };
        $sequencenumber=$sequencenumber+1;
        $self->{keyDBupdate}->deletedata($key);
        $self->{keyDBupdate}->setdata($sequencenumber,$key);
        $self->{keyDBupdate}->store($self->{cacheseqindex});
}

sub updatenumber {
        my $self=shift;
        my $key=shift;

        my ($rv)=$self->{keyDBupdate}->getdata($key);
        return ((defined $rv)?$rv:0);
}

sub filestore {
        my $self=shift;
        return $self->{cachedir};
}

sub filename {
	my $self=shift;
        my $key=shift;

        my $filenumber;

        my $file=$self->file($key);
        if ( $file eq "" ) {
          # need to generate a new filename - a random number will do
          srand();
          do {
            $filenumber=int(rand 99999999)+1;
            $file=$self->filestore()."/".$filenumber;
          } until ( ! ( -e $file ) );
        }
        return $file;
}

sub file {
        my $self=shift;
        my $key=shift;

        my @found=$self->{keyDB}->getdata($key);
        my $file=( ($#found == -1)?"":$found[0]);
	# expand any files to include the path (unless complete path names)
	if ( ($file ne "") && ($file!~/^\//) ) {
		$file=$self->filestore()."/".$file;
	}
	return $file;
}

sub clear {
        my $self=shift;
        foreach $item ( $self->{keyDB}->match() ) {
          $self->delete($item->keys());
        }
}

sub delete {
        my $self=shift;
        my $key=shift;
        unlink ($self->{keyDB}->getdata($URL));
        $self->{keyDB}->deletedata($key);
        $self->{keyDB}->store($self->{cacheindex});
}

sub location {
	my $self=shift;
	return $self->{cachetop};
}

sub _init {
        my $self=shift;
        $self->{cachetop}=shift;
        $self->{cachedir}=$self->{cachetop}."/files";
	AddDir::adddir($self->{cachetop});
        AddDir::adddir($self->{cachedir});

        $self->{cacheindex}=$self->{cachetop}."/index.db";
        $self->{cacheseqindex}=$self->{cachetop}."/seqnumb.db";
        $self->{keyDB}=Utilities::HashDB->new();
        $self->{keyDBupdate}=Utilities::HashDB->new();

        if ( -f $self->{cacheindex} ) {
          $self->{keyDB}->restore($self->{cacheindex});
        }
        else {
          AddDir::adddir($self->{cachedir});
        }

        if ( -f $self->{cacheseqindex} ) {
          $self->{keyDBupdate}->restore($self->{cacheseqindex});
        }

	my $mode = 0644;
	chmod $mode, $self->{cacheindex}, $self->{cacheseqindex};	

}
