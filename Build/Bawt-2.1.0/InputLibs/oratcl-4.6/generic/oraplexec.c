/*
 * oraplexec.c
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "oratclInt.h"
#include "oratclTypes.h"
#include "oratclExtern.h"
#include "oratcl.h"

/*
 *----------------------------------------------------------------------
 * Oratcl_PLexec --
 *    Implements the oraplexec command:
 *    usage: oraplexec cur_handle pl_block [ :varname value ]  [ .... ]
 *
 *    results:
 *	return parms in tcl list form
 *      TCL_OK - proc executed
 *      TCL_ERROR - wrong # args, or handle not opened,
 *----------------------------------------------------------------------
 */

int
Oratcl_PLexec (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{

	int		bindObjc = 0;
	Tcl_Obj		**bindObjv = NULL;

	register int	i;
	int		tcl_return = TCL_OK;

	if (objc < 3) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle pl_block [ :varname value ] ...");
		return TCL_ERROR;
	}

	for (i = 0; i < objc; i++) {
		Tcl_IncrRefCount(objv[i]);
	}

	tcl_return = Oratcl_Parse(clientData, interp, 3, objv);
	if (tcl_return != TCL_OK) {
		goto common_exit;
	}

	/* reorganise arguments for Oratcl_Bind */
	bindObjc = objc - 1;
	bindObjv = (Tcl_Obj **) ckalloc(bindObjc * sizeof(Tcl_Obj *));
	if (bindObjv == NULL) {
		goto common_exit;
	}


	bindObjv[0] = objv[0];
	bindObjv[1] = objv[1];

	for (i = 3;  i < objc;  i++) {
		bindObjv[i-1] = objv[i];
	}

	tcl_return = Oratcl_Bind(clientData, interp, bindObjc, bindObjv);
	if (tcl_return != TCL_OK) {
		goto common_exit;
	}

	tcl_return = Oratcl_Exec(clientData, interp, 3, objv);

common_exit:

	for (i = 0; i < objc; i++) {
		Tcl_DecrRefCount(objv[i]);
	}

	if (bindObjv) {
		ckfree ((char *) bindObjv);
	}

	return tcl_return;
}
