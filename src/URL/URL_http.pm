#____________________________________________________________________ 
# File: URL_http.pm
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2006-02-15 18:18:04+0100
# Revision: $Id: URL_http.pm,v 1.4 2007/02/27 13:07:07 sashby Exp $ 
#
# Copyright: 2006 (C) Shaun ASHBY
#
#--------------------------------------------------------------------
package URL::URL_http;

=head1 NAME

URL::URL_http -

=head1 SYNOPSIS

	my $obj = URL::URL_http->new();

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

use URL::URL_base;
use Cwd;
use Exporter;
require 5.004;

@ISA = qw(Exporter URL::URL_base);

sub init()
   {
   ###############################################################
   # init                                                        #
   ###############################################################
   # modified : Wed Feb 15 18:18:18 2006 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   my $self=shift;
   $self->{webget}="wget";
   }

sub get()
   {
   my $self=shift;
   my ($urlobject, $location)=@_;
   my $rv="";

   use LWP::Simple qw(&getstore);
   use File::Basename;
   my ($dir,$dirname)=($location=~/(.*)\/(.*)/);

   require Utilities::AddDir;
   if ( $dir ne $location )
      {
      AddDir::adddir($dir);
      }
   
   my @cvscmd=($self->{cvsco});
   my $version=$url->param('version');
   my $module;
   ($module=$url->param('module'))=~s/\/$//;
   my $filename="";
   if ( $module=~/\/.?/ )
      {
      ($filename=$module)=~s/.*\///;
      }
   
   push @cvscmd, ("-d", "$dirname");
   if ( $version && ($version ne "") )
      {
      push @cvscmd, ("-r", "$version");
      }
   
   return $rv;
   }

1;

__END__


=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY

=cut

