/* expect_tcl.h - include file for using the expect library, libexpect.a
with Tcl (and optionally Tk)

Written by: Don Libes, libes@cme.nist.gov, NIST, 12/3/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#ifndef _EXPECT_TCL_H
#define _EXPECT_TCL_H

#include <stdio.h>
#include "expect_comm.h"

/*
 * This is a convenience macro used to initialize a thread local storage ptr.
 * Stolen from tclInt.h
 */
#ifndef TCL_TSD_INIT
#define TCL_TSD_INIT(keyPtr)	(ThreadSpecificData *)Tcl_GetThreadData((keyPtr), sizeof(ThreadSpecificData))
#endif

EXTERN int exp_cmdlinecmds;
EXTERN int exp_interactive;
EXTERN FILE *exp_cmdfile;
EXTERN char *exp_cmdfilename;
EXTERN int exp_getpid;	/* pid of Expect itself */
EXTERN int exp_buffer_command_input;

EXTERN int exp_strict_write;

EXTERN int exp_tcl_debugger_available;

EXTERN Tcl_Interp *exp_interp;

#define Exp_Init Expect_Init
EXTERN int	Expect_Init _ANSI_ARGS_((Tcl_Interp *));	/* for Tcl_AppInit apps */
EXTERN void	exp_parse_argv _ANSI_ARGS_((Tcl_Interp *,int argc,char **argv));
EXTERN int	exp_interpreter _ANSI_ARGS_((Tcl_Interp *,Tcl_Obj *));
EXTERN int	exp_interpret_cmdfile _ANSI_ARGS_((Tcl_Interp *,FILE *));
EXTERN int	exp_interpret_cmdfilename _ANSI_ARGS_((Tcl_Interp *,char *));
EXTERN void	exp_interpret_rcfiles _ANSI_ARGS_((Tcl_Interp *,int my_rc,int sys_rc));

EXTERN char *	exp_cook _ANSI_ARGS_((char *s,int *len));

EXTERN void	expCloseOnExec _ANSI_ARGS_((int));

			/* app-specific exit handler */
EXTERN void	(*exp_app_exit)_ANSI_ARGS_((Tcl_Interp *));
EXTERN void	exp_exit_handlers _ANSI_ARGS_((ClientData));

EXTERN void	exp_error _ANSI_ARGS_(TCL_VARARGS(Tcl_Interp *,interp));

#endif /* _EXPECT_TCL_H */
