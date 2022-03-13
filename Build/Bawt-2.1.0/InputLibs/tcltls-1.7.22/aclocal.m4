dnl Tcl M4 Routines

dnl Find a runnable Tcl
AC_DEFUN([TCLEXT_FIND_TCLSH_PROG], [
	AC_CACHE_CHECK([for runnable tclsh], [tcl_cv_tclsh_native_path], [
		dnl Try to find a runnable tclsh
		if test -z "$TCLCONFIGPATH"; then
			TCLCONFIGPATH=/dev/null/null
		fi

		for try_tclsh in "$TCLSH_NATIVE" "$TCLCONFIGPATH/../bin/tclsh" \
		                 "$TCLCONFIGPATH/../bin/tclsh8.6" \
		                 "$TCLCONFIGPATH/../bin/tclsh8.5" \
		                 "$TCLCONFIGPATH/../bin/tclsh8.4" \
		                 `which tclsh 2>/dev/null` \
		                 `which tclsh8.6 2>/dev/null` \
		                 `which tclsh8.5 2>/dev/null` \
		                 `which tclsh8.4 2>/dev/null` \
		                 tclsh; do
			if test -z "$try_tclsh"; then
				continue
			fi
			if test -x "$try_tclsh"; then
				if echo 'exit 0' | "$try_tclsh" 2>/dev/null >/dev/null; then
					tcl_cv_tclsh_native_path="$try_tclsh"

					break
				fi
			fi
		done

		if test "$TCLCONFIGPATH" = '/dev/null/null'; then
			unset TCLCONFIGPATH
		fi
	])

	TCLSH_PROG="${tcl_cv_tclsh_native_path}"
	AC_SUBST(TCLSH_PROG)
])


dnl Must call AC_CANONICAL_HOST  before calling us
AC_DEFUN([TCLEXT_FIND_TCLCONFIG], [

	TCLCONFIGPATH=""
	AC_ARG_WITH([tcl], AS_HELP_STRING([--with-tcl], [directory containing tcl configuration (tclConfig.sh)]), [
		if test "x$withval" = "xno"; then
			AC_MSG_ERROR([cant build without tcl])
		fi

		TCLCONFIGPATH="$withval"
	], [
		if test "$cross_compiling" = 'no'; then
			TCLEXT_FIND_TCLSH_PROG
			tclConfigCheckDir0="`echo 'puts [[tcl::pkgconfig get libdir,runtime]]' | "$TCLSH_PROG" 2>/dev/null`"
			tclConfigCheckDir1="`echo 'puts [[tcl::pkgconfig get scriptdir,runtime]]' | "$TCLSH_PROG" 2>/dev/null`"
		else
			tclConfigCheckDir0=/dev/null/null
			tclConfigCheckDir1=/dev/null/null
		fi

		if test "$cross_compiling" = 'no'; then
			dirs="/usr/$host_alias/lib /usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64"
		else
			dirs=''
		fi

		for dir in "$tclConfigCheckDir0" "$tclConfigCheckDir1" $dirs; do
			if test -f "$dir/tclConfig.sh"; then
				TCLCONFIGPATH="$dir"

				break
			fi
		done
	])

	AC_MSG_CHECKING([for path to tclConfig.sh])

	if test -z "$TCLCONFIGPATH"; then
		AC_MSG_ERROR([unable to locate tclConfig.sh.  Try --with-tcl.])
	fi

	AC_SUBST(TCLCONFIGPATH)

	AC_MSG_RESULT([$TCLCONFIGPATH])

	dnl Find Tcl if we haven't already
	if test -z "$TCLSH_PROG"; then
		TCLEXT_FIND_TCLSH_PROG
	fi
])

dnl Must define TCLCONFIGPATH before calling us (i.e., by TCLEXT_FIND_TCLCONFIG)
AC_DEFUN([TCLEXT_LOAD_TCLCONFIG], [
	AC_MSG_CHECKING([for working tclConfig.sh])

	if test -f "$TCLCONFIGPATH/tclConfig.sh"; then
		. "$TCLCONFIGPATH/tclConfig.sh"
	else
		AC_MSG_ERROR([unable to load tclConfig.sh])
	fi


	AC_MSG_RESULT([found])
])

AC_DEFUN([TCLEXT_INIT], [
	AC_CANONICAL_HOST

	TCLEXT_FIND_TCLCONFIG
	TCLEXT_LOAD_TCLCONFIG

	AC_DEFINE_UNQUOTED([MODULE_SCOPE], [static], [Define how to declare a function should only be visible to the current module])

	TCLEXT_BUILD='shared'
	AC_ARG_ENABLE([shared], AS_HELP_STRING([--disable-shared], [disable the shared build (same as --enable-static)]), [
		if test "$enableval" = "no"; then
			TCLEXT_BUILD='static'
			TCL_SUPPORTS_STUBS=0
		fi
	])

	AC_ARG_ENABLE([static], AS_HELP_STRING([--enable-static], [enable a static build]), [
		if test "$enableval" = "yes"; then
			TCLEXT_BUILD='static'
			TCL_SUPPORTS_STUBS=0
		fi
	])

	AC_ARG_ENABLE([stubs], AS_HELP_STRING([--disable-stubs], [disable use of Tcl stubs]), [
		if test "$enableval" = "no"; then
			TCL_SUPPORTS_STUBS=0
		else
			TCL_SUPPORTS_STUBS=1
		fi
	])

	if test "$TCL_SUPPORTS_STUBS" = "1"; then
		AC_DEFINE([USE_TCL_STUBS], [1], [Define if you are using the Tcl Stubs Mechanism])

		TCL_STUB_LIB_SPEC="`eval echo "${TCL_STUB_LIB_SPEC}"`"
		LIBS="${LIBS} ${TCL_STUB_LIB_SPEC}"
	else
		TCL_LIB_SPEC="`eval echo "${TCL_LIB_SPEC}"`"
		LIBS="${LIBS} ${TCL_LIB_SPEC}"
	fi

	TCL_INCLUDE_SPEC="`eval echo "${TCL_INCLUDE_SPEC}"`"

	CFLAGS="${CFLAGS} ${TCL_INCLUDE_SPEC}"
	CPPFLAGS="${CPPFLAGS} ${TCL_INCLUDE_SPEC}"
	TCL_DEFS_TCL_ONLY=`(
		eval "set -- ${TCL_DEFS}"
		for flag in "[$]@"; do
			case "${flag}" in
				-DTCL_*)
					echo "${flag}" | sed "s/'/'\\''/g" | sed "s@^@'@;s@"'[$]'"@'@" | tr $'\n' ' '
					;;
			esac
		done
	)`
	TCL_DEFS="${TCL_DEFS_TCL_ONLY}"
	AC_SUBST(TCL_DEFS)

	dnl Needed for package installation
	if test "$prefix" = 'NONE' -a "$exec_prefix" = 'NONE' -a "${libdir}" = '${exec_prefix}/lib'; then
		TCL_PACKAGE_PATH="`echo "${TCL_PACKAGE_PATH}" | sed 's@  *$''@@' | awk '{ print [$]1 }'`"
	else
		TCL_PACKAGE_PATH='${libdir}'
	fi
	AC_SUBST(TCL_PACKAGE_PATH)

	AC_SUBST(LIBS)
])
dnl Usage:
dnl    DC_TEST_SHOBJFLAGS(shobjflags, shobjldflags, action-if-not-found)
dnl
AC_DEFUN([DC_TEST_SHOBJFLAGS], [
  AC_SUBST(SHOBJFLAGS)
  AC_SUBST(SHOBJCPPFLAGS)
  AC_SUBST(SHOBJLDFLAGS)

  OLD_LDFLAGS="$LDFLAGS"
  OLD_CFLAGS="$CFLAGS"
  OLD_CPPFLAGS="$CPPFLAGS"

  SHOBJFLAGS=""
  SHOBJCPPFLAGS=""
  SHOBJLDFLAGS=""

  CFLAGS="$OLD_CFLAGS $1"
  CPPFLAGS="$OLD_CPPFLAGS $2"
  LDFLAGS="$OLD_LDFLAGS $3"

  AC_TRY_LINK([#include <stdio.h>
int unrestst(void);], [ printf("okay\n"); unrestst(); return(0); ], [ SHOBJFLAGS="$1"; SHOBJCPPFLAGS="$2"; SHOBJLDFLAGS="$3" ], [
    LDFLAGS="$OLD_LDFLAGS"
    CFLAGS="$OLD_CFLAGS"
    CPPFLAGS="$OLD_CPPFLAGS"
    $4
  ])

  LDFLAGS="$OLD_LDFLAGS"
  CFLAGS="$OLD_CFLAGS"
  CPPFLAGS="$OLD_CPPFLAGS"
])

AC_DEFUN([DC_GET_SHOBJFLAGS], [
  AC_SUBST(SHOBJFLAGS)
  AC_SUBST(SHOBJCPPFLAGS)
  AC_SUBST(SHOBJLDFLAGS)

  DC_CHK_OS_INFO

  AC_MSG_CHECKING(how to create shared objects)

  if test -z "$SHOBJFLAGS" -a -z "$SHOBJLDFLAGS" -a -z "$SHOBJCPPFLAGS"; then
    DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-shared], [
      DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-shared -mimpure-text], [
        DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-shared -rdynamic -Wl,-G,-z,textoff], [
          DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-shared -Wl,-G], [
            DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-shared -dynamiclib -flat_namespace -undefined suppress -bind_at_load], [
              DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-dynamiclib -flat_namespace -undefined suppress -bind_at_load], [
                DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-Wl,-dynamiclib -Wl,-flat_namespace -Wl,-undefined,suppress -Wl,-bind_at_load], [
                  DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-dynamiclib -flat_namespace -undefined suppress], [
                    DC_TEST_SHOBJFLAGS([-fPIC], [-DPIC], [-dynamiclib], [
                      AC_MSG_RESULT(cant)
                      AC_MSG_ERROR([We are unable to make shared objects.])
                    ])
                  ])
                ])
              ])
            ])
          ])
        ])
      ])
    ])
  fi

  AC_MSG_RESULT($SHOBJCPPFLAGS $SHOBJFLAGS $SHOBJLDFLAGS)

  DC_SYNC_SHLIBOBJS
])

AC_DEFUN([DC_SYNC_SHLIBOBJS], [
  AC_SUBST(SHLIBOBJS)
  SHLIBOBJS=""
  for obj in $LIB@&t@OBJS; do
    SHLIBOBJS="$SHLIBOBJS `echo $obj | sed 's/\.o$/_shr.o/g'`"
  done
])

AC_DEFUN([DC_SYNC_RPATH], [
	AC_ARG_ENABLE([rpath], AS_HELP_STRING([--disable-rpath], [disable setting of rpath]), [
		if test "$enableval" = 'no'; then
			set_rpath='no'
		else
			set_rpath='yes'
		fi
	], [
		if test "$cross_compiling" = 'yes'; then
			set_rpath='no'
		else
			ifelse($1, [], [
				set_rpath='yes'
			], [
				set_rpath='$1'
			])
		fi
	])

	if test "$set_rpath" = 'yes'; then
		OLD_LDFLAGS="$LDFLAGS"

		AC_CACHE_CHECK([how to set rpath], [rsk_cv_link_set_rpath], [
			AC_LANG_PUSH(C)
			for tryrpath in "-Wl,-rpath" "-Wl,--rpath" "-Wl,-R"; do
				LDFLAGS="$OLD_LDFLAGS $tryrpath -Wl,/tmp"
				AC_LINK_IFELSE([AC_LANG_PROGRAM([], [ return(0); ])], [
					rsk_cv_link_set_rpath="$tryrpath"
					break
				])
			done
			AC_LANG_POP(C)
			unset tryrpath
		])

		LDFLAGS="$OLD_LDFLAGS"
		unset OLD_LDFLAGS

		if test -n "$rsk_cv_link_set_rpath"; then
			ADDLDFLAGS=""
			for opt in $LDFLAGS $LIBS; do
				if echo "$opt" | grep '^-L' >/dev/null; then
					rpathdir="`echo "$opt" | sed 's@^-L *@@'`"
					ADDLDFLAGS="$ADDLDFLAGS $rsk_cv_link_set_rpath -Wl,$rpathdir"
				fi
			done
			unset opt

			LDFLAGS="$LDFLAGS $ADDLDFLAGS"

			unset ADDLDFLAGS
		fi
	fi
])

AC_DEFUN([DC_CHK_OS_INFO], [
	AC_CANONICAL_HOST
	AC_SUBST(SHOBJEXT)
	AC_SUBST(SHOBJFLAGS)
	AC_SUBST(SHOBJCPPFLAGS)
	AC_SUBST(SHOBJLDFLAGS)
	AC_SUBST(CFLAGS)
	AC_SUBST(CPPFLAGS)
	AC_SUBST(AREXT)

	if test "$dc_cv_dc_chk_os_info_called" != '1'; then
		dc_cv_dc_chk_os_info_called='1'

		AC_MSG_CHECKING(host operating system)
		AC_MSG_RESULT($host_os)

		SHOBJEXT="so"
		AREXT="a"

		case $host_os in
			darwin*)
				SHOBJEXT="dylib"
				;;
			hpux*)
				case "$host_cpu" in
					ia64)
						SHOBJEXT="so"
						;;
					*)
						SHOBJEXT="sl"
						;;
				esac
				;;
			mingw32|mingw32msvc*)
				SHOBJEXT="dll"
				CFLAGS="$CFLAGS -mms-bitfields"
				CPPFLAGS="$CPPFLAGS -mms-bitfields"
				SHOBJCPPFLAGS="-DPIC"
				SHOBJLDFLAGS='-shared -Wl,--dll -Wl,--enable-auto-image-base -Wl,--output-def,$[@].def,--out-implib,$[@].a'
				;;
			msvc)
				SHOBJEXT="dll"
				AREXT='lib'
				CFLAGS="$CFLAGS -nologo"
				SHOBJCPPFLAGS='-DPIC'
				SHOBJLDFLAGS='/LD /LINK /NODEFAULTLIB:MSVCRT'
				;;
			cygwin*)
				SHOBJEXT="dll"
				SHOBJFLAGS="-fPIC"
				SHOBJCPPFLAGS="-DPIC"
				CFLAGS="$CFLAGS -mms-bitfields"
				CPPFLAGS="$CPPFLAGS -mms-bitfields"
				SHOBJLDFLAGS='-shared -Wl,--enable-auto-image-base -Wl,--output-def,$[@].def,--out-implib,$[@].a'
				;;
		esac
	fi
])

AC_DEFUN([SHOBJ_SET_SONAME], [
	SAVE_LDFLAGS="$LDFLAGS"

	AC_MSG_CHECKING([how to specify soname])

	for try in "-Wl,--soname,$1" "Wl,-install_name,$1" '__fail__'; do
		LDFLAGS="$SAVE_LDFLAGS"

		if test "${try}" = '__fail__'; then
			AC_MSG_RESULT([can't])

			break
		fi

		LDFLAGS="${LDFLAGS} ${try}"
		AC_TRY_LINK([void TestTest(void) { return; }], [], [
			LDFLAGS="${SAVE_LDFLAGS}"
			SHOBJLDFLAGS="${SHOBJLDFLAGS} ${try}"

			AC_MSG_RESULT([$try])

			break
		])
	done

	AC_SUBST(SHOBJLDFLAGS)
])

dnl $1 = Description to show user
dnl $2 = Libraries to link to
dnl $3 = Variable to update (optional; default LIBS)
dnl $4 = Action to run if found
dnl $5 = Action to run if not found
AC_DEFUN([SHOBJ_DO_STATIC_LINK_LIB], [
        ifelse($3, [], [
                define([VAR_TO_UPDATE], [LIBS])
        ], [
                define([VAR_TO_UPDATE], [$3])
        ])  


	AC_MSG_CHECKING([for how to statically link to $1])

	trylink_ADD_LDFLAGS=''
	for arg in $VAR_TO_UPDATE; do
		case "${arg}" in
			-L*)
				trylink_ADD_LDFLAGS="${arg}"
				;;
		esac
	done

	SAVELIBS="$LIBS"
	staticlib=""
	found="0"
	dnl HP/UX uses -Wl,-a,archive ... -Wl,-a,shared_archive
	dnl Linux and Solaris us -Wl,-Bstatic ... -Wl,-Bdynamic
	AC_LANG_PUSH([C])
	for trylink in "-Wl,-a,archive $2 -Wl,-a,shared_archive" "-Wl,-Bstatic $2 -Wl,-Bdynamic" "$2"; do
		if echo " ${LDFLAGS} " | grep ' -static ' >/dev/null; then
			if test "${trylink}" != "$2"; then
				continue
			fi
		fi

		LIBS="${SAVELIBS} ${trylink_ADD_LDFLAGS} ${trylink}"

		AC_LINK_IFELSE([AC_LANG_PROGRAM([], [])], [
			staticlib="${trylink}"
			found="1"

			break
		])
	done
	AC_LANG_POP([C])
	LIBS="${SAVELIBS}"

	if test "${found}" = "1"; then
		new_RESULT=''
		SAVERESULT="$VAR_TO_UPDATE"
		for lib in ${SAVERESULT}; do
			addlib='1'
			for removelib in $2; do
				if test "${lib}" = "${removelib}"; then
					addlib='0'
					break
				fi
			done

			if test "$addlib" = '1'; then
				new_RESULT="${new_RESULT} ${lib}"
			fi
		done
		VAR_TO_UPDATE="${new_RESULT} ${staticlib}"

		AC_MSG_RESULT([${staticlib}])

		$4
	else
		AC_MSG_RESULT([cant])

		$5
	fi
])

AC_DEFUN([DC_SETUP_STABLE_API], [
	VERSIONSCRIPT="$1"
	SYMFILE="$2"

	DC_FIND_STRIP_AND_REMOVESYMS([$SYMFILE])
	DC_SETVERSIONSCRIPT([$VERSIONSCRIPT], [$SYMFILE])
])


AC_DEFUN([DC_SETVERSIONSCRIPT], [
	VERSIONSCRIPT="$1"
	SYMFILE="$2"
	TMPSYMFILE="${SYMFILE}.tmp"
	TMPVERSIONSCRIPT="${VERSIONSCRIPT}.tmp"

	echo "${SYMPREFIX}Test_Symbol" > "${TMPSYMFILE}"

	echo '{' > "${TMPVERSIONSCRIPT}"
	echo '	local:' >> "${TMPVERSIONSCRIPT}"
	echo "		${SYMPREFIX}Test_Symbol;" >> "${TMPVERSIONSCRIPT}"
	echo '};' >> "${TMPVERSIONSCRIPT}"

	SAVE_LDFLAGS="${LDFLAGS}"

	AC_MSG_CHECKING([for how to set version script])

	for tryaddldflags in "-Wl,--version-script,${TMPVERSIONSCRIPT}" "-Wl,-exported_symbols_list,${TMPSYMFILE}"; do
		LDFLAGS="${SAVE_LDFLAGS} ${tryaddldflags}"
		AC_TRY_LINK([void Test_Symbol(void) { return; }], [], [
			addldflags="`echo "${tryaddldflags}" | sed 's/\.tmp$//'`"

			break
		])
	done

	rm -f "${TMPSYMFILE}"
	rm -f "${TMPVERSIONSCRIPT}"

	LDFLAGS="${SAVE_LDFLAGS}"

	if test -n "${addldflags}"; then
		SHOBJLDFLAGS="${SHOBJLDFLAGS} ${addldflags}"

		AC_MSG_RESULT($addldflags)
	else
		AC_MSG_RESULT([don't know])
	fi

	AC_SUBST(SHOBJLDFLAGS)
])

AC_DEFUN([DC_FIND_STRIP_AND_REMOVESYMS], [
	SYMFILE="$1"

	dnl Determine how to strip executables
	AC_CHECK_TOOLS(OBJCOPY, objcopy gobjcopy, [false])
	AC_CHECK_TOOLS(STRIP, strip gstrip, [false])

	if test "x${STRIP}" = "xfalse"; then
		STRIP="${OBJCOPY}"
	fi

	WEAKENSYMS='true'
	REMOVESYMS='true'
	SYMPREFIX=''

	case $host_os in
		darwin*)
			SYMPREFIX="_"
			REMOVESYMS="${STRIP} -u -x"
			;;
		*)
			if test "x${OBJCOPY}" != "xfalse"; then
				WEAKENSYMS="${OBJCOPY} --keep-global-symbols=${SYMFILE}"
				REMOVESYMS="${OBJCOPY} --discard-all"
			elif test "x${STRIP}" != "xfalse"; then
				REMOVESYMS="${STRIP} -x"
			fi
			;;
	esac

	AC_SUBST(WEAKENSYMS)
	AC_SUBST(REMOVESYMS)
	AC_SUBST(SYMPREFIX)
])
# ===========================================================================
#  https://www.gnu.org/software/autoconf-archive/ax_check_compile_flag.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_CHECK_COMPILE_FLAG(FLAG, [ACTION-SUCCESS], [ACTION-FAILURE], [EXTRA-FLAGS], [INPUT])
#
# DESCRIPTION
#
#   Check whether the given FLAG works with the current language's compiler
#   or gives an error.  (Warnings, however, are ignored)
#
#   ACTION-SUCCESS/ACTION-FAILURE are shell commands to execute on
#   success/failure.
#
#   If EXTRA-FLAGS is defined, it is added to the current language's default
#   flags (e.g. CFLAGS) when the check is done.  The check is thus made with
#   the flags: "CFLAGS EXTRA-FLAGS FLAG".  This can for example be used to
#   force the compiler to issue an error when a bad flag is given.
#
#   INPUT gives an alternative input source to AC_LINK_IFELSE.
#
#   NOTE: Implementation based on AX_CFLAGS_GCC_OPTION. Please keep this
#   macro in sync with AX_CHECK_{PREPROC,LINK}_FLAG.
#
# LICENSE
#
#   Copyright (c) 2008 Guido U. Draheim <guidod@gmx.de>
#   Copyright (c) 2011 Maarten Bosmans <mkbosmans@gmail.com>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved.  This file is offered as-is, without any
#   warranty.

#serial 6

AC_DEFUN([AX_CHECK_COMPILE_FLAG],
[AC_PREREQ(2.64)dnl for _AC_LANG_PREFIX and AS_VAR_IF
AS_VAR_PUSHDEF([CACHEVAR],[ax_cv_check_[]_AC_LANG_ABBREV[]flags_$4_$1])dnl
AC_CACHE_CHECK([whether _AC_LANG compiler accepts $1], CACHEVAR, [
  ax_check_save_flags=$[]_AC_LANG_PREFIX[]FLAGS
  _AC_LANG_PREFIX[]FLAGS="$[]_AC_LANG_PREFIX[]FLAGS $4 $1"
  AC_LINK_IFELSE([m4_default([$5],[AC_LANG_PROGRAM()])],
    [AS_VAR_SET(CACHEVAR,[yes])],
    [AS_VAR_SET(CACHEVAR,[no])])
  _AC_LANG_PREFIX[]FLAGS=$ax_check_save_flags])
AS_VAR_IF(CACHEVAR,yes,
  [m4_default([$2], :)],
  [m4_default([$3], :)])
AS_VAR_POPDEF([CACHEVAR])dnl
])dnl AX_CHECK_COMPILE_FLAGS
dnl $1 = Name of variable
dnl $2 = Name of function to check for
dnl $3 = Name of protocol
dnl $4 = Name of CPP macro to define
dnl $5 = Name of CPP macro to check for instead of a function
AC_DEFUN([TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER], [
	dnl Determine if particular SSL version is enabled
	if test "[$]$1" = "true" -o "[$]$1" = "force"; then
		proto_check='true'
		ifelse($5,, [
			AC_CHECK_FUNC($2,, [
				proto_check='false'
			])
		], [
			AC_LANG_PUSH(C)
			AC_MSG_CHECKING([for $3 protocol support])
			AC_COMPILE_IFELSE([AC_LANG_PROGRAM([
#include <openssl/ssl.h>
#include <openssl/opensslv.h>
#if (SSLEAY_VERSION_NUMBER >= 0x0907000L)
# include <openssl/conf.h>
#endif
			], [
int x = $5;
			])], [
				AC_MSG_RESULT([yes])
			], [
				AC_MSG_RESULT([no])

				proto_check='false'
			])
			AC_LANG_POP([C])
		])

		if test "$proto_check" = 'false'; then
			if test "[$]$1" = "force"; then
				AC_MSG_ERROR([Unable to enable $3])
			fi

			$1='false'
		fi
	fi

	if test "[$]$1" = "false"; then
		AC_DEFINE($4, [1], [Define this to disable $3 in OpenSSL support])
	fi

])

AC_DEFUN([TCLTLS_SSL_OPENSSL], [
	openssldir=''
	opensslpkgconfigdir=''
	AC_ARG_WITH([ssl-dir],
		AS_HELP_STRING(
			[--with-ssl-dir=<dir>],
			[deprecated, use --with-openssl-dir -- currently has the same meaning]
		), [
			openssldir="$withval"
		]
	)
	AC_ARG_WITH([openssl-dir],
		AS_HELP_STRING(
			[--with-openssl-dir=<dir>],
			[path to root directory of OpenSSL or LibreSSL installation]
		), [
			openssldir="$withval"
		]
	)
	AC_ARG_WITH([openssl-pkgconfig],
		AS_HELP_STRING(
			[--with-openssl-pkgconfig=<dir>],
			[path to root directory of OpenSSL or LibreSSL pkgconfigdir]
		), [
			opensslpkgconfigdir="$withval"
		]
	)

	if test -n "$openssldir"; then
		if test -e "$openssldir/libssl.$SHOBJEXT"; then
			TCLTLS_SSL_LIBS="-L$openssldir -lssl -lcrypto"
			openssldir="`AS_DIRNAME(["$openssldir"])`"
		else
			TCLTLS_SSL_LIBS="-L$openssldir/lib -lssl -lcrypto"
		fi
		TCLTLS_SSL_CFLAGS="-I$openssldir/include"
		TCLTLS_SSL_CPPFLAGS="-I$openssldir/include"
	fi

	pkgConfigExtraArgs=''
	if test "$TCLEXT_BUILD" = "static" -o "$TCLEXT_TLS_STATIC_SSL" = 'yes'; then
		pkgConfigExtraArgs='--static'
	fi

	dnl Use pkg-config to find the libraries
	dnl Temporarily update PKG_CONFIG_PATH
	PKG_CONFIG_PATH_SAVE="${PKG_CONFIG_PATH}"
	if test -n "${opensslpkgconfigdir}"; then
		if ! test -f "${opensslpkgconfigdir}/openssl.pc"; then
			AC_MSG_ERROR([Unable to locate ${opensslpkgconfigdir}/openssl.pc])
		fi

		PKG_CONFIG_PATH="${opensslpkgconfigdir}${PATH_SEPARATOR}${PKG_CONFIG_PATH}"
		export PKG_CONFIG_PATH
	fi

	AC_ARG_VAR([TCLTLS_SSL_LIBS], [libraries to pass to the linker for OpenSSL or LibreSSL])
	AC_ARG_VAR([TCLTLS_SSL_CFLAGS], [C compiler flags for OpenSSL or LibreSSL])
	AC_ARG_VAR([TCLTLS_SSL_CPPFLAGS], [C preprocessor flags for OpenSSL or LibreSSL])
	if test -z "$TCLTLS_SSL_LIBS"; then
		TCLTLS_SSL_LIBS="`"${PKGCONFIG}" openssl --libs $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])
	fi
	if test -z "$TCLTLS_SSL_CFLAGS"; then
		TCLTLS_SSL_CFLAGS="`"${PKGCONFIG}" openssl --cflags-only-other $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])
	fi
	if test -z "$TCLTLS_SSL_CPPFLAGS"; then
		TCLTLS_SSL_CPPFLAGS="`"${PKGCONFIG}" openssl --cflags-only-I $pkgConfigExtraArgs`" || AC_MSG_ERROR([Unable to get OpenSSL Configuration])
	fi
	PKG_CONFIG_PATH="${PKG_CONFIG_PATH_SAVE}"

	if test "$TCLEXT_BUILD" = "static"; then
		dnl If we are doing a static build, save the linker flags for other programs to consume
		rm -f tcltls.${AREXT}.linkadd
		AS_ECHO(["$TCLTLS_SSL_LIBS"]) > tcltls.${AREXT}.linkadd
	fi

	dnl If we have been asked to statically link to the SSL library, specifically tell the linker to do so
	if test "$TCLEXT_TLS_STATIC_SSL" = 'yes'; then
		dnl Don't bother doing this if we aren't actually doing the runtime linking
		if test "$TCLEXT_BUILD" != "static"; then
			dnl Split the libraries into SSL and non-SSL libraries
			new_TCLTLS_SSL_LIBS_normal=''
			new_TCLTLS_SSL_LIBS_static=''
			for arg in $TCLTLS_SSL_LIBS; do
				case "${arg}" in
					-L*)
						new_TCLTLS_SSL_LIBS_normal="${new_TCLTLS_SSL_LIBS_normal} ${arg}"
						new_TCLTLS_SSL_LIBS_static="${new_TCLTLS_SSL_LIBS_static} ${arg}"
						;;
					-ldl|-lrt|-lc|-lpthread|-lm|-lcrypt|-lidn|-lresolv|-lgcc|-lgcc_s)
						new_TCLTLS_SSL_LIBS_normal="${new_TCLTLS_SSL_LIBS_normal} ${arg}"
						;;
					-l*)
						new_TCLTLS_SSL_LIBS_static="${new_TCLTLS_SSL_LIBS_static} ${arg}"
						;;
					*)
						new_TCLTLS_SSL_LIBS_normal="${new_TCLTLS_SSL_LIBS_normal} ${arg}"
						;;
				esac
			done
			SHOBJ_DO_STATIC_LINK_LIB([OpenSSL], [$new_TCLTLS_SSL_LIBS_static], [new_TCLTLS_SSL_LIBS_static])
			TCLTLS_SSL_LIBS="${new_TCLTLS_SSL_LIBS_normal} ${new_TCLTLS_SSL_LIBS_static}"
		fi
	fi

	dnl Save compile-altering variables we are changing
	SAVE_LIBS="${LIBS}"
	SAVE_CFLAGS="${CFLAGS}"
	SAVE_CPPFLAGS="${CPPFLAGS}"

	dnl Update compile-altering variables to include the OpenSSL libraries
	LIBS="${TCLTLS_SSL_LIBS} ${SAVE_LIBS} ${TCLTLS_SSL_LIBS}"
	CFLAGS="${TCLTLS_SSL_CFLAGS} ${SAVE_CFLAGS} ${TCLTLS_SSL_CFLAGS}"
	CPPFLAGS="${TCLTLS_SSL_CPPFLAGS} ${SAVE_CPPFLAGS} ${TCLTLS_SSL_CPPFLAGS}"

	dnl Verify that basic functionality is there
	AC_LANG_PUSH(C)
	AC_MSG_CHECKING([if a basic OpenSSL program works])
	AC_LINK_IFELSE([AC_LANG_PROGRAM([
#include <openssl/ssl.h>
#include <openssl/opensslv.h>
#if (SSLEAY_VERSION_NUMBER >= 0x0907000L)
# include <openssl/conf.h>
#endif
		], [
  SSL_library_init();
  SSL_load_error_strings();
		])], [
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
		AC_MSG_ERROR([Unable to compile a basic program using OpenSSL])
	])
	AC_LANG_POP([C])

	AC_CHECK_FUNCS([TLS_method])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_ssl2], [SSLv2_method], [sslv2], [NO_SSL2])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_ssl3], [SSLv3_method], [sslv3], [NO_SSL3])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_tls1_0], [TLSv1_method], [tlsv1.0], [NO_TLS1])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_tls1_1], [TLSv1_1_method], [tlsv1.1], [NO_TLS1_1])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_tls1_2], [TLSv1_2_method], [tlsv1.2], [NO_TLS1_2])
	TCLTLS_SSL_OPENSSL_CHECK_PROTO_VER([tcltls_ssl_tls1_3], [], [tlsv1.3], [NO_TLS1_3], [SSL_OP_NO_TLSv1_3])

	AC_CACHE_VAL([tcltls_cv_func_tlsext_hostname], [
		AC_LANG_PUSH(C)
		AC_MSG_CHECKING([for SSL_set_tlsext_host_name])
		AC_LINK_IFELSE([AC_LANG_PROGRAM([
#include <openssl/ssl.h>
#if (SSLEAY_VERSION_NUMBER >= 0x0907000L)
# include <openssl/conf.h>
#endif
			], [
  (void)SSL_set_tlsext_host_name((void *) 0, (void *) 0);
			])], [
			AC_MSG_RESULT([yes])
			tcltls_cv_func_tlsext_hostname='yes'
		], [
			AC_MSG_RESULT([no])
			tcltls_cv_func_tlsext_hostname='no'
		])
		AC_LANG_POP([C])
	])

	if test "$tcltls_cv_func_tlsext_hostname" = 'no'; then
		AC_DEFINE([OPENSSL_NO_TLSEXT], [1], [Define this if your OpenSSL does not support the TLS Extension for SNI])
	fi

	dnl Restore compile-altering variables
	LIBS="${SAVE_LIBS}"
	CFLAGS="${SAVE_CFLAGS}"
	CPPFLAGS="${SAVE_CPPFLAGS}"
])
