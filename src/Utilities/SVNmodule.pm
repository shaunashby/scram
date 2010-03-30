#____________________________________________________________________ 
# File: SVNmodule.pm
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2006-02-10 15:25:48+0100
# Revision: $Id: SVNmodule.pm,v 1.1 2006/02/10 18:10:14 sashby Exp $ 
#
# Copyright: 2006 (C) Shaun ASHBY
#
#--------------------------------------------------------------------
package Utillities::SVNmodule;

=head1 NAME

Utillities::SVNmodule -

=head1 SYNOPSIS

	my $obj = Utillities::SVNmodule->new();

=head1 DESCRIPTION

=head1 METHODS

=over

=cut
require 5.004;
use Exporter;
use Utilities::AddDir;

@ISA=qw(Exporter);
@EXPORT_OK=qw( );

sub new()
   {
   ###############################################################
   # new                                                         #
   ###############################################################
   # modified : Fri Feb 10 15:26:06 2006 / SFA                   #
   # params   :                                                  #
   #          :                                                  #
   # function :                                                  #
   #          :                                                  #
   ###############################################################
   my $proto=shift;
   my $class=ref($proto) || $proto;
   my $self={};
   bless $self,$class;

   $self->{myenv}={};
   $self->{svn}='svn';
   # Reset All variables
   $self->{auth}="";
   $self->{passkey}="";
   $self->{user}="";
   $self->{base}="";
   $self->set_passbase("/tmp/".$>."SVNmodule/.svnpass");
   return $self;
   }

sub set_passbase
   {
   my $self=shift;
   my $file=shift;
   my $dir;
   ($dir=$file)=~s/(.*)\/.*/$1/;
   AddDir::adddir($dir);
   $self->{passbase}=$file;
   $self->env("SVN_PASSFILE", $file);
   }

sub set_passkey
   {
   use Utilities::SCRAMUtils;
   $self=shift;
   $self->{passkey}=shift;
   my $file=$self->{passbase};
   SCRAMUtils::updatelookup($file,
			    $self->{svnroot}." ", $self->{passkey});
   }

sub set_base
   {
   $self=shift;
   $self->{base}=shift;
   $self->_updatesvnroot();
   }

sub get_base
   {
   }


sub set_user
   {
   $self=shift;
   $self->{user}=shift;
   if ( $self->{user} ne "" )
      {
      $self->{user}= $self->{user}.'@';
      }
   $self->_updatesvnroot();
   }

sub set_auth
   {
   $self=shift;
   $self->{auth}=shift;
   $self->{auth}=~s/^\:*(.*)\:*/\:$1\:/;
   
   $self->_updatesvnroot();
   }

sub env
   {
   $self=shift;
   my $name=shift;
   $self->{myenv}{$name}=shift;
   }

sub invokesvn
   {
   $self=shift;
   @cmds=@_;
   # make sure weve got the right environment
   foreach $key ( %{$self->{myenv}} )
      {
      $ENV{$key}=$self->{myenv}{$key};
      }
   # now perform the svn command
   return ( system( "$self->{svn}" ,"-Q", "-d", "$self->{svnroot}", @cmds ));
   }

sub _updatesvnroot
   {
   my $self=shift;
   $self->{svnroot}=$self->{auth}.$self->{user}.$self->{base};
   }

sub svnroot
   {
   my $self=shift;
   return $self->{svnroot};
   }

sub repository
   {
   my $self=shift;
   return $self->{base};
   }

1;

__END__
   
=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY

=cut

