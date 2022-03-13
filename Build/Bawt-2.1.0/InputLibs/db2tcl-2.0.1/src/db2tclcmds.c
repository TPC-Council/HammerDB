/* $Id$ */

#include "db2tclcmds.h"

#include <sqlcli1.h>
#include <string.h>

static SQLHANDLE henv = SQL_NULL_HANDLE;
static int num_connect = 0;

int Db2CloseConnection (ClientData cData, Tcl_Interp * interp)
{
    Db2Connection *conn;

    conn = (Db2Connection *) cData;

    /* Disconnect from database */
    conn->rc = SQLDisconnect (conn->hdbc);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, SQL_NULL_HANDLE,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    /* Free unused handles */
    SQLFreeHandle (SQL_HANDLE_DBC, conn->hdbc);

    num_connect--;

    if (num_connect == 0)
    {
	SQLFreeHandle (SQL_HANDLE_ENV, henv);
	henv = SQL_NULL_HANDLE;
    }
/*Change reverted to original as per pull request to memmertoIBM/db2tcl */
      Tcl_EventuallyFree ((ClientData) conn, TCL_DYNAMIC); 
/*    Tcl_EventuallyFree ((ClientData) conn->rc, TCL_DYNAMIC);  */

    return 0;
}

int Db2InputProc (ClientData cData, char *buf, int bufSize, int *errorCodePtr)
{
    Db2Connection *conn;

    conn = (Db2Connection *) cData;

    return 0;
}

int Db2OutputProc (ClientData cData, CONST84 char *buf, int bufSize,
		   int *errorCodePtr)
{
    Db2Connection *conn;

    conn = (Db2Connection *) cData;

    return 0;
}

int Db2WatchProc (ClientData cData,  Tcl_Interp * interp)
{
    return 0;
}

Tcl_ChannelType Db2_ConnType = {
    "db2sql",			/* channel type */
    NULL,
    Db2CloseConnection,		/* closeproc */
    Db2InputProc,		/* inputproc */
    Db2OutputProc,		/* outputproc */
    NULL,
    NULL,
    NULL,
    Db2WatchProc,		/* watchproc */
    NULL,
    NULL
};

/*
   TCL syntax:

   db2_connect dbname ?username? ?password?

   Return database handle
*/

int Db2_connect (ClientData cData, Tcl_Interp * interp, int argc,
		 CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;

    if (argc > 4 || argc < 2)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) ckalloc (sizeof (Db2Connection));
    memset (conn, '\0', (sizeof (Db2Connection)));

    strncpy (conn->database, argv[1], SQL_MAX_DSN_LENGTH);

    if (argc > 2  && argv[2])
    {
	strncpy (conn->user, argv[2], MAX_UID_LENGTH);
    }

    if (argc > 3 && argv[3])
    {
	strncpy (conn->password, argv[3], MAX_PWD_LENGTH);
    }

    if (henv == SQL_NULL_HANDLE)
    {
	conn->rc = SQLAllocHandle (SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);

	if (conn->rc != SQL_SUCCESS)
	{
	    SQLError (henv, SQL_NULL_HANDLE, SQL_NULL_HANDLE,
		      (SQLCHAR *) & conn->sql_state,
		      &conn->native_error,
		      (SQLCHAR *) & conn->error_msg,
		      sizeof (conn->error_msg), &conn->size_error_msg);
	    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	    return TCL_ERROR;
	}
    }

    conn->rc = SQLAllocHandle (SQL_HANDLE_DBC, henv, &conn->hdbc);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, SQL_NULL_HANDLE,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    /* Connect to database */
    conn->rc = SQLConnect (conn->hdbc,
			   (SQLCHAR *) & conn->database, SQL_NTS,
			   (SQLCHAR *) & conn->user, SQL_NTS,
			   (SQLCHAR *) & conn->password, SQL_NTS);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, SQL_NULL_HANDLE,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }


    num_connect++;

    snprintf (conn->id, MAX_ID_LENGTH, "db2sql%d", (int) conn->hdbc);

    /* Create TCL channel for read and write */
    conn_channel = Tcl_CreateChannel (&Db2_ConnType,
				      conn->id,
				      (ClientData) conn,
				      TCL_READABLE | TCL_WRITABLE);

    Tcl_SetChannelOption (interp, conn_channel, "-buffering", "line");
    Tcl_RegisterChannel (interp, conn_channel);

    Tcl_SetResult (interp, conn->id, TCL_VOLATILE);

    return TCL_OK;
}

/*
   TCL syntax:

   db2_disconnect db_handle

   Return database handle
*/

int Db2_disconnect (ClientData cData, Tcl_Interp * interp, int argc,
		    CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    char id[MAX_ID_LENGTH + 1];
    short num_fields;
    SQLHANDLE hdbc, hstmt;

    /* db2sqlX.Y.Z where X is database handle, Y is database statement, Z is fields count */

   if (argv[1] && sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_fields) < 1) 
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

       Tcl_ResetResult (interp);
       return Tcl_UnregisterChannel (interp, conn_channel);
}

/*
    TCL syntax:

    db2_exec_direct handle sql_code

    Return database handle
*/

int Db2_exec_direct (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;
    char buff[MAX_ID_LENGTH + 1];

    if (argc != 3)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLAllocHandle (SQL_HANDLE_STMT, conn->hdbc, &hstmt);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }
    /* NOTE: SQLExecDirect() has "char *", not "const char*" for the 2nd argument in the prototype*/
    conn->rc = SQLExecDirect (hstmt, (char *) argv[2], SQL_NTS);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    /* Return result by template db2sqlX.Y */
    snprintf (buff, MAX_ID_LENGTH, "%s.%d", conn->id, SQL_NULL_HANDLE);
    Tcl_AppendResult (interp, buff, (char *)NULL);

    conn->rc = SQLFreeHandle (SQL_HANDLE_STMT, hstmt);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    return TCL_OK;
}

/*
    TCL syntax:

    db2_select_direct handle sql_code

    Return database handle
*/

int Db2_select_direct (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;
    short num_fields;
    char buff[MAX_ID_LENGTH + 1];

    if (argc != 3)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLAllocHandle (SQL_HANDLE_STMT, conn->hdbc, &hstmt);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    /* NOTE: SQLExecDirect() has "char *", not "const char*" for the 2nd argument in the prototype*/
    conn->rc = SQLExecDirect (hstmt, (char *) argv[2], SQL_NTS);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }


    conn->rc = SQLNumResultCols (hstmt, &num_fields);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (buff, MAX_ID_LENGTH, "%s.%d.%d", conn->id, hstmt, num_fields);
    Tcl_AppendResult (interp, buff, (char *)NULL);

    return TCL_OK;
}

/*
    TCL syntax:

    db2_prepare handle sql_code

    Return database handle
*/

int Db2_prepare (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;
    short num_params;
    char buff[MAX_ID_LENGTH + 1];

    if (argc != 3)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLAllocHandle (SQL_HANDLE_STMT, conn->hdbc, &hstmt);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    conn->rc = SQLPrepare (hstmt, (char *) argv[2], SQL_NTS);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }


    conn->rc = SQLNumParams (hstmt, &num_params);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (buff, MAX_ID_LENGTH, "%s.%d.%d", conn->id, hstmt, num_params);
    Tcl_AppendResult (interp, buff, (char *)NULL);

    return TCL_OK;
}

/*
    TCL syntax:

    db2_bind_param handle parameters

    Return database handle
*/


int Db2_bind_param (ClientData cData, Tcl_Interp * interp, int argc,
                  CONST84 char *argv[])
{
    int i = 1;
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    char id[MAX_ID_LENGTH + 1];
    SQLHANDLE hdbc, hstmt;
    SQLLEN ival = SQL_NULL_DATA;
    short num_params;
    int nparam;
    char **paramList;

if (argc != 3)
    {
        Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
        return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_params) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " first argument is not a prepared statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

	if (Tcl_SplitList(interp, argv[2], &nparam, &paramList) != TCL_OK) {
        Tcl_SetResult(interp, "Cannot parse the parameter list", TCL_STATIC);
	if (paramList) ckfree((char *) paramList);
	return TCL_ERROR;
	} 

	if (nparam != num_params) {
        Tcl_SetResult(interp, "Number of parameters to bind differs from statement", TCL_STATIC);
	if (paramList) ckfree((char *) paramList);
	return TCL_ERROR; 
	} 

    conn->rc = SQLFreeStmt(hstmt, SQL_RESET_PARAMS);
	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
                    if (paramList) ckfree((char *) paramList);
		    return TCL_ERROR;
	    }

	for (i = 0; i < nparam; i++)
	{
        if (strncmp (paramList[i], "NULL", 4) == 0)
    {
        /* null bind */
        conn->rc = SQLBindParameter (hstmt, i + 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, 0, 0, NULL, 0, &ival);
    }
    else
    {
        /* bind value */
        conn->rc = SQLBindParameter (hstmt, i + 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, 0, 0, paramList[i], 0, NULL);
    }

	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
                    if (paramList) ckfree((char *) paramList);
		    return TCL_ERROR;
	    }
	}
    if (paramList) ckfree((char *) paramList);
    return TCL_OK;
}

/*
    TCL syntax:

    db2_bind_exec handle parameters

    Return database handle
*/


int Db2_bind_exec (ClientData cData, Tcl_Interp * interp, int argc,
                  CONST84 char *argv[])
{
    int i = 1;
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    char id[MAX_ID_LENGTH + 1];
    char buff[MAX_ID_LENGTH + 1];
    SQLHANDLE hdbc, hstmt;
    SQLLEN ival = SQL_NULL_DATA;
    short num_params;
    int nparam;
    char **paramList;

if (argc != 3)
    {
        Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
        return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_params) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " first argument is not a prepared statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

	if (Tcl_SplitList(interp, argv[2], &nparam, &paramList) != TCL_OK) {
        Tcl_SetResult(interp, "Cannot parse the parameter list", TCL_STATIC);
	if (paramList) ckfree((char *) paramList);
	return TCL_ERROR;
	} 

	if (nparam != num_params) {
        Tcl_SetResult(interp, "Number of parameters to bind differs from statement", TCL_STATIC);
	if (paramList) ckfree((char *) paramList);
	return TCL_ERROR; 
	} 

    conn->rc = SQLFreeStmt(hstmt, SQL_RESET_PARAMS);
	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
		    if (paramList) ckfree((char *) paramList);
		    return TCL_ERROR;
	    }

	for (i = 0; i < nparam; i++)
	{
  if (strncmp (paramList[i], "NULL", 4) == 0)
    {
        /* null bind */
        conn->rc = SQLBindParameter (hstmt, i + 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, 0, 0, NULL, 0, &ival);
    }
    else
    {
        /* bind value */
        conn->rc = SQLBindParameter (hstmt, i + 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, 0, 0, paramList[i], 0, NULL);
    }

	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
		    if (paramList) ckfree((char *) paramList);
		    return TCL_ERROR;
	    }
	}

    conn->rc = SQLExecute (hstmt);

    if (conn->rc != SQL_SUCCESS)
    {
        SQLError (henv, conn->hdbc, hstmt,
                  (SQLCHAR *) & conn->sql_state,
                  &conn->native_error,
                  (SQLCHAR *) & conn->error_msg,
                  sizeof (conn->error_msg), &conn->size_error_msg);
        Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
        if (paramList) ckfree((char *) paramList);
        return TCL_ERROR;
    }

    /* Return result by template db2sqlX.Y */
    snprintf (buff, MAX_ID_LENGTH, "%s.%d", conn->id, SQL_NULL_HANDLE);
    Tcl_AppendResult (interp, buff, (char *)NULL);
    if (paramList) ckfree((char *) paramList);
    return TCL_OK;
}
/*
    TCL syntax:

    db2_exec_prepared handle 

    Return database handle
*/

int Db2_exec_prepared (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hdbc, hstmt;
    char id[MAX_ID_LENGTH + 1];
    char buff[MAX_ID_LENGTH + 1];
    short num_params;

    if (argc != 2)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_params) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " first argument is not a prepared statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLFreeStmt(hstmt, SQL_CLOSE);

	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
		    return TCL_ERROR;
	    }


    conn->rc = SQLExecute (hstmt);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    /* Return result by template db2sqlX.Y */
    snprintf (buff, MAX_ID_LENGTH, "%s.%d", conn->id, SQL_NULL_HANDLE);
    Tcl_AppendResult (interp, buff, (char *)NULL);

    return TCL_OK;
}
/*
    TCL syntax:

    db2_select_prepared handle

    Return database handle
*/

int Db2_select_prepared (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hdbc, hstmt;
    char id[MAX_ID_LENGTH + 1];
    char buff[MAX_ID_LENGTH + 1];
    short num_params;
    short num_fields;

    if (argc != 2)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_params) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " first argument is not a prepared statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLFreeStmt(hstmt, SQL_CLOSE);

	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
		    return TCL_ERROR;
	    }

    conn->rc = SQLExecute (hstmt);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    conn->rc = SQLNumResultCols (hstmt, &num_fields);
    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (buff, MAX_ID_LENGTH, "%s.%d.%d", conn->id, hstmt, num_fields);
    Tcl_AppendResult (interp, buff, (char *)NULL);

    return TCL_OK;
}

/*

/*
    TCL syntax:

    db2_fetchrow handle ?number?

    Return database handle
*/

int Db2_fetchrow (ClientData cData, Tcl_Interp * interp, int argc,
		  CONST84 char *argv[])
{
    int i = 1;
    int num_col = 0;
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLPOINTER *buff;
    SQLINTEGER size_buff;
    char id[MAX_ID_LENGTH + 1];
    SQLHANDLE hdbc, hstmt;
    short num_fields;
    SQLINTEGER res_size = 0;

    if (argc > 3 || argc < 2)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_fields) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    if (argv[2])
    {
	num_col = atoi (argv[2]);
    }

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLFetch (hstmt);

    if (conn->rc == SQL_NO_DATA_FOUND)
    {
	return TCL_OK;
    }

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    size_buff = 4096;
    buff = (SQLPOINTER *) ckalloc (size_buff);

    if (num_col)
    {
	conn->rc = SQLGetData (hstmt, i + 1, SQL_C_CHAR, buff,
                                       size_buff, &res_size);

        if (conn->rc != SQL_SUCCESS)
        {
    	    SQLError (henv, conn->hdbc, hstmt,
        	      (SQLCHAR *) & conn->sql_state,
                      &conn->native_error,
                      (SQLCHAR *) & conn->error_msg,
                      sizeof (conn->error_msg), &conn->size_error_msg);
    	    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
            ckfree (buff);
            return TCL_ERROR;
	}

 	Tcl_AppendElement (interp, (char *) buff); 
/* 	Tcl_AppendResult(interp, (char *)buff, " ", 0);  */
    }
    else
    {
	for (i = 0; i < num_fields; i++)
	{
	    conn->rc = SQLGetData (hstmt, i + 1, SQL_C_CHAR, buff, 
			    		size_buff, &res_size);

	    if (conn->rc != SQL_SUCCESS)
	    {
		    SQLError (henv, conn->hdbc, hstmt,
				    (SQLCHAR *) & conn->sql_state,
				    &conn->native_error,
				    (SQLCHAR *) & conn->error_msg,
				    sizeof (conn->error_msg), &conn->size_error_msg);
		    Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
		    ckfree (buff);
		    return TCL_ERROR;
	    }

	    Tcl_AppendElement (interp, (char *) buff);
	/*    Tcl_AppendResult(interp, (char *)buff, " ", 0);  */
	}
    }

    ckfree (buff);

    return TCL_OK;
}

/*
    TCL syntax: 

    db2_finish handle
*/

int Db2_finish (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    char id[MAX_ID_LENGTH + 1];
    SQLHANDLE hdbc, hstmt;
    short num_fields;

    if (argc != 2)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_fields) < 3)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid statement", (char *)NULL);
	return TCL_ERROR;
    }

    snprintf (id, MAX_ID_LENGTH, "db2sql%d", (int) hdbc);

    conn_channel = Tcl_GetChannel (interp, id, NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLFreeHandle (SQL_HANDLE_STMT, hstmt);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    return TCL_OK;
}

/*
    TCL syntax: 

    db2_getnumrows handle

    Return number of columns in query
*/
int Db2_getnumrows (ClientData cData, Tcl_Interp * interp, int argc,
                    CONST84 char *argv[])
{
    SQLHANDLE hdbc, hstmt;
    short num_fields;
    char buff[32];

    if (sscanf (argv[1], "db2sql%d.%d.%hd", &hdbc, &hstmt, &num_fields) < 3)
    {
        Tcl_AppendResult (interp, argv[1], " is not a valid statement", (char *)NULL);
        return TCL_ERROR;
    }

    snprintf (buff, 32, "%d", num_fields);

    Tcl_AppendResult (interp, buff, (char *)NULL);

    return TCL_OK;
}
/*
    TCL syntax: 

    db2_begin_transaction db_handle

*/

int Db2_begin_transaction (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;

    if (argc != 2 || argv[1] == NULL)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLSetConnectAttr (conn->hdbc,
                                  SQL_ATTR_AUTOCOMMIT,
                                  (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                                  SQL_NTS);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    return TCL_OK;
}

/*
    TCL syntax: 

    db2_commit_transaction db_handle

*/

int Db2_commit_transaction (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;

    if (argc != 2 || argv[1] == NULL)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLTransact (henv, conn->hdbc, SQL_COMMIT);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    conn->rc = SQLSetConnectAttr (conn->hdbc,
                                  SQL_ATTR_AUTOCOMMIT,
                                  (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                                  SQL_NTS);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    return TCL_OK;
}

/*
    TCL syntax: 

    db2_rollback_transaction db_handle

*/

int Db2_rollback_transaction (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    Tcl_Channel conn_channel;
    Db2Connection *conn;
    SQLHANDLE hstmt;

    if (argc != 2 || argv[1] == NULL)
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    conn_channel = Tcl_GetChannel (interp, argv[1], NULL);

    if (conn_channel == NULL)
    {
	Tcl_AppendResult (interp, argv[1], " is not a valid connection", (char *)NULL);
	return TCL_ERROR;
    }

    conn = (Db2Connection *) Tcl_GetChannelInstanceData (conn_channel);

    conn->rc = SQLTransact (henv, conn->hdbc, SQL_ROLLBACK);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    conn->rc = SQLSetConnectAttr (conn->hdbc,
                                  SQL_ATTR_AUTOCOMMIT,
                                  (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                                  SQL_NTS);

    if (conn->rc != SQL_SUCCESS)
    {
	SQLError (henv, conn->hdbc, hstmt,
		  (SQLCHAR *) & conn->sql_state,
		  &conn->native_error,
		  (SQLCHAR *) & conn->error_msg,
		  sizeof (conn->error_msg), &conn->size_error_msg);
	Tcl_AppendResult (interp, conn->error_msg, (char *)NULL);
	return TCL_ERROR;
    }

    return TCL_OK;
}

/*
    db2tcl super command
*/

int Db2_db2 (ClientData cData, Tcl_Interp * interp, int argc, CONST84 char *argv[])
{
    if (argc < 2 || argv[1] == NULL )
    {
	Tcl_AppendResult (interp, "Wrong number of arguments", (char *)NULL);
	return TCL_ERROR;
    }

    if (strncmp (argv[1], "fetchrow", 8) == 0)
    {
	Db2_fetchrow (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "getnumrows", 9) == 0)
    {
	Db2_getnumrows (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "select_direct", 13) == 0)
    {
	Db2_select_direct (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "select_prepared", 15) == 0)
    {
	Db2_select_prepared (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "prepare", 7) == 0)
    {
	Db2_prepare (cData, interp, argc - 1, argv + 1);
    } 
    else if (strncmp (argv[1], "bind_param", 10) == 0)
    {
	Db2_bind_param (cData, interp, argc - 1, argv + 1);
    } 
    else if (strncmp (argv[1], "bind_exec", 9) == 0)
    {
	Db2_bind_exec (cData, interp, argc - 1, argv + 1);
    } 
    else if (strncmp (argv[1], "finish", 6) == 0)
    {
	Db2_finish (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "exec_direct", 11) == 0)
    {
	Db2_exec_direct (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "exec_prepared", 13) == 0)
    {
	Db2_exec_prepared (cData, interp, argc - 1, argv + 1);
    }
    if (strncmp (argv[1], "connect", 7) == 0)
    {
	Db2_connect (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "disconnect", 10) == 0)
    {
	Db2_disconnect (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "begin_transaction", 17) == 0)
    {
	Db2_begin_transaction (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "commit_transaction", 18) == 0)
    {
	Db2_commit_transaction (cData, interp, argc - 1, argv + 1);
    }
    else if (strncmp (argv[1], "rollback_transaction", 20) == 0)
    {
	Db2_rollback_transaction (cData, interp, argc - 1, argv + 1);
    }
    return TCL_OK;
}

/* This function only for test */

int Db2_test (ClientData clientData, Tcl_Interp * interp, int objc, struct Tcl_Obj * CONST * objv)
{
    int i;

    for(i = 0; i < objc; i++)
    {
	printf("objv[%d] = %s\n", i, Tcl_GetStringFromObj(*(objv + i), NULL));
    }
    return 0;
}
