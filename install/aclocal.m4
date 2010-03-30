dnl ____________________________________________________________________ 
dnl  File: aclocal.m4, macros for SCRAM installation
dnl ____________________________________________________________________ 
dnl   
dnl  Author:  <Shaun.Ashby@cern.ch>
dnl  Update: 2004-03-17 20:27:00+0100
dnl  Revision: $Id: aclocal.m4,v 1.8.4.1 2007/03/02 13:53:59 sashby Exp $ 
dnl 
dnl  Copyright: 2004 (C) 
dnl 
dnl --------------------------------------------------------------------
dnl
AC_DEFUN(AC_SCRAM_INIT,
dnl
dnl Check for SCRAM_VERSION, do init
dnl
[
SCRAM_HOME=""
SCRAM_BASEDIR=""
SCRAM_VERSION=""
AC_MSG_CHECKING(for SCRAM source directory and environment variables)
AC_ARG_WITH(homedir,
[  --with-homedir=NAME              The base of the scram source tree],
SCRAM_HOME="$withval")
if test x"$SCRAM_HOME" = x; then
SCRAM_HOME=`cd ..; pwd`
fi
export SCRAM_HOME
AC_MSG_RESULT([using $SCRAM_HOME])
SCRAM_BASEDIR=`cd $SCRAM_HOME; cd ..; pwd`
export SCRAM_BASEDIR
AC_MSG_CHECKING(for SCRAM version)
SCRAM_VERSION=`echo $SCRAM_HOME | sed -e 's/.*\///g'`
export SCRAM_VERSION
AC_MSG_RESULT([ version is $SCRAM_VERSION])

AC_SUBST(SCRAM_HOME)
AC_SUBST(SCRAM_BASEDIR)
AC_SUBST(SCRAM_VERSION)
])

dnl #####################################################################################
AC_DEFUN(AC_SCRAM_CHECK_PERL,
dnl
dnl Check for Perl5
dnl
[
PERL5="perl"
PERL5VERSION=""
PERL5ARCH=""

AC_MSG_CHECKING(for Perl5)
perl_version_line=`perl -v | grep "This"`

PERL5VERSION=`echo $perl_version_line | sed 's/^This is perl, v\([[0-9\.]]*\).*$/\1/'`
PERL5ARCH=`echo $perl_version_line | sed 's/^This is perl, v[[0-9\.]]* built for \(.*\)$/\1/'`

if test x"$PERL5VERSION" = x; then
   AC_MSG_ERROR([failed to find Perl5 on this system....])
else
   AC_MSG_RESULT($PERL5VERSION)
fi
export PERL5VERSION
export PERL5ARCH
])
dnl ####################################################################
AC_DEFUN(AC_SCRAM_CHECK_MAKE,
dnl
dnl Check for gmake v3.79 or later
dnl
[
MAKE="make"
AC_MSG_CHECKING(for GNU Make)
make_version=`make -v | grep Make | sed 's/GNU Make version \([[0-9.*]]*\).*$/\1/'`
make_found=$?
if test x"$make_version" = x; then
   AC_MSG_ERROR([failed to find GNU Make on this system....])
else
   AC_MSG_RESULT($make_version)
fi
])
dnl ####################################################################
AC_DEFUN(AC_SET_PERLEXE,
dnl
dnl Macro to allow setting of Perl location (instead of "/usr/bin/env perl")
dnl
[
AC_MSG_CHECKING(for Perl executable location)
AC_ARG_WITH(perlexe,[  --with-perlexe=LOC                Location of Perl executable],
PERLEXE="$withval")
if test x"$PERLEXE" = x; then
PERLEXE="/usr/bin/env perl"
AC_MSG_RESULT([using $PERLEXE as default])
else
AC_MSG_RESULT([$PERLEXE])
fi
AC_SUBST(PERLEXE)
])
dnl ####################################################################
AC_DEFUN(AC_SET_SCRAM_SITENAME,
dnl
dnl Macro to allow setting of SCRAM_SITENAME. Default is CERN
dnl
[
SCRAM_SITENAME=""
AC_MSG_CHECKING(for SITENAME settings)
AC_ARG_WITH(sitename,
[  --with-sitename=NAME              Name of this site is NAME (default is CERN)],
SCRAM_SITENAME="$withval")
if test x"$SCRAM_SITENAME" = x; then
SCRAM_SITENAME="CERN"
AC_MSG_RESULT([using default sitename (CERN)])
else
AC_MSG_RESULT([using $SCRAM_SITENAME])
fi
AC_SUBST(SCRAM_SITENAME)
])
dnl ####################################################################
AC_DEFUN(AC_SET_SCRAM_LOOKUPDB,
dnl
dnl Macro to allow setting of project.lookup file (the SCRAM database)
dnl Normally this is done inside SCRAM (default is under SCRAM_HOME/scramdb). This
dnl can be used to override internal settings
dnl
[
SCRAM_LOOKUPDB_DIR=$SCRAM_BASEDIR/scramdb
AC_MSG_CHECKING(for SCRAM Database location)
AC_ARG_WITH(scramdb-dir,
[  --with-scramdb-dir=DIR            SCRAM project database location dir],
SCRAM_LOOKUPDB_DIR="$withval")
if test x"$SCRAM_LOOKUPDB_DIR" = x; then
SCRAM_LOOKUPDB_DIR=""
AC_MSG_RESULT([default lookup db location under $SCRAM_BASEDIR/scramdb will be used])
else
AC_MSG_RESULT([using $SCRAM_LOOKUPDB_DIR])
fi
AC_SUBST(SCRAM_LOOKUPDB_DIR)
])
dnl ####################################################################
AC_DEFUN(AC_SCRAM_INSTALL_DIR,
dnl
dnl
dnl
[
SCRAM_EXEDIR=""
AC_MSG_CHECKING(for installation area where scram is to be installed)
AC_ARG_WITH(install-dir,
[  --with-install-dir=DIR            dir where scram executable will be located],
SCRAM_EXEDIR="$withval")
if test x"$SCRAM_EXEDIR" = x; then
SCRAM_EXEDIR=$SCRAM_HOME/bin
export SCRAM_EXEDIR
else
export SCRAM_EXEDIR
fi
AC_MSG_RESULT([scram executable will be installed at $SCRAM_EXEDIR])
AC_SUBST(SCRAM_EXEDIR)
])
dnl ####################################################################
AC_DEFUN(AC_SCRAM_MAN_INSTALL_DIR,
dnl
dnl
dnl
[
SCRAM_MANDIR=""
AC_MSG_CHECKING(for directory where scram documentation is to be installed)
AC_ARG_WITH(doc-dir,
[  --with-doc-dir=DIR                dir where scram documentation will be located],
SCRAM_MANDIR="$withval")
if test x"$SCRAM_MANDIR" = x; then
SCRAM_MANDIR=$SCRAM_HOME/doc
export SCRAM_MANDIR
else
export SCRAM_MANDIR
fi
AC_MSG_RESULT([scram documentation will be installed at $SCRAM_MANDIR])
AC_SUBST(SCRAM_MANDIR)
])
dnl ####################################################################
AC_DEFUN(AC_SCRAM_EXE_NAME,
dnl
dnl
dnl
[
SCRAM_EXENAME=""
SCRAM_OLD_DO_REMOVE=""
AC_MSG_CHECKING(for name of SCRAM executable to be installed)
AC_ARG_WITH(install-name,
[  --with-install-name=NAME          name of installed scram executable],
SCRAM_EXENAME="$withval")
if test x"$SCRAM_EXENAME" = x; then
SCRAM_EXENAME="scram"
export SCRAM_EXENAME
SCRAM_OLD_DO_REMOVE="true"
export SCRAM_OLD_DO_REMOVE
else
export SCRAM_OLD_DO_REMOVE
export SCRAM_EXENAME
fi
AC_MSG_RESULT([scram executable will be called $SCRAM_EXENAME])
AC_SUBST(SCRAM_EXENAME)
])
