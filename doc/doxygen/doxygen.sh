#!/bin/sh
#____________________________________________________________________ 
# File: doxygen.sh
#____________________________________________________________________ 
#  
# Author: Shaun ASHBY <Shaun.Ashby@cern.ch>
# Update: 2005-08-08 14:27:59+0200
# Revision: $Id: doxygen.sh,v 1.2.2.1 2007/03/02 13:53:59 sashby Exp $ 
#
# Copyright: 2005 (C) Shaun ASHBY
#
#--------------------------------------------------------------------
if [[ -z ${DOXYGEN_ROOT} && -z ${GRAPHVIZ_ROOT} ]]; then
    echo "Can't find dot or doxygen. Set envs DOXYGEN_ROOT and GRAPHVIZ_ROOT"
    echo "to the base of their installations."
    exit 1
else
    export PATH=${DOXYGEN_ROOT}/bin:${GRAPHVIZ_ROOT}/bin:.:${PATH}
    export LD_LIBRARY_PATH=${GRAPHVIZ_ROOT}/lib/graphviz
    export PERL5LIB=.
    # Now run it:
    echo "Running doxygen (`which doxygen`)"
    echo "========================================================="
    doxygen
    echo "Finished at `date`"
    echo
    exit 0
fi
