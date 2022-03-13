/*
 * oramsg.c
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
 *
 * Oratcl_Message --
 *    Implements the oramsg command:
 *    usage: oramsg stm_handle
 *
 *    results:
 *	oracle message information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_Message (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	Tcl_HashEntry	*stmHashPtr;
	OratclLogs	*LogPtr = NULL;
	OratclStms	*StmPtr = NULL;

	int		mode = 1;

	int		oColsc;
	Tcl_Obj		**oCols = NULL;
	int		oColslen = 7;
	Tcl_Obj		*oResult;

	static CONST84 char *options[] = {"all",
				   "rc",
				   "error",
				   "rows",
				   "peo",
				   "ocicode",
				   "sqltype",
				   "arraydml_errors",
				   NULL};

	enum		optindex {OPT_ALL,
				  OPT_RC,
				  OPT_ERR,
				  OPT_ROW,
				  OPT_PEO,
				  OPT_FCD,
				  OPT_SQL,
				  OPT_ARRAY_DML};

	int		tcl_return = TCL_OK;

	if (objc == 1 || objc > 3 ) {
		Tcl_WrongNumArgs(interp, objc, objv, "stm_handle ?-option?");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	if (objc == 3) {
		if (Tcl_GetIndexFromObj(interp,
					objv[2],
					(CONST84 char **)options,
					"option",
					0,
					&mode)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
	}

	/*
	 *  We will accept either a logon handle or statement handle.
	 */
	stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
				       Tcl_GetStringFromObj(objv[1], NULL));

	if (stmHashPtr == NULL) {

		logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
					       Tcl_GetStringFromObj(objv[1], NULL));

		if (logHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": handle ",
					objv[1],
					" not valid");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);

	} else {

		StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);

	}

	oResult = Tcl_GetObjResult(interp);
	oCols = (Tcl_Obj **) ckalloc (oColslen * sizeof(*oCols));

	oColsc = 0;
	if (mode == OPT_ALL || mode == OPT_RC) {
		if (LogPtr) {
			oCols[oColsc++] = Tcl_NewIntObj(LogPtr->ora_rc);
		} else if (StmPtr) {
			oCols[oColsc++] = Tcl_NewIntObj(StmPtr->ora_rc);
		} else {
			oCols[oColsc++] = Tcl_NewIntObj(0);
		}
	}
	if (mode == OPT_ALL || mode == OPT_ERR) {
		if (LogPtr) {
			oCols[oColsc++] = Tcl_NewStringObj(LogPtr->ora_err.string, LogPtr->ora_err.length);
		} else if (StmPtr) {
			oCols[oColsc++] = Tcl_NewStringObj(StmPtr->ora_err.string, StmPtr->ora_err.length);
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}
	if (mode == OPT_ALL || mode == OPT_ROW) {
		if (StmPtr) {
			oCols[oColsc++] = Tcl_NewLongObj(StmPtr->ora_row);
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}
	if (mode == OPT_ALL || mode == OPT_PEO) {
		if (StmPtr) {
			oCols[oColsc++] = Tcl_NewIntObj(StmPtr->ora_peo);
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}
	if (mode == OPT_ALL || mode == OPT_FCD) {
		if (StmPtr) {
			oCols[oColsc++] = Tcl_NewIntObj(StmPtr->ora_fcd);
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}
	if (mode == OPT_ALL || mode == OPT_SQL) {
		if (StmPtr) {
			oCols[oColsc++] = Tcl_NewIntObj(StmPtr->sqltype);
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}
	if (mode == OPT_ALL || mode == OPT_ARRAY_DML) {
		if (StmPtr) {
			if (StmPtr->array_dml_errors) {
				oCols[oColsc++] = StmPtr->array_dml_errors;
			} else {
				oCols[oColsc++] = Tcl_NewStringObj("", -1);;
			}
		} else {
			oCols[oColsc++] = Tcl_NewStringObj("", -1);;
		}
	}

	if (mode == OPT_ALL) {
		Tcl_ListObjAppendElement(interp, oResult, Tcl_NewListObj(oColslen, oCols));
	} else {
		Tcl_ListObjAppendElement(interp, oResult, oCols[0]);
	}

common_exit:

	if (oCols)
		ckfree((char *) oCols);

	return tcl_return;
}
