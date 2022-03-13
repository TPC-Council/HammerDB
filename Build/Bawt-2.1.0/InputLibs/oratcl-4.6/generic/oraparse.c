/*
 * oraparse.c
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
 * Oratcl_Parse --
 *    Implements the ::oratcl::oraparse command:
 *    usage: ::oratcl::oraparse stm_handle sql_string
 *
 *    results:
 *	return code from OCIStmtPrepare or OCI_StmtExecute
 *      TCL_OK - handle is opened, sql executed ok
 *      TCL_ERROR - wrong # args, or handle not opened,  bad sql stmt
 *----------------------------------------------------------------------
 */

int
Oratcl_Parse (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;

	Tcl_DString	stmStr;
	sword		rc;
	int		cols;

	char		*stmt;
	ub4		stln;

	int		tcl_return = TCL_OK;

	if (objc < 3) {
		Tcl_WrongNumArgs(interp, objc, objv, "stm_handle sql_str");
		return TCL_ERROR;
	}

	Tcl_DStringInit(&stmStr);

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

	stmt = Tcl_GetStringFromObj(objv[2], (int *) &stln);
	if (StmPtr->utfmode) {
		Tcl_UtfToExternalDString(NULL, stmt, stln, &stmStr);
	} else {
		Tcl_DStringAppend(&stmStr, stmt, stln);
	}

	if (LogPtr->async == 1 && StmPtr->ora_rc == OCI_STILL_EXECUTING) {
		/* NULL Statement */
	} else {

		/* clear any previous results */
		StmPtr->ora_rc = 0;
		Tcl_DStringInit(&StmPtr->ora_err);
		StmPtr->ora_row = 0;
		Oratcl_ColFree(StmPtr->col_list);
		StmPtr->col_list   	= NULL;
		Oratcl_ColFree(StmPtr->bind_list);
		StmPtr->bind_list	= NULL;
		StmPtr->ora_fcd = 0;

		/* prepare the new statement */
		rc = OCI_StmtPrepare((dvoid *) StmPtr->stmhp,
				     LogPtr->errhp,
				     (text *) Tcl_DStringValue(&stmStr),
				     (ub4) Tcl_DStringLength(&stmStr),
				     (ub4) OCI_NTV_SYNTAX,
				     (ub4) OCI_DEFAULT);

		if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO) {
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

	/* get sql type */
	OCI_AttrGet( (dvoid *) StmPtr->stmhp,
		    (ub4) OCI_HTYPE_STMT,
		    (ub2 *) &StmPtr->sqltype,
		    (ub4) 0,
		    OCI_ATTR_STMT_TYPE,
		    LogPtr->errhp);

	if (StmPtr->sqltype == OCI_STMT_SELECT) {
		StmPtr->iters = 0;
		StmPtr->ora_peo = 0;
		/* need to describe the sql to get the select columns */
		rc = OCI_StmtExecute(LogPtr->svchp,
				     StmPtr->stmhp,
				     LogPtr->errhp,
				     (ub4) StmPtr->iters,
				     (ub4) 0,
				     (OCISnapshot *) NULL,
				     (OCISnapshot *) NULL,
				     OCI_DESCRIBE_ONLY);

		if (rc == OCI_STILL_EXECUTING) {
			Tcl_SetObjResult(interp, Tcl_NewIntObj(rc));
			StmPtr->ora_rc = rc;
			if (LogPtr->async == 1) {
				tcl_return = TCL_OK;
			} else {
				tcl_return = TCL_ERROR;
			}
			goto common_exit;
		}

		if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO) {
#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
			OCI_AttrGet( (dvoid *) StmPtr->stmhp,
				    (ub4) OCI_HTYPE_STMT,
				    (ub2 *) &StmPtr->ora_peo,
				    (ub4) 0,
				    OCI_ATTR_PARSE_ERROR_OFFSET,
				    LogPtr->errhp);
#endif
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&StmPtr->ora_rc,
					&StmPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		cols = Oratcl_ColDescribe(interp, StmPtr);
		if (cols < 0) {
			tcl_return = TCL_ERROR;
			goto common_exit;	
		}

	} else {
		StmPtr->iters = 1;
	}

	StmPtr->ora_rc = 0;
	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));

common_exit:

	Tcl_DStringFree(&stmStr);

	return tcl_return;
}
