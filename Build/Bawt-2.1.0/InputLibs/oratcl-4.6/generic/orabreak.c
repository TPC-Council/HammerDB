/*
 * orabreak.c
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
 * Oratcl_Break --
 *    Implements the orabreak command:
 *    usage: orabreak stm_handle
 *    usage: ::oratcl::orabreak stm_handle
 *
 *    results:
 *	return code from OCIBreak or OCIReset
 *      TCL_OK - handle is reset
 *      TCL_ERROR - wrong # args, or handle not opened,  OCI error
 *----------------------------------------------------------------------
 */

int
Oratcl_Break (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;

	sword		rc;

	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle");
		return TCL_ERROR;
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
	LogPtr = (OratclLogs *) Tcl_GetHashValue(StmPtr->logHashPtr);

	StmPtr->ora_rc  = 0;
	Tcl_DStringInit(&StmPtr->ora_err);

	if (LogPtr->async == 1) {
		rc = OCI_Break((dvoid *) LogPtr->srvhp,
			       LogPtr->errhp);

		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&StmPtr->ora_rc,
					&StmPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		rc = OCI_Reset((dvoid *) LogPtr->srvhp,
			       LogPtr->errhp);

		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&StmPtr->ora_rc,
					&StmPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

	}

	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));

common_exit:

	return tcl_return;
}
