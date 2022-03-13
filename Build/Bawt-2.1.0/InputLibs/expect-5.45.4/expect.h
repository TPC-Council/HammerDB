/* expect.h - include file for using the expect library, libexpect.a
from C or C++ (i.e., without Tcl)

Written by: Don Libes, libes@cme.nist.gov, NIST, 12/3/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#ifndef _EXPECT_H
#define _EXPECT_H

#include <stdio.h>
#include <setjmp.h>

/*
 * tcl.h --
 *
 *	This header file describes the externally-visible facilities
 *	of the Tcl interpreter.
 *
 * Copyright (c) 1987-1994 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright (c) 1993-1996 Lucent Technologies.
 * Copyright (c) 1998-1999 Scriptics Corporation.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: expect.h,v 5.32 2010/07/01 00:53:49 eee Exp $
 */

#ifndef _TCL
#define _TCL

#ifndef __WIN32__
#   if defined(_WIN32) || defined(WIN32)
#	define __WIN32__
#   endif
#endif

#ifdef __WIN32__
#   ifndef STRICT
#	define STRICT
#   endif
#   ifndef USE_PROTOTYPE
#	define USE_PROTOTYPE 1
#   endif
#   ifndef HAS_STDARG
#	define HAS_STDARG 1
#   endif
#   ifndef USE_PROTOTYPE
#	define USE_PROTOTYPE 1
#   endif

/*
 * Under Windows we need to call Tcl_Alloc in all cases to avoid competing
 * C run-time library issues.
 */

#   ifndef USE_TCLALLOC
#	define USE_TCLALLOC 1
#   endif
#endif /* __WIN32__ */

/*
 * The following definitions set up the proper options for Macintosh
 * compilers.  We use this method because there is no autoconf equivalent.
 */

#ifdef MAC_TCL
#   ifndef HAS_STDARG
#	define HAS_STDARG 1
#   endif
#   ifndef USE_TCLALLOC
#	define USE_TCLALLOC 1
#   endif
#   ifndef NO_STRERROR
#	define NO_STRERROR 1
#   endif
#endif

/*
 * Utility macros: STRINGIFY takes an argument and wraps it in "" (double
 * quotation marks), JOIN joins two arguments.
 */

#define VERBATIM(x) x
#ifdef _MSC_VER
# define STRINGIFY(x) STRINGIFY1(x)
# define STRINGIFY1(x) #x
# define JOIN(a,b) JOIN1(a,b)
# define JOIN1(a,b) a##b
#else
# ifdef RESOURCE_INCLUDED
#  define STRINGIFY(x) STRINGIFY1(x)
#  define STRINGIFY1(x) #x
#  define JOIN(a,b) JOIN1(a,b)
#  define JOIN1(a,b) a##b
# else
#  ifdef __STDC__
#   define STRINGIFY(x) #x
#   define JOIN(a,b) a##b
#  else
#   define STRINGIFY(x) "x"
#   define JOIN(a,b) VERBATIM(a)VERBATIM(b)
#  endif
# endif
#endif

/* 
 * A special definition used to allow this header file to be included 
 * in resource files so that they can get obtain version information from
 * this file.  Resource compilers don't like all the C stuff, like typedefs
 * and procedure declarations, that occur below.
 */

#ifndef RESOURCE_INCLUDED

#ifndef BUFSIZ
#include <stdio.h>
#endif

/*
 * Definitions that allow Tcl functions with variable numbers of
 * arguments to be used with either varargs.h or stdarg.h.  TCL_VARARGS
 * is used in procedure prototypes.  TCL_VARARGS_DEF is used to declare
 * the arguments in a function definiton: it takes the type and name of
 * the first argument and supplies the appropriate argument declaration
 * string for use in the function definition.  TCL_VARARGS_START
 * initializes the va_list data structure and returns the first argument.
 */

#if defined(__STDC__) || defined(HAS_STDARG)
#   include <stdarg.h>

#   define TCL_VARARGS(type, name) (type name, ...)
#   define TCL_VARARGS_DEF(type, name) (type name, ...)
#   define TCL_VARARGS_START(type, name, list) (va_start(list, name), name)
#else
#   include <varargs.h>

#   ifdef __cplusplus
#	define TCL_VARARGS(type, name) (type name, ...)
#	define TCL_VARARGS_DEF(type, name) (type va_alist, ...)
#   else
#	define TCL_VARARGS(type, name) ()
#	define TCL_VARARGS_DEF(type, name) (va_alist)
#   endif
#   define TCL_VARARGS_START(type, name, list) \
	(va_start(list), va_arg(list, type))
#endif

/*
 * Macros used to declare a function to be exported by a DLL.
 * Used by Windows, maps to no-op declarations on non-Windows systems.
 * The default build on windows is for a DLL, which causes the DLLIMPORT
 * and DLLEXPORT macros to be nonempty. To build a static library, the
 * macro STATIC_BUILD should be defined.
 */

#ifdef STATIC_BUILD
# define DLLIMPORT
# define DLLEXPORT
#else
# if defined(__WIN32__) && (defined(_MSC_VER) || (defined(__GNUC__) && defined(__declspec)))
#   define DLLIMPORT __declspec(dllimport)
#   define DLLEXPORT __declspec(dllexport)
# else
#  define DLLIMPORT
#  define DLLEXPORT
# endif
#endif

/*
 * These macros are used to control whether functions are being declared for
 * import or export.  If a function is being declared while it is being built
 * to be included in a shared library, then it should have the DLLEXPORT
 * storage class.  If is being declared for use by a module that is going to
 * link against the shared library, then it should have the DLLIMPORT storage
 * class.  If the symbol is beind declared for a static build or for use from a
 * stub library, then the storage class should be empty.
 *
 * The convention is that a macro called BUILD_xxxx, where xxxx is the
 * name of a library we are building, is set on the compile line for sources
 * that are to be placed in the library.  When this macro is set, the
 * storage class will be set to DLLEXPORT.  At the end of the header file, the
 * storage class will be reset to DLLIMPORt.
 */

#undef TCL_STORAGE_CLASS
#ifdef BUILD_tcl
# define TCL_STORAGE_CLASS DLLEXPORT
#else
# ifdef USE_TCL_STUBS
#  define TCL_STORAGE_CLASS
# else
#  define TCL_STORAGE_CLASS DLLIMPORT
# endif
#endif

/*
 * Definitions that allow this header file to be used either with or
 * without ANSI C features like function prototypes.  */

#undef _ANSI_ARGS_
#undef CONST

#if ((defined(__STDC__) || defined(SABER)) && !defined(NO_PROTOTYPE)) || defined(__cplusplus) || defined(USE_PROTOTYPE)
#   define _USING_PROTOTYPES_ 1
#   define _ANSI_ARGS_(x)	x
#   define CONST const
#else
#   define _ANSI_ARGS_(x)	()
#   define CONST
#endif

#ifdef __cplusplus
#   define EXTERN extern "C" TCL_STORAGE_CLASS
#else
#   define EXTERN extern TCL_STORAGE_CLASS
#endif

/*
 * Macro to use instead of "void" for arguments that must have
 * type "void *" in ANSI C;  maps them to type "char *" in
 * non-ANSI systems.
 */
#ifndef __WIN32__
#ifndef VOID
#   ifdef __STDC__
#       define VOID void
#   else
#       define VOID char
#   endif
#endif
#else /* __WIN32__ */
/*
 * The following code is copied from winnt.h
 */
#ifndef VOID
#define VOID void
typedef char CHAR;
typedef short SHORT;
typedef long LONG;
#endif
#endif /* __WIN32__ */

/*
 * Miscellaneous declarations.
 */

#ifndef NULL
#define NULL 0
#endif

typedef struct Tcl_RegExp_ *Tcl_RegExp;

/*
 * These function have been renamed. The old names are deprecated, but we
 * define these macros for backwards compatibilty.
 */

#define Tcl_Ckalloc Tcl_Alloc
#define Tcl_Ckfree Tcl_Free
#define Tcl_Ckrealloc Tcl_Realloc
#define Tcl_Return Tcl_SetResult
#define Tcl_TildeSubst Tcl_TranslateFileName

#endif /* RESOURCE_INCLUDED */

#undef TCL_STORAGE_CLASS
#define TCL_STORAGE_CLASS DLLIMPORT

#endif /* _TCL */

/*
 * end of tcl.h definitions
 */


/*
 * regexp definitions - from tcl8.0/tclRegexp.h
 */

/*
 * Definitions etc. for regexp(3) routines.
 *
 * Caveat:  this is V8 regexp(3) [actually, a reimplementation thereof],
 * not the System V one.
 *
 * RCS: @(#) $Id: expect.h,v 5.32 2010/07/01 00:53:49 eee Exp $
 */

#ifndef _REGEXP
#define _REGEXP 1

#ifdef BUILD_tcl
# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLEXPORT
#endif

/*
 * NSUBEXP must be at least 10, and no greater than 117 or the parser
 * will not work properly.
 */

#define NSUBEXP  20

typedef struct regexp {
	char *startp[NSUBEXP];
	char *endp[NSUBEXP];
	char regstart;		/* Internal use only. */
	char reganch;		/* Internal use only. */
	char *regmust;		/* Internal use only. */
	int regmlen;		/* Internal use only. */
	char program[1];	/* Unwarranted chumminess with compiler. */
} regexp;

EXTERN regexp *TclRegComp _ANSI_ARGS_((char *exp));
EXTERN int TclRegExec _ANSI_ARGS_((regexp *prog, char *string, char *start));
EXTERN void TclRegSub _ANSI_ARGS_((regexp *prog, char *source, char *dest));
EXTERN void exp_TclRegError _ANSI_ARGS_((char *msg));
EXTERN char *TclGetRegError _ANSI_ARGS_((void));

# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT

#endif /* REGEXP */


/*
 * end of regexp definitions
 */


/*
 * finally - expect-specific definitions
 */

#include "expect_comm.h"

enum exp_type {
	exp_end = 0,		/* placeholder - no more cases */
	exp_glob,		/* glob-style */
	exp_exact,		/* exact string */
	exp_regexp,		/* regexp-style, uncompiled */
	exp_compiled,		/* regexp-style, compiled */
	exp_null,		/* matches binary 0 */
	exp_bogus		/* aid in reporting compatibility problems */
};

struct exp_case {		/* case for expect command */
	char *pattern;
	regexp *re;
	enum exp_type type;
	int value;		/* value to be returned upon match */
};

EXTERN char *exp_buffer;		/* buffer of matchable chars */
EXTERN char *exp_buffer_end;		/* one beyond end of matchable chars */
EXTERN char *exp_match;			/* start of matched string */
EXTERN char *exp_match_end;		/* one beyond end of matched string */
EXTERN int exp_match_max;		/* bytes */
EXTERN int exp_timeout;			/* seconds */
EXTERN int exp_full_buffer;		/* if true, return on full buffer */
EXTERN int exp_remove_nulls;		/* if true, remove nulls */

EXTERN int exp_pty_timeout;		/* see Cray hooks in source */
EXTERN int exp_pid;			/* process-id of spawned process */
EXTERN int exp_autoallocpty;		/* if TRUE, we do allocation */
EXTERN int exp_pty[2];			/* master is [0], slave is [1] */
EXTERN char *exp_pty_slave_name;	/* name of pty slave device if we */
					/* do allocation */
EXTERN char *exp_stty_init;		/* initial stty args */
EXTERN int exp_ttycopy;			/* copy tty parms from /dev/tty */
EXTERN int exp_ttyinit;			/* set tty parms to sane state */
EXTERN int exp_console;			/* redirect console */

#ifdef HAVE_SIGLONGJMP
EXTERN sigjmp_buf exp_readenv;		/* for interruptable read() */
#else
EXTERN jmp_buf exp_readenv;		/* for interruptable read() */
#endif /* HAVE_SIGLONGJMP */

EXTERN int exp_reading;			/* whether we can longjmp or not */
#define EXP_ABORT	1		/* abort read */
#define EXP_RESTART	2		/* restart read */

EXTERN int exp_is_debugging;
EXTERN int exp_loguser;

EXTERN void (*exp_close_in_child)();	/* procedure to close files in child */
EXTERN void exp_slave_control _ANSI_ARGS_((int,int));
EXTERN int exp_logfile_all;
EXTERN FILE *exp_debugfile;
EXTERN FILE *exp_logfile;
extern void exp_debuglog _ANSI_ARGS_(TCL_VARARGS(char *,fmt));
extern void exp_errorlog _ANSI_ARGS_(TCL_VARARGS(char *,fmt));

EXTERN int exp_disconnect _ANSI_ARGS_((void));
EXTERN FILE *exp_popen	_ANSI_ARGS_((char *command));
EXTERN void (*exp_child_exec_prelude) _ANSI_ARGS_((void));

#ifndef EXP_DEFINE_FNS
EXTERN int exp_spawnl	_ANSI_ARGS_(TCL_VARARGS(char *,file));
EXTERN int exp_expectl	_ANSI_ARGS_(TCL_VARARGS(int,fd));
EXTERN int exp_fexpectl	_ANSI_ARGS_(TCL_VARARGS(FILE *,fp));
#endif

EXTERN int exp_spawnv	_ANSI_ARGS_((char *file, char *argv[]));
EXTERN int exp_expectv	_ANSI_ARGS_((int fd, struct exp_case *cases));
EXTERN int exp_fexpectv	_ANSI_ARGS_((FILE *fp, struct exp_case *cases));

EXTERN int exp_spawnfd	_ANSI_ARGS_((int fd));

#endif /* _EXPECT_H */
