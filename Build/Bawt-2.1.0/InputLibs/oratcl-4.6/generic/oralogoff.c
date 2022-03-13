/*
 * oralogoff.c
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
 * Oratcl_Logoff --
 *    Implements the oralogoff command:
 *    usage: oralogon lda_handle
 *       lda_handle should be a valid, open lda handle from oralogon
 *
 *    results:
 *	null string
 *      TCL_OK - logoff successful
 *      TCL_ERROR - logoff not successful - error message returned
 *----------------------------------------------------------------------
 */

int
Oratcl_Logoff (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	Tcl_HashEntry	*stmHashPtr;
	OratclLogs	*LogPtr;
	OratclStms	*StmPtr;
	Tcl_HashSearch  search;
	
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

	/* close the open statement handles for this connection */
	stmHashPtr = Tcl_FirstHashEntry(OratclStatePtr->stmHash, &search);
	while (stmHashPtr != NULL) {
		StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
		if (StmPtr->logid == LogPtr->logid) {
			Oratcl_StmFree(StmPtr);
			StmPtr = NULL;
			Tcl_DeleteHashEntry(stmHashPtr);
			stmHashPtr = Tcl_FirstHashEntry(OratclStatePtr->stmHash, &search);
		} else {
			stmHashPtr = Tcl_NextHashEntry(&search);
		}
	}

	rc = OCI_SessionEnd(LogPtr->svchp,
			    LogPtr->errhp,
			    LogPtr->usrhp,
			    OCI_DEFAULT);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);

	rc = OCI_ServerDetach(LogPtr->srvhp,
			      LogPtr->errhp,
			      (ub4) OCI_DEFAULT);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);

	Oratcl_LogFree(LogPtr);

	Tcl_DeleteHashEntry(logHashPtr);

	Tcl_SetObjResult(interp, Tcl_NewIntObj(rc));

common_exit:

	return tcl_return;
}
