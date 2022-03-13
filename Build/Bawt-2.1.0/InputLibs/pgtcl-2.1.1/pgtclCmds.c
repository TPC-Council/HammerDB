/*-------------------------------------------------------------------------.
 *
 * pgtclCmds.c
 *	  C functions which implement pg_* tcl commands
 *
 * Portions Copyright (c) 2004-2013, L Bayuk
 * Portions Copyright (c) 1996-2004, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  $Id: pgtclCmds.c 372 2014-09-12 19:37:05Z lbayuk $
 *
 *-------------------------------------------------------------------------
 */

#include <ctype.h>
#include <string.h>

#include "pgtclCmds.h"
#include "pgtclId.h"
#include "libpq/libpq-fs.h"		/* large-object interface */

/*
 * Local function forward declarations
 */
static int execute_put_values(Tcl_Interp *interp, char *array_varname,
				   PGresult *result, int tupno);

static Tcl_Obj *result_get_obj(PGresult *result, int tupno, int colno);

static Tcl_Obj *get_row_list_obj(Tcl_Interp *interp, PGresult *result,
		 			int tupno);


/**********************************
 * pg_conndefaults

 syntax:
 pg_conndefaults

 the return result is a list describing the possible options and their
 current default values for a call to pg_connect with the new -conninfo
 syntax. Each entry in the list is a sublist of the format:

	 {optname label dispchar dispsize value}

 **********************************/

int
Pg_conndefaults(ClientData cData, Tcl_Interp *interp, int objc,
				Tcl_Obj *CONST objv[])
{
	PQconninfoOption *options = PQconndefaults();
	PQconninfoOption *option;

	if (objc != 1)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "");
		return TCL_ERROR;
	}

	if (options)
	{
		Tcl_Obj    *resultList = Tcl_GetObjResult(interp);

		Tcl_SetListObj(resultList, 0, NULL);

		for (option = options; option->keyword != NULL; option++)
		{
			char	   *val = option->val ? option->val : "";

			/* start a sublist */
			Tcl_Obj    *subList = Tcl_NewListObj(0, NULL);

			if (Tcl_ListObjAppendElement(interp, subList,
					 Tcl_NewStringObj(option->keyword, -1)) == TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, subList,
					   Tcl_NewStringObj(option->label, -1)) == TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, subList,
					Tcl_NewStringObj(option->dispchar, -1)) == TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, subList,
						   Tcl_NewIntObj(option->dispsize)) == TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, subList,
								 Tcl_NewStringObj(val, -1)) == TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, resultList,
										 subList) == TCL_ERROR)
				return TCL_ERROR;
		}
		PQconninfoFree(options);
	}
	return TCL_OK;
}


/**********************************
 * pg_connect
Make a connection to a backend.

Syntax:

  pg_connect -conninfo connInfoString
     Where connInfoString looks like: "host=Hostname dbname=Databasename..."
     Or, connInfoString can be a postgresql:// or postgres:// URI. This is
     handled transparently by the libpq function PQconnectDB().
  pg_connect -connlist connInfoList
     Where connInfoList is a Tcl list of option name/value pairs.
  pg_connect dbName [-host hostName] [-port portNumber] [-tty pqtty]
     This is an old, obsolete form.

The result is a database connection handle, or a Tcl error with error
message on failure.

 **********************************/

int
Pg_connect(ClientData cData, Tcl_Interp *interp, int objc,
		   Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	const char *firstArg;
	static char *usage = "-conninfo conninfoString | "
                         "-connlist conninfoList | "
                         "dbName ?options?";

	if (objc == 1)
	{
		Tcl_WrongNumArgs(interp, 1, objv, usage);
		return TCL_ERROR;
	}

	firstArg = Tcl_GetString(objv[1]);
	if (strcmp(firstArg, "-conninfo") == 0)
	{
		/*
		 * Establish a connection using PQconnectdb()
		 */
		char	   *conninfoString;

		if (objc != 3)
		{
			Tcl_WrongNumArgs(interp, 2, objv, "conninfoString");
			return TCL_ERROR;
		}
		conninfoString = Tcl_GetString(objv[2]);
		conn = PQconnectdb(conninfoString);
	}
	else if (strcmp(firstArg, "-connlist") == 0)
	{
		/*
		 * Establish a connection using PQconnectdbParams()
		 */
		Tcl_Obj	   *connList;
		const char **connKeywords;
		const char **nextKeyword;
		const char **connValues;
		const char **nextValue;
		int			nKeywords;
		int			listLen;
		int			i;
		int			listIndex;
		Tcl_Obj	   *connListElement;

		if (objc != 3)
		{
			Tcl_WrongNumArgs(interp, 2, objv, "conninfoList");
			return TCL_ERROR;
		}
		connList = objv[2];
		if (Tcl_ListObjLength(interp, connList, &listLen) == TCL_ERROR)
		{
			return TCL_ERROR;
		}
		if (listLen % 2)
		{
			Tcl_AppendResult(interp, "conninfoList must have"
									" an even number of elements", 0);
			return TCL_ERROR;
		}

		/*
		 * Copy the keyword/value pairwise list to 2 separate arrays for
		 * PQconnectdbParams()
		 */
		nKeywords = listLen / 2;
		connKeywords = (const char **)Tcl_Alloc((nKeywords + 1) * sizeof(char *));
		connValues = (const char **)Tcl_Alloc((nKeywords + 1) * sizeof(char *));
		listIndex = 0;
		nextKeyword = connKeywords;
		nextValue = connValues;
		for (i = 0; i < nKeywords; i++)
		{
			Tcl_ListObjIndex(interp, connList, listIndex++, &connListElement);
			*nextKeyword++ = Tcl_GetString(connListElement);
			Tcl_ListObjIndex(interp, connList, listIndex++, &connListElement);
			*nextValue++ = Tcl_GetString(connListElement);
		}
		*nextKeyword = *nextValue = NULL;
		conn = PQconnectdbParams(connKeywords, connValues, 0);
		Tcl_Free((char *)connKeywords);
		Tcl_Free((char *)connValues);
	}
	else if (*firstArg == '-')
	{
		/*
		 * Catch usage error, rather than assuming -xxx is a database name
		 */
		Tcl_WrongNumArgs(interp, 1, objv, usage);
		return TCL_ERROR;
	}
	else
	{
		/*
		 * Establish a connection using the obsolete PQsetdb() interface.
		 * "firstarg" is the database name.
		 */
		int			i;
		char	   *nextArg;
		int			optIndex;
		const char *pghost = NULL;
		const char *pgtty = NULL;
		const char *pgport = NULL;
		const char *pgoptions = NULL;
		static CONST84 char *options[] = {
			"-host", "-port", "-tty", "-options", (char *)NULL
		};
		enum options
		{
			OPT_HOST, OPT_PORT, OPT_TTY, OPT_OPTIONS
		};


		if (objc > 2)  /* More options follow the datbase name*/
		{
			/* parse for pg environment settings */
			i = 2;
			while (i + 1 < objc)
			{
				nextArg = Tcl_GetString(objv[i + 1]);

				/* process command options */
				if (Tcl_GetIndexFromObj(interp, objv[i], options,
							   "switch", TCL_EXACT, &optIndex) != TCL_OK)
					return TCL_ERROR;

				switch ((enum options) optIndex)
				{
					case OPT_HOST:
						{
							pghost = nextArg;
							i += 2;
							break;
						}

					case OPT_PORT:
						{
							pgport = nextArg;
							i += 2;
							break;
						}

					case OPT_TTY:
						{
							pgtty = nextArg;
							i += 2;
							break;
						}

					case OPT_OPTIONS:
						{
							pgoptions = nextArg;
							i += 2;
						}
				}
			}

			if ((i % 2 != 0) || i != objc)
			{
				Tcl_WrongNumArgs(interp, 1, objv, "databaseName ?-host hostName? ?-port portNumber? ?-tty pgtty? ?-options pgoptions?");
				return TCL_ERROR;
			}
		}
		conn = PQsetdb(pghost, pgport, pgoptions, pgtty, firstArg);
	}

	if (PQstatus(conn) != CONNECTION_OK)
	{
		Tcl_AppendResult(interp, "Connection to database failed\n",
						 PQerrorMessage(conn), 0);
		PQfinish(conn);
		return TCL_ERROR;
	}

	PgSetConnectionId(interp, conn);
	/* Set libpq's client encoding to UNICODE (UTF8), since that is what
	   Tcl >= 8.1 uses for internal character storage. This replaces
	   the PGCLIENTENCODING environment variable setting in pgtcl.c,
	   which did not work with Windows DLLs.
	*/
	if (PQsetClientEncoding(conn, "UTF8") != 0)
	{
		Tcl_AppendResult(interp, "Unable to set client encoding\n",
						 PQerrorMessage(conn), 0);
		PQfinish(conn);
		return TCL_ERROR;
	}

	return TCL_OK;
}


/**********************************
 * pg_disconnect
 close a backend connection

 syntax:
 pg_disconnect connection

 The argument passed in must be a connection pointer.

 **********************************/

int
Pg_disconnect(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	Tcl_Channel conn_chan;
	char	   *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn_chan = Tcl_GetChannel(interp, connString, 0);
	if (conn_chan == NULL)
	{
		Tcl_ResetResult(interp);
		Tcl_AppendResult(interp, connString, " is not a valid connection", 0);
		return TCL_ERROR;
	}

	/* Check that it is a PG connection and not something else */
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *) NULL)
		return TCL_ERROR;

	return Tcl_UnregisterChannel(interp, conn_chan);
}

/**********************************
 * pg_encrypt_password
 Encrypt (hash) a password/username, like PostgreSQL does.

 syntax:
 pg_encrypt_password password username

 Returns the resulting hash as a string.

 **********************************/

#ifdef HAVE_PQENCRYPTPASSWORD /* PostgreSQL >= 8.2.0 */
int
Pg_encrypt_password(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	CONST char	*password;
	CONST char	*username;
	char		*encrypted;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "password username");
		return TCL_ERROR;
	}

	password = Tcl_GetString(objv[1]);
	username = Tcl_GetString(objv[2]);

	encrypted = PQencryptPassword(password, username);
	if (!encrypted)
	{
		Tcl_ResetResult(interp);
		Tcl_AppendResult(interp, "PQencryptPassword failed", 0);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(encrypted, -1));
	return TCL_OK;
}
#endif


/**********************************
 * get_result_format - Helper for pg_exec_prepared and pg_exec_params

	Parse resultListObj and make resultFormat argument.
	The Tcl command syntax supports per-column result formats, but libpq
	does not (yet), so make sure the caller isn't asking for something
	that libpq can't handle. Take the first value, and make sure the
	remaining ones match.
	On success, store the result format in *resultFormat and return TCL_OK.
	On error, store a message in the interp and return TCL_ERROR.

 **********************************/
static int
get_result_format(Tcl_Interp *interp, Tcl_Obj *resultListObj, int *resultFormat)
{
	int		   listLen;
	Tcl_Obj	   **objp;
	int		i;

	if (Tcl_ListObjGetElements(interp, resultListObj, &listLen, &objp) != TCL_OK)
	{
		Tcl_SetResult(interp, "Invalid resultFormatList parameter", TCL_STATIC);
		return TCL_ERROR;
	}
	if (listLen > 0)
	{
		*resultFormat = (*Tcl_GetString(objp[0]) == 'B');
		for (i = 1; i < listLen; i++)
			if (*resultFormat != (*Tcl_GetString(objp[i]) == 'B'))
			{
				Tcl_SetResult(interp, "Mixed resultFormat values are not supported",
					TCL_STATIC);
				return TCL_ERROR;
			}
	}
    else *resultFormat = 0;  /* Empty list => All TEXT */

	return TCL_OK;;
}

/**********************************
 * get_param_formats - Helper for pg_exec_prepared and pg_exec_params

	Parse argFormat list and make paramFormats argument.
	The parameter must either be empty (all TEXT), a single word T*|B*
	(all that format), or nParams values, one per query parameter.
    The libpq call will accept a null pointer for this argument, meaning
	all text, so we can avoid the allocation in that most common case.
	Set the allParamsText flag in that case.

	On success, set or clear the allParamsText flag, store a NULL
	pointer or a pointer to nParams ints in paramFormatsResult,
	and return TCL_OK. (Caller must free paramFormatsResult.)
	On error, store a message in the interp and return TCL_ERROR.

 **********************************/
static int
get_param_formats(Tcl_Interp *interp, Tcl_Obj *argFormatListObj,
	int nParams, int *allParamsText, int **paramFormatsResult)
{
	int		listLen;
	Tcl_Obj	**objp;
	int		*paramFormats;
	int		i;

	if (Tcl_ListObjGetElements(interp, argFormatListObj, &listLen, &objp) != TCL_OK)
	{
		Tcl_SetResult(interp, "Invalid argFormatList parameter", TCL_STATIC);
		return TCL_ERROR;
	}

	paramFormats = NULL;
	*allParamsText = 1;
	if (listLen == 1)
	{
		if (*Tcl_GetString(objp[0]) == 'B')
		{
			paramFormats = (int *)Tcl_Alloc(nParams * sizeof(int));
			for (i = 0; i < nParams; i++)
				paramFormats[i] = 1;
			*allParamsText = 0;
		}
	}
	else if (listLen > 1)
	{
		if (listLen != nParams)
		{
			Tcl_SetResult(interp, "Mismatched argFormatList and parameter count",
				TCL_STATIC);
			return TCL_ERROR;
		}
		paramFormats = (int *)Tcl_Alloc(nParams * sizeof(int));
		for (i = 0; i < nParams; i++)
			if ((paramFormats[i] = (*Tcl_GetString(objp[i]) == 'B')))
				*allParamsText = 0;
	}

	*paramFormatsResult = paramFormats;
	return TCL_OK;
}

/**********************************
 * get_param_values - Helper for pg_exec, pg_exec_prepared, and pg_exec_params

	For each query parameter, we need its address in an array paramValues.
	For each binary-format query parameter, we need its length in an
	array paramLengths.  (Length is ignored for text-format parameters.)
	If there are no binary parameters, paramLengths will be NULL.
	(If this is known in advance, and the allParamText flag is 1, then the
	the paramLengths_result argument can be supplied as NULL. This is used
	by the extended form of pg_exec.)
	If there are no query parameters, both arrays are NULL.
	CHECK: Currently uses ByteArray for binary, String for text, but it
	is unclear if this is correct.
	 
	Stores the results in *paramLengths_result and *paramValues_result,
	which the caller must free if not NULL.
	No errors, void return.

 **********************************/
static void
get_param_values(Tcl_Interp *interp, Tcl_Obj *CONST *objv,
	int nParams, int allParamsText, int *paramFormats,
	const char *const **paramValues_result, int **paramLengths_result)
{
	int		i;
	int		*paramLengths;
	const char	**paramValues;

	paramLengths = NULL;
	paramValues = NULL;
	if (nParams > 0)
	{
		paramValues = (const char **)Tcl_Alloc(nParams * sizeof(char *));
		if (!allParamsText)
			paramLengths = (int *)Tcl_Alloc(nParams * sizeof(int));

		for (i = 0; i < nParams; i++)
		{
			if (paramFormats && paramFormats[i]) /* Binary Format */
				paramValues[i] = (char *)Tcl_GetByteArrayFromObj(*objv,
										&paramLengths[i]);
			else /* Text Format */
				paramValues[i] = Tcl_GetString(*objv);
			objv++;
		}
	}
	*paramValues_result = paramValues;
	if (paramLengths_result)
		*paramLengths_result = paramLengths;
}

/**********************************
 * get_param_types - Helper for pg_exec_params

	Build an array of type OIDs from the supplied list. The list must
	either be empty or contain nParams items.
	 
	Stores the result in *paramTypes, which the caller must free
	if not NULL. This will be either NULL or a pointer to nParams Oids.
	Returns TCL_OK if OK.
	On error, store a message in the interp and return TCL_ERROR.

 **********************************/
static int
get_param_types(Tcl_Interp *interp, Tcl_Obj *argTypeListObj,
	int nParams, Oid **paramTypesResult)
{
	int		listLen;
	Tcl_Obj	**objp;
	Oid *paramTypes;
	int		i;

	if (Tcl_ListObjGetElements(interp, argTypeListObj, &listLen, &objp) != TCL_OK)
	{
		Tcl_SetResult(interp, "Invalid argTypeList parameter", TCL_STATIC);
		return TCL_ERROR;
	}

	paramTypes = NULL;
	if (listLen > 0)
	{
		if (listLen != nParams)
		{
			Tcl_SetResult(interp, "Mismatched argTypeList and parameter count",
				TCL_STATIC);
			return TCL_ERROR;
		}
		paramTypes = (Oid *)Tcl_Alloc(nParams * sizeof(int));
		for (i = 0; i < nParams; i++)
		{
			/*
			 * Note: paramTypes[i] is Oid which is unsigned int, and
			 * Tcl_GetIntFromObj() expects a pointer to a signed int.
			 * There is no direct support for unsigned in Tcl, but tests
			 * and code examination show it will work for values that
			 * will fit in unsigned but not signed. Anyway, it's the best
			 * we can do.
			 */
			if (Tcl_GetIntFromObj(interp, objp[i], (int *)&paramTypes[i]) != TCL_OK)
			{
		  		Tcl_Free((char *)paramTypes);
				return TCL_ERROR;
			}
		}
	}
	*paramTypesResult = paramTypes;
	return TCL_OK;
}

/**********************************
 * PgQueryOK - Check that it is OK to send a query.
   This checks that the connection ID is valid, no COPY is in progress,
   and (if asyncOK is 0) no asynchronous query callback is active.

   Returns 1 if OK, else 0. On error, stores an error message in the
   interp (if applicable).

 *********************************/
static int
PgQueryOK(Tcl_Interp *interp, PGconn *conn, Pg_ConnectionId *connid, int asyncOK)
{
	if (conn == NULL) return 0;
	if (connid->res_copyStatus != RES_COPY_NONE)
	{
		Tcl_SetResult(interp, "Operation not allowed while COPY is in progress",
			TCL_STATIC);
		return 0;
	}
	if (!asyncOK && connid->callbackPtr)
	{
		Tcl_SetResult(interp, "Operation not allowed while waiting for callback",
		TCL_STATIC);
		return 0;
	}
	return 1;
}

/**********************************
 * pg_exec
 send a query string to the backend connection

 syntax:
 pg_exec connection query ?param...?

 Optional args are used as parameters to PQexecParams(). This is a simplified
 version of Pg_exec_params using text-only, untyped parameters.
 With no optional args, use regular PQexec().

 the return result is either an error message or a handle for a query
 result.  Handles start with the prefix "pgp"
 **********************************/

int
Pg_exec(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	PGresult   *result;
	char	   *connString;
	char	   *execString;
	const char *const *paramValues;
	int		   nParams;

	nParams = objc - 3;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection queryString ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	execString = Tcl_GetString(objv[2]);

	if (nParams > 0)
	{
		get_param_values(interp, &objv[3], nParams, /* allParamsText = */ 1,
			/* paramFormats = */ NULL, &paramValues,
			/* paramLengths_result = */ NULL);

		result = PQexecParams(conn, execString, nParams, NULL,
						paramValues, NULL, NULL, /* resultFormat= */ 0);

		if (paramValues)
			Tcl_Free((char *)paramValues);

	} else {
		result = PQexec(conn, execString);
	}


	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (result)
	{
		int			rId = PgSetResultId(interp, connString, result);
		ExecStatusType rStat;

		if (rId == -1)
		{
			/*
			 * Query response was OK, but unable to allocate result slot.
			 * This is bad news, since the caller will think the query failed,
			 * but the query may have worked and modified the database.
			 * But there isn't much choice at this point.
			 */
			PQclear(result);
			return TCL_ERROR;
		}
		rStat = PQresultStatus(result);

		if (rStat == PGRES_COPY_IN || rStat == PGRES_COPY_OUT)
		{
			connid->res_copyStatus = RES_COPY_INPROGRESS;
			connid->res_copy = rId;
			connid->copyBuf = NULL;
		}
		return TCL_OK;
	}
	else
	{
		/* error occurred during the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}
}



/**********************************
 * pg_exec_prepared
 Execute a pre-prepared query with supplied parameters

 Syntax:
 pg_exec_prepared connection statementName resultFormatList \
    argFormatList ?param...?

 argFormatList is empty (= same as T), a single word T|B|TEXT|BINARY, or
 a list of those words, describing each argument as text or binary. If a
 single word, it applies to all arguments.  (Actually, anything starting
 with B means Binary, and anything else means Text. There is no error
 checking.)

 resultFormatList is similar to argFormatList except that it applies to the
 columns of the results. Currently,  all result parameters must be text, or
 all must be binary (this is a libpq limitation, not a PostgreSQL
 limitation). So you might as well specify a single word BINARY or leave it
 empty.

 The return result is either an error message or a handle for a query
 result.
 **********************************/

int
Pg_exec_prepared(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;
	PGresult   *result;
	char	   *statementName;
	int		   nParams;
	int		   allParamsText;
	int 	   resultFormat;
	int		   *paramFormats;
	int		   *paramLengths;
	const char *const *paramValues;
	int		   returnValue;

	nParams = objc - 5;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection statementName "
			"resultFormat argFormatList ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	statementName = Tcl_GetString(objv[2]);

	/* Parse resultFormatList and make resultFormat argument. */
	if (get_result_format(interp, objv[3], &resultFormat) != TCL_OK)
		return TCL_ERROR;

	/* Parse argFormat list and make paramFormats argument and all-text flag */
	if (get_param_formats(interp, objv[4], nParams, &allParamsText,
			&paramFormats) != TCL_OK)
		return TCL_ERROR;

	/* Copy query parameters, and lengths if binary format */
	get_param_values(interp, &objv[5], nParams, allParamsText, paramFormats,
			&paramValues, &paramLengths);

	/* Now execute the prepared query */
	result = PQexecPrepared(conn, statementName, nParams, paramValues,
			paramLengths, paramFormats, resultFormat);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	/*
	 * Note: You can't use this command to start a COPY, so there is no
	 * need to check for PGRES_COPY_* status like pg_exec does.
	 */
	if (!result)
	{
		/* error occurred during the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		returnValue = TCL_ERROR;
	}
	else if (PgSetResultId(interp, connString, result) == -1)
	{
		/* Query response was OK, but unable to allocate result slot. */
		PQclear(result);
		returnValue = TCL_ERROR;
	}
	else
		returnValue = TCL_OK;

	if (paramFormats)
		Tcl_Free((char *)paramFormats);
	if (paramLengths)
		Tcl_Free((char *)paramLengths);
	if (paramValues)
		Tcl_Free((char *)paramValues);

	return returnValue;
}

/**********************************
 * pg_exec_params
 Parse, bind parameters, and execute a query

 Syntax:
 pg_exec_params connection query resultFormatList argFormatList
         argTypeList param...

 query is an SQL statement with parameter placeholders specified as
 $1, $2, etc.

 argFormatList is empty (= same as T), a single word T|B|TEXT|BINARY, or
 a list of those words, describing each argument as text or binary. If a
 single word, it applies to all arguments.  (Actually, anything starting
 with B means Binary, and anything else means Text. There is no error
 checking.)

 resultFormatList is similar to argFormatList except that it applies to the
 columns of the results. Currently, all result parameters must be text, or
 all must be binary (this is a libpq limitation, not a PostgreSQL
 limitation). So you might as well specify a single word BINARY or leave it
 empty.

 argTypeList is a list of PostgreSQL type OIDs for the query parameter
 arguments. Type OIDs must be supplied for each binary-format argument.
 If there are any binary format arguments, the argTypeList must contain
 an entry for each argument, although the actual value will be ignored
 for text-mode arguments.

 Note: If you are using all text arguments, it is easier to use pg_exec
 with the optional parameter arguments.

 The return result is either an error message or a handle for a query
 result.
 **********************************/

int
Pg_exec_params(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;
	PGresult   *result;
	char	   *queryString;
	int		   nParams;
	int		   allParamsText;
	int 	   resultFormat;
	int		   *paramFormats;
	int		   *paramLengths;
	const char *const *paramValues;
    Oid		   *paramTypes;
	int		   returnValue;

	nParams = objc - 6;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection queryString "
			"resultFormat argFormatList argTypeList ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	queryString = Tcl_GetString(objv[2]);

	/* Parse resultFormatList and make resultFormat argument. */
	if (get_result_format(interp, objv[3], &resultFormat) != TCL_OK)
		return TCL_ERROR;

	/* Parse argFormat list and make paramFormats argument and all-text flag */
	if (get_param_formats(interp, objv[4], nParams, &allParamsText,
			&paramFormats) != TCL_OK)
		return TCL_ERROR;

	/* Get the parameter type OID list into an array */
	if (get_param_types(interp, objv[5], nParams, &paramTypes) != TCL_OK) {
		if (paramFormats)
			Tcl_Free((char *)paramFormats);
		return TCL_ERROR;
	}

	/* Copy query parameters, and lengths if binary format */
	get_param_values(interp, &objv[6], nParams, allParamsText, paramFormats,
			&paramValues, &paramLengths);

	/* Now execute the parameterized query */
	result = PQexecParams(conn, queryString, nParams, paramTypes,
			paramValues, paramLengths, paramFormats, resultFormat);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	/*
	 * Note: You can't use this command to start a COPY, so there is no
	 * need to check for PGRES_COPY_* status like pg_exec does.
	 */
	if (!result)
	{
		/* error occurred during the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		returnValue = TCL_ERROR;
	}
	else if (PgSetResultId(interp, connString, result) == -1)
	{
		/* Query response was OK, but unable to allocate result slot. */
		PQclear(result);
		returnValue = TCL_ERROR;
	}
	else
		returnValue = TCL_OK;

	if (paramFormats)
		Tcl_Free((char *)paramFormats);
	if (paramLengths)
		Tcl_Free((char *)paramLengths);
	if (paramValues)
		Tcl_Free((char *)paramValues);
	if (paramTypes)
		Tcl_Free((char *)paramTypes);

	return returnValue;
}

/**********************************
 * pg_result_errorfield_code
 Translate error fieldName to fieldCode for pg_result -error?Field?
 Valid fieldNames are strings matching the constant name without PG_DIAG_,
such as "SEVERITY", or the single letter code which is the value of the
constant, like 'S'. See postgres_ext.h for the list.

  Both field names and field codes (the PG_DIAG_* names) used to be folded to
upper case for comparison, making them case-insensitive. But starting with
PostgreSQL-9.2 and 9.3, new codes used single lower case letters. So it was
necessary to break compatibility with previous releases. Now the field names
(and the aliases, without the prefix e.g. MESSAGE_ or SOURCE_) are still case
insensitive, but single-character codes are now case sensitive.

 Returns a valid PG_DIAG_* constant, or 0 if there is no match.
 **********************************/
static int
pg_result_errorfield_code(char *fieldName)
{
	static struct errorfield_names_t {
		char *fieldName;
		int fieldCode;
	} errorfield_names[] = {
		{ "SEVERITY",			PG_DIAG_SEVERITY },
		{ "SQLSTATE",			PG_DIAG_SQLSTATE },
		{ "MESSAGE_PRIMARY",	PG_DIAG_MESSAGE_PRIMARY },
		{ "MESSAGE_DETAIL",		PG_DIAG_MESSAGE_DETAIL },
		{ "MESSAGE_HINT",		PG_DIAG_MESSAGE_HINT },
		{ "STATEMENT_POSITION", PG_DIAG_STATEMENT_POSITION },
		{ "CONTEXT",			PG_DIAG_CONTEXT },
		{ "SOURCE_FILE",		PG_DIAG_SOURCE_FILE },
		{ "SOURCE_LINE",		PG_DIAG_SOURCE_LINE },
		{ "SOURCE_FUNCTION",	PG_DIAG_SOURCE_FUNCTION },
		{ "PRIMARY",            PG_DIAG_MESSAGE_PRIMARY },
		{ "DETAIL",             PG_DIAG_MESSAGE_DETAIL },
		{ "HINT",               PG_DIAG_MESSAGE_HINT },
		{ "POSITION",           PG_DIAG_STATEMENT_POSITION },
		{ "FILE",               PG_DIAG_SOURCE_FILE },
		{ "LINE",               PG_DIAG_SOURCE_LINE },
		{ "FUNCTION",           PG_DIAG_SOURCE_FUNCTION },
#ifdef PG_DIAG_SCHEMA_NAME  /* These 5 codes were added in PostgreSQL-9.3.0 */
		{ "SCHEMA_NAME",        PG_DIAG_SCHEMA_NAME },
		{ "TABLE_NAME",         PG_DIAG_TABLE_NAME },
		{ "COLUMN_NAME",        PG_DIAG_COLUMN_NAME },
		{ "DATATYPE_NAME",      PG_DIAG_DATATYPE_NAME },
		{ "CONSTRAINT_NAME",    PG_DIAG_CONSTRAINT_NAME },
#endif
		{ 0, '\0'}};

	struct errorfield_names_t *ep = errorfield_names;
	char field1;

	if (!fieldName || !fieldName[0])
		return 0;
	if (fieldName[1])
	{
		/* Check for exact word match if length>1, case insensitively */
		while (ep->fieldName &&
				!Tcl_StringCaseMatch(fieldName, ep->fieldName, 1))
		 	ep++;
	} else {
		/* Check for single-character code match.
			Note these are being checked against the PG_DIAG_* values,
			which are defined in postgres_ext.h as single characters.
		*/
		field1 = fieldName[0];
		while (ep->fieldCode && ep->fieldCode != field1) ep++;
	}
	return ep->fieldCode;
}


/**********************************
 * pg_result
 get information about the results of a query

 syntax:

	pg_result result ?option?

 the options are:

	-status the status of the result

	-error	?code?
	-errorField ?code?
		If the status does not indicate an error, returns an empty string.
		Else, if no code is provided, returns the current error message.
		Else, the code names an error message subfield or abbreviation,
		and the value of that error field is returned if valid and available.
		Else, an empty string is returned.

	-conn	the connection that produced the result

	-oid	if command was an INSERT, the OID of the inserted tuple

	-numTuples	the number of tuples in the query

	-cmdTuples	Same as -numTuples, but for DELETE and UPDATE

	-cmdStatus	returns the command status tag, e.g. "INSERT ... ..."

	-numAttrs	returns the number of attributes returned by the query

	-assign arrayName
		assign the results to an array, using subscripts of the form
			(tupno,attributeName)

	-assignbyidx arrayName ?appendstr?
		assign the results to an array using the first field's value
		as a key.
		All but the first field of each tuple are stored, using
		subscripts of the form (field0value,attributeNameappendstr)

	-getTuple tupleNumber
		returns the values of the tuple in a list

	-getNull tupleNumber
		returns a list indicating if each value in the tuple is NULL

	-tupleArray tupleNumber arrayName
		stores the values of the tuple in array arrayName, indexed
		by the attributes returned

	-attributes
		returns a list of the name/type pairs of the tuple attributes

	-lAttributes
		returns a list of the {name type len} entries of the tuple
		attributes

	-lxAttributes
		returns an extended list of the tuple attributes in the form:
			{name type size size_modifier format table_oid table_column}

	-list
		returns one list of all of the data

	-llist
		returns a list of lists, where each embedded list represents 
		a tuple in the result

	-numParams
		returns the number of paramters in a prepared statement.
		This may be used only after pg_describe_prepared.

	-paramTypes
		returns a list of Type OIDs for the parameters in a prepared statement.
		This may be used only after pg_describe_prepared.

	-clear	clear the result buffer. Do not reuse after this

    -dict   Return a Tcl8.5 dictionary containing the query results, with
        integer row numbers as outer keys, and field names as inner keys.

 **********************************/
int
Pg_result(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGresult   *result;
	int			i;
	int			tupno;
	char	   *queryResultString;
	int			optIndex;

	static CONST84 char *options[] = {
		"-status", "-error", "-errorField", "-conn", "-oid",
		"-numTuples", "-cmdTuples", "-numAttrs", "-assign", "-assignbyidx",
		"-getTuple", "-tupleArray", "-attributes", "-lAttributes",
		"-lxAttributes", "-clear", "-list", "-llist", "-getNull",
		"-cmdStatus", "-dict",
#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
		"-numParams", "-paramTypes",
#endif
		(char *)NULL
	};

	enum options
	{
		OPT_STATUS, OPT_ERROR, OPT_ERRORFIELD, OPT_CONN, OPT_OID,
		OPT_NUMTUPLES, OPT_CMDTUPLES, OPT_NUMATTRS, OPT_ASSIGN, OPT_ASSIGNBYIDX,
		OPT_GETTUPLE, OPT_TUPLEARRAY, OPT_ATTRIBUTES, OPT_LATTRIBUTES,
		OPT_LXATTRIBUTES, OPT_CLEAR, OPT_LIST, OPT_LLIST, OPT_GETNULL,
		OPT_CMDSTATUS, OPT_DICT,
#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
		OPT_NUMPARAMS, OPT_PARAMTYPES
#endif
	};

	/*
	 * Check for resultHandle and switch. Subfunctions will further check
	 * their argument counts. Note: Common Tcl practice is that with too
	 * few args, the command reports "wrong # args: should be..." and just
	 * summarizes the usage. With an invalid arg, the command lists all
	 * valid args: "bad option "...": must be A, B, ...".
	 * pg_result now does this; please don't change it back.
	 */
	if (objc < 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "resultHandle switch ?arg ...?");
		return TCL_ERROR;
	}

	/* figure out the query result handle and look it up */
	queryResultString = Tcl_GetString(objv[1]);
	result = PgGetResultId(interp, queryResultString);
	if (result == (PGresult *)NULL)
	{
		Tcl_AppendResult(interp, "\n", queryResultString,
						 " is not a valid query result", (char *)NULL);
		return TCL_ERROR;
	}

	/* process command options */
	if (Tcl_GetIndexFromObj(interp, objv[2], options, "switch", TCL_EXACT,
							&optIndex) != TCL_OK)
		return TCL_ERROR;

	switch ((enum options) optIndex)
	{
		case OPT_STATUS:
			{
				char	   *resultStatus;

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				resultStatus = PQresStatus(PQresultStatus(result));
				Tcl_SetObjResult(interp, Tcl_NewStringObj(resultStatus, -1));
				return TCL_OK;
			}

		case OPT_ERROR:
			/* Fall through - these subcommands are now identical */

		case OPT_ERRORFIELD:
			{
				char   *fieldName;
				int		fieldCode;
				char   *errorField;

				if (objc == 3)
				{
					Tcl_SetObjResult(interp,
						Tcl_NewStringObj(PQresultErrorMessage(result), -1));
					return TCL_OK;
				}

				if (objc != 4)
				{
					Tcl_WrongNumArgs(interp, 3, objv, "?fieldName?");
					return TCL_ERROR;
				}

				fieldName = Tcl_GetString(objv[3]);
				if ((fieldCode = pg_result_errorfield_code(fieldName)) != 0
					&& (errorField = PQresultErrorField(result, fieldCode))
						 != NULL)
					Tcl_SetObjResult(interp, Tcl_NewStringObj(errorField, -1));
				return TCL_OK;
			}

		case OPT_CONN:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				return PgGetConnByResultId(interp, queryResultString);
			}

		case OPT_OID:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetLongObj(Tcl_GetObjResult(interp), PQoidValue(result));
				return TCL_OK;
			}

		case OPT_CLEAR:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				PgDelResultId(interp, queryResultString);
				PQclear(result);
				return TCL_OK;
			}

		case OPT_NUMTUPLES:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetIntObj(Tcl_GetObjResult(interp), PQntuples(result));
				return TCL_OK;
			}

		case OPT_CMDTUPLES:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetStringObj(Tcl_GetObjResult(interp), PQcmdTuples(result), -1);
				return TCL_OK;
			}

		case OPT_CMDSTATUS:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetStringObj(Tcl_GetObjResult(interp), PQcmdStatus(result), -1);
				return TCL_OK;
			}


		case OPT_NUMATTRS:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetIntObj(Tcl_GetObjResult(interp), PQnfields(result));
				return TCL_OK;
			}

		case OPT_ASSIGN:
			{
				Tcl_Obj    *fieldNameObj;
				Tcl_Obj    *arrVarObj;
				Tcl_Obj    *valueObj;
				int			ncols = PQnfields(result);
				int			nrows = PQntuples(result);

				if (objc != 4)
				{
					Tcl_WrongNumArgs(interp, 3, objv, "arrayName");
					return TCL_ERROR;
				}

				arrVarObj = objv[3];

				/*
				 * this assignment assigns the table of result tuples into
				 * a giant array with the name given in the argument. The
				 * indices of the array are of the form (tupno,attrName).
				 */
				for (tupno = 0; tupno < nrows; tupno++)
				{
					for (i = 0; i < ncols; i++)
					{
						/*
						 * Moving this into the loop and increasing the reference count
						 * became necessary at Tcl-8.5 because Tcl_ObjSetVar2
						 * now apparently saves a reference to the array index object.
						 */
						fieldNameObj = Tcl_NewObj();
						Tcl_IncrRefCount(fieldNameObj);

						/*
						 * construct the array element name consisting
						 * of the tuple number, a comma, and the field
						 * name.
						 * this is a little kludgey -- we set the obj
						 * to an int but the append following will force a
						 * string conversion.
						 */
						Tcl_SetIntObj(fieldNameObj, tupno);
						Tcl_AppendToObj(fieldNameObj, ",", 1);
						Tcl_AppendToObj(fieldNameObj, PQfname(result, i), -1);

						valueObj = result_get_obj(result, tupno, i);
						Tcl_IncrRefCount(valueObj);
						if (Tcl_ObjSetVar2(interp, arrVarObj, fieldNameObj, valueObj,
								TCL_LEAVE_ERR_MSG) == NULL) {
							Tcl_DecrRefCount(fieldNameObj);
							Tcl_DecrRefCount(valueObj);
							return TCL_ERROR;
						}
						Tcl_DecrRefCount(fieldNameObj);
						Tcl_DecrRefCount(valueObj);
					}
				}
				return TCL_OK;
			}

		case OPT_ASSIGNBYIDX:
			{
				Tcl_Obj 	*fieldNameObj;
				Tcl_Obj		*arrVarObj;
				Tcl_Obj		*valueObj;
				Tcl_Obj		*appendstrObj;
				Tcl_Obj		*field0;
				int			ncols = PQnfields(result);
				int			nrows = PQntuples(result);

				if ((objc != 4) && (objc != 5))
				{
					Tcl_WrongNumArgs(interp, 3, objv, "arrayName ?append_string?");
					return TCL_ERROR;
				}

				arrVarObj = objv[3];

				if (objc == 5)
					appendstrObj = objv[4];
				else
					appendstrObj = NULL;

				/*
				 * this assignment assigns the table of result tuples into
				 * a giant array with the name given in the argument.  The
				 * indices of the array are of the form
				 * (field0Value,attrNameappendstr). Here, we still assume
				 * PQfname won't exceed 200 characters, but we dare not
				 * make the same assumption about the data in field 0 nor
				 * the append string.
				 */
				for (tupno = 0; tupno < nrows; tupno++)
				{
					field0 = result_get_obj(result, tupno, 0);
					Tcl_IncrRefCount(field0);

					for (i = 1; i < ncols; i++)
					{
						fieldNameObj = Tcl_NewObj();
						Tcl_IncrRefCount(fieldNameObj);
						Tcl_SetObjLength(fieldNameObj, 0);
						Tcl_AppendObjToObj(fieldNameObj, field0);
						Tcl_AppendToObj(fieldNameObj, ",", 1);
						Tcl_AppendToObj(fieldNameObj, PQfname(result, i), -1);

						if (appendstrObj != NULL)
							Tcl_AppendObjToObj(fieldNameObj, appendstrObj);

						valueObj = result_get_obj(result, tupno, i);
						Tcl_IncrRefCount(valueObj);
						if (Tcl_ObjSetVar2(interp, arrVarObj, fieldNameObj, valueObj,
								TCL_LEAVE_ERR_MSG) == NULL)
						{
							Tcl_DecrRefCount(fieldNameObj);
							Tcl_DecrRefCount(field0);
							Tcl_DecrRefCount(valueObj);
							return TCL_ERROR;
						}
						Tcl_DecrRefCount(fieldNameObj);
						Tcl_DecrRefCount(valueObj);
					}
					Tcl_DecrRefCount(field0);
				}
				return TCL_OK;
			}

		case OPT_GETTUPLE:
			{
				Tcl_Obj    *resultObj;

				if (objc != 4)
				{
					Tcl_WrongNumArgs(interp, 3, objv, "tuple_number");
					return TCL_ERROR;
				}

				if (Tcl_GetIntFromObj(interp, objv[3], &tupno) == TCL_ERROR)
					return TCL_ERROR;

				if (tupno < 0 || tupno >= PQntuples(result))
				{
					Tcl_AppendResult(interp, "argument to getTuple cannot exceed number of tuples - 1", 0);
					return TCL_ERROR;
				}

				/* set the result object to be the list of values */
				resultObj = get_row_list_obj(interp, result, tupno);
				if (!resultObj)
					return TCL_ERROR;
				Tcl_IncrRefCount(resultObj);

				/* Make this object the interpreter result */
				Tcl_SetObjResult(interp, resultObj);
				Tcl_DecrRefCount(resultObj);

				return TCL_OK;
			}

		case OPT_TUPLEARRAY:
			{
				char	   *arrayName;
				int			ncols = PQnfields(result);

				if (objc != 5)
				{
					Tcl_WrongNumArgs(interp, 3, objv, "tuple_number array_name");
					return TCL_ERROR;
				}

				if (Tcl_GetIntFromObj(interp, objv[3], &tupno) == TCL_ERROR)
					return TCL_ERROR;

				if (tupno < 0 || tupno >= PQntuples(result))
				{
					Tcl_AppendResult(interp, "argument to tupleArray cannot exceed number of tuples - 1", 0);
					return TCL_ERROR;
				}

				arrayName = Tcl_GetString(objv[4]);

				for (i = 0; i < ncols; i++)
				{
					if (Tcl_SetVar2Ex(interp, arrayName, PQfname(result, i),
									result_get_obj(result, tupno, i),
									TCL_LEAVE_ERR_MSG) == NULL)
						return TCL_ERROR;
				}
				return TCL_OK;
			}

		case OPT_ATTRIBUTES:
			{
				Tcl_Obj    *resultObj = Tcl_GetObjResult(interp);
				int			ncols = PQnfields(result);

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetListObj(resultObj, 0, NULL);

				for (i = 0; i < ncols; i++)
				{
					Tcl_ListObjAppendElement(interp, resultObj,
							   Tcl_NewStringObj(PQfname(result, i), -1));
				}
				return TCL_OK;
			}

		case OPT_LATTRIBUTES:
			{
				Tcl_Obj    *resultObj = Tcl_GetObjResult(interp);
				int			ncols = PQnfields(result);

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetListObj(resultObj, 0, NULL);

				/* For each column: {name type size} */
				for (i = 0; i < ncols; i++)
				{
					Tcl_Obj    *subList = Tcl_NewListObj(0, NULL);

					Tcl_IncrRefCount(subList);
					if (Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewStringObj(PQfname(result, i), -1)
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewLongObj((long)PQftype(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewIntObj(PQfsize(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, resultObj, subList)
							== TCL_ERROR)
					{
						Tcl_DecrRefCount(subList);
						return TCL_ERROR;
					}
					Tcl_DecrRefCount(subList);
				}
				return TCL_OK;
			}

		case OPT_LXATTRIBUTES:
			{
				Tcl_Obj    *resultObj = Tcl_GetObjResult(interp);
				int			ncols = PQnfields(result);

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetListObj(resultObj, 0, NULL);

				/* For each column: {name type size sizemod format tblOid tblCol} */
				for (i = 0; i < ncols; i++)
				{
					Tcl_Obj    *subList = Tcl_NewListObj(0, NULL);

					Tcl_IncrRefCount(subList);
					if (Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewStringObj(PQfname(result, i), -1)
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewLongObj((long)PQftype(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewIntObj(PQfsize(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewIntObj(PQfmod(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewIntObj(PQfformat(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewLongObj((long)PQftable(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, subList,
							Tcl_NewLongObj((long)PQftablecol(result, i))
							) == TCL_ERROR

						|| Tcl_ListObjAppendElement(interp, resultObj, subList)
							== TCL_ERROR)
					{
						Tcl_DecrRefCount(subList);
						return TCL_ERROR;
					}
					Tcl_DecrRefCount(subList);
				}
				return TCL_OK;
			}

		case OPT_LIST: 
			{
				Tcl_Obj    *listObj;
				Tcl_Obj    *subListObj;
				int			nrows = PQntuples(result);

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}
 	
				listObj = Tcl_NewListObj(0, (Tcl_Obj **) NULL);
				Tcl_IncrRefCount(listObj);

				/*
				**	Loop through the tuple, and append each 
				**	value to the list
				**
				**	This option appends all of the values
				**	for each tuple to the same list
				**
				**  According to brett, it performs better when you make a
				**  sublist for each tuple and append the sublist to a main
				**  list, rather than appending each value separately.
				**  That's why this uses get_row_list_obj().
				*/
				for (tupno = 0; tupno < nrows; tupno++)
				{
					subListObj = get_row_list_obj(interp, result, tupno);
					if (!subListObj)
					{
						Tcl_DecrRefCount(listObj);
						return TCL_ERROR;
					}
					Tcl_IncrRefCount(subListObj);
					if (Tcl_ListObjAppendList(interp, listObj, subListObj) != TCL_OK)
					{
						Tcl_DecrRefCount(listObj);
						Tcl_DecrRefCount(subListObj);
						return TCL_ERROR;
					}
					Tcl_DecrRefCount(subListObj);
				}
				Tcl_SetObjResult(interp, listObj);
				Tcl_DecrRefCount(listObj);
				return TCL_OK;
			}

		case OPT_LLIST: 
			{
				Tcl_Obj    *listObj;
				Tcl_Obj	   *subListObj;
				int			nrows = PQntuples(result);
 	
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}
 	
				listObj = Tcl_NewListObj(0, (Tcl_Obj **) NULL);
				Tcl_IncrRefCount(listObj);
	
				/*
				**	This is the top level list. This
				**	contains the other lists
				**
				**	This option contructs a list of
				**	values for each tuple, and
				**	appends that to the main list.
				**	This is a list of lists
				*/
				for (tupno = 0; tupno < nrows; tupno++)
				{
					subListObj = get_row_list_obj(interp, result, tupno);
					if (!subListObj)
					{
						Tcl_DecrRefCount(listObj);
						return TCL_ERROR;
					}
					Tcl_IncrRefCount(subListObj);
					if (Tcl_ListObjAppendElement(interp, listObj, subListObj) != TCL_OK)
					{
						Tcl_DecrRefCount(listObj);
						Tcl_DecrRefCount(subListObj);
						return TCL_ERROR;
					}
					Tcl_DecrRefCount(subListObj);
				}
	
				Tcl_SetObjResult(interp, listObj);
				Tcl_DecrRefCount(listObj);
				return TCL_OK;
			}

		case OPT_GETNULL:
			{
				Tcl_Obj    *resultObj = Tcl_GetObjResult(interp);
				int			ncols = PQnfields(result);
				Tcl_Obj	   *trueObj, *falseObj;

				if (objc != 4)
				{
					Tcl_WrongNumArgs(interp, 3, objv, "tuple_number");
					return TCL_ERROR;
				}

				if (Tcl_GetIntFromObj(interp, objv[3], &tupno) == TCL_ERROR)
					return TCL_ERROR;

				if (tupno < 0 || tupno >= PQntuples(result))
				{
					Tcl_AppendResult(interp, "argument to getNull cannot exceed number of tuples - 1", 0);
					return TCL_ERROR;
				}

				Tcl_SetListObj(resultObj, 0, NULL);
				trueObj = Tcl_NewBooleanObj(1);
				Tcl_IncrRefCount(trueObj);
				falseObj = Tcl_NewBooleanObj(0);
				Tcl_IncrRefCount(falseObj);

				for (i = 0; i < ncols; i++)
				{
					Tcl_ListObjAppendElement(interp, resultObj,
						PQgetisnull(result, tupno, i) ? trueObj : falseObj);
				}
				Tcl_DecrRefCount(trueObj);
				Tcl_DecrRefCount(falseObj);

				return TCL_OK;
			}

#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
		case OPT_NUMPARAMS:
			{
				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetIntObj(Tcl_GetObjResult(interp), PQnparams(result));
				return TCL_OK;
			}
#endif

#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
		case OPT_PARAMTYPES:
			{
				Tcl_Obj    *resultObj = Tcl_GetObjResult(interp);
				int			nparams = PQnparams(result);

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

				Tcl_SetListObj(resultObj, 0, NULL);

				/* Loop over parameters to the prepared query */
				for (i = 0; i < nparams; i++)
				{
					if (Tcl_ListObjAppendElement(interp, resultObj,
						Tcl_NewIntObj(PQparamtype(result, i))) == TCL_ERROR) {
						return TCL_ERROR;
					}
				}
				return TCL_OK;
			}
#endif

		case OPT_DICT: /* Tcl 8.5 or higher */
			{
				Tcl_Obj		*dict;
				int			nrows = PQntuples(result);
				int			ncols = PQnfields(result);
				Tcl_Obj		*keyv[2];  /* 2-level dictionary key */
				Tcl_Obj     *valueObj;
				Tcl_Obj		**fieldNames; /* Array of field names */
				int			status = TCL_OK;

				if (objc != 3)
				{
					Tcl_WrongNumArgs(interp, 3, objv, NULL);
					return TCL_ERROR;
				}

#if TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION < 5 || TCL_MAJOR_VERSION < 8
				Tcl_AppendResult(interp,
					"pg_result -dict requires Tcl dictionary support\n", NULL);
				return TCL_ERROR;
#else
				/*
			 	 * Note: If this is built with Tcl8.5 stubs, but run under 8.4,
			 	 * calling Tcl_NewDictObj() will crash. To avoid that, because
			 	 * pgtclng does otherwise test out OK in that setup, do a
				 * runtime check for Tcl version.
			 	 */
				if (pgtcl_tcl_version < 8.5)
				{
					Tcl_AppendResult(interp,
						"pg_result -dict requires Tcl dictionary support\n",
						NULL);
					return TCL_ERROR;
				}

				dict = Tcl_NewDictObj();
				Tcl_IncrRefCount(dict);

				/*
				 * Make an array of objects holding field names, for use
				 * in the dictionary keys.
				 */
				fieldNames = (Tcl_Obj **)ckalloc(sizeof(Tcl_Obj *) * ncols);
				for (i = 0; i < ncols; i++)
				{
					fieldNames[i] = Tcl_NewStringObj(PQfname(result, i), -1);
					Tcl_IncrRefCount(fieldNames[i]);
				}

				/*
				 * Create a 2-level dictionary of query result values,
				 * with keys: rownum, fieldname.
				 */
				for (tupno = 0; tupno < nrows && status == TCL_OK; tupno++)
				{
					keyv[0] = Tcl_NewIntObj(tupno); /* 1st level key */
					Tcl_IncrRefCount(keyv[0]);

					for (i = 0; i < ncols && status == TCL_OK; i++)
					{
						keyv[1] = fieldNames[i]; /* 2nd level key: field name */
						valueObj = result_get_obj(result, tupno, i);
						Tcl_IncrRefCount(valueObj);
						status = Tcl_DictObjPutKeyList(interp, dict, 2, keyv,
										valueObj);
						Tcl_DecrRefCount(valueObj);
					}
					Tcl_DecrRefCount(keyv[0]);
				}

				/* Cleanup */
				for (i = 0; i < ncols; i++)
					Tcl_DecrRefCount(fieldNames[i]);
				ckfree((void *)fieldNames);

				if (status == TCL_OK)
					Tcl_SetObjResult(interp, dict);
				Tcl_DecrRefCount(dict);
				return status;
#endif /* Tcl >= 8.5 has dictionaries */
			}

		default:
			/*
			 * Note: This should never happen, since Tcl_GetIndexFromObj
			 * already checked for a valid switch.
			 */
			Tcl_AppendResult(interp, "pg_result: invalid option\n", NULL);
			return TCL_ERROR;
	}
}

/**********************************
 * result_get_obj

 Return a single result value as a Tcl_Obj. For Text format columns, return
 a StringObj. For Binary format columns, return a ByteArray object.
 The returned object has reference count 0.
 Note: This should be the *only* place in the package where we fetch a
 value from a query result - the only place libpq's PQgetvalue is used.
 **********************************/
static Tcl_Obj *
result_get_obj(PGresult *result, int tupno, int colno)
{
	if (PQfformat(result, colno) == 0)
		/* This is a Text format column */
		return Tcl_NewStringObj(PQgetvalue(result, tupno, colno), -1);

	/* This is a Binary format column */
	return Tcl_NewByteArrayObj((unsigned char *)PQgetvalue(result, tupno, colno),
		PQgetlength(result, tupno, colno));
}

/**********************************
 * get_row_list_obj

 Return the values for a result row as a list object.
 The row number tupno must be within range (checked by caller).
 On error (unlikely), returns NULL and leaves an error message in the
 interpreter.
 The returned object has reference count 0.
 **********************************/
static Tcl_Obj *
get_row_list_obj(Tcl_Interp *interp, PGresult *result, int tupno)
{
	int colno;
	Tcl_Obj *resultObj = Tcl_NewListObj(0, NULL);
	int ncols = PQnfields(result);

	for (colno = 0; colno < ncols; colno++)
	{
		if (Tcl_ListObjAppendElement(interp, resultObj,
				result_get_obj(result, tupno, colno)) == TCL_ERROR)
		{
			Tcl_DecrRefCount(resultObj); /* Free the object */
			return NULL;
		}
	}
	return resultObj; /* Return an object with refCount=0 */
}


/**********************************
 * pg_execute
 send a query string to the backend connection and process the result

 syntax:
 pg_execute ?-array name? ?-oid varname? connection query ?loop_body?

 the return result is the number of tuples processed. If the query
 returns tuples (i.e. a SELECT statement), the result is placed into
 variables
 **********************************/

int
Pg_execute(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	PGresult   *result;
	int			i;
	int			tupno;
	int			ntup;
	int			loop_rc = TCL_OK;
	char	   *array_varname = NULL;
	char	   *arg;
	char	   *connString;
	char	   *queryString;

	Tcl_Obj    *oid_varnameObj = NULL;
	Tcl_Obj    *evalObj;
	Tcl_Obj    *resultObj;

	char	   *usage = "?-array arrayname? ?-oid varname? "
	"connection queryString ?loop_body?";

	/*
	 * First we parse the options
	 */
	i = 1;
	while (i < objc)
	{
		arg = Tcl_GetString(objv[i]);
		if (arg[0] != '-')
			break;

		if (strcmp(arg, "-array") == 0)
		{
			/*
			 * The rows should appear in an array vs. to single variables
			 */
			i++;
			if (i == objc)
			{
				Tcl_WrongNumArgs(interp, 1, objv, usage);
				return TCL_ERROR;
			}

			array_varname = Tcl_GetString(objv[i++]);
			continue;
		}

		arg = Tcl_GetString(objv[i]);

		if (strcmp(arg, "-oid") == 0)
		{
			/*
			 * We should place PQoidValue() somewhere
			 */
			i++;
			if (i == objc)
			{
				Tcl_WrongNumArgs(interp, 1, objv, usage);
				return TCL_ERROR;
			}
			oid_varnameObj = objv[i++];
			continue;
		}

		Tcl_WrongNumArgs(interp, 1, objv, usage);
		return TCL_ERROR;
	}

	/*
	 * Check that after option parsing at least 'connection' and 'query'
	 * are left
	 */
	if (objc - i < 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, usage);
		return TCL_ERROR;
	}

	/*
	 * Get the connection and make sure no COPY command is pending
	 */
	connString = Tcl_GetString(objv[i++]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	/*
	 * Execute the query
	 */
	queryString = Tcl_GetString(objv[i++]);
	result = PQexec(conn, queryString);

	/*
	 * Transfer any notify events from libpq to Tcl event queue.
	 */
	PgNotifyTransferEvents(connid);

	/*
	 * Check for errors
	 */
	if (result == NULL)
	{
		Tcl_SetResult(interp, PQerrorMessage(conn), TCL_VOLATILE);
		return TCL_ERROR;
	}

	/*
	 * Set the oid variable to the returned oid of an INSERT statement if
	 * requested (or 0 if it wasn't an INSERT)
	 */
	if (oid_varnameObj != NULL)
	{
		Tcl_Obj *oidValue = Tcl_NewLongObj((long)PQoidValue(result));
		Tcl_IncrRefCount(oidValue);
		if (Tcl_ObjSetVar2(interp, oid_varnameObj, NULL, oidValue,
						   TCL_LEAVE_ERR_MSG) == NULL)
		{
			PQclear(result);
			Tcl_DecrRefCount(oidValue);
			return TCL_ERROR;
		}
		Tcl_DecrRefCount(oidValue);
	}

	/*
	 * Decide how to go on based on the result status
	 */
	switch (PQresultStatus(result))
	{
		case PGRES_TUPLES_OK:
			/* fall through if we have tuples */
			break;

		case PGRES_EMPTY_QUERY:
		case PGRES_COMMAND_OK:
			/* tell the number of affected tuples for non-SELECT queries */
			Tcl_SetObjResult(interp,
							 Tcl_NewStringObj(PQcmdTuples(result), -1));
			PQclear(result);
			return TCL_OK;

			/*
			 * Note: COPY_IN and COPY_OUT are not allowed with pg_execute
			 * because there is no result handle returned, and copy needs one.
			 * Return an error, but it probably is not recoverable because
			 * the connection is already in COPY mode.
			 */
		case PGRES_COPY_IN:
		case PGRES_COPY_OUT:
			Tcl_SetResult(interp, "Not allowed to start COPY with pg_execute",
				TCL_STATIC);
			PQclear(result);
			return TCL_ERROR;

		default:
			/* anything else must be an error */
			/* set the result object to be an empty list */
			resultObj = Tcl_GetObjResult(interp);
			Tcl_SetListObj(resultObj, 0, NULL);
			if (Tcl_ListObjAppendElement(interp, resultObj,
			   Tcl_NewStringObj(PQresStatus(PQresultStatus(result)), -1))
				== TCL_ERROR)
				return TCL_ERROR;

			if (Tcl_ListObjAppendElement(interp, resultObj,
					  Tcl_NewStringObj(PQresultErrorMessage(result), -1))
				== TCL_ERROR)
				return TCL_ERROR;

			PQclear(result);
			return TCL_ERROR;
	}

	/*
	 * We reach here only for queries that returned tuples
	 */
	if (i == objc)
	{
		/*
		 * We don't have a loop body. If we have at least one result row,
		 * we set all the variables to the first one and return.
		 */
		if (PQntuples(result) > 0)
		{
			if (execute_put_values(interp, array_varname, result, 0) != TCL_OK)
			{
				PQclear(result);
				return TCL_ERROR;
			}
		}

		Tcl_SetObjResult(interp, Tcl_NewIntObj(PQntuples(result)));
		PQclear(result);
		return TCL_OK;
	}

	/*
	 * We have a loop body. For each row in the result set, put the values
	 * into the Tcl variables and execute the body.
	 */
	ntup = PQntuples(result);
	evalObj = objv[i];
	for (tupno = 0; tupno < ntup; tupno++)
	{
		if (execute_put_values(interp, array_varname, result, tupno) != TCL_OK)
		{
			PQclear(result);
			return TCL_ERROR;
		}

		loop_rc = Tcl_EvalObjEx(interp, evalObj, 0);

		/* The returncode of the loop body controls the loop execution */
		if (loop_rc == TCL_CONTINUE)
		{
			loop_rc = TCL_OK;   /* Continue is the same as OK from here on */
		}
		else if (loop_rc != TCL_OK)  /* Not OK or Continue - stop looping */
		{
			if (loop_rc == TCL_ERROR)
			{
				/* Show where the error occurred */
				char		msg[60];

				sprintf(msg, "\n    (\"pg_execute\" body line %d)",
						Get_ErrorLine(interp));
				Tcl_AddErrorInfo(interp, msg);
			}
			else if (loop_rc == TCL_BREAK)
			{
				/* On break, break out but return OK */
				loop_rc = TCL_OK;
			}
			break;
		}
	}

	/*
	 * At the end of the loop we put the number of rows we got into the
	 * interpreter result, but only on normal return, and clear the result set.
	 */
	if (loop_rc == TCL_OK)
		Tcl_SetObjResult(interp, Tcl_NewIntObj(ntup));
	PQclear(result);

	return loop_rc;
}


/**********************************
 * execute_put_values

 Put the values of one tuple into Tcl variables named like the
 column names, or into an array indexed by the column names.
 **********************************/
static int
execute_put_values(Tcl_Interp *interp, char *array_varname,
				   PGresult *result, int tupno)
{
	int			i;
	int			n;
	Tcl_Obj	   *value;
	/*
	 * Note: "gcc -Wall" reports that the following two variables
	 * "may be used uninitialized" if not assigned here. That is
	 * not possible, but initialize them anyway to quiet gcc.
	 */
	char	   *varname = NULL;
	char	   *indexname = NULL;

	/*
	 * Loop-invariant parts of variable name varname(indexname):
	 */
	if (array_varname != NULL)
		varname = array_varname;
	else
		indexname = NULL;

	/*
	 * For each column get the column name and value and put it into a Tcl
	 * variable (either scalar or array item)
	 */
	n = PQnfields(result);
	for (i = 0; i < n; i++)
	{
		value = result_get_obj(result, tupno, i);
		Tcl_IncrRefCount(value);

		/*
		 * Loop-variant parts of variable name varname(indexname):
		 */
		if (array_varname != NULL)
			indexname = PQfname(result, i);
		else
			varname = PQfname(result, i);

		if (Tcl_SetVar2Ex(interp, varname, indexname, value,
						TCL_LEAVE_ERR_MSG) == NULL)
		{
			Tcl_DecrRefCount(value);
			return TCL_ERROR;
		}
		Tcl_DecrRefCount(value);
	}
	return TCL_OK;
}

/**********************************
 * pg_lo_open
	 open a large object

 syntax:
 pg_lo_open conn objOid mode

 where mode can be either 'r', 'w', or 'rw'

 returns: a large object file ID
 on error: throws a Tcl error.
**********************/

int
Pg_lo_open(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			lobjId;
	int			mode;
	int			fd;
	char	   *connString;
	char	   *modeString;
	int			modeStringLen;

	if (objc != 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection lobjOid mode");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &lobjId) == TCL_ERROR)
		return TCL_ERROR;

	modeString = Tcl_GetStringFromObj(objv[3], &modeStringLen);
	if ((modeStringLen < 1) || (modeStringLen > 2))
	{
		Tcl_AppendResult(interp, "mode argument must be 'r', 'w', or 'rw'", 0);
		return TCL_ERROR;
	}

	switch (modeString[0])
	{
		case 'r':
		case 'R':
			mode = INV_READ;
			break;
		case 'w':
		case 'W':
			mode = INV_WRITE;
			break;
		default:
			Tcl_AppendResult(interp, "mode argument must be 'r', 'w', or 'rw'", 0);
			return TCL_ERROR;
	}

	switch (modeString[1])
	{
		case '\0':
			break;
		case 'r':
		case 'R':
			mode |= INV_READ;
			break;
		case 'w':
		case 'W':
			mode |= INV_WRITE;
			break;
		default:
			Tcl_AppendResult(interp, "mode argument must be 'r', 'w', or 'rw'", 0);
			return TCL_ERROR;
	}

	fd = lo_open(conn, lobjId, mode);
	/* Note: undocumented but true, lo_open returns -1 on error */
	if (fd == -1)
	{
		Tcl_AppendResult(interp, "Large Object open failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(fd));
	return TCL_OK;
}

/**********************************
 * pg_lo_close
	 close a large object

 syntax:
 pg_lo_close conn fd

 returns: nothing
 on error: throws a Tcl error.
**********************/
int
Pg_lo_close(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	char	   *connString;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection fd");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	if (lo_close(conn, fd) < 0)
	{
		Tcl_AppendResult(interp, "Large Object close failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	return TCL_OK;
}

/**********************************
 * pg_lo_read
	 reads at most len bytes from a large object into a variable named
 bufVar

 syntax:
 pg_lo_read conn fd bufVar len

 bufVar is the name of a variable in which to store the contents of the read

 returns: the number of bytes read.
 on error: on parameter error, throws a Tcl error, but on a database error
	returns a negative number and status TCL_OK. It should throw an error in
    this case too, but too late - it was already documented to work this way.
**********************/
int
Pg_lo_read(ClientData cData, Tcl_Interp *interp, int objc,
		   Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	int			nbytes = 0;
	char	   *buf;
	Tcl_Obj    *bufVar;
	Tcl_Obj    *bufObj;
	int			len;
	int			rc = TCL_OK;

	if (objc != 5)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd bufVar len");
		return TCL_ERROR;
	}

	conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]),
							 (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	bufVar = objv[3];

	if (Tcl_GetIntFromObj(interp, objv[4], &len) != TCL_OK)
		return TCL_ERROR;

	if (len <= 0)
	{
		Tcl_SetObjResult(interp, Tcl_NewIntObj(nbytes));
		return TCL_OK;
	}

	buf = ckalloc(len + 1);

	nbytes = lo_read(conn, fd, buf, len);

	if (nbytes >= 0)
	{
#if TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION >= 1 || TCL_MAJOR_VERSION > 8
		bufObj = Tcl_NewByteArrayObj((unsigned char *)buf, nbytes);
#else
		bufObj = Tcl_NewStringObj(buf, nbytes);
#endif
		Tcl_IncrRefCount(bufObj);
		if (Tcl_ObjSetVar2(interp, bufVar, NULL, bufObj,
						   TCL_LEAVE_ERR_MSG | TCL_PARSE_PART1) == NULL)
			rc = TCL_ERROR;
		Tcl_DecrRefCount(bufObj);
	}

	if (rc == TCL_OK)
		Tcl_SetObjResult(interp, Tcl_NewIntObj(nbytes));

	ckfree(buf);
	return rc;
}

/***********************************
Pg_lo_write
   write at most len bytes to a large object

 syntax:
 pg_lo_write conn fd buf len

 returns: the number of bytes written.
 on error: on parameter error, throws a Tcl error, but on a database error
	returns a negative number and status TCL_OK. It should throw an error in
    this case too, but too late - it was already documented to work this way.
***********************************/
int
Pg_lo_write(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	char	   *buf;
	int			fd;
	int			nbytes = 0;
	int			len;

	if (objc != 5)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd buf len");
		return TCL_ERROR;
	}

	conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]),
							 (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

#if TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION >= 1 || TCL_MAJOR_VERSION > 8
	buf = (char *)Tcl_GetByteArrayFromObj(objv[3], &nbytes);
#else
	buf = Tcl_GetStringFromObj(objv[3], &nbytes);
#endif

	if (Tcl_GetIntFromObj(interp, objv[4], &len) != TCL_OK)
		return TCL_ERROR;

	if (len > nbytes)
		len = nbytes;

	if (len <= 0)
		nbytes = 0;
	else
		nbytes = lo_write(conn, fd, buf, len);
	
	Tcl_SetObjResult(interp, Tcl_NewIntObj(nbytes));
	return TCL_OK;
}

/***********************************
Pg_lo_lseek
	seek to a certain position in a large object

syntax
  pg_lo_lseek conn fd offset whence

whence can be either
"SEEK_CUR", "SEEK_END", or "SEEK_SET"

 returns: the new position in the object
 on error: throws a Tcl error.
***********************************/
int
Pg_lo_lseek(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	char	   *whenceStr;
	int			offset;
	int			whence;
	char	   *connString;
	int			newOffset;

	if (objc != 5)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd offset whence");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[3], &offset) == TCL_ERROR)
		return TCL_ERROR;

	whenceStr = Tcl_GetString(objv[4]);

	if (strcmp(whenceStr, "SEEK_SET") == 0)
		whence = SEEK_SET;
	else if (strcmp(whenceStr, "SEEK_CUR") == 0)
		whence = SEEK_CUR;
	else if (strcmp(whenceStr, "SEEK_END") == 0)
		whence = SEEK_END;
	else
	{
		Tcl_AppendResult(interp, "'whence' must be SEEK_SET, SEEK_CUR or SEEK_END", 0);
		return TCL_ERROR;
	}

	newOffset = lo_lseek(conn, fd, offset, whence);
	if (newOffset == -1)
	{
		Tcl_AppendResult(interp, "Large Object seek failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, Tcl_NewIntObj(newOffset));
	return TCL_OK;
}

/***********************************
Pg_lo_lseek64
	seek to a certain position in a large object, 64-bit version

syntax
  pg_lo_lseek64 conn fd offset whence

whence can be either
"SEEK_CUR", "SEEK_END", or "SEEK_SET"

 returns: the new position in the object
 on error: throws a Tcl error.
***********************************/
#ifdef HAVE_LO_TELL64 /* lo_lseek64 was added together with lo_tell64 */
int
Pg_lo_lseek64(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	char	   *whenceStr;
	Tcl_WideInt	toffset64;
	pg_int64	offset, newOffset;
	int			whence;
	char	   *connString;

	if (objc != 5)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd offset whence");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	/* The Tcl_WideInt and pg_int64 types might be identical, but it seems
	   to be safer to assume they are assignment-compatible rather than
	   allowing a pointer to one to be used in a function expecting the
	   other.
	*/
	if (Tcl_GetWideIntFromObj(interp, objv[3], &toffset64) == TCL_ERROR)
		return TCL_ERROR;
	offset = toffset64;   /* "Type" conversion */

	whenceStr = Tcl_GetString(objv[4]);

	if (strcmp(whenceStr, "SEEK_SET") == 0)
		whence = SEEK_SET;
	else if (strcmp(whenceStr, "SEEK_CUR") == 0)
		whence = SEEK_CUR;
	else if (strcmp(whenceStr, "SEEK_END") == 0)
		whence = SEEK_END;
	else
	{
		Tcl_AppendResult(interp, "'whence' must be SEEK_SET, SEEK_CUR or SEEK_END", 0);
		return TCL_ERROR;
	}

	newOffset = lo_lseek64(conn, fd, offset, whence);

	if (newOffset == -1)
	{
		Tcl_AppendResult(interp, "Large Object seek failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}

	toffset64 = newOffset; /* Possible type conversion */
	Tcl_SetObjResult(interp, Tcl_NewWideIntObj(toffset64));
	return TCL_OK;
}
#endif


/***********************************
Pg_lo_creat
   create a new large object with mode

 syntax:
   pg_lo_creat conn mode

mode can be any OR'ing together of INV_READ, INV_WRITE,
for now, we don't support any additional storage managers.

 returns: a large object OID
 on error: throws a Tcl error.
***********************************/
int
Pg_lo_creat(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	char	   *modeStr;
	char	   *modeWord;
	int			mode;
	char	   *connString;
	int			loid;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn mode");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	modeStr = Tcl_GetString(objv[2]);

	modeWord = strtok(modeStr, "|");
	if (strcmp(modeWord, "INV_READ") == 0)
		mode = INV_READ;
	else if (strcmp(modeWord, "INV_WRITE") == 0)
		mode = INV_WRITE;
	else
	{
		Tcl_AppendResult(interp,
						 "mode must be some OR'd combination of INV_READ, and INV_WRITE", 0);
		return TCL_ERROR;
	}

	while ((modeWord = strtok((char *)NULL, "|")) != NULL)
	{
		if (strcmp(modeWord, "INV_READ") == 0)
			mode |= INV_READ;
		else if (strcmp(modeWord, "INV_WRITE") == 0)
			mode |= INV_WRITE;
		else
		{
			Tcl_AppendResult(interp,
							 "mode must be some OR'd combination of INV_READ, INV_WRITE", 0);
			return TCL_ERROR;
		}
	}

	loid = lo_creat(conn, mode);
	/* Note: undocumented but true, lo_creat returns InvalidOid on error */
	if (loid == InvalidOid)
	{
		Tcl_AppendResult(interp, "Large Object create failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(loid));
	return TCL_OK;
}

/***********************************
Pg_lo_tell
	returns the current seek location of the large object

 syntax:
   pg_lo_tell conn fd

 returns: the current position in the object
 on error: throws a Tcl error.
***********************************/
int
Pg_lo_tell(ClientData cData, Tcl_Interp *interp, int objc,
		   Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	char	   *connString;
	int			offset;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	offset = lo_tell(conn, fd);
	if (offset == -1)
	{
		Tcl_AppendResult(interp, "Large Object tell offset failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(offset));
	return TCL_OK;
}

/***********************************
Pg_lo_tell64
	returns the current seek location of the large object, 64-bit version

 syntax:
   pg_lo_tell64 conn fd

 returns: the current position in the object
 on error: throws a Tcl error.
***********************************/
#ifdef HAVE_LO_TELL64
int
Pg_lo_tell64(ClientData cData, Tcl_Interp *interp, int objc,
		   Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	char	   *connString;
	pg_int64	offset;
	Tcl_WideInt	toffset64;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	offset = lo_tell64(conn, fd);
	if (offset == -1)
	{
		Tcl_AppendResult(interp, "Large Object tell offset failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	toffset64 = offset; /* Possible "type" conversion */
	Tcl_SetObjResult(interp, Tcl_NewWideIntObj(toffset64));
	return TCL_OK;
}
#endif

/***********************************
Pg_lo_unlink
	unlink a file based on lobject id

 syntax:
   pg_lo_unlink conn lobjId


 returns: nothing
 on error: throws a Tcl error.
***********************************/
int
Pg_lo_unlink(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			lobjId;
	char	   *connString;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &lobjId) == TCL_ERROR)
		return TCL_ERROR;

	if (lo_unlink(conn, lobjId) < 0)
	{
		Tcl_AppendResult(interp, "Large Object unlink failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	return TCL_OK;
}

/***********************************
Pg_lo_import
	import a Unix file into an (inversion) large objct

 syntax:
   pg_lo_import conn filename

 returns: OID of the imported large object
 on error: throws a Tcl error.
***********************************/

int
Pg_lo_import(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	const char *filename;
	Oid			lobjId;
	char	   *connString;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn filename");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	filename = Tcl_GetString(objv[2]);

	lobjId = lo_import(conn, filename);
	if (lobjId == InvalidOid)
	{
		Tcl_AppendResult(interp, "Large Object import of '", filename,
			"' failed\n", PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}

	Tcl_SetLongObj(Tcl_GetObjResult(interp), (long)lobjId);
	return TCL_OK;
}

/***********************************
Pg_lo_export
	export an Inversion large object to a Unix file

 syntax:
   pg_lo_export conn lobjId filename

 returns: nothing
 on error: throws a Tcl error.
***********************************/

int
Pg_lo_export(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	const char *filename;
	Oid			lobjId;
	char	   *connString;

	if (objc != 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn lobjId filename");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	/*
	 * Note: casting Oid lobjId to int for GetIntFromObj just hides the
	 * real problem - lack of unsigned int in Tcl objects.
	 */
	if (Tcl_GetIntFromObj(interp, objv[2], (int *)&lobjId) == TCL_ERROR)
		return TCL_ERROR;

	filename = Tcl_GetString(objv[3]);

	if (lo_export(conn, lobjId, filename) == -1)
	{
		Tcl_AppendResult(interp, "Large Object export to '", filename,
			"' failed\n", PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}
	return TCL_OK;
}

/***********************************
Pg_lo_truncate
	Truncate (or extend) the size of a large object
Note: This requires PostgreSQL libpq >= 8.3

syntax
  pg_lo_truncate conn fd length

 returns zero if OK.
 on error: throws a Tcl error.
***********************************/
#ifdef HAVE_LO_TRUNCATE /* PostgreSQL >= 8.3.0 */
int
Pg_lo_truncate(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	int			length;
	char	   *connString;
	int			result;

	if (objc != 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd length");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[3], &length) == TCL_ERROR)
		return TCL_ERROR;

	result = lo_truncate(conn, fd, length);
	if (result < 0)
	{
		Tcl_AppendResult(interp, "Large Object truncate failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, Tcl_NewIntObj(result));
	return TCL_OK;
}
#endif

/***********************************
Pg_lo_truncate64
	Truncate (or extend) the size of a large object, 64-bit version

syntax
  pg_lo_truncate64 conn fd length

 returns zero if OK.
 on error: throws a Tcl error.
***********************************/
#ifdef HAVE_LO_TELL64 /* lo_truncate64 was added together with lo_tell64 */
int
Pg_lo_truncate64(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	int			fd;
	Tcl_WideInt	tlength;
	pg_int64	length;
	char	   *connString;
	int			result;

	if (objc != 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn fd length");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	if (Tcl_GetIntFromObj(interp, objv[2], &fd) != TCL_OK)
		return TCL_ERROR;

	if (Tcl_GetWideIntFromObj(interp, objv[3], &tlength) == TCL_ERROR)
		return TCL_ERROR;
	length = tlength;   /* Possible "type" conversion */

	result = lo_truncate64(conn, fd, length);
	if (result < 0)
	{
		Tcl_AppendResult(interp, "Large Object truncate failed\n",
			PQerrorMessage(conn), NULL);
		return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, Tcl_NewIntObj(result));
	return TCL_OK;
}
#endif

/**********************************
pg_select_helper - Helper for pg_select

This is the core processing for pg_select.
(This is a separate function to make error handling easier to follow.)
Returns a TCL status: TCL_OK if OK, else TCL_ERROR, or a status returned
from the script (such as TCL_RETURN or another code).
**********************************/

static int
pg_select_helper(Tcl_Interp *interp, PGresult *result, Tcl_Obj *varNameObj,
		Tcl_Obj **column_names, Tcl_Obj *script)
{
	int		tupno,
			ntuples,
			column,
			ncols,
			r,
			err;
	Tcl_Obj	*value;
	char	*varNameString;
	char	msg[60];


	varNameString = Tcl_GetString(varNameObj);

	ncols = PQnfields(result);
	ntuples = PQntuples(result);

	/* Loop over all the rows of the query result: */
	for (tupno = 0; tupno < ntuples; tupno++)
	{
		/* Set Array(.tupno) to the row number: */
		if (Tcl_SetVar2Ex(interp, varNameString, ".tupno",
				Tcl_NewIntObj(tupno), TCL_LEAVE_ERR_MSG) == NULL)
			return TCL_ERROR;

		for (column = 0; column < ncols; column++)
		{
			value = result_get_obj(result, tupno, column);
			Tcl_IncrRefCount(value);
			err = (Tcl_ObjSetVar2(interp, varNameObj, column_names[column],
								value, TCL_LEAVE_ERR_MSG) == NULL);
			Tcl_DecrRefCount(value);
			if (err)
				return TCL_ERROR;
		}

		r = Tcl_EvalObjEx(interp, script, 0);
		if (r != TCL_OK && r != TCL_CONTINUE)
		{
			if (r == TCL_BREAK)
				break;			/* exit loop, but return TCL_OK */

			if (r == TCL_ERROR)
			{
				sprintf(msg, "\n    (\"pg_select\" body line %d)",
						Get_ErrorLine(interp));
				Tcl_AddErrorInfo(interp, msg);
			}
			return r;
		}
	}
	return TCL_OK;
}

/**********************************
 * pg_select
 send a select query string to the backend connection and loop over the result rows.

 syntax:
 pg_select connection query var proc

 The query must be a select statement
 The var is used in the proc as an array
 The proc is run once for each row found

 The return is either TCL_OK, TCL_ERROR or TCL_RETURN and interp->result
 may contain more information.
 **********************************/

int
Pg_select(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	PGresult   *result;
	int			retval;
	int			column;
	int			ncols;
	char	   *connString;
	char	   *queryString;
	char	   *varNameString;
	Tcl_Obj    *varNameObj;
	Tcl_Obj    *procStringObj;
	Tcl_Obj    *columnListObj;
	Tcl_Obj   **columnNameObjs;

	if (objc != 5)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection queryString var proc");
		return TCL_ERROR;
	}

	retval = TCL_OK;

	connString = Tcl_GetString(objv[1]);
	queryString = Tcl_GetString(objv[2]);

	varNameObj = objv[3];
	varNameString = Tcl_GetString(varNameObj);

	procStringObj = objv[4];

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	/* Execute the query: */
	if ((result = PQexec(conn, queryString)) == NULL)
	{
		/* error occurred sending the query */
		Tcl_SetResult(interp, PQerrorMessage(conn), TCL_VOLATILE);
		return TCL_ERROR;
	}

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	/* Check query result status: */
	if (PQresultStatus(result) != PGRES_TUPLES_OK)
	{
		/* query failed, or it wasn't SELECT (which is also an error). */
		Tcl_SetResult(interp, (char *)PQresultErrorMessage(result),
					  TCL_VOLATILE);
		PQclear(result);
		return TCL_ERROR;
	}

	ncols = PQnfields(result);

	/* Allocate space and fill an array of column names as Tcl objects: */
	columnNameObjs = (Tcl_Obj **)ckalloc(sizeof(Tcl_Obj *) * ncols);
	for (column = 0; column < ncols; column++)
	{
		columnNameObjs[column] = Tcl_NewStringObj(PQfname(result, column), -1);
		Tcl_IncrRefCount(columnNameObjs[column]);
	}


	/* Set Array(.numcols) to the number of result columns.
		Note: This used to set Array(.command) = "update" but that was
		never documented or explained and seemed to have no purpose.
	*/
	if (Tcl_SetVar2Ex(interp, varNameString, ".numcols", Tcl_NewIntObj(ncols),
					TCL_LEAVE_ERR_MSG) == NULL)
		retval = TCL_ERROR;
	else {
		/* Set Array(.headers) to be a Tcl list of column names: */
		columnListObj = Tcl_NewListObj(ncols, columnNameObjs);
		Tcl_IncrRefCount(columnListObj);
		if (Tcl_SetVar2Ex(interp, varNameString, ".headers", columnListObj,
							TCL_LEAVE_ERR_MSG) == NULL)
			retval = TCL_ERROR;
		Tcl_DecrRefCount(columnListObj);
	}

	/* The helper function does the rest of the work. */
	if (retval != TCL_ERROR)
		retval = pg_select_helper(interp, result, varNameObj, columnNameObjs, procStringObj);

	/* Cleanup - deallocate space, free objects, free the result structure */
	for (column = 0; column < ncols; column++)
		Tcl_DecrRefCount(columnNameObjs[column]);
	ckfree((void *)columnNameObjs);
	Tcl_UnsetVar(interp, varNameString, 0);
	PQclear(result);
	return retval;
}

/*
 * Test whether any callbacks are registered on this connection for
 * the given relation name.  NB: supplied name must be case-folded already.
 */

static int
Pg_have_listener(Pg_ConnectionId * connid, CONST char *relname)
{
	Pg_TclNotifies *notifies;
	Tcl_HashEntry *entry;

	for (notifies = connid->notify_list;
		 notifies != NULL;
		 notifies = notifies->next)
	{
		Tcl_Interp *interp = notifies->interp;

		if (interp == NULL)
			continue;			/* ignore deleted interpreter */

		entry = Tcl_FindHashEntry(&notifies->notify_hash, (char *)relname);
		if (entry == NULL)
			continue;			/* no pg_listen in this interpreter */

		return TRUE;			/* OK, there is a listener */
	}

	return FALSE;				/* Found no listener */
}

/*
 * Find or make a Pg_TclNotifies struct for this interp and connection.
 * This is used by Pg_listen() and Pg_on_connection_loss().
 */
static Pg_TclNotifies *
Pg_get_notifies(Tcl_Interp *interp, Pg_ConnectionId *connid)
{
	Pg_TclNotifies *notifies;

	for (notifies = connid->notify_list; notifies; notifies = notifies->next)
	{
		if (notifies->interp == interp)
			break;
	}

	if (notifies == NULL)
	{
		notifies = (Pg_TclNotifies *) ckalloc(sizeof(Pg_TclNotifies));
		notifies->interp = interp;
		Tcl_InitHashTable(&notifies->notify_hash, TCL_STRING_KEYS);
		notifies->conn_loss_cmd = NULL;
		notifies->next = connid->notify_list;
		connid->notify_list = notifies;
		Tcl_CallWhenDeleted(interp, PgNotifyInterpDelete, (ClientData)notifies);
	}
	return notifies;
}


/***********************************
Pg_listen
	create or remove a callback request for notifies on a given name

 syntax:
   pg_listen ?-pid? conn notifyname ?callbackcommand?

   With a callbackcommand arg, creates or changes the callback command for
   notifies on the given name; without, cancels the callback request.

   The -pid argument results in appending the notifying process' PID to
   the callback as an argument. If the NOTIFY message includes a non-empty
   payload (available with PostgreSQL-9.0 and up), then the payload will be
   appended to the command as an argument. The callback command (function)
   must defined the payload as an optional argument.

   The callback is stored in a hash table from the connection structure.
   A flag is set in the table if -pid was provided. This tells
   Pg_Notify_EventProc() in pgtclId.c to include the PID argument to the
   callback.

   Callbacks can occur whenever Tcl is executing its event loop.
   This is the normal idle loop in Tk; in plain tclsh applications,
   vwait or update can be used to enter the Tcl event loop.
***********************************/
int
Pg_listen(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	const char *origrelname;
	char	   *caserelname;
	char	   *callback = NULL;
	Pg_TclNotifies *notifies;
	Tcl_HashEntry *entry;
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	PGresult   *result;
	int			new;
	char	   *connString;
	int			callbackStrlen = 0;
	int         origrelnameStrlen;
	Pg_notify_command  *notifCmd;
	int			pass_pid = 0; /* Flag: -pid was used? */
	int			arg_n = 1; /* Argument pointer */

	/* Check for -pid argument */
	if (objc > 1 && strcmp(Tcl_GetString(objv[1]), "-pid") == 0)
	{
		pass_pid = 1;
		arg_n++;
		objc--;
	}

	if (objc < 3 || objc > 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "?options? connection relname ?callback?");
		return TCL_ERROR;
	}

	/*
	 * Get the command arguments. Note that the relation name will be
	 * copied by Tcl_CreateHashEntry while the callback string must be
	 * allocated by us.
	 */
	connString = Tcl_GetString(objv[arg_n++]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 0))
		return TCL_ERROR;

	/*
	 * LISTEN/NOTIFY do not preserve case unless the relation name is
	 * quoted.	We have to do the same thing to ensure that we will find
	 * the desired pg_listen item.
	 */
	origrelname = Tcl_GetStringFromObj(objv[arg_n++], &origrelnameStrlen);
	caserelname = (char *)ckalloc((unsigned)(origrelnameStrlen + 1));
	if (*origrelname == '"')
	{
		/* Copy a quoted string without downcasing */
		strcpy(caserelname, origrelname + 1);
		caserelname[origrelnameStrlen - 2] = '\0';
	}
	else
	{
		/* Downcase it */
		const char *rels = origrelname;
		char	   *reld = caserelname;

		while (*rels)
			*reld++ = tolower((unsigned char)*rels++);
		*reld = '\0';
	}

	if (objc > 3)
	{
		char	   *callbackStr;

		callbackStr = Tcl_GetStringFromObj(objv[arg_n++], &callbackStrlen);
		callback = ckalloc(callbackStrlen + 1);
		strcpy(callback, callbackStr);
	}

	/* Find or make a Pg_TclNotifies struct for this interp and connection */
	notifies = Pg_get_notifies(interp, connid);

	if (callback)
	{
		/*
		 * Create or update a callback for a relation
		 */
		int			alreadyHadListener = Pg_have_listener(connid, caserelname);

		entry = Tcl_CreateHashEntry(&notifies->notify_hash, caserelname, &new);
		/* If update, free the old callback string and containing struct */
		if (!new)
		{
			notifCmd = (Pg_notify_command *)Tcl_GetHashValue(entry);
			if (notifCmd->callback) ckfree(notifCmd->callback);
			ckfree((char *)notifCmd);
		}

		/* Store the new callback string */
		notifCmd = (Pg_notify_command *)ckalloc(sizeof(Pg_notify_command));
		notifCmd->callback = callback;
		notifCmd->use_pid = pass_pid;
		Tcl_SetHashValue(entry, notifCmd);

		/* Start the notify event source if it isn't already running */
		PgStartNotifyEventSource(connid);

		/*
		 * Send a LISTEN command if this is the first listener.
		 */
		if (!alreadyHadListener)
		{
			char	   *cmd = (char *)ckalloc((unsigned)(origrelnameStrlen + 8));

			sprintf(cmd, "LISTEN %s", origrelname);
			result = PQexec(conn, cmd);
			ckfree(cmd);
			/* Transfer any notify events from libpq to Tcl event queue. */
			PgNotifyTransferEvents(connid);
			if (PQresultStatus(result) != PGRES_COMMAND_OK)
			{
				/* Error occurred during the execution of command */
				PQclear(result);
				ckfree(callback);
				ckfree((char *)notifCmd);
				Tcl_DeleteHashEntry(entry);
				ckfree(caserelname);
				Tcl_SetResult(interp, PQerrorMessage(conn), TCL_VOLATILE);
				return TCL_ERROR;
			}
			PQclear(result);
		}
	}
	else
	{
		/*
		 * Remove a callback for a relation
		 */
		entry = Tcl_FindHashEntry(&notifies->notify_hash, caserelname);
		if (entry == NULL)
		{
			Tcl_AppendResult(interp, "not listening on ", origrelname, 0);
			ckfree(caserelname);
			return TCL_ERROR;
		}

		notifCmd = (Pg_notify_command *)Tcl_GetHashValue(entry);
		if (notifCmd->callback) ckfree(notifCmd->callback);
		ckfree((char *)notifCmd);
		Tcl_DeleteHashEntry(entry);

		/*
		 * Send an UNLISTEN command if that was the last listener. Note:
		 * we don't attempt to turn off the notify mechanism if no LISTENs
		 * remain active; not worth the trouble.
		 */
		if (!Pg_have_listener(connid, caserelname))
		{
			char	   *cmd = (char *)
			ckalloc((unsigned)(origrelnameStrlen + 10));

			sprintf(cmd, "UNLISTEN %s", origrelname);
			result = PQexec(conn, cmd);
			ckfree(cmd);
			/* Transfer any notify events from libpq to Tcl event queue. */
			PgNotifyTransferEvents(connid);
			if (PQresultStatus(result) != PGRES_COMMAND_OK)
			{
				/* Error occurred during the execution of command */
				PQclear(result);
				ckfree(caserelname);
				Tcl_SetResult(interp, PQerrorMessage(conn), TCL_VOLATILE);
				return TCL_ERROR;
			}
			PQclear(result);
		}
	}

	ckfree(caserelname);
	return TCL_OK;
}

/**********************************
 * pg_sendquery
 send a query string to the backend connection

 syntax:
 pg_sendquery connection query ?param...?

 Optional args are used as parameters to PQsendQueryParams(). This allows
 only text format, untyped parameters.

 Returns OK status if the command was dispatched, or throws a Tcl error
 on error.
 **********************************/
int
Pg_sendquery(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;
	char	   *execString;
	int			status;
	const char *const *paramValues;
	int			nParams;

	nParams = objc - 3;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection queryString ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 1))
		return TCL_ERROR;

	execString = Tcl_GetString(objv[2]);

	if (nParams > 0)
	{
		get_param_values(interp, &objv[3], nParams, /* allParamsText = */ 1,
			/* paramFormats = */ NULL, &paramValues,
			/* paramLengths_result = */ NULL);

		status = PQsendQueryParams(conn, execString, nParams, NULL,
					paramValues, NULL, NULL, /* resultFormat= */ 0);

		if (paramValues)
			Tcl_Free((char *)paramValues);

	} else {
		status = PQsendQuery(conn, execString);
	}

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (status)
		return TCL_OK;
	else
	{
		/* error occurred during the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}
}

/**********************************
 * pg_sendquery_prepared
 send a query using a prepared query to the backend connection

 syntax:
 pg_sendquery_prepared connection statementName resultFormatList \
     argFormatList ?param...?

 This is similar to pg_exec_prepared, but asynchronous like pg_sendquery.

 argFormatList is empty (= same as T), a single word T|B|TEXT|BINARY, or
 a list of those words, describing each argument as text or binary. If a
 single word, it applies to all arguments.  (Actually, anything starting
 with B means Binary, and anything else means Text. There is no error
 checking.)

 resultFormatList is similar to argFormatList except that it applies to the
 columns of the results. Currently,  all result parameters must be text, or
 all must be binary (this is a libpq limitation, not a PostgreSQL
 limitation). So you might as well specify a single word BINARY or leave it
 empty.

 Returns OK status if the command was dispatched, or throws a Tcl error
 on error.
 **********************************/
int
Pg_sendquery_prepared(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;
	char	   *statementName;
	int		   nParams;
	int		   allParamsText;
	int 	   resultFormat;
	int		   *paramFormats;
	int		   *paramLengths;
	const char *const *paramValues;
	int			returnValue;
	int 		status;

	nParams = objc - 5;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection statementName "
			"resultFormat argFormatList ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 1))
		return TCL_ERROR;

	statementName = Tcl_GetString(objv[2]);

	/* Parse resultFormatList and make resultFormat argument. */
	if (get_result_format(interp, objv[3], &resultFormat) != TCL_OK)
		return TCL_ERROR;

	/* Parse argFormat list and make paramFormats argument and all-text flag */
	if (get_param_formats(interp, objv[4], nParams, &allParamsText,
			&paramFormats) != TCL_OK)
		return TCL_ERROR;

	/* Copy query parameters, and lengths if binary format */
	get_param_values(interp, &objv[5], nParams, allParamsText, paramFormats,
			&paramValues, &paramLengths);

	/* Now dispatch the prepared query */
	status = PQsendQueryPrepared(conn, statementName, nParams, paramValues,
			paramLengths, paramFormats, resultFormat);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (status)
		returnValue = TCL_OK;
	else
	{
		/* error occurred when sending the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		returnValue = TCL_ERROR;
	}

	if (paramFormats)
		Tcl_Free((char *)paramFormats);
	if (paramLengths)
		Tcl_Free((char *)paramLengths);
	if (paramValues)
		Tcl_Free((char *)paramValues);

	return returnValue;
}

/**********************************
 * pg_sendquery_params
 Parse, bind parameters, and send a query using a prepared query to the
 backend connection for asynchronous execution.

 syntax:
 pg_sendquery_params connection query resultFormatList argFormatList \
       argTypeList ?param...?

 query is an SQL statement with parameter placeholders specified as
 $1, $2, etc.

 argFormatList is empty (= same as T), a single word T|B|TEXT|BINARY, or
 a list of those words, describing each argument as text or binary. If a
 single word, it applies to all arguments.  (Actually, anything starting
 with B means Binary, and anything else means Text. There is no error
 checking.)

 resultFormatList is similar to argFormatList except that it applies to the
 columns of the results. Currently, all result parameters must be text, or
 all must be binary (this is a libpq limitation, not a PostgreSQL
 limitation). So you might as well specify a single word BINARY or leave it
 empty.

 argTypeList is a list of PostgreSQL type OIDs for the query parameter
 arguments. Type OIDs must be supplied for each binary-format argument.
 If there are any binary format arguments, the argTypeList must contain
 an entry for each argument, although the actual value will be ignored
 for text-mode arguments.

 This is similar to pg_exec_params, but asynchronous like pg_sendquery.
 Note: If you are using all text arguments, it is easier to use pg_sendquery
 with the optional parameter arguments.

 Returns OK status if the command was dispatched, or throws a Tcl error
 on error.
 **********************************/
int
Pg_sendquery_params(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;
	char	   *queryString;
	int		   nParams;
	int		   allParamsText;
	int 	   resultFormat;
	int		   *paramFormats;
	int		   *paramLengths;
	const char *const *paramValues;
    Oid		   *paramTypes;
	int			returnValue;
	int 		status;

	nParams = objc - 6;
	if (nParams < 0)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection queryString "
			"resultFormat argFormatList argTypeList ?param...?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (!PgQueryOK(interp, conn, connid, 1))
		return TCL_ERROR;

	queryString = Tcl_GetString(objv[2]);

	/* Parse resultFormatList and make resultFormat argument. */
	if (get_result_format(interp, objv[3], &resultFormat) != TCL_OK)
		return TCL_ERROR;

	/* Parse argFormat list and make paramFormats argument and all-text flag */
	if (get_param_formats(interp, objv[4], nParams, &allParamsText,
			&paramFormats) != TCL_OK)
		return TCL_ERROR;

	/* Get the parameter type OID list into an array */
	if (get_param_types(interp, objv[5], nParams, &paramTypes) != TCL_OK) {
		if (paramFormats)
			Tcl_Free((char *)paramFormats);
		return TCL_ERROR;
	}

	/* Copy query parameters, and lengths if binary format */
	get_param_values(interp, &objv[6], nParams, allParamsText, paramFormats,
			&paramValues, &paramLengths);

	/* Now dispatch the parameterized query to the backend */
	status = PQsendQueryParams(conn, queryString, nParams, paramTypes,
			paramValues, paramLengths, paramFormats, resultFormat);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (status)
		returnValue = TCL_OK;
	else {
		/* error occurred when sending the query */
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		returnValue = TCL_ERROR;
	}

	if (paramFormats)
		Tcl_Free((char *)paramFormats);
	if (paramLengths)
		Tcl_Free((char *)paramLengths);
	if (paramValues)
		Tcl_Free((char *)paramValues);
	if (paramTypes)
		Tcl_Free((char *)paramTypes);

	return returnValue;
}

/**********************************
 * pg_result_callback
 register or remove a callback for the next pg_sendquery to complete

 syntax:
 pg_result_callback connection ?callback?

 Original version written by msofer
 **********************************/
int
Pg_result_callback(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;

	if (objc < 2 || 3 < objc)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection ?callback?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (conn == NULL)
		return TCL_ERROR;

	/* Forget any existing result callback */
	PgClearResultCallback(connid);

	if (objc > 2)
	{
		/* Establish a result callback */

		/* Start the notify event source if it isn't already running */
		PgStartNotifyEventSource(connid);

		connid->callbackPtr = objv[2];
		connid->callbackInterp = interp;

		Tcl_IncrRefCount(objv[2]);
		Tcl_Preserve((ClientData) interp);
	}
	
	return TCL_OK;
}


/**********************************
 * pg_getresult
 wait for the next result from a prior pg_sendquery

 syntax:
 pg_getresult connection

 the return result is either an error message, nothing, or a handle for a query
 result.  Handles start with the prefix "pgp"
 **********************************/

int
Pg_getresult(ClientData cData, Tcl_Interp *interp, int objc,
			 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	PGresult   *result;
	char	   *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	/* Cancel any callback script: the user lost patience */
	PgClearResultCallback(connid);

	result = PQgetResult(conn);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	/* if there's a non-null result, give the caller the handle */
	if (result)
	{
		int			rId = PgSetResultId(interp, connString, result);
		ExecStatusType rStat;

		if (rId == -1)
		{
			/* There is a result available, but unable to allocate a result
			 * slot for it. Return error; PgSetResultId left a message.
			 */
			PQclear(result);
			return TCL_ERROR;
		}
		rStat = PQresultStatus(result);

		if (rStat == PGRES_COPY_IN || rStat == PGRES_COPY_OUT)
		{
			connid->res_copyStatus = RES_COPY_INPROGRESS;
			connid->res_copy = rId;
		}
	}
	return TCL_OK;
}

/**********************************
 * pg_isbusy
 see if a query is busy, i.e. pg_getresult would block.

 syntax:
 pg_isbusy connection

 return is 1 if it's busy and pg_getresult would block, 0 otherwise
 **********************************/

int
Pg_isbusy(ClientData cData, Tcl_Interp *interp, int objc,
		  Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	char	   *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	PQconsumeInput(conn);

	Tcl_SetIntObj(Tcl_GetObjResult(interp), PQisBusy(conn));
	return TCL_OK;
}

/**********************************
 * pg_blocking
 see or set whether or not a connection is set to blocking or nonblocking

 Syntax:
   pg_blocking connection ?newSetting?

 returns:
   If newSetting is provided, returns the blocking state - 1 if blocking, 0
if non-blocking - before changing to the new setting.
   If newSetting is not provided, returns the current blocking state.
 **********************************/

int
Pg_blocking(ClientData cData, Tcl_Interp *interp, int objc,
			Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	char	   *connString;
	int			boolean;

	if ((objc < 2) || (objc > 3))
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection ?bool?");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (conn == (PGconn *)NULL)
		return TCL_ERROR;

	/* Return the current value */
	Tcl_SetBooleanObj(Tcl_GetObjResult(interp), !PQisnonblocking(conn));

	/* If new setting provided, change it: */
	if (objc == 3)
	{
		if (Tcl_GetBooleanFromObj(interp, objv[2], &boolean) == TCL_ERROR)
			return TCL_ERROR;
		PQsetnonblocking(conn, !boolean); /* Non-blocking if arg is 1 */
	}
	return TCL_OK;
}

/**********************************
 * pg_cancelrequest
 request that postgresql abandon processing of the current command

 syntax:
 pg_cancelrequest connection

 returns nothing if the command successfully dispatched or if nothing was
 going on, otherwise an error
 **********************************/

int
Pg_cancelrequest(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	conn = PgGetConnectionId(interp, connString, &connid);
	if (conn == NULL)
		return TCL_ERROR;

	/* Cancel any callback script */
	PgClearResultCallback(connid);

	if (PQrequestCancel(conn) == 0)
	{
		Tcl_SetObjResult(interp,
					 Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}
	return TCL_OK;
}

/***********************************
Pg_on_connection_loss
	create or remove a callback request for unexpected connection loss

 syntax:
   pg_on_connection_loss conn ?callbackcommand?

   With a third arg, creates or changes the callback command for
   connection loss; without, cancels the callback request.

   Callbacks can occur whenever Tcl is executing its event loop.
   This is the normal idle loop in Tk; in plain tclsh applications,
   vwait or update can be used to enter the Tcl event loop.
***********************************/
int
Pg_on_connection_loss(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	char	   *callback = NULL;
	Pg_TclNotifies *notifies;
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	char	   *connString;

	if (objc < 2 || objc > 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection ?callback?");
		return TCL_ERROR;
	}

	/*
	 * Get the command arguments.
	 */
	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (conn == (PGconn *) NULL)
		return TCL_ERROR;

	if (objc > 2)
	{
		int         callbackStrLen;
		char	   *callbackStr;

		/* there is probably a better way to do this, like incrementing
		 * the reference count (?) */
		callbackStr = Tcl_GetStringFromObj(objv[2], &callbackStrLen);
		callback = (char *) ckalloc((unsigned) (callbackStrLen + 1));
		strcpy(callback, callbackStr);
	}

	/* Find or make a Pg_TclNotifies struct for this interp and connection */
	notifies = Pg_get_notifies(interp, connid);

	/* Store new callback setting */

	if (notifies->conn_loss_cmd)
		ckfree((void *) notifies->conn_loss_cmd);
	notifies->conn_loss_cmd = callback;

	if (callback)
	{
		/*
		 * Start the notify event source if it isn't already running. The
		 * notify source will cause Tcl to watch read-ready on the
		 * connection socket, so that we find out quickly if the
		 * connection drops.
		 */
		PgStartNotifyEventSource(connid);
	}

	return TCL_OK;
}

/***********************************
Pg_escape_string
	escape string for inclusion in SQL queries
    See also Pg_quote and Pg_escape_literal

 syntax:
   pg_escape_string ?conn? string

  If the optional connection handle argument is supplied, it calls the
  newer libpq escape function that uses connection-specific information
  about encoding and standard_conforming_strings.

  Note: This was first added to another pgtcl implementation, as a wrapper
  around the libpq PQescapeString function. Later it was removed from there,
  and a new command pg_quote was added, which includes the containing quotes
  in the return value.
  Both pgtcl-ng and pgin.tcl implemented pg_escape_string (without quotes)
  and pg_quote (with quotes). But then the other pgtcl implementation re-added
  pg_escape_string, but this time it included the quotes in the return value.
  However, pgtcl-ng and pgin.tcl had already released versions with
  pg_escape_string not including the quotes. The choice was to break
  compatibility with itself, or with the other pgtcl.
  So pg_escape_string is NOT compatible with the other Pgtcl implementation.

***********************************/
int
Pg_escape_string(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	char	   *fromString;
	char	   *toString;
	int         fromStringLen;
	int			toStringLen;
	PGconn	   *conn;

	if (objc == 3)
	{
		conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]), NULL);
		if (!conn)
			return TCL_ERROR;
		fromString = Tcl_GetStringFromObj(objv[2], &fromStringLen);
	} else if (objc == 2) {
		conn = NULL;
		fromString = Tcl_GetStringFromObj(objv[1], &fromStringLen);
	} else {
		Tcl_WrongNumArgs(interp, 1, objv, "?conn? string");
		return TCL_ERROR;
	}

	/* 
	 * Allocate the "to" string. Max size is documented in the
	 * PostgreSQL docs as 2 * fromStringLen + 1 
	 */
	toString = (char *) ckalloc((2 * fromStringLen) + 1);

	/*
	 * Call the library routine to escape the string, and return
	 * the command result as a Tcl object.
	 */

#ifdef HAVE_PQESCAPESTRINGCONN
	if (conn)
		toStringLen = PQescapeStringConn (conn, toString, fromString, fromStringLen, NULL);
	else
#endif
		toStringLen = PQescapeString (toString, fromString, fromStringLen);

	Tcl_SetObjResult(interp, Tcl_NewStringObj(toString, toStringLen));
	ckfree(toString);

	return TCL_OK;
}

/***********************************
Pg_quote
	escape and quote string for inclusion in SQL queries
    See also Pg_escape_string and note on compatibility with other pgtcl's.
    See also Pg_escape_literal
 syntax:
   pg_quote ?conn? string

***********************************/
int
Pg_quote(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	char	   *fromString;
	char	   *toString;
	int         fromStringLen;
	int			toStringLen;
	PGconn	   *conn;

	if (objc == 3)
	{
		conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]), NULL);
		if (!conn)
			return TCL_ERROR;
		fromString = Tcl_GetStringFromObj(objv[2], &fromStringLen);
	} else if (objc == 2) {
		conn = NULL;
		fromString = Tcl_GetStringFromObj(objv[1], &fromStringLen);
	} else {
		Tcl_WrongNumArgs(interp, 1, objv, "?conn? string");
		return TCL_ERROR;
	}

	/* 
	 * Allocate the "to" string. Max size is documented in the
	 * PostgreSQL docs as 2 * fromStringLen + 1. Add 2 for quotes,
	 * and subtract 1 because NewStringObj doesn't need the ending null.
	 */
	toString = (char *) ckalloc((2 * fromStringLen) + 2);

	/*
	 * Call the library routine to escape the string, and return
	 * the command result as a Tcl object with quote marks around it.
	 */


	toString[0] = '\'';
#ifdef HAVE_PQESCAPESTRINGCONN
	if (conn)
		toStringLen = 1 + PQescapeStringConn (conn, toString+1, fromString, fromStringLen, NULL);
	else
#endif
		toStringLen = 1 + PQescapeString (toString+1, fromString, fromStringLen);
	toString[toStringLen++] = '\'';
	Tcl_SetObjResult(interp, Tcl_NewStringObj(toString, toStringLen));
	ckfree(toString);

	return TCL_OK;
}


/***********************************
Pg_escape_l_i

	Escape string as literal or identifier, for inclusion in SQL queries
    See also Pg_escape_string and Pg_quote

 This implements both pg_escape_literal pg_escape_identifier, based on
 ClientData:  ClientData=1 for pg_escape_literal, 2 for pg_escape_identifier

 syntax:
   pg_escape_literal conn string
   pg_escape_identifier conn string

  Note: pg_escape_literal is effectively equivalent to pg_quote. It
  wraps libpq PQescapeLiteral() which was added after pg_quote was
  implemented. Like pg_quote, it escapes a string and returns it inside
  single quotes. Unlike pg_quote (and its underlying pg_escape_string),
  the implementation is not dependent on standard_conforming_strings.

  pg_escape_identifier wraps libpq PQescapeIdentifier. Both of these
  were added to libpq in PostgreSQL-9.0.

  Also unlike pg_quote and pg_escape_string, the $conn argument is
  required for both commands. It is used to handle encoding / multibyte issues.

***********************************/
#ifdef HAVE_PQESCAPELITERAL /* Added in PostgreSQL-9.0 */
int
Pg_escape_l_i(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	char	   *fromString;
	char	   *toString;
	int         fromStringLen;
	PGconn	   *conn;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "conn string");
		return TCL_ERROR;
	}

	conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]), NULL);
	if (!conn)
		return TCL_ERROR;

	fromString = Tcl_GetStringFromObj(objv[2], &fromStringLen);
	if ((int)cData == 1)
	{
		toString = PQescapeLiteral(conn, fromString, fromStringLen);
	}
	else if ((int)cData == 2)
	{
		toString = PQescapeIdentifier(conn, fromString, fromStringLen);
	}
	else toString = NULL;  /* This should never happen */

 	if (!toString)
	{
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(toString, -1));
	PQfreemem(toString);
	return TCL_OK;
}
#endif


/***********************************
 * Pg_escape_bytea
   Escape a binary string for inclusion in SQL queries as a bytea type.
   See libpq PQescapeBytea, PQescapeByteaConn.

   If the optional connection handle argument is supplied, it calls the
   newer libpq escape function that uses connection-specific information
   about standard_conforming_strings. With no connection handle, the
   original libpq call is used, which makes its best guess as to whether
   standard_conforming_strings is on or not. (The guess will always be
   correct for applications using a single database connection at a time.)

   The escaping (as of PostgreSQL-8.3 or so) is as follows:
       Single quote (') is doubled ('').
       Backslash (\) produces 2 (\\) in standard_conforming_strings mode,
           or 4 (\\\\) in non-standard_conforming_strings mode.
       All characters below ASCII 0x20 (space) or above 0x7e (~) are encoded
           as 3 octal digits ooo, and then output as
           \ooo in standard_conforming_strings mode,
           \\ooo in non-standard_conforming_strings_mode.

   The doubling of backslashes (in non-standard_conforming_strings mode) is
   due to PostgreSQL parsing the data once for SQL syntax, and again for
   bytea input.
   Note: This function is NOT the inverse of Pg_unescape_bytea (cf).

   Syntax:
   pg_escape_bytea ?conn? binary_string

***********************************/
int
Pg_escape_bytea(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	unsigned char	   *from_binary;
	int         		from_len;
	char			   *to_string;
	size_t 				to_len;
	PGconn			   *conn;

	if (objc == 3)
	{
		conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]), NULL);
		if (!conn)
			return TCL_ERROR;
		from_binary = Tcl_GetByteArrayFromObj(objv[2], &from_len);
	} else if (objc == 2) {
		conn = NULL;
		from_binary = Tcl_GetByteArrayFromObj(objv[1], &from_len);
	} else {
		Tcl_WrongNumArgs(interp, 1, objv, "?conn? binaryString");
		return TCL_ERROR;
	}

	/*
	 * Escape the data. libpq allocates the memory for us.
	 * Note to_len includes the terminating null byte.
	 */
#ifdef HAVE_PQESCAPEBYTEACONN
	if (conn)
		to_string = (char *)PQescapeByteaConn(conn, from_binary, (size_t)from_len, &to_len);
	else
#endif
		to_string = (char *)PQescapeBytea(from_binary, (size_t)from_len, &to_len);
	if (!to_string)
	{
		Tcl_AppendResult(interp, "pg_escape_bytea: failed to get memory\n", 0);
		return TCL_ERROR;
	}

	/*
	 * Copy the result to the interpreter as a string object.
	 */
	Tcl_SetObjResult(interp, Tcl_NewStringObj(to_string, to_len-1));

	/*
	 * Free libpq-allocated memory
	 */
	PQfreemem(to_string);

	return TCL_OK;
}

/***********************************
 * Pg_unescape_bytea
   Unescape a string from a PostgreSQL bytea data type and return the
   original binary data as a Tcl binary object.
   See libpq PQunescapeBytea.
   In summary, this takes \nnn octal escapes and produces the byte
   equivalent to nnn, and any other \c becomes c.

   Note: This function is NOT the inverse of Pg_escape_bytea. That
   function produces doubled backslashes, and this function expects
   single backslashes. That's because pg_escape_bytea is meant to
   escape binary data for quoted SQL strings in SELECT,  INSERT, etc.
   which goes through two levels of parsing. pg_unescape_bytea is
   used to retrieve binary data returned by a query on a bytea column,
   which has only had one level of escaping performed on it.

   Syntax:
   pg_unescape_bytea string

***********************************/
int
Pg_unescape_bytea(ClientData cData, Tcl_Interp *interp, int objc,
				 Tcl_Obj *CONST objv[])
{
	unsigned char	   *to_binary;
	size_t 				to_len;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "string");
		return TCL_ERROR;
	}

	/*
	 * Unescape the data. libpq allocates the memory for us.
	 */
	to_binary = PQunescapeBytea((unsigned char *)Tcl_GetString(objv[1]), &to_len);
	if (!to_binary)
	{
		Tcl_AppendResult(interp, "pg_unescape_bytea: failed to get memory\n", 0);
		return TCL_ERROR;
	}

	/*
	 * Copy the result to the interpreter as a ByteArray (binary) object.
	 */
	Tcl_SetObjResult(interp, Tcl_NewByteArrayObj(to_binary, to_len));

	/*
	 * Free libpq-allocated memory
	 */
	PQfreemem(to_binary);

	return TCL_OK;
}

/**********************************
 * pg_transaction_status
 Return the transaction status of a connection

 syntax:
 pg_transaction_status connection

 The argument passed in must be a connection pointer.
 Returns one of the following strings: IDLE ACTIVE INTRANS INERROR UNKNOWN
 For more information, see the PostgreSQL libpq PQtransactionStatus() function.

 **********************************/

int
Pg_transaction_status(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	   *conn;
	char	   *connString;
	char	   *result;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);

	/* Get and validate the libpq connection handle. */
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (!conn)
		return TCL_ERROR;

	switch (PQtransactionStatus(conn))
	{
		case PQTRANS_IDLE:
			result = "IDLE";
			break;

		case PQTRANS_ACTIVE:
			result = "ACTIVE";
			break;

		case PQTRANS_INTRANS:
			result = "INTRANS";
			break;

		case PQTRANS_INERROR:
			result = "INERROR";
			break;

		/* Treat anything else as PQTRANS_UNKNOWN */
		default:
			result = "UNKNOWN";
			break;
	}
	Tcl_SetResult(interp, result, TCL_STATIC);
	return TCL_OK;
}

/**********************************
 * pg_parameter_status
 Return the value of a server-side parameter

 Syntax:
 pg_parameter_status connection parameter_name

 The return value is the value of the named server parameter, or an empty
 string if there is no such parameter. This does not communicate with the
 server, but requires a valid connection, as libpq stores all the parameters
 sent by the server at connect time.
 
 For more information, see the PostgreSQL libpq PQparameterStatus() function.

 **********************************/

int
Pg_parameter_status(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	  *conn;
	char	  *connString;
	char	  *paramName;
	CONST char	  *paramValue;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection parameterName");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (!conn)
		return TCL_ERROR;

	paramName = Tcl_GetString(objv[2]);

	if ((paramValue = PQparameterStatus(conn, paramName)) != NULL)
		/* paramValue points to storage owned by libpq, so let Tcl copy it */
		Tcl_SetResult(interp, (char *)paramValue, TCL_VOLATILE);

	return TCL_OK;
}

/**********************************
 * pg_backend_pid
 Return the backend process id (PID) for this connection

 Syntax:
 pg_backend_pid connection

 For more information, see the PostgreSQL libpq PQbackendPID() function.

 **********************************/

int
Pg_backend_pid(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	  *conn;
	char	  *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (!conn)
		return TCL_ERROR;

	Tcl_SetObjResult(interp, Tcl_NewIntObj(PQbackendPID(conn)));
	return TCL_OK;
}

/**********************************
 * pg_server_version
 Return the server version as an integer.

 Syntax:
 pg_server_version connection

 For more information, see the PostgreSQL libpq PQserverVersion() function.

 **********************************/

int
Pg_server_version(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn	  *conn;
	char	  *connString;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, (Pg_ConnectionId **) NULL);
	if (!conn)
		return TCL_ERROR;

	Tcl_SetObjResult(interp, Tcl_NewIntObj(PQserverVersion(conn)));
	return TCL_OK;
}

/*
 * Notice handler procedure. Arg is a pointer to the Pg_ConnectionId
 * structure describing the connection. This includes a pointer to the
 * Tcl interpreter, which is needed to execute code. The Tcl code to execute
 * can be found in the Tcl object connid->notice_command. If NULL, do
 * nothing, else append the message and execute. Errors are ignored.
 * It is probably a bad idea to borrow the interpreter to execute the handler
 * code, but it will only happen during a query sending command (PQexec)
 * so it should be safe. Also the interp value is saved and restored to
 * ensure the handler doesn't overwrite anything.
 */
static void
PgNoticeProcessor(void *arg, const char *message)
{
	Pg_ConnectionId *connid = (Pg_ConnectionId *)arg;
	Tcl_Interp *interp = connid->interp;
	Tcl_Obj *messageObj;
	Tcl_Obj	*cmdObj;
	Tcl_Obj *savedInterpResult;

	/* Empty handler command means ignore messages. */
	if (connid->notice_command == NULL || interp == NULL)
		return;

	/* Build the command with the message appended as a single list element */
	cmdObj = Tcl_DuplicateObj(connid->notice_command);
	Tcl_IncrRefCount(cmdObj);
	messageObj = Tcl_NewStringObj(message, -1);
	Tcl_IncrRefCount(messageObj);

	savedInterpResult = Tcl_DuplicateObj(Tcl_GetObjResult(interp));
    Tcl_IncrRefCount(savedInterpResult);

	if (Tcl_ListObjAppendElement(interp, cmdObj, messageObj) == TCL_OK)
	{
		/*
		 * Ignore the return status, since the interpreter isn't expecting
		 * anything to happen at this point.
		 */
 		Tcl_EvalObjEx(interp, cmdObj, TCL_EVAL_GLOBAL);
	}
	Tcl_DecrRefCount(messageObj);
	Tcl_DecrRefCount(cmdObj);
	Tcl_SetObjResult(interp, savedInterpResult);
	Tcl_DecrRefCount(savedInterpResult);
}

/**********************************
 * pg_notice_handler 
 Establish a Tcl command to call on Notice or Warning messages.

 Syntax:
 pg_set_notice_handler connection ?command?

   If command is supplied, it becomes the new Notice handler. The text of
   the message is appended to the command as a list element.

   If command is empty, ignore notice and warning messages.

 Returns: The current value of the notice handler command (before it is
   changed by a supplied command argument, if any).

 **********************************/

int
Pg_notice_handler(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn		*conn;
	Pg_ConnectionId	*connid;
	char		*command;
	static char default_notice_handler[] = "puts -nonewline stderr";


	if (objc < 2 || objc > 3)
	{
		Tcl_WrongNumArgs(interp, 0, objv, "connection ?command?");
		return TCL_ERROR;
	}
	conn = PgGetConnectionId(interp, Tcl_GetString(objv[1]), &connid);
	if (!conn)
		return TCL_ERROR;

	if (objc == 3)
		command = Tcl_GetString(objv[2]);
	else
		command = NULL;

	/*
	 * Return the previous notice handler. If no handler was set,
	 * pretend that "puts -nonewline stderr" is the notice handler,
	 * since that is equivalent to the libpq default handler.
	 */
	if (connid->notice_command)
		Tcl_SetObjResult(interp, connid->notice_command);
	else
		Tcl_SetResult(interp, default_notice_handler, TCL_STATIC);

	if (command)
	{
		/*
		 * Change the notice handler.
		 * If this is the first time the handler is being set, establish
		 * the notice processor function using libpq. The first-time
		 * handler setup is indicated by a null "interp" field. A null
		 * notice_command, on the other hand, means ignore notices.
		 */
		if (connid->interp == NULL)
		{
			connid->notice_command = Tcl_NewStringObj(default_notice_handler, -1);
			Tcl_IncrRefCount(connid->notice_command);
			PQsetNoticeProcessor(conn, PgNoticeProcessor, (void *)connid);
		}
		/*
		 * Remember which interp last set a handler. This is the
		 * interpreter which will be used to execute the handler.
		 */
		connid->interp = interp;

		/*
		 * Free any previous handler, and store the new handler command:
		 */
		if (connid->notice_command)
			Tcl_DecrRefCount(connid->notice_command);
		if (*command)
		{
			connid->notice_command =  Tcl_NewStringObj(command, -1);
			Tcl_IncrRefCount(connid->notice_command);
		}
		else
			connid->notice_command = NULL;
	}
	return TCL_OK;
}

/**********************************
 pg_describe_cursor
 Return a result structure with information about a cursor

 Syntax:
 pg_describe_cursor connection cursor_name

 The return value is a result structure (with no data). It can be used
 with pg_result to find information about the cursor.

 For more information, see the PostgreSQL libpq PQdescribePortal() function.
 (PostgreSQL refers to cursors as 'portals', but 'cursors' is more common.)

 **********************************/

#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
int
Pg_describe_cursor(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn			*conn;
	char			*connString;
	Pg_ConnectionId	*connid;
	const char		*cursorName;
	PGresult		*result;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection cursorName");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (!conn)
		return TCL_ERROR;

	cursorName = Tcl_GetString(objv[2]);
	/* Note: PQdescribePortal accepts an empty string (or NULL) to get
		information about the 'unnamed cursor'. I don't think that makes
		any sense in this context, however it is possible, so we will
		not check and exclude an empty cursor name.
	*/
	result = PQdescribePortal(conn, cursorName);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (!result)
	{
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}

	if (PgSetResultId(interp, connString, result) == -1)
	{
		/* Response OK but failed to get a result slot. */
		PQclear(result);
		return TCL_ERROR;
	}
	return TCL_OK;
}
#endif

/**********************************
 pg_describe_prepared
 Return a result structure with information about a prepared statement

 Syntax:
 pg_describe_prepared connection prepared_statement_name

 The return value is a result structure (with no data). It can be used
 with pg_result to find information about the prepared statement. In
 particular, two pg_result options are specifically for prepared statement
 results: -paramTypes and -numParams

 For more information, see the PostgreSQL libpq PQdescribePrepared() function.

 **********************************/

#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
int
Pg_describe_prepared(ClientData cData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	PGconn			*conn;
	char			*connString;
	Pg_ConnectionId	*connid;
	const char		*statementName;
	PGresult		*result;

	if (objc != 3)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "connection statementName");
		return TCL_ERROR;
	}

	connString = Tcl_GetString(objv[1]);
	conn = PgGetConnectionId(interp, connString, &connid);
	if (!conn)
		return TCL_ERROR;

	statementName = Tcl_GetString(objv[2]);
	/* Note: PQdescribePrepared accepts an empty string (or NULL) to get
		information about the 'unnamed prepared statement'. I don't think
		that makes any sense in this context, however it is possible, so
		we will not check and exclude an empty prepared statement name.
	*/
	result = PQdescribePrepared(conn, statementName);

	/* Transfer any notify events from libpq to Tcl event queue. */
	PgNotifyTransferEvents(connid);

	if (!result)
	{
		Tcl_SetObjResult(interp, Tcl_NewStringObj(PQerrorMessage(conn), -1));
		return TCL_ERROR;
	}

	if (PgSetResultId(interp, connString, result) == -1)
	{
		/* Response OK but failed to get a result slot. */
		PQclear(result);
		return TCL_ERROR;
	}
	return TCL_OK;
}
#endif
