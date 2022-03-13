/*
 * orainfo.c
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
 * Oratcl_Info --
 *    Implements the orainfo command:
 *    usage: orainfo lda_handle
 *
 *    results:
 *	server information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_Info (clientData, interp, objc, objv)
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
	char		*logHashKey;

	sword		rc;
	static text	svr[ORA_MSG_SIZE];

	/* note that 'loginhandle' is a typo.  This will be deprecated in the next version */

	static CONST84 char *options[] = {"server",
				   "client",
				   "status",
				   "version",
				   "release",
				   "logonhandle",
				   "loginhandle",
				   "nlsgetinfo",
				   NULL};

	enum		optindex {OPT_SERVER,
				  OPT_CLIENT,
				  OPT_STATUS,
				  OPT_VERSION,
				  OPT_RELEASE,
				  OPT_LOGONHANDLE,
				  OPT_LOGINHANDLE,
				  OPT_NLSGETINFO};

	int		index = 0;

	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp, objc, objv, "option ?args?");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	if (Tcl_GetIndexFromObj(interp,
				objv[1],
				(CONST84 char **)options,
				"option",
				0,
				&index)) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	if (index == OPT_VERSION) {
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PACKAGE_VERSION, -1));
	}

	if (index == OPT_STATUS) {
		ub4		serverStatus = 0;

		if (objc < 3) {
			Tcl_WrongNumArgs(interp, objc, objv, "lda_handle");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
					       Tcl_GetStringFromObj(objv[2],
								    NULL));

		if (logHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": lda_handle ",
					objv[2],
					" not valid");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);

		rc = OCI_AttrGet (LogPtr->srvhp,
				 OCI_HTYPE_SERVER,
				 (dvoid *)&serverStatus,
				 (ub4 *) 0,
				 OCI_ATTR_SERVER_STATUS,
				 LogPtr->errhp);

		switch (serverStatus) {
		case OCI_SERVER_NORMAL:
			Tcl_SetObjResult(interp, Tcl_NewIntObj(OCI_SERVER_NORMAL));
			break;
		case OCI_SERVER_NOT_CONNECTED:
			Tcl_SetObjResult(interp, Tcl_NewIntObj(OCI_SERVER_NOT_CONNECTED));
			break;
		default:
			Oratcl_ErrorMsg(interp,
					objv[0],
					": server status request failed",
					(Tcl_Obj *) NULL,
					(char *) NULL);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
	}

	if (index == OPT_SERVER) {
		if (objc < 3) {
			Tcl_WrongNumArgs(interp, objc, objv, "lda_handle");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
					       Tcl_GetStringFromObj(objv[2],
								    NULL));

		if (logHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": lda_handle ",
					objv[2],
					" not valid");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);
		Tcl_DStringInit(&LogPtr->ora_err);

		rc = OCI_ServerVersion(LogPtr->svchp,
				       LogPtr->errhp,
				       (text *) &svr,
				       ORA_MSG_SIZE,
				       OCI_HTYPE_SVCCTX);


		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&LogPtr->ora_rc,
					&LogPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
		Tcl_SetObjResult(interp, Tcl_NewStringObj((char *) svr, -1));

	}

	if (index == OPT_RELEASE) {
		OraText	rlsbuff[OCI_NLS_MAXBUFSZ];
		ub4	*rlsnumb = 0;
		long	major_version = 0;
		long	minor_version = 0;
		long 	update_num = 0;
		long	patch_num = 0;
		long	port_update_num = 0;

		if (objc < 3) {
			Tcl_WrongNumArgs(interp, objc, objv, "lda_handle");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
					       Tcl_GetStringFromObj(objv[2],
								    NULL));

		if (logHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": lda_handle ",
					objv[2],
					" not valid");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);
		Tcl_DStringInit(&LogPtr->ora_err);

		rc = OCI_ServerRelease(LogPtr->svchp,
				       LogPtr->errhp,
				       rlsbuff,
				       (size_t) OCI_NLS_MAXBUFSZ,
				       OCI_HTYPE_SVCCTX,
				       (ub4 *) &rlsnumb);

		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&LogPtr->ora_rc,
					&LogPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit; }

		major_version   = (((long) rlsnumb >> 24) & 0x000000FF);
		minor_version   = (((long) rlsnumb >> 20) & 0x0000000F);
		update_num      = (((long) rlsnumb >> 12) & 0x000000FF);
		patch_num       = (((long) rlsnumb >>  8) & 0x0000000F);
		port_update_num = (((long) rlsnumb >>  0) & 0x000000FF);

		sprintf( (char *) svr,
			"%d.%d.%d.%d.%d",
			(int) major_version,
			(int) minor_version,
			(int) update_num,
			(int) patch_num,
			(int) port_update_num);
		Tcl_SetObjResult(interp, Tcl_NewStringObj((char *) svr, -1));

	}


	if (index == OPT_CLIENT) {
		sword	major_version = 0;
		sword	minor_version = 0;
		sword 	update_num = 0;
		sword	patch_num = 0;
		sword	port_update_num = 0;

		if (OCI_ClientVersion != NULL) {
			rc = OCI_ClientVersion(&major_version,
					       &minor_version,
					       &update_num,
					       &patch_num,
					       &port_update_num);
		}
		sprintf( (char *) svr,
			"%d.%d.%d.%d.%d",
			(int) major_version,
			(int) minor_version,
			(int) update_num,
			(int) patch_num,
			(int) port_update_num);
		Tcl_SetObjResult(interp, Tcl_NewStringObj((char *) svr, -1));

	}

	if (index == OPT_LOGONHANDLE || index == OPT_LOGINHANDLE) {
		if (objc < 3) {
			Tcl_WrongNumArgs(interp, objc, objv, "stm_handle");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
					       Tcl_GetStringFromObj(objv[2],
								    NULL));

		if (stmHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": stm_handle ",
					objv[2],
					" not open");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
		logHashKey = Tcl_GetHashKey(OratclStatePtr->logHash,
					    StmPtr->logHashPtr);
		Tcl_SetObjResult(interp, Tcl_NewStringObj((char *) logHashKey, -1));
	}

	if (index == OPT_NLSGETINFO) {
		OraText	nlsbuff[OCI_NLS_MAXBUFSZ];
		sb4	*nlsnumb = NULL;
		ub2	nlscode = 0;
		ub2	nlsproc = 0;
		int	nlsindex = 0;


		enum	nlsoptindex {
			OPT_NLS_DAYNAME1,
			OPT_NLS_DAYNAME2,
			OPT_NLS_DAYNAME3,
			OPT_NLS_DAYNAME4,
			OPT_NLS_DAYNAME5,
			OPT_NLS_DAYNAME6,
			OPT_NLS_DAYNAME7,
			OPT_NLS_ABDAYNAME1,
			OPT_NLS_ABDAYNAME2,
			OPT_NLS_ABDAYNAME3,
			OPT_NLS_ABDAYNAME4,
			OPT_NLS_ABDAYNAME5,
			OPT_NLS_ABDAYNAME6,
			OPT_NLS_ABDAYNAME7,
			OPT_NLS_MONTHNAME1,
			OPT_NLS_MONTHNAME2,
			OPT_NLS_MONTHNAME3,
			OPT_NLS_MONTHNAME4,
			OPT_NLS_MONTHNAME5,
			OPT_NLS_MONTHNAME6,
			OPT_NLS_MONTHNAME7,
			OPT_NLS_MONTHNAME8,
			OPT_NLS_MONTHNAME9,
			OPT_NLS_MONTHNAME10,
			OPT_NLS_MONTHNAME11,
			OPT_NLS_MONTHNAME12,
			OPT_NLS_ABMONTHNAME1,
			OPT_NLS_ABMONTHNAME2,
			OPT_NLS_ABMONTHNAME3,
			OPT_NLS_ABMONTHNAME4,
			OPT_NLS_ABMONTHNAME5,
			OPT_NLS_ABMONTHNAME6,
			OPT_NLS_ABMONTHNAME7,
			OPT_NLS_ABMONTHNAME8,
			OPT_NLS_ABMONTHNAME9,
			OPT_NLS_ABMONTHNAME10,
			OPT_NLS_ABMONTHNAME11,
			OPT_NLS_ABMONTHNAME12,
			OPT_NLS_YES,
			OPT_NLS_NO,
			OPT_NLS_AM,
			OPT_NLS_PM,
			OPT_NLS_AD,
			OPT_NLS_BC,
			OPT_NLS_DECIMAL,
			OPT_NLS_GROUP,
			OPT_NLS_DEBIT,
			OPT_NLS_CREDIT,
			OPT_NLS_DATEFORMAT,
			OPT_NLS_INT_CURRENCY,
			OPT_NLS_DUAL_CURRENCY,
			OPT_NLS_LOC_CURRENCY,
			OPT_NLS_LANGUAGE,
			OPT_NLS_ABLANGUAGE,
			OPT_NLS_TERRITORY,
			OPT_NLS_CHARACTER_SET,
			OPT_NLS_LINGUISTIC_NAME,
			OPT_NLS_CALENDAR,
#if 0
			OPT_NLS_WRITING_DIR,
#endif
			OPT_NLS_ABTERRITORY,
			OPT_NLS_DDATEFORMAT,
			OPT_NLS_DTIMEFORMAT,
			OPT_NLS_SFDATEFORMAT,
			OPT_NLS_SFTIMEFORMAT,
			OPT_NLS_NUMGROUPING,
			OPT_NLS_LISTSEP,
			OPT_NLS_MONDECIMAL,
			OPT_NLS_MONGROUP,
			OPT_NLS_MONGROUPING,
			OPT_NLS_INT_CURRENCYSEP,
			OPT_NLS_CHARSET_MAXBYTESZ,
			OPT_NLS_CHARSET_FIXEDWIDTH
		};

		static CONST84 char *nlsoptions[] = {
			"NLS_DAYNAME1",
			"NLS_DAYNAME2",
			"NLS_DAYNAME3",
			"NLS_DAYNAME4",
			"NLS_DAYNAME5",
			"NLS_DAYNAME6",
			"NLS_DAYNAME7",
			"NLS_ABDAYNAME1",
			"NLS_ABDAYNAME2",
			"NLS_ABDAYNAME3",
			"NLS_ABDAYNAME4",
			"NLS_ABDAYNAME5",
			"NLS_ABDAYNAME6",
			"NLS_ABDAYNAME7",
			"NLS_MONTHNAME1",
			"NLS_MONTHNAME2",
			"NLS_MONTHNAME3",
			"NLS_MONTHNAME4",
			"NLS_MONTHNAME5",
			"NLS_MONTHNAME6",
			"NLS_MONTHNAME7",
			"NLS_MONTHNAME8",
			"NLS_MONTHNAME9",
			"NLS_MONTHNAME10",
			"NLS_MONTHNAME11",
			"NLS_MONTHNAME12",
			"NLS_ABMONTHNAME1",
			"NLS_ABMONTHNAME2",
			"NLS_ABMONTHNAME3",
			"NLS_ABMONTHNAME4",
			"NLS_ABMONTHNAME5",
			"NLS_ABMONTHNAME6",
			"NLS_ABMONTHNAME7",
			"NLS_ABMONTHNAME8",
			"NLS_ABMONTHNAME9",
			"NLS_ABMONTHNAME10",
			"NLS_ABMONTHNAME11",
			"NLS_ABMONTHNAME12",
			"NLS_YES",
			"NLS_NO",
			"NLS_AM",
			"NLS_PM",
			"NLS_AD",
			"NLS_BC",
			"NLS_DECIMAL",
			"NLS_GROUP",
			"NLS_DEBIT",
			"NLS_CREDIT",
			"NLS_DATEFORMAT",
			"NLS_INT_CURRENCY",
			"NLS_DUAL_CURRENCY",
			"NLS_LOC_CURRENCY",
			"NLS_LANGUAGE",
			"NLS_ABLANGUAGE",
			"NLS_TERRITORY",
			"NLS_CHARACTER_SET",
			"NLS_LINGUISTIC_NAME",
			"NLS_CALENDAR",
#if 0
			"NLS_WRITING_DIR",
#endif
			"NLS_ABTERRITORY",
			"NLS_DDATEFORMAT",
			"NLS_DTIMEFORMAT",
			"NLS_SFDATEFORMAT",
			"NLS_SFTIMEFORMAT",
			"NLS_NUMGROUPING",
			"NLS_LISTSEP",
			"NLS_MONDECIMAL",
			"NLS_MONGROUP",
			"NLS_MONGROUPING",
			"NLS_INT_CURRENCYSEP",
			"NLS_CHARSET_MAXBYTESZ",
			"NLS_CHARSET_FIXEDWIDTH",
			NULL
		};

		if (objc < 4) {
			Tcl_WrongNumArgs(interp, objc, objv, "lda_handle nls_parameter");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		logHashPtr = Tcl_FindHashEntry(OratclStatePtr->logHash,
					       Tcl_GetStringFromObj(objv[2],
								    NULL));

		if (logHashPtr == NULL) {
			Oratcl_ErrorMsg(interp,
					objv[0],
					": lda_handle ",
					objv[2],
					" not valid");
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);


		if (Tcl_GetIndexFromObj(interp,
					objv[3],
					(CONST84 char **)nlsoptions,
					"nlsdata",
					0,
					&nlsindex)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		nlsproc = 0;
		switch (nlsindex) {
			case OPT_NLS_DAYNAME1:
				nlscode = OCI_NLS_DAYNAME1;
				break;
			case OPT_NLS_DAYNAME2:
				nlscode = OCI_NLS_DAYNAME2;
				break;
			case OPT_NLS_DAYNAME3:
				nlscode = OCI_NLS_DAYNAME3;
				break;
			case OPT_NLS_DAYNAME4:
				nlscode = OCI_NLS_DAYNAME4;
				break;
			case OPT_NLS_DAYNAME5:
				nlscode = OCI_NLS_DAYNAME5;
				break;
			case OPT_NLS_DAYNAME6:
				nlscode = OCI_NLS_DAYNAME6;
				break;
			case OPT_NLS_DAYNAME7:
				nlscode = OCI_NLS_DAYNAME7;
				break;
			case OPT_NLS_ABDAYNAME1:
				nlscode = OCI_NLS_ABDAYNAME1;
				break;
			case OPT_NLS_ABDAYNAME2:
				nlscode = OCI_NLS_ABDAYNAME2;
				break;
			case OPT_NLS_ABDAYNAME3:
				nlscode = OCI_NLS_ABDAYNAME3;
				break;
			case OPT_NLS_ABDAYNAME4:
				nlscode = OCI_NLS_ABDAYNAME4;
				break;
			case OPT_NLS_ABDAYNAME5:
				nlscode = OCI_NLS_ABDAYNAME5;
				break;
			case OPT_NLS_ABDAYNAME6:
				nlscode = OCI_NLS_ABDAYNAME6;
				break;
			case OPT_NLS_ABDAYNAME7:
				nlscode = OCI_NLS_ABDAYNAME7;
				break;
			case OPT_NLS_MONTHNAME1:
				nlscode = OCI_NLS_MONTHNAME1;
				break;
			case OPT_NLS_MONTHNAME2:
				nlscode = OCI_NLS_MONTHNAME2;
				break;
			case OPT_NLS_MONTHNAME3:
				nlscode = OCI_NLS_MONTHNAME3;
				break;
			case OPT_NLS_MONTHNAME4:
				nlscode = OCI_NLS_MONTHNAME4;
				break;
			case OPT_NLS_MONTHNAME5:
				nlscode = OCI_NLS_MONTHNAME5;
				break;
			case OPT_NLS_MONTHNAME6:
				nlscode = OCI_NLS_MONTHNAME6;
				break;
			case OPT_NLS_MONTHNAME7:
				nlscode = OCI_NLS_MONTHNAME7;
				break;
			case OPT_NLS_MONTHNAME8:
				nlscode = OCI_NLS_MONTHNAME8;
				break;
			case OPT_NLS_MONTHNAME9:
				nlscode = OCI_NLS_MONTHNAME9;
				break;
			case OPT_NLS_MONTHNAME10:
				nlscode = OCI_NLS_MONTHNAME10;
				break;
			case OPT_NLS_MONTHNAME11:
				nlscode = OCI_NLS_MONTHNAME11;
				break;
			case OPT_NLS_MONTHNAME12:
				nlscode = OCI_NLS_MONTHNAME12;
				break;
			case OPT_NLS_ABMONTHNAME1:
				nlscode = OCI_NLS_ABMONTHNAME1;
				break;
			case OPT_NLS_ABMONTHNAME2:
				nlscode = OCI_NLS_ABMONTHNAME2;
				break;
			case OPT_NLS_ABMONTHNAME3:
				nlscode = OCI_NLS_ABMONTHNAME3;
				break;
			case OPT_NLS_ABMONTHNAME4:
				nlscode = OCI_NLS_ABMONTHNAME4;
				break;
			case OPT_NLS_ABMONTHNAME5:
				nlscode = OCI_NLS_ABMONTHNAME5;
				break;
			case OPT_NLS_ABMONTHNAME6:
				nlscode = OCI_NLS_ABMONTHNAME6;
				break;
			case OPT_NLS_ABMONTHNAME7:
				nlscode = OCI_NLS_ABMONTHNAME7;
				break;
			case OPT_NLS_ABMONTHNAME8:
				nlscode = OCI_NLS_ABMONTHNAME8;
				break;
			case OPT_NLS_ABMONTHNAME9:
				nlscode = OCI_NLS_ABMONTHNAME9;
				break;
			case OPT_NLS_ABMONTHNAME10:
				nlscode = OCI_NLS_ABMONTHNAME10;
				break;
			case OPT_NLS_ABMONTHNAME11:
				nlscode = OCI_NLS_ABMONTHNAME11;
				break;
			case OPT_NLS_ABMONTHNAME12:
				nlscode = OCI_NLS_ABMONTHNAME12;
				break;
			case OPT_NLS_YES:
				nlscode = OCI_NLS_YES;
				break;
			case OPT_NLS_NO:
				nlscode = OCI_NLS_NO;
				break;
			case OPT_NLS_AM:
				nlscode = OCI_NLS_AM;
				break;
			case OPT_NLS_PM:
				nlscode = OCI_NLS_PM;
				break;
			case OPT_NLS_AD:
				nlscode = OCI_NLS_AD;
				break;
			case OPT_NLS_BC:
				nlscode = OCI_NLS_BC;
				break;
			case OPT_NLS_DECIMAL:
				nlscode = OCI_NLS_DECIMAL;
				break;
			case OPT_NLS_GROUP:
				nlscode = OCI_NLS_GROUP;
				break;
			case OPT_NLS_DEBIT:
				nlscode = OCI_NLS_DEBIT;
				break;
			case OPT_NLS_CREDIT:
				nlscode = OCI_NLS_CREDIT;
				break;
			case OPT_NLS_DATEFORMAT:
				nlscode = OCI_NLS_DATEFORMAT;
				break;
			case OPT_NLS_INT_CURRENCY:
				nlscode = OCI_NLS_INT_CURRENCY;
				break;
			case OPT_NLS_DUAL_CURRENCY:
				nlscode = OCI_NLS_DUAL_CURRENCY;
				break;
			case OPT_NLS_LOC_CURRENCY:
				nlscode = OCI_NLS_LOC_CURRENCY;
				break;
			case OPT_NLS_LANGUAGE:
				nlscode = OCI_NLS_LANGUAGE;
				break;
			case OPT_NLS_ABLANGUAGE:
				nlscode = OCI_NLS_ABLANGUAGE;
				break;
			case OPT_NLS_TERRITORY:
				nlscode = OCI_NLS_TERRITORY;
				break;
			case OPT_NLS_CHARACTER_SET:
				nlscode = OCI_NLS_CHARACTER_SET;
				break;
			case OPT_NLS_LINGUISTIC_NAME:
				nlscode = OCI_NLS_LINGUISTIC_NAME;
				break;
			case OPT_NLS_CALENDAR:
				nlscode = OCI_NLS_CALENDAR;
				break;
# if 0
			case OPT_NLS_WRITING_DIR:
				nlscode = OCI_NLS_WRITING_DIR;
				break;
# endif
			case OPT_NLS_ABTERRITORY:
				nlscode = OCI_NLS_ABTERRITORY;
				break;
			case OPT_NLS_DDATEFORMAT:
				nlscode = OCI_NLS_DDATEFORMAT;
				break;
			case OPT_NLS_DTIMEFORMAT:
				nlscode = OCI_NLS_DTIMEFORMAT;
				break;
			case OPT_NLS_SFDATEFORMAT:
				nlscode = OCI_NLS_SFDATEFORMAT;
				break;
			case OPT_NLS_SFTIMEFORMAT:
				nlscode = OCI_NLS_SFTIMEFORMAT;
				break;
			case OPT_NLS_NUMGROUPING:
				nlscode = OCI_NLS_NUMGROUPING;
				break;
			case OPT_NLS_LISTSEP:
				nlscode = OCI_NLS_LISTSEP;
				break;
			case OPT_NLS_MONDECIMAL:
				nlscode = OCI_NLS_MONDECIMAL;
				break;
			case OPT_NLS_MONGROUP:
				nlscode = OCI_NLS_MONGROUP;
				break;
			case OPT_NLS_MONGROUPING:
				nlscode = OCI_NLS_MONGROUPING;
				break;
			case OPT_NLS_INT_CURRENCYSEP:
				nlscode = OCI_NLS_INT_CURRENCYSEP;
				break;
			case OPT_NLS_CHARSET_MAXBYTESZ:
				nlscode = OCI_NLS_CHARSET_MAXBYTESZ;
				nlsproc = 1;
				break;
			case OPT_NLS_CHARSET_FIXEDWIDTH:
				nlscode = OCI_NLS_CHARSET_FIXEDWIDTH;
				nlsproc = 1;
				break;
			default:
				nlsproc = -1;
				break;
		}

		if (nlsproc == 0 && OCI_NlsGetInfo  != NULL) {
			rc = OCI_NlsGetInfo(
				(dvoid *) LogPtr->envhp,
				(OCIError *) LogPtr->errhp,
				nlsbuff,
				(size_t) OCI_NLS_MAXBUFSZ,
				(ub2) nlscode
			);
			Tcl_SetObjResult(interp, Tcl_NewStringObj((char *) nlsbuff, -1));
		}

		if (nlsproc == 1 && OCI_NlsNumericInfoGet  != NULL) {
			rc = OCI_NlsNumericInfoGet(
				(dvoid *) LogPtr->envhp,
				(OCIError *) LogPtr->errhp,
				(sb4 *) &nlsnumb,
				(ub2) nlscode
			);
			Tcl_SetObjResult(interp, Tcl_NewWideIntObj((Tcl_WideInt) nlsnumb));
		}
	}

common_exit:

	return tcl_return;
}

/*
 *----------------------------------------------------------------------
 * Oratcl_Lda_List --
 *    Implements the oraldalist command:
 *    usage: oraldalist
 *
 *    results:
 *	null string
 *      TCL_OK - list if built
 *      TCL_ERROR - wrong # args
 *----------------------------------------------------------------------
 */

int
Oratcl_Lda_List (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*logHashPtr;
	char		*logHashKey;
	Tcl_HashSearch	search;

	int		oColsc;
	int		oColslen = 0;
	Tcl_Obj		**oColsv = NULL;

	int		tcl_return = TCL_OK;

	/* Preallocate some list elements */
	if (oColsv == NULL) {
		oColslen = 10;
		oColsv = (Tcl_Obj **) ckalloc (oColslen * sizeof(*oColsv));
	}

	oColsc = 0;

	logHashPtr = Tcl_FirstHashEntry(OratclStatePtr->logHash, &search);
	while (logHashPtr != NULL) {
		logHashKey = Tcl_GetHashKey(OratclStatePtr->logHash, logHashPtr);
		if (oColsc >= oColslen) {
			oColslen += 10;
			oColsv = (Tcl_Obj **) ckrealloc ((char *) oColsv, oColslen * sizeof(*oColsv));
		}
		oColsv[oColsc++] = Tcl_NewStringObj(logHashKey, -1);
		logHashPtr = Tcl_NextHashEntry(&search);
	}

	Tcl_SetObjResult(interp, Tcl_NewListObj(oColsc, oColsv));

	if (oColsv)
		ckfree((char *) oColsv);

	return tcl_return;
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Stm_List --
 *    Implements the orastmlist command:
 *    usage: orastmlist lda_handle
 *
 *    results:
 *	null string
 *      TCL_OK - list if built
 *      TCL_ERROR - wrong # args
 *----------------------------------------------------------------------
 */

int
Oratcl_Stm_List (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	OratclLogs	*LogPtr;
	OratclStms	*StmPtr;
	Tcl_HashEntry	*logHashPtr;
	Tcl_HashEntry	*stmHashPtr;
	char		*stmHashKey;
	Tcl_HashSearch	search;

	int		oColsc;
	int		oColslen = 0;
	Tcl_Obj		**oColsv = NULL;

	int		tcl_return = TCL_OK;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp, objc, objv, "lda_handle");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* Preallocate some list elements */
	if (oColsv == NULL) {
		oColslen = 10;
		oColsv = (Tcl_Obj **) ckalloc (oColslen * sizeof(*oColsv));
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

	/* NOTE :: rebuild using Tcl_DString */
	oColsc = 0;
	stmHashPtr = Tcl_FirstHashEntry(OratclStatePtr->stmHash, &search);
	while (stmHashPtr != NULL) {
		StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
		if (StmPtr->logid == LogPtr->logid) {
			stmHashKey = Tcl_GetHashKey(OratclStatePtr->stmHash, stmHashPtr);
			if (oColsc >= oColslen) {
				oColslen += 10;
				oColsv = (Tcl_Obj **) ckrealloc ((char *) oColsv, oColslen * sizeof(*oColsv));
			}
			oColsv[oColsc++] = Tcl_NewStringObj(stmHashKey, -1);
		}
		stmHashPtr = Tcl_NextHashEntry(&search);
	}

	Tcl_SetObjResult(interp, Tcl_NewListObj(oColsc, oColsv));

common_exit:

	if (oColsv)
		ckfree((char *) oColsv);

	return tcl_return;
}
