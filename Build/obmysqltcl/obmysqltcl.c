/*
 * OceanBase-only binding derived from HammerDB mysqltcl 3.052.1.
 * Source: https://www.hammerdb.com/build5/InputLibs/mysqltcl-3.052.1.7z
 * Changes: separate package, commands, status and object types; verified TLS
 * without plaintext fallback; hidden symbols except Tcl loading entry points.
 * Original copyright and permission notice follow and remain applicable.
 */
/*
 * $Eid: mysqltcl.c,v 1.2 2002/02/15 18:52:08 artur Exp $
 *
 * MYSQL interface to Tcl
 *
 * Hakan Soderstrom, hs@soderstrom.se
 *
 */

/*
 * Copyright (c) 1994, 1995 Hakan Soderstrom and Tom Poindexter
 *
 * Permission to use, copy, modify, distribute, and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice and this permission notice
 * appear in all copies of the software and related documentation.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 *
 * IN NO EVENT SHALL HAKAN SODERSTROM OR SODERSTROM PROGRAMVARUVERKSTAD
 * AB BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL
 * DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF THE POSSIBILITY
 * OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT OF OR IN
 * CONNECTON WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 Modified after version 2.0 by Artur Trzewik
 see http://www.xdobry.de/mysqltcl
 Patch for encoding option by Alexander Schoepe (version2.20)
*/


#ifndef PACKAGE_VERSION
#define PACKAGE_VERSION "0.1"
#endif
#if defined(__GNUC__)
#define OBMYSQL_EXPORT __attribute__((visibility("default")))
#else
#define OBMYSQL_EXPORT
#endif

#ifdef _WINDOWS
   #include <windows.h>
   #define PACKAGE "obmysqltcl"
   #define PACKAGE_VERSION "0.1"
   #define uint unsigned int
#endif


#include <tcl.h>
#include <mysql.h>

#include <errno.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#define TCL_RESULT_SIZE    200
#define MYSQL_SMALL_SIZE  TCL_RESULT_SIZE /* Smaller buffer size. */
#define MYSQL_NAME_LEN     80    /* Max. database name length. */
/* #define PREPARED_STATEMENT */

enum ObmysqlHandleType {HT_CONNECTION=1,HT_QUERY=2,HT_STATEMENT=3};

typedef struct ObmysqlTclHandle {
  MYSQL * connection;         /* Connection handle, if connected; NULL otherwise. */
  char database[MYSQL_NAME_LEN];  /* Db name, if selected; NULL otherwise. */
  MYSQL_RES* result;              /* Stored result, if any; NULL otherwise. */
  int res_count;                 /* Count of unfetched rows in result. */
  int col_count;                 /* Column count in result, if any. */
  int number;                    /* handle id */
  enum ObmysqlHandleType type;                      /* handle type */
  Tcl_Encoding encoding;         /* encoding for connection */
#ifdef PREPARED_STATEMENT
  MYSQL_STMT *statement;         /* used only by prepared statements*/
  MYSQL_BIND *bindParam;
  MYSQL_BIND *bindResult;
  MYSQL_RES *resultMetadata;
  MYSQL_RES *paramMetadata;
#endif
} ObmysqlTclHandle;

typedef struct ObmysqltclState {
  Tcl_HashTable hash;
  int handleNum;
  char *ObmysqlNullvalue;
  // Tcl_Obj *nullObjPtr;
} ObmysqltclState;

static char *ObmysqlHandlePrefix = "obmysql";
/* Prefix string used to identify handles.
 * The following must be strlen(ObmysqlHandlePrefix).
 */
#define MYSQL_HPREFIX_LEN 7

/* Array for status info, and its elements. */
#define MYSQL_STATUS_ARR "obmysqlstatus"

#define MYSQL_STATUS_CODE "code"
#define MYSQL_STATUS_CMD  "command"
#define MYSQL_STATUS_MSG  "message"
#define MYSQL_STATUS_NULLV  "nullvalue"

#define FUNCTION_NOT_AVAILABLE "function not available"

/* C variable corresponding to mysqlstatus(nullvalue) */
#define MYSQL_NULLV_INIT ""

/* Check Level for mysql_prologue */
enum CONNLEVEL {CL_PLAIN,CL_CONN,CL_DB,CL_RES};

/* Prototypes for all functions. */

static int Obmysqltcl_Use(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Escape(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Sel(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Fetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Seek(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Map(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Exec(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Close(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Info(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Result(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Col(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_State(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_InsertId(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Query(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Obmysqltcl_Receive(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int ObmysqlHandleSet(Tcl_Interp *interp,Tcl_Obj *objPtr);
static void ObmysqlHandleFree(Tcl_Obj *objPtr);
static int ObmysqlNullSet(Tcl_Interp *interp,Tcl_Obj *objPtr);
static Tcl_Obj *Obmysqltcl_NewNullObj(ObmysqltclState *obmysqltclState);
static void UpdateStringOfNull(Tcl_Obj *objPtr);

/* handle object type
 * This section defince funtions for Handling new Tcl_Obj type */

static Tcl_ObjType obmysqlHandleType = {
    "obmysqlhandle",
    ObmysqlHandleFree,
    (Tcl_DupInternalRepProc *) NULL,
    NULL,
    ObmysqlHandleSet
};
static Tcl_ObjType obmysqlNullType = {
    "obmysqlnull",
    (Tcl_FreeInternalRepProc *) NULL,
    (Tcl_DupInternalRepProc *) NULL,
    UpdateStringOfNull,
    ObmysqlNullSet
};


static ObmysqltclState *getMysqltclState(Tcl_Interp *interp) {
  Tcl_CmdInfo cmdInfo;
  if (Tcl_GetCommandInfo(interp,"obmysqlconnect",&cmdInfo)==0) {
    return NULL;
  }
  return (ObmysqltclState *)cmdInfo.objClientData;
}

static int ObmysqlHandleSet(Tcl_Interp *interp, register Tcl_Obj *objPtr)
{
    const Tcl_ObjType *oldTypePtr = objPtr->typePtr;
    char *string;
    ObmysqlTclHandle *handle;
    Tcl_HashEntry *entryPtr;
    ObmysqltclState *statePtr;

    string = Tcl_GetStringFromObj(objPtr, NULL);
    statePtr = getMysqltclState(interp);
    if (statePtr==NULL) return TCL_ERROR;

    entryPtr = Tcl_FindHashEntry(&statePtr->hash,string);
    if (entryPtr == NULL) {

      handle=0;
    } else {
      handle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);
    }
    if (!handle) {
        if (interp != NULL)
	  return TCL_ERROR;
    }
    if ((oldTypePtr != NULL) && (oldTypePtr->freeIntRepProc != NULL)) {
        oldTypePtr->freeIntRepProc(objPtr);
    }

    objPtr->internalRep.otherValuePtr = (ObmysqlTclHandle *) handle;
    objPtr->typePtr = &obmysqlHandleType;
    Tcl_Preserve((char *)handle);
    return TCL_OK;
}
static int ObmysqlNullSet(Tcl_Interp *interp, Tcl_Obj *objPtr)
{
    const Tcl_ObjType *oldTypePtr = objPtr->typePtr;

    if ((oldTypePtr != NULL) && (oldTypePtr->freeIntRepProc != NULL)) {
        oldTypePtr->freeIntRepProc(objPtr);
    }
    objPtr->typePtr = &obmysqlNullType;
    return TCL_OK;
}
static void UpdateStringOfNull(Tcl_Obj *objPtr) {
	int valueLen;
	ObmysqltclState *state = (ObmysqltclState *)objPtr->internalRep.otherValuePtr;

	valueLen = strlen(state->ObmysqlNullvalue);
	objPtr->bytes = Tcl_Alloc(valueLen+1);
	strcpy(objPtr->bytes,state->ObmysqlNullvalue);
	objPtr->length = valueLen;
}
static void ObmysqlHandleFree(Tcl_Obj *obj)
{
  ObmysqlTclHandle *handle = (ObmysqlTclHandle *)obj->internalRep.otherValuePtr;
  Tcl_Release((char *)handle);
}

static int GetHandleFromObj(Tcl_Interp *interp,Tcl_Obj *objPtr,ObmysqlTclHandle **handlePtr)
{
    if (Tcl_ConvertToType(interp, objPtr, &obmysqlHandleType) != TCL_OK)
        return TCL_ERROR;
    *handlePtr = (ObmysqlTclHandle *)objPtr->internalRep.otherValuePtr;
    return TCL_OK;
}

static Tcl_Obj *Tcl_NewHandleObj(ObmysqltclState *statePtr,ObmysqlTclHandle *handle)
{
    register Tcl_Obj *objPtr;
    char buffer[MYSQL_HPREFIX_LEN+TCL_DOUBLE_SPACE+1];
    register int len;
    Tcl_HashEntry *entryPtr;
    int newflag;

    objPtr=Tcl_NewObj();
    /* the string for "query" can not be longer as ObmysqlHandlePrefix see buf variable */
    len=sprintf(buffer, "%s%d", (handle->type==HT_QUERY) ? "obquery" : ObmysqlHandlePrefix,handle->number);
    objPtr->bytes = Tcl_Alloc((unsigned) len + 1);
    strcpy(objPtr->bytes, buffer);
    objPtr->length = len;

    entryPtr=Tcl_CreateHashEntry(&statePtr->hash,buffer,&newflag);
    Tcl_SetHashValue(entryPtr,handle);

    objPtr->internalRep.otherValuePtr = handle;
    objPtr->typePtr = &obmysqlHandleType;

    Tcl_Preserve((char *)handle);

    return objPtr;
}




/* CONFLICT HANDLING
 *
 * Every command begins by calling 'mysql_prologue'.
 * This function resets mysqlstatus(code) to zero; the other array elements
 * retain their previous values.
 * The function also saves objc/objv in global variables.
 * After this the command processing proper begins.
 *
 * If there is a conflict, the message is taken from one of the following
 * sources,
 * -- this code (mysql_prim_confl),
 * -- the database server (mysql_server_confl),
 * A complete message is put together from the above plus the name of the
 * command where the conflict was detected.
 * The complete message is returned as the Tcl result and is also stored in
 * mysqlstatus(message).
 * mysqlstatus(code) is set to "-1" for a primitive conflict or to mysql_errno
 * for a server conflict
 * In addition, the whole command where the conflict was detected is put
 * together from the saved objc/objv and is copied into mysqlstatus(command).
 */

/*
 *-----------------------------------------------------------
 * set_statusArr
 * Help procedure to set Tcl global array with obmysqltcl internal
 * informations
 */

static void set_statusArr(Tcl_Interp *interp,char *elem_name,Tcl_Obj *tobj)
{
  Tcl_SetVar2Ex (interp,MYSQL_STATUS_ARR,elem_name,tobj,TCL_GLOBAL_ONLY);
}

/*
 *----------------------------------------------------------------------
 * clear_msg
 *
 * Clears all error and message elements in the global array variable.
 *
 */

static void
clear_msg(Tcl_Interp *interp)
{
  set_statusArr(interp,MYSQL_STATUS_CODE,Tcl_NewIntObj(0));
  set_statusArr(interp,MYSQL_STATUS_CMD,Tcl_NewObj());
  set_statusArr(interp,MYSQL_STATUS_MSG,Tcl_NewObj());
}

/*
 *----------------------------------------------------------------------
 * mysql_reassemble
 * Reassembles the current command from the saved objv; copies it into
 * mysqlstatus(command).
 */

static void mysql_reassemble(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[])
{
   set_statusArr(interp,MYSQL_STATUS_CMD,Tcl_NewListObj(objc, objv));
}

/*
 * free result from handle and consume left result of multresult statement
 */
static void freeResult(ObmysqlTclHandle *handle)
{
	MYSQL_RES* result;
	if (handle->result != NULL) {
		mysql_free_result(handle->result);
		handle->result = NULL ;
	}
#if (MYSQL_VERSION_ID >= 50000)
	while (!mysql_next_result(handle->connection)) {
		result = mysql_store_result(handle->connection);
		if (result) {
			mysql_free_result(result);
		}
	}
#endif
}

/*
 *----------------------------------------------------------------------
 * mysql_prim_confl
 * Conflict handling after a primitive conflict.
 *
 */

static int mysql_prim_confl(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[],char *msg)
{
  set_statusArr(interp,MYSQL_STATUS_CODE,Tcl_NewIntObj(-1));

  Tcl_ResetResult(interp) ;
  Tcl_AppendStringsToObj(Tcl_GetObjResult(interp),
                          Tcl_GetString(objv[0]), ": ", msg, (char*)NULL);

  set_statusArr(interp,MYSQL_STATUS_MSG,Tcl_GetObjResult(interp));

  mysql_reassemble(interp,objc,objv) ;
  return TCL_ERROR ;
}


/*
 *----------------------------------------------------------------------
 * mysql_server_confl
 * Conflict handling after an mySQL conflict.
 * If error it set error message and return TCL_ERROR
 * If no error occurs it returns TCL_OK
 */

static int mysql_server_confl(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[],MYSQL * connection)
{
  const char* mysql_errorMsg;
  if (mysql_errno(connection)) {
    mysql_errorMsg = mysql_error(connection);

    set_statusArr(interp,MYSQL_STATUS_CODE,Tcl_NewIntObj(mysql_errno(connection)));


    Tcl_ResetResult(interp) ;
    Tcl_AppendStringsToObj(Tcl_GetObjResult(interp),
                          Tcl_GetString(objv[0]), "/db server: ",
		          (mysql_errorMsg == NULL) ? "" : mysql_errorMsg,
                          (char*)NULL) ;

    set_statusArr(interp,MYSQL_STATUS_MSG,Tcl_GetObjResult(interp));

    mysql_reassemble(interp,objc,objv);
    return TCL_ERROR;
  } else {
    return TCL_OK;
  }
}

static  ObmysqlTclHandle *get_handle(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[],int check_level)
{
  ObmysqlTclHandle *handle;
  if (GetHandleFromObj(interp, objv[1], &handle) != TCL_OK) {
    mysql_prim_confl(interp,objc,objv,"not obmysqltcl handle") ;
    return NULL;
  }
  if (check_level==CL_PLAIN) return handle;
  if (handle->connection == 0) {
      mysql_prim_confl(interp,objc,objv,"handle already closed (dangling pointer)") ;
      return NULL;
  }
  if (check_level==CL_CONN) return handle;
  if (check_level!=CL_RES) {
    if (handle->database[0] == '\0') {
      mysql_prim_confl(interp,objc,objv,"no current database") ;
      return NULL;
    }
    if (check_level==CL_DB) return handle;
  }
  if (handle->result == NULL) {
      mysql_prim_confl(interp,objc,objv,"no result pending") ;
      return NULL;
  }
  return handle;
}

/*----------------------------------------------------------------------

 * mysql_QueryTclObj
 * This to method control how tcl data is transfered to mysql and
 * how data is imported into tcl from mysql
 * Return value : Zero on success, Non-zero if an error occurred.
 */
static int mysql_QueryTclObj(ObmysqlTclHandle *handle,Tcl_Obj *obj)
{
  char *query;
  int result;
  Tcl_Size queryLen;

  Tcl_DString queryDS;

  query=Tcl_GetStringFromObj(obj, &queryLen);


  if (handle->encoding==NULL) {
    query = (char *) Tcl_GetByteArrayFromObj(obj, &queryLen);
    result =  mysql_real_query(handle->connection,query,queryLen);
  } else {
    Tcl_UtfToExternalDString(handle->encoding, query, -1, &queryDS);
    queryLen = Tcl_DStringLength(&queryDS);
    result =  mysql_real_query(handle->connection,Tcl_DStringValue(&queryDS),queryLen);
    Tcl_DStringFree(&queryDS);
  }
  return result;
}
static Tcl_Obj *getRowCellAsObject(ObmysqltclState *obmysqltclState,ObmysqlTclHandle *handle,MYSQL_ROW row,int length)
{
  Tcl_Obj *obj;
  Tcl_DString ds;

  if (*row) {
    if (handle->encoding!=NULL) {
      Tcl_ExternalToUtfDString(handle->encoding, *row, length, &ds);
      obj = Tcl_NewStringObj(Tcl_DStringValue(&ds), Tcl_DStringLength(&ds));
      Tcl_DStringFree(&ds);
    } else {
      obj = Tcl_NewByteArrayObj((unsigned char *)*row,length);
    }
  } else {
    obj = Obmysqltcl_NewNullObj(obmysqltclState);
  }
  return obj;
}

static ObmysqlTclHandle *createMysqlHandle(ObmysqltclState *statePtr)
{
  ObmysqlTclHandle *handle;
  handle=(ObmysqlTclHandle *)Tcl_Alloc(sizeof(ObmysqlTclHandle));
  memset(handle,0,sizeof(ObmysqlTclHandle));
  if (handle == 0) {
    Tcl_Panic("no memory for handle");
    return handle;
  }
  handle->type = HT_CONNECTION;

  /* MT-safe, because every thread in tcl has own interpreter */
  handle->number=statePtr->handleNum++;
  return handle;
}

static ObmysqlTclHandle *createHandleFrom(ObmysqltclState *statePtr,ObmysqlTclHandle *handle,enum ObmysqlHandleType handleType)
{
  int number;
  ObmysqlTclHandle *qhandle;
  qhandle = createMysqlHandle(statePtr);
  /* do not overwrite the number */
  number = qhandle->number;
  if (!qhandle) return qhandle;
  memcpy(qhandle,handle,sizeof(ObmysqlTclHandle));
  qhandle->type=handleType;
  qhandle->number=number;
  return qhandle;
}
static void closeHandle(ObmysqlTclHandle *handle)
{
  freeResult(handle);
  if (handle->type==HT_CONNECTION) {
    mysql_close(handle->connection);
  }
#ifdef PREPARED_STATEMENT
  if (handle->type==HT_STATEMENT) {
    if (handle->statement!=NULL)
	    mysql_stmt_close(handle->statement);
	if (handle->bindResult!=NULL)
		Tcl_Free((char *)handle->bindResult);
    if (handle->bindParam!=NULL)
        Tcl_Free((char *)handle->bindParam);
    if (handle->resultMetadata!=NULL)
	    mysql_free_result(handle->resultMetadata);
    if (handle->paramMetadata!=NULL)
	    mysql_free_result(handle->paramMetadata);
  }
#endif
  handle->connection = (MYSQL *)NULL;
  if (handle->encoding!=NULL && handle->type==HT_CONNECTION)
  {
    Tcl_FreeEncoding(handle->encoding);
    handle->encoding = NULL;
  }
  Tcl_EventuallyFree((char *)handle,TCL_DYNAMIC);
}

/*
 *----------------------------------------------------------------------
 * mysql_prologue
 *
 * Does most of standard command prologue; required for all commands
 * having conflict handling.
 * 'req_min_args' must be the minimum number of arguments for the command,
 * including the command word.
 * 'req_max_args' must be the maximum number of arguments for the command,
 * including the command word.
 * 'usage_msg' must be a usage message, leaving out the command name.
 * Checks the handle assumed to be present in objv[1] if 'check' is not NULL.
 * RETURNS: Handle index or -1 on failure.
 * SIDE EFFECT: Sets the Tcl result on failure.
 */

static ObmysqlTclHandle *mysql_prologue(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[],int req_min_args,int req_max_args,int check_level,char *usage_msg)
{
  /* Check number of args. */
  if (objc < req_min_args || objc > req_max_args) {
      Tcl_WrongNumArgs(interp, 1, objv, usage_msg);
      return NULL;
  }

  /* Reset mysqlstatus(code). */
  set_statusArr(interp,MYSQL_STATUS_CODE,Tcl_NewIntObj(0));

  /* Check the handle.
   * The function is assumed to set the status array on conflict.
   */
  return (get_handle(interp,objc,objv,check_level));
}

/*
 *----------------------------------------------------------------------
 * mysql_colinfo
 *
 * Given an MYSQL_FIELD struct and a string keyword appends a piece of
 * column info (one item) to the Tcl result.
 * ASSUMES 'fld' is non-null.
 * RETURNS 0 on success, 1 otherwise.
 * SIDE EFFECT: Sets the result and status on failure.
 */

static Tcl_Obj *mysql_colinfo(Tcl_Interp *interp,int objc,Tcl_Obj *const objv[],MYSQL_FIELD* fld,Tcl_Obj * keyw)
{
  int idx ;

  static const char* ObmysqlColkey[] =
    {
      "table", "name", "type", "length", "prim_key", "non_null", "numeric", "decimals", NULL
    };
  enum coloptions {
    MYSQL_COL_TABLE_K, MYSQL_COL_NAME_K, MYSQL_COL_TYPE_K, MYSQL_COL_LENGTH_K,
    MYSQL_COL_PRIMKEY_K, MYSQL_COL_NONNULL_K, MYSQL_COL_NUMERIC_K, MYSQL_COL_DECIMALS_K};

  if (Tcl_GetIndexFromObj(interp, keyw, ObmysqlColkey, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return NULL;

  switch (idx)
    {
    case MYSQL_COL_TABLE_K:
      return Tcl_NewStringObj(fld->table, -1) ;
    case MYSQL_COL_NAME_K:
      return Tcl_NewStringObj(fld->name, -1) ;
    case MYSQL_COL_TYPE_K:
      switch (fld->type)
	{


	case FIELD_TYPE_DECIMAL:
	  return Tcl_NewStringObj("decimal", -1);
	case FIELD_TYPE_TINY:
	  return Tcl_NewStringObj("tiny", -1);
	case FIELD_TYPE_SHORT:
	  return Tcl_NewStringObj("short", -1);
	case FIELD_TYPE_LONG:
	  return Tcl_NewStringObj("long", -1) ;
	case FIELD_TYPE_FLOAT:
	  return Tcl_NewStringObj("float", -1);
	case FIELD_TYPE_DOUBLE:
	  return Tcl_NewStringObj("double", -1);
	case FIELD_TYPE_NULL:
	  return Tcl_NewStringObj("null", -1);
	case FIELD_TYPE_TIMESTAMP:
	  return Tcl_NewStringObj("timestamp", -1);
	case FIELD_TYPE_LONGLONG:
	  return Tcl_NewStringObj("long long", -1);
	case FIELD_TYPE_INT24:
	  return Tcl_NewStringObj("int24", -1);
	case FIELD_TYPE_DATE:
	  return Tcl_NewStringObj("date", -1);
	case FIELD_TYPE_TIME:
	  return Tcl_NewStringObj("time", -1);
	case FIELD_TYPE_DATETIME:
	  return Tcl_NewStringObj("date time", -1);
	case FIELD_TYPE_YEAR:
	  return Tcl_NewStringObj("year", -1);
	case FIELD_TYPE_NEWDATE:
	  return Tcl_NewStringObj("new date", -1);
	case FIELD_TYPE_ENUM:
	  return Tcl_NewStringObj("enum", -1);
	case FIELD_TYPE_SET:
	  return Tcl_NewStringObj("set", -1);
	case FIELD_TYPE_TINY_BLOB:
	  return Tcl_NewStringObj("tiny blob", -1);
	case FIELD_TYPE_MEDIUM_BLOB:
	  return Tcl_NewStringObj("medium blob", -1);
	case FIELD_TYPE_LONG_BLOB:
	  return Tcl_NewStringObj("long blob", -1);
	case FIELD_TYPE_BLOB:
	  return Tcl_NewStringObj("blob", -1);
	case FIELD_TYPE_VAR_STRING:
	  return Tcl_NewStringObj("var string", -1);
	case FIELD_TYPE_STRING:
	  return Tcl_NewStringObj("string", -1);
#if MYSQL_VERSION_ID >= 50000
	case MYSQL_TYPE_NEWDECIMAL:
	   return Tcl_NewStringObj("newdecimal", -1);
	case MYSQL_TYPE_GEOMETRY:
	   return Tcl_NewStringObj("geometry", -1);
	case MYSQL_TYPE_BIT:
	   return Tcl_NewStringObj("bit", -1);
#endif
	default:
	  return Tcl_NewStringObj("unknown", -1);
	}
      break ;
    case MYSQL_COL_LENGTH_K:
      return Tcl_NewIntObj(fld->length) ;
    case MYSQL_COL_PRIMKEY_K:
      return Tcl_NewBooleanObj(IS_PRI_KEY(fld->flags));
    case MYSQL_COL_NONNULL_K:
      return Tcl_NewBooleanObj(IS_NOT_NULL(fld->flags));
    case MYSQL_COL_NUMERIC_K:
      return Tcl_NewBooleanObj(IS_NUM(fld->type));
    case MYSQL_COL_DECIMALS_K:
      return IS_NUM(fld->type)? Tcl_NewIntObj(fld->decimals): Tcl_NewIntObj(-1);
    default: /* should never happen */
      mysql_prim_confl(interp,objc,objv,"weirdness in mysql_colinfo");
      return NULL ;
    }
}

/*
 * Obmysqltcl_CloseAll
 * Close all connections.
 */

static void Obmysqltcl_CloseAll(ClientData clientData)
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  Tcl_HashSearch search;
  ObmysqlTclHandle *handle;
  Tcl_HashEntry *entryPtr;
  int wasdeleted=0;

  for (entryPtr=Tcl_FirstHashEntry(&statePtr->hash,&search);
       entryPtr!=NULL;
       entryPtr=Tcl_NextHashEntry(&search)) {
    wasdeleted=1;
    handle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);

    if (handle->connection == 0) continue;
    closeHandle(handle);
  }
  if (wasdeleted) {
    Tcl_DeleteHashTable(&statePtr->hash);
    Tcl_InitHashTable(&statePtr->hash, TCL_STRING_KEYS);
  }
}
/*
 * Invoked from Interpreter by removing obmysqltcl command

 * Warnign: This procedure can be called only once
 */
static void Obmysqltcl_Kill(ClientData clientData)
{
   ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
   Tcl_HashEntry *entryPtr;
   ObmysqlTclHandle *handle;
   Tcl_HashSearch search;

   for (entryPtr=Tcl_FirstHashEntry(&statePtr->hash,&search);
       entryPtr!=NULL;
       entryPtr=Tcl_NextHashEntry(&search)) {
     handle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);
     if (handle->connection == 0) continue;
     closeHandle(handle);
   }
   Tcl_Free(statePtr->ObmysqlNullvalue);
   Tcl_Free((char *)statePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Connect
 * Implements the mysqlconnect command:
 * usage: mysqlconnect ?option value ...?
 *
 * Results:
 *      handle - a character string of newly open handle
 *      TCL_OK - connect successful
 *      TCL_ERROR - connect not successful - error message returned
 */

static const char* ObmysqlConnectOpt[] =
    {
      "-host", "-user", "-password", "-db", "-port", "-socket","-encoding",
      "-ssl", "-compress", "-noschema","-odbc",
#if (MYSQL_VERSION_ID >= 40107)
      "-multistatement","-multiresult",
#endif
      "-localfiles","-ignorespace","-foundrows","-interactive","-sslkey","-sslcert",
      "-sslca","-sslcapath","-sslciphers","-reconnect", NULL
    };

static int Obmysqltcl_Connect(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  int        i, idx;
  int        mysql_options_reconnect = 0;
  char *hostname = NULL;
  char *user = NULL;
  char *password = NULL;
  char *db = NULL;
  int port = 0, flags = 0, booleanflag;
  char *socket = NULL;
  char *encodingname = NULL;

#if (MYSQL_VERSION_ID >= 40107)
  int isSSL = 0;
#endif
  char *sslkey = NULL;
  char *sslcert = NULL;
  char *sslca = NULL;
  char *sslcapath = NULL;
  char *sslcipher = NULL;

  ObmysqlTclHandle *handle;
  const char *groupname = "obmysqltcl";


  enum connectoption {
    MYSQL_CONNHOST_OPT, MYSQL_CONNUSER_OPT, MYSQL_CONNPASSWORD_OPT,
    MYSQL_CONNDB_OPT, MYSQL_CONNPORT_OPT, MYSQL_CONNSOCKET_OPT, MYSQL_CONNENCODING_OPT,
    MYSQL_CONNSSL_OPT, MYSQL_CONNCOMPRESS_OPT, MYSQL_CONNNOSCHEMA_OPT, MYSQL_CONNODBC_OPT,
#if (MYSQL_VERSION_ID >= 40107)
    MYSQL_MULTISTATEMENT_OPT,MYSQL_MULTIRESULT_OPT,
#endif
    MYSQL_LOCALFILES_OPT,MYSQL_IGNORESPACE_OPT,
    MYSQL_FOUNDROWS_OPT,MYSQL_INTERACTIVE_OPT,MYSQL_SSLKEY_OPT,MYSQL_SSLCERT_OPT,
    MYSQL_SSLCA_OPT,MYSQL_SSLCAPATH_OPT,MYSQL_SSLCIPHERS_OPT, MYSQL_RECONNECT_OPT
  };

  if (!(objc & 1) ||
    objc>(sizeof(ObmysqlConnectOpt)/sizeof(ObmysqlConnectOpt[0]-1)*2+1)) {
    Tcl_WrongNumArgs(interp, 1, objv, "[-user xxx] [-db mysql] [-port 3306] [-host localhost] [-socket sock] [-password pass] [-encoding encoding] [-ssl boolean] [-compress boolean] [-odbc boolean] [-noschema boolean] [-reconnect boolean]"
    );
	return TCL_ERROR;
  }

  for (i = 1; i < objc; i++) {
    if (Tcl_GetIndexFromObj(interp, objv[i], ObmysqlConnectOpt, "option",
                          0, &idx) != TCL_OK)
      return TCL_ERROR;

    switch (idx) {
    case MYSQL_CONNHOST_OPT:
      hostname = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNUSER_OPT:
      user = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNPASSWORD_OPT:
      password = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNDB_OPT:
      db = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNPORT_OPT:
      if (Tcl_GetIntFromObj(interp, objv[++i], &port) != TCL_OK)
	return TCL_ERROR;
      break;
    case MYSQL_CONNSOCKET_OPT:
      socket = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNENCODING_OPT:
      encodingname = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_CONNSSL_OPT:
#if (MYSQL_VERSION_ID >= 40107)
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&isSSL) != TCL_OK )
	return TCL_ERROR;
#else
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_SSL;
#endif
      break;
    case MYSQL_CONNCOMPRESS_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_COMPRESS;
      break;
    case MYSQL_CONNNOSCHEMA_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_NO_SCHEMA;
      break;
    case MYSQL_CONNODBC_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_ODBC;
      break;
#if (MYSQL_VERSION_ID >= 40107)
    case MYSQL_MULTISTATEMENT_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_MULTI_STATEMENTS;
      break;
    case MYSQL_MULTIRESULT_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_MULTI_RESULTS;
      break;
#endif
    case MYSQL_LOCALFILES_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_LOCAL_FILES;
      break;
    case MYSQL_IGNORESPACE_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_IGNORE_SPACE;
      break;
    case MYSQL_FOUNDROWS_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_FOUND_ROWS;
      break;
    case MYSQL_INTERACTIVE_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
	flags |= CLIENT_INTERACTIVE;
      break;
    case MYSQL_SSLKEY_OPT:
      sslkey = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_SSLCERT_OPT:
      sslcert = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_SSLCA_OPT:
      sslca = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_SSLCAPATH_OPT:
      sslcapath = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_SSLCIPHERS_OPT:
      sslcipher = Tcl_GetStringFromObj(objv[++i],NULL);
      break;
    case MYSQL_RECONNECT_OPT:
      if (Tcl_GetBooleanFromObj(interp,objv[++i],&booleanflag) != TCL_OK )
	return TCL_ERROR;
      if (booleanflag)
        mysql_options_reconnect = 1;
      break;
    default:
      return mysql_prim_confl(interp,objc,objv,"Weirdness in options");
    }
  }

  handle = createMysqlHandle(statePtr);

  if (handle == 0) {
    Tcl_Panic("no memory for handle");
    return TCL_ERROR;

  }

  handle->connection = mysql_init(NULL);

  /* the function below caused in version pre 3.23.50 segmentation fault */
#if (MYSQL_VERSION_ID>=32350)
  if(mysql_options_reconnect)
  {
      _Bool reconnect = 1;
      mysql_options(handle->connection, MYSQL_OPT_RECONNECT, &reconnect);
  }
  mysql_options(handle->connection,MYSQL_READ_DEFAULT_GROUP,groupname);
#endif
#if (MYSQL_VERSION_ID >= 40107)
  if (isSSL) {
      my_bool required = 1;
      /* In Connector/C, SSL_ENFORCE alone still permits a server without TLS.
       * VERIFY_SERVER_CERT also rejects that server before authentication and
       * verifies the certificate chain and the requested host name. */
      if (mysql_ssl_set(handle->connection, sslkey, sslcert, sslca, sslcapath, sslcipher)
          || mysql_options(handle->connection, MYSQL_OPT_SSL_ENFORCE, &required)
          || mysql_options(handle->connection, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &required)) {
          mysql_server_confl(interp,objc,objv,handle->connection);
          closeHandle(handle);
          return TCL_ERROR;
      }
  } else {
      my_bool disabled = 0;
      mysql_options(handle->connection, MYSQL_OPT_SSL_ENFORCE, &disabled);
      mysql_options(handle->connection, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &disabled);
  }
#endif
  if (!mysql_real_connect(handle->connection, hostname, user,
                                password, db, port, socket, flags)) {
      mysql_server_confl(interp,objc,objv,handle->connection);
      closeHandle(handle);
      return TCL_ERROR;
  }
  if (isSSL && mysql_get_ssl_cipher(handle->connection) == NULL) {
      mysql_prim_confl(interp,objc,objv,"TLS was requested but no TLS cipher was negotiated");
      closeHandle(handle);
      return TCL_ERROR;
  }

  if (db) {
    strncpy(handle->database, db, MYSQL_NAME_LEN) ;
    handle->database[MYSQL_NAME_LEN - 1] = '\0' ;
  }

  if (encodingname==NULL || (encodingname!=NULL &&  strcmp(encodingname, "binary") != 0)) {
    if (encodingname==NULL)
      encodingname = (char *)Tcl_GetEncodingName(NULL);
    handle->encoding = Tcl_GetEncoding(interp, encodingname);
    if (handle->encoding == NULL)
      return TCL_ERROR;
  }

  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr,handle));

  return TCL_OK;

}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Use
 *    Implements the mysqluse command:

 *    usage: mysqluse handle dbname
 *
 *    results:
 *	Sets current database to dbname.
 */

static int Obmysqltcl_Use(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  Tcl_Size len;
  char *db;
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle dbname")) == 0)
    return TCL_ERROR;

  db=Tcl_GetStringFromObj(objv[2], &len);
  if (len >= MYSQL_NAME_LEN) {
     mysql_prim_confl(interp,objc,objv,"database name too long");
     return TCL_ERROR;
  }

  if (mysql_select_db(handle->connection, db)!=0) {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }
  strcpy(handle->database, db);
  return TCL_OK;
}



/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Escape
 *    Implements the mysqlescape command:
 *    usage: mysqlescape string
 *
 *    results:
 *	Escaped string for use in queries.
 */

static int Obmysqltcl_Escape(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  Tcl_Size len;
  char *inString, *outString;
  ObmysqlTclHandle *handle;

  if (objc <2 || objc>3) {
      Tcl_WrongNumArgs(interp, 1, objv, "?handle? string");
      return TCL_ERROR;
  }
  if (objc==2) {
    inString=Tcl_GetStringFromObj(objv[1], &len);
    outString=Tcl_Alloc((len<<1) + 1);
    len=mysql_escape_string(outString, inString, len);
    Tcl_SetStringObj(Tcl_GetObjResult(interp), outString, len);
    Tcl_Free(outString);
  } else {
    if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle string")) == 0)
      return TCL_ERROR;
    inString=Tcl_GetStringFromObj(objv[2], &len);
    outString=Tcl_Alloc((len<<1) + 1);
    len=mysql_real_escape_string(handle->connection, outString, inString, len);
    Tcl_SetStringObj(Tcl_GetObjResult(interp), outString, len);
    Tcl_Free(outString);
  }
  return TCL_OK;
}



/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Sel
 *    Implements the mysqlsel command:
 *    usage: mysqlsel handle sel-query ?-list|-flatlist?
 *
 *    results:
 *
 *    SIDE EFFECT: Flushes any pending result, even in case of conflict.
 *    Stores new results.
 */

static int Obmysqltcl_Sel(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  Tcl_Obj *res, *resList;
  MYSQL_ROW row;
  ObmysqlTclHandle *handle;
  unsigned long *lengths;


  static const char* selOptions[] = {"-list", "-flatlist", NULL};
  /* Warning !! no option number */
  int i,selOption=2,colCount;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 4, CL_CONN,
			    "handle sel-query ?-list|-flatlist?")) == 0)
    return TCL_ERROR;


  if (objc==4) {
    if (Tcl_GetIndexFromObj(interp, objv[3], selOptions, "option",
			    TCL_EXACT, &selOption) != TCL_OK)
      return TCL_ERROR;
  }

  /* Flush any previous result. */
  freeResult(handle);

  if (mysql_QueryTclObj(handle,objv[2])) {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }
  if (selOption<2) {
    /* If imadiatly result than do not store result in mysql client library cache */
    handle->result = mysql_use_result(handle->connection);
  } else {
    handle->result = mysql_store_result(handle->connection);
  }

  if (handle->result == NULL) {
    if (selOption==2) Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
  } else {
    colCount = handle->col_count = mysql_num_fields(handle->result);
    res = Tcl_GetObjResult(interp);
    handle->res_count = 0;
    switch (selOption) {
    case 0: /* -list */
      while ((row = mysql_fetch_row(handle->result)) != NULL) {
	resList = Tcl_NewListObj(0, NULL);
	lengths = mysql_fetch_lengths(handle->result);
	for (i=0; i< colCount; i++, row++) {
	  Tcl_ListObjAppendElement(interp, resList,getRowCellAsObject(statePtr,handle,row,lengths[i]));
	}
	Tcl_ListObjAppendElement(interp, res, resList);
      }
      break;
    case 1: /* -flatlist */
      while ((row = mysql_fetch_row(handle->result)) != NULL) {
	lengths = mysql_fetch_lengths(handle->result);
	for (i=0; i< colCount; i++, row++) {
	  Tcl_ListObjAppendElement(interp, res,getRowCellAsObject(statePtr,handle,row,lengths[i]));
	}
      }
      break;
    case 2: /* No option */
      handle->res_count = mysql_num_rows(handle->result);
      Tcl_SetIntObj(res, handle->res_count);
      break;
    }
  }
  return TCL_OK;
}
/*
 * Obmysqltcl_Query
 * Works as obmysqltclsel but return an $query handle that allow to build
 * nested queries on simple handle
 */

static int Obmysqltcl_Query(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  MYSQL_RES *result;
  ObmysqlTclHandle *handle, *qhandle;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,

			    "handle sqlstatement")) == 0)
    return TCL_ERROR;

  if (mysql_QueryTclObj(handle,objv[2])) {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }

  if ((result = mysql_store_result(handle->connection)) == NULL) {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
    return TCL_OK;
  }
  if ((qhandle = createHandleFrom(statePtr,handle,HT_QUERY)) == NULL) return TCL_ERROR;
  qhandle->result = result;
  qhandle->col_count = mysql_num_fields(qhandle->result) ;


  qhandle->res_count = mysql_num_rows(qhandle->result);
  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr,qhandle));
  return TCL_OK;
}

/*
 * Obmysqltcl_Enquery
 * close and free a query handle
 * if handle is not query than the result will be discarted
 */

static int Obmysqltcl_EndQuery(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  Tcl_HashEntry *entryPtr;
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "queryhandle")) == 0)
    return TCL_ERROR;

  if (handle->type==HT_QUERY) {
    entryPtr = Tcl_FindHashEntry(&statePtr->hash,Tcl_GetStringFromObj(objv[1],NULL));
    if (entryPtr) {
      Tcl_DeleteHashEntry(entryPtr);
    }
    closeHandle(handle);
  } else {
      freeResult(handle);
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Exec
 * Implements the mysqlexec command:
 * usage: mysqlexec handle sql-statement
 *
 * Results:
 * Number of affected rows on INSERT, UPDATE or DELETE, 0 otherwise.
 *
 * SIDE EFFECT: Flushes any pending result, even in case of conflict.
 */



static int Obmysqltcl_Exec(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
	ObmysqlTclHandle *handle;
	int affected;
	Tcl_Obj *resList;
        if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,"handle sql-statement")) == 0)
           return TCL_ERROR;

        /* Flush any previous result. */
	freeResult(handle);

	if (mysql_QueryTclObj(handle,objv[2]))
        return mysql_server_confl(interp,objc,objv,handle->connection);

	if ((affected=mysql_affected_rows(handle->connection)) < 0) affected=0;

#if (MYSQL_VERSION_ID >= 50000)
	if (!mysql_next_result(handle->connection)) {
		resList = Tcl_GetObjResult(interp);
		Tcl_ListObjAppendElement(interp, resList, Tcl_NewIntObj(affected));
		do {
			if ((affected=mysql_affected_rows(handle->connection)) < 0) affected=0;
                Tcl_ListObjAppendElement(interp, resList, Tcl_NewIntObj(affected));
		} while (!mysql_next_result(handle->connection));
		return TCL_OK;
	}
#endif
	Tcl_SetIntObj(Tcl_GetObjResult(interp),affected);
	return TCL_OK ;
}



/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Fetch
 *    Implements the mysqlnext command:

 *    usage: obmysql::fetch handle
 *
 *    results:
 *	next row from pending results as tcl list, or null list.
 */

static int Obmysqltcl_Fetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle;
  int idx ;
  MYSQL_ROW row ;
  Tcl_Obj *resList;
  unsigned long *lengths;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_RES,"handle")) == 0)
    return TCL_ERROR;


  if (handle->res_count == 0)
    return TCL_OK ;
  else if ((row = mysql_fetch_row(handle->result)) == NULL) {
    handle->res_count = 0 ;
    return mysql_prim_confl(interp,objc,objv,"result counter out of sync") ;
  } else
    handle->res_count-- ;

  lengths = mysql_fetch_lengths(handle->result);


  resList = Tcl_GetObjResult(interp);
  for (idx = 0 ; idx < handle->col_count ; idx++, row++) {
    Tcl_ListObjAppendElement(interp, resList,getRowCellAsObject(statePtr,handle,row,lengths[idx]));
  }
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Seek
 *    Implements the mysqlseek command:
 *    usage: mysqlseek handle rownumber
 *
 *    results:
 *	number of remaining rows
 */

static int Obmysqltcl_Seek(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
    ObmysqlTclHandle *handle;
    int row;
    int total;

    if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_RES,
                              " handle row-index")) == 0)
      return TCL_ERROR;

    if (Tcl_GetIntFromObj(interp, objv[2], &row) != TCL_OK)
      return TCL_ERROR;

    total = mysql_num_rows(handle->result);

    if (total + row < 0) {
      mysql_data_seek(handle->result, 0);

      handle->res_count = total;
    } else if (row < 0) {
      mysql_data_seek(handle->result, total + row);
      handle->res_count = -row;
    } else if (row >= total) {
      mysql_data_seek(handle->result, row);
      handle->res_count = 0;
    } else {
      mysql_data_seek(handle->result, row);
      handle->res_count = total - row;
    }

    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count)) ;
    return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Map
 * Implements the mysqlmap command:
 * usage: mysqlmap handle binding-list script
 *
 * Results:
 * SIDE EFFECT: For each row the column values are bound to the variables
 * in the binding list and the script is evaluated.
 * The variables are created in the current context.
 * NOTE: mysqlmap works very much like a 'foreach' construct.
 * The 'continue' and 'break' commands may be used with their usual effect.
 */

static int Obmysqltcl_Map(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  int code ;
  int count ;

  ObmysqlTclHandle *handle;
  int idx;
  Tcl_Size listObjc;
  Tcl_Obj *tempObj,*varNameObj;
  MYSQL_ROW row;
  int *val;
  unsigned long *lengths;

  if ((handle = mysql_prologue(interp, objc, objv, 4, 4, CL_RES,
			    "handle binding-list script")) == 0)
    return TCL_ERROR;

  if (Tcl_ListObjLength(interp, objv[2], &listObjc) != TCL_OK)
        return TCL_ERROR ;


  if (listObjc > handle->col_count)
    {
      return mysql_prim_confl(interp,objc,objv,"too many variables in binding list") ;
    }
  else
    count = (listObjc < handle->col_count)?listObjc
      :handle->col_count ;

  val=(int*)Tcl_Alloc((count * sizeof(int)));

  for (idx=0; idx<count; idx++) {
    val[idx]=1;
    if (Tcl_ListObjIndex(interp, objv[2], idx, &varNameObj)!=TCL_OK)
        return TCL_ERROR;
    if (Tcl_GetStringFromObj(varNameObj,0)[0] != '-')
        val[idx]=1;
    else
        val[idx]=0;
  }

  while (handle->res_count > 0) {
    /* Get next row, decrement row counter. */
    if ((row = mysql_fetch_row(handle->result)) == NULL) {
      handle->res_count = 0 ;
      Tcl_Free((char *)val);
      return mysql_prim_confl(interp,objc,objv,"result counter out of sync") ;
    } else
      handle->res_count-- ;

    /* Bind variables to column values. */
    for (idx = 0; idx < count; idx++, row++) {
      lengths = mysql_fetch_lengths(handle->result);
      if (val[idx]) {
	tempObj = getRowCellAsObject(statePtr,handle,row,lengths[idx]);
        if (Tcl_ListObjIndex(interp, objv[2], idx, &varNameObj) != TCL_OK)
            goto error;
	if (Tcl_ObjSetVar2 (interp,varNameObj,NULL,tempObj,0) == NULL)
            goto error;
      }
    }

    /* Evaluate the script. */
    switch(code=Tcl_EvalObjEx(interp, objv[3],0)) {
    case TCL_CONTINUE:
    case TCL_OK:
      break ;
    case TCL_BREAK:
      Tcl_Free((char *)val);
      return TCL_OK ;
    default:
      Tcl_Free((char *)val);
      return code ;
    }
  }
  Tcl_Free((char *)val);
  return TCL_OK ;
error:
  Tcl_Free((char *)val);
  return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Receive
 * Implements the mysqlmap command:
 * usage: mysqlmap handle sqlquery binding-list script
 *
 * The method use internal mysql_use_result that no cache statment on client but
 * receive it direct from server
 *
 * Results:
 * SIDE EFFECT: For each row the column values are bound to the variables
 * in the binding list and the script is evaluated.
 * The variables are created in the current context.
 * NOTE: mysqlmap works very much like a 'foreach' construct.
 * The 'continue' and 'break' commands may be used with their usual effect.

 */

static int Obmysqltcl_Receive(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  int code=0;
  int count=0;

  ObmysqlTclHandle *handle;
  int idx;
  Tcl_Size listObjc;
  Tcl_Obj *tempObj,*varNameObj;
  MYSQL_ROW row;
  int *val = NULL;
  int breakLoop = 0;
  unsigned long *lengths;


  if ((handle = mysql_prologue(interp, objc, objv, 5, 5, CL_CONN,
			    "handle sqlquery binding-list script")) == 0)
    return TCL_ERROR;

  if (Tcl_ListObjLength(interp, objv[3], &listObjc) != TCL_OK)
        return TCL_ERROR;

  freeResult(handle);

  if (mysql_QueryTclObj(handle,objv[2])) {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }

  if ((handle->result = mysql_use_result(handle->connection)) == NULL) {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  } else {
    while ((row = mysql_fetch_row(handle->result))!= NULL) {
      if (val==NULL) {
	/* first row compute all data */
	handle->col_count = mysql_num_fields(handle->result);
	if (listObjc > handle->col_count) {
          return mysql_prim_confl(interp,objc,objv,"too many variables in binding list") ;
	} else {
	  count = (listObjc < handle->col_count)?listObjc:handle->col_count ;
	}
	val=(int*)Tcl_Alloc((count * sizeof(int)));
	for (idx=0; idx<count; idx++) {
          if (Tcl_ListObjIndex(interp, objv[3], idx, &varNameObj)!=TCL_OK)
            return TCL_ERROR;
	  if (Tcl_GetStringFromObj(varNameObj,0)[0] != '-')
	    val[idx]=1;
	  else
	    val[idx]=0;
	}
      }
      for (idx = 0; idx < count; idx++, row++) {
	 lengths = mysql_fetch_lengths(handle->result);

	 if (val[idx]) {
	    if (Tcl_ListObjIndex(interp, objv[3], idx, &varNameObj)!=TCL_OK) {
                Tcl_Free((char *)val);
                return TCL_ERROR;
            }
            tempObj = getRowCellAsObject(statePtr,handle,row,lengths[idx]);
            if (Tcl_ObjSetVar2 (interp,varNameObj,NULL,tempObj,TCL_LEAVE_ERR_MSG) == NULL) {
	       Tcl_Free((char *)val);
	       return TCL_ERROR ;
	    }
	 }
      }

      /* Evaluate the script. */
      switch(code=Tcl_EvalObjEx(interp, objv[4],0)) {
      case TCL_CONTINUE:
      case TCL_OK:
	break ;
      case TCL_BREAK:
	breakLoop=1;
	break;
      default:
	breakLoop=1;
	break;
      }
      if (breakLoop==1) break;
    }
  }
  if (val!=NULL) {
    Tcl_Free((char *)val);
  }
  /*  Read all rest rows that leave in error or break case */
  while ((row = mysql_fetch_row(handle->result))!= NULL);
  if (code!=TCL_CONTINUE && code!=TCL_OK && code!=TCL_BREAK) {
    return code;
  } else {
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Info
 * Implements the mysqlinfo command:
 * usage: mysqlinfo handle option
 *


 */

static int Obmysqltcl_Info(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{

  int count ;
  ObmysqlTclHandle *handle;
  int idx ;
  MYSQL_RES* list ;
  MYSQL_ROW row ;
  const char* val ;
  Tcl_Obj *resList;
  static const char* ObmysqlDbOpt[] =
    {
      "dbname", "dbname?", "tables", "host", "host?", "databases",
      "info","serverversion",
#if (MYSQL_VERSION_ID >= 40107)
      "serverversionid","sqlstate",
#endif
      "state",NULL
    };
  enum dboption {
    MYSQL_INFNAME_OPT, MYSQL_INFNAMEQ_OPT, MYSQL_INFTABLES_OPT,
    MYSQL_INFHOST_OPT, MYSQL_INFHOSTQ_OPT, MYSQL_INFLIST_OPT, MYSQL_INFO,
    MYSQL_INF_SERVERVERSION,MYSQL_INFO_SERVERVERSION_ID,MYSQL_INFO_SQLSTATE,MYSQL_INFO_STATE
  };

  /* We can't fully check the handle at this stage. */
  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_PLAIN,
			    "handle option")) == 0)
    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], ObmysqlDbOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx) {
  case MYSQL_INFNAMEQ_OPT:
    if ((handle = get_handle(interp,objc,objv,CL_CONN))!=NULL) {
      if (handle->database[0] == '\0')
	return TCL_OK ; /* Return empty string if no current db. */
    }
    break ;
  case MYSQL_INFNAME_OPT:
  case MYSQL_INFTABLES_OPT:
  case MYSQL_INFHOST_OPT:
  case MYSQL_INFLIST_OPT:
    /* !!! */
    handle = get_handle(interp,objc,objv,CL_CONN);
    break;
  case MYSQL_INFO:
  case MYSQL_INF_SERVERVERSION:
#if (MYSQL_VERSION_ID >= 40107)
  case MYSQL_INFO_SERVERVERSION_ID:
  case MYSQL_INFO_SQLSTATE:
#endif
  case MYSQL_INFO_STATE:
    break;

  case MYSQL_INFHOSTQ_OPT:
    if (handle->connection == 0)
      return TCL_OK ; /* Return empty string if not connected. */
    break;
  default: /* should never happen */
    return mysql_prim_confl(interp,objc,objv,"weirdness in Obmysqltcl_Info") ;
  }

  if (handle == 0) return TCL_ERROR ;

  /* Handle OK, return the requested info. */
  switch (idx) {
  case MYSQL_INFNAME_OPT:
  case MYSQL_INFNAMEQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(handle->database, -1));
    break ;
  case MYSQL_INFTABLES_OPT:
    if ((list = mysql_list_tables(handle->connection,(char*)NULL)) == NULL)
      return mysql_server_confl(interp,objc,objv,handle->connection);

    resList = Tcl_GetObjResult(interp);
    for (count = mysql_num_rows(list); count > 0; count--) {
      val = *(row = mysql_fetch_row(list)) ;
      Tcl_ListObjAppendElement(interp, resList, Tcl_NewStringObj((val == NULL)?"":val,-1));
    }
    mysql_free_result(list) ;
    break ;
  case MYSQL_INFHOST_OPT:

  case MYSQL_INFHOSTQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_host_info(handle->connection), -1));
    break ;
  case MYSQL_INFLIST_OPT:
    if ((list = mysql_list_dbs(handle->connection,(char*)NULL)) == NULL)
      return mysql_server_confl(interp,objc,objv,handle->connection);

    resList = Tcl_GetObjResult(interp);
    for (count = mysql_num_rows(list); count > 0; count--) {
      val = *(row = mysql_fetch_row(list)) ;
      Tcl_ListObjAppendElement(interp, resList,
				Tcl_NewStringObj((val == NULL)?"":val,-1));
    }
    mysql_free_result(list) ;
    break ;
  case MYSQL_INFO:
    val = mysql_info(handle->connection);
    if (val!=NULL) {
      Tcl_SetObjResult(interp, Tcl_NewStringObj(val,-1));
    }
    break;
  case MYSQL_INF_SERVERVERSION:
     Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_server_info(handle->connection),-1));
     break;
#if (MYSQL_VERSION_ID >= 40107)
  case MYSQL_INFO_SERVERVERSION_ID:
	 Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_get_server_version(handle->connection)));
	 break;
  case MYSQL_INFO_SQLSTATE:
     Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_sqlstate(handle->connection),-1));
     break;
#endif
  case MYSQL_INFO_STATE:
     Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_stat(handle->connection),-1));
     break;
  default: /* should never happen */
    return mysql_prim_confl(interp,objc,objv,"weirdness in Obmysqltcl_Info") ;
  }

  return TCL_OK ;
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_BaseInfo
 * Implements the mysqlinfo command:
 * usage: mysqlbaseinfo option
 *
 */

static int Obmysqltcl_BaseInfo(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int idx ;
  Tcl_Obj *resList;
  char **option;
  static const char* ObmysqlInfoOpt[] =
    {
      "connectparameters", "clientversion",
#if (MYSQL_VERSION_ID >= 40107)
      "clientversionid",
#endif
      NULL
    };
  enum baseoption {
    MYSQL_BINFO_CONNECT, MYSQL_BINFO_CLIENTVERSION,MYSQL_BINFO_CLIENTVERSIONID
  };

  if (objc <2) {
      Tcl_WrongNumArgs(interp, 1, objv, "connectparameters | clientversion");

      return TCL_ERROR;
  }
  if (Tcl_GetIndexFromObj(interp, objv[1], ObmysqlInfoOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx) {
  case MYSQL_BINFO_CONNECT:
    option = (char **)ObmysqlConnectOpt;
    resList = Tcl_NewListObj(0, NULL);

    while (*option!=NULL) {
      Tcl_ListObjAppendElement(interp, resList, Tcl_NewStringObj(*option,-1));
      option++;
    }
    Tcl_SetObjResult(interp, resList);
    break ;
  case MYSQL_BINFO_CLIENTVERSION:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_client_info(),-1));
    break;
#if (MYSQL_VERSION_ID >= 40107)
  case MYSQL_BINFO_CLIENTVERSIONID:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_get_client_version()));
    break;
#endif
  }
  return TCL_OK ;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Result

 * Implements the mysqlresult command:
 * usage: mysqlresult handle option
 *
 */

static int Obmysqltcl_Result(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int idx ;
  ObmysqlTclHandle *handle;
  static const char* ObmysqlResultOpt[] =
    {
     "rows", "rows?", "cols", "cols?", "current", "current?", NULL
    };
  enum resultoption {
    MYSQL_RESROWS_OPT, MYSQL_RESROWSQ_OPT, MYSQL_RESCOLS_OPT,
    MYSQL_RESCOLSQ_OPT, MYSQL_RESCUR_OPT, MYSQL_RESCURQ_OPT
  };
  /* We can't fully check the handle at this stage. */
  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_PLAIN,
			    " handle option")) == 0)

    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], ObmysqlResultOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx) {
  case MYSQL_RESROWS_OPT:
  case MYSQL_RESCOLS_OPT:
  case MYSQL_RESCUR_OPT:
    handle = get_handle(interp,objc,objv,CL_RES) ;
    break ;
  case MYSQL_RESROWSQ_OPT:
  case MYSQL_RESCOLSQ_OPT:
  case MYSQL_RESCURQ_OPT:
    if ((handle = get_handle(interp,objc,objv,CL_RES))== NULL)
      return TCL_OK ; /* Return empty string if no pending result. */
    break ;
  default: /* should never happen */
    return mysql_prim_confl(interp,objc,objv,"weirdness in Obmysqltcl_Result") ;
  }


  if (handle == 0)
    return TCL_ERROR ;

  /* Handle OK; return requested info. */
  switch (idx) {
  case MYSQL_RESROWS_OPT:
  case MYSQL_RESROWSQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count));
    break ;
  case MYSQL_RESCOLS_OPT:
  case MYSQL_RESCOLSQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->col_count));
    break ;
  case MYSQL_RESCUR_OPT:
  case MYSQL_RESCURQ_OPT:
    Tcl_SetObjResult(interp,
                       Tcl_NewIntObj(mysql_num_rows(handle->result)
	                             - handle->res_count)) ;
    break ;
  default:
    return mysql_prim_confl(interp,objc,objv,"weirdness in Obmysqltcl_Result");
  }
  return TCL_OK ;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Col

 *    Implements the mysqlcol command:
 *    usage: mysqlcol handle table-name option ?option ...?
 *           mysqlcol handle -current option ?option ...?
 * '-current' can only be used if there is a pending result.
 *
 *    results:
 *	List of lists containing column attributes.
 *      If a single attribute is requested the result is a simple list.
 *
 * SIDE EFFECT: '-current' disturbs the field position of the result.
 */

static int Obmysqltcl_Col(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int coln ;
  int current_db ;
  ObmysqlTclHandle *handle;
  int idx ;
  Tcl_Size listObjc ;
  Tcl_Obj **listObjv, *colinfo, *resList, *resSubList;
  MYSQL_FIELD* fld ;
  MYSQL_RES* result ;
  char *argv ;

  /* This check is enough only without '-current'. */
  if ((handle = mysql_prologue(interp, objc, objv, 4, 99, CL_CONN,
			    "handle table-name option ?option ...?")) == 0)
    return TCL_ERROR;

  /* Fetch column info.
   * Two ways: explicit database and table names, or current.
   */
  argv=Tcl_GetStringFromObj(objv[2],NULL);
  current_db = strcmp(argv, "-current") == 0;

  if (current_db) {
    if ((handle = get_handle(interp,objc,objv,CL_RES)) == 0)
      return TCL_ERROR ;
    else
      result = handle->result ;
  } else {
    if ((result = mysql_list_fields(handle->connection, argv, (char*)NULL)) == NULL) {
      return mysql_server_confl(interp,objc,objv,handle->connection) ;
    }
  }
  /* Must examine the first specifier at this point. */
  if (Tcl_ListObjGetElements(interp, objv[3], &listObjc, &listObjv) != TCL_OK)
    return TCL_ERROR ;
  resList = Tcl_GetObjResult(interp);
  if (objc == 4 && listObjc == 1) {
      mysql_field_seek(result, 0) ;
      while ((fld = mysql_fetch_field(result)) != NULL)
        if ((colinfo = mysql_colinfo(interp,objc,objv,fld, objv[3])) != NULL) {
            Tcl_ListObjAppendElement(interp, resList, colinfo);
        } else {
            goto conflict;
	    }
  } else if (objc == 4 && listObjc > 1) {
      mysql_field_seek(result, 0) ;
      while ((fld = mysql_fetch_field(result)) != NULL) {
        resSubList = Tcl_NewListObj(0, NULL);
        for (coln = 0; coln < listObjc; coln++)
            if ((colinfo = mysql_colinfo(interp,objc,objv,fld, listObjv[coln])) != NULL) {
                Tcl_ListObjAppendElement(interp, resSubList, colinfo);
            } else {

               goto conflict;
            }
        Tcl_ListObjAppendElement(interp, resList, resSubList);
	}
  } else {
      for (idx = 3; idx < objc; idx++) {
        resSubList = Tcl_NewListObj(0, NULL);
        mysql_field_seek(result, 0) ;
        while ((fld = mysql_fetch_field(result)) != NULL)
        if ((colinfo = mysql_colinfo(interp,objc,objv,fld, objv[idx])) != NULL) {

            Tcl_ListObjAppendElement(interp, resSubList, colinfo);
        } else {
            goto conflict;
        }
        Tcl_ListObjAppendElement(interp, resList, resSubList);
      }
  }
  if (!current_db) mysql_free_result(result) ;
  return TCL_OK;

  conflict:
    if (!current_db) mysql_free_result(result) ;
    return TCL_ERROR;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_State
 *    Implements the mysqlstate command:
 *    usage: mysqlstate handle ?-numeric?

 *
 */

static int Obmysqltcl_State(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqlTclHandle *handle;
  int numeric=0 ;
  Tcl_Obj *res;

  if (objc!=2 && objc!=3) {
      Tcl_WrongNumArgs(interp, 1, objv, "handle ?-numeric");
      return TCL_ERROR;
  }

  if (objc==3) {
    if (strcmp(Tcl_GetStringFromObj(objv[2],NULL), "-numeric"))
      return mysql_prim_confl(interp,objc,objv,"last parameter should be -numeric");
    else

      numeric=1;
  }

  if (GetHandleFromObj(interp, objv[1], &handle) != TCL_OK)
    res = (numeric)?Tcl_NewIntObj(0):Tcl_NewStringObj("NOT_A_HANDLE",-1);
  else if (handle->connection == 0)
    res = (numeric)?Tcl_NewIntObj(1):Tcl_NewStringObj("UNCONNECTED",-1);
  else if (handle->database[0] == '\0')
    res = (numeric)?Tcl_NewIntObj(2):Tcl_NewStringObj("CONNECTED",-1);
  else if (handle->result == NULL)
    res = (numeric)?Tcl_NewIntObj(3):Tcl_NewStringObj("IN_USE",-1);
  else
    res = (numeric)?Tcl_NewIntObj(4):Tcl_NewStringObj("RESULT_PENDING",-1);

  Tcl_SetObjResult(interp, res);
  return TCL_OK ;
}


/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_InsertId
 *    Implements the mysqlstate command:
 *    usage: mysqlinsertid handle
 *    Returns the auto increment id of the last INSERT statement
 *
 */

static int Obmysqltcl_InsertId(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{

  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;

  Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_insert_id(handle->connection)));

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Ping
 *    usage: mysqlping handle
 *    It can be used to check and refresh (reconnect after time out) the connection
 *    Returns 0 if connection is OK
 */


static int Obmysqltcl_Ping(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;

  Tcl_SetObjResult(interp, Tcl_NewBooleanObj(mysql_ping(handle->connection)==0));

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_ChangeUser
 *    usage: mysqlchangeuser handle user password database
 *    return TCL_ERROR if operation failed
 */

static int Obmysqltcl_ChangeUser(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqlTclHandle *handle;
  Tcl_Size len;
  char *user,*password,*database=NULL;

  if ((handle = mysql_prologue(interp, objc, objv, 4, 5, CL_CONN,
			    "handle user password ?database?")) == 0)
    return TCL_ERROR;

  user = Tcl_GetStringFromObj(objv[2],NULL);
  password = Tcl_GetStringFromObj(objv[3],NULL);
  if (objc==5) {
    database = Tcl_GetStringFromObj(objv[4],&len);
    if (len >= MYSQL_NAME_LEN) {
       mysql_prim_confl(interp,objc,objv,"database name too long");
       return TCL_ERROR;
    }
  }
  if (mysql_change_user(handle->connection, user, password, database)!=0) {
      mysql_server_confl(interp,objc,objv,handle->connection);
      return TCL_ERROR;
  }
  if (database!=NULL)
	  strcpy(handle->database, database);
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_AutoCommit
 *    usage: obmysql::autocommit bool
 *    set autocommit mode
 */

static int Obmysqltcl_AutoCommit(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;
  int isAutocommit = 0;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle bool")) == 0)
	return TCL_ERROR;
  if (Tcl_GetBooleanFromObj(interp,objv[2],&isAutocommit) != TCL_OK )
	return TCL_ERROR;
  if (mysql_autocommit(handle->connection, isAutocommit)!=0) {
        mysql_server_confl(interp,objc,objv,handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Commit
 *    usage: obmysql::commit
 *
 */

static int Obmysqltcl_Commit(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;
  if (mysql_commit(handle->connection)!=0) {
        mysql_server_confl(interp,objc,objv,handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Rollback
 *    usage: obmysql::rollback
 *
 */

static int Obmysqltcl_Rollback(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;
  if (mysql_rollback(handle->connection)!=0) {
      mysql_server_confl(interp,objc,objv,handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_MoreResult
 *    usage: obmysql::moreresult handle
 *    return true if more results exists
 */

static int Obmysqltcl_MoreResult(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;
  int boolResult = 0;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_RES,
			    "handle")) == 0)
    return TCL_ERROR;
  boolResult =  mysql_more_results(handle->connection);
  Tcl_SetObjResult(interp,Tcl_NewBooleanObj(boolResult));
  return TCL_OK;
#endif
}
/*

 *----------------------------------------------------------------------
 *
 * Obmysqltcl_NextResult
 *    usage: obmysql::nextresult
 *
 *  return nummber of rows in result set. 0 if no next result
 */

static int Obmysqltcl_NextResult(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;
  int result = 0;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_RES,
			    "handle")) == 0)
    return TCL_ERROR;
  if (handle->result != NULL) {
    mysql_free_result(handle->result) ;
    handle->result = NULL ;
  }
  result = mysql_next_result(handle->connection);
  if (result==-1) {
      Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
      return TCL_OK;
  }
  if (result<0) {
      return mysql_server_confl(interp,objc,objv,handle->connection);
  }
  handle->result = mysql_store_result(handle->connection);
  handle->col_count = mysql_num_fields(handle->result);
  if (handle->result == NULL) {
      Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
  } else {
      handle->res_count = mysql_num_rows(handle->result);
      Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count));
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_WarningCount
 *    usage: obmysql::warningcount
 *
 */

static int Obmysqltcl_WarningCount(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;
  int count = 0;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;
  count = mysql_warning_count(handle->connection);
  Tcl_SetObjResult(interp,Tcl_NewIntObj(count));
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_IsNull
 *    usage: obmysql::isnull value
 *
 */

static int Obmysqltcl_IsNull(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int boolResult = 0;
  if (objc != 2) {
      Tcl_WrongNumArgs(interp, 1, objv, "value");
      return TCL_ERROR;
  }
  boolResult = objv[1]->typePtr == &obmysqlNullType;
  Tcl_SetObjResult(interp,Tcl_NewBooleanObj(boolResult));
  return TCL_OK;

  return TCL_OK;
}
/*
 * Create new Obmysql NullObject
 * (similar to Tcl API for example Tcl_NewIntObj)
 */
static Tcl_Obj *Obmysqltcl_NewNullObj(ObmysqltclState *obmysqltclState) {
  Tcl_Obj *objPtr;
  objPtr = Tcl_NewObj();
  objPtr->bytes = NULL;
  objPtr->typePtr = &obmysqlNullType;
  objPtr->internalRep.otherValuePtr = obmysqltclState;
  return objPtr;
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_NewNull
 *    usage: obmysql::newnull
 *
 */

static int Obmysqltcl_NewNull(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  if (objc != 1) {
      Tcl_WrongNumArgs(interp, 1, objv, "");
      return TCL_ERROR;
  }
  Tcl_SetObjResult(interp,Obmysqltcl_NewNullObj((ObmysqltclState *)clientData));
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_SetServerOption
 *    usage: obmysql::setserveroption (-
 *
 */
#if (MYSQL_VERSION_ID >= 40107)
static const char* ObmysqlServerOpt[] =
    {
      "-multi_statment_on", "-multi_statment_off", "-auto_reconnect_on", "-auto_reconnect_off", NULL
    };
#endif

static int Obmysqltcl_SetServerOption(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  ObmysqlTclHandle *handle;
  int idx;
  enum enum_mysql_set_option mysqlServerOption;

  enum serveroption {
    MYSQL_MSTATMENT_ON_SOPT, MYSQL_MSTATMENT_OFF_SOPT
  };

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle option")) == 0)
    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], ObmysqlServerOpt, "option",
                          0, &idx) != TCL_OK)
      return TCL_ERROR;

  switch (idx) {
    case MYSQL_MSTATMENT_ON_SOPT:
      mysqlServerOption = MYSQL_OPTION_MULTI_STATEMENTS_ON;
      break;
    case MYSQL_MSTATMENT_OFF_SOPT:
      mysqlServerOption = MYSQL_OPTION_MULTI_STATEMENTS_OFF;
      break;
    default:
      return mysql_prim_confl(interp,objc,objv,"Weirdness in server options");
  }
  if (mysql_set_server_option(handle->connection,mysqlServerOption)!=0) {
        mysql_server_confl(interp,objc,objv,handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_ShutDown
 *    usage: obmysql::shutdown handle
 *
 */
static int Obmysqltcl_ShutDown(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "handle")) == 0)
    return TCL_ERROR;
#if (MYSQL_VERSION_ID >= 40107)
  if (mysql_shutdown(handle->connection,SHUTDOWN_DEFAULT)!=0) {
#else
  if (mysql_shutdown(handle->connection)!=0) {
#endif
        mysql_server_confl(interp,objc,objv,handle->connection);
  }
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Encoding
 *    usage: obmysql::encoding handle ?encoding|binary?
 *
 */
static int Obmysqltcl_Encoding(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  Tcl_HashSearch search;
  Tcl_HashEntry *entryPtr;
  ObmysqlTclHandle *handle,*qhandle;
  char *encodingname;
  Tcl_Encoding encoding;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 3, CL_CONN,
			    "handle")) == 0)
        return TCL_ERROR;
  if (objc==2) {
      if (handle->encoding == NULL)
         Tcl_SetObjResult(interp, Tcl_NewStringObj("binary",-1));
      else
         Tcl_SetObjResult(interp, Tcl_NewStringObj(Tcl_GetEncodingName(handle->encoding),-1));
  } else {
      if (handle->type!=HT_CONNECTION) {
            Tcl_SetObjResult(interp, Tcl_NewStringObj("encoding set can be used only on connection handle",-1));
            return TCL_ERROR;
      }
      encodingname = Tcl_GetStringFromObj(objv[2],NULL);
      if (strcmp(encodingname, "binary") == 0) {
	 encoding = NULL;
      } else {
         encoding = Tcl_GetEncoding(interp, encodingname);
	 if (encoding == NULL)
	     return TCL_ERROR;
      }
      if (handle->encoding!=NULL)
          Tcl_FreeEncoding(handle->encoding);
      handle->encoding = encoding;

      /* change encoding of all subqueries */
      for (entryPtr=Tcl_FirstHashEntry(&statePtr->hash,&search);
               entryPtr!=NULL;
                entryPtr=Tcl_NextHashEntry(&search)) {
            qhandle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);
            if (qhandle->type==HT_QUERY && handle->connection==qhandle->connection) {
                qhandle->encoding = encoding;
            }
      }

  }
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Close --
 *    Implements the mysqlclose command:
 *    usage: mysqlclose ?handle?
 *
 *    results:
 *	null string
 */

static int Obmysqltcl_Close(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])

{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle,*thandle;
  Tcl_HashEntry *entryPtr;
  Tcl_HashEntry *qentries[16];
  Tcl_HashSearch search;

  int i,qfound = 0;


  /* If handle omitted, close all connections. */
  if (objc == 1) {
      Obmysqltcl_CloseAll(clientData) ;
      return TCL_OK ;
  }

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "?handle?")) == 0)
    return TCL_ERROR;


  /* Search all queries and statements on this handle and close those */
  if (handle->type==HT_CONNECTION)  {
    while (1) {
      for (entryPtr=Tcl_FirstHashEntry(&statePtr->hash,&search);
	   entryPtr!=NULL;
	   entryPtr=Tcl_NextHashEntry(&search)) {

	thandle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);
	if (thandle->connection == handle->connection &&
	    thandle->type!=HT_CONNECTION) {
	  qentries[qfound++] = entryPtr;
	}
	if (qfound==16) break;
      }
      if (qfound>0) {
	for(i=0;i<qfound;i++) {
	  entryPtr=qentries[i];
	  thandle=(ObmysqlTclHandle *)Tcl_GetHashValue(entryPtr);
	  Tcl_DeleteHashEntry(entryPtr);
	  closeHandle(thandle);
	}
      }
      if (qfound!=16) break;
      qfound = 0;
    }
  }
  entryPtr = Tcl_FindHashEntry(&statePtr->hash,Tcl_GetStringFromObj(objv[1],NULL));
  if (entryPtr) Tcl_DeleteHashEntry(entryPtr);
  closeHandle(handle);
  return TCL_OK;
}

#ifdef PREPARED_STATEMENT
/*
 *----------------------------------------------------------------------
 *
 * Obmysqltcl_Prepare --
 *    Implements the obmysql::prepare command:
 *    usage: obmysql::prepare handle statements
 *
 *    results:
 *	    prepared statment handle
 */

static int Obmysqltcl_Prepare(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;

  ObmysqlTclHandle *handle;
  ObmysqlTclHandle *shandle;
  MYSQL_STMT *statement;
  char *query;
  int queryLen;
  int resultColumns;
  int paramCount;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle sql-statement")) == 0)
    return TCL_ERROR;

  statement = mysql_stmt_init(handle->connection);
  if (statement==NULL) {
        return TCL_ERROR;
  }
  query = (char *)Tcl_GetByteArrayFromObj(objv[2], &queryLen);
  if (mysql_stmt_prepare(statement,query,queryLen)) {

        mysql_stmt_close(statement);
    return mysql_server_confl(interp,objc,objv,handle->connection);
  }
  if ((shandle = createHandleFrom(statePtr,handle,HT_STATEMENT)) == NULL) return TCL_ERROR;
  shandle->statement=statement;
  shandle->resultMetadata = mysql_stmt_result_metadata(statement);
  shandle->paramMetadata = mysql_stmt_param_metadata(statement);
  /* set result bind memory */
  resultColumns = mysql_stmt_field_count(statement);
  if (resultColumns>0) {
        shandle->bindResult = (MYSQL_BIND *)Tcl_Alloc(sizeof(MYSQL_BIND)*resultColumns);
    memset(shandle->bindResult,0,sizeof(MYSQL_BIND)*resultColumns);
  }
  paramCount = mysql_stmt_param_count(statement);
  if (resultColumns>0) {
        shandle->bindParam = (MYSQL_BIND *)Tcl_Alloc(sizeof(MYSQL_BIND)*paramCount);
    memset(shandle->bindParam,0,sizeof(MYSQL_BIND)*paramCount);
  }
  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr,shandle));
  return TCL_OK;
}
static int Obmysqltcl_ParamMetaData(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle;
  MYSQL_RES *res;
  MYSQL_ROW row;
  Tcl_Obj *colinfo,*resObj;
  unsigned long *lengths;
  int i;
  int colCount;
  MYSQL_FIELD* fld;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "statement-handle")) == 0)
    return TCL_ERROR;
  if(handle->type!=HT_STATEMENT)
        return TCL_ERROR;

  resObj = Tcl_GetObjResult(interp);
  printf("statement %p count %d\n",handle->statement,mysql_stmt_param_count(handle->statement));
  res = mysql_stmt_result_metadata(handle->statement);
  printf("res %p\n",res);
  if(res==NULL)
        return TCL_ERROR;

  mysql_field_seek(res, 0) ;
  while ((fld = mysql_fetch_field(res)) != NULL) {
        if ((colinfo = mysql_colinfo(interp,objc,objv,fld, objv[2])) != NULL) {
            Tcl_ListObjAppendElement(interp, resObj, colinfo);
        } else {
            goto conflict;
	    }
  }
  conflict:

  mysql_free_result(res);
  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Obmysqltcl_PSelect --
 *    Implements the obmysql::pselect command:
 *    usage: obmysql::pselect $statement_handle ?arguments...?
 *
 *    results:
 *	    number of returned rows
 */

static int Obmysqltcl_PSelect(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle sql-statement")) == 0)
    return TCL_ERROR;
  if (handle->type!=HT_STATEMENT) {
        return TCL_ERROR;
  }
  mysql_stmt_reset(handle->statement);
  if (mysql_stmt_execute(handle->statement)) {
        return mysql_server_confl(interp,objc,objv,handle->connection);
  }
  mysql_stmt_bind_result(handle->statement, handle->bindResult);
  mysql_stmt_store_result(handle->statement);
  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Obmysqltcl_PFetch --
 *    Implements the obmysql::pfetch command:
 *    usage: obmysql::pfetch $statement_handle
 *
 *    results:
 *	    number of returned rows
 */

static int Obmysqltcl_PFetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 2, 2, CL_CONN,
			    "prep-stat-handle")) == 0)
    return TCL_ERROR;
  if (handle->type!=HT_STATEMENT) {
        return TCL_ERROR;
  }

  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Obmysqltcl_PExecute --
 *    Implements the obmysql::pexecute command:
 *    usage: obmysql::pexecute statement-handle ?arguments...?
 *
 *    results:
 *	    number of effected rows
 */

static int Obmysqltcl_PExecute(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  ObmysqltclState *statePtr = (ObmysqltclState *)clientData;
  ObmysqlTclHandle *handle;

  if ((handle = mysql_prologue(interp, objc, objv, 3, 3, CL_CONN,
			    "handle sql-statement")) == 0)
    return TCL_ERROR;
  if (handle->type!=HT_STATEMENT) {
        return TCL_ERROR;
  }
  mysql_stmt_reset(handle->statement);

  if (mysql_stmt_param_count(handle->statement)!=0) {
	  Tcl_SetStringObj(Tcl_GetObjResult(interp),"works only for 0 params",-1);
	  return TCL_ERROR;
  }
  if (mysql_stmt_execute(handle->statement))
  {
	Tcl_SetStringObj(Tcl_GetObjResult(interp),mysql_stmt_error(handle->statement),-1);
        return TCL_ERROR;
  }
  return TCL_OK;
}
#endif

/*
 *----------------------------------------------------------------------
 * Obmysqltcl_Init
 * Perform all initialization for the MYSQL to Tcl interface.
 * Adds additional commands to interp, creates message array, initializes
 * all handles.
 *
 * A call to Obmysqltcl_Init should exist in Tcl_CreateInterp or
 * Tcl_CreateExtendedInterp.

 */


OBMYSQL_EXPORT int Obmysqltcl_Init(interp)
    Tcl_Interp *interp;
{
  char nbuf[MYSQL_SMALL_SIZE];
  ObmysqltclState *statePtr;

  if (Tcl_InitStubs(interp, "8.6-", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgRequire(interp, "Tcl", "8.6-", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgProvide(interp, "obmysqltcl" , PACKAGE_VERSION) != TCL_OK)
    return TCL_ERROR;
  /*

   * Initialize the new Tcl commands.
   * Deleting any command will close all connections.
   */
   statePtr = (ObmysqltclState*)Tcl_Alloc(sizeof(ObmysqltclState));
   Tcl_InitHashTable(&statePtr->hash, TCL_STRING_KEYS);
   statePtr->handleNum = 0;

   Tcl_CreateObjCommand(interp,"obmysqlconnect",Obmysqltcl_Connect,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqluse", Obmysqltcl_Use,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlescape", Obmysqltcl_Escape,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlsel", Obmysqltcl_Sel,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlnext", Obmysqltcl_Fetch,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlseek", Obmysqltcl_Seek,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlmap", Obmysqltcl_Map,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlexec", Obmysqltcl_Exec,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlclose", Obmysqltcl_Close,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlinfo", Obmysqltcl_Info,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlresult", Obmysqltcl_Result,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlcol", Obmysqltcl_Col,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlstate", Obmysqltcl_State,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlinsertid", Obmysqltcl_InsertId,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlquery", Obmysqltcl_Query,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlendquery", Obmysqltcl_EndQuery,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlbaseinfo", Obmysqltcl_BaseInfo,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlping", Obmysqltcl_Ping,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlchangeuser", Obmysqltcl_ChangeUser,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"obmysqlreceive", Obmysqltcl_Receive,(ClientData)statePtr, NULL);

   Tcl_CreateObjCommand(interp,"::obmysql::connect",Obmysqltcl_Connect,(ClientData)statePtr, Obmysqltcl_Kill);
   Tcl_CreateObjCommand(interp,"::obmysql::use", Obmysqltcl_Use,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::escape", Obmysqltcl_Escape,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::sel", Obmysqltcl_Sel,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::fetch", Obmysqltcl_Fetch,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::seek", Obmysqltcl_Seek,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::map", Obmysqltcl_Map,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::exec", Obmysqltcl_Exec,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::close", Obmysqltcl_Close,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::info", Obmysqltcl_Info,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::result", Obmysqltcl_Result,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::col", Obmysqltcl_Col,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::state", Obmysqltcl_State,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::insertid", Obmysqltcl_InsertId,(ClientData)statePtr, NULL);
   /* new in obmysqltcl 2.0 */
   Tcl_CreateObjCommand(interp,"::obmysql::query", Obmysqltcl_Query,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::endquery", Obmysqltcl_EndQuery,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::baseinfo", Obmysqltcl_BaseInfo,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::ping", Obmysqltcl_Ping,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::changeuser", Obmysqltcl_ChangeUser,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::receive", Obmysqltcl_Receive,(ClientData)statePtr, NULL);
   /* new in obmysqltcl 3.0 */
   Tcl_CreateObjCommand(interp,"::obmysql::autocommit", Obmysqltcl_AutoCommit,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::commit", Obmysqltcl_Commit,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::rollback", Obmysqltcl_Rollback,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::nextresult", Obmysqltcl_NextResult,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::moreresult", Obmysqltcl_MoreResult,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::warningcount", Obmysqltcl_WarningCount,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::isnull", Obmysqltcl_IsNull,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::newnull", Obmysqltcl_NewNull,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::setserveroption", Obmysqltcl_SetServerOption,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::shutdown", Obmysqltcl_ShutDown,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::encoding", Obmysqltcl_Encoding,(ClientData)statePtr, NULL);
   /* prepared statements */

#ifdef PREPARED_STATEMENT
   Tcl_CreateObjCommand(interp,"::obmysql::prepare", Obmysqltcl_Prepare,(ClientData)statePtr, NULL);
   // Tcl_CreateObjCommand(interp,"::obmysql::parammetadata", Obmysqltcl_ParamMetaData,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::pselect", Obmysqltcl_PSelect,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::pselect", Obmysqltcl_PFetch,(ClientData)statePtr, NULL);
   Tcl_CreateObjCommand(interp,"::obmysql::pexecute", Obmysqltcl_PExecute,(ClientData)statePtr, NULL);
#endif



   /* Initialize mysqlstatus global array. */

   clear_msg(interp);

   /* Link the null value element to the corresponding C variable. */
   if ((statePtr->ObmysqlNullvalue = Tcl_Alloc (12)) == NULL) return TCL_ERROR;
   strcpy (statePtr->ObmysqlNullvalue, MYSQL_NULLV_INIT);
   sprintf (nbuf, "%s(%s)", MYSQL_STATUS_ARR, MYSQL_STATUS_NULLV);

   /* set null object in obmysqltcl state */
   /* statePtr->nullObjPtr = Obmysqltcl_NewNullObj(statePtr); */

   if (Tcl_LinkVar(interp,nbuf,(char *)&statePtr->ObmysqlNullvalue, TCL_LINK_STRING) != TCL_OK)
     return TCL_ERROR;

   /* Register the handle object type */
   Tcl_RegisterObjType(&obmysqlHandleType);
   /* Register own null type object */
   Tcl_RegisterObjType(&obmysqlNullType);

   /* A little sanity check.
    * If this message appears you must change the source code and recompile.
   */
   if (strlen(ObmysqlHandlePrefix) == MYSQL_HPREFIX_LEN)
     return TCL_OK;
   else {
     Tcl_Panic("*** obmysqltcl (obmysqltcl.c): handle prefix inconsistency!\n");
     return TCL_ERROR ;
   }
}

OBMYSQL_EXPORT int Obmysqltcl_SafeInit(interp)
    Tcl_Interp *interp;
{
  return Obmysqltcl_Init(interp);
}
