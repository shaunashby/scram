#
# ActiveStore.pm
#
# Originally Written by Christopher Williams
#
# Description
# Implements ObjectStore interface
#
# Interface
# ---------
# new([directory|[ObjectStore ObjectCache]]): A new ActiveConfig object
# cache()		: Return the cache
# store(object,@keys)   :
# find (@keys)		:

package ActiveDoc::ActiveStore;
require 5.004;
use URL::URLcache;
use ObjectUtilities::ObjectStore;
use Utilities::Verbose;
@ISA=qw(Utilities::Verbose);

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->init(@_);
	return $self;
}

sub init {
	my $self=shift;

	if ( $#_ == 0 ) {
	  my $dir=shift;

	  $self->{objectstore}=ObjectUtilities::ObjectStore->
		new($dir."/ObjectStore", $self);
	  $self->{cache}=URL::URLcache->new($dir."/cache");
	}
	elsif ( $#_ == 1 ) {
	  $self->{objectstore}=shift;
	  $self->{objectstore}->storeref($self);
	  $self->{cache}=shift;
	}
	else {
	  $self->error("Unable to initialise with arguments @_");
	}
}

sub cache {
	my $self=shift;
	return $self->{cache};
}

sub AUTOLOAD { # Call any method in the ObjectStore directly
	my $self=shift;
	my $call;
	# dont propagate a destroy method
	return if $AUTOLOAD=~/::DESTROY$/;
	($call=$AUTOLOAD)=~s/^.*:://;
	return $self->{objectstore}->$call(@_);
}
