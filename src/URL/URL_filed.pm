#
# standard url interface for local file - direct use no copying to cache
#
# Interface
# ---------
# new()			:
# setbase()		:
# unsetbase()		:
# get(url, destination) :

package URL::URL_filed;
require 5.001;
use File::Copy;
use URL::URL_base;
@ISA=qw(URL::URL_base);

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->{path}="";
	return $self;
}

sub setbase {
	my $self=shift;
	my $varhash=shift;

	if ( exists $$varhash{'base'} ) {
		$self->{path}=$$varhash{'base'};
	}
}

sub unsetbase {
	my $self=shift;
	$self->{path}="";
}

sub get {
	my $self=shift;
	my $file=shift;
	my $dir=shift; # Were not copying anything so this is irrelevant

	my $rv="";
	my $urlfile=$file;

	if ( $file!~/^\// ) {
	 $urlfile=$self->{path}."/".$file;
	}
	if ( -e "$urlfile" ) {
	 $rv=$urlfile;
	} 
	return $rv;
}
