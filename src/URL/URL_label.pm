#
# standard url interface for local file
#
# Interface
# ---------
# new()			:
# setbase()		:
# unsetbase()		:
# get(url, destination) :

package URL_label;
require 5.001;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->{db}="";
	return $self;
}

sub setbase {
	my $self=shift;
	my $varhash=shift;

	if ( exists $$varhash{'base'} ) {
		$self->{db}=$$varhash{'base'};
	}
}

sub unsetbase {
	my $self=shift;
	$self->{db}="";
}

sub get {
	my $self=shift;
	my $label=shift;
        my $filename=shift;
	my $returnval="";

	my $urlfile;

	open ( LOOKUP, "<$self->{db}" ) 
		|| die "URLhandler: Unable to open DataBase $self->{db} $!";
	while ( <LOOKUP> ) {
          next if /^#/;
          if ( $_=~s/^$label\:// ) {
                $returnval = urlhandler($_,$filename);
          }
        }
        close LOOKUP;
        if ( $returnval ne "" ) {
          return $returnval;
        }
        ($proj,$ver)=split /:/, $label;
        print "Error : Unknown project name or version (".$proj." ".$ver.")\n";
        carp;
}
