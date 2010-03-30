#
# URLcache.pm
#
# Originally Written by Christopher Williams
#
# Description
# -----------
# Simple url->file lookup (persistent)
#
# Interface
# ---------
# new(cachedir)		: A new URLcache object in a given directory
# store(url,file)	: store a url/file combination
# file(url)		: return the file for a given url
# delete(url)		: remove from cache url
# clear()		: clear cache
# filestore()	        : Return the directory to download files to
# filename(url)		: return a unique file/dir in cache for the given url
# updatenumber(int)	: return an integer number changed with each store

package URL::URLcache;
require 5.004;
use Utilities::IndexedFileStore;
@ISA=qw(Utilities::IndexedFileStore)
