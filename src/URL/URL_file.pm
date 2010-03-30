#
# standard url interface for local file
#
# Interface
# ---------
# new()			:
# get(url, destination) :

package URL::URL_file;
require 5.001;
use File::Copy;
use URL::URL_base;
@ISA=qw(URL::URL_base);

sub get {
	my $self=shift;
	my $url=shift;
	my $location=shift;
	my $filename=$url->path();
	
	if ( -e $filename ) {
         if ( -d $filename ) { #- directory copy
	  require Utilities::AddDir;
	  AddDir::copydir($filename,$location);
	 }
	 else {
	  copy ( $filename,$location) || die "Unable to copy file $filename --> "
		."$location \n$!\n";
	 }
	 $rv=$location;
	} 
	else {
	 $rv="";
	}
	return $rv;
}
