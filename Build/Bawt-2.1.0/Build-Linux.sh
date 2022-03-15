#!/bin/bash

if [ $# -le 2 ] ; then
    echo ""
    echo "Usage: `basename $0` Architecture SetupFile Action [Target1] [TargetN]"
    echo "  Architecture  : x86 x64"
    echo "  Actions       : list clean extract configure compile distribute finalize complete update simulate touch"
    echo "  Default target: all"
    echo ""
    exit 1
fi

ARCH=$1
SETUPFILE=$2
ACTION="$3"
shift 3

if [ $# -eq 0 ] ; then
    if [ "${ACTION}" == "clean" ] ; then
        echo "Warning: This may clean everything. Use \"clean all\" to allow this operation."
        exit 1
    fi
    if [ "${ACTION}" == "complete" ] ; then
        echo "Warning: This may rebuild everything. Use \"complete all\" to allow this operation."
        exit 1
    fi
    TARGETS=all
else
    TARGETS=$@
fi

if [ "${ARCH}" == "x64" ] ; then
    BITS=64
else
    BITS=32
fi

OUTROOTDIR="../BawtBuild"
TCLKIT="./tclkit-Linux${BITS}"
NUMJOBS=`nproc`
ACTION="--${ACTION}"

BAWTOPTS="--rootdir ${OUTROOTDIR} --architecture ${ARCH} --numjobs ${NUMJOBS} --url http://www.hammerdb.com/build --finalizefile Setup/HammerDBFinalize.bawt"

# Build all libraries as listed in Setup file.
${TCLKIT} Bawt.tcl ${BAWTOPTS} ${ACTION} ${SETUPFILE} ${TARGETS}

exit 0
