#!/usr/bin/env perl
# -*-perl-*-
#____________________________________________________________________ 
# File: testsuite.pl
#____________________________________________________________________ 
#  
# Author: Shaun Ashby <Shaun.Ashby@cern.ch>
# Update: 2005-08-17 16:06:40+0200
# Revision: $Id: testsuite.pl.in,v 1.1 2005/08/17 14:32:21 sashby Exp $ 
#
# Copyright: 2005 (C) Shaun Ashby
#
#--------------------------------------------------------------------
BEGIN
   {
   # Set the path to local modules. Install dir is usually
   # SCRAM_HOME/src:
   unshift @INC,'/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0', '/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0/src';
   }

use TestSuite;

my $ts = TestSuite->new();

$ts->run();
$ts->statusreport();

my $date = `date`;
chomp($date);

print "=======================================================================","\n";
print "Test Suite run on ".$date." [ COMPLETED ] \n";
print "=======================================================================","\n";
