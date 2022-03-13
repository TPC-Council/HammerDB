# aclocal.m4 - autoconf support, copied from TEA and customized for pgtcl-ng
#
# The reason for the customization is that TEA has no apparent way to add a
# shared library path, which is needed for PostgreSQL libpq. Earlier efforts
# replaced TEA_CONFIG_CFLAGS with PGTCL_CONFIG_FLAGS which added the
# library path. But that doesn't work with newer TEA because another
# macro calls TEA_CONFIG_CFLAGS and undoes the customization.

# Changes include:
#   Stripping out some of the Windows support. Pgtcl-ng is built
# on Windows without autoconf, so doesn't need this.
#   Remove TK support, Serial, X11.
# Add LIB_PGTCL_RUNTIME_DIR as another "rpath" directory.
# NOTE: TEA_CONFIG_FLAGS has the additional directory coded only for
# some architectures, and the syntax is untested except for Linux.

AC_PREREQ(2.60)

#------------------------------------------------------------------------
# TEA_PATH_TCLCONFIG --
#
#	Locate the tclConfig.sh file and perform a sanity check on
#	the Tcl compile flags
#
# Arguments:
#	none
#
# Results:
#
#	Adds the following arguments to configure:
#		--with-tcl=...
#
#	Defines the following vars:
#		TCL_BIN_DIR	Full path to the directory containing
#				the tclConfig.sh file
#------------------------------------------------------------------------

AC_DEFUN([TEA_PATH_TCLCONFIG], [
    dnl Make sure we are initialized
    AC_REQUIRE([TEA_INIT])
    #
    # Ok, lets find the tcl configuration
    # First, look for one uninstalled.
    # the alternative search directory is invoked by --with-tcl
    #

    if test x"${no_tcl}" = x ; then
	# we reset no_tcl in case something fails here
	no_tcl=true
	AC_ARG_WITH(tcl,
	    AC_HELP_STRING([--with-tcl],
		[directory containing tcl configuration (tclConfig.sh)]),
	    with_tclconfig=${withval})
	AC_MSG_CHECKING([for Tcl configuration])
	AC_CACHE_VAL(ac_cv_c_tclconfig,[

	    # First check to see if --with-tcl was specified.
	    if test x"${with_tclconfig}" != x ; then
		case ${with_tclconfig} in
		    */tclConfig.sh )
			if test -f ${with_tclconfig}; then
			    AC_MSG_WARN([--with-tcl argument should refer to directory containing tclConfig.sh, not to tclConfig.sh itself])
			    with_tclconfig=`echo ${with_tclconfig} | sed 's!/tclConfig\.sh$!!'`
			fi ;;
		esac
		if test -f "${with_tclconfig}/tclConfig.sh" ; then
		    ac_cv_c_tclconfig=`(cd ${with_tclconfig}; pwd)`
		else
		    AC_MSG_ERROR([${with_tclconfig} directory doesn't contain tclConfig.sh])
		fi
	    fi

	    # then check for a private Tcl installation
	    if test x"${ac_cv_c_tclconfig}" = x ; then
		for i in \
			../tcl \
			`ls -dr ../tcl[[8-9]].[[0-9]].[[0-9]]* 2>/dev/null` \
			`ls -dr ../tcl[[8-9]].[[0-9]] 2>/dev/null` \
			`ls -dr ../tcl[[8-9]].[[0-9]]* 2>/dev/null` \
			../../tcl \
			`ls -dr ../../tcl[[8-9]].[[0-9]].[[0-9]]* 2>/dev/null` \
			`ls -dr ../../tcl[[8-9]].[[0-9]] 2>/dev/null` \
			`ls -dr ../../tcl[[8-9]].[[0-9]]* 2>/dev/null` \
			../../../tcl \
			`ls -dr ../../../tcl[[8-9]].[[0-9]].[[0-9]]* 2>/dev/null` \
			`ls -dr ../../../tcl[[8-9]].[[0-9]] 2>/dev/null` \
			`ls -dr ../../../tcl[[8-9]].[[0-9]]* 2>/dev/null` ; do
		    if test -f "$i/unix/tclConfig.sh" ; then
			ac_cv_c_tclconfig=`(cd $i/unix; pwd)`
			break
		    fi
		done
	    fi

	    # on Darwin, check in Framework installation locations
	    if test "`uname -s`" = "Darwin" -a x"${ac_cv_c_tclconfig}" = x ; then
		for i in `ls -d ~/Library/Frameworks 2>/dev/null` \
			`ls -d /Library/Frameworks 2>/dev/null` \
			`ls -d /Network/Library/Frameworks 2>/dev/null` \
			`ls -d /System/Library/Frameworks 2>/dev/null` \
			; do
		    if test -f "$i/Tcl.framework/tclConfig.sh" ; then
			ac_cv_c_tclconfig=`(cd $i/Tcl.framework; pwd)`
			break
		    fi
		done
	    fi

	    # on Windows, check in common installation locations
	    if test "${TEA_PLATFORM}" = "windows" \
		-a x"${ac_cv_c_tclconfig}" = x ; then
		for i in `ls -d C:/Tcl/lib 2>/dev/null` \
			`ls -d C:/Progra~1/Tcl/lib 2>/dev/null` \
			; do
		    if test -f "$i/tclConfig.sh" ; then
			ac_cv_c_tclconfig=`(cd $i; pwd)`
			break
		    fi
		done
	    fi

	    # check in a few common install locations
	    if test x"${ac_cv_c_tclconfig}" = x ; then
		for i in `ls -d ${libdir} 2>/dev/null` \
			`ls -d ${exec_prefix}/lib 2>/dev/null` \
			`ls -d ${prefix}/lib 2>/dev/null` \
			`ls -d /usr/local/lib 2>/dev/null` \
			`ls -d /usr/contrib/lib 2>/dev/null` \
			`ls -d /usr/lib 2>/dev/null` \
			; do
		    if test -f "$i/tclConfig.sh" ; then
			ac_cv_c_tclconfig=`(cd $i; pwd)`
			break
		    fi
		done
	    fi

	    # check in a few other private locations
	    if test x"${ac_cv_c_tclconfig}" = x ; then
		for i in \
			${srcdir}/../tcl \
			`ls -dr ${srcdir}/../tcl[[8-9]].[[0-9]].[[0-9]]* 2>/dev/null` \
			`ls -dr ${srcdir}/../tcl[[8-9]].[[0-9]] 2>/dev/null` \
			`ls -dr ${srcdir}/../tcl[[8-9]].[[0-9]]* 2>/dev/null` ; do
		    if test -f "$i/unix/tclConfig.sh" ; then
		    ac_cv_c_tclconfig=`(cd $i/unix; pwd)`
		    break
		fi
		done
	    fi
	])

	if test x"${ac_cv_c_tclconfig}" = x ; then
	    TCL_BIN_DIR="# no Tcl configs found"
	    AC_MSG_WARN([Can't find Tcl configuration definitions])
	    exit 0
	else
	    no_tcl=
	    TCL_BIN_DIR=${ac_cv_c_tclconfig}
	    AC_MSG_RESULT([found ${TCL_BIN_DIR}/tclConfig.sh])
	fi
    fi
])

#------------------------------------------------------------------------
# TEA_LOAD_TCLCONFIG --
#
#	Load the tclConfig.sh file
#
# Arguments:
#	
#	Requires the following vars to be set:
#		TCL_BIN_DIR
#
# Results:
#
#	Subst the following vars:
#		TCL_BIN_DIR
#		TCL_SRC_DIR
#		TCL_LIB_FILE
#
#------------------------------------------------------------------------

AC_DEFUN([TEA_LOAD_TCLCONFIG], [
    AC_MSG_CHECKING([for existence of ${TCL_BIN_DIR}/tclConfig.sh])

    if test -f "${TCL_BIN_DIR}/tclConfig.sh" ; then
        AC_MSG_RESULT([loading])
	. ${TCL_BIN_DIR}/tclConfig.sh
    else
        AC_MSG_RESULT([could not find ${TCL_BIN_DIR}/tclConfig.sh])
    fi

    # eval is required to do the TCL_DBGX substitution
    eval "TCL_LIB_FILE=\"${TCL_LIB_FILE}\""
    eval "TCL_STUB_LIB_FILE=\"${TCL_STUB_LIB_FILE}\""

    # If the TCL_BIN_DIR is the build directory (not the install directory),
    # then set the common variable name to the value of the build variables.
    # For example, the variable TCL_LIB_SPEC will be set to the value
    # of TCL_BUILD_LIB_SPEC. An extension should make use of TCL_LIB_SPEC
    # instead of TCL_BUILD_LIB_SPEC since it will work with both an
    # installed and uninstalled version of Tcl.
    if test -f ${TCL_BIN_DIR}/Makefile ; then
        TCL_LIB_SPEC=${TCL_BUILD_LIB_SPEC}
        TCL_STUB_LIB_SPEC=${TCL_BUILD_STUB_LIB_SPEC}
        TCL_STUB_LIB_PATH=${TCL_BUILD_STUB_LIB_PATH}
    elif test "`uname -s`" = "Darwin"; then
	# If Tcl was built as a framework, attempt to use the libraries
	# from the framework at the given location so that linking works
	# against Tcl.framework installed in an arbitary location.
	case ${TCL_DEFS} in
	    *TCL_FRAMEWORK*)
		if test -f ${TCL_BIN_DIR}/${TCL_LIB_FILE}; then
		    for i in "`cd ${TCL_BIN_DIR}; pwd`" \
			     "`cd ${TCL_BIN_DIR}/../..; pwd`"; do
			if test "`basename "$i"`" = "${TCL_LIB_FILE}.framework"; then
			    TCL_LIB_SPEC="-F`dirname "$i"` -framework ${TCL_LIB_FILE}"
			    break
			fi
		    done
		fi
		if test -f ${TCL_BIN_DIR}/${TCL_STUB_LIB_FILE}; then
		    TCL_STUB_LIB_SPEC="-L${TCL_BIN_DIR} ${TCL_STUB_LIB_FLAG}"
		    TCL_STUB_LIB_PATH="${TCL_BIN_DIR}/${TCL_STUB_LIB_FILE}"
		fi
		;;
	esac
    fi

    # eval is required to do the TCL_DBGX substitution
    eval "TCL_LIB_FLAG=\"${TCL_LIB_FLAG}\""
    eval "TCL_LIB_SPEC=\"${TCL_LIB_SPEC}\""
    eval "TCL_STUB_LIB_FLAG=\"${TCL_STUB_LIB_FLAG}\""
    eval "TCL_STUB_LIB_SPEC=\"${TCL_STUB_LIB_SPEC}\""

    AC_SUBST(TCL_VERSION)
    AC_SUBST(TCL_BIN_DIR)
    AC_SUBST(TCL_SRC_DIR)

    AC_SUBST(TCL_LIB_FILE)
    AC_SUBST(TCL_LIB_FLAG)
    AC_SUBST(TCL_LIB_SPEC)

    AC_SUBST(TCL_STUB_LIB_FILE)
    AC_SUBST(TCL_STUB_LIB_FLAG)
    AC_SUBST(TCL_STUB_LIB_SPEC)

    AC_SUBST(TCL_LIBS)
    AC_SUBST(TCL_DEFS)
    AC_SUBST(TCL_EXTRA_CFLAGS)
    AC_SUBST(TCL_LD_FLAGS)
    AC_SUBST(TCL_SHLIB_LD_LIBS)
])

#------------------------------------------------------------------------
# TEA_ENABLE_SHARED --
#
#	Allows the building of shared libraries
#
# Arguments:
#	none
#	
# Results:
#
#	Adds the following arguments to configure:
#		--enable-shared=yes|no
#
#	Defines the following vars:
#		STATIC_BUILD	Used for building import/export libraries
#				on Windows.
#
#	Sets the following vars:
#		SHARED_BUILD	Value of 1 or 0
#------------------------------------------------------------------------

AC_DEFUN([TEA_ENABLE_SHARED], [
    AC_MSG_CHECKING([how to build libraries])
    AC_ARG_ENABLE(shared,
	AC_HELP_STRING([--enable-shared],
	    [build and link with shared libraries (default: on)]),
	[tcl_ok=$enableval], [tcl_ok=yes])

    if test "${enable_shared+set}" = set; then
	enableval="$enable_shared"
	tcl_ok=$enableval
    else
	tcl_ok=yes
    fi

    if test "$tcl_ok" = "yes" ; then
	AC_MSG_RESULT([shared])
	SHARED_BUILD=1
    else
	AC_MSG_RESULT([static])
	SHARED_BUILD=0
	AC_DEFINE(STATIC_BUILD, 1, [Is this a static build?])
    fi
    AC_SUBST(SHARED_BUILD)
])

#------------------------------------------------------------------------
# TEA_ENABLE_SYMBOLS --
#
#	Specify if debugging symbols should be used.
#	Memory (TCL_MEM_DEBUG) debugging can also be enabled.
#
# Arguments:
#	none
#	
#	TEA varies from core Tcl in that C|LDFLAGS_DEFAULT receives
#	the value of C|LDFLAGS_OPTIMIZE|DEBUG already substituted.
#	Requires the following vars to be set in the Makefile:
#		CFLAGS_DEFAULT
#		LDFLAGS_DEFAULT
#	
# Results:
#
#	Adds the following arguments to configure:
#		--enable-symbols
#
#	Defines the following vars:
#		CFLAGS_DEFAULT	Sets to $(CFLAGS_DEBUG) if true
#				Sets to $(CFLAGS_OPTIMIZE) if false
#		LDFLAGS_DEFAULT	Sets to $(LDFLAGS_DEBUG) if true
#				Sets to $(LDFLAGS_OPTIMIZE) if false
#		DBGX		Formerly used as debug library extension;
#				always blank now.
#
#------------------------------------------------------------------------

AC_DEFUN([TEA_ENABLE_SYMBOLS], [
    dnl Make sure we are initialized
    AC_REQUIRE([TEA_CONFIG_CFLAGS])
    AC_MSG_CHECKING([for build with symbols])
    AC_ARG_ENABLE(symbols,
	AC_HELP_STRING([--enable-symbols],
	    [build with debugging symbols (default: off)]),
	[tcl_ok=$enableval], [tcl_ok=no])
    DBGX=""
    if test "$tcl_ok" = "no"; then
	CFLAGS_DEFAULT="${CFLAGS_OPTIMIZE}"
	LDFLAGS_DEFAULT="${LDFLAGS_OPTIMIZE}"
	AC_MSG_RESULT([no])
    else
	CFLAGS_DEFAULT="${CFLAGS_DEBUG}"
	LDFLAGS_DEFAULT="${LDFLAGS_DEBUG}"
	if test "$tcl_ok" = "yes"; then
	    AC_MSG_RESULT([yes (standard debugging)])
	fi
    fi
    if test "${TEA_PLATFORM}" != "windows" ; then
	LDFLAGS_DEFAULT="${LDFLAGS}"
    fi

    AC_SUBST(TCL_DBGX)
    AC_SUBST(CFLAGS_DEFAULT)
    AC_SUBST(LDFLAGS_DEFAULT)

    if test "$tcl_ok" = "mem" -o "$tcl_ok" = "all"; then
	AC_DEFINE(TCL_MEM_DEBUG, 1, [Is memory debugging enabled?])
    fi

    if test "$tcl_ok" != "yes" -a "$tcl_ok" != "no"; then
	if test "$tcl_ok" = "all"; then
	    AC_MSG_RESULT([enabled symbols mem debugging])
	else
	    AC_MSG_RESULT([enabled $tcl_ok debugging])
	fi
    fi
])

#--------------------------------------------------------------------
# TEA_CONFIG_SYSTEM
#
#	Determine what the system is (some things cannot be easily checked
#	on a feature-driven basis, alas). This can usually be done via the
#	"uname" command, but there are a few systems, like Next, where
#	this doesn't work.
#
# Arguments:
#	none
#
# Results:
#	Defines the following var:
#
#	system -	System/platform/version identification code.
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_CONFIG_SYSTEM], [
    AC_CACHE_CHECK([system version], tcl_cv_sys_version, [
	if test "${TEA_PLATFORM}" = "windows" ; then
	    tcl_cv_sys_version=windows
	elif test -f /usr/lib/NextStep/software_version; then
	    tcl_cv_sys_version=NEXTSTEP-`awk '/3/,/3/' /usr/lib/NextStep/software_version`
	else
	    tcl_cv_sys_version=`uname -s`-`uname -r`
	    if test "$?" -ne 0 ; then
		AC_MSG_WARN([can't find uname command])
		tcl_cv_sys_version=unknown
	    else
		# Special check for weird MP-RAS system (uname returns weird
		# results, and the version is kept in special file).

		if test -r /etc/.relid -a "X`uname -n`" = "X`uname -s`" ; then
		    tcl_cv_sys_version=MP-RAS-`awk '{print [$]3}' /etc/.relid`
		fi
		if test "`uname -s`" = "AIX" ; then
		    tcl_cv_sys_version=AIX-`uname -v`.`uname -r`
		fi
	    fi
	fi
    ])
    system=$tcl_cv_sys_version
])

#--------------------------------------------------------------------
# TEA_CONFIG_CFLAGS
#
#	Try to determine the proper flags to pass to the compiler
#	for building shared libraries and other such nonsense.
#
# Modified for pgtcl-ng to add the PostgreSQL library search path.
#
# Arguments:
#	none
#
# Results:
#
#	Defines and substitutes the following vars:
#
#       DL_OBJS -       Name of the object file that implements dynamic
#                       loading for Tcl on this system.
#       DL_LIBS -       Library file(s) to include in tclsh and other base
#                       applications in order for the "load" command to work.
#       LDFLAGS -      Flags to pass to the compiler when linking object
#                       files into an executable application binary such
#                       as tclsh.
#       LD_SEARCH_FLAGS-Flags to pass to ld, such as "-R /usr/local/tcl/lib",
#                       that tell the run-time dynamic linker where to look
#                       for shared libraries such as libtcl.so.  Depends on
#                       the variable LIB_RUNTIME_DIR in the Makefile. Could
#                       be the same as CC_SEARCH_FLAGS if ${CC} is used to link.
#       CC_SEARCH_FLAGS-Flags to pass to ${CC}, such as "-Wl,-rpath,/usr/local/tcl/lib",
#                       that tell the run-time dynamic linker where to look
#                       for shared libraries such as libtcl.so.  Depends on
#                       the variable LIB_RUNTIME_DIR in the Makefile.
#       SHLIB_CFLAGS -  Flags to pass to cc when compiling the components
#                       of a shared library (may request position-independent
#                       code, among other things).
#       SHLIB_LD -      Base command to use for combining object files
#                       into a shared library.
#       SHLIB_LD_LIBS - Dependent libraries for the linker to scan when
#                       creating shared libraries.  This symbol typically
#                       goes at the end of the "ld" commands that build
#                       shared libraries. The value of the symbol is
#                       "${LIBS}" if all of the dependent libraries should
#                       be specified when creating a shared library.  If
#                       dependent libraries should not be specified (as on
#                       SunOS 4.x, where they cause the link to fail, or in
#                       general if Tcl and Tk aren't themselves shared
#                       libraries), then this symbol has an empty string
#                       as its value.
#       SHLIB_SUFFIX -  Suffix to use for the names of dynamically loadable
#                       extensions.  An empty string means we don't know how
#                       to use shared libraries on this platform.
#       LIB_SUFFIX -    Specifies everything that comes after the "libfoo"
#                       in a static or shared library name, using the $VERSION variable
#                       to put the version in the right place.  This is used
#                       by platforms that need non-standard library names.
#                       Examples:  ${VERSION}.so.1.1 on NetBSD, since it needs
#                       to have a version after the .so, and ${VERSION}.a
#                       on AIX, since a shared library needs to have
#                       a .a extension whereas shared objects for loadable
#                       extensions have a .so extension.  Defaults to
#                       ${VERSION}${SHLIB_SUFFIX}.
#       TCL_NEEDS_EXP_FILE -
#                       1 means that an export file is needed to link to a
#                       shared library.
#       TCL_EXP_FILE -  The name of the installed export / import file which
#                       should be used to link to the Tcl shared library.
#                       Empty if Tcl is unshared.
#       TCL_BUILD_EXP_FILE -
#                       The name of the built export / import file which
#                       should be used to link to the Tcl shared library.
#                       Empty if Tcl is unshared.
#	CFLAGS_DEBUG -
#			Flags used when running the compiler in debug mode
#	CFLAGS_OPTIMIZE -
#			Flags used when running the compiler in optimize mode
#	CFLAGS -	Additional CFLAGS added as necessary (usually 64-bit)
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_CONFIG_CFLAGS], [
    dnl Make sure we are initialized
    AC_REQUIRE([TEA_INIT])

    # Step 0.a: Enable 64 bit support?

    AC_MSG_CHECKING([if 64bit support is requested])
    AC_ARG_ENABLE(64bit,
	AC_HELP_STRING([--enable-64bit],
	    [enable 64bit support (default: off)]),
	[do64bit=$enableval], [do64bit=no])
    AC_MSG_RESULT([$do64bit])

    # Step 0.b: Enable Solaris 64 bit VIS support?

    AC_MSG_CHECKING([if 64bit Sparc VIS support is requested])
    AC_ARG_ENABLE(64bit-vis,
	AC_HELP_STRING([--enable-64bit-vis],
	    [enable 64bit Sparc VIS support (default: off)]),
	[do64bitVIS=$enableval], [do64bitVIS=no])
    AC_MSG_RESULT([$do64bitVIS])

    if test "$do64bitVIS" = "yes"; then
	# Force 64bit on with VIS
	do64bit=yes
    fi

    # Step 0.c: Cross-compiling options for Windows/CE builds?

    if test "${TEA_PLATFORM}" = "windows" ; then
	AC_MSG_CHECKING([if Windows/CE build is requested])
	AC_ARG_ENABLE(wince,[  --enable-wince          enable Win/CE support (where applicable)], [doWince=$enableval], [doWince=no])
	AC_MSG_RESULT([$doWince])
    fi

    # Step 1: set the variable "system" to hold the name and version number
    # for the system.

    TEA_CONFIG_SYSTEM

    # Step 2: check for existence of -ldl library.  This is needed because
    # Linux can use either -ldl or -ldld for dynamic loading.

    AC_CHECK_LIB(dl, dlopen, have_dl=yes, have_dl=no)

    # Require ranlib early so we can override it in special cases below.

    AC_REQUIRE([AC_PROG_RANLIB])

    # Step 3: set configuration options based on system name and version.

    do64bit_ok=no
    LDFLAGS_ORIG="$LDFLAGS"
    # When ld needs options to work in 64-bit mode, put them in
    # LDFLAGS_ARCH so they eventually end up in LDFLAGS even if [load]
    # is disabled by the user. [Bug 1016796]
    LDFLAGS_ARCH=""
    TCL_EXPORT_FILE_SUFFIX=""
    UNSHARED_LIB_SUFFIX=""
    TCL_TRIM_DOTS='`echo ${PACKAGE_VERSION} | tr -d .`'
    ECHO_VERSION='`echo ${PACKAGE_VERSION}`'
    TCL_LIB_VERSIONS_OK=ok
    CFLAGS_DEBUG=-g
    CFLAGS_OPTIMIZE=-O
    if test "$GCC" = "yes" ; then
	CFLAGS_OPTIMIZE=-O2
	CFLAGS_WARNING="-Wall -Wno-implicit-int"
    else
	CFLAGS_WARNING=""
    fi
    TCL_NEEDS_EXP_FILE=0
    TCL_BUILD_EXP_FILE=""
    TCL_EXP_FILE=""
dnl FIXME: Replace AC_CHECK_PROG with AC_CHECK_TOOL once cross compiling is fixed.
dnl AC_CHECK_TOOL(AR, ar)
    AC_CHECK_PROG(AR, ar, ar)
    STLIB_LD='${AR} cr'
    LD_LIBRARY_PATH_VAR="LD_LIBRARY_PATH"
    case $system in

	AIX-*)
	    if test "${TCL_THREADS}" = "1" -a "$GCC" != "yes" ; then
		# AIX requires the _r compiler when gcc isn't being used
		case "${CC}" in
		    *_r)
			# ok ...
			;;
		    *)
			CC=${CC}_r
			;;
		esac
		AC_MSG_RESULT([Using $CC for compiling with threads])
	    fi
	    LIBS="$LIBS -lc"
	    SHLIB_CFLAGS=""
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    DL_OBJS="tclLoadDl.o"
	    LD_LIBRARY_PATH_VAR="LIBPATH"

	    # Check to enable 64-bit flags for compiler/linker on AIX 4+
	    if test "$do64bit" = "yes" -a "`uname -v`" -gt "3" ; then
		if test "$GCC" = "yes" ; then
		    AC_MSG_WARN([64bit mode not supported with GCC on $system])
		else 
		    do64bit_ok=yes
		    CFLAGS="$CFLAGS -q64"
		    LDFLAGS_ARCH="-q64"
		    RANLIB="${RANLIB} -X64"
		    AR="${AR} -X64"
		    SHLIB_LD_FLAGS="-b64"
		fi
	    fi

	    if test "`uname -m`" = "ia64" ; then
		# AIX-5 uses ELF style dynamic libraries on IA-64, but not PPC
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		# AIX-5 has dl* in libc.so
		DL_LIBS=""
		if test "$GCC" = "yes" ; then
		    CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		else
		    CC_SEARCH_FLAGS='-R${LIB_RUNTIME_DIR} -R${LIB_PGTCL_RUNTIME_DIR}'
		fi
		LD_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
	    else
		if test "$GCC" = "yes" ; then
		    SHLIB_LD="gcc -shared"
		else
		    SHLIB_LD="/bin/ld -bhalt:4 -bM:SRE -bE:lib.exp -H512 -T512 -bnoentry"
		fi
		SHLIB_LD="${TCL_SRC_DIR}/unix/ldAix ${SHLIB_LD} ${SHLIB_LD_FLAGS}"
		DL_LIBS="-ldl"
		CC_SEARCH_FLAGS='-L${LIB_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
		TCL_NEEDS_EXP_FILE=1
		TCL_EXPORT_FILE_SUFFIX='${PACKAGE_VERSION}.exp'
	    fi

	    # AIX v<=4.1 has some different flags than 4.2+
	    if test "$system" = "AIX-4.1" -o "`uname -v`" -lt "4" ; then
		AC_LIBOBJ([tclLoadAix])
		DL_LIBS="-lld"
	    fi

	    # On AIX <=v4 systems, libbsd.a has to be linked in to support
	    # non-blocking file IO.  This library has to be linked in after
	    # the MATH_LIBS or it breaks the pow() function.  The way to
	    # insure proper sequencing, is to add it to the tail of MATH_LIBS.
	    # This library also supplies gettimeofday.
	    #
	    # AIX does not have a timezone field in struct tm. When the AIX
	    # bsd library is used, the timezone global and the gettimeofday
	    # methods are to be avoided for timezone deduction instead, we
	    # deduce the timezone by comparing the localtime result on a
	    # known GMT value.

	    AC_CHECK_LIB(bsd, gettimeofday, libbsd=yes, libbsd=no)
	    if test $libbsd = yes; then
	    	MATH_LIBS="$MATH_LIBS -lbsd"
	    	AC_DEFINE(USE_DELTA_FOR_TZ, 1, [Do we need a special AIX hack for timezones?])
	    fi
	    ;;
	BeOS*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="${CC} -nostart"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"

	    #-----------------------------------------------------------
	    # Check for inet_ntoa in -lbind, for BeOS (which also needs
	    # -lsocket, even if the network functions are in -lnet which
	    # is always linked to, for compatibility.
	    #-----------------------------------------------------------
	    AC_CHECK_LIB(bind, inet_ntoa, [LIBS="$LIBS -lbind -lsocket"])
	    ;;
	BSD/OS-2.1*|BSD/OS-3*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="shlicc -r"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	BSD/OS-4.*)
	    SHLIB_CFLAGS="-export-dynamic -fPIC"
	    SHLIB_LD="cc -shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -export-dynamic"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	dgux*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	HP-UX-*.11.*)
	    # Use updated header definitions where possible
	    AC_DEFINE(_XOPEN_SOURCE_EXTENDED, 1, [Do we want to use the XOPEN network library?])
	    # Needed by Tcl, but not most extensions
	    #AC_DEFINE(_XOPEN_SOURCE, 1, [Do we want to use the XOPEN network library?])
	    #LIBS="$LIBS -lxnet"               # Use the XOPEN network library

	    SHLIB_SUFFIX=".sl"
	    AC_CHECK_LIB(dld, shl_load, tcl_ok=yes, tcl_ok=no)
	    if test "$tcl_ok" = yes; then
		SHLIB_CFLAGS="+z"
		SHLIB_LD="ld -b"
		SHLIB_LD_LIBS='${LIBS}'
		DL_OBJS="tclLoadShl.o"
		DL_LIBS="-ldld"
		LDFLAGS="$LDFLAGS -Wl,-E"
		CC_SEARCH_FLAGS='-Wl,+s,+b,${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_SEARCH_FLAGS='+s +b ${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_LIBRARY_PATH_VAR="SHLIB_PATH"
	    fi
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="gcc -shared"
		SHLIB_LD_LIBS='${LIBS}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    fi

	    # Users may want PA-RISC 1.1/2.0 portable code - needs HP cc
	    #CFLAGS="$CFLAGS +DAportable"

	    # Check to enable 64-bit flags for compiler/linker
	    if test "$do64bit" = "yes" ; then
		if test "$GCC" = "yes" ; then
		    hpux_arch=`${CC} -dumpmachine`
		    case $hpux_arch in
			hppa64*)
			    # 64-bit gcc in use.  Fix flags for GNU ld.
			    do64bit_ok=yes
			    SHLIB_LD="${CC} -shared"
			    SHLIB_LD_LIBS='${LIBS}'
			    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR}'
			    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
			    ;;
			*)
			    AC_MSG_WARN([64bit mode not supported with GCC on $system])
			    ;;
		    esac
		else
		    do64bit_ok=yes
		    CFLAGS="$CFLAGS +DD64"
		    LDFLAGS_ARCH="+DD64"
		fi
	    fi
	    ;;
	HP-UX-*.08.*|HP-UX-*.09.*|HP-UX-*.10.*)
	    SHLIB_SUFFIX=".sl"
	    AC_CHECK_LIB(dld, shl_load, tcl_ok=yes, tcl_ok=no)
	    if test "$tcl_ok" = yes; then
		SHLIB_CFLAGS="+z"
		SHLIB_LD="ld -b"
		SHLIB_LD_LIBS=""
		DL_OBJS="tclLoadShl.o"
		DL_LIBS="-ldld"
		LDFLAGS="$LDFLAGS -Wl,-E"
		CC_SEARCH_FLAGS='-Wl,+s,+b,${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_SEARCH_FLAGS='+s +b ${LIB_RUNTIME_DIR}:${LIB_PGTCL_RUNTIME_DIR}:.'
		LD_LIBRARY_PATH_VAR="SHLIB_PATH"
	    fi
	    ;;
	IRIX-5.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    ;;
	IRIX-6.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -n32 -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "$GCC" = "yes" ; then
		CFLAGS="$CFLAGS -mabi=n32"
		LDFLAGS="$LDFLAGS -mabi=n32"
	    else
		case $system in
		    IRIX-6.3)
			# Use to build 6.2 compatible binaries on 6.3.
			CFLAGS="$CFLAGS -n32 -D_OLD_TERMIOS"
			;;
		    *)
			CFLAGS="$CFLAGS -n32"
			;;
		esac
		LDFLAGS="$LDFLAGS -n32"
	    fi
	    ;;
	IRIX64-6.*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="ld -n32 -shared -rdata_shared"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'

	    # Check to enable 64-bit flags for compiler/linker

	    if test "$do64bit" = "yes" ; then
	        if test "$GCC" = "yes" ; then
	            AC_MSG_WARN([64bit mode not supported by gcc])
	        else
	            do64bit_ok=yes
	            SHLIB_LD="ld -64 -shared -rdata_shared"
	            CFLAGS="$CFLAGS -64"
	            LDFLAGS_ARCH="-64"
	        fi
	    fi
	    ;;
	Linux*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    CFLAGS_OPTIMIZE="-O2 -fomit-frame-pointer"
	    # egcs-2.91.66 on Redhat Linux 6.0 generates lots of warnings 
	    # when you inline the string and math operations.  Turn this off to
	    # get rid of the warnings.
	    #CFLAGS_OPTIMIZE="${CFLAGS_OPTIMIZE} -D__NO_STRING_INLINES -D__NO_MATH_INLINES"

	    SHLIB_LD="${CC} -shared"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,--export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    if test "`uname -m`" = "alpha" ; then
		CFLAGS="$CFLAGS -mieee"
	    fi

	    # The combo of gcc + glibc has a bug related
	    # to inlining of functions like strtod(). The
	    # -fno-builtin flag should address this problem
	    # but it does not work. The -fno-inline flag
	    # is kind of overkill but it works.
	    # Disable inlining only when one of the
	    # files in compat/*.c is being linked in.
	    if test x"${USE_COMPAT}" != x ; then
	        CFLAGS="$CFLAGS -fno-inline"
	    fi

	    ;;
	GNU*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"

	    SHLIB_LD="${CC} -shared"
	    DL_OBJS=""
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,--export-dynamic"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    if test "`uname -m`" = "alpha" ; then
		CFLAGS="$CFLAGS -mieee"
	    fi
	    ;;
	Lynx*)
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    CFLAGS_OPTIMIZE=-02
	    SHLIB_LD="${CC} -shared "
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-mshared -ldl"
	    LD_FLAGS="-Wl,--export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR}'
	    ;;
	MP-RAS-02*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	MP-RAS-*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    LDFLAGS="$LDFLAGS -Wl,-Bexport"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	NetBSD-*|FreeBSD-[[1-2]].*)
	    # NetBSD/SPARC needs -fPIC, -fpic will not do.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    AC_CACHE_CHECK([for ELF], tcl_cv_ld_elf, [
		AC_EGREP_CPP(yes, [
#ifdef __ELF__
	yes
#endif
		], tcl_cv_ld_elf=yes, tcl_cv_ld_elf=no)])
	    if test $tcl_cv_ld_elf = yes; then
		SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so'
	    else
		SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    fi

	    # Ancient FreeBSD doesn't handle version numbers with dots.

	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	OpenBSD-*)
	    # OpenBSD/SPARC[64] needs -fPIC, -fpic will not do.
	    case `machine` in
	    sparc|sparc64)
		SHLIB_CFLAGS="-fPIC";;
	    *)
		SHLIB_CFLAGS="-fpic";;
	    esac
	    SHLIB_LD="${CC} -shared ${SHLIB_CFLAGS}"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    AC_CACHE_CHECK([for ELF], tcl_cv_ld_elf, [
		AC_EGREP_CPP(yes, [
#ifdef __ELF__
	yes
#endif
		], tcl_cv_ld_elf=yes, tcl_cv_ld_elf=no)])
	    if test $tcl_cv_ld_elf = yes; then
		LDFLAGS=-Wl,-export-dynamic
	    else
		LDFLAGS=""
	    fi

	    # OpenBSD doesn't do version numbers with dots.
	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	FreeBSD-*)
	    # FreeBSD 3.* and greater have ELF.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    LDFLAGS="$LDFLAGS -export-dynamic"
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "${TCL_THREADS}" = "1" ; then
		# The -pthread needs to go in the CFLAGS, not LIBS
		LIBS=`echo $LIBS | sed s/-pthread//`
		CFLAGS="$CFLAGS -pthread"
	    	LDFLAGS="$LDFLAGS -pthread"
	    fi
	    case $system in
	    FreeBSD-3.*)
	    	# FreeBSD-3 doesn't handle version numbers with dots.
	    	UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    	SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so'
	    	TCL_LIB_VERSIONS_OK=nodots
		;;
	    esac
	    ;;
	Darwin-*)
	    CFLAGS_OPTIMIZE="-Os"
	    SHLIB_CFLAGS="-fno-common"
	    if test $do64bit = yes; then
	        do64bit_ok=yes
	        CFLAGS="$CFLAGS -arch ppc64 -mpowerpc64 -mcpu=G5"
	    fi
	    # TEA specific: use LDFLAGS_DEFAULT instead of LDFLAGS here:
	    SHLIB_LD='${CC} -dynamiclib ${CFLAGS} ${LDFLAGS_DEFAULT}'
	    AC_CACHE_CHECK([if ld accepts -single_module flag], tcl_cv_ld_single_module, [
	        hold_ldflags=$LDFLAGS
	        LDFLAGS="$LDFLAGS -dynamiclib -Wl,-single_module"
	        AC_TRY_LINK(, [int i;], tcl_cv_ld_single_module=yes, tcl_cv_ld_single_module=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_single_module = yes; then
	        SHLIB_LD="${SHLIB_LD} -Wl,-single_module"
	    fi
	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".dylib"
	    DL_OBJS="tclLoadDyld.o"
	    DL_LIBS=""
	    # Don't use -prebind when building for Mac OS X 10.4 or later only:
	    test -z "${MACOSX_DEPLOYMENT_TARGET}" || \
		test "`echo "${MACOSX_DEPLOYMENT_TARGET}" | awk -F. '{print [$]2}'`" -lt 4 && \
		LDFLAGS="$LDFLAGS -prebind"
	    LDFLAGS="$LDFLAGS -headerpad_max_install_names"
	    AC_CACHE_CHECK([if ld accepts -search_paths_first flag], tcl_cv_ld_search_paths_first, [
	        hold_ldflags=$LDFLAGS
	        LDFLAGS="$LDFLAGS -Wl,-search_paths_first"
	        AC_TRY_LINK(, [int i;], tcl_cv_ld_search_paths_first=yes, tcl_cv_ld_search_paths_first=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_search_paths_first = yes; then
	        LDFLAGS="$LDFLAGS -Wl,-search_paths_first"
	    fi
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    LD_LIBRARY_PATH_VAR="DYLD_LIBRARY_PATH"

	    # TEA specific: for Tk extensions, remove -arch ppc64 from CFLAGS
	    # for fat builds, as neither TkAqua nor TkX11 can be built for 64bit
	    # at present (no 64bit GUI libraries).
	    test $do64bit_ok = no && test -n "${TK_BIN_DIR}" && \
	        CFLAGS="`echo "$CFLAGS" | sed -e 's/-arch ppc64/-arch ppc/g'`"
	    ;;
	NEXTSTEP-*)
	    SHLIB_CFLAGS=""
	    SHLIB_LD="cc -nostdlib -r"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadNext.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OS/390-*)
	    CFLAGS_OPTIMIZE=""		# Optimizer is buggy
	    AC_DEFINE(_OE_SOCKETS, 1,	# needed in sys/socket.h
		[Should OS/390 do the right thing with sockets?])
	    ;;      
	OSF1-1.0|OSF1-1.1|OSF1-1.2)
	    # OSF/1 1.[012] from OSF, and derivatives, including Paragon OSF/1
	    SHLIB_CFLAGS=""
	    # Hack: make package name same as library name
	    SHLIB_LD='ld -R -export $@:'
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadOSF.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OSF1-1.*)
	    # OSF/1 1.3 from OSF using ELF, and derivatives, including AD2
	    SHLIB_CFLAGS="-fPIC"
	    if test "$SHARED_BUILD" = "1" ; then
	        SHLIB_LD="ld -shared"
	    else
	        SHLIB_LD="ld -non_shared"
	    fi
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	OSF1-V*)
	    # Digital OSF/1
	    SHLIB_CFLAGS=""
	    if test "$SHARED_BUILD" = "1" ; then
	        SHLIB_LD='ld -shared -expect_unresolved "*"'
	    else
	        SHLIB_LD='ld -non_shared -expect_unresolved "*"'
	    fi
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS='-Wl,-rpath,${LIB_RUNTIME_DIR},-rpath,${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS='-rpath ${LIB_RUNTIME_DIR} -rpath ${LIB_PGTCL_RUNTIME_DIR}'
	    if test "$GCC" = "yes" ; then
		CFLAGS="$CFLAGS -mieee"
            else
		CFLAGS="$CFLAGS -DHAVE_TZSET -std1 -ieee"
	    fi
	    # see pthread_intro(3) for pthread support on osf1, k.furukawa
	    if test "${TCL_THREADS}" = "1" ; then
		CFLAGS="$CFLAGS -DHAVE_PTHREAD_ATTR_SETSTACKSIZE"
		CFLAGS="$CFLAGS -DTCL_THREAD_STACK_MIN=PTHREAD_STACK_MIN*64"
		LIBS=`echo $LIBS | sed s/-lpthreads//`
		if test "$GCC" = "yes" ; then
		    LIBS="$LIBS -lpthread -lmach -lexc"
		else
		    CFLAGS="$CFLAGS -pthread"
		    LDFLAGS="$LDFLAGS -pthread"
		fi
	    fi

	    ;;
	QNX-6*)
	    # QNX RTP
	    # This may work for all QNX, but it was only reported for v6.
	    SHLIB_CFLAGS="-fPIC"
	    SHLIB_LD="ld -Bshareable -x"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    # dlopen is in -lc on QNX
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SCO_SV-3.2*)
	    # Note, dlopen is available only on SCO 3.2.5 and greater. However,
	    # this test works, since "uname -s" was non-standard in 3.2.4 and
	    # below.
	    if test "$GCC" = "yes" ; then
	    	SHLIB_CFLAGS="-fPIC -melf"
	    	LDFLAGS="$LDFLAGS -melf -Wl,-Bexport"
	    else
	    	SHLIB_CFLAGS="-Kpic -belf"
	    	LDFLAGS="$LDFLAGS -belf -Wl,-Bexport"
	    fi
	    SHLIB_LD="ld -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS=""
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SINIX*5.4*)
	    SHLIB_CFLAGS="-K PIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
	SunOS-4*)
	    SHLIB_CFLAGS="-PIC"
	    SHLIB_LD="ld"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    CC_SEARCH_FLAGS='-L${LIB_RUNTIME_DIR} -L${LIB_PGTCL_RUNTIME_DIR}'
	    LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}

	    # SunOS can't handle version numbers with dots in them in library
	    # specs, like -ltcl7.5, so use -ltcl75 instead.  Also, it
	    # requires an extra version number at the end of .so file names.
	    # So, the library has to have a name like libtcl75.so.1.0

	    SHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.so.1.0'
	    UNSHARED_LIB_SUFFIX='${TCL_TRIM_DOTS}.a'
	    TCL_LIB_VERSIONS_OK=nodots
	    ;;
	SunOS-5.[[0-6]])
	    # Careful to not let 5.10+ fall into this case

	    # Note: If _REENTRANT isn't defined, then Solaris
	    # won't define thread-safe library routines.

	    AC_DEFINE(_REENTRANT, 1, [Do we want the reentrant OS API?])
	    AC_DEFINE(_POSIX_PTHREAD_SEMANTICS, 1,
		[Do we really want to follow the standard? Yes we do!])

	    SHLIB_CFLAGS="-KPIC"

	    # Note: need the LIBS below, otherwise Tk won't find Tcl's
	    # symbols when dynamically loaded into tclsh.

	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="$CC -shared"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    else
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		CC_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
	    fi
	    ;;
	SunOS-5*)
	    # Note: If _REENTRANT isn't defined, then Solaris
	    # won't define thread-safe library routines.

	    AC_DEFINE(_REENTRANT, 1, [Do we want the reentrant OS API?])
	    AC_DEFINE(_POSIX_PTHREAD_SEMANTICS, 1,
		[Do we really want to follow the standard? Yes we do!])

	    SHLIB_CFLAGS="-KPIC"

	    # Check to enable 64-bit flags for compiler/linker
	    if test "$do64bit" = "yes" ; then
		arch=`isainfo`
		if test "$arch" = "sparcv9 sparc" ; then
			if test "$GCC" = "yes" ; then
			    if test "`gcc -dumpversion | awk -F. '{print [$]1}'`" -lt "3" ; then
				AC_MSG_WARN([64bit mode not supported with GCC < 3.2 on $system])
			    else
				do64bit_ok=yes
				CFLAGS="$CFLAGS -m64 -mcpu=v9"
				LDFLAGS="$LDFLAGS -m64 -mcpu=v9"
				SHLIB_CFLAGS="-fPIC"
			    fi
			else
			    do64bit_ok=yes
			    if test "$do64bitVIS" = "yes" ; then
				CFLAGS="$CFLAGS -xarch=v9a"
			    	LDFLAGS_ARCH="-xarch=v9a"
			    else
				CFLAGS="$CFLAGS -xarch=v9"
			    	LDFLAGS_ARCH="-xarch=v9"
			    fi
			    # Solaris 64 uses this as well
			    #LD_LIBRARY_PATH_VAR="LD_LIBRARY_PATH_64"
			fi
		elif test "$arch" = "amd64 i386" ; then
		    if test "$GCC" = "yes" ; then
			AC_MSG_WARN([64bit mode not supported with GCC on $system])
		    else
			do64bit_ok=yes
			CFLAGS="$CFLAGS -xarch=amd64"
			LDFLAGS="$LDFLAGS -xarch=amd64"
		    fi
		else
		    AC_MSG_WARN([64bit mode not supported for $arch])
		fi
	    fi
	    
	    # Note: need the LIBS below, otherwise Tk won't find Tcl's
	    # symbols when dynamically loaded into tclsh.

	    SHLIB_LD_LIBS='${LIBS}'
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    if test "$GCC" = "yes" ; then
		SHLIB_LD="$CC -shared"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS=${CC_SEARCH_FLAGS}
		if test "$do64bit_ok" = "yes" ; then
		    # We need to specify -static-libgcc or we need to
		    # add the path to the sparv9 libgcc.
		    # JH: static-libgcc is necessary for core Tcl, but may
		    # not be necessary for extensions.
		    SHLIB_LD="$SHLIB_LD -m64 -mcpu=v9 -static-libgcc"
		    # for finding sparcv9 libgcc, get the regular libgcc
		    # path, remove so name and append 'sparcv9'
		    #v9gcclibdir="`gcc -print-file-name=libgcc_s.so` | ..."
		    #CC_SEARCH_FLAGS="${CC_SEARCH_FLAGS},-R,$v9gcclibdir"
		fi
	    else
		SHLIB_LD="/usr/ccs/bin/ld -G -z text"
		CC_SEARCH_FLAGS='-Wl,-R,${LIB_RUNTIME_DIR},-R,${LIB_PGTCL_RUNTIME_DIR}'
		LD_SEARCH_FLAGS='-R ${LIB_RUNTIME_DIR} -R ${LIB_PGTCL_RUNTIME_DIR}'
	    fi
	    ;;
	UNIX_SV* | UnixWare-5*)
	    SHLIB_CFLAGS="-KPIC"
	    SHLIB_LD="cc -G"
	    SHLIB_LD_LIBS=""
	    SHLIB_SUFFIX=".so"
	    DL_OBJS="tclLoadDl.o"
	    DL_LIBS="-ldl"
	    # Some UNIX_SV* systems (unixware 1.1.2 for example) have linkers
	    # that don't grok the -Bexport option.  Test that it does.
	    AC_CACHE_CHECK([for ld accepts -Bexport flag], tcl_cv_ld_Bexport, [
		hold_ldflags=$LDFLAGS
		LDFLAGS="$LDFLAGS -Wl,-Bexport"
		AC_TRY_LINK(, [int i;], tcl_cv_ld_Bexport=yes, tcl_cv_ld_Bexport=no)
	        LDFLAGS=$hold_ldflags])
	    if test $tcl_cv_ld_Bexport = yes; then
		LDFLAGS="$LDFLAGS -Wl,-Bexport"
	    fi
	    CC_SEARCH_FLAGS=""
	    LD_SEARCH_FLAGS=""
	    ;;
    esac

    if test "$do64bit" = "yes" -a "$do64bit_ok" = "no" ; then
	AC_MSG_WARN([64bit support being disabled -- don't know magic for this platform])
    fi

    # Step 4: disable dynamic loading if requested via a command-line switch.

    AC_ARG_ENABLE(load,
	AC_HELP_STRING([--disable-load],
	    [disallow dynamic loading and "load" command (default: enabled)]),
	[tcl_ok=$enableval], [tcl_ok=yes])
    if test "$tcl_ok" = "no"; then
	DL_OBJS=""
    fi

    if test "x$DL_OBJS" != "x" ; then
	BUILD_DLTEST="\$(DLTEST_TARGETS)"
    else
	echo "Can't figure out how to do dynamic loading or shared libraries"
	echo "on this system."
	SHLIB_CFLAGS=""
	SHLIB_LD=""
	SHLIB_SUFFIX=""
	DL_OBJS="tclLoadNone.o"
	DL_LIBS=""
	LDFLAGS="$LDFLAGS_ORIG"
	CC_SEARCH_FLAGS=""
	LD_SEARCH_FLAGS=""
	BUILD_DLTEST=""
    fi
    LDFLAGS="$LDFLAGS $LDFLAGS_ARCH"

    # If we're running gcc, then change the C flags for compiling shared
    # libraries to the right flags for gcc, instead of those for the
    # standard manufacturer compiler.

    if test "$DL_OBJS" != "tclLoadNone.o" ; then
	if test "$GCC" = "yes" ; then
	    case $system in
		AIX-*)
		    ;;
		BSD/OS*)
		    ;;
		IRIX*)
		    ;;
		NetBSD-*|FreeBSD-*)
		    ;;
		Darwin-*)
		    ;;
		SCO_SV-3.2*)
		    ;;
		windows)
		    ;;
		*)
		    SHLIB_CFLAGS="-fPIC"
		    ;;
	    esac
	fi
    fi

    if test "$SHARED_LIB_SUFFIX" = "" ; then
	SHARED_LIB_SUFFIX='${PACKAGE_VERSION}${SHLIB_SUFFIX}'
    fi
    if test "$UNSHARED_LIB_SUFFIX" = "" ; then
	UNSHARED_LIB_SUFFIX='${PACKAGE_VERSION}.a'
    fi

    AC_SUBST(DL_LIBS)

    AC_SUBST(CFLAGS_DEBUG)
    AC_SUBST(CFLAGS_OPTIMIZE)
    AC_SUBST(CFLAGS_WARNING)

    AC_SUBST(STLIB_LD)
    AC_SUBST(SHLIB_LD)

    AC_SUBST(SHLIB_LD_LIBS)
    AC_SUBST(SHLIB_CFLAGS)

    AC_SUBST(LD_LIBRARY_PATH_VAR)

    # These must be called after we do the basic CFLAGS checks and
    # verify any possible 64-bit or similar switches are necessary
    TEA_TCL_EARLY_FLAGS
    TEA_TCL_64BIT_FLAGS
])

#--------------------------------------------------------------------
# TEA_MISSING_POSIX_HEADERS
#
#	Supply substitutes for missing POSIX header files.  Special
#	notes:
#	    - stdlib.h doesn't define strtol, strtoul, or
#	      strtod insome versions of SunOS
#	    - some versions of string.h don't declare procedures such
#	      as strstr
#
# Arguments:
#	none
#	
# Results:
#
#	Defines some of the following vars:
#		NO_DIRENT_H
#		NO_ERRNO_H
#		NO_VALUES_H
#		HAVE_LIMITS_H or NO_LIMITS_H
#		NO_STDLIB_H
#		NO_STRING_H
#		NO_SYS_WAIT_H
#		NO_DLFCN_H
#		HAVE_SYS_PARAM_H
#
#		HAVE_STRING_H ?
#
# tkUnixPort.h checks for HAVE_LIMITS_H, so do both HAVE and
# CHECK on limits.h
#--------------------------------------------------------------------

AC_DEFUN([TEA_MISSING_POSIX_HEADERS], [
    AC_CACHE_CHECK([dirent.h], tcl_cv_dirent_h,
    AC_TRY_LINK([#include <sys/types.h>
#include <dirent.h>], [
#ifndef _POSIX_SOURCE
#   ifdef __Lynx__
	/*
	 * Generate compilation error to make the test fail:  Lynx headers
	 * are only valid if really in the POSIX environment.
	 */

	missing_procedure();
#   endif
#endif
DIR *d;
struct dirent *entryPtr;
char *p;
d = opendir("foobar");
entryPtr = readdir(d);
p = entryPtr->d_name;
closedir(d);
], tcl_cv_dirent_h=yes, tcl_cv_dirent_h=no))

    if test $tcl_cv_dirent_h = no; then
	AC_DEFINE(NO_DIRENT_H, 1, [Do we have <dirent.h>?])
    fi

    AC_CHECK_HEADER(errno.h, , [AC_DEFINE(NO_ERRNO_H, 1, [Do we have <errno.h>?])])
    AC_CHECK_HEADER(float.h, , [AC_DEFINE(NO_FLOAT_H, 1, [Do we have <float.h>?])])
    AC_CHECK_HEADER(values.h, , [AC_DEFINE(NO_VALUES_H, 1, [Do we have <values.h>?])])
    AC_CHECK_HEADER(limits.h,
	[AC_DEFINE(HAVE_LIMITS_H, 1, [Do we have <limits.h>?])],
	[AC_DEFINE(NO_LIMITS_H, 1, [Do we have <limits.h>?])])
    AC_CHECK_HEADER(stdlib.h, tcl_ok=1, tcl_ok=0)
    AC_EGREP_HEADER(strtol, stdlib.h, , tcl_ok=0)
    AC_EGREP_HEADER(strtoul, stdlib.h, , tcl_ok=0)
    AC_EGREP_HEADER(strtod, stdlib.h, , tcl_ok=0)
    if test $tcl_ok = 0; then
	AC_DEFINE(NO_STDLIB_H, 1, [Do we have <stdlib.h>?])
    fi
    AC_CHECK_HEADER(string.h, tcl_ok=1, tcl_ok=0)
    AC_EGREP_HEADER(strstr, string.h, , tcl_ok=0)
    AC_EGREP_HEADER(strerror, string.h, , tcl_ok=0)

    # See also memmove check below for a place where NO_STRING_H can be
    # set and why.

    if test $tcl_ok = 0; then
	AC_DEFINE(NO_STRING_H, 1, [Do we have <string.h>?])
    fi

    AC_CHECK_HEADER(sys/wait.h, , [AC_DEFINE(NO_SYS_WAIT_H, 1, [Do we have <sys/wait.h>?])])
    AC_CHECK_HEADER(dlfcn.h, , [AC_DEFINE(NO_DLFCN_H, 1, [Do we have <dlfcn.h>?])])

    # OS/390 lacks sys/param.h (and doesn't need it, by chance).
    AC_HAVE_HEADERS(sys/param.h)
])

#--------------------------------------------------------------------
# TEA_BLOCKING_STYLE
#
#	The statements below check for systems where POSIX-style
#	non-blocking I/O (O_NONBLOCK) doesn't work or is unimplemented. 
#	On these systems (mostly older ones), use the old BSD-style
#	FIONBIO approach instead.
#
# Arguments:
#	none
#	
# Results:
#
#	Defines some of the following vars:
#		HAVE_SYS_IOCTL_H
#		HAVE_SYS_FILIO_H
#		USE_FIONBIO
#		O_NONBLOCK
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_BLOCKING_STYLE], [
    AC_CHECK_HEADERS(sys/ioctl.h)
    AC_CHECK_HEADERS(sys/filio.h)
    TEA_CONFIG_SYSTEM
    AC_MSG_CHECKING([FIONBIO vs. O_NONBLOCK for nonblocking I/O])
    case $system in
	# There used to be code here to use FIONBIO under AIX.  However, it
	# was reported that FIONBIO doesn't work under AIX 3.2.5.  Since
	# using O_NONBLOCK seems fine under AIX 4.*, I removed the FIONBIO
	# code (JO, 5/31/97).

	OSF*)
	    AC_DEFINE(USE_FIONBIO, 1, [Should we use FIONBIO?])
	    AC_MSG_RESULT([FIONBIO])
	    ;;
	SunOS-4*)
	    AC_DEFINE(USE_FIONBIO, 1, [Should we use FIONBIO?])
	    AC_MSG_RESULT([FIONBIO])
	    ;;
	*)
	    AC_MSG_RESULT([O_NONBLOCK])
	    ;;
    esac
])

#--------------------------------------------------------------------
# TEA_TIME_HANLDER
#
#	Checks how the system deals with time.h, what time structures
#	are used on the system, and what fields the structures have.
#
# Arguments:
#	none
#	
# Results:
#
#	Defines some of the following vars:
#		USE_DELTA_FOR_TZ
#		HAVE_TM_GMTOFF
#		HAVE_TM_TZADJ
#		HAVE_TIMEZONE_VAR
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_TIME_HANDLER], [
    AC_CHECK_HEADERS(sys/time.h)
    AC_HEADER_TIME
    AC_STRUCT_TIMEZONE

    AC_CHECK_FUNCS(gmtime_r localtime_r)

    AC_CACHE_CHECK([tm_tzadj in struct tm], tcl_cv_member_tm_tzadj,
	AC_TRY_COMPILE([#include <time.h>], [struct tm tm; tm.tm_tzadj;],
	    tcl_cv_member_tm_tzadj=yes, tcl_cv_member_tm_tzadj=no))
    if test $tcl_cv_member_tm_tzadj = yes ; then
	AC_DEFINE(HAVE_TM_TZADJ, 1, [Should we use the tm_tzadj field of struct tm?])
    fi

    AC_CACHE_CHECK([tm_gmtoff in struct tm], tcl_cv_member_tm_gmtoff,
	AC_TRY_COMPILE([#include <time.h>], [struct tm tm; tm.tm_gmtoff;],
	    tcl_cv_member_tm_gmtoff=yes, tcl_cv_member_tm_gmtoff=no))
    if test $tcl_cv_member_tm_gmtoff = yes ; then
	AC_DEFINE(HAVE_TM_GMTOFF, 1, [Should we use the tm_gmtoff field of struct tm?])
    fi

    #
    # Its important to include time.h in this check, as some systems
    # (like convex) have timezone functions, etc.
    #
    AC_CACHE_CHECK([long timezone variable], tcl_cv_timezone_long,
	AC_TRY_COMPILE([#include <time.h>],
	    [extern long timezone;
	    timezone += 1;
	    exit (0);],
	    tcl_cv_timezone_long=yes, tcl_cv_timezone_long=no))
    if test $tcl_cv_timezone_long = yes ; then
	AC_DEFINE(HAVE_TIMEZONE_VAR, 1, [Should we use the global timezone variable?])
    else
	#
	# On some systems (eg IRIX 6.2), timezone is a time_t and not a long.
	#
	AC_CACHE_CHECK([time_t timezone variable], tcl_cv_timezone_time,
	    AC_TRY_COMPILE([#include <time.h>],
		[extern time_t timezone;
		timezone += 1;
		exit (0);],
		tcl_cv_timezone_time=yes, tcl_cv_timezone_time=no))
	if test $tcl_cv_timezone_time = yes ; then
	    AC_DEFINE(HAVE_TIMEZONE_VAR, 1, [Should we use the global timezone variable?])
	fi
    fi
])

#--------------------------------------------------------------------
# TEA_BUGGY_STRTOD
#
#	Under Solaris 2.4, strtod returns the wrong value for the
#	terminating character under some conditions.  Check for this
#	and if the problem exists use a substitute procedure
#	"fixstrtod" (provided by Tcl) that corrects the error.
#	Also, on Compaq's Tru64 Unix 5.0,
#	strtod(" ") returns 0.0 instead of a failure to convert.
#
# Arguments:
#	none
#	
# Results:
#
#	Might defines some of the following vars:
#		strtod (=fixstrtod)
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_BUGGY_STRTOD], [
    AC_CHECK_FUNC(strtod, tcl_strtod=1, tcl_strtod=0)
    if test "$tcl_strtod" = 1; then
	AC_CACHE_CHECK([for Solaris2.4/Tru64 strtod bugs], tcl_cv_strtod_buggy,[
	    AC_TRY_RUN([
		extern double strtod();
		int main() {
		    char *infString="Inf", *nanString="NaN", *spaceString=" ";
		    char *term;
		    double value;
		    value = strtod(infString, &term);
		    if ((term != infString) && (term[-1] == 0)) {
			exit(1);
		    }
		    value = strtod(nanString, &term);
		    if ((term != nanString) && (term[-1] == 0)) {
			exit(1);
		    }
		    value = strtod(spaceString, &term);
		    if (term == (spaceString+1)) {
			exit(1);
		    }
		    exit(0);
		}], tcl_cv_strtod_buggy=ok, tcl_cv_strtod_buggy=buggy,
		    tcl_cv_strtod_buggy=buggy)])
	if test "$tcl_cv_strtod_buggy" = buggy; then
	    AC_LIBOBJ([fixstrtod])
	    USE_COMPAT=1
	    AC_DEFINE(strtod, fixstrtod, [Do we want to use the strtod() in compat?])
	fi
    fi
])

#--------------------------------------------------------------------
# TEA_TCL_LINK_LIBS
#
#	Search for the libraries needed to link the Tcl shell.
#	Things like the math library (-lm) and socket stuff (-lsocket vs.
#	-lnsl) are dealt with here.
#
# Arguments:
#	Requires the following vars to be set in the Makefile:
#		DL_LIBS
#		LIBS
#		MATH_LIBS
#	
# Results:
#
#	Subst's the following var:
#		TCL_LIBS
#		MATH_LIBS
#
#	Might append to the following vars:
#		LIBS
#
#	Might define the following vars:
#		HAVE_NET_ERRNO_H
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_TCL_LINK_LIBS], [
    #--------------------------------------------------------------------
    # On a few very rare systems, all of the libm.a stuff is
    # already in libc.a.  Set compiler flags accordingly.
    # Also, Linux requires the "ieee" library for math to work
    # right (and it must appear before "-lm").
    #--------------------------------------------------------------------

    AC_CHECK_FUNC(sin, MATH_LIBS="", MATH_LIBS="-lm")
    AC_CHECK_LIB(ieee, main, [MATH_LIBS="-lieee $MATH_LIBS"])

    #--------------------------------------------------------------------
    # Interactive UNIX requires -linet instead of -lsocket, plus it
    # needs net/errno.h to define the socket-related error codes.
    #--------------------------------------------------------------------

    AC_CHECK_LIB(inet, main, [LIBS="$LIBS -linet"])
    AC_CHECK_HEADER(net/errno.h, [
	AC_DEFINE(HAVE_NET_ERRNO_H, 1, [Do we have <net/errno.h>?])])

    #--------------------------------------------------------------------
    #	Check for the existence of the -lsocket and -lnsl libraries.
    #	The order here is important, so that they end up in the right
    #	order in the command line generated by make.  Here are some
    #	special considerations:
    #	1. Use "connect" and "accept" to check for -lsocket, and
    #	   "gethostbyname" to check for -lnsl.
    #	2. Use each function name only once:  can't redo a check because
    #	   autoconf caches the results of the last check and won't redo it.
    #	3. Use -lnsl and -lsocket only if they supply procedures that
    #	   aren't already present in the normal libraries.  This is because
    #	   IRIX 5.2 has libraries, but they aren't needed and they're
    #	   bogus:  they goof up name resolution if used.
    #	4. On some SVR4 systems, can't use -lsocket without -lnsl too.
    #	   To get around this problem, check for both libraries together
    #	   if -lsocket doesn't work by itself.
    #--------------------------------------------------------------------

    tcl_checkBoth=0
    AC_CHECK_FUNC(connect, tcl_checkSocket=0, tcl_checkSocket=1)
    if test "$tcl_checkSocket" = 1; then
	AC_CHECK_FUNC(setsockopt, , [AC_CHECK_LIB(socket, setsockopt,
	    LIBS="$LIBS -lsocket", tcl_checkBoth=1)])
    fi
    if test "$tcl_checkBoth" = 1; then
	tk_oldLibs=$LIBS
	LIBS="$LIBS -lsocket -lnsl"
	AC_CHECK_FUNC(accept, tcl_checkNsl=0, [LIBS=$tk_oldLibs])
    fi
    AC_CHECK_FUNC(gethostbyname, , [AC_CHECK_LIB(nsl, gethostbyname,
	    [LIBS="$LIBS -lnsl"])])
    
    # Don't perform the eval of the libraries here because DL_LIBS
    # won't be set until we call TEA_CONFIG_CFLAGS

    TCL_LIBS='${DL_LIBS} ${LIBS} ${MATH_LIBS}'
    AC_SUBST(TCL_LIBS)
    AC_SUBST(MATH_LIBS)
])

#--------------------------------------------------------------------
# TEA_TCL_EARLY_FLAGS
#
#	Check for what flags are needed to be passed so the correct OS
#	features are available.
#
# Arguments:
#	None
#	
# Results:
#
#	Might define the following vars:
#		_ISOC99_SOURCE
#		_LARGEFILE64_SOURCE
#		_LARGEFILE_SOURCE64
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_TCL_EARLY_FLAG],[
    AC_CACHE_VAL([tcl_cv_flag_]translit($1,[A-Z],[a-z]),
	AC_TRY_COMPILE([$2], $3, [tcl_cv_flag_]translit($1,[A-Z],[a-z])=no,
	    AC_TRY_COMPILE([[#define ]$1[ 1
]$2], $3,
		[tcl_cv_flag_]translit($1,[A-Z],[a-z])=yes,
		[tcl_cv_flag_]translit($1,[A-Z],[a-z])=no)))
    if test ["x${tcl_cv_flag_]translit($1,[A-Z],[a-z])[}" = "xyes"] ; then
	AC_DEFINE($1, 1, [Add the ]$1[ flag when building])
	tcl_flags="$tcl_flags $1"
    fi
])

AC_DEFUN([TEA_TCL_EARLY_FLAGS],[
    AC_MSG_CHECKING([for required early compiler flags])
    tcl_flags=""
    TEA_TCL_EARLY_FLAG(_ISOC99_SOURCE,[#include <stdlib.h>],
	[char *p = (char *)strtoll; char *q = (char *)strtoull;])
    TEA_TCL_EARLY_FLAG(_LARGEFILE64_SOURCE,[#include <sys/stat.h>],
	[struct stat64 buf; int i = stat64("/", &buf);])
    TEA_TCL_EARLY_FLAG(_LARGEFILE_SOURCE64,[#include <sys/stat.h>],
	[char *p = (char *)open64;])
    if test "x${tcl_flags}" = "x" ; then
	AC_MSG_RESULT([none])
    else
	AC_MSG_RESULT([${tcl_flags}])
    fi
])

#--------------------------------------------------------------------
# TEA_TCL_64BIT_FLAGS
#
#	Check for what is defined in the way of 64-bit features.
#
# Arguments:
#	None
#	
# Results:
#
#	Might define the following vars:
#		TCL_WIDE_INT_IS_LONG
#		TCL_WIDE_INT_TYPE
#		HAVE_STRUCT_DIRENT64
#		HAVE_STRUCT_STAT64
#		HAVE_TYPE_OFF64_T
#
#--------------------------------------------------------------------

AC_DEFUN([TEA_TCL_64BIT_FLAGS], [
    AC_MSG_CHECKING([for 64-bit integer type])
    AC_CACHE_VAL(tcl_cv_type_64bit,[
	tcl_cv_type_64bit=none
	# See if the compiler knows natively about __int64
	AC_TRY_COMPILE(,[__int64 value = (__int64) 0;],
	    tcl_type_64bit=__int64, tcl_type_64bit="long long")
	# See if we should use long anyway  Note that we substitute in the
	# type that is our current guess for a 64-bit type inside this check
	# program, so it should be modified only carefully...
        AC_TRY_COMPILE(,[switch (0) { 
            case 1: case (sizeof(]${tcl_type_64bit}[)==sizeof(long)): ; 
        }],tcl_cv_type_64bit=${tcl_type_64bit})])
    if test "${tcl_cv_type_64bit}" = none ; then
	AC_DEFINE(TCL_WIDE_INT_IS_LONG, 1, [Are wide integers to be implemented with C 'long's?])
	AC_MSG_RESULT([using long])
    elif test "${tcl_cv_type_64bit}" = "__int64" \
		-a "${TEA_PLATFORM}" = "windows" ; then
	# We actually want to use the default tcl.h checks in this
	# case to handle both TCL_WIDE_INT_TYPE and TCL_LL_MODIFIER*
	AC_MSG_RESULT([using Tcl header defaults])
    else
	AC_DEFINE_UNQUOTED(TCL_WIDE_INT_TYPE,${tcl_cv_type_64bit},
	    [What type should be used to define wide integers?])
	AC_MSG_RESULT([${tcl_cv_type_64bit}])

	# Now check for auxiliary declarations
	AC_CACHE_CHECK([for struct dirent64], tcl_cv_struct_dirent64,[
	    AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/dirent.h>],[struct dirent64 p;],
		tcl_cv_struct_dirent64=yes,tcl_cv_struct_dirent64=no)])
	if test "x${tcl_cv_struct_dirent64}" = "xyes" ; then
	    AC_DEFINE(HAVE_STRUCT_DIRENT64, 1, [Is 'struct dirent64' in <sys/types.h>?])
	fi

	AC_CACHE_CHECK([for struct stat64], tcl_cv_struct_stat64,[
	    AC_TRY_COMPILE([#include <sys/stat.h>],[struct stat64 p;
],
		tcl_cv_struct_stat64=yes,tcl_cv_struct_stat64=no)])
	if test "x${tcl_cv_struct_stat64}" = "xyes" ; then
	    AC_DEFINE(HAVE_STRUCT_STAT64, 1, [Is 'struct stat64' in <sys/stat.h>?])
	fi

	AC_CHECK_FUNCS(open64 lseek64)
	AC_MSG_CHECKING([for off64_t])
	AC_CACHE_VAL(tcl_cv_type_off64_t,[
	    AC_TRY_COMPILE([#include <sys/types.h>],[off64_t offset;
],
		tcl_cv_type_off64_t=yes,tcl_cv_type_off64_t=no)])
	dnl Define HAVE_TYPE_OFF64_T only when the off64_t type and the
	dnl functions lseek64 and open64 are defined.
	if test "x${tcl_cv_type_off64_t}" = "xyes" && \
	        test "x${ac_cv_func_lseek64}" = "xyes" && \
	        test "x${ac_cv_func_open64}" = "xyes" ; then
	    AC_DEFINE(HAVE_TYPE_OFF64_T, 1, [Is off64_t in <sys/types.h>?])
	    AC_MSG_RESULT([yes])
	else
	    AC_MSG_RESULT([no])
	fi
    fi
])

##
## Here ends the standard Tcl configuration bits and starts the
## TEA specific functions
##

#------------------------------------------------------------------------
# TEA_INIT --
#
#	Init various Tcl Extension Architecture (TEA) variables.
#	This should be the first called TEA_* macro.
#
# Arguments:
#	none
#
# Results:
#
#	Defines and substs the following vars:
#		CYGPATH
#		EXEEXT
#	Defines only:
#		TEA_VERSION
#		TEA_INITED
#		TEA_PLATFORM (windows or unix)
#
# "cygpath" is used on windows to generate native path names for include
# files. These variables should only be used with the compiler and linker
# since they generate native path names.
#
# EXEEXT
#	Select the executable extension based on the host type.  This
#	is a lightweight replacement for AC_EXEEXT that doesn't require
#	a compiler.
#------------------------------------------------------------------------

AC_DEFUN([TEA_INIT], [
    # TEA extensions pass this us the version of TEA they think they
    # are compatible with.
    TEA_VERSION="3.5"

    AC_MSG_CHECKING([for correct TEA configuration])
    if test x"${PACKAGE_NAME}" = x ; then
	AC_MSG_ERROR([
The PACKAGE_NAME variable must be defined by your TEA configure.in])
    fi
    if test x"$1" = x ; then
	AC_MSG_ERROR([
TEA version not specified.])
    elif test "$1" != "${TEA_VERSION}" ; then
	AC_MSG_RESULT([warning: requested TEA version "$1", have "${TEA_VERSION}"])
    else
	AC_MSG_RESULT([ok (TEA ${TEA_VERSION})])
    fi
    case "`uname -s`" in
	*win32*|*WIN32*|*CYGWIN_NT*|*CYGWIN_9*|*CYGWIN_ME*|*MINGW32_*)
	    AC_CHECK_PROG(CYGPATH, cygpath, cygpath -w, echo)
	    EXEEXT=".exe"
	    TEA_PLATFORM="windows"
	    ;;
	*)
	    CYGPATH=echo
	    EXEEXT=""
	    TEA_PLATFORM="unix"
	    ;;
    esac

    # Check if exec_prefix is set. If not use fall back to prefix.
    # Note when adjusted, so that TEA_PREFIX can correct for this.
    # This is needed for recursive configures, since autoconf propagates
    # $prefix, but not $exec_prefix (doh!).
    if test x$exec_prefix = xNONE ; then
	exec_prefix_default=yes
	exec_prefix=$prefix
    fi

    AC_SUBST(EXEEXT)
    AC_SUBST(CYGPATH)

    # This package name must be replaced statically for AC_SUBST to work
    AC_SUBST(PKG_LIB_FILE)
    # Substitute STUB_LIB_FILE in case package creates a stub library too.
    AC_SUBST(PKG_STUB_LIB_FILE)

    # We AC_SUBST these here to ensure they are subst'ed,
    # in case the user doesn't call TEA_ADD_...
    AC_SUBST(PKG_STUB_SOURCES)
    AC_SUBST(PKG_STUB_OBJECTS)
    AC_SUBST(PKG_TCL_SOURCES)
    AC_SUBST(PKG_HEADERS)
    AC_SUBST(PKG_INCLUDES)
    AC_SUBST(PKG_LIBS)
    AC_SUBST(PKG_CFLAGS)
])

#------------------------------------------------------------------------
# TEA_ADD_SOURCES --
#
#	Specify one or more source files.  Users should check for
#	the right platform before adding to their list.
#	It is not important to specify the directory, as long as it is
#	in the generic, win or unix subdirectory of $(srcdir).
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_SOURCES
#		PKG_OBJECTS
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_SOURCES], [
    vars="$@"
    for i in $vars; do
	case $i in
	    [\$]*)
		# allow $-var names
		PKG_SOURCES="$PKG_SOURCES $i"
		PKG_OBJECTS="$PKG_OBJECTS $i"
		;;
	    *)
		# check for existence - allows for generic/win/unix VPATH
		if test ! -f "${srcdir}/$i" -a ! -f "${srcdir}/generic/$i" \
		    -a ! -f "${srcdir}/win/$i" -a ! -f "${srcdir}/unix/$i" \
		    ; then
		    AC_MSG_ERROR([could not find source file '$i'])
		fi
		PKG_SOURCES="$PKG_SOURCES $i"
		# this assumes it is in a VPATH dir
		i=`basename $i`
		# handle user calling this before or after TEA_SETUP_COMPILER
		if test x"${OBJEXT}" != x ; then
		    j="`echo $i | sed -e 's/\.[[^.]]*$//'`.${OBJEXT}"
		else
		    j="`echo $i | sed -e 's/\.[[^.]]*$//'`.\${OBJEXT}"
		fi
		PKG_OBJECTS="$PKG_OBJECTS $j"
		;;
	esac
    done
    AC_SUBST(PKG_SOURCES)
    AC_SUBST(PKG_OBJECTS)
])

#------------------------------------------------------------------------
# TEA_ADD_STUB_SOURCES --
#
#	Specify one or more source files.  Users should check for
#	the right platform before adding to their list.
#	It is not important to specify the directory, as long as it is
#	in the generic, win or unix subdirectory of $(srcdir).
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_STUB_SOURCES
#		PKG_STUB_OBJECTS
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_STUB_SOURCES], [
    vars="$@"
    for i in $vars; do
	# check for existence - allows for generic/win/unix VPATH
	if test ! -f "${srcdir}/$i" -a ! -f "${srcdir}/generic/$i" \
	    -a ! -f "${srcdir}/win/$i" -a ! -f "${srcdir}/unix/$i" \
	    ; then
	    AC_MSG_ERROR([could not find stub source file '$i'])
	fi
	PKG_STUB_SOURCES="$PKG_STUB_SOURCES $i"
	# this assumes it is in a VPATH dir
	i=`basename $i`
	# handle user calling this before or after TEA_SETUP_COMPILER
	if test x"${OBJEXT}" != x ; then
	    j="`echo $i | sed -e 's/\.[[^.]]*$//'`.${OBJEXT}"
	else
	    j="`echo $i | sed -e 's/\.[[^.]]*$//'`.\${OBJEXT}"
	fi
	PKG_STUB_OBJECTS="$PKG_STUB_OBJECTS $j"
    done
    AC_SUBST(PKG_STUB_SOURCES)
    AC_SUBST(PKG_STUB_OBJECTS)
])

#------------------------------------------------------------------------
# TEA_ADD_TCL_SOURCES --
#
#	Specify one or more Tcl source files.  These should be platform
#	independent runtime files.
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_TCL_SOURCES
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_TCL_SOURCES], [
    vars="$@"
    for i in $vars; do
	# check for existence, be strict because it is installed
	if test ! -f "${srcdir}/$i" ; then
	    AC_MSG_ERROR([could not find tcl source file '${srcdir}/$i'])
	fi
	PKG_TCL_SOURCES="$PKG_TCL_SOURCES $i"
    done
    AC_SUBST(PKG_TCL_SOURCES)
])

#------------------------------------------------------------------------
# TEA_ADD_HEADERS --
#
#	Specify one or more source headers.  Users should check for
#	the right platform before adding to their list.
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_HEADERS
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_HEADERS], [
    vars="$@"
    for i in $vars; do
	# check for existence, be strict because it is installed
	if test ! -f "${srcdir}/$i" ; then
	    AC_MSG_ERROR([could not find header file '${srcdir}/$i'])
	fi
	PKG_HEADERS="$PKG_HEADERS $i"
    done
    AC_SUBST(PKG_HEADERS)
])

#------------------------------------------------------------------------
# TEA_ADD_INCLUDES --
#
#	Specify one or more include dirs.  Users should check for
#	the right platform before adding to their list.
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_INCLUDES
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_INCLUDES], [
    vars="$@"
    for i in $vars; do
	PKG_INCLUDES="$PKG_INCLUDES $i"
    done
    AC_SUBST(PKG_INCLUDES)
])

#------------------------------------------------------------------------
# TEA_ADD_LIBS --
#
#	Specify one or more libraries.  Users should check for
#	the right platform before adding to their list.  For Windows,
#	libraries provided in "foo.lib" format will be converted to
#	"-lfoo" when using GCC (mingw).
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_LIBS
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_LIBS], [
    vars="$@"
    for i in $vars; do
	if test "${TEA_PLATFORM}" = "windows" -a "$GCC" = "yes" ; then
	    # Convert foo.lib to -lfoo for GCC.  No-op if not *.lib
	    i=`echo "$i" | sed -e 's/^\([[^-]].*\)\.lib[$]/-l\1/i'`
	fi
	PKG_LIBS="$PKG_LIBS $i"
    done
    AC_SUBST(PKG_LIBS)
])

#------------------------------------------------------------------------
# TEA_ADD_CFLAGS --
#
#	Specify one or more CFLAGS.  Users should check for
#	the right platform before adding to their list.
#
# Arguments:
#	one or more file names
#
# Results:
#
#	Defines and substs the following vars:
#		PKG_CFLAGS
#------------------------------------------------------------------------
AC_DEFUN([TEA_ADD_CFLAGS], [
    PKG_CFLAGS="$PKG_CFLAGS $@"
    AC_SUBST(PKG_CFLAGS)
])

#------------------------------------------------------------------------
# TEA_PREFIX --
#
#	Handle the --prefix=... option by defaulting to what Tcl gave
#
# Arguments:
#	none
#
# Results:
#
#	If --prefix or --exec-prefix was not specified, $prefix and
#	$exec_prefix will be set to the values given to Tcl when it was
#	configured.
#------------------------------------------------------------------------
AC_DEFUN([TEA_PREFIX], [
    if test "${prefix}" = "NONE"; then
	prefix_default=yes
	if test x"${TCL_PREFIX}" != x; then
	    AC_MSG_NOTICE([--prefix defaulting to TCL_PREFIX ${TCL_PREFIX}])
	    prefix=${TCL_PREFIX}
	else
	    AC_MSG_NOTICE([--prefix defaulting to /usr/local])
	    prefix=/usr/local
	fi
    fi
    if test "${exec_prefix}" = "NONE" -a x"${prefix_default}" = x"yes" \
	-o x"${exec_prefix_default}" = x"yes" ; then
	if test x"${TCL_EXEC_PREFIX}" != x; then
	    AC_MSG_NOTICE([--exec-prefix defaulting to TCL_EXEC_PREFIX ${TCL_EXEC_PREFIX}])
	    exec_prefix=${TCL_EXEC_PREFIX}
	else
	    AC_MSG_NOTICE([--exec-prefix defaulting to ${prefix}])
	    exec_prefix=$prefix
	fi
    fi
])

#------------------------------------------------------------------------
# TEA_SETUP_COMPILER_CC --
#
#	Do compiler checks the way we want.  This is just a replacement
#	for AC_PROG_CC in TEA configure.in files to make them cleaner.
#
# Arguments:
#	none
#
# Results:
#
#	Sets up CC var and other standard bits we need to make executables.
#------------------------------------------------------------------------
AC_DEFUN([TEA_SETUP_COMPILER_CC], [
    # Don't put any macros that use the compiler (e.g. AC_TRY_COMPILE)
    # in this macro, they need to go into TEA_SETUP_COMPILER instead.

    # If the user did not set CFLAGS, set it now to keep
    # the AC_PROG_CC macro from adding "-g -O2".
    if test "${CFLAGS+set}" != "set" ; then
	CFLAGS=""
    fi

    AC_PROG_CC
    AC_PROG_CPP

    AC_PROG_INSTALL

    #--------------------------------------------------------------------
    # Checks to see if the make program sets the $MAKE variable.
    #--------------------------------------------------------------------

    AC_PROG_MAKE_SET

    #--------------------------------------------------------------------
    # Find ranlib
    #--------------------------------------------------------------------

    AC_PROG_RANLIB

    #--------------------------------------------------------------------
    # Determines the correct binary file extension (.o, .obj, .exe etc.)
    #--------------------------------------------------------------------

    AC_OBJEXT
    AC_EXEEXT
])

#------------------------------------------------------------------------
# TEA_SETUP_COMPILER --
#
#	Do compiler checks that use the compiler.  This must go after
#	TEA_SETUP_COMPILER_CC, which does the actual compiler check.
#
# Arguments:
#	none
#
# Results:
#
#	Sets up CC var and other standard bits we need to make executables.
#------------------------------------------------------------------------
AC_DEFUN([TEA_SETUP_COMPILER], [
    # Any macros that use the compiler (e.g. AC_TRY_COMPILE) have to go here.
    AC_REQUIRE([TEA_SETUP_COMPILER_CC])

    #------------------------------------------------------------------------
    # If we're using GCC, see if the compiler understands -pipe. If so, use it.
    # It makes compiling go faster.  (This is only a performance feature.)
    #------------------------------------------------------------------------

    if test -z "$no_pipe" -a -n "$GCC"; then
	AC_MSG_CHECKING([if the compiler understands -pipe])
	OLDCC="$CC"
	CC="$CC -pipe"
	AC_TRY_COMPILE(,, AC_MSG_RESULT([yes]), CC="$OLDCC"
	    AC_MSG_RESULT([no]))
    fi

    #--------------------------------------------------------------------
    # Common compiler flag setup
    #--------------------------------------------------------------------

    AC_C_BIGENDIAN
    if test "${TEA_PLATFORM}" = "unix" ; then
	TEA_TCL_LINK_LIBS
	TEA_MISSING_POSIX_HEADERS
	# Let the user call this, because if it triggers, they will
	# need a compat/strtod.c that is correct.  Users can also
	# use Tcl_GetDouble(FromObj) instead.
	#TEA_BUGGY_STRTOD
    fi
])

#------------------------------------------------------------------------
# TEA_MAKE_LIB --
#
#	Generate a line that can be used to build a shared/unshared library
#	in a platform independent manner.
#
# Arguments:
#	none
#
#	Requires:
#
# Results:
#
#	Defines the following vars:
#	CFLAGS -	Done late here to note disturb other AC macros
#       MAKE_LIB -      Command to execute to build the Tcl library;
#                       differs depending on whether or not Tcl is being
#                       compiled as a shared library.
#	MAKE_SHARED_LIB	Makefile rule for building a shared library
#	MAKE_STATIC_LIB	Makefile rule for building a static library
#	MAKE_STUB_LIB	Makefile rule for building a stub library
#------------------------------------------------------------------------

AC_DEFUN([TEA_MAKE_LIB], [
    if test "${TEA_PLATFORM}" = "windows" -a "$GCC" != "yes"; then
	MAKE_STATIC_LIB="\${STLIB_LD} -out:\[$]@ \$(PKG_OBJECTS)"
	MAKE_SHARED_LIB="\${SHLIB_LD} \${SHLIB_LD_LIBS} \${LDFLAGS_DEFAULT} -out:\[$]@ \$(PKG_OBJECTS)"
	MAKE_STUB_LIB="\${STLIB_LD} -out:\[$]@ \$(PKG_STUB_OBJECTS)"
    else
	MAKE_STATIC_LIB="\${STLIB_LD} \[$]@ \$(PKG_OBJECTS)"
	MAKE_SHARED_LIB="\${SHLIB_LD} -o \[$]@ \$(PKG_OBJECTS) \${SHLIB_LD_LIBS}"
	MAKE_STUB_LIB="\${STLIB_LD} \[$]@ \$(PKG_STUB_OBJECTS)"
    fi

    if test "${SHARED_BUILD}" = "1" ; then
	MAKE_LIB="${MAKE_SHARED_LIB} "
    else
	MAKE_LIB="${MAKE_STATIC_LIB} "
    fi

    #--------------------------------------------------------------------
    # Shared libraries and static libraries have different names.
    # Use the double eval to make sure any variables in the suffix is
    # substituted. (@@@ Might not be necessary anymore)
    #--------------------------------------------------------------------

    if test "${TEA_PLATFORM}" = "windows" ; then
	if test "${SHARED_BUILD}" = "1" ; then
	    # We force the unresolved linking of symbols that are really in
	    # the private libraries of Tcl and Tk.
	    SHLIB_LD_LIBS="${SHLIB_LD_LIBS} \"`${CYGPATH} ${TCL_BIN_DIR}/${TCL_STUB_LIB_FILE}`\""
	    if test x"${TK_BIN_DIR}" != x ; then
		SHLIB_LD_LIBS="${SHLIB_LD_LIBS} \"`${CYGPATH} ${TK_BIN_DIR}/${TK_STUB_LIB_FILE}`\""
	    fi
	    eval eval "PKG_LIB_FILE=${PACKAGE_NAME}${SHARED_LIB_SUFFIX}"
	else
	    eval eval "PKG_LIB_FILE=${PACKAGE_NAME}${UNSHARED_LIB_SUFFIX}"
	fi
	# Some packages build their own stubs libraries
	eval eval "PKG_STUB_LIB_FILE=${PACKAGE_NAME}stub${UNSHARED_LIB_SUFFIX}"
	if test "$GCC" = "yes"; then
	    PKG_STUB_LIB_FILE=lib${PKG_STUB_LIB_FILE}
	fi
	# These aren't needed on Windows (either MSVC or gcc)
	RANLIB=:
	RANLIB_STUB=:
    else
	RANLIB_STUB="${RANLIB}"
	if test "${SHARED_BUILD}" = "1" ; then
	    SHLIB_LD_LIBS="${SHLIB_LD_LIBS} ${TCL_STUB_LIB_SPEC}"
	    if test x"${TK_BIN_DIR}" != x ; then
		SHLIB_LD_LIBS="${SHLIB_LD_LIBS} ${TK_STUB_LIB_SPEC}"
	    fi
	    eval eval "PKG_LIB_FILE=lib${PACKAGE_NAME}${SHARED_LIB_SUFFIX}"
	    RANLIB=:
	else
	    eval eval "PKG_LIB_FILE=lib${PACKAGE_NAME}${UNSHARED_LIB_SUFFIX}"
	fi
	# Some packages build their own stubs libraries
	eval eval "PKG_STUB_LIB_FILE=lib${PACKAGE_NAME}stub${UNSHARED_LIB_SUFFIX}"
    fi

    # These are escaped so that only CFLAGS is picked up at configure time.
    # The other values will be substituted at make time.
    CFLAGS="${CFLAGS} \${CFLAGS_DEFAULT} \${CFLAGS_WARNING}"
    if test "${SHARED_BUILD}" = "1" ; then
	CFLAGS="${CFLAGS} \${SHLIB_CFLAGS}"
    fi

    AC_SUBST(MAKE_LIB)
    AC_SUBST(MAKE_SHARED_LIB)
    AC_SUBST(MAKE_STATIC_LIB)
    AC_SUBST(MAKE_STUB_LIB)
    AC_SUBST(RANLIB_STUB)
])

#------------------------------------------------------------------------
# TEA_PUBLIC_TCL_HEADERS --
#
#	Locate the installed public Tcl header files
#
# Arguments:
#	None.
#
# Requires:
#	CYGPATH must be set
#
# Results:
#
#	Adds a --with-tclinclude switch to configure.
#	Result is cached.
#
#	Substs the following vars:
#		TCL_INCLUDES
#------------------------------------------------------------------------

AC_DEFUN([TEA_PUBLIC_TCL_HEADERS], [
    AC_MSG_CHECKING([for Tcl public headers])

    AC_ARG_WITH(tclinclude, [  --with-tclinclude       directory containing the public Tcl header files], with_tclinclude=${withval})

    AC_CACHE_VAL(ac_cv_c_tclh, [
	# Use the value from --with-tclinclude, if it was given

	if test x"${with_tclinclude}" != x ; then
	    if test -f "${with_tclinclude}/tcl.h" ; then
		ac_cv_c_tclh=${with_tclinclude}
	    else
		AC_MSG_ERROR([${with_tclinclude} directory does not contain tcl.h])
	    fi
	else
	    if test "`uname -s`" = "Darwin"; then
		# If Tcl was built as a framework, attempt to use
		# the framework's Headers directory
		case ${TCL_DEFS} in
		    *TCL_FRAMEWORK*)
			list="`ls -d ${TCL_BIN_DIR}/Headers 2>/dev/null`"
			;;
		esac
	    fi

	    # Look in the source dir only if Tcl is not installed,
	    # and in that situation, look there before installed locations.
	    if test -f "${TCL_BIN_DIR}/Makefile" ; then
		list="$list `ls -d ${TCL_SRC_DIR}/generic 2>/dev/null`"
	    fi

	    # Check order: pkg --prefix location, Tcl's --prefix location,
	    # relative to directory of tclConfig.sh.

	    eval "temp_includedir=${includedir}"
	    list="$list \
		`ls -d ${temp_includedir}        2>/dev/null` \
		`ls -d ${TCL_PREFIX}/include     2>/dev/null` \
		`ls -d ${TCL_BIN_DIR}/../include 2>/dev/null`"
	    if test "${TEA_PLATFORM}" != "windows" -o "$GCC" = "yes"; then
		list="$list /usr/local/include /usr/include"
		if test x"${TCL_INCLUDE_SPEC}" != x ; then
		    d=`echo "${TCL_INCLUDE_SPEC}" | sed -e 's/^-I//'`
		    list="$list `ls -d ${d} 2>/dev/null`"
		fi
	    fi
	    for i in $list ; do
		if test -f "$i/tcl.h" ; then
		    ac_cv_c_tclh=$i
		    break
		fi
	    done
	fi
    ])

    # Print a message based on how we determined the include path

    if test x"${ac_cv_c_tclh}" = x ; then
	AC_MSG_ERROR([tcl.h not found.  Please specify its location with --with-tclinclude])
    else
	AC_MSG_RESULT([${ac_cv_c_tclh}])
    fi

    # Convert to a native path and substitute into the output files.

    INCLUDE_DIR_NATIVE=`${CYGPATH} ${ac_cv_c_tclh}`

    TCL_INCLUDES=-I\"${INCLUDE_DIR_NATIVE}\"

    AC_SUBST(TCL_INCLUDES)
])


#------------------------------------------------------------------------
# TEA_PROG_TCLSH
#	Determine the fully qualified path name of the tclsh executable
#	in the Tcl build directory or the tclsh installed in a bin
#	directory. This macro will correctly determine the name
#	of the tclsh executable even if tclsh has not yet been
#	built in the build directory. The tclsh found is always
#	associated with a tclConfig.sh file. This tclsh should be used
#	only for running extension test cases. It should never be
#	or generation of files (like pkgIndex.tcl) at build time.
#
# Arguments
#	none
#
# Results
#	Subst's the following values:
#		TCLSH_PROG
#------------------------------------------------------------------------

AC_DEFUN([TEA_PROG_TCLSH], [
    AC_MSG_CHECKING([for tclsh])
    if test -f "${TCL_BIN_DIR}/Makefile" ; then
        # tclConfig.sh is in Tcl build directory
        if test "${TEA_PLATFORM}" = "windows"; then
            TCLSH_PROG="${TCL_BIN_DIR}/tclsh${TCL_MAJOR_VERSION}${TCL_MINOR_VERSION}${TCL_DBGX}${EXEEXT}"
        else
            TCLSH_PROG="${TCL_BIN_DIR}/tclsh"
        fi
    else
        # tclConfig.sh is in install location
        if test "${TEA_PLATFORM}" = "windows"; then
            TCLSH_PROG="tclsh${TCL_MAJOR_VERSION}${TCL_MINOR_VERSION}${TCL_DBGX}${EXEEXT}"
        else
            TCLSH_PROG="tclsh${TCL_MAJOR_VERSION}.${TCL_MINOR_VERSION}${TCL_DBGX}"
        fi
        list="`ls -d ${TCL_BIN_DIR}/../bin 2>/dev/null` \
              `ls -d ${TCL_BIN_DIR}/..     2>/dev/null` \
              `ls -d ${TCL_PREFIX}/bin     2>/dev/null`"
        for i in $list ; do
            if test -f "$i/${TCLSH_PROG}" ; then
                REAL_TCL_BIN_DIR="`cd "$i"; pwd`"
                break
            fi
        done
        TCLSH_PROG="${REAL_TCL_BIN_DIR}/${TCLSH_PROG}"
    fi
    AC_MSG_RESULT([${TCLSH_PROG}])
    AC_SUBST(TCLSH_PROG)
])
