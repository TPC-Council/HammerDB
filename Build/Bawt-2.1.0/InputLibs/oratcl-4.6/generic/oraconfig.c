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
 * Oratcl_Config --
 *    Implements the oraconfig command:
 *    usage: oraconfig stm_handle field value
 *
 *    results:
 *	table information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_Config (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;

	static CONST84 char *options[] = {"longsize",
				   "bindsize",
				   "nullvalue",
				   "fetchrows",
				   "lobpsize",
				   "longpsize",
				   "utfmode",
				   "numbsize",
				   "datesize",
				   "unicode",
				   NULL};

	enum		optindex {OPT_LONG,
				  OPT_BIND,
				  OPT_NULL,
				  OPT_CACHE,
				  OPT_LOBP,
				  OPT_LONGP,
				  OPT_UTFMODE,
				  OPT_NUMB,
				  OPT_DATE,
				  OPT_UNICODE};
	int		optlength = 20;

	int		option;
	int		value;
	int		i;
	int		tcl_rc;

	Tcl_Obj		**infoObjv;
	int		infoObjc;

	int		tcl_return = TCL_OK;

	if ((objc < 2) || (((objc % 2) == 1) && (objc != 3))) {
		Tcl_WrongNumArgs(interp,
				 1,
				 objv,
				 "stm_handle optionName value ?optionName value? ...");
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

	if (objc == 2) {
		/* return list of alternating option names and values */
		/* should use a Tcl_DString for this */
		infoObjv = (Tcl_Obj **) ckalloc (optlength * sizeof(*infoObjv));
		infoObjc = 0;
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[0], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->longsize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[1], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->bindsize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[2], -1);
		infoObjv[infoObjc++] = Tcl_DuplicateObj(StmPtr->nullvalue);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[3], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->fetchrows);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[4], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->lobpsize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[5], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->longpsize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[6], -1);
		infoObjv[infoObjc++] = Tcl_NewBooleanObj(StmPtr->utfmode);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[7], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->numbsize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[8], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->datesize);
		infoObjv[infoObjc++] = Tcl_NewStringObj(options[9], -1);
		infoObjv[infoObjc++] = Tcl_NewIntObj(StmPtr->unicode);
		Tcl_SetObjResult(interp, Tcl_NewListObj(infoObjc, infoObjv));
		ckfree((char *) infoObjv);
		tcl_return = TCL_OK;
		goto common_exit;
	}

	if (objc == 3) {
		/* return current value of given option */
		if (Tcl_GetIndexFromObj(interp,
					objv[2],
					(CONST84 char **)options,
					"optionName",
					0,
					&option)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (option == OPT_LONG) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->longsize));
		}
		if (option == OPT_BIND) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->bindsize));
		}
		if (option == OPT_NULL) {
			Tcl_SetObjResult(interp,
					 Tcl_DuplicateObj(StmPtr->nullvalue));
		}
		if (option == OPT_CACHE) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->fetchrows));
		}
		if (option == OPT_LOBP) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->lobpsize));
		}
		if (option == OPT_LONGP) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->longpsize));
		}
		if (option == OPT_UTFMODE) {
			Tcl_SetObjResult(interp,
					 Tcl_NewBooleanObj(StmPtr->utfmode));
		}
		if (option == OPT_NUMB) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->numbsize));
		}
		if (option == OPT_DATE) {
			Tcl_SetObjResult(interp,
					 Tcl_NewIntObj(StmPtr->datesize));
		}
		if (option == OPT_UNICODE) {
			Tcl_SetObjResult(interp,
					 Tcl_NewBooleanObj(StmPtr->unicode));
		}
		tcl_return = TCL_OK;
		goto common_exit;
	}

	for (i = 3; i < objc; i += 2) {
		if (Tcl_GetIndexFromObj(interp,
					objv[i-1],
					(CONST84 char **)options,
					"optionName",
					0,
					&option)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (option == OPT_LONG) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 0 || value > MAX_LONG_SIZE) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->longsize = value;
		}
		if (option == OPT_BIND) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 0) {
#if 0
			if (tcl_rc != TCL_OK || value < 0 || value > MAX_BIND_SIZE)
#endif
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->bindsize = value;
		}
		if (option == OPT_NULL) {
			StmPtr->nullvalue = Tcl_DuplicateObj(objv[i]);
		}
		if (option == OPT_CACHE) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 0) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->fetchrows = value;
		}
		if (option == OPT_LOBP) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 0 || value > MAX_LOBP_SIZE) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->lobpsize = value;
		}
		if (option == OPT_LONGP) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 0 || value > MAX_LONGP_SIZE) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->longpsize = value;
		}
		if (option == OPT_UTFMODE) {
			tcl_rc = Tcl_GetBooleanFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->utfmode = value;
		}
		if (option == OPT_NUMB) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 1 || value > MAX_NUMB_SIZE) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->numbsize = value;
		}
		if (option == OPT_DATE) {
			tcl_rc = Tcl_GetIntFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK || value < 1 || value > MAX_DATE_SIZE) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->datesize = value;
		}
		if (option == OPT_UNICODE) {
			tcl_rc = Tcl_GetBooleanFromObj(interp, objv[i], &value);
			/* test for valid integer */
			if (tcl_rc != TCL_OK) {
				Oratcl_ErrorMsg(interp,
						objv[0],
						": invalid value",
						(Tcl_Obj *) NULL,
						(char *) NULL);
				tcl_return = TCL_ERROR;
				goto common_exit;
			}
			StmPtr->unicode = value;
		}
	}

common_exit:

	return tcl_return;
}
