/*
 * oraroll.c
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
 * Oratcl_Roll --
 *    Implements the oraroll command:
 *    usage: oraroll lda_handle
 *
 *    results:
 *	null string
 *      TCL_OK - transactions rolled back
 *      TCL_ERROR - wrong # args, or handle not opened,
 *----------------------------------------------------------------------
 */

int
Oratcl_Roll (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	OratclLogs	*LogPtr;
	sword		rc;
	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp, objc, objv, "lda_handle");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
				       Tcl_GetStringFromObj(objv[1], NULL));

	if (logHashPtr == NULL) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": lda_handle ",
				objv[1],
				" not valid");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);
	Tcl_DStringInit(&LogPtr->ora_err);

	rc = OCI_TransRollback((dvoid *) LogPtr->svchp,
			       (dvoid *) LogPtr->errhp,
			       (ub4) OCI_DEFAULT);

	if (rc != OCI_SUCCESS) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	Tcl_SetObjResult(interp, Tcl_NewIntObj(rc));

common_exit:

	return tcl_return;
}
