db2tclsh_LDFLAGS = @LDFLAGS@ @TCL_LIB_SPEC@
db2wish_LDFLAGS = @LDFLAGS@ @TCL_LIB_SPEC@ @TK_LIB_SPEC@

AM_CFLAGS = -I@TCL_EXEC_PREFIX@/include -I@TK_EXEC_PREFIX@/include

bin_PROGRAMS = db2tclsh db2wish
db2tclsh_SOURCES = db2tclsh.c db2tclcmds.c db2tcl.c
db2wish_SOURCES = db2wish.c db2tclcmds.c db2tcl.c
#EXTRA_DIST = db2tclcmds.h db2tcl.h
noinst_HEADERS = db2tclcmds.h db2tcl.h


lib_LTLIBRARIES = libdb2tcl.la
noinst_LTLIBRARIES = libdb2tcl.la

libdb2tcl_la_SOURCES = db2tclcmds.c db2tcl.c
libdb2tcl_la_LDFLAGS = -version-info 0:1:0

index:
	@echo "pkg_mkIndex -verbose .libs " | tcl

check:
	cd ../tests && $(MAKE) check

LIBTOOL_DEPS = @LIBTOOL_DEPS@
libtool: $(LIBTOOL_DEPS)
	$(SHELL) ./config.status --recheck
