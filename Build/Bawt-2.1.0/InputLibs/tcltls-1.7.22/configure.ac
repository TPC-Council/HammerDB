dnl Define ourselves
AC_INIT(tcltls, 1.7.22)

dnl Checks for programs.
AC_PROG_CC
AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_GNU_SOURCE

dnl Determine system information
DC_CHK_OS_INFO

dnl Look for appropriate headers
AC_CHECK_HEADERS(unistd.h stdlib.h string.h strings.h)

dnl Perform Tcl Extension required stuff
TCLEXT_INIT

if test "$TCLEXT_BUILD" != 'static'; then
	dnl Determine how to make shared objects
	DC_GET_SHOBJFLAGS

	EXTENSION_TARGET="tcltls.${SHOBJEXT}"
else
	AC_CHECK_TOOL([AR], [ar], [false])
	AC_CHECK_TOOL([RANLIB], [ranlib], [:])
	EXTENSION_TARGET="tcltls.${AREXT}"
fi
AC_SUBST(EXTENSION_TARGET)
AC_SUBST(TCLEXT_BUILD)

dnl Determine what SSL library to link with
AC_ARG_WITH([ssl], AS_HELP_STRING([--with-ssl=<name>], [name of ssl library to build against (openssl, libressl, nss, auto)]), [
	if test "$withval" = "no"; then
		AC_MSG_ERROR([You may not specify --without-ssl])
	fi

	if test "$withval" = "yes"; then
		AC_MSG_ERROR([If you specify --with-ssl then you must provide a value])
	fi

	tcltls_ssl_lib="$withval"
], [
	tcltls_ssl_lib='auto'
])

dnl Enable support for building the same library every time
tcltls_deterministic='false'
AC_ARG_ENABLE([deterministic], AS_HELP_STRING([--enable-deterministic], [enable deterministic parameters]), [
	if test "$enableval" = "yes"; then
		tcltls_deterministic='true'
	fi
])
if test "$tcltls_deterministic" = 'true'; then
	GEN_DH_PARAMS_ARGS='fallback'
else
	GEN_DH_PARAMS_ARGS=''
fi

dnl Enable support for specifying pre-computed DH params size
AC_ARG_WITH([builtin-dh-params-size], AS_HELP_STRING([--with-builtin-dh-params-size=<bits>], [specify the size of the built-in, precomputed, DH params]), [
	AS_CASE([$withval],
		[2048|4096|8192],,
		[
			AC_MSG_ERROR([Unsupported DH params size: $withval])
		]
	)
	GEN_DH_PARAMS_ARGS="${GEN_DH_PARAMS_ARGS} bits=$withval"
])
AC_SUBST(GEN_DH_PARAMS_ARGS)

dnl Allow the user to manually disable protocols
dnl ## SSLv2: Enabled by default
tcltls_ssl_ssl2='true'
AC_ARG_ENABLE([sslv2], AS_HELP_STRING([--disable-sslv2], [disable SSLv2 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_ssl2='force'
	else
		tcltls_ssl_ssl2='false'
	fi
])

dnl ## SSLv3: Enabled by default
tcltls_ssl_ssl3='true'
AC_ARG_ENABLE([sslv3], AS_HELP_STRING([--disable-sslv3], [disable SSLv3 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_ssl3='force'
	else
		tcltls_ssl_ssl3='false'
	fi
])

dnl ## TLSv1.0: Enabled by default
tcltls_ssl_tls1_0='true'
AC_ARG_ENABLE([tlsv1.0], AS_HELP_STRING([--disable-tlsv1.0], [disable TLSv1.0 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_tls1_0='force'
	else
		tcltls_ssl_tls1_0='false'
	fi
])

dnl ## TLSv1.1: Enabled by default
tcltls_ssl_tls1_1='true'
AC_ARG_ENABLE([tlsv1.1], AS_HELP_STRING([--disable-tlsv1.1], [disable TLSv1.1 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_tls1_1='force'
	else
		tcltls_ssl_tls1_1='false'
	fi
])

dnl ## TLSv1.2: Enabled by default
tcltls_ssl_tls1_2='true'
AC_ARG_ENABLE([tlsv1.2], AS_HELP_STRING([--disable-tlsv1.2], [disable TLSv1.2 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_tls1_2='force'
	else
		tcltls_ssl_tls1_2='false'
	fi
])

dnl ## TLSv1.3: Enabled by default
tcltls_ssl_tls1_3='true'
AC_ARG_ENABLE([tlsv1.3], AS_HELP_STRING([--disable-tlsv1.3], [disable TLSv1.3 protocol]), [
	if test "$enableval" = "yes"; then
		tcltls_ssl_tls1_3='force'
	else
		tcltls_ssl_tls1_3='false'
	fi
])


dnl Enable support for a debugging build
tcltls_debug='false'
AC_ARG_ENABLE([debug], AS_HELP_STRING([--enable-debug], [enable debugging parameters]), [
	if test "$enableval" = "yes"; then
		tcltls_debug='true'
	fi
])
if test "$tcltls_debug" = 'true'; then
	AC_DEFINE(TCLEXT_TCLTLS_DEBUG, [1], [Enable debugging build])
	AX_CHECK_COMPILE_FLAG([-fcheck-pointer-bounds], [CFLAGS="$CFLAGS -fcheck-pointer-bounds"])
else
	dnl If we are not doing debugging disable some of the more annoying warnings
	AX_CHECK_COMPILE_FLAG([-Wno-unused-value], [CFLAGS="$CFLAGS -Wno-unused-value"])
	AX_CHECK_COMPILE_FLAG([-Wno-unused-parameter], [CFLAGS="$CFLAGS -Wno-unused-parameter"])
	AX_CHECK_COMPILE_FLAG([-Wno-deprecated-declarations], [CFLAGS="$CFLAGS -Wno-deprecated-declarations"])
fi

dnl Find "pkg-config" since we need to use it
AC_CHECK_TOOL([PKGCONFIG], [pkg-config], [false])

dnl Determine if we have been asked to use a fast path if possible
tcltls_ssl_fastpath='no'
AC_ARG_ENABLE([ssl-fastpath], AS_HELP_STRING([--enable-ssl-fastpath], [enable using the underlying file descriptor for talking directly to the SSL library]), [
	if test "$enableval" = 'yes'; then
		tcltls_ssl_fastpath='yes'
	else
		tcltls_ssl_fastpath='no'
	fi
])

if test "$tcltls_ssl_fastpath" = 'yes'; then
	AC_DEFINE(TCLTLS_SSL_USE_FASTPATH, [1], [Define this to enable using the underlying file descriptor for talking directly to the SSL library])
fi

dnl Determine if we have been asked to statically link to the SSL library
TCLEXT_TLS_STATIC_SSL='no'
AC_ARG_ENABLE([static-ssl], AS_HELP_STRING([--enable-static-ssl], [enable statically linking to the specified SSL library]), [
	if test "$enableval" = 'yes'; then
		TCLEXT_TLS_STATIC_SSL='yes'
	fi
])

dnl Enable compiler warnings
AX_CHECK_COMPILE_FLAG([-Wall], [CFLAGS="$CFLAGS -Wall"])
AX_CHECK_COMPILE_FLAG([-W], [
	CFLAGS="$CFLAGS -W"
	AX_CHECK_COMPILE_FLAG([-Wno-self-assign], [CFLAGS="$CFLAGS -Wno-self-assign"])
])

dnl Enable hardening
tcltls_enable_hardening='auto'
AC_ARG_ENABLE([hardening], AS_HELP_STRING([--disable-hardening], [disable hardening attempts]), [
	tcltls_enable_hardening="$enableval"
])
if test "$tcltls_enable_hardening" = 'auto'; then
	tcltls_enable_hardening='true'
	if test "$TCLEXT_BUILD" = 'static'; then
		tcltls_enable_hardening='false'
	fi
elif test "$tcltls_enable_hardening" = 'yes'; then
	tcltls_enable_hardening='true'
else
	tcltls_enable_hardening='false'
fi
if test "$tcltls_enable_hardening" = 'true'; then
	AX_CHECK_COMPILE_FLAG([-fstack-protector-all], [CFLAGS="$CFLAGS -fstack-protector-all"])
	AX_CHECK_COMPILE_FLAG([-fno-strict-overflow], [CFLAGS="$CFLAGS -fno-strict-overflow"])
	AC_DEFINE([_FORTIFY_SOURCE], [2], [Enable fortification])
fi

dnl XXX:TODO: Automatically determine the SSL library to use
dnl           defaulting to OpenSSL for compatibility reasons
if test "$tcltls_ssl_lib" = 'auto'; then
	tcltls_ssl_lib='openssl'
fi

AC_MSG_CHECKING([which TLS library to use])
AC_MSG_RESULT([$tcltls_ssl_lib])

dnl Manually rewrite libressl to OpenSSL since we use the
dnl compatibility interface
if test "$tcltls_ssl_lib" = "libressl"; then
	tcltls_ssl_lib='openssl'
fi

AS_CASE([$tcltls_ssl_lib],
	[openssl], [
		TCLTLS_SSL_OPENSSL
	],
	[nss], [
	 	TCLTLS_SSL_LIBS=""
		TCLTLS_SSL_CFLAGS=""
		TCLTLS_SSL_CPPFLAGS=""
	],
	[
		AC_MSG_ERROR([Unsupported SSL library: $tcltls_ssl_lib])
	]
)
dnl Determine how to use this SSL library
AC_MSG_CHECKING([how to use $tcltls_ssl_lib])
LIBS="${TCLTLS_SSL_LIBS} ${LIBS} ${TCLTLS_SSL_LIBS}"
CFLAGS="${TCLTLS_SSL_CFLAGS} ${CFLAGS} ${TCLTLS_SSL_CFLAGS}"
CPPFLAGS="${TCLTLS_SSL_CPPFLAGS} ${CPPFLAGS} ${TCLTLS_SSL_CPPFLAGS}"
AC_MSG_RESULT([$TCLTLS_SSL_CPPFLAGS $TCLTLS_SSL_CFLAGS $TCLTLS_SSL_LIBS])

dnl Sync the RPATH if requested
if test "$TCLEXT_BUILD" != 'static'; then
	if test "$TCLEXT_TLS_STATIC_SSL" = 'yes'; then
		DC_SYNC_RPATH([no])
	else
		DC_SYNC_RPATH([yes])
	fi
fi

dnl Enable a stable ABI
DC_SETUP_STABLE_API([${srcdir}/tcltls.vers], tcltls.syms)
if test "$tcltls_debug" = 'true'; then
	WEAKENSYMS=':'
	REMOVESYMS=':'
fi

dnl Produce output
AC_OUTPUT(Makefile pkgIndex.tcl tcltls.syms)
