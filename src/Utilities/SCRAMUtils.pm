#
# Utility Routines for the SCRAM tools
#
# Interface
#
# dated(testfile,@dependencies) : returns 1 if testfile is older than any of its
#				  dependencies or does not exist

package SCRAMUtils;
require 5.001;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(checkfile updatelookup dated);
use Carp;

sub dated {
	my $testfile=shift;
	my @files=@_;

	my $rv=0;
	if ( -f $testfile ) {
	   my $time=(stat($testfile))[9];
	   foreach $file ( @files ) {
	    if ( -f $file ) {
	     if ( (stat($file))[9] > $time ) {
		$rv=1;
		print "$testfile is out of date relative to $file\n";
	     }
	    }
	   }
	}
	else { $rv=1; }
	return $rv;
}

sub checkfile {
	my $filename=shift;
	my $thisfile="";
	$thisfile=$ENV{LOCALTOP}."/".$filename;
	return $thisfile, if ( -e $thisfile );
	$thisfile=$ENV{RELEASETOP}."/".$filename;
	return $thisfile, if ( -e $thisfile );
	return "";
}

#
# Replace or add an entry in a hashing file
#
sub updatelookup {
	my $filename=shift;
	my $key=shift;
	my $rest=shift;
	my $update=0;
	use File::Copy;
	local $_;
	use FileHandle;
	my $fhw=FileHandle->new();
	my $fh=FileHandle->new();
	open ( $fhw, ">".$filename.".wk" )  ||
		die "Unable to open $filename.wk ".$!."\n";
	$fh->open($filename);
	#print "Searching for ".$key."\n";
	while ( <$fh> ) {
		if ( $_=~/^\Q$key\E/o ) {
			$update=1;
			print $fhw $key.$rest."\n";
		}
		else {	
		 print $fhw $_;
	        }
	}
	undef $fh;
	if ( $update==0 ) {
		print $fhw $key.$rest."\n";
	}
	undef $fhw;
	copy "$filename.wk", $filename or croak "Unable to update file "
				."$filename $!\n";
	}
