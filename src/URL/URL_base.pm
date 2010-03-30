#
# standard url interface - dummy implementation
#
# Interface
# ---------
# new()			: new object - calls init ->override init
# get(url, destination) : Override
# init()		: Override

package URL::URL_base;
use URL::URLclass;
require 5.004;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->init();
	return $self;
}

sub error {
        my $self=shift;

	if ( @_ ) {
	  $self->{errorstring}=$self->{errorstring}."\n".shift;
	}
	return (defined $self->{errorstring})?$self->{errorstring}:undef;
}

# ----- Dummy interface routines
sub init {
	# Dummy - override as reqd
	}
