# $Id: Makefile 384 2014-09-12 21:57:00Z lbayuk $
# Makefile for pgtcl-ng/extra: 
#     pgtclsh (Tcl shell + PostgreSQL)
#     pgwish (Tcl/Tk shell + PostgreSQL)

# ===== Configure these =====
# Include paths: needs to find libpgtcl.h and Tcl headers:
INCLUDES=-I..

# Link libpgtcl:
libpgtcl_link=-L.. -lpgtcl2.1.1
# Link Tcl libraries:
tcl_link=-ltcl
# Link Tk libraries:
tk_link=-ltk
# Link PostgreSQL libpq:
libpq_link=-L/opt/postgres/lib -lpq

CFLAGS=-O -Wall $(INCLUDES)

TCL_LDFLAGS=$(libpgtcl_link) $(tcl_link) $(libpq_link)
TK_LDFLAGS=$(libpgtcl_link) $(tk_link) $(tcl_link) $(libpq_link)

# ===========================


all: pgtclsh pgwish

pgtclsh: pgtclAppInit.o
	$(CC) $(TCL_LDFLAGS) -o pgtclsh pgtclAppInit.o

pgwish: pgtkAppInit.o
	$(CC) $(TK_LDFLAGS) -o pgwish pgtkAppInit.o

clean distclean:
	rm -f pgtclAppInit.o pgtkAppInit.o pgtclsh pgwish
