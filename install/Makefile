#____________________________________________________________________ 
# File: Makefile
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2006-08-31 14:39:18+0200
# Revision: $Id: Makefile.in,v 1.3 2007/02/27 17:20:19 sashby Exp $ 
#
# Copyright: 2006 (C) Shaun ASHBY
#
#--------------------------------------------------------------------

.PHONY: 

SCRAM_HOME=/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0
SCRAM_BASEDIR=/afs/cern.ch/user/s/sashby/w2/SCRAM
SCRAM_VERSION=V2_0_0
INSTALLDIR=/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0/src
SCRAM_EXEDIR=/afs/cern.ch/user/s/sashby/scripts
SCRAM_EXENAME=scram2
SCRAM_LOOKUPDB=/afs/cern.ch/user/s/sashby/w2/SCRAM/scramdb
SCRAM_MANDIR=/afs/cern.ch/user/s/sashby/w2/SCRAM/V2_0_0/doc

all: install doc

info:
	@echo "------------------------------------------------"
	@echo " SCRAM_HOME     = $(SCRAM_HOME)"
	@echo " SCRAM_BASEDIR  = $(SCRAM_BASEDIR)"
	@echo " SCRAM_LOOKUPDB = $(SCRAM_LOOKUPDB)"
	@echo " SCRAM_EXEDIR   = $(SCRAM_EXEDIR)"
	@echo " SCRAM_EXENAME  = $(SCRAM_EXENAME)"
	@echo "------------------------------------------------"

install: info
	@if [ ! -d $(SCRAM_EXEDIR) ]; then \
	 mkdir -p $(SCRAM_EXEDIR) > /dev/null 2>&1; \
	 echo "Creating install directory"; \
	fi
	@echo "Installing SCRAM version $(SCRAM_VERSION) to $(SCRAM_EXEDIR)"
	@chmod +x scram.pl
	@cp scram.pl $(INSTALLDIR)/main
	@cp scram.pl $(SCRAM_EXEDIR)/$(SCRAM_EXENAME)
	@echo ""
	@echo "------------------------------------------------------------------"
	@echo "Installation completed at `date`"
	@echo "------------------------------------------------------------------"
	@echo " "

doc: pdf doxygen
pdf:
	@if [ ! -d $(SCRAM_MANDIR) ]; then \
	 mkdir -p $(SCRAM_MANDIR) > /dev/null 2>&1; \
	 echo "Creating doc install directory"; \
	fi
	@echo "Building SCRAM manual (PDF from latex)..."
	@cd $(SCRAM_HOME)/doc/tex/manual; latex SCRAM-manual; makeindex SCRAM-manual.idx; latex SCRAM-manual; dvipdf SCRAM-manual
	@mv $(SCRAM_HOME)/doc/tex/manual/SCRAM-manual.pdf $(SCRAM_MANDIR)

doxygen:
	@echo "Building SCRAM reference manual for SCRAM developers..."
	@cd $(SCRAM_HOME)/doc/doxygen; ls

#############