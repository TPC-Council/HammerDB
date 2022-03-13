/*
 * oradesc.c
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
 * Oratcl_Describe --
 *    Implements the oradesc command:
 *    usage: oradesc lda_handle table_name
 *
 *    results:
 *	table information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_Describe (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	OratclLogs	*LogPtr;

	sword		rc;

	OCIDescribe	*dschp = (OCIDescribe *)0;

	char		*tmp_str;
	int		tmp_len;

	text		*syn_st1 = NULL, *syn_st2 = NULL, *syn_st3 = NULL;
	ub4		syn_ln1, syn_ln2, syn_ln3;

	Tcl_DString	tblStr, resStr;
	Tcl_Obj		*tmp_obj;

	OCIParam	*parmp, *collst, *parmh;
	ub2		numcols;
	int		pos;

	OratclDesc	column;

	int		tcl_return = TCL_OK;

	Tcl_DStringInit(&tblStr);
	Tcl_DStringInit(&resStr);

	/* Initialize the column structure */
	column.typecode = 0;
	Tcl_DStringInit(&column.typename);
	column.size = 0;
	column.name = NULL;
	column.namesz = 0;
	column.prec = 0;
	column.scale = 0;
	column.nullok = 0;
	column.valuep = NULL;
	column.valuesz	= 0;

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

	rc = OCI_HandleAlloc((dvoid *) LogPtr->envhp,
			     (dvoid *) &dschp,
			     (ub4) OCI_HTYPE_DESCRIBE,
			     (size_t) 0,
			     (dvoid **) 0);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);

	if (rc != OCI_SUCCESS) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": handle allocation failed",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	tmp_str = Tcl_GetStringFromObj(objv[2], &tmp_len);
	if (tmp_str == NULL) {
		fprintf(stderr, "error:: tmp_str is NULL return -1\n");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}
	Tcl_DStringAppend(&tblStr, tmp_str, tmp_len);

	rc = OCI_DescribeAny(LogPtr->svchp,
			     LogPtr->errhp,
			     (dvoid *) tblStr.string,
			     (ub4) tblStr.length,
			     OCI_OTYPE_NAME,
			     (ub1)0,
			     OCI_PTYPE_TABLE,
			     dschp);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);

	/* check for a view */
	if (LogPtr->ora_rc == 4043) {

		rc = OCI_DescribeAny(LogPtr->svchp,
				     LogPtr->errhp,
				     (dvoid *) tblStr.string,
				     (ub4) tblStr.length,
				     OCI_OTYPE_NAME,
				     (ub1)0,
				     OCI_PTYPE_VIEW,
				     dschp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
	}

	/* check for a private synonym */
	while (LogPtr->ora_rc == 4043) {

		rc = OCI_AttrSet((dvoid *) dschp,
				 (ub4) OCI_HTYPE_DESCRIBE,
				 (dvoid *) NULL,
				 (ub4) 0,
				 (ub4) OCI_ATTR_DESC_PUBLIC,
				 (OCIError *) LogPtr->errhp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		rc = OCI_DescribeAny(LogPtr->svchp,
				     LogPtr->errhp,
				     (dvoid *) tblStr.string,
				     (ub4) tblStr.length,
				     OCI_OTYPE_NAME,
				     (ub1)0,
				     OCI_PTYPE_SYN,
				     dschp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		/* get the parameter descriptor */
		rc = OCI_AttrGet((dvoid *)dschp,
				 (ub4)OCI_HTYPE_DESCRIBE,
				 (dvoid *) &parmp,
				 (ub4 *)0,
				 (ub4)OCI_ATTR_PARAM,
				 (OCIError *)LogPtr->errhp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		Tcl_DStringInit(&tblStr);

		/* retrieve the synonym schema name attribute */
		tmp_str = NULL;
		rc = OCI_AttrGet((dvoid*) parmp,
				 (ub4) OCI_DTYPE_PARAM,
				 (dvoid*) &syn_st1,
				 (ub4 *) &syn_ln1,
				 (ub4) OCI_ATTR_SCHEMA_NAME,
				 (OCIError *)LogPtr->errhp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (syn_st1) {
			Tcl_DStringAppend(&tblStr, (char *) syn_st1, syn_ln1);
			Tcl_DStringAppend(&tblStr, ".", 1);
		}

		/* retrieve the synonym name attribute */
		rc = OCI_AttrGet((dvoid*) parmp,
				 (ub4) OCI_DTYPE_PARAM,
				 (dvoid*) &syn_st2,
				 (ub4 *) &syn_ln2,
				 (ub4) OCI_ATTR_NAME,
				 (OCIError *)LogPtr->errhp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (syn_st2) {
			Tcl_DStringAppend(&tblStr, (char *) syn_st2, syn_ln2);
		}

		/* retrieve the synonym dblink attribute */
		rc = OCI_AttrGet((dvoid*) parmp,
				 (ub4) OCI_DTYPE_PARAM,
				 (dvoid*) &syn_st3,
				 (ub4 *) &syn_ln3,
				 (ub4) OCI_ATTR_LINK,
				 (OCIError *)LogPtr->errhp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (syn_st3) {
			Tcl_DStringAppend(&tblStr, "@", 1);
			Tcl_DStringAppend(&tblStr, (char *) syn_st3, syn_ln3);
		}

		/* describe the table pointed to by the synonym */
		rc = OCI_DescribeAny(LogPtr->svchp,
				     LogPtr->errhp,
				     (dvoid *)tblStr.string,
				     (ub4) tblStr.length,
				     OCI_OTYPE_NAME,
				     (ub1)0,
				     OCI_PTYPE_TABLE,
				     dschp);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);

	}

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* get the parameter descriptor */
	rc = OCI_AttrGet((dvoid *)dschp,
			 (ub4)OCI_HTYPE_DESCRIBE,
			 (dvoid *) &parmp,
			 (ub4 *)0,
			 (ub4)OCI_ATTR_PARAM,
			 (OCIError *)LogPtr->errhp);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);
	if (rc != OCI_SUCCESS) {
		Oratcl_ErrorMsg(interp, objv[0], " error ", objv[1], (char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* number of columns */
	rc = OCI_AttrGet((dvoid*) parmp,
			 (ub4) OCI_DTYPE_PARAM,
			 (dvoid*) &numcols,
			 (ub4 *) 0,
			 (ub4) OCI_ATTR_NUM_COLS,
			 (OCIError *)LogPtr->errhp);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);
	if (rc != OCI_SUCCESS) {
		Oratcl_ErrorMsg(interp, objv[0], " error ", objv[1], (char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* column list of the table */
	rc = OCI_AttrGet((dvoid*) parmp,
			 (ub4) OCI_DTYPE_PARAM,
			 (dvoid*) &collst,
			 (ub4 *) 0,
			 (ub4) OCI_ATTR_LIST_COLUMNS,
			 (OCIError *)LogPtr->errhp);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&LogPtr->ora_rc,
			&LogPtr->ora_err);
	if (rc != OCI_SUCCESS) {
		Oratcl_ErrorMsg(interp, objv[0], " error ", objv[1], (char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* now describe each column */
	for (pos = 1; pos <= numcols; pos++) {

		/* get the parameter descriptor for each column */
		rc = OCI_ParamGet((dvoid *)collst,
				  (ub4)OCI_DTYPE_PARAM,
				  LogPtr->errhp,
				  (dvoid *)&parmh,
				  (ub4) pos);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				0,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			Oratcl_ErrorMsg(interp, objv[0], " error ", objv[1], (char *) NULL);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		Tcl_DStringSetLength(&column.typename, 0);

		rc = Oratcl_Attributes(interp, LogPtr->errhp, parmh, &column, 1);
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			Oratcl_ErrorMsg(interp, objv[0], " error ", objv[1], (char *) NULL);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		Tcl_DStringStartSublist(&resStr);
		Tcl_DStringAppendElement(&resStr,
					 (char *) column.name);

		tmp_obj = Tcl_NewIntObj(column.size);
		Tcl_IncrRefCount(tmp_obj);
		Tcl_DStringAppendElement(&resStr,
					  Tcl_GetStringFromObj(tmp_obj, NULL));
		Tcl_DecrRefCount(tmp_obj);

		Tcl_DStringAppendElement(&resStr,
					  Tcl_DStringValue(&column.typename));

		tmp_obj = Tcl_NewIntObj(column.prec);
		Tcl_IncrRefCount(tmp_obj);
		Tcl_DStringAppendElement(&resStr,
					  Tcl_GetStringFromObj(tmp_obj, NULL));
		Tcl_DecrRefCount(tmp_obj);

		tmp_obj = Tcl_NewIntObj(column.scale);
		Tcl_IncrRefCount(tmp_obj);
		Tcl_DStringAppendElement(&resStr,
					  Tcl_GetStringFromObj(tmp_obj, NULL));
		Tcl_DecrRefCount(tmp_obj);

		tmp_obj = Tcl_NewIntObj(column.nullok);
		Tcl_IncrRefCount(tmp_obj);
		Tcl_DStringAppendElement(&resStr,
					  Tcl_GetStringFromObj(tmp_obj, NULL));
		Tcl_DecrRefCount(tmp_obj);

		Tcl_DStringEndSublist(&resStr);

		ckfree((char *)column.name);
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(resStr.string, resStr.length));

common_exit:

	(void) OCI_HandleFree((dvoid *) dschp,
			      (ub4) OCI_HTYPE_DESCRIBE);

	Tcl_DStringFree(&tblStr);
	Tcl_DStringFree(&resStr);

	return tcl_return;
}
