# Interface
# ---------
# new(cache)       : A new urlhandler with a defined default cahce directory
# download(url,[location]) : as get but always download
# get(url,[location]) : download from the specified url to cache or location
#			return the full url path name incl. any base expansion
#			and the filename downloaded to
# setbase(urlstring) : set a base url type - return the url object
# unsetbase(type)  : deactivate a previously set base
# currentbase(type) : return the current base for the given type
# expandurl(urlstring) : return the base expanded URLclass of the given string
#
# ----------------------------------------------------------------------

package URL::URLhandler;
require 5.004;
use Utilities::AddDir;
use URL::URLcache;
use URL::URLclass;
use Carp;

sub new {
	my $class=shift;
	my $cache=shift;
	$self={};
	bless $self, $class;
	$self->init($cache);
	return $self;
}

sub init {
	use Utilities::AddDir;
	my $self=shift;
	my $cache=shift;
	$self->{cache}=$cache;
	$self->{cachestore}=$self->{cache}->filestore();

	use URL::URL_cvs;
	use URL::URL_file;
	use URL::URL_http;
	use URL::URL_svn;

	$self->{urlmodules}={
			'cvs' => 'URL::URL_cvs',
			'file' => 'URL::URL_file',
			'http' => 'URL::URL_http',
			'svn' => 'URL::URL_svn'
		};
}

sub get
   {
   my $self=shift;
   my $origurl=shift;
   my $file="";
   
   my $url=URL::URLclass->new($origurl);
   my $type=$url->type();
   $url->merge($self->currentbase($type));
   my $fullurl=$url->url();
   
   $file=$self->{cache}->file($fullurl);
   if ( $file eq "" )
      {
      ($fullurl,$file)=$self->download($origurl, @_);
      if (-f $file)
	 {
	 my $filemode = 0644;   chmod $filemode, $file;
	 }
      }
   return ($fullurl, $file);
   }

sub download {
	my $self=shift;
        my $origurl=shift;

        # Process the URL string
        my $url=URL::URLclass->new($origurl);
	my $type=$url->type();
	$urltypehandler=$self->_typehandler($type);
	$url->merge($self->currentbase($type));

	# Generate a location name if not provided 
	my $nocache=1;
	if ( @_ ) {
	   $location=shift;
	   $nocache=0; # dont cache if downloaded to an external location
	}
	else {
	   $location=$self->{cache}->filename($url->url());
	}
	# -- get the file from the appropriate handler
	if ( defined $urltypehandler ) {
	     # Call the download module
	     $file=eval{$urltypehandler->get($url, $location)}; 
	} 

        # now register it in the cache if successful
	if ( $file ne "" ) {
         if ( $file && $nocache) {
          $self->{cache}->store($url->url(), $file);
         }
	}
	return ($url->url(), $file, $urltypehandler->error());
}

sub expandurl {
	my $self=shift;
	my $urlstring=shift;

	my $url=URL::URLclass->new($urlstring);
	my $type=$url->type();
	$url->merge($self->currentbase($type));
	return $url;
}

sub setbase {
	my $self=shift;
	my $partialurl=shift;

	my $base=URL::URLclass->new($partialurl);
	my $type=$base->type();
	$self->checktype($type);
	# make a new base-url object
	push @{$self->{"basestack"}{$type}}, $base;
	return $base;
}

sub unsetbase {
	my $self=shift;
        my $type=shift;
	my $oref;

	$self->checktype($type);
	# pop off the stack and call the unset base method
	if ( $#{$self->{basestack}{$type}} >=0 ) {
	   my $base=pop @{$self->{basestack}{$type}};
	   undef $base;
	}
	else {
	   die "URLhandler error: Unable to unset type $type\n";
	}
	# remove the stack if its empty
	if ( $#{$self->{basestack}{$type}} == -1 ) {
	  delete $self->{basestack}{$type};
	}
}

sub currentbase {
	my $self=shift;
	my $type=shift;
	my $rv;

	if ( exists $self->{basestack}{$type} ) {
	  $rv=${$self->{basestack}{$type}}[$#{$self->{basestack}{$type}}];
	}
	else {
	  $rv=undef;
	}
	return $rv;
}

sub checktype($type) {
	my $self=shift;
	my $type=shift;

        # Check type is supported
        if ( ! exists $self->{urlmodules}{$type} ) {
          die "URLhandler error: Unsupported type $type\n";
        }
}

sub _typehandler {
	my $self=shift;
	my $type=shift;

	$self->checktype($type);

	# instantiate only if it doesnt already exist;
	if ( exists $self->{'urlobjs'}{$type} ) {
		$self->{'urlobjs'}{$type};
	}	
	else {
		$self->{'urlobjs'}{$type}=$self->{urlmodules}{$type}->new();
	}
}
