#
# standard url interface for cvs
#
# cvs urls
#
# cvs://server_name:/repository_location?passkey=xxx&auth=xxx&user=xxx
#	&module=co_files
#
# Interface
#-------------
# new()			:
# get(url,$dirname) :

package URL::URL_cvs;
require 5.001;
use Utilities::CVSmodule;
use URL::URL_base;
use Carp;
use Cwd;

@ISA = qw(URL::URL_base);

sub init {
	my $self=shift;
	$self->{cvsco}="co";
}

sub setbase {
	my $self=shift;
	my $base=shift;
	my $varhash=shift;

        my $auth=$$varhash{'auth'};

        # a new cvs object
        $self->{cvsobject}=Utilities::CVSmodule->new();
        $self->{cvsobject}->set_base($base);
        $self->{cvsobject}->set_auth($auth);
        if ( exists $$varhash{'user'} ) {
             $self->{cvsobject}->set_user($$varhash{'user'});
        }
        if ( exists $$varhash{'passkey'} ) {
             $self->{cvsobject}->set_passkey($$varhash{'passkey'});
        }
        if ( exists $$varhash{'method'} ) {
             $self->{cvsco}=$$varhash{'method'};
        }
	# Alternative dir name to co to
	if ( exists $$varhash{'name'} ) {
             $self->{dirname}=$$varhash{'name'};
        }
}

sub get {
	my $self=shift;
	my $url=shift;
	my $location=shift;
	my $rv="";

	use File::Basename;
	my ($dir,$dirname)=($location=~/(.*)\/(.*)/);
	# Check for type of auth. If local, we can skip the server entry:
	if ($url->vars()->{'auth'} eq "local")
	   {
	   $self->setbase($url->path(),$url->vars());
	   }
	else
	   {
	   $self->setbase($url->servername().":/".$url->path(),$url->vars());
	   }
	if ( -f $location ) {
	  # must be a file to update
	  my $thisdir=cwd();
	  chdir $dir or die "unable to enter directory $dir\n";
          $self->{cvsobject}->invokecvs("update");
	  chdir $thisdir;
	  $rv=$location;
	}
	else { #a checkout
	  require Utilities::AddDir;
	  if ( $dir ne $location ) {
	    AddDir::adddir($dir);
	  }

          my @cvscmd=($self->{cvsco});
          my $version=$url->param('version');
	  my $module;
	  ($module=$url->param('module'))=~s/\/$//;
	  my $filename="";
	  if ( $module=~/\/.?/ ) {
	    ($filename=$module)=~s/.*\///;
	  }

	  push @cvscmd, ("-d", "$dirname");
          if ( $version && ($version ne "") ) {
           push @cvscmd, ("-r", "$version");
          }
          #
          # Check to see we have a server and if so attempt the checkout
          #
          if ( ! defined $self->{cvsobject} )  {
           $self->error("undefined cvs server for $module");
          }
          else {
	   if ( ! defined $module ) {
	    $self->error("undefined module to checkout");
	   }
	   else {
	    my $thisdir=cwd();
	    chdir $dir or die "unable to enter directory $dir\n";
            $self->{cvsobject}->invokecvs(@cvscmd,  $module);
	    chdir $thisdir;
	    if ( -e $location."/".$filename ) { 
			$rv=$location."/".$filename; 
			$rv=~s/\/$//;
	    } 
	    elsif ( -d $location."/CVS" ) {
	   		$rv=$location;
			$rv=~s/\/$//;
	    }
	    else {
	     $self->error("Download failed for ".$url->url().
	      " ".$location."/".$filename." does not exist\n");  
	     $rv="";
	    }
	   }
	 }
	}
	return $rv;
}
