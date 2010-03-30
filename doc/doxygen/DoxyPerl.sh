#!/bin/sh
perl $DOXY_PERL_FLAGS ./DoxyFilt.pl \
     --filter=Perl --filter=POD \
     $DOXY_FILT_FLAGS $*
