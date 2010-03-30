#
# PreProcessedFile.pm
#
# Originally Written by Christopher Williams
#
# Description
# -----------
# Handle Preprocessed file information
#
# Interface
# ---------
# new(cache,dbstore)  : A new PreProcessedFile object
# url([url])	: return the full url. With an argument will take the given
#		  url and expand it in the context of the current url base. 
# file()        : return the filename corresponding to url of the document
# ProcessedFile() : return the filename corresponding to processed url 
#			of the document
# realline(number): Return the line and fileobj corresponding to number in 
#	            processed file
# update()	  : update the preprocessed file as required.
# store(filename) :
# restore(filename) :
package ActiveDoc::PreProcessedFile;
use ActiveDoc::ActiveDoc;
use Utilities::Verbose;
use ObjectUtilities::StorableObject;
require 5.004;

@ISA=qw(ObjectUtilities::StorableObject Utilities::Verbose);

1;
