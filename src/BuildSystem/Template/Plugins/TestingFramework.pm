#____________________________________________________________________ 
# File: TestingFramework.pm
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2007-02-27 15:47:41+0100
# Revision: $Id: TestingFramework.pm,v 1.2 2007/02/27 15:25:25 sashby Exp $ 
#
# Copyright: 2007 (C) Shaun ASHBY
#
#--------------------------------------------------------------------
package BuildSystem::Template::Plugins::TestingFramework;

=head1 NAME

BuildSystem::Template::Plugins::TestingFramework - A plugin to supply capabilities
                                      for a simple testing framework.

=head1 SYNOPSIS

	my $obj = BuildSystem::Template::Plugins::TestingFramework->new();

=head1 DESCRIPTION

A plugin which can provide virtual functions for configuring a unit test framework.
This plugin provides a Singleton object once instantiated.

This package is currently under development.
    
=head1 METHODS

=over

=cut

use vars qw( @ISA );
use base qw(Template::Plugin);
use Template::Plugin;
use Exporter;
@ISA=qw(Exporter);

sub load() {
    ###############################################################
    # new                                                         #
    ###############################################################
    # modified : Tue Feb 27 15:48:05 2007 / SFA                   #
    # params   :                                                  #
    #          :                                                  #
    # function :                                                  #
    #          :                                                  #
    ###############################################################
    my ($class, $context) = @_;
    my $self = {
	_CONTEXT => $context,
	_TESTCOUNT => 0
	};
    bless($self, $class);
    return $self;
}

sub unitTest() {
    my $self=shift;
    my ($name)=@_;
    $self->{_TESTCOUNT}++;
    print "Plugins::TestingFramework: Defining unit test ",$name,"\n";
}

sub new() {
    my ($self, $context, @param) =@_;
    return $self;
}

sub DESTROY {
    my $self=shift;
    # Use the destroy method to dump some statistics at the end of the job:
    # <put some print here>
    print "==> TestingFramework statistics: ".$self->{_TESTCOUNT}." tests defined.\n";
}

1;

__END__

=back

=head1 AUTHOR/MAINTAINER

Shaun ASHBY

=cut

