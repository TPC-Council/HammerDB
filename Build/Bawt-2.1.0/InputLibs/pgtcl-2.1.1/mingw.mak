# pgtclng/Makefile for MinGW32
# $Id: mingw.mak 385 2014-09-12 21:57:05Z lbayuk $
# This is a simple Makefile for building pgtclng using the MinGW tools on
# Windows.
# You must edit the PGSQL and TCL symbols below, at least, before using.
#
# This builds a stubs-enabled DLL for pgtcl-ng. If you want a non-stubs-
# enabled version, remove the definition of USE_TCL_STUBS and change the
# TCLLIB definition below.
#
# When loading the built libpgtcl.dll into a Tcl shell or application,
# libpq.dll must be on your PATH.

PACKAGE_VERSION = 2.1.1

# Path to PostgreSQL top-level installation directory:
PGSQL=e:/local/pgsql

# Path to Tcl installation base directory:
TCL=c:/local/tcl8.6
# Tcl stub library name:
TCLLIB=tclstub86

# PostgreSQL version tests:
# These require PostgreSQL-9.3.x and higher:
PG93DEFS=\
 -DHAVE_LO_TELL64=1\
 -DHAVE_PQESCAPELITERAL=1

# These require PostgreSQL-8.3.x and higher:
PG83DEFS=\
 -DHAVE_LO_TRUNCATE=1\
 -DHAVE_PQDESCRIBEPREPARED=1\
 -DHAVE_PQENCRYPTPASSWORD=1\
 -DHAVE_PQESCAPEBYTEACONN=1\
 -DHAVE_PQESCAPESTRINGCONN=1

# Uncomment to configure for PostgreSQL-9.3.x or higher:
PGDEFS=$(PG83DEFS) $(PG93DEFS)
# Uncomment to configure for PostgreSQL-8.3.x through 9.2.x:
#PGDEFS=$(PG83DEFS)
# If you are building with a version older than PostgreSQL-8.3.0, you
# are on your own. (8.2.x and older are unsupported by the PostgreSQL
# project as of Dec 2011.)

# Stubs enabled:
STUBS=-DUSE_TCL_STUBS

# ===========================

PG_INCLUDES = -I"$(PGSQL)/include"
PG_LIBS = -L"$(PGSQL)/lib" -lpq
TCL_INCLUDES = -I"$(TCL)/include"
TCL_LIBS = -L"$(TCL)/lib" -l$(TCLLIB)
OBJS = pgtcl.o pgtclCmds.o pgtclId.o pgtclres.o

CC = gcc
CFLAGS_EXTRA = -O2 -Wall
# Note: enable-runtime-pseudo-reloc-v2 option is via the MinGW mailing
# list. Without it, programs crash when calling PQisnonblocking.
# enable-auto-import avoids a warning related to that same function.
LDFLAGS_EXTRA = -Wl,-enable-runtime-pseudo-reloc-v2 -Wl,-enable-auto-import

# Note: Tcl includes must be first, because EnterpriseDB ships tcl.h
# from a possibly older version of Tcl inside the PostgreSQL includes dir.
INCLUDES =  $(TCL_INCLUDES) $(PG_INCLUDES)

DEFS = -DPACKAGE_VERSION=\"$(PACKAGE_VERSION)\" $(PGDEFS) $(STUBS)

CFLAGS = $(CFLAGS_EXTRA) $(INCLUDES) $(DEFS)

LDFLAGS = $(LDFLAGS_EXTRA)

all: dll

dll: $(OBJS)
	$(CC) -shared -o libpgtcl.dll $(LDFLAGS) $(OBJS) $(TCL_LIBS) $(PG_LIBS)

pgtclres.o: pgtclres.rc
	windres pgtclres.rc pgtclres.o

clean:
	-erase $(OBJS)
