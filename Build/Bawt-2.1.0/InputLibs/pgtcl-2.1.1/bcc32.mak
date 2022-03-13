# pgtclng/Makefile for Borland C++ 5.5
# $Id: bcc32.mak 272 2011-03-24 00:22:40Z lbayuk $
#  This originally started from the win32.mak (MS VC++ makefile) but has
# been rewritten using H.G.'s sample files and a lot of simplification.
#
# This builds a stubs-enabled DLL for pgtcl-ng. If you want a non-stubs-
# enabled version, as was done with pgtclng-1.7.0 and older, remove the
# definition of USE_TCL_STUBS and change the TCLLIB definition below.
#
# This assumes your PATH includes the Borland BCC bin directory, so
# it can find MAKE, and that your bcc32.cfg/ilink32.cfg files were
# created (in the Borland bin directory) per the installation notes,
# so it can find the include files and libraries.

# Release version, needed by the source code.
MAJOR_VERSION=1
MINOR_VERSION=7
PATCHLEVEL=.2
VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)$(PATCHLEVEL)

# Path to Borland compiler installation base directory:
BORLAND=c:\apps\bcc
# Path to Tcl installation base directory:
TCL=c:\apps\tcl
# Path to top-level PostgreSQL source directory (src/ in the distribution):
POSTGRESQL=c:\src\pgsql\src
# Path to PostgreSQL libpq source directory:
LIBPQ=$(POSTGRESQL)\interfaces\libpq
# Path to libpq build directory:
LIBPQDIR=$(LIBPQ)\Release

# Commands:
LINK=ilink32

# Include paths:
INCLUDES=-I$(POSTGRESQL)\include -I$(LIBPQ) -I$(TCL)\include
# Library path:
LIBDIRS=-L$(TCL)\lib -L$(LIBPQDIR)

# Tcl Stubs library: This is built from tclstublib.c using BCC.
TCLLIB=tclstub85bcc.lib
STUBS=-DUSE_TCL_STUBS
# If you do not want a stubs-enabled DLL, or can't build the above file, you
# can make a non-stubs-enabled version of pgtclng. Comment out the two lines
# above this comment, and uncomment these.  Use coff2omf (included with BCC)
# to convert the Tcl library tcl85.lib to tcl85omf.lib.
# Tcl Library name, non-stubs: This is converted with coff2omf.
#TCLLIB=tcl85omf.lib
#STUBS=

# PostgreSQL libpq export library name - this was directly built with bcc:
PGLIB=blibpqdll.lib
# PostgreSQL libpq loadable library
PGDLL=blibpq.dll
# If you are building with a version older than PostgreSQL-8.3.0 you
# may need to undefine some of these.
PGDEFS=$(STUBS) \
 -DHAVE_LO_TRUNCATE=1\
 -DHAVE_PQDESCRIBEPREPARED=1\
 -DHAVE_PQENCRYPTPASSWORD=1\
 -DHAVE_PQESCAPEBYTEACONN=1\
 -DHAVE_PQESCAPESTRINGCONN=1

# Destination for "make install":
DEST=$(TCL)\lib\Pgtcl$(VERSION)

# Compiler flags and preprocessor defines - uncomment one set for debug/release:
# Compiler flags for no-debug:
CCFLAGS=-5 -d -WD -tWM -c -v- -vi- -w -O2 -OS -a8 -w-par -w-pia
# -5 : Generate Pentium instructions
# -d : merge duplicate strings
# -WD : Target is a DLL
# -tWM : Multi-threaded target
# -c : Compile to .obj without linking
# -v- : Don't enable source debugging
# -vi- : Don't expand inline functions
# -O2 : Optimize for speed
# -OS : Pentium instruction scheduling
# -a8 : 8-byte alignment (default is 4)
# -w : Display warnings on
# -w-par : Omit warning: parameter not used (Tcl procs have a lot)
# -w-pia : Omit warning: possibly incorrect assignment, because bcc doesn't
#          honor the double parens ((a = exp)) hint.
# Compiler preprocessor defines:
DEFINES=-DNDEBUG -DWIN32 -D_WINDOWS -D_USRDLL $(PGDEFS) -DVERSION=\"$(VERSION)\"
#
# Compiler flags for debugging:
#CCFLAGS=-5 -d -WD -c -r- -v -vi- -y -w -Od -a8 -w-par -w-pia
#  -r- : do not use register vars
#  -v : turn on debug
#  -vi- : No inline expansion
#  -y : turn on line numbers
#  -Od : no optimization
#    Omit -OS Pentium scheduling
# Compiler preprocessor defines:
#DEFINES=-D_DEBUG -DWIN32 -D_WINDOWS -D_USRDLL $(PGDEFS) -DVERSION=\"$(VERSION)\"

# Linker flags and startup file (c0d32):
LINKFLAGS=$(LIBDIRS) -ap -Tpd -c -Gn $(BORLAND)\lib\c0d32.obj
# -ap : Build a 32-bit Windows console app (vs -aa, a Windows app)
# -Tpd : Targets a Windows DLL file
# -c : Treats case as significant in symbols
# -Gn : Don't make files for incremental link.
# Linker libraries:
# Note: cw32mt is multi-threaded static RTL. Don't use cw32mti (multi-threaded
# import RTL), because fprintf will crash.
LINKLIBS=$(TCLLIB) $(PGLIB) import32.lib cw32mt.lib

# Combined compiler flags/options used by default .c.obj rule:
CFLAGS=$(DEFINES) $(INCLUDES) $(CCFLAGS)

# List of objects making up the target:
OBJS=pgtcl.obj pgtclCmds.obj pgtclId.obj

# Default thing to build:
TARGET=libpgtcl
all: $(TARGET).dll

# Things to build:
$(TARGET).dll: $(OBJS)
	$(LINK) $(LINKFLAGS) $(OBJS),$@,-x,$(LINKLIBS),,

# Source and header dependencies:
pgtcl.obj: pgtcl.c libpgtcl.h pgtclCmds.h pgtclId.h
pgtclCmds.obj: pgtclCmds.c pgtclCmds.h pgtclId.h
pgtclId.obj: pgtclId.c pgtclCmds.h pgtclId.h

# Install Pgtcl as a loadable package:
install: $(TARGET).dll
	-mkdir $(DEST)
	copy $(LIBPQDIR)\$(PGDLL) $(DEST)
	copy $(TARGET).dll $(DEST)
	copy pkgIndex.tcl.win32 $(DEST)\pkgIndex.tcl

# Cleanup: Remove all but the target DLL
clean:
	-del $(OBJS)
	-del $(TARGET).tds
	-del $(TARGET).il?
