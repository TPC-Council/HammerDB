/*
 * pgtkAppInit.c
 *    $Id: pgtkAppInit.c 5 2004-02-29 20:54:55Z lbayuk $
 *    A Tcl/Tk shell ("wish") with PostgreSQL interface commands
 *
 * Portions Copyright (c) 1996-2003, PostgreSQL Global Development Group
 * Portions Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

#include <tk.h>
#include "libpgtcl.h"

/*
 *----------------------------------------------------------------------
 *
 * main
 *
 *		This is the main program for the application.
 *
 * Results:
 *		None: Tk_Main never returns here, so this procedure never
 *		returns either.
 *
 * Side effects:
 *		Whatever the application does.
 *
 *----------------------------------------------------------------------
 */

int
main(int argc, char **argv)
{
	extern int Tcl_AppInit (Tcl_Interp *interp);

	Tk_Main(argc, argv, Tcl_AppInit);
	return 0;					/* Needed only to prevent compiler
								 * warning. */
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit
 *
 *		This procedure performs application-specific initialization.
 *		Most applications, especially those that incorporate additional
 *		packages, will have their own version of this procedure.
 *
 * Results:
 *		Returns a standard Tcl completion code, and leaves an error
 *		message in interp->result if an error occurs.
 *
 * Side effects:
 *		Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_AppInit(Tcl_Interp *interp)
{
	if (Tcl_Init(interp) == TCL_ERROR)
		return TCL_ERROR;
	if (Tk_Init(interp) == TCL_ERROR)
		return TCL_ERROR;

	/*
	 * Call the init procedures for libpgtcl.
	 */
	if (Pgtcl_Init(interp) == TCL_ERROR)
		return TCL_ERROR;

	/*
	 * Specify a user-specific startup file to invoke if the application
	 * is run interactively.  Typically the startup file is "~/.apprc"
	 * where "app" is the name of the application.	If this line is
	 * deleted then no user-specific startup file will be run under any
	 * conditions.
	 */

	Tcl_SetVar(interp, "tcl_rcFileName", "~/.wishrc", TCL_GLOBAL_ONLY);

	return TCL_OK;
}
