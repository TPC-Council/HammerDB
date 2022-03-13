/*
 * oraopen.c
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
 * Oratcl_Open --
 *    Implements the oraopen command:
 *    usage: oralogon lda_handle
 *
 *    results:
 *	stm_handle
 *      TCL_OK - OCIAllocHandle successful
 *      TCL_ERROR - OCIAllocHandle not successful - error message returned
 *----------------------------------------------------------------------
 */

int
Oratcl_Open (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{

	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	Tcl_HashEntry	*stmHashPtr;
	char		*logHashKey = NULL;
	OratclLogs	*LogPtr;
	OratclStms	*StmPtr;

	sword		rc;
	int		new;
	char		buf[25];

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
	logHashKey = Tcl_GetHashKey(OratclStatePtr->logHash, logHashPtr);

	StmPtr = (OratclStms *) ckalloc (sizeof (OratclStms));

	/* generate an lda name and put it in the hash table. */
	OratclStatePtr->stmid++;
	sprintf(buf,"%s.%d",logHashKey,OratclStatePtr->stmid);
	stmHashPtr = Tcl_CreateHashEntry(OratclStatePtr->stmHash, buf, &new);

	if (stmHashPtr == NULL) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": no statement handles available",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		ckfree ((char *)StmPtr);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	Tcl_SetHashValue(stmHashPtr, StmPtr);

	StmPtr->stmid = OratclStatePtr->stmid;
	StmPtr->ora_rc		= 0;
	Tcl_DStringInit(&StmPtr->ora_err);
	StmPtr->ora_row		= 0;
	StmPtr->ora_peo		= 0;
	StmPtr->ora_fcd		= 0;

	rc = OCI_HandleAlloc((dvoid *) LogPtr->envhp,
			     (dvoid **) (dvoid *) &StmPtr->stmhp,
			     (ub4) OCI_HTYPE_STMT,
			     (size_t) 0,
			     (dvoid **) 0);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc != OCI_SUCCESS) {
		Oratcl_StmFree(StmPtr);
		StmPtr = NULL;
		Tcl_DeleteHashEntry(stmHashPtr);

		Oratcl_ErrorMsg(interp,
				objv[0],
				": handle allocation failed",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* cursor open ok */
	StmPtr->col_list	= NULL;
	StmPtr->bind_list	= NULL;
	StmPtr->fetchrows	= ORA_FETCH_ROWS;
	StmPtr->fetchmem	= ORA_FETCH_ROWS;
	StmPtr->longsize	= ORA_LONG_SIZE;
	StmPtr->lobpsize	= ORA_LOBP_SIZE;
	StmPtr->longpsize	= ORA_LONGP_SIZE;
	StmPtr->bindsize	= ORA_BIND_SIZE;
	StmPtr->numbsize	= ORA_NUMB_SIZE;
	StmPtr->datesize	= ORA_DATE_SIZE;
	StmPtr->nullvalue	= Tcl_NewStringObj("default", -1);
	Tcl_IncrRefCount(StmPtr->nullvalue);
	StmPtr->fetchidx		= 0;
	StmPtr->fetch_end	= 1;
	StmPtr->fetch_cnt	= 0;
	StmPtr->array_dml	= 0;
	StmPtr->array_dml_errors = NULL;
	StmPtr->append_cnt	= 0;
	StmPtr->sqltype		= 0;
	StmPtr->logHashPtr	= logHashPtr;
	StmPtr->logid		= LogPtr->logid;
	StmPtr->utfmode		= 0;
	StmPtr->unicode		= 0;

	Tcl_SetObjResult(interp, Tcl_NewStringObj(buf, -1));

common_exit:

	return tcl_return;
}
