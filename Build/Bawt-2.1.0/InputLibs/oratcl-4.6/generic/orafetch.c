/*
 * orafetch.c
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
 * Oratcl_Fetch --
 *    Implements the orafetch command:
 *    usage: orafetch statement-handle ?options? ...
 *
 * Results:
 *	return code from OCI_StmtFetch
 *      TCL_OK - handle is opened
 *      TCL_ERROR - wrong # args, or handle not opened
 *----------------------------------------------------------------------
 */

int
Oratcl_Fetch (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;

	int		ca = 0;
	int		i;
	OratclCols 	*ColPtr;
	OratclCols	*col;
	sword		rc;
	int		hashType = 1;	/* default use column name for array index */

	int		option;
	static CONST84 char *options[] = {"-datavariable",
				   "-dataarray",
				   "-command",
				   "-indexbyname",
				   "-indexbynumber",
				   NULL};
	enum		optindex {OPT_DVAR,
				  OPT_DARR,
				  OPT_EVAL,
				  OPT_IBNA,
				  OPT_IBNU};

	Tcl_Obj		*dvarObjPtr = NULL;
	Tcl_Obj		*avarObjPtr = NULL;
	Tcl_Obj		*evalObjPtr = NULL;

	int		objix;
	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "statement-handle ?options ...?");
		return TCL_ERROR;
	}

	stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
				       Tcl_GetString(objv[1]));

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

	for (objix=2; objix<objc; objix++) {
		if (Tcl_GetIndexFromObj(interp,
					objv[objix],
					(CONST84 char **)options,
					"option",
					0,
					&option)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
		switch (option) {
			case OPT_IBNA:
				hashType = 1;
				break;
			case OPT_IBNU:
				hashType = 0;
				break;
			case OPT_DVAR:
				objix++;
				if (objix < objc) {
					dvarObjPtr = objv[objix];
					Tcl_IncrRefCount(dvarObjPtr);
				}
				break;
			case OPT_DARR:
				objix++;
				if (objix < objc) {
					avarObjPtr = objv[objix];
					Tcl_IncrRefCount(avarObjPtr);
				}
				break;
			case OPT_EVAL:
				objix++;
				if (objix < objc) {
					evalObjPtr = objv[objix];
					Tcl_IncrRefCount(evalObjPtr);
				}
				break;
			default:
				/*NOTREACHED*/
				break;
		}

	}

	/*
	 * If PL/SQL, use bind_list else use col_list.
	 */
	if (StmPtr->sqltype == OCI_STMT_BEGIN ||
	    StmPtr->sqltype == OCI_STMT_DECLARE) {
		ColPtr = StmPtr->bind_list;
	} else {
		ColPtr = StmPtr->col_list;
	}

	StmPtr->ora_rc = 0;
	Tcl_DStringInit(&StmPtr->ora_err);

	/* check if already exhausted */

	if (StmPtr->fetch_end
	    && StmPtr->append_cnt >= StmPtr->fetch_cnt
	    && StmPtr->fetch_cnt >  0) {
		Tcl_SetObjResult(interp, Tcl_NewIntObj(NO_DATA_FOUND));
		StmPtr->ora_rc = NO_DATA_FOUND;
		tcl_return = TCL_OK;
		goto common_exit;
	}

	if (StmPtr->fetchidx >= StmPtr->fetchmem) {

		for (col=ColPtr; col != NULL; col=col->next) {
			for (i=0; i < StmPtr->fetchmem; i++) {
				col->rcodep[i] = 0;
				col->rlenp[i] = 0;
			}
		}

		rc = OCI_StmtFetch(StmPtr->stmhp,
				  LogPtr->errhp,
				  StmPtr->fetchmem,
				  OCI_FETCH_NEXT,
				  OCI_DEFAULT);


		if (rc == OCI_STILL_EXECUTING) {
			StmPtr->ora_rc = rc;
			Tcl_SetObjResult(interp, Tcl_NewIntObj(rc));
			tcl_return = TCL_OK;
			goto common_exit;
		}

		OCI_AttrGet( (dvoid *) StmPtr->stmhp,
			    (ub4) OCI_HTYPE_STMT,
			    (ub4 *) &StmPtr->fetch_cnt,
			    (ub4) 0,
			    OCI_ATTR_ROW_COUNT,
			    LogPtr->errhp);

		if (rc == OCI_NO_DATA) {
			StmPtr->fetch_end = 1;
			if (StmPtr->append_cnt >= StmPtr->fetch_cnt) {
				Tcl_SetObjResult(interp, Tcl_NewIntObj(NO_DATA_FOUND));
				StmPtr->ora_rc = NO_DATA_FOUND;
				tcl_return = TCL_OK;
				goto common_exit;
			}

		} else if (rc == OCI_SUCCESS || rc == OCI_SUCCESS_WITH_INFO) {
			/* Null Statement */
		} else {
			StmPtr->fetch_cnt = 0;
			StmPtr->fetchidx  = 0;
			StmPtr->fetch_end = 1;
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&StmPtr->ora_rc,
					&StmPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		StmPtr->fetchidx = 0;
	}

	ca = Oratcl_ColAppend(interp, StmPtr, dvarObjPtr, avarObjPtr, hashType);
	if (ca < 0) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* preserve the result we have set for this command */

	if (evalObjPtr) {
		tcl_return = Tcl_EvalObjEx(interp, evalObjPtr, 0);
		if (tcl_return == TCL_OK) {
			Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
		}
	}

common_exit:

	if (dvarObjPtr) {
		Tcl_DecrRefCount(dvarObjPtr);
	}
	if (avarObjPtr) {
		Tcl_DecrRefCount(avarObjPtr);
	}
	if (evalObjPtr) {
		Tcl_DecrRefCount(evalObjPtr);
	}

	return tcl_return;
}
