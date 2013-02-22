#!/bin/bash -e
# A script to convert sourceware's CVS repo to a set of Git repos
# Written by Simon Cook <simon.cook@embecosm.com>

# Copyright (c) 2013 Embecosm Limited

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

#######################################
##           Configuration           ##
#######################################

# 1. Location to store working directory (script will only work in there, except
#    for removing CVSPS working files on each iteration)
BASEDIR='/opt/sourcewaretree'
# 2. Configuration for which repositories to upload
#    To enable sync and upload, set the enable variable to 1 and destination
#    (I have only included a selection here, but really can do all if we want)
# CGEN
CGEN=1
CGENREPO="git@github.com:embecosm/cgen.git"
# binutils
BINUTILS=0
BINURILSREPO="git@github.com:embecosm/binutils.git"
# src - the entire tree
ALLSRC=0
ALLSRCREPO="git@github.com:embecosm/sourceware.git"

# We need a custom function to merge in changes from the different
# locations that changes may be found in.
synccvs() {
  # Make sure parent directory works, otherwise sync fails
  mkdir -p `dirname ${DESTDIR}/${1}`
  # Firstly if directory, sync dir
  if test -d ${SRCDIR}/${1}; then
    rsync -az ${SRCDIR}/${1}/ ${DESTDIR}/${1}
    return
  fi
  # Next, if file not in attic, sync that
  if test -e ${SRCDIR}/${1},v; then
    rsync -az ${SRCDIR}/${1},v ${DESTDIR}/${1},v
    return
  fi
  # Finally, check if file in attic, then sync that
  if test -e `dirname ${SRCDIR}/${1}`/Attic/`basename ${SRCDIR}/${1}`,v; then
    mkdir -p `dirname ${DESTDIR}/${1}`/Attic
    rsync -az `dirname ${SRCDIR}/${1}`/Attic/`basename ${SRCDIR}/${1}`,v \
      `dirname ${DESTDIR}/${1}`/Attic/`basename ${DESTDIR}/${1}`,v
    return
  fi
  echo "Path doesnt exist! ${1}"
  exit 1
}

# This function acts as an alias for synccvsing the src-support module found in
# CVSROOT/modules on sourceware
syncsrcsupport() {
  synccvs src/.cvsignore
  synccvs src/COPYING
  synccvs src/COPYING3
  synccvs src/COPYING.LIB
  synccvs src/COPYING3.LIB
  synccvs src/COPYING.NEWLIB
  synccvs src/COPYING.LIBGLOSS
  synccvs src/ChangeLog
  synccvs src/MAINTAINERS
  synccvs src/Makefile.def
  synccvs src/Makefile.in
  synccvs src/Makefile.tpl
  synccvs src/README
  synccvs src/README-maintainer-mode
  synccvs src/compile
  synccvs src/config
  synccvs src/config-ml.in
  synccvs src/config.guess
  synccvs src/config.if
  synccvs src/config.rpath
  synccvs src/config.sub
  synccvs src/configure
  synccvs src/configure.ac
  synccvs src/configure.in
  synccvs src/contrib
  synccvs src/depcomp
  synccvs src/etc
  synccvs src/gettext.m4
  synccvs src/install-sh
  synccvs src/lt~obsolete.m4
  synccvs src/ltgcc.m4
  synccvs src/ltsugar.m4
  synccvs src/ltversion.m4
  synccvs src/ltoptions.m4
  synccvs src/libtool.m4
  synccvs src/ltcf-c.sh
  synccvs src/ltcf-cxx.sh
  synccvs src/ltcf-gcj.sh
  synccvs src/ltconfig
  synccvs src/ltmain.sh
  synccvs src/makefile.vms
  synccvs src/missing
  synccvs src/mkdep
  synccvs src/mkinstalldirs
  synccvs src/move-if-change
  synccvs src/setup.com
  synccvs src/src-release
  synccvs src/symlink-tree
  synccvs src/ylwrap
}

# Get sources (we don't check out CVSROOT because we don't use it)
export SRCDIR=${BASEDIR}/sourceware
rsync -az -v --delete --delete-excluded --exclude CVSROOT/** \
  sourceware.org::src-cvs/ ${SRCDIR}

#######################################
##            cgen Module            ##
#######################################
if test ${CGEN} == 1; then
  export DESTDIR=${BASEDIR}/cgen
  export GITDIR=${BASEDIR}/cgen.git
  # Sync CVS Tree
  rm -Rf ${DESTDIR}
  mkdir -p ${DESTDIR}
  syncsrcsupport
  synccvs src/CVS
  synccvs src/cgen
  synccvs src/cpu
  # Remove cvsps temporary files
  CVSPSFILE=`echo ${DESTDIR} | sed 's/\//\#/g'`
  rm -Rf ~/.cvsps/${CVSPSFILE}*
  # Reinitialize cvs for our new repo and then convert (using src as module)
  cvs -d ${DESTDIR} init
  git cvsimport -v -d ${DESTDIR} -C ${GITDIR} -p -z,120 -o master -k src
  # Push to GitHub
  cd ${GITDIR}
  git remote rm github || true
  git remote add github ${CGENREPO}
  git push github --mirror
fi

#######################################
##          binutils Module          ##
#######################################
if test ${BINUTILS} == 1; then
  export DESTDIR=${BASEDIR}/binutils
  export GITDIR=${BASEDIR}/binutils.git
  # Sync CVS Tree
  rm -Rf ${DESTDIR}
  mkdir -p ${DESTDIR}
  syncsrcsupport
  synccvs src/CVS
  synccvs src/binutils
  synccvs src/opcodes
  synccvs src/bfd
  synccvs src/libiberty
  synccvs src/include
  synccvs src/gas
  synccvs src/gprof
  synccvs src/ld
  synccvs src/gold
  synccvs src/elfcpp
 synccvs src/intl
  synccvs src/texinfo
  synccvs src/cpu
  # Remove cvsps temporary files
  CVSPSFILE=`echo ${DESTDIR} | sed 's/\//\#/g'`
  rm -Rf ~/.cvsps/${CVSPSFILE}*
  # Reinitialize cvs for our new repo and then convert (using src as module)
  cvs -d ${DESTDIR} init
  git cvsimport -v -d ${DESTDIR} -C ${GITDIR} -p -z,120 -o master -k src
  # Push to GitHub
  cd ${GITDIR}
  git remote rm github || true
  git remote add github ${BINUTILSREPO}
  git push github --mirror
fi

#######################################
##      src Module (everything)      ##
#######################################
if test ${ALLSRC} == 1; then
  export DESTDIR=${BASEDIR}/allsrc
  export GITDIR=${BASEDIR}/allsrc.git
  # Sync CVS Tree
  rm -Rf ${DESTDIR}
  mkdir -p ${DESTDIR}
  synccvs src
  # Remove cvsps temporary files
  CVSPSFILE=`echo ${DESTDIR} | sed 's/\//\#/g'`
  rm -Rf ~/.cvsps/${CVSPSFILE}*
  # Reinitialize cvs for our new repo and then convert (using src as module)
  cvs -d ${DESTDIR} init
  git cvsimport -v -d ${DESTDIR} -C ${GITDIR} -p -z,120 -o master -k src
  # Push to GitHub
  cd ${GITDIR}
  git remote rm github || true
  git remote add github ${ALLSRCREPO}
  git push github --mirror
fi
