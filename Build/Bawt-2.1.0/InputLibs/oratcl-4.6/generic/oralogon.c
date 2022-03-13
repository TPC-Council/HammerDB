/*
 * oralogon.c
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

sb4 callback_fn(dvoid *, dvoid *, dvoid *, ub4, ub4);


/*
 *----------------------------------------------------------------------
 * Oratcl_Logon --
 *    Implements the oralogon command:
 *    usage: oralogon connect_string ?-async? ?-failovercallback <procname>?
 *    connect_string should be a valid oracle logon string:
 *         name
 *         name/password
 *         name@d:dbname
 *         name/password@d:dbname
 *	   sysdba
 *	   sysoper
 *
 *    results:
 *	handle - a character string of newly open logon handle
 *      TCL_OK - connect successful
 *      TCL_ERROR - connect not successful - error message returned
 *----------------------------------------------------------------------
 */

int
Oratcl_Logon (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	OCIFocbkStruct	failover;
	int		i;
	Tcl_HashEntry	*logHashPtr = NULL;
	OratclLogs	*LogPtr = NULL;
	int		new;

	static char *OraHandlePrefix = "oratcl";

	int		tcl_return = TCL_OK;

	char 		*con_str = NULL;
	char		*cpy_str = NULL;
	char		*cpy_pos1 = NULL;
	char		*cpy_pos2 = NULL;
	int		con_len;
	sword		rc = 0;

	int		attached = 0;

	char		*ora_name = NULL;
	char		*ora_pass = NULL;
	char		*ora_conn = NULL;

	size_t		ora_namelen = 0;
	size_t		ora_passlen = 0;
	size_t		ora_connlen = 0;

	ub4		oci_cred = OCI_CRED_RDBMS;
	ub4		oci_conn = OCI_DEFAULT;

	char		*p = NULL;
	char		buf[25];

	if (objc < 2) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "connect_string ?-async?");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	LogPtr = (OratclLogs *) ckalloc (sizeof (OratclLogs));
	if (LogPtr == NULL) {
		fprintf(stderr, "error:: new_col->column.valuep is NULL return -1\n");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* generate an lda name and put it in the hash table. */
	OratclStatePtr->logid++;
	sprintf(buf,"%s%d",OraHandlePrefix,OratclStatePtr->logid);
	logHashPtr = Tcl_CreateHashEntry(OratclStatePtr->logHash, buf, &new);

	LogPtr->envhp = NULL;
	LogPtr->errhp = NULL;
	LogPtr->svchp = NULL;
	LogPtr->srvhp = NULL;
	LogPtr->usrhp = (OCISession *) 0;
	LogPtr->autocom = 0;
	LogPtr->async = 0;
	LogPtr->ora_rc = OCI_SUCCESS;
	LogPtr->failovercallback = NULL;
	Tcl_DStringInit(&LogPtr->ora_err);
	LogPtr->logid = OratclStatePtr->logid;

	Tcl_SetHashValue(logHashPtr,  LogPtr);

	con_str = Tcl_GetStringFromObj(objv[1], &con_len);
	cpy_str = ckalloc (con_len + 1);
	if (cpy_str == NULL) {
		fprintf(stderr, "error:: cpy_str is NULL return -1\n");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}
	memcpy (cpy_str, con_str, con_len);
	cpy_str[con_len] = '\0';

	/* break the connect string into components. */
	cpy_pos1 = strchr(cpy_str, '/');
	cpy_pos2 = strchr(cpy_str, '@');

	if (cpy_pos1 != NULL && cpy_pos2 != NULL) {
		*cpy_pos1 = '\0';
		*cpy_pos2 = '\0';
		ora_name = cpy_str;
		ora_pass = cpy_pos1 + 1;
		ora_conn = cpy_pos2 + 1;
	} else if (cpy_pos1 != NULL) {
		*cpy_pos1 = '\0';
		ora_name = cpy_str;
		ora_pass = cpy_pos1 + 1;
	} else if (cpy_pos2 != NULL) {
		*cpy_pos2 = '\0';
		ora_name = cpy_str;
		ora_conn = cpy_pos2 + 1;
	} else {
		if (strcasecmp(cpy_str, "sysdba") == 0) {
			oci_conn = OCI_SYSDBA;
			ora_name = "";
			ora_pass = "";
		} else if (strcasecmp(cpy_str, "sysoper") == 0) {
			oci_conn = OCI_SYSOPER;
			ora_name = "";
			ora_pass = "";
		} else if (strcasecmp(cpy_str, "sysasm") == 0) {
			oci_conn = OCI_SYSASM;
			ora_name = "";
			ora_pass = "";
		} else {
			ora_name = cpy_str;
		}
	}

	/*
	 * check for AS SYDBA | AS SYSOPER | AS SYSASM
	*/
	for (i = 2; i < objc; i++) {
		
		if (0 == strcasecmp(Tcl_GetString(objv[2]), "-sysdba")) {
			oci_conn = OCI_SYSDBA;
		}

		if (0 == strcasecmp(Tcl_GetString(objv[2]), "-sysoper")) {
			oci_conn = OCI_SYSOPER;
		}

		if (0 == strcasecmp(Tcl_GetString(objv[2]), "-sysasm")) {
			oci_conn = OCI_SYSASM;
		}

	}

	if (ora_name)
		ora_namelen = strlen(ora_name);

	if (ora_pass)
		ora_passlen = strlen(ora_pass);

	if (ora_conn)
		ora_connlen = strlen(ora_conn);

	rc = OCI_EnvCreate ((OCIEnv **) &LogPtr->envhp,
#ifdef TCL_THREADS
			    OCI_OBJECT | OCI_THREADED,
#else
			    OCI_OBJECT,
#endif
			    (dvoid *)0,
			    NULL,
			    NULL,
			    NULL,
			    0,
			    (dvoid *) 0 );

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	(void) OCI_HandleAlloc( (CONST dvoid *) LogPtr->envhp,
			       (dvoid **) (dvoid *) &LogPtr->errhp,
			       OCI_HTYPE_ERROR,
			       (size_t) 0,
			       (dvoid **) 0);

	/* server contexts */
	(void) OCI_HandleAlloc( (CONST dvoid *) LogPtr->envhp,
			       (dvoid **) (dvoid *) &LogPtr->srvhp,
			       OCI_HTYPE_SERVER,
			       (size_t) 0,
			       (dvoid **) 0);

	(void) OCI_HandleAlloc( (CONST dvoid *) LogPtr->envhp,
			       (dvoid **) (dvoid *) &LogPtr->svchp,
			       OCI_HTYPE_SVCCTX,
			       (size_t) 0,
			       (dvoid **) 0);


	/*
	 * Attach to Server
	 */

	rc = OCI_ServerAttach(LogPtr->srvhp,
			      LogPtr->errhp,
			      (text *) ora_conn,
			      ora_connlen,
			      OCI_DEFAULT);

	if (rc != OCI_SUCCESS) {
		attached = 1;
		tcl_return = TCL_ERROR;
		goto common_exit;
	}


	/*
	 * set attribute server context in the service context
	 */

	rc = OCI_AttrSet( (dvoid *) LogPtr->svchp,
			   OCI_HTYPE_SVCCTX,
			   (dvoid *)LogPtr->srvhp,
			   (ub4) 0,
			   OCI_ATTR_SERVER,
			   (OCIError *) LogPtr->errhp);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}


	/* 
	 * allocate a session handle
	 */

	rc = OCI_HandleAlloc((dvoid *) LogPtr->envhp,
			     (dvoid **) (dvoid *) &LogPtr->usrhp,
			     (ub4) OCI_HTYPE_SESSION,
			     (size_t) 0,
			     (dvoid **) 0);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}


	/*
	 * set the username attribute
	 */

	rc = OCI_AttrSet((dvoid *) LogPtr->usrhp,
			 (ub4) OCI_HTYPE_SESSION,
			 (dvoid *) ora_name,
			 (ub4) ora_namelen,
			 (ub4) OCI_ATTR_USERNAME,
			 LogPtr->errhp);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/*
	 * set the password attribute
	 */

	rc = OCI_AttrSet((dvoid *) LogPtr->usrhp,
			 (ub4) OCI_HTYPE_SESSION,
			 (dvoid *) ora_pass,
			 (ub4) ora_passlen,
			 (ub4) OCI_ATTR_PASSWORD,
			 LogPtr->errhp);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	rc = OCI_AttrSet((dvoid *) LogPtr->usrhp,
			 (ub4) OCI_HTYPE_SESSION,
			 (dvoid *) PACKAGE_NAME,
			 (ub4) strlen(PACKAGE_NAME),
			 (ub4) OCI_ATTR_DRIVER_NAME,
			 LogPtr->errhp);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	if ((ora_namelen + ora_passlen) == 0) {
		oci_cred = OCI_CRED_EXT;
	}

	rc = OCI_SessionBegin (LogPtr->svchp,
			       LogPtr->errhp,
			       LogPtr->usrhp,
			       (ub4) oci_cred,
			       (ub4) oci_conn);

	if (rc == OCI_SUCCESS_WITH_INFO) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				0,
				&LogPtr->ora_rc,
				&LogPtr->ora_err);
	} else if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* check for options and deprecated keywords */
	for (i = 2; i < objc; i++) {
		
		if (0 == strcmp(Tcl_GetString(objv[2]), "-async")) {
			LogPtr->async = 1;
		}

		if (0 == strcmp(Tcl_GetString(objv[2]), "-failovercallback")) {
			if (objc > i) {
				i++;
				p = Tcl_GetStringFromObj(objv[i], NULL);

				/* append oralogon handle string */
				LogPtr->failovercallback = ckalloc(strlen(p) + strlen(buf) +2);
				sprintf(LogPtr->failovercallback, "%s %s", p, buf);
				LogPtr->interp = interp;
				failover.fo_ctx = (dvoid *)LogPtr;
				failover.callback_function = &callback_fn;

				/* OCI callback registration */
				rc = OCI_AttrSet(LogPtr->srvhp,
						 (ub4) OCI_HTYPE_SERVER,
						 (dvoid *) &failover,
						 (ub4) 0,
						 (ub4) OCI_ATTR_FOCBK,
						 LogPtr->errhp);

				if (rc != OCI_SUCCESS) {
					tcl_return = TCL_ERROR;
					goto common_exit;
				}
			}
		}

	}

	if (LogPtr->async == 1) {
		rc = OCI_AttrSet((dvoid *) LogPtr->srvhp,
				 (ub4) OCI_HTYPE_SERVER,
				 (dvoid *) 0,
				 (ub4) 0,
				 (ub4) OCI_ATTR_NONBLOCKING_MODE,
				 LogPtr->errhp);
		if (rc != OCI_SUCCESS) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
	}

	rc = OCI_AttrSet((dvoid *) LogPtr->svchp,
			 (ub4) OCI_HTYPE_SVCCTX,
			 (dvoid *) LogPtr->usrhp,
			 (ub4) 0,
			 (ub4) OCI_ATTR_SESSION,
			 LogPtr->errhp);

	if (rc != OCI_SUCCESS) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(buf, -1));

common_exit:

	if (tcl_return == TCL_ERROR) {

		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&LogPtr->ora_rc,
					&LogPtr->ora_err);
		}

		if (attached) {
			(void) OCI_ServerDetach(LogPtr->srvhp,
						LogPtr->errhp,
						(ub4) OCI_DEFAULT);
		}

		if (logHashPtr) {
			Tcl_DeleteHashEntry(logHashPtr);
		}

		if (LogPtr) {
			Oratcl_LogFree(LogPtr);
		}

	}

	ckfree(cpy_str);

	return tcl_return;
}

/* 
 *----------------------------------------------------------------------
 * TAF Callback
 *----------------------------------------------------------------------
 */
sb4 callback_fn(svchp, envhp, fo_ctx, fo_type, fo_event)
	dvoid		*svchp;
	dvoid		*envhp;
	dvoid		*fo_ctx;
	ub4		fo_type;
	ub4		fo_event;
{
	int		res;

	OratclLogs *LogPtr = (OratclLogs*)fo_ctx;
	char buffer[100];

	sprintf(buffer,
		"%s %d %d",
		LogPtr->failovercallback,
		fo_type,
		fo_event);
	res = Tcl_Eval(LogPtr->interp, buffer);
	if (res != TCL_OK) {
		Tcl_BackgroundError(LogPtr->interp);
	}

	return 0;
}

