#
# URLclass.pm
#
# Originally Written by Christopher Williams
#
# Description
#
# Interface
# ---------
# new(url)	: A new URLclass object
# origurl()	: return the original url as originally provided in new
# url()	        : return the full url name with all expansion
# path()	: return the path (all after server name - no vars)
# file()	: return the filename from the end of the path
# param(var)	: return the value of a url parameter
# servername()	: return/set the name of the server
# equals(URLclass) : compare with another URLclass object for equality
#			0=false 1=true
# merge(URLclass) : merge the given URL into the current one according to the
#		    following rules -
#		     - types are identical
#		     - servername is taken only if not set locally
#		     - the local path is appended to that passed in the arg
#		     - variables are added only if they dont already exist
# type()	: get/set the url type
# vars()	: get/set the url parameter hash
# transfervars(varhash)  : transfer any variables from varhash into vars
#			   only if they do not already exist

package URL::URLclass;
require 5.004;

sub new {
	my $class=shift;
	$self={};
	bless $self, $class;
	$self->{origurl}=shift;
	$self->_init();
	$self->_url($self->{origurl});
	return $self;
}

sub _init {
	my $self=shift;
	$self->{vars}={};
	$self->{servername}="";
	$self->{path}="";
	$self->{type}="";
}

sub origurl {
	my $self=shift;
	return $self->{origurl};
}


sub servername {
	my $self=shift;
	@_?$self->{servername}=shift
	  :$self->{servername};
}

sub path {
	my $self=shift;
	@_?$self->{path}=shift
	  :$self->{path};
}

sub type {
	my $self=shift;
	@_?$self->{type}=shift
	  :$self->{type};
}

sub vars {
	my $self=shift;
	@_?$self->{vars}=shift
	  :$self->{vars};
}

sub url {
	my $self=shift;
	
	my $vars=$self->_vartostring();
	my $server=$self->servername();
	my $fullurl=$self->type().":".(($server ne "")?"//".$server."/":"").
			$self->path().(($vars ne "")?"\?".$vars:"");
	return $fullurl;
}

sub merge {
	my $self=shift;
	my $url=shift;

	my $rv=1;
	# -- can only merge url's of the same type
	if ( (defined $url) && ($self->type() eq $url->type()) ) {
	 # -- merge server only if it dosnt exist locally
	 if ( (! defined $self->{servername}) || ($self->{servername} eq "") ) {
	  $self->servername($url->servername());
	 }
	 # -- merge  path - insert at beginning of existing path
	 if ( defined $url->{path} ) {
	   $self->{path}=$url->{path}.$self->{path};
	 }
	 
	 # -- now merge vars
	 $self->transfervars($url->vars());
	 $rv=0;
	}
	
	return $rv;
}

sub equals {
	my $self=shift;
	my $testurl=shift;

	my $rv=0;
	if ( $self->servername() eq $testurl->servername() ) {
	  if ( $self->path() eq $testurl->path() ) {
	   #  -- check the passed variables
	   my @testkeys=keys %{$testurl->vars()}; 
	   if ( $#{keys %{$self->{vars}}} == $#testkeys ) {
	    my $okvar=-1;
	    foreach $var ( @testkeys ) {
	     if ( exists $self->{vars}{$var} ) {
	      if ( $self->{vars}{$var} eq $testurl->{vars}{$var} ) {
		$okvar++;
	      } 
	     }
	    }
	    # if we get this far and all the testvars have been tested then
	    if ( $okvar == $#{keys %{$self->{vars}}} ) {
	     $rv=1;
	    }
	   }
	  }
	}
	return $rv;
}

sub transfervars {
        my $self=shift;
        my $basevars=shift;

        foreach $key ( keys %$basevars ) {
          if ( ! exists $self->{vars}{$key} ) {
                $self->{vars}{$key}=$$basevars{$key};
          }
        }
}

sub file {
	my $self=shift;
        my $file;

        if ( $self->{path}=~/\// ) {
          ($file=$self->{path})=~s/.*\///g;
        }
        else {
          $file=$self->{path};
        }
        return $file;
}

sub param {
	my $self=shift;
	my $param=shift;

	$self->{vars}{$param};
}

#
# --- Support Routines
#

sub _vartostring {
	my $self=shift;

	my $string="";
	foreach $key ( sort(keys %{$self->{vars}}) ) {
	  $string=$string.(($string eq "")?"":"\&").$key."=".$self->{vars}{$key};
	}
	return $string;
}

sub _splitvarstring {
	my $self=shift;
	my $varstring=shift;
	
	my @pairs=split /\&/, $varstring;
	foreach $pair ( @pairs ) {
	  my ($var,$val)= split /=/, $pair;
	  $self->{vars}{$var}=$val;
	}
}

# process a url string into its component parts
sub _url {
	my $self=shift;
	my $url=shift;

	if ( $url!~/:/ ) {
	  $self->error("Invalid URL specification - no type: in $url");
	}
	else {
	# -- split out type and lowercase it
	my ($type, @rest)= split ":", $url;
	($self->{type}=$type)=~tr[A-Z][a-z];

	# -- sort out variables
	my $tmp=join ':' ,@rest;
	my($path, @varsarray)=split /\?/, $tmp;
	my $varstring=join '?' ,@varsarray;
	if ( $varstring ) { $self->_splitvarstring($varstring);}

	# -- extract servername from path
	if ( ! defined $path ) {
	  $path="";
	}
	elsif ( $path=~/^\/\// ) {
	  my $server;
	 ($server,$path)=($path=~/^\/\/(.*?)\/(.*)/);
	 $self->servername($server);
	}
	$self->path($path);
	}
}

sub error {
	my $self=shift;
	my $string=shift;
	print "URLClass: ".$string."\n";
	die;
}
