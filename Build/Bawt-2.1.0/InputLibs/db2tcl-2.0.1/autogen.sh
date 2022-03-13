#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

ORIGDIR=`pwd`
cd $srcdir
PROJECT=db2tcl

DIE=0

test -z "$AUTOCONF" && AUTOCONF=autoconf
test -z "$AUTOHEADER" && AUTOHEADER=autoheader
test -z "$AUTOMAKE" && AUTOMAKE=automake
test -z "$ACLOCAL" && ACLOCAL=aclocal
    
(autoconf --version) < /dev/null > /dev/null 2>&1 || {
	echo
	echo "You must have autoconf installed to compile $PROJECT."
	echo "Download the appropriate package for your distribution,"
	echo "or get the source tarball at ftp://ftp.gnu.org/pub/gnu/"
	DIE=1
}

(libtool --version) < /dev/null > /dev/null 2>&1 || {
        echo
        echo "You must have libtool installed to compile $PROJECT."
        echo "Get ftp://ftp.gnu.org/gnu/libtool/libtool-1.4.tar.gz"
        echo "(or a newer version if it is available)"
        DIE=1
}

(automake --version) < /dev/null > /dev/null 2>&1 || {
	echo
	echo "You must have automake installed to compile $PROJECT."
	echo "Get ftp://ftp.gnu.org/pub/gnu/automake/automake-1.7.6.tar.gz"
	echo "(or a newer version if it is available)"
	DIE=1
}

if test "$DIE" -eq 1; then
	exit 1
fi

case $CC in
*xlc | *xlc\ * | *lcc | *lcc\ *) am_opt=--include-deps;;
esac

$ACLOCAL $ACLOCAL_FLAGS

# optionally feature autoheader
($AUTOHEADER --version)  < /dev/null > /dev/null 2>&1 && $AUTOHEADER

# run libtoolize ...
libtoolize --force --copy

$AUTOMAKE $am_opt --add-missing --copy
$AUTOHEADER
$AUTOCONF
cd $ORIGDIR

($srcdir/configure --enable-maintainer-mode "$@") || {
	exit 1
}

echo 
echo "Now type 'make' to compile $PROJECT."

