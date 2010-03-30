#
# IncFile.pm
#
# Originally Written by Christopher Williams
#
# Description
# -----------
# Private Class for PreProcessedFile
#
# Interface
# ---------
# new(dbstore)		: A new IncFile object
# filename()	        : return the filename

package ActiveDoc::IncFile;
require 5.004;
use ActiveDoc::Parse;

sub new
   {
   my $class=shift;
   $self={};
   bless $self, $class;
   $self->{ObjectStore}=shift;
   return $self;
   }

sub filename()
   {
   my $self=shift;
   @_ : $self->{filename} = shift
      ? $self->{filename};
   }

1;
