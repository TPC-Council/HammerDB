/*
 * orabind.c
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
#include "oratcl.h"

static sb4
Oratcl_ArrayPutElement (ictxp, bindp, iter, index, bufpp, alenp, piecep, indpp)
	dvoid	*ictxp;
	OCIBind *bindp;
	ub4	iter;
	ub4	index;
	dvoid	**bufpp;
	ub4	*alenp;
	ub1	*piecep;
	dvoid	**indpp;
{
	OratclCols *tmp_col = ictxp;
	Tcl_Obj	*element;
	
	if (Tcl_ListObjIndex(NULL, tmp_col->array_values, iter, &element) != TCL_OK) {
	  /* handle invalid list element error */
	}
	*bufpp = Tcl_GetStringFromObj(element, (int *) alenp);
	*piecep = OCI_ONE_PIECE;
	*indpp = NULL;

	if (iter == tmp_col->array_count) {
		Tcl_DecrRefCount(tmp_col->array_values);
	}

	return OCI_CONTINUE;
}
	
/*
 *----------------------------------------------------------------------
 * Oratcl_Bind --
 *    Implements the orabind command:
 *    usage: orabind stm_handle :bindname value ...
 *    usage: ::oratcl::orabind stm_handle :bindname value ...
 *
 *    results:
 *	return code from OCIBindByName
 *      TCL_OK - binding successful
 *      TCL_ERROR - wrong # args, handle not opened, or OCI error
 *----------------------------------------------------------------------
 */
int
Oratcl_Bind (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	Tcl_HashEntry	*refHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;
	OratclStms	*RefPtr = NULL;

	int		parm_cnt;
	sword		rc;
	ub2		myucs2id = OCI_UCS2ID;
	ub2		mybindmax = 0;

	OratclCols	*tmp_col_head = NULL;
	OratclCols	*tmp_col = NULL;
	OratclCols	*head_col = NULL;

	Tcl_DString	argStr;
	char		*arg_pcc = NULL;
	char		*arg_pcp = NULL;
	Tcl_UniChar	*arg_upcp = NULL;
	int		arg_pcc_len, arg_pcp_len;
	int		array_max_length = 0;
	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle [ :varname value ] ...");
		tcl_return = TCL_ERROR;
		goto common_exit;
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

	/* check for arraydml paramenter */
	parm_cnt = 2;
	if (objc >= 3) {
		char *p;
		p = Tcl_GetStringFromObj(objv[2], (int *) NULL);
		if (*p == '-') {
			p++;
		}
		if (strcmp(p, "arraydml") == 0) {
			StmPtr->array_dml = 1;
				parm_cnt = 3;
		}
	}
	if (StmPtr->array_dml &&
			(StmPtr->sqltype != OCI_STMT_UPDATE &&
			 StmPtr->sqltype != OCI_STMT_INSERT)) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": cannot use -arraydml option on non-dml statement",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}
		

	StmPtr->ora_rc  = 0;
	Tcl_DStringInit(&StmPtr->ora_err);
	StmPtr->ora_row = 0;


	/* if first time in, allocate bind_list */
	if (StmPtr->bind_list == NULL) {

		if (objc > parm_cnt + 1) {
			tmp_col_head = Oratcl_ColAlloc(StmPtr->fetchmem);
			if (tmp_col_head == NULL) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": cannot malloc new col",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			tmp_col      = tmp_col_head;
			head_col     = tmp_col_head;
			StmPtr->bind_list = tmp_col_head;
		} else {
			tmp_col_head = NULL;
		}

		while (objc > parm_cnt + 1) {       /* always in pairs of two */

			/* get two arg strings */
			arg_pcc = Tcl_GetStringFromObj(objv[parm_cnt], &arg_pcc_len);

			/* make sure bind variable name has a leading ':' */
			if (*arg_pcc != ':') {
				Oratcl_ColFree(StmPtr->col_list);
				StmPtr->col_list = NULL;
				Oratcl_ColFree(StmPtr->bind_list);
				StmPtr->bind_list = NULL;
				Oratcl_ErrorMsg(interp,
						objv[0],
						": bind variable '",
						objv[parm_cnt],
						"' does not begin with ':'");
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			

			if (StmPtr->array_dml) {
				Tcl_ListObjLength(interp, objv[parm_cnt + 1], &tmp_col->array_count);
				Tcl_IncrRefCount(objv[parm_cnt + 1]);
				tmp_col->array_values = objv[parm_cnt + 1];
				if (parm_cnt == 3) {
					StmPtr->iters=tmp_col->array_count;
				} else {
					if (StmPtr->iters != tmp_col->array_count) {
						Oratcl_ColFree(StmPtr->col_list);
						StmPtr->col_list = NULL;
						Oratcl_ColFree(StmPtr->bind_list);
						StmPtr->bind_list = NULL;
						Oratcl_ErrorMsg(interp,
								objv[0],
								": array dml columns not equal lengths",
								(Tcl_Obj *) NULL,
								(char *) NULL);
						tcl_return = TCL_ERROR;
						goto common_exit;
					}
				}
			} else {
				if (StmPtr->unicode) {
					arg_upcp = Tcl_GetUnicodeFromObj(objv[parm_cnt + 1], &arg_pcp_len);
				} else {
					arg_pcp = Tcl_GetStringFromObj(objv[parm_cnt + 1], &arg_pcp_len);
				}
			}

			refHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
						       Tcl_GetStringFromObj(objv[parm_cnt+1], NULL));
			if (refHashPtr != NULL) {
				RefPtr = (OratclStms *) Tcl_GetHashValue(refHashPtr);

				if (stmHashPtr == refHashPtr) {
					Oratcl_ColFree(tmp_col_head);
					StmPtr->bind_list = NULL;
					Oratcl_ErrorMsg(interp,
							objv[0],
							": bind cursor for ",
							objv[parm_cnt],
							" same as cursor_handle");
					tcl_return = TCL_ERROR;
					goto common_exit;
				}

				if (StmPtr->logid != LogPtr->logid) {
					Oratcl_ColFree(tmp_col_head);
					StmPtr->bind_list = NULL;
					Oratcl_ErrorMsg(interp,
							objv[0],
							": bind cursor for ",
							objv[parm_cnt],
							" not from same login handle as statement handle");
					tcl_return = TCL_ERROR;
					goto common_exit;
				}

				Oratcl_ColFree(RefPtr->col_list);
				RefPtr->col_list	= NULL;
				Oratcl_ColFree(RefPtr->bind_list);
				RefPtr->bind_list	= NULL;
				RefPtr->fetchidx	= RefPtr->fetchmem;
				RefPtr->fetch_end       = 0;    /* try to fetch */
				RefPtr->fetch_cnt       = 0;    /* start fetch cnt at zero */
				RefPtr->append_cnt      = 0;    /* start append cnt at zero */

				tmp_col->bindPtr	= refHashPtr;
			} else {
				tmp_col->bindPtr	= NULL;
			}

			if (arg_pcp_len > StmPtr->bindsize && !StmPtr->array_dml) {
				Oratcl_ColFree(StmPtr->col_list);
				StmPtr->col_list = NULL;
				Oratcl_ColFree(StmPtr->bind_list);
				StmPtr->bind_list = NULL;
				Oratcl_ErrorMsg(interp,
						objv[0],
						": bind value ",
						objv[parm_cnt+1],
						"too large for bindsize");
				tcl_return = TCL_ERROR;
				goto common_exit;
			}

			/* allocate adequate space for reuse */
			if (StmPtr->array_dml) {
				Tcl_Obj **list;
				int list_size, j, len =0;

				if (Tcl_ListObjGetElements(interp, objv[parm_cnt+1], &list_size, &list) != TCL_OK) {
					Oratcl_ColFree(StmPtr->col_list);
					StmPtr->col_list = NULL;
					Oratcl_ColFree(StmPtr->bind_list);
					StmPtr->bind_list = NULL;
					Oratcl_ErrorMsg(interp,
							objv[0],
							": invalid list",
							(Tcl_Obj *) NULL,
							(char *) NULL);
					tcl_return = TCL_ERROR;
					goto common_exit;
				}
				for (j=0; j < list_size; j++) {
					Tcl_GetStringFromObj(list[j], &len);
					if (len > array_max_length) {
						array_max_length = len;
					}
				}
			} else {

				tmp_col->column.valuesz = StmPtr->bindsize;
				if (StmPtr->unicode) {
					tmp_col->column.valuep = ckalloc((tmp_col->column.valuesz +1) * sizeof(utext));
				} else {
					tmp_col->column.valuep = ckalloc(tmp_col->column.valuesz + 1);
				}
				if (tmp_col->column.valuep == NULL) {
					Oratcl_ColFree(tmp_col_head);
					StmPtr->bind_list = NULL;
					Oratcl_ErrorMsg(interp,
							objv[0],
							": allocation failure",
							objv[parm_cnt],
							(char *) NULL);
					tcl_return = TCL_ERROR;
					goto common_exit;
				}

				if (StmPtr->utfmode) {
					Tcl_DStringInit(&argStr);
					Tcl_UtfToExternalDString(NULL,
								 arg_pcp,
								 arg_pcp_len,
								 &argStr);
					memcpy(tmp_col->column.valuep,
					       Tcl_DStringValue(&argStr),
					       Tcl_DStringLength(&argStr));
					tmp_col->column.valuep[argStr.length] = '\0';
					Tcl_DStringFree(&argStr);
				} else if (StmPtr->unicode) {
					memcpy(tmp_col->column.valuep,
					       arg_upcp,
					       ((arg_pcp_len+1)*sizeof(utext)));
					tmp_col->column.valuep[arg_pcp_len*sizeof(utext)] = L'\0';
				} else {
					memcpy(tmp_col->column.valuep,
					       arg_pcp,
					       arg_pcp_len);
					tmp_col->column.valuep[arg_pcp_len] = '\0';
				}

			}

			tmp_col->rlenp[0] = 0;
			tmp_col->rcodep[0] = 0;

			tmp_col->column.name = (text *) ckalloc(arg_pcc_len + 1);
			if (tmp_col->column.name == NULL) {
				Oratcl_ColFree(tmp_col_head);
				StmPtr->bind_list = NULL;
				Oratcl_ErrorMsg(interp,
						objv[0],
						": allocation failure",
						objv[parm_cnt+1],
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			memcpy(tmp_col->column.name, arg_pcc, arg_pcc_len);
			tmp_col->column.name[arg_pcc_len] = '\0';
			tmp_col->column.namesz = arg_pcc_len;

			tmp_col->bindp = (OCIBind *) 0;

			if (tmp_col->bindPtr == NULL) {

				/* string data type */
				tmp_col->column.typecode = SQLT_STR;

				if (StmPtr->unicode) {
					mybindmax = (ub2) (tmp_col->column.valuesz+1)*sizeof(utext);
					rc = OCI_BindByName(StmPtr->stmhp,
							    (OCIBind **) &tmp_col->bindp,
							    LogPtr->errhp,
							    (text *) tmp_col->column.name,
							    (sb4) tmp_col->column.namesz,
							    StmPtr->array_dml ? NULL : (dvoid *) tmp_col->column.valuep,
							    StmPtr->array_dml ? array_max_length + 1 : (ub4) mybindmax,
							    StmPtr->array_dml ? (ub2) SQLT_CHR : (ub2) SQLT_STR,
							    StmPtr->array_dml ? NULL : (dvoid *) &tmp_col->indp[0],
							    (ub2 *) 0,
							    (ub2 *) 0,
							    (ub4) 0,
							    (ub4 *) 0,
							    StmPtr->array_dml ? (ub4) OCI_DATA_AT_EXEC : (ub4) OCI_DEFAULT);

					if (rc != OCI_SUCCESS) {
						Oratcl_Checkerr(interp,
								LogPtr->errhp,
								rc,
								1,
								&StmPtr->ora_rc,
								&StmPtr->ora_err);
						Oratcl_ColFree(tmp_col_head);
						StmPtr->bind_list = NULL;
						tcl_return = TCL_ERROR;
						goto common_exit;
					}

					(void) OCI_AttrSet((dvoid *) tmp_col->bindp,
							  OCI_HTYPE_BIND,
							  &myucs2id,
							  0,
							  OCI_ATTR_CHARSET_ID,
							  LogPtr->errhp);
					(void) OCI_AttrSet((dvoid *) tmp_col->bindp,
							  OCI_HTYPE_BIND,
							  &mybindmax,
							  0,
							  OCI_ATTR_MAXDATA_SIZE,
							  LogPtr->errhp);

				} else {
					rc = OCI_BindByName(StmPtr->stmhp,
							    (OCIBind **) &tmp_col->bindp,
							    LogPtr->errhp,
							    (text *) tmp_col->column.name,
							    (sb4) tmp_col->column.namesz,
							    StmPtr->array_dml ? NULL : (dvoid *) tmp_col->column.valuep,
							    StmPtr->array_dml ? array_max_length + 1 : (sb4) tmp_col->column.valuesz + 1,
							    StmPtr->array_dml ? (ub2) SQLT_CHR : (ub2) SQLT_STR,
							    StmPtr->array_dml ? NULL : (dvoid *) &tmp_col->indp[0],
							    (ub2 *) 0,
							    (ub2 *) 0,
							    (ub4) 0,
							    (ub4 *) 0,
							    StmPtr->array_dml ? (ub4) OCI_DATA_AT_EXEC : (ub4) OCI_DEFAULT);

					if (StmPtr->array_dml) {
						rc = OCI_BindDynamic(tmp_col->bindp,
								      LogPtr->errhp,
								      (dvoid *) tmp_col,
								      Oratcl_ArrayPutElement,
								      (dvoid *) NULL,
								      NULL);
					}
				}

			} else {

				/* cursor data type */
				tmp_col->column.typecode = SQLT_CUR;

				rc = OCI_BindByName(StmPtr->stmhp,
						    (OCIBind **) &tmp_col->bindp,
						    LogPtr->errhp,
						    (text *) tmp_col->column.name,
						    (sb4) tmp_col->column.namesz,
						    (dvoid *) &RefPtr->stmhp,
						    (sb4) 0,
						    (ub2) SQLT_RSET,
						    (dvoid *) 0,
						    (ub2 *) 0,
						    (ub2 *) 0,
						    (ub4) 0,
						    (ub4 *) 0,
						    (ub4) OCI_DEFAULT);

			}

			if (rc != OCI_SUCCESS) {
				Oratcl_Checkerr(interp,
						LogPtr->errhp,
						rc,
						1,
						&StmPtr->ora_rc,
						&StmPtr->ora_err);
				Oratcl_ColFree(tmp_col_head);
				StmPtr->bind_list = NULL;
				tcl_return = TCL_ERROR;
				goto common_exit;
			}

			parm_cnt += 2;

			if (objc > parm_cnt + 1) {       /* more args? alloc new colbufs */
				head_col = tmp_col;
				tmp_col = Oratcl_ColAlloc(StmPtr->fetchmem);
				if (tmp_col == NULL) {
					Oratcl_ColFree(StmPtr->col_list);
					StmPtr->col_list = NULL;
					Oratcl_ColFree(StmPtr->bind_list);
					StmPtr->bind_list = NULL;
					Oratcl_ErrorMsg(interp,
						objv[0],
						": cannot malloc new col",
						(Tcl_Obj *) NULL,
						(char *) NULL);
					tcl_return = TCL_ERROR;
					goto common_exit;
				}
				head_col->next = tmp_col;
			}
		}

	} else if (!StmPtr->array_dml) {
		/* else, binds have been done, just copy in new data */
		while (objc > parm_cnt + 1) {       /* always in pairs of two */
			tmp_col = StmPtr->bind_list;
			while (tmp_col != NULL) {
				if (strncmp((char *) tmp_col->column.name, Tcl_GetStringFromObj(objv[parm_cnt], (int *) NULL), 255) == 0) {
					if (StmPtr->unicode) {
						arg_upcp = Tcl_GetUnicodeFromObj(objv[parm_cnt + 1], &arg_pcp_len);
						memcpy(tmp_col->column.valuep, arg_upcp, ((arg_pcp_len+1)*sizeof(utext)));
						tmp_col->column.valuep[arg_pcp_len*sizeof(utext)] = L'\0';
					} else {
						arg_pcp = Tcl_GetStringFromObj(objv[parm_cnt + 1], &arg_pcp_len);

						if (StmPtr->utfmode) {
							Tcl_DStringInit(&argStr);
							Tcl_UtfToExternalDString(NULL,
										 arg_pcp,
										 arg_pcp_len,
										 &argStr);
							memcpy(tmp_col->column.valuep,
							       Tcl_DStringValue(&argStr),
							       Tcl_DStringLength(&argStr));
							tmp_col->column.valuep[argStr.length] = '\0';
							Tcl_DStringFree(&argStr);
						} else {
							memcpy(tmp_col->column.valuep,
							       arg_pcp,
							       arg_pcp_len);
							tmp_col->column.valuep[arg_pcp_len] = '\0';
						}

					}

					break;
				}
				tmp_col = tmp_col->next;
			}
			parm_cnt += 2;
		}
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));

common_exit:

	return tcl_return;
}
