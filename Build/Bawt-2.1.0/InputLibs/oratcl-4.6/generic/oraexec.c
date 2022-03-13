/*
 * oraexec.c
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

#include "oratclInt.h"
#include "oratclTypes.h"
#include "oratclExtern.h"

/*
 *----------------------------------------------------------------------
 * Oratcl_Exec --
 *    Implements the oraexec command:
 *    usage: oraexec stm_handle
 *    usage: ::oratcl::oraexec stm_handle
 *
 *    results:
 *	return code from OCI_StmtExecute
 *      TCL_OK - execution successful
 *      TCL_ERROR - wrong # args, handle not opened, or OCI error
 *----------------------------------------------------------------------
 */

int
Oratcl_Exec (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;
	OratclStms	*RefPtr;
	OratclCols	*tmp_col;

	char		*p;
	ub4		oci_mode = OCI_DEFAULT;
	ub4		rowcnt;
	sword		rc;
	int		ca = 0;

	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle ?-commit?");
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

	/* cause first orafetch to fetch */
	StmPtr->fetchidx   = StmPtr->fetchmem;
	StmPtr->fetch_end = 0;		/* try to fetch */
	StmPtr->fetch_cnt = 0;		/* start fetch cnt at zero */
	StmPtr->append_cnt = 0;		/* start append cnt at zero */

	if (StmPtr->sqltype == OCI_STMT_SELECT) {
		StmPtr->iters = 0;
	} else if (!StmPtr->array_dml) {
		StmPtr->iters = 1;
	}

	/* check for option and deprecated keywords */
	if (objc >= 3) {
		p = Tcl_GetStringFromObj(objv[2], (int *) NULL);
		if (*p == '-') {
			p++;
		}
		if (strcmp(p,"commit") == 0) {
			oci_mode = oci_mode | OCI_COMMIT_ON_SUCCESS;
		}
	}

	if (LogPtr->autocom) {
		oci_mode = oci_mode | OCI_COMMIT_ON_SUCCESS;
	}

	if (StmPtr->array_dml) {
		oci_mode = oci_mode | OCI_BATCH_ERRORS;
	}

	rc = OCI_StmtExecute(LogPtr->svchp,
			     StmPtr->stmhp,
			     LogPtr->errhp,
			     (ub4) StmPtr->iters,
			     (ub4) 0,
			     (OCISnapshot *) NULL,
			     (OCISnapshot *) NULL,
			     oci_mode);

	StmPtr->ora_rc = rc;

	if (rc == OCI_STILL_EXECUTING) {
		Tcl_SetObjResult(interp, Tcl_NewIntObj(rc));
		if (LogPtr->async == 1) {
			tcl_return = TCL_OK;
		} else {
			tcl_return = TCL_ERROR;
		}
		goto common_exit;
	}

	if (rc != OCI_SUCCESS && StmPtr->array_dml) {
		int num_errs;

		OCI_AttrGet (StmPtr->stmhp, 
			     OCI_HTYPE_STMT, 
			     (sb4 *) &num_errs, 
			     0,
			     OCI_ATTR_NUM_DML_ERRORS, 
			     LogPtr->errhp);

		if (num_errs) {
			OCIError	*tmp_errhp;
			int		row_offset;
			static char	errbuf[ORA_MSG_SIZE];
			ub4		i;
			sb4		errcode = 0;
			Tcl_Obj		*err_list;

			(void) OCI_HandleAlloc((dvoid *) LogPtr->envhp,
					       (dvoid **) (dvoid *) &tmp_errhp,
					       OCI_HTYPE_ERROR,
					       (size_t) 0,
					       (dvoid **) 0);

			err_list = Tcl_NewListObj(0, NULL);
			Tcl_IncrRefCount(err_list);
		
			for (i=0; i<num_errs; i++) {
				Tcl_Obj		*err;
				err = Tcl_NewListObj(0, NULL);

				OCI_ParamGet(LogPtr->errhp, 
					     OCI_HTYPE_ERROR, 
					     LogPtr->errhp, 
					     (dvoid *)&tmp_errhp, 
					     i);

				OCI_AttrGet (tmp_errhp, 
					     OCI_HTYPE_ERROR, 
					     &row_offset,
					     0, 
					     OCI_ATTR_DML_ROW_OFFSET, 
					     LogPtr->errhp);
						  
				OCI_ErrorGet ((dvoid *) tmp_errhp,
					      (ub4) 1,
					      (text *) NULL,
					      &errcode,
					      (text *) errbuf,
					      (ub4) sizeof(errbuf),
					      (ub4) OCI_HTYPE_ERROR);

				Tcl_ListObjAppendElement(interp, err, Tcl_NewIntObj(row_offset));
				Tcl_ListObjAppendElement(interp, err, Tcl_NewIntObj(errcode));
				Tcl_ListObjAppendElement(interp, err, Tcl_NewStringObj(errbuf, sizeof(errbuf)));
				Tcl_ListObjAppendElement(interp, err_list, err);
			}                      

                        Oratcl_Checkerr(interp,
                                        LogPtr->errhp,
                                        rc,
                                        1,
                                        &StmPtr->ora_rc,
                                        &StmPtr->ora_err);
			Oratcl_ColFree(StmPtr->col_list);
			StmPtr->col_list = NULL;
			Oratcl_ColFree(StmPtr->bind_list);
			StmPtr->bind_list = NULL;
			StmPtr->array_dml_errors = err_list;
			(void) OCI_HandleFree((dvoid *) tmp_errhp, 
					      OCI_HTYPE_ERROR);


			tcl_return = TCL_ERROR;
			goto common_exit;
		}

	} else if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);
		Oratcl_ColFree(StmPtr->col_list);
		StmPtr->col_list = NULL;
		Oratcl_ColFree(StmPtr->bind_list);
		StmPtr->bind_list = NULL;
		tcl_return = TCL_ERROR;
		goto common_exit;
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));

	OCI_AttrGet( (dvoid *) StmPtr->stmhp,
		    (ub4) OCI_HTYPE_STMT,
		    (ub2 *) &StmPtr->ora_fcd,
		    (ub4) 0,
		    OCI_ATTR_SQLFNCODE,
		    LogPtr->errhp);

	if (StmPtr->sqltype == OCI_STMT_UPDATE ||
	    StmPtr->sqltype == OCI_STMT_DELETE ||
	    StmPtr->sqltype == OCI_STMT_INSERT ||
	    StmPtr->sqltype == OCI_STMT_MERGE) {

		rowcnt = 0;
		rc = (OCI_AttrGet( (dvoid *) StmPtr->stmhp,
				  (ub4) OCI_HTYPE_STMT,
				  (ub4 *) &rowcnt,
				  (ub4) 0,
				  OCI_ATTR_ROW_COUNT,
				  LogPtr->errhp));

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				0,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": OCIAttrGet failed",
					(Tcl_Obj *) NULL,
					(char *) NULL);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		/* set "rows" to rpc (rows processed count) */
		StmPtr->ora_row = rowcnt;
	}

	if (StmPtr->sqltype == OCI_STMT_BEGIN ||
	    StmPtr->sqltype == OCI_STMT_DECLARE) {

		if (StmPtr->bind_list) {

			/* for all ref_cursor columns, parse results */
			tmp_col = StmPtr->bind_list;
			while (tmp_col != NULL) {

				if (tmp_col->column.typecode == SQLT_CUR) {
					if (tmp_col->bindPtr != NULL) {
						RefPtr = (OratclStms *) Tcl_GetHashValue(tmp_col->bindPtr);
						Tcl_DStringInit(&RefPtr->ora_err);

						while ((rc = OCI_StmtExecute(LogPtr->svchp,
									     RefPtr->stmhp,
									     LogPtr->errhp,
									     (ub4) 0,
									     (ub4) 0,
									     (OCISnapshot *) NULL,
									     (OCISnapshot *) NULL,
									     OCI_DESCRIBE_ONLY)) == OCI_STILL_EXECUTING) {
							/* NULL statement */
						}

						if (rc != OCI_SUCCESS) {
#ifdef OCI_ATTR_PARSE_ERROR_OFFSET
							OCI_AttrGet( (dvoid *) RefPtr->stmhp,
								    (ub4) OCI_HTYPE_STMT,
								    (ub2 *) &RefPtr->ora_peo,
								    (ub4) 0,
								    OCI_ATTR_PARSE_ERROR_OFFSET,
								    LogPtr->errhp);
#endif
							Oratcl_Checkerr(interp,
									LogPtr->errhp,
									rc,
									1,
									&RefPtr->ora_rc,
									&RefPtr->ora_err);
							tcl_return = TCL_ERROR;
							goto common_exit;
						}

						OCI_AttrGet( (dvoid *) RefPtr->stmhp,
							    (ub4) OCI_HTYPE_STMT,
							    (ub2 *) &RefPtr->ora_fcd,
							    (ub4) 0,
							    OCI_ATTR_SQLFNCODE,
							    LogPtr->errhp);

						if (Oratcl_ColDescribe(interp, RefPtr) == -1) {
							Oratcl_ErrorMsg(interp,
									objv[0],
									": Oratcl_ColDescribe failed for ",
									(Tcl_Obj *) NULL,
									(char *) tmp_col->column.name);
							tcl_return = TCL_ERROR;
							goto common_exit;
						}
						RefPtr->append_cnt = 0;
						RefPtr->fetchidx = RefPtr->fetchmem;
						RefPtr->fetch_end = 0;
						RefPtr->fetch_cnt = 0;
					}
				}

				tmp_col = tmp_col->next;
			}

			StmPtr->fetch_end  = 0;		/* let Oratcl_ColAppend work */
			StmPtr->fetch_cnt  = 0;
			StmPtr->append_cnt = 0;
			StmPtr->fetchidx   = 0;

			/* set results, same as orafetch */
			ca = Oratcl_ColAppend(interp, StmPtr, NULL, NULL, 0);
			if (ca == -1) {
				tcl_return = TCL_ERROR;
				goto common_exit;
			}

			StmPtr->fetch_end  = 1;
			StmPtr->fetch_cnt  = 1;
			StmPtr->append_cnt = 0;
			StmPtr->fetchidx   = 0;
		}
	}

common_exit:

	return tcl_return;
}
