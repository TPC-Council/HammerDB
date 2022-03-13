/*
 * oraclose.c
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

/*
 *----------------------------------------------------------------------
 * Oratcl_Close --
 *    Implements the oraclose command:
 *    usage: oraclose stm_handle
 *
 *    results:
 *	null string
 *      TCL_OK - statement handle closed successfully
 *      TCL_ERROR - wrong # args, or stm_handle not opened
 *----------------------------------------------------------------------
 */

int
Oratcl_Close (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp, objc, objv, "stm_handle");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
				       Tcl_GetStringFromObj(objv[1], NULL));

	if (stmHashPtr == NULL) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": handle ",
				objv[1],
				" not open");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);

	Oratcl_StmFree(StmPtr);
	StmPtr = NULL;
	Tcl_DeleteHashEntry(stmHashPtr);

	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));

common_exit:

	return tcl_return;
}
