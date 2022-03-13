/*
 * orasql.c
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

#include "oratcl.h"
#include "oratclInt.h"
#include "oratclTypes.h"
#include "oratclExtern.h"

/*
 *----------------------------------------------------------------------
 * Oratcl_Sql --
 *    Implements the orasql command:
 *    usage: orasql stm_handle sql_string ?-parseonly? ?-commit?
 *
 *    results:
 *	return code from OCI_StmtExecute
 *      TCL_OK - handle is opened, sql executed ok
 *      TCL_ERROR - wrong # args, or handle not opened,  bad sql stmt
 *----------------------------------------------------------------------
 */

int
Oratcl_Sql (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	int		parseonly = 0;
	char		*p;

	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	int		postcommit = 0;
	int		commitObjc = 0;
	Tcl_Obj		**commitObjv = NULL;
	char		*logHashKey;
	Tcl_Obj		*res_obj;

	int		tcl_return = TCL_OK;

	if (objc < 3) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle sql_str ?-parseonly? | ?-commit?");
		return TCL_ERROR;
	}

	/* check for options and deprecated keywords */
	if (objc >= 4) {
		p = Tcl_GetStringFromObj(objv[3], NULL);
		if (*p == '-') {
			p++;
		}
		if (strcmp(p,"parseonly") == 0) {
			parseonly = 1;
		}
		if (strcmp(p,"commit") == 0) {
			postcommit = 1;
		}
	}

	tcl_return = Oratcl_Parse(clientData, interp, objc, objv);
	if (tcl_return != TCL_OK) {
		goto common_exit;
	}

	if (parseonly) {
		goto common_exit;
	}

	tcl_return = Oratcl_Exec(clientData, interp, objc, objv);

	if (postcommit) {
		stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
					       Tcl_GetStringFromObj(objv[1],
								    NULL));

		if (stmHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": stm_handle ",
					objv[1],
					" not open");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
		logHashKey = Tcl_GetHashKey(OratclStatePtr->logHash,
					    StmPtr->logHashPtr);

		res_obj = Tcl_NewStringObj((char *) logHashKey, -1);
		Tcl_IncrRefCount(res_obj);
		commitObjc = 2;	
		commitObjv = (Tcl_Obj **) ckalloc(commitObjc * sizeof(Tcl_Obj *));
		commitObjv[0] = objv[0];
		commitObjv[1] = res_obj;
		Oratcl_Commit (clientData, interp, commitObjc, commitObjv);
		Tcl_DecrRefCount(res_obj);
	}
common_exit:

	if (commitObjv) {
		ckfree ((char *) commitObjv);
	}

	return tcl_return;
}
