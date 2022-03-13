SUBDIRS = src doc tests

LIBTOOL_DEPS = @LIBTOOL_DEPS@

libtool: $(LIBTOOL_DEPS)
	$(SHELL) ./config.status --recheck

EXTRA_DIST = db2tcl.spec tcl.m4 ibmdb2.m4