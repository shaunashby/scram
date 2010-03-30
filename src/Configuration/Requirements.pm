# Requirements Doc - just to get ordering info
#
# Interface
# ---------
# new(ActiveStore,url[,arch])     : new requirements doc
# setup(toolbox): set up the requirements into the specified toolbox object
# download(toolbox)    : download description files (into toolbox cache)
# tools()       : Return list of ALL requirements (ordered)
# selectedtools() : Return list of only those tools selected
# version(tool) : return the version of a given tool
# toolurl(tool)     : return the url of a given tool
# getreqforarch(arch) : Return a RequirementsObject corresponding to the
#			specified architecture
# toolcomment(tool,version) : return the comment string for the specified tool
# distributionurl(tool,version) : return the dist info url for the tool

package Configuration::Requirements;
use ActiveDoc::ActiveDoc;
use Utilities::Verbose;

require 5.004;
@ISA=qw(Utilities::Verbose);
$Configuration::Requirements::self;

sub new
   {
   my $class=shift;
   # Initialise the global package variable:
   no strict 'refs';
   $self = defined $self ? $self
      : (bless {}, $class );
   $self->{dbstore}=shift;
   $self->{file}=shift;
   $self->{cache}=$self->{dbstore}->cache();

   if ( @_ )
      {
      $self->arch(shift);
      }
   
   $self->verbose("Initialising a new Requirements Doc");
   $self->{mydoctype} = "Configuration::Requirements";
   $self->{mydocversion}="2.0";
   # Counter for downloaded tools: zero it here. It will
   # be auto-incremented as each tool is selected:
   $self->{selectcounter}=0;
   $self->{Arch}=1;
   push @{$self->{ARCHBLOCK}}, $self->{Arch};
   $self->init($self->{file});
   return $self;
   }

sub toolmanager
   {
   my $self=shift;
   
   @_ ? $self->{toolmanagerobject} = shift
      : $self->{toolmanagerobject};
   
   }

sub configversion
   {
   my $self=shift;
   @_ ? $self->{configversion} = shift
      : $self->{configversion};
   }

sub url
   {
   my $self=shift;
   
   if ( @_ )
      {
      $self->{file}=shift;
      }
   return $self->{file};
   }

sub tools
   {
   my $self=shift;
   return @{$self->{tools}};
   }

sub version
   {
   my $self=shift;
   my $tool=shift;
   return $self->{'version'}{$tool};
   }

sub toolurl
   {
   my $self=shift;
   my $tool=shift;
   return $self->{'url'}{$tool};
   }

sub init
   {
   my $self=shift;
   my $url=shift;
   my $scramdoc=ActiveDoc::ActiveDoc->new($self->{dbstore});
   $scramdoc->verbosity($self->verbosity());
   $scramdoc->url($url);   
   $scramdoc->newparse("ordering",$self->{mydoctype},'Subs');
   $self->{reqcontext}=0;
   $self->{scramdoc}=$scramdoc;
   undef $self->{restrictstack};
   @{$self->{tools}}=();
   @{$self->{ArchStack}}=();
   $self->verbose("Initial Document Parse");
   $self->{scramdoc}->parse("ordering");
   # Set the config version. If there isn't a version, it means that we
   # have a stand-alone repository for the toolbox, rather than a CVS
   # one. Hence, no CVS tag (== version):
   ($scramdoc->{configurl}->param('version') eq '') ?
      $self->configversion("STANDALONE") :
      $self->configversion($scramdoc->{configurl}->param('version'));
   }

sub arch
   {
   my $self=shift;
   # $self->arch is the SCRAM_ARCH value:
   if ( @_ )
      {
      $self->{arch}=shift;
      }
   else
      {
      if ( ! defined $self->{arch} )
	 {
	 $self->{arch}="";
	 }
      }
   return $self->{arch};
   }

sub archlist
   {
   my $self=shift;
   return @{$self->{ArchStack}};
   }

sub getreqforarch
   {
   my $self=shift;
   my $arch=shift;
   
   if ( ! defined $self->{reqsforarch}{$arch} )
      {
      $self->{reqsforarch}{$arch}=
	 Configuration::Requirements->new($self->{dbstore},$self->{file},
					$arch);
      }
   return $self->{reqsforarch}{$arch};
   }

sub download
   {
   my $self=shift;
   my $tool;
   $| = 1; # Unbuffer the output

   print  "Downloading tool descriptions....","\n";
   print  " ";
   foreach $tool ( $self->tools() )
      {
      print "#";
      $self->verbose("Downloading ".$self->toolurl($tool));
      # get into the cache:
      $self->{scramdoc}->urlget($self->toolurl($tool));
      }
   print "\nDone.","\n";
   # So now add the list of downloaded tools, and which were
   # selected, to tool cache:
   print "Tool info cached locally.","\n","\n";

   # Now copy required info from this object to ToolManager (ToolCache):
   $self->toolmanager()->downloadedtools($self->{tools});
   $self->toolmanager()->defaultversions($self->{version});
   $self->toolmanager()->toolurls($self->{url});
   $self->toolmanager()->selected($self->{selected});
   }

sub require()
   {
   my ($xmlparser,$name,%attributes)=@_;
   my $name=$attributes{'name'};
   my $version=$attributes{'version'};
   my $url=$attributes{'url'};
   $name =~ tr[A-Z][a-z];
   
   # Add protection so that architecture tags are obeyed during download:
   if ( $self->{Arch} )
      {
      # Add tool to the tool array:
      push @{$self->{tools}}, $name;
      
      # If the tool already has an entry, modify the version string to
      # include both versions. The versions can later be separated and
      # parsed as normal:
      if (defined $self->{version}{$name})
	 {
	 # Don't need an extra entry for this tool onto tool array:
	 pop @{$self->{tools}}, $name;
	 # Modify the version string to append the other tool version.
	 # Separate using a colon:
	 my $newversion=$self->{version}{$name}.":".$version;
	 $self->{version}{$name}=$newversion;
	 }
      else
	 {
	 $self->{version}{$name}=$version;
	 }
      # -- make sure the full url is taken
      my $urlobj=$self->{scramdoc}->expandurl($url);
      $self->{url}{$name}=$urlobj->url();
      $self->{creqtool}=$name;
      $self->{creqversion}=$version;
      $self->{reqtext}{$self->{creqtool}}{$self->{creqversion}}="";
      }
   }

sub select()
   {
   my ($xmlparser,$name,%attributes)=@_;
   my $name=$attributes{'name'};
   $name =~ tr[A-Z][a-z];
   if ( $self->{Arch} )
      {
      $self->verbose("Selecting ".$name);
      # Increment counter:
      $self->{selectcounter}++;
      $self->{selected}{$name}=$self->{selectcounter};
      }
   }

sub architecture()
   {
   my ($xmlparser,$name,%attributes)=@_;
   my $archname=$attributes{'name'};
   # Check the architecture tag:
   ( ($self->arch()=~/$archname.*/) )? ($self->{Arch}=1)
      : ($self->{Arch}=0);
   push @{$self->{ARCHBLOCK}}, $self->{Arch};
   push @{$self->{ArchStack}}, $archname;
   }

sub architecture_()
   {
   pop @{$self->{ARCHBLOCK}};
   $self->{Arch}=$self->{ARCHBLOCK}[$#{$self->{ARCHBLOCK}}];
   }

sub include_()
   {
   my $incfile = $self->{scramdoc}->included_file();
   my $incscramdoc=ActiveDoc::ActiveDoc->new($self->{dbstore});
   $incscramdoc->verbosity($self->verbosity());
   $incscramdoc->filetoparse($incfile);
   $incscramdoc->newparse("included_file",$self->{mydoctype},'Subs');
   $self->verbose("Included File Parse");
   $incscramdoc->parse("included_file");   
   }

sub AUTOLOAD()
   {
   my ($xmlparser,$name,%attributes)=@_;
   return if $AUTOLOAD =~ /::DESTROY$/;
   my $name=$AUTOLOAD;
   $name =~ s/.*://;
   # Delegate missing function calls to the doc parser class:
   $self->{scramdoc}->$name(%attributes);
   }

1;
