#
# standard url interface - dummy implementation
#
# Interface
# ---------
# new()			: new object - calls init ->override init
# get(url, destination) : Override
# init()		: Override

package URL::URL_interface;
use URL::URLclass;
require 5.001;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->init();
	return $self;
}

# ----- Dummy interface routines
sub init {
	# Dummy - override as reqd
	}
