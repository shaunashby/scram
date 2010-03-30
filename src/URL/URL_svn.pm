#
# standard url interface for svn
#
# svn urls
#
# svn://server_name:/repository_location?passkey=xxx&auth=xxx&user=xxx
#	&module=co_files
#
# Interface
#-------------
# new()		    :
# get(url,$dirname) :
package URL::URL_svn;
require 5.001;
use Utilities::SVNmodule;
use URL::URL_base;
use Carp;
use Cwd;

@ISA = qw(URL::URL_base);

sub init {
	my $self=shift;
	$self->{svnco}="co";
}

sub setbase {
	my $self=shift;
	my $base=shift;
	my $varhash=shift;

        my $auth=$$varhash{'auth'};

        # a new svn object
        $self->{svnobject}=Utilities::SVNmodule->new();
        $self->{svnobject}->set_base($base);
        $self->{svnobject}->set_auth($auth);
        if ( exists $$varhash{'user'} ) {
             $self->{svnobject}->set_user($$varhash{'user'});
        }
        if ( exists $$varhash{'passkey'} ) {
             $self->{svnobject}->set_passkey($$varhash{'passkey'});
        }
        if ( exists $$varhash{'method'} ) {
             $self->{svnco}=$$varhash{'method'};
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
          $self->{svnobject}->invokesvn("update");
	  chdir $thisdir;
	  $rv=$location;
	}
	else { #a checkout
	  require Utilities::AddDir;
	  if ( $dir ne $location ) {
	    AddDir::adddir($dir);
	  }

          my @svncmd=($self->{svnco});
          my $version=$url->param('version');
	  my $module;
	  ($module=$url->param('module'))=~s/\/$//;
	  my $filename="";
	  if ( $module=~/\/.?/ ) {
	    ($filename=$module)=~s/.*\///;
	  }

	  push @svncmd, ("-d", "$dirname");
          if ( $version && ($version ne "") ) {
           push @svncmd, ("-r", "$version");
          }
          #
          # Check to see we have a server and if so attempt the checkout
          #
          if ( ! defined $self->{svnobject} )  {
           $self->error("undefined svn server for $module");
          }
          else {
	   if ( ! defined $module ) {
	    $self->error("undefined module to checkout");
	   }
	   else {
	    my $thisdir=cwd();
	    chdir $dir or die "unable to enter directory $dir\n";
            $self->{svnobject}->invokesvn(@svncmd,  $module);
	    chdir $thisdir;
	    if ( -e $location."/".$filename ) { 
			$rv=$location."/".$filename; 
			$rv=~s/\/$//;
	    } 
	    elsif ( -d $location."/.svn" ) {
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
