/*
 * orabindexec.c
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#include <string.h>

#include "oratclInt.h"
#include "oratclTypes.h"
#include "oratclExtern.h"
#include "oratcl.h"

/*
 *----------------------------------------------------------------------
 * Oratcl_Bindexec --
 *    Implements the orabindexec command:
 *    usage: orabindexec cur_handle ?-commit? :varname value
 *
 *    results:
 *	bind :varname value pairs, execute sql
 *	sets message array element "rc" with value of exec rcode
 *      TCL_OK - handle is opened
 *      TCL_ERROR - wrong # args, or handle not opened
 *----------------------------------------------------------------------
 */

int
Oratcl_Bindexec (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{

	int		bindObjc = 0;
	Tcl_Obj		**bindObjv = NULL;
	int		execObjc = 0;
	Tcl_Obj		**execObjv = NULL;

	register int	i;
	char		*p;

	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle ?-commit? [ :varname value ] ...");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	for (i = 0; i < objc; i++) {
		Tcl_IncrRefCount(objv[i]);
	}

	/* reorganise arguments for Oratcl_Bind and Oratcl_Exec */
	execObjc = 2;
	bindObjc = objc;

	/* check for option and deprecated keywords */
	if (objc >= 3) {
		p = Tcl_GetStringFromObj(objv[2], (int *) NULL);
		if (*p == '-') {
			p++;
		}
		if (strcmp(p,"commit") == 0) {
			bindObjc--;
			execObjc++;
		}
	}

	bindObjv = (Tcl_Obj **) ckalloc(bindObjc * sizeof(Tcl_Obj *));
	execObjv = (Tcl_Obj **) ckalloc(execObjc * sizeof(Tcl_Obj *));

	bindObjv[0] = objv[0];
	execObjv[0] = objv[0];
	bindObjv[1] = objv[1];
	execObjv[1] = objv[1];

	/* pass commit along */
	if (execObjc == 3) {
		execObjv[2] = objv[2];
		for (i = 3;  i < objc;  i++) {
			bindObjv[i-1] = objv[i];
		}
	} else {
		for (i = 2;  i < objc;  i++) {
			bindObjv[i] = objv[i];
		}
	}

	tcl_return = Oratcl_Bind(clientData, interp, bindObjc, bindObjv);
	if (tcl_return != TCL_OK) {
		goto common_exit;
	}

	tcl_return = Oratcl_Exec(clientData, interp, execObjc, execObjv);

common_exit:

	for (i = 0; i < objc; i++) {
		Tcl_DecrRefCount(objv[i]);
	}

	if (bindObjv) {
		ckfree ((char *) bindObjv);
	}
	
	if (execObjv) {
		ckfree ((char *) execObjv);
	}

	return tcl_return;
}
