/*
 * $Eid: mariatcl.c,v 0.1 2021/03/15 18:52:08 artur Exp $
 *
 * MariaDB interface to Tcl
 *
 * Hakan Soderstrom, hs@soderstrom.se
 * Jiang Hua, ricky_jiang_h@hotmail.com
 *
 */

/*
 * Copyright (c) 1994, 1995 Hakan Soderstrom and Tom Poindexter
 *               2021 Jiang Hua
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
 Modified after version 2.0 from http://www.xdobry.de/mariatcl
*/

#ifdef _WINDOWS
#include <windows.h>
#define PACKAGE "mariatcl"
#define PACKAGE_VERSION "0.1"
#endif

#include <tcl.h>
#include <mysql.h>

#include <errno.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#define MARIA_SMALL_SIZE TCL_RESULT_SIZE /* Smaller buffer size. */
#define MARIA_NAME_LEN 80                /* Max. database name length. */
/* #define PREPARED_STATEMENT */

enum MariaHandleType
{
  HT_CONNECTION = 1,
  HT_QUERY = 2,
  HT_STATEMENT = 3
};

typedef struct MariaTclHandle
{
  MYSQL *connection;             /* Connection handle, if connected; NULL otherwise. */
  char database[MARIA_NAME_LEN]; /* Db name, if selected; NULL otherwise. */
  MYSQL_RES *result;             /* Stored result, if any; NULL otherwise. */
  int res_count;                 /* Count of unfetched rows in result. */
  int col_count;                 /* Column count in result, if any. */
  int number;                    /* handle id */
  enum MariaHandleType type;     /* handle type */
  Tcl_Encoding encoding;         /* encoding for connection */
#ifdef PREPARED_STATEMENT
  MARIA_STMT *statement; /* used only by prepared statements*/
  MARIA_BIND *bindParam;
  MARIA_BIND *bindResult;
  MYSQL_RES *resultMetadata;
  MYSQL_RES *paramMetadata;
#endif
} MariaTclHandle;

typedef struct MariatclState
{
  Tcl_HashTable hash;
  int handleNum;
  char *MariaNullvalue;
  // Tcl_Obj *nullObjPtr;
} MariatclState;

static char *MariaHandlePrefix = "maria";
/* Prefix string used to identify handles.
 * The following must be strlen(MariaHandlePrefix).
 */
#define MARIA_HPREFIX_LEN 5

/* Array for status info, and its elements. */
#define MARIA_STATUS_ARR "mariastatus"

#define MARIA_STATUS_CODE "code"
#define MARIA_STATUS_CMD "command"
#define MARIA_STATUS_MSG "message"
#define MARIA_STATUS_NULLV "nullvalue"

#define FUNCTION_NOT_AVAILABLE "function not available"

/* C variable corresponding to mariastatus(nullvalue) */
#define MARIA_NULLV_INIT ""

/* Check Level for maria_prologue */
enum CONNLEVEL
{
  CL_PLAIN,
  CL_CONN,
  CL_DB,
  CL_RES
};

/* Prototypes for all functions. */

static int Mariatcl_Use(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Escape(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Sel(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Fetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Seek(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Map(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Exec(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Close(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Info(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Result(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Col(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_State(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_InsertId(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Query(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int Mariatcl_Receive(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[]);
static int MariaHandleSet _ANSI_ARGS_((Tcl_Interp * interp, Tcl_Obj *objPtr));
static void MariaHandleFree _ANSI_ARGS_((Tcl_Obj * objPtr));
static int MariaNullSet _ANSI_ARGS_((Tcl_Interp * interp, Tcl_Obj *objPtr));
static Tcl_Obj *Mariatcl_NewNullObj(MariatclState *mariatclState);
static void UpdateStringOfNull _ANSI_ARGS_((Tcl_Obj * objPtr));

/* handle object type 
 * This section defince funtions for Handling new Tcl_Obj type */

Tcl_ObjType mariaHandleType = {
    "mariahandle",
    MariaHandleFree,
    (Tcl_DupInternalRepProc *)NULL,
    NULL,
    MariaHandleSet};
Tcl_ObjType mariaNullType = {
    "marianull",
    (Tcl_FreeInternalRepProc *)NULL,
    (Tcl_DupInternalRepProc *)NULL,
    UpdateStringOfNull,
    MariaNullSet};

static MariatclState *getMariatclState(Tcl_Interp *interp)
{
  Tcl_CmdInfo cmdInfo;
  if (Tcl_GetCommandInfo(interp, "mariaconnect", &cmdInfo) == 0)
  {
    return NULL;
  }
  return (MariatclState *)cmdInfo.objClientData;
}

static int MariaHandleSet(Tcl_Interp *interp, register Tcl_Obj *objPtr)
{
  Tcl_ObjType *oldTypePtr = objPtr->typePtr;
  char *string;
  MariaTclHandle *handle;
  Tcl_HashEntry *entryPtr;
  MariatclState *statePtr;

  string = Tcl_GetStringFromObj(objPtr, NULL);
  statePtr = getMariatclState(interp);
  if (statePtr == NULL)
    return TCL_ERROR;

  entryPtr = Tcl_FindHashEntry(&statePtr->hash, string);
  if (entryPtr == NULL)
  {

    handle = 0;
  }
  else
  {
    handle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);
  }
  if (!handle)
  {
    if (interp != NULL)
      return TCL_ERROR;
  }
  if ((oldTypePtr != NULL) && (oldTypePtr->freeIntRepProc != NULL))
  {
    oldTypePtr->freeIntRepProc(objPtr);
  }

  objPtr->internalRep.otherValuePtr = (MariaTclHandle *)handle;
  objPtr->typePtr = &mariaHandleType;
  Tcl_Preserve((char *)handle);
  return TCL_OK;
}
static int MariaNullSet(Tcl_Interp *interp, Tcl_Obj *objPtr)
{
  Tcl_ObjType *oldTypePtr = objPtr->typePtr;

  if ((oldTypePtr != NULL) && (oldTypePtr->freeIntRepProc != NULL))
  {
    oldTypePtr->freeIntRepProc(objPtr);
  }
  objPtr->typePtr = &mariaNullType;
  return TCL_OK;
}
static void UpdateStringOfNull(Tcl_Obj *objPtr)
{
  int valueLen;
  MariatclState *state = (MariatclState *)objPtr->internalRep.otherValuePtr;

  valueLen = strlen(state->MariaNullvalue);
  objPtr->bytes = Tcl_Alloc(valueLen + 1);
  strcpy(objPtr->bytes, state->MariaNullvalue);
  objPtr->length = valueLen;
}
static void MariaHandleFree(Tcl_Obj *obj)
{
  MariaTclHandle *handle = (MariaTclHandle *)obj->internalRep.otherValuePtr;
  Tcl_Release((char *)handle);
}

static int GetHandleFromObj(Tcl_Interp *interp, Tcl_Obj *objPtr, MariaTclHandle **handlePtr)
{
  if (Tcl_ConvertToType(interp, objPtr, &mariaHandleType) != TCL_OK)
    return TCL_ERROR;
  *handlePtr = (MariaTclHandle *)objPtr->internalRep.otherValuePtr;
  return TCL_OK;
}

static Tcl_Obj *Tcl_NewHandleObj(MariatclState *statePtr, MariaTclHandle *handle)
{
  register Tcl_Obj *objPtr;
  char buffer[MARIA_HPREFIX_LEN + TCL_DOUBLE_SPACE + 1];
  register int len;
  Tcl_HashEntry *entryPtr;
  int newflag;

  objPtr = Tcl_NewObj();
  /* the string for "query" can not be longer as MariaHandlePrefix see buf variable */
  len = sprintf(buffer, "%s%d", (handle->type == HT_QUERY) ? "query" : MariaHandlePrefix, handle->number);
  objPtr->bytes = Tcl_Alloc((unsigned)len + 1);
  strcpy(objPtr->bytes, buffer);
  objPtr->length = len;

  entryPtr = Tcl_CreateHashEntry(&statePtr->hash, buffer, &newflag);
  Tcl_SetHashValue(entryPtr, handle);

  objPtr->internalRep.otherValuePtr = handle;
  objPtr->typePtr = &mariaHandleType;

  Tcl_Preserve((char *)handle);

  return objPtr;
}

/* CONFLICT HANDLING
 *
 * Every command begins by calling 'maria_prologue'.
 * This function resets mariastatus(code) to zero; the other array elements
 * retain their previous values.
 * The function also saves objc/objv in global variables.
 * After this the command processing proper begins.
 *
 * If there is a conflict, the message is taken from one of the following
 * sources,
 * -- this code (maria_prim_confl),
 * -- the database server (maria_server_confl),
 * A complete message is put together from the above plus the name of the
 * command where the conflict was detected.
 * The complete message is returned as the Tcl result and is also stored in
 * mariastatus(message).
 * mariastatus(code) is set to "-1" for a primitive conflict or to mysql_errno
 * for a server conflict
 * In addition, the whole command where the conflict was detected is put
 * together from the saved objc/objv and is copied into mariastatus(command).
 */

/*
 *-----------------------------------------------------------
 * set_statusArr
 * Help procedure to set Tcl global array with mariatcl internal
 * informations
 */

static void set_statusArr(Tcl_Interp *interp, char *elem_name, Tcl_Obj *tobj)
{
  Tcl_SetVar2Ex(interp, MARIA_STATUS_ARR, elem_name, tobj, TCL_GLOBAL_ONLY);
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
  set_statusArr(interp, MARIA_STATUS_CODE, Tcl_NewIntObj(0));
  set_statusArr(interp, MARIA_STATUS_CMD, Tcl_NewObj());
  set_statusArr(interp, MARIA_STATUS_MSG, Tcl_NewObj());
}

/*
 *----------------------------------------------------------------------
 * maria_reassemble
 * Reassembles the current command from the saved objv; copies it into
 * mariastatus(command).
 */

static void maria_reassemble(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  set_statusArr(interp, MARIA_STATUS_CMD, Tcl_NewListObj(objc, objv));
}

/*
 * free result from handle and consume left result of multresult statement 
 */
static void freeResult(MariaTclHandle *handle)
{
  MYSQL_RES *result;
  if (handle->result != NULL)
  {
    mysql_free_result(handle->result);
    handle->result = NULL;
  }
#if (MYSQL_VERSION_ID >= 50000)
  while (!mysql_next_result(handle->connection))
  {
    result = mysql_store_result(handle->connection);
    if (result)
    {
      mysql_free_result(result);
    }
  }
#endif
}

/*
 *----------------------------------------------------------------------
 * maria_prim_confl
 * Conflict handling after a primitive conflict.
 *
 */

static int maria_prim_confl(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], char *msg)
{
  set_statusArr(interp, MARIA_STATUS_CODE, Tcl_NewIntObj(-1));

  Tcl_ResetResult(interp);
  Tcl_AppendStringsToObj(Tcl_GetObjResult(interp),
                         Tcl_GetString(objv[0]), ": ", msg, (char *)NULL);

  set_statusArr(interp, MARIA_STATUS_MSG, Tcl_GetObjResult(interp));

  maria_reassemble(interp, objc, objv);
  return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 * maria_server_confl
 * Conflict handling after an mySQL conflict.
 * If error it set error message and return TCL_ERROR
 * If no error occurs it returns TCL_OK
 */

static int maria_server_confl(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], MYSQL *connection)
{
  const char *mysql_errorMsg;
  if (mysql_errno(connection))
  {
    mysql_errorMsg = mysql_error(connection);

    set_statusArr(interp, MARIA_STATUS_CODE, Tcl_NewIntObj(mysql_errno(connection)));

    Tcl_ResetResult(interp);
    Tcl_AppendStringsToObj(Tcl_GetObjResult(interp),
                           Tcl_GetString(objv[0]), "/db server: ",
                           (mysql_errorMsg == NULL) ? "" : mysql_errorMsg,
                           (char *)NULL);

    set_statusArr(interp, MARIA_STATUS_MSG, Tcl_GetObjResult(interp));

    maria_reassemble(interp, objc, objv);
    return TCL_ERROR;
  }
  else
  {
    return TCL_OK;
  }
}

static MariaTclHandle *get_handle(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], int check_level)
{
  MariaTclHandle *handle;
  if (GetHandleFromObj(interp, objv[1], &handle) != TCL_OK)
  {
    maria_prim_confl(interp, objc, objv, "not mariatcl handle");
    return NULL;
  }
  if (check_level == CL_PLAIN)
    return handle;
  if (handle->connection == 0)
  {
    maria_prim_confl(interp, objc, objv, "handle already closed (dangling pointer)");
    return NULL;
  }
  if (check_level == CL_CONN)
    return handle;
  if (check_level != CL_RES)
  {
    if (handle->database[0] == '\0')
    {
      maria_prim_confl(interp, objc, objv, "no current database");
      return NULL;
    }
    if (check_level == CL_DB)
      return handle;
  }
  if (handle->result == NULL)
  {
    maria_prim_confl(interp, objc, objv, "no result pending");
    return NULL;
  }
  return handle;
}

/*----------------------------------------------------------------------

 * maria_QueryTclObj
 * This to method control how tcl data is transfered to maria and
 * how data is imported into tcl from maria
 * Return value : Zero on success, Non-zero if an error occurred.
 */
static int maria_QueryTclObj(MariaTclHandle *handle, Tcl_Obj *obj)
{
  char *query;
  int result, queryLen;

  Tcl_DString queryDS;

  query = Tcl_GetStringFromObj(obj, &queryLen);

  if (handle->encoding == NULL)
  {
    query = (char *)Tcl_GetByteArrayFromObj(obj, &queryLen);
    result = mysql_real_query(handle->connection, query, queryLen);
  }
  else
  {
    Tcl_UtfToExternalDString(handle->encoding, query, -1, &queryDS);
    queryLen = Tcl_DStringLength(&queryDS);
    result = mysql_real_query(handle->connection, Tcl_DStringValue(&queryDS), queryLen);
    Tcl_DStringFree(&queryDS);
  }
  return result;
}
static Tcl_Obj *getRowCellAsObject(MariatclState *mariatclState, MariaTclHandle *handle, MYSQL_ROW row, int length)
{
  Tcl_Obj *obj;
  Tcl_DString ds;

  if (*row)
  {
    if (handle->encoding != NULL)
    {
      Tcl_ExternalToUtfDString(handle->encoding, *row, length, &ds);
      obj = Tcl_NewStringObj(Tcl_DStringValue(&ds), Tcl_DStringLength(&ds));
      Tcl_DStringFree(&ds);
    }
    else
    {
      obj = Tcl_NewByteArrayObj((unsigned char *)*row, length);
    }
  }
  else
  {
    obj = Mariatcl_NewNullObj(mariatclState);
  }
  return obj;
}

static MariaTclHandle *createMariaHandle(MariatclState *statePtr)
{
  MariaTclHandle *handle;
  handle = (MariaTclHandle *)Tcl_Alloc(sizeof(MariaTclHandle));
  memset(handle, 0, sizeof(MariaTclHandle));
  if (handle == 0)
  {
    panic("no memory for handle");
    return handle;
  }
  handle->type = HT_CONNECTION;

  /* MT-safe, because every thread in tcl has own interpreter */
  handle->number = statePtr->handleNum++;
  return handle;
}

static MariaTclHandle *createHandleFrom(MariatclState *statePtr, MariaTclHandle *handle, enum MariaHandleType handleType)
{
  int number;
  MariaTclHandle *qhandle;
  qhandle = createMariaHandle(statePtr);
  /* do not overwrite the number */
  number = qhandle->number;
  if (!qhandle)
    return qhandle;
  memcpy(qhandle, handle, sizeof(MariaTclHandle));
  qhandle->type = handleType;
  qhandle->number = number;
  return qhandle;
}
static void closeHandle(MariaTclHandle *handle)
{
  freeResult(handle);
  if (handle->type == HT_CONNECTION)
  {
    mysql_close(handle->connection);
  }
#ifdef PREPARED_STATEMENT
  if (handle->type == HT_STATEMENT)
  {
    if (handle->statement != NULL)
      mysql_stmt_close(handle->statement);
    if (handle->bindResult != NULL)
      Tcl_Free((char *)handle->bindResult);
    if (handle->bindParam != NULL)
      Tcl_Free((char *)handle->bindParam);
    if (handle->resultMetadata != NULL)
      mysql_free_result(handle->resultMetadata);
    if (handle->paramMetadata != NULL)
      mysql_free_result(handle->paramMetadata);
  }
#endif
  handle->connection = (MYSQL *)NULL;
  if (handle->encoding != NULL && handle->type == HT_CONNECTION)
  {
    Tcl_FreeEncoding(handle->encoding);
    handle->encoding = NULL;
  }
  Tcl_EventuallyFree((char *)handle, TCL_DYNAMIC);
}

/*
 *----------------------------------------------------------------------
 * maria_prologue
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

static MariaTclHandle *maria_prologue(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], int req_min_args, int req_max_args, int check_level, char *usage_msg)
{
  /* Check number of args. */
  if (objc < req_min_args || objc > req_max_args)
  {
    Tcl_WrongNumArgs(interp, 1, objv, usage_msg);
    return NULL;
  }

  /* Reset mariastatus(code). */
  set_statusArr(interp, MARIA_STATUS_CODE, Tcl_NewIntObj(0));

  /* Check the handle.
   * The function is assumed to set the status array on conflict.
   */
  return (get_handle(interp, objc, objv, check_level));
}

/*
 *----------------------------------------------------------------------
 * maria_colinfo
 *
 * Given an MYSQL_FIELD struct and a string keyword appends a piece of
 * column info (one item) to the Tcl result.
 * ASSUMES 'fld' is non-null.
 * RETURNS 0 on success, 1 otherwise.
 * SIDE EFFECT: Sets the result and status on failure.
 */

static Tcl_Obj *maria_colinfo(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], MYSQL_FIELD *fld, Tcl_Obj *keyw)
{
  int idx;

  static CONST char *MariaColkey[] =
      {
          "table", "name", "type", "length", "prim_key", "non_null", "numeric", "decimals", NULL};
  enum coloptions
  {
    MARIA_COL_TABLE_K,
    MARIA_COL_NAME_K,
    MARIA_COL_TYPE_K,
    MARIA_COL_LENGTH_K,
    MARIA_COL_PRIMKEY_K,
    MARIA_COL_NONNULL_K,
    MARIA_COL_NUMERIC_K,
    MARIA_COL_DECIMALS_K
  };

  if (Tcl_GetIndexFromObj(interp, keyw, MariaColkey, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return NULL;

  switch (idx)
  {
  case MARIA_COL_TABLE_K:
    return Tcl_NewStringObj(fld->table, -1);
  case MARIA_COL_NAME_K:
    return Tcl_NewStringObj(fld->name, -1);
  case MARIA_COL_TYPE_K:
    switch (fld->type)
    {

    case FIELD_TYPE_DECIMAL:
      return Tcl_NewStringObj("decimal", -1);
    case FIELD_TYPE_TINY:
      return Tcl_NewStringObj("tiny", -1);
    case FIELD_TYPE_SHORT:
      return Tcl_NewStringObj("short", -1);
    case FIELD_TYPE_LONG:
      return Tcl_NewStringObj("long", -1);
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
    break;
  case MARIA_COL_LENGTH_K:
    return Tcl_NewIntObj(fld->length);
  case MARIA_COL_PRIMKEY_K:
    return Tcl_NewBooleanObj(IS_PRI_KEY(fld->flags));
  case MARIA_COL_NONNULL_K:
    return Tcl_NewBooleanObj(IS_NOT_NULL(fld->flags));
  case MARIA_COL_NUMERIC_K:
    return Tcl_NewBooleanObj(IS_NUM(fld->type));
  case MARIA_COL_DECIMALS_K:
    return IS_NUM(fld->type) ? Tcl_NewIntObj(fld->decimals) : Tcl_NewIntObj(-1);
  default: /* should never happen */
    maria_prim_confl(interp, objc, objv, "weirdness in maria_colinfo");
    return NULL;
  }
}

/*
 * Mariatcl_CloseAll
 * Close all connections.
 */

static void Mariatcl_CloseAll(ClientData clientData)
{
  MariatclState *statePtr = (MariatclState *)clientData;
  Tcl_HashSearch search;
  MariaTclHandle *handle;
  Tcl_HashEntry *entryPtr;
  int wasdeleted = 0;

  for (entryPtr = Tcl_FirstHashEntry(&statePtr->hash, &search);
       entryPtr != NULL;
       entryPtr = Tcl_NextHashEntry(&search))
  {
    wasdeleted = 1;
    handle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);

    if (handle->connection == 0)
      continue;
    closeHandle(handle);
  }
  if (wasdeleted)
  {
    Tcl_DeleteHashTable(&statePtr->hash);
    Tcl_InitHashTable(&statePtr->hash, TCL_STRING_KEYS);
  }
}
/*
 * Invoked from Interpreter by removing mariatcl command

 * Warnign: This procedure can be called only once
 */
static void Mariatcl_Kill(ClientData clientData)
{
  MariatclState *statePtr = (MariatclState *)clientData;
  Tcl_HashEntry *entryPtr;
  MariaTclHandle *handle;
  Tcl_HashSearch search;

  for (entryPtr = Tcl_FirstHashEntry(&statePtr->hash, &search);
       entryPtr != NULL;
       entryPtr = Tcl_NextHashEntry(&search))
  {
    handle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);
    if (handle->connection == 0)
      continue;
    closeHandle(handle);
  }
  Tcl_Free(statePtr->MariaNullvalue);
  Tcl_Free((char *)statePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Connect
 * Implements the mariaconnect command:
 * usage: mariaconnect ?option value ...?
 *	                
 * Results:
 *      handle - a character string of newly open handle
 *      TCL_OK - connect successful
 *      TCL_ERROR - connect not successful - error message returned
 */

static CONST char *MariaConnectOpt[] =
    {
        "-host", "-user", "-password", "-db", "-port", "-socket", "-encoding",
        "-ssl", "-compress", "-noschema", "-odbc",
#if (MYSQL_VERSION_ID >= 40107)
        "-multistatement", "-multiresult",
#endif
        "-localfiles", "-ignorespace", "-foundrows", "-interactive", "-sslkey", "-sslcert",
        "-sslca", "-sslcapath", "-sslciphers", "-reconnect", NULL};

static int Mariatcl_Connect(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  int i, idx;
  int mysql_options_reconnect = 0;
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

  MariaTclHandle *handle;
  const char *groupname = "mariatcl";

  enum connectoption
  {
    MARIA_CONNHOST_OPT,
    MARIA_CONNUSER_OPT,
    MARIA_CONNPASSWORD_OPT,
    MARIA_CONNDB_OPT,
    MARIA_CONNPORT_OPT,
    MARIA_CONNSOCKET_OPT,
    MARIA_CONNENCODING_OPT,
    MARIA_CONNSSL_OPT,
    MARIA_CONNCOMPRESS_OPT,
    MARIA_CONNNOSCHEMA_OPT,
    MARIA_CONNODBC_OPT,
#if (MYSQL_VERSION_ID >= 40107)
    MARIA_MULTISTATEMENT_OPT,
    MARIA_MULTIRESULT_OPT,
#endif
    MARIA_LOCALFILES_OPT,
    MARIA_IGNORESPACE_OPT,
    MARIA_FOUNDROWS_OPT,
    MARIA_INTERACTIVE_OPT,
    MARIA_SSLKEY_OPT,
    MARIA_SSLCERT_OPT,
    MARIA_SSLCA_OPT,
    MARIA_SSLCAPATH_OPT,
    MARIA_SSLCIPHERS_OPT,
    MARIA_RECONNECT_OPT
  };

  if (!(objc & 1) ||
      objc > (sizeof(MariaConnectOpt) / sizeof(MariaConnectOpt[0] - 1) * 2 + 1))
  {
    Tcl_WrongNumArgs(interp, 1, objv, "[-user xxx] [-db maria] [-port 3306] [-host localhost] [-socket sock] [-password pass] [-encoding encoding] [-ssl boolean] [-compress boolean] [-odbc boolean] [-noschema boolean] [-reconnect boolean]");
    return TCL_ERROR;
  }

  for (i = 1; i < objc; i++)
  {
    if (Tcl_GetIndexFromObj(interp, objv[i], MariaConnectOpt, "option",
                            0, &idx) != TCL_OK)
      return TCL_ERROR;

    switch (idx)
    {
    case MARIA_CONNHOST_OPT:
      hostname = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNUSER_OPT:
      user = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNPASSWORD_OPT:
      password = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNDB_OPT:
      db = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNPORT_OPT:
      if (Tcl_GetIntFromObj(interp, objv[++i], &port) != TCL_OK)
        return TCL_ERROR;
      break;
    case MARIA_CONNSOCKET_OPT:
      socket = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNENCODING_OPT:
      encodingname = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_CONNSSL_OPT:
#if (MYSQL_VERSION_ID >= 40107)
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &isSSL) != TCL_OK)
        return TCL_ERROR;
#else
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_SSL;
#endif
      break;
    case MARIA_CONNCOMPRESS_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_COMPRESS;
      break;
    case MARIA_CONNNOSCHEMA_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_NO_SCHEMA;
      break;
    case MARIA_CONNODBC_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_ODBC;
      break;
#if (MYSQL_VERSION_ID >= 40107)
    case MARIA_MULTISTATEMENT_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_MULTI_STATEMENTS;
      break;
    case MARIA_MULTIRESULT_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_MULTI_RESULTS;
      break;
#endif
    case MARIA_LOCALFILES_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_LOCAL_FILES;
      break;
    case MARIA_IGNORESPACE_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_IGNORE_SPACE;
      break;
    case MARIA_FOUNDROWS_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_FOUND_ROWS;
      break;
    case MARIA_INTERACTIVE_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        flags |= CLIENT_INTERACTIVE;
      break;
    case MARIA_SSLKEY_OPT:
      sslkey = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_SSLCERT_OPT:
      sslcert = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_SSLCA_OPT:
      sslca = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_SSLCAPATH_OPT:
      sslcapath = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_SSLCIPHERS_OPT:
      sslcipher = Tcl_GetStringFromObj(objv[++i], NULL);
      break;
    case MARIA_RECONNECT_OPT:
      if (Tcl_GetBooleanFromObj(interp, objv[++i], &booleanflag) != TCL_OK)
        return TCL_ERROR;
      if (booleanflag)
        mysql_options_reconnect = 1;
      break;
    default:
      return maria_prim_confl(interp, objc, objv, "Weirdness in options");
    }
  }

  handle = createMariaHandle(statePtr);

  if (handle == 0)
  {
    panic("no memory for handle");
    return TCL_ERROR;
  }

  handle->connection = mysql_init(NULL);

  /* the function below caused in version pre 3.23.50 segmentation fault */
#if (MYSQL_VERSION_ID >= 32350)
  if (mysql_options_reconnect)
  {
    _Bool reconnect = 1;
    mysql_options(handle->connection, MYSQL_OPT_RECONNECT, &reconnect);
  }
  mysql_options(handle->connection, MYSQL_READ_DEFAULT_GROUP, groupname);
#endif
#if (MYSQL_VERSION_ID >= 40107)
  if (isSSL)
  {
    mysql_ssl_set(handle->connection, sslkey, sslcert, sslca, sslcapath, sslcipher);
  }
#endif

  if (!mysql_real_connect(handle->connection, hostname, user,
                          password, db, port, socket, flags))
  {
    maria_server_confl(interp, objc, objv, handle->connection);
    closeHandle(handle);
    return TCL_ERROR;
  }

  if (db)
  {
    strncpy(handle->database, db, MARIA_NAME_LEN);
    handle->database[MARIA_NAME_LEN - 1] = '\0';
  }

  if (encodingname == NULL || (encodingname != NULL && strcmp(encodingname, "binary") != 0))
  {
    if (encodingname == NULL)
      encodingname = (char *)Tcl_GetEncodingName(NULL);
    handle->encoding = Tcl_GetEncoding(interp, encodingname);
    if (handle->encoding == NULL)
      return TCL_ERROR;
  }

  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr, handle));

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Use
 *    Implements the mariause command:

 *    usage: mariause handle dbname
 *	                
 *    results:
 *	Sets current database to dbname.
 */

static int Mariatcl_Use(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int len;
  char *db;
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle dbname")) == 0)
    return TCL_ERROR;

  db = Tcl_GetStringFromObj(objv[2], &len);
  if (len >= MARIA_NAME_LEN)
  {
    maria_prim_confl(interp, objc, objv, "database name too long");
    return TCL_ERROR;
  }

  if (mysql_select_db(handle->connection, db) != 0)
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  strcpy(handle->database, db);
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Escape
 *    Implements the mariaescape command:
 *    usage: mariaescape string
 *	                
 *    results:
 *	Escaped string for use in queries.
 */

static int Mariatcl_Escape(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int len;
  char *inString, *outString;
  MariaTclHandle *handle;

  if (objc < 2 || objc > 3)
  {
    Tcl_WrongNumArgs(interp, 1, objv, "?handle? string");
    return TCL_ERROR;
  }
  if (objc == 2)
  {
    inString = Tcl_GetStringFromObj(objv[1], &len);
    outString = Tcl_Alloc((len << 1) + 1);
    len = mysql_escape_string(outString, inString, len);
    Tcl_SetStringObj(Tcl_GetObjResult(interp), outString, len);
    Tcl_Free(outString);
  }
  else
  {
    if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                                 "handle string")) == 0)
      return TCL_ERROR;
    inString = Tcl_GetStringFromObj(objv[2], &len);
    outString = Tcl_Alloc((len << 1) + 1);
    len = mysql_real_escape_string(handle->connection, outString, inString, len);
    Tcl_SetStringObj(Tcl_GetObjResult(interp), outString, len);
    Tcl_Free(outString);
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Sel
 *    Implements the mariasel command:
 *    usage: mariasel handle sel-query ?-list|-flatlist?
 *	                
 *    results:
 *
 *    SIDE EFFECT: Flushes any pending result, even in case of conflict.
 *    Stores new results.
 */

static int Mariatcl_Sel(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  Tcl_Obj *res, *resList;
  MYSQL_ROW row;
  MariaTclHandle *handle;
  unsigned long *lengths;

  static CONST char *selOptions[] = {"-list", "-flatlist", NULL};
  /* Warning !! no option number */
  int i, selOption = 2, colCount;

  if ((handle = maria_prologue(interp, objc, objv, 3, 4, CL_CONN,
                               "handle sel-query ?-list|-flatlist?")) == 0)
    return TCL_ERROR;

  if (objc == 4)
  {
    if (Tcl_GetIndexFromObj(interp, objv[3], selOptions, "option",
                            TCL_EXACT, &selOption) != TCL_OK)
      return TCL_ERROR;
  }

  /* Flush any previous result. */
  freeResult(handle);

  if (maria_QueryTclObj(handle, objv[2]))
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  if (selOption < 2)
  {
    /* If imadiatly result than do not store result in maria client library cache */
    handle->result = mysql_use_result(handle->connection);
  }
  else
  {
    handle->result = mysql_store_result(handle->connection);
  }

  if (handle->result == NULL)
  {
    if (selOption == 2)
      Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
  }
  else
  {
    colCount = handle->col_count = mysql_num_fields(handle->result);
    res = Tcl_GetObjResult(interp);
    handle->res_count = 0;
    switch (selOption)
    {
    case 0: /* -list */
      while ((row = mysql_fetch_row(handle->result)) != NULL)
      {
        resList = Tcl_NewListObj(0, NULL);
        lengths = mysql_fetch_lengths(handle->result);
        for (i = 0; i < colCount; i++, row++)
        {
          Tcl_ListObjAppendElement(interp, resList, getRowCellAsObject(statePtr, handle, row, lengths[i]));
        }
        Tcl_ListObjAppendElement(interp, res, resList);
      }
      break;
    case 1: /* -flatlist */
      while ((row = mysql_fetch_row(handle->result)) != NULL)
      {
        lengths = mysql_fetch_lengths(handle->result);
        for (i = 0; i < colCount; i++, row++)
        {
          Tcl_ListObjAppendElement(interp, res, getRowCellAsObject(statePtr, handle, row, lengths[i]));
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
 * Mariatcl_Query
 * Works as mariatclsel but return an $query handle that allow to build
 * nested queries on simple handle
 */

static int Mariatcl_Query(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MYSQL_RES *result;
  MariaTclHandle *handle, *qhandle;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,

                               "handle sqlstatement")) == 0)
    return TCL_ERROR;

  if (maria_QueryTclObj(handle, objv[2]))
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }

  if ((result = mysql_store_result(handle->connection)) == NULL)
  {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
    return TCL_OK;
  }
  if ((qhandle = createHandleFrom(statePtr, handle, HT_QUERY)) == NULL)
    return TCL_ERROR;
  qhandle->result = result;
  qhandle->col_count = mysql_num_fields(qhandle->result);

  qhandle->res_count = mysql_num_rows(qhandle->result);
  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr, qhandle));
  return TCL_OK;
}

/*
 * Mariatcl_Enquery
 * close and free a query handle
 * if handle is not query than the result will be discarted
 */

static int Mariatcl_EndQuery(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  Tcl_HashEntry *entryPtr;
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "queryhandle")) == 0)
    return TCL_ERROR;

  if (handle->type == HT_QUERY)
  {
    entryPtr = Tcl_FindHashEntry(&statePtr->hash, Tcl_GetStringFromObj(objv[1], NULL));
    if (entryPtr)
    {
      Tcl_DeleteHashEntry(entryPtr);
    }
    closeHandle(handle);
  }
  else
  {
    freeResult(handle);
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Exec
 * Implements the mariaexec command:
 * usage: mariaexec handle sql-statement
 *	                
 * Results:
 * Number of affected rows on INSERT, UPDATE or DELETE, 0 otherwise.
 *
 * SIDE EFFECT: Flushes any pending result, even in case of conflict.
 */

static int Mariatcl_Exec(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;
  int affected;
  Tcl_Obj *resList;
  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN, "handle sql-statement")) == 0)
    return TCL_ERROR;

  /* Flush any previous result. */
  freeResult(handle);

  if (maria_QueryTclObj(handle, objv[2]))
    return maria_server_confl(interp, objc, objv, handle->connection);

  if ((affected = mysql_affected_rows(handle->connection)) < 0)
    affected = 0;

#if (MYSQL_VERSION_ID >= 50000)
  if (!mysql_next_result(handle->connection))
  {
    resList = Tcl_GetObjResult(interp);
    Tcl_ListObjAppendElement(interp, resList, Tcl_NewIntObj(affected));
    do
    {
      if ((affected = mysql_affected_rows(handle->connection)) < 0)
        affected = 0;
      Tcl_ListObjAppendElement(interp, resList, Tcl_NewIntObj(affected));
    } while (!mysql_next_result(handle->connection));
    return TCL_OK;
  }
#endif
  Tcl_SetIntObj(Tcl_GetObjResult(interp), affected);
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Fetch
 *    Implements the marianext command:

 *    usage: maria::fetch handle
 *	                
 *    results:
 *	next row from pending results as tcl list, or null list.
 */

static int Mariatcl_Fetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle;
  int idx;
  MYSQL_ROW row;
  Tcl_Obj *resList;
  unsigned long *lengths;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_RES, "handle")) == 0)
    return TCL_ERROR;

  if (handle->res_count == 0)
    return TCL_OK;
  else if ((row = mysql_fetch_row(handle->result)) == NULL)
  {
    handle->res_count = 0;
    return maria_prim_confl(interp, objc, objv, "result counter out of sync");
  }
  else
    handle->res_count--;

  lengths = mysql_fetch_lengths(handle->result);

  resList = Tcl_GetObjResult(interp);
  for (idx = 0; idx < handle->col_count; idx++, row++)
  {
    Tcl_ListObjAppendElement(interp, resList, getRowCellAsObject(statePtr, handle, row, lengths[idx]));
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Seek
 *    Implements the mariaseek command:
 *    usage: mariaseek handle rownumber
 *	                
 *    results:
 *	number of remaining rows
 */

static int Mariatcl_Seek(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;
  int row;
  int total;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_RES,
                               " handle row-index")) == 0)
    return TCL_ERROR;

  if (Tcl_GetIntFromObj(interp, objv[2], &row) != TCL_OK)
    return TCL_ERROR;

  total = mysql_num_rows(handle->result);

  if (total + row < 0)
  {
    mysql_data_seek(handle->result, 0);

    handle->res_count = total;
  }
  else if (row < 0)
  {
    mysql_data_seek(handle->result, total + row);
    handle->res_count = -row;
  }
  else if (row >= total)
  {
    mysql_data_seek(handle->result, row);
    handle->res_count = 0;
  }
  else
  {
    mysql_data_seek(handle->result, row);
    handle->res_count = total - row;
  }

  Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count));
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Map
 * Implements the mariamap command:
 * usage: mariamap handle binding-list script
 *	                
 * Results:
 * SIDE EFFECT: For each row the column values are bound to the variables
 * in the binding list and the script is evaluated.
 * The variables are created in the current context.
 * NOTE: mariamap works very much like a 'foreach' construct.
 * The 'continue' and 'break' commands may be used with their usual effect.
 */

static int Mariatcl_Map(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  int code;
  int count;

  MariaTclHandle *handle;
  int idx;
  int listObjc;
  Tcl_Obj *tempObj, *varNameObj;
  MYSQL_ROW row;
  int *val;
  unsigned long *lengths;

  if ((handle = maria_prologue(interp, objc, objv, 4, 4, CL_RES,
                               "handle binding-list script")) == 0)
    return TCL_ERROR;

  if (Tcl_ListObjLength(interp, objv[2], &listObjc) != TCL_OK)
    return TCL_ERROR;

  if (listObjc > handle->col_count)
  {
    return maria_prim_confl(interp, objc, objv, "too many variables in binding list");
  }
  else
    count = (listObjc < handle->col_count) ? listObjc
                                           : handle->col_count;

  val = (int *)Tcl_Alloc((count * sizeof(int)));

  for (idx = 0; idx < count; idx++)
  {
    val[idx] = 1;
    if (Tcl_ListObjIndex(interp, objv[2], idx, &varNameObj) != TCL_OK)
      return TCL_ERROR;
    if (Tcl_GetStringFromObj(varNameObj, 0)[0] != '-')
      val[idx] = 1;
    else
      val[idx] = 0;
  }

  while (handle->res_count > 0)
  {
    /* Get next row, decrement row counter. */
    if ((row = mysql_fetch_row(handle->result)) == NULL)
    {
      handle->res_count = 0;
      Tcl_Free((char *)val);
      return maria_prim_confl(interp, objc, objv, "result counter out of sync");
    }
    else
      handle->res_count--;

    /* Bind variables to column values. */
    for (idx = 0; idx < count; idx++, row++)
    {
      lengths = mysql_fetch_lengths(handle->result);
      if (val[idx])
      {
        tempObj = getRowCellAsObject(statePtr, handle, row, lengths[idx]);
        if (Tcl_ListObjIndex(interp, objv[2], idx, &varNameObj) != TCL_OK)
          goto error;
        if (Tcl_ObjSetVar2(interp, varNameObj, NULL, tempObj, 0) == NULL)
          goto error;
      }
    }

    /* Evaluate the script. */
    switch (code = Tcl_EvalObjEx(interp, objv[3], 0))
    {
    case TCL_CONTINUE:
    case TCL_OK:
      break;
    case TCL_BREAK:
      Tcl_Free((char *)val);
      return TCL_OK;
    default:
      Tcl_Free((char *)val);
      return code;
    }
  }
  Tcl_Free((char *)val);
  return TCL_OK;
error:
  Tcl_Free((char *)val);
  return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Receive
 * Implements the mariamap command:
 * usage: mariamap handle sqlquery binding-list script
 * 
 * The method use internal mysql_use_result that no cache statment on client but
 * receive it direct from server 
 *
 * Results:
 * SIDE EFFECT: For each row the column values are bound to the variables
 * in the binding list and the script is evaluated.
 * The variables are created in the current context.
 * NOTE: mariamap works very much like a 'foreach' construct.
 * The 'continue' and 'break' commands may be used with their usual effect.

 */

static int Mariatcl_Receive(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  int code = 0;
  int count = 0;

  MariaTclHandle *handle;
  int idx;
  int listObjc;
  Tcl_Obj *tempObj, *varNameObj;
  MYSQL_ROW row;
  int *val = NULL;
  int breakLoop = 0;
  unsigned long *lengths;

  if ((handle = maria_prologue(interp, objc, objv, 5, 5, CL_CONN,
                               "handle sqlquery binding-list script")) == 0)
    return TCL_ERROR;

  if (Tcl_ListObjLength(interp, objv[3], &listObjc) != TCL_OK)
    return TCL_ERROR;

  freeResult(handle);

  if (maria_QueryTclObj(handle, objv[2]))
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }

  if ((handle->result = mysql_use_result(handle->connection)) == NULL)
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  else
  {
    while ((row = mysql_fetch_row(handle->result)) != NULL)
    {
      if (val == NULL)
      {
        /* first row compute all data */
        handle->col_count = mysql_num_fields(handle->result);
        if (listObjc > handle->col_count)
        {
          return maria_prim_confl(interp, objc, objv, "too many variables in binding list");
        }
        else
        {
          count = (listObjc < handle->col_count) ? listObjc : handle->col_count;
        }
        val = (int *)Tcl_Alloc((count * sizeof(int)));
        for (idx = 0; idx < count; idx++)
        {
          if (Tcl_ListObjIndex(interp, objv[3], idx, &varNameObj) != TCL_OK)
            return TCL_ERROR;
          if (Tcl_GetStringFromObj(varNameObj, 0)[0] != '-')
            val[idx] = 1;
          else
            val[idx] = 0;
        }
      }
      for (idx = 0; idx < count; idx++, row++)
      {
        lengths = mysql_fetch_lengths(handle->result);

        if (val[idx])
        {
          if (Tcl_ListObjIndex(interp, objv[3], idx, &varNameObj) != TCL_OK)
          {
            Tcl_Free((char *)val);
            return TCL_ERROR;
          }
          tempObj = getRowCellAsObject(statePtr, handle, row, lengths[idx]);
          if (Tcl_ObjSetVar2(interp, varNameObj, NULL, tempObj, TCL_LEAVE_ERR_MSG) == NULL)
          {
            Tcl_Free((char *)val);
            return TCL_ERROR;
          }
        }
      }

      /* Evaluate the script. */
      switch (code = Tcl_EvalObjEx(interp, objv[4], 0))
      {
      case TCL_CONTINUE:
      case TCL_OK:
        break;
      case TCL_BREAK:
        breakLoop = 1;
        break;
      default:
        breakLoop = 1;
        break;
      }
      if (breakLoop == 1)
        break;
    }
  }
  if (val != NULL)
  {
    Tcl_Free((char *)val);
  }
  /*  Read all rest rows that leave in error or break case */
  while ((row = mysql_fetch_row(handle->result)) != NULL)
    ;
  if (code != TCL_CONTINUE && code != TCL_OK && code != TCL_BREAK)
  {
    return code;
  }
  else
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Info
 * Implements the mariainfo command:
 * usage: mariainfo handle option
 *


 */

static int Mariatcl_Info(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{

  int count;
  MariaTclHandle *handle;
  int idx;
  MYSQL_RES *list;
  MYSQL_ROW row;
  const char *val;
  Tcl_Obj *resList;
  static CONST char *MariaDbOpt[] =
  {
    "dbname",
    "dbname?",
    "tables",
    "host",
    "host?",
    "databases",
    "info",
    "serverversion",
#if (MYSQL_VERSION_ID >= 40107)
    "serverversionid",
    "sqlstate",
#endif
    "state",
    NULL
  };
  enum dboption
  {
    MARIA_INFNAME_OPT,
    MARIA_INFNAMEQ_OPT,
    MARIA_INFTABLES_OPT,
    MARIA_INFHOST_OPT,
    MARIA_INFHOSTQ_OPT,
    MARIA_INFLIST_OPT,
    MARIA_INFO,
    MARIA_INF_SERVERVERSION,
    MARIA_INFO_SERVERVERSION_ID,
    MARIA_INFO_SQLSTATE,
    MARIA_INFO_STATE
  };

  /* We can't fully check the handle at this stage. */
  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_PLAIN,
                               "handle option")) == 0)
    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], MariaDbOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx)
  {
  case MARIA_INFNAMEQ_OPT:
    if ((handle = get_handle(interp, objc, objv, CL_CONN)) != NULL)
    {
      if (handle->database[0] == '\0')
        return TCL_OK; /* Return empty string if no current db. */
    }
    break;
  case MARIA_INFNAME_OPT:
  case MARIA_INFTABLES_OPT:
  case MARIA_INFHOST_OPT:
  case MARIA_INFLIST_OPT:
    /* !!! */
    handle = get_handle(interp, objc, objv, CL_CONN);
    break;
  case MARIA_INFO:
  case MARIA_INF_SERVERVERSION:
#if (MYSQL_VERSION_ID >= 40107)
  case MARIA_INFO_SERVERVERSION_ID:
  case MARIA_INFO_SQLSTATE:
#endif
  case MARIA_INFO_STATE:
    break;

  case MARIA_INFHOSTQ_OPT:
    if (handle->connection == 0)
      return TCL_OK; /* Return empty string if not connected. */
    break;
  default: /* should never happen */
    return maria_prim_confl(interp, objc, objv, "weirdness in Mariatcl_Info");
  }

  if (handle == 0)
    return TCL_ERROR;

  /* Handle OK, return the requested info. */
  switch (idx)
  {
  case MARIA_INFNAME_OPT:
  case MARIA_INFNAMEQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(handle->database, -1));
    break;
  case MARIA_INFTABLES_OPT:
    if ((list = mysql_list_tables(handle->connection, (char *)NULL)) == NULL)
      return maria_server_confl(interp, objc, objv, handle->connection);

    resList = Tcl_GetObjResult(interp);
    for (count = mysql_num_rows(list); count > 0; count--)
    {
      val = *(row = mysql_fetch_row(list));
      Tcl_ListObjAppendElement(interp, resList, Tcl_NewStringObj((val == NULL) ? "" : val, -1));
    }
    mysql_free_result(list);
    break;
  case MARIA_INFHOST_OPT:

  case MARIA_INFHOSTQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_host_info(handle->connection), -1));
    break;
  case MARIA_INFLIST_OPT:
    if ((list = mysql_list_dbs(handle->connection, (char *)NULL)) == NULL)
      return maria_server_confl(interp, objc, objv, handle->connection);

    resList = Tcl_GetObjResult(interp);
    for (count = mysql_num_rows(list); count > 0; count--)
    {
      val = *(row = mysql_fetch_row(list));
      Tcl_ListObjAppendElement(interp, resList,
                               Tcl_NewStringObj((val == NULL) ? "" : val, -1));
    }
    mysql_free_result(list);
    break;
  case MARIA_INFO:
    val = mysql_info(handle->connection);
    if (val != NULL)
    {
      Tcl_SetObjResult(interp, Tcl_NewStringObj(val, -1));
    }
    break;
  case MARIA_INF_SERVERVERSION:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_server_info(handle->connection), -1));
    break;
#if (MYSQL_VERSION_ID >= 40107)
  case MARIA_INFO_SERVERVERSION_ID:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_get_server_version(handle->connection)));
    break;
  case MARIA_INFO_SQLSTATE:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_sqlstate(handle->connection), -1));
    break;
#endif
  case MARIA_INFO_STATE:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_stat(handle->connection), -1));
    break;
  default: /* should never happen */
    return maria_prim_confl(interp, objc, objv, "weirdness in Mariatcl_Info");
  }

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_BaseInfo
 * Implements the mariainfo command:
 * usage: mariabaseinfo option
 *
 */

static int Mariatcl_BaseInfo(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int idx;
  Tcl_Obj *resList;
  char **option;
  static CONST char *MariaInfoOpt[] =
  {
    "connectparameters",
    "clientversion",
#if (MYSQL_VERSION_ID >= 40107)
    "clientversionid",
#endif
    NULL
  };
  enum baseoption
  {
    MARIA_BINFO_CONNECT,
    MARIA_BINFO_CLIENTVERSION,
    MARIA_BINFO_CLIENTVERSIONID
  };

  if (objc < 2)
  {
    Tcl_WrongNumArgs(interp, 1, objv, "connectparameters | clientversion");

    return TCL_ERROR;
  }
  if (Tcl_GetIndexFromObj(interp, objv[1], MariaInfoOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx)
  {
  case MARIA_BINFO_CONNECT:
    option = (char **)MariaConnectOpt;
    resList = Tcl_NewListObj(0, NULL);

    while (*option != NULL)
    {
      Tcl_ListObjAppendElement(interp, resList, Tcl_NewStringObj(*option, -1));
      option++;
    }
    Tcl_SetObjResult(interp, resList);
    break;
  case MARIA_BINFO_CLIENTVERSION:
    Tcl_SetObjResult(interp, Tcl_NewStringObj(mysql_get_client_info(), -1));
    break;
#if (MYSQL_VERSION_ID >= 40107)
  case MARIA_BINFO_CLIENTVERSIONID:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_get_client_version()));
    break;
#endif
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Result

 * Implements the mariaresult command:
 * usage: mariaresult handle option
 *
 */

static int Mariatcl_Result(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int idx;
  MariaTclHandle *handle;
  static CONST char *MariaResultOpt[] =
      {
          "rows", "rows?", "cols", "cols?", "current", "current?", NULL};
  enum resultoption
  {
    MYSQL_RESROWS_OPT,
    MYSQL_RESROWSQ_OPT,
    MYSQL_RESCOLS_OPT,
    MYSQL_RESCOLSQ_OPT,
    MYSQL_RESCUR_OPT,
    MYSQL_RESCURQ_OPT
  };
  /* We can't fully check the handle at this stage. */
  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_PLAIN,
                               " handle option")) == 0)

    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], MariaResultOpt, "option",
                          TCL_EXACT, &idx) != TCL_OK)
    return TCL_ERROR;

  /* First check the handle. Checking depends on the option. */
  switch (idx)
  {
  case MYSQL_RESROWS_OPT:
  case MYSQL_RESCOLS_OPT:
  case MYSQL_RESCUR_OPT:
    handle = get_handle(interp, objc, objv, CL_RES);
    break;
  case MYSQL_RESROWSQ_OPT:
  case MYSQL_RESCOLSQ_OPT:
  case MYSQL_RESCURQ_OPT:
    if ((handle = get_handle(interp, objc, objv, CL_RES)) == NULL)
      return TCL_OK; /* Return empty string if no pending result. */
    break;
  default: /* should never happen */
    return maria_prim_confl(interp, objc, objv, "weirdness in Mariatcl_Result");
  }

  if (handle == 0)
    return TCL_ERROR;

  /* Handle OK; return requested info. */
  switch (idx)
  {
  case MYSQL_RESROWS_OPT:
  case MYSQL_RESROWSQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count));
    break;
  case MYSQL_RESCOLS_OPT:
  case MYSQL_RESCOLSQ_OPT:
    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->col_count));
    break;
  case MYSQL_RESCUR_OPT:
  case MYSQL_RESCURQ_OPT:
    Tcl_SetObjResult(interp,
                     Tcl_NewIntObj(mysql_num_rows(handle->result) - handle->res_count));
    break;
  default:
    return maria_prim_confl(interp, objc, objv, "weirdness in Mariatcl_Result");
  }
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Col

 *    Implements the mariacol command:
 *    usage: mariacol handle table-name option ?option ...?
 *           mariacol handle -current option ?option ...?
 * '-current' can only be used if there is a pending result.
 *	                
 *    results:
 *	List of lists containing column attributes.
 *      If a single attribute is requested the result is a simple list.
 *
 * SIDE EFFECT: '-current' disturbs the field position of the result.
 */

static int Mariatcl_Col(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int coln;
  int current_db;
  MariaTclHandle *handle;
  int idx;
  int listObjc;
  Tcl_Obj **listObjv, *colinfo, *resList, *resSubList;
  MYSQL_FIELD *fld;
  MYSQL_RES *result;
  char *argv;

  /* This check is enough only without '-current'. */
  if ((handle = maria_prologue(interp, objc, objv, 4, 99, CL_CONN,
                               "handle table-name option ?option ...?")) == 0)
    return TCL_ERROR;

  /* Fetch column info.
   * Two ways: explicit database and table names, or current.
   */
  argv = Tcl_GetStringFromObj(objv[2], NULL);
  current_db = strcmp(argv, "-current") == 0;

  if (current_db)
  {
    if ((handle = get_handle(interp, objc, objv, CL_RES)) == 0)
      return TCL_ERROR;
    else
      result = handle->result;
  }
  else
  {
    if ((result = mysql_list_fields(handle->connection, argv, (char *)NULL)) == NULL)
    {
      return maria_server_confl(interp, objc, objv, handle->connection);
    }
  }
  /* Must examine the first specifier at this point. */
  if (Tcl_ListObjGetElements(interp, objv[3], &listObjc, &listObjv) != TCL_OK)
    return TCL_ERROR;
  resList = Tcl_GetObjResult(interp);
  if (objc == 4 && listObjc == 1)
  {
    mysql_field_seek(result, 0);
    while ((fld = mysql_fetch_field(result)) != NULL)
      if ((colinfo = maria_colinfo(interp, objc, objv, fld, objv[3])) != NULL)
      {
        Tcl_ListObjAppendElement(interp, resList, colinfo);
      }
      else
      {
        goto conflict;
      }
  }
  else if (objc == 4 && listObjc > 1)
  {
    mysql_field_seek(result, 0);
    while ((fld = mysql_fetch_field(result)) != NULL)
    {
      resSubList = Tcl_NewListObj(0, NULL);
      for (coln = 0; coln < listObjc; coln++)
        if ((colinfo = maria_colinfo(interp, objc, objv, fld, listObjv[coln])) != NULL)
        {
          Tcl_ListObjAppendElement(interp, resSubList, colinfo);
        }
        else
        {

          goto conflict;
        }
      Tcl_ListObjAppendElement(interp, resList, resSubList);
    }
  }
  else
  {
    for (idx = 3; idx < objc; idx++)
    {
      resSubList = Tcl_NewListObj(0, NULL);
      mysql_field_seek(result, 0);
      while ((fld = mysql_fetch_field(result)) != NULL)
        if ((colinfo = maria_colinfo(interp, objc, objv, fld, objv[idx])) != NULL)
        {

          Tcl_ListObjAppendElement(interp, resSubList, colinfo);
        }
        else
        {
          goto conflict;
        }
      Tcl_ListObjAppendElement(interp, resList, resSubList);
    }
  }
  if (!current_db)
    mysql_free_result(result);
  return TCL_OK;

conflict:
  if (!current_db)
    mysql_free_result(result);
  return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_State
 *    Implements the mariastate command:
 *    usage: mariastate handle ?-numeric?

 *	                
 */

static int Mariatcl_State(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;
  int numeric = 0;
  Tcl_Obj *res;

  if (objc != 2 && objc != 3)
  {
    Tcl_WrongNumArgs(interp, 1, objv, "handle ?-numeric");
    return TCL_ERROR;
  }

  if (objc == 3)
  {
    if (strcmp(Tcl_GetStringFromObj(objv[2], NULL), "-numeric"))
      return maria_prim_confl(interp, objc, objv, "last parameter should be -numeric");
    else

      numeric = 1;
  }

  if (GetHandleFromObj(interp, objv[1], &handle) != TCL_OK)
    res = (numeric) ? Tcl_NewIntObj(0) : Tcl_NewStringObj("NOT_A_HANDLE", -1);
  else if (handle->connection == 0)
    res = (numeric) ? Tcl_NewIntObj(1) : Tcl_NewStringObj("UNCONNECTED", -1);
  else if (handle->database[0] == '\0')
    res = (numeric) ? Tcl_NewIntObj(2) : Tcl_NewStringObj("CONNECTED", -1);
  else if (handle->result == NULL)
    res = (numeric) ? Tcl_NewIntObj(3) : Tcl_NewStringObj("IN_USE", -1);
  else
    res = (numeric) ? Tcl_NewIntObj(4) : Tcl_NewStringObj("RESULT_PENDING", -1);

  Tcl_SetObjResult(interp, res);
  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_InsertId
 *    Implements the mariastate command:
 *    usage: mariainsertid handle 
 *    Returns the auto increment id of the last INSERT statement
 *	                
 */

static int Mariatcl_InsertId(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{

  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;

  Tcl_SetObjResult(interp, Tcl_NewIntObj(mysql_insert_id(handle->connection)));

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Ping
 *    usage: mariaping handle
 *    It can be used to check and refresh (reconnect after time out) the connection
 *    Returns 0 if connection is OK
 */

static int Mariatcl_Ping(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;

  Tcl_SetObjResult(interp, Tcl_NewBooleanObj(mysql_ping(handle->connection) == 0));

  return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_ChangeUser
 *    usage: mariachangeuser handle user password database
 *    return TCL_ERROR if operation failed
 */

static int Mariatcl_ChangeUser(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;
  int len;
  char *user, *password, *database = NULL;

  if ((handle = maria_prologue(interp, objc, objv, 4, 5, CL_CONN,
                               "handle user password ?database?")) == 0)
    return TCL_ERROR;

  user = Tcl_GetStringFromObj(objv[2], NULL);
  password = Tcl_GetStringFromObj(objv[3], NULL);
  if (objc == 5)
  {
    database = Tcl_GetStringFromObj(objv[4], &len);
    if (len >= MARIA_NAME_LEN)
    {
      maria_prim_confl(interp, objc, objv, "database name too long");
      return TCL_ERROR;
    }
  }
  if (mysql_change_user(handle->connection, user, password, database) != 0)
  {
    maria_server_confl(interp, objc, objv, handle->connection);
    return TCL_ERROR;
  }
  if (database != NULL)
    strcpy(handle->database, database);
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_AutoCommit
 *    usage: maria::autocommit bool
 *    set autocommit mode
 */

static int Mariatcl_AutoCommit(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;
  int isAutocommit = 0;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle bool")) == 0)
    return TCL_ERROR;
  if (Tcl_GetBooleanFromObj(interp, objv[2], &isAutocommit) != TCL_OK)
    return TCL_ERROR;
  if (mysql_autocommit(handle->connection, isAutocommit) != 0)
  {
    maria_server_confl(interp, objc, objv, handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Commit
 *    usage: maria::commit
 *    
 */

static int Mariatcl_Commit(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;
  if (mysql_commit(handle->connection) != 0)
  {
    maria_server_confl(interp, objc, objv, handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Rollback
 *    usage: maria::rollback
 *
 */

static int Mariatcl_Rollback(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;
  if (mysql_rollback(handle->connection) != 0)
  {
    maria_server_confl(interp, objc, objv, handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_MoreResult
 *    usage: maria::moreresult handle
 *    return true if more results exists
 */

static int Mariatcl_MoreResult(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;
  int boolResult = 0;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_RES,
                               "handle")) == 0)
    return TCL_ERROR;
  boolResult = mysql_more_results(handle->connection);
  Tcl_SetObjResult(interp, Tcl_NewBooleanObj(boolResult));
  return TCL_OK;
#endif
}
/*

 *----------------------------------------------------------------------
 *
 * Mariatcl_NextResult
 *    usage: maria::nextresult
 *
 *  return nummber of rows in result set. 0 if no next result
 */

static int Mariatcl_NextResult(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;
  int result = 0;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_RES,
                               "handle")) == 0)
    return TCL_ERROR;
  if (handle->result != NULL)
  {
    mysql_free_result(handle->result);
    handle->result = NULL;
  }
  result = mysql_next_result(handle->connection);
  if (result == -1)
  {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
    return TCL_OK;
  }
  if (result < 0)
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  handle->result = mysql_store_result(handle->connection);
  handle->col_count = mysql_num_fields(handle->result);
  if (handle->result == NULL)
  {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(-1));
  }
  else
  {
    handle->res_count = mysql_num_rows(handle->result);
    Tcl_SetObjResult(interp, Tcl_NewIntObj(handle->res_count));
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_WarningCount
 *    usage: maria::warningcount
 *
 */

static int Mariatcl_WarningCount(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;
  int count = 0;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;
  count = mysql_warning_count(handle->connection);
  Tcl_SetObjResult(interp, Tcl_NewIntObj(count));
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_IsNull
 *    usage: maria::isnull value
 *
 */

static int Mariatcl_IsNull(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  int boolResult = 0;
  if (objc != 2)
  {
    Tcl_WrongNumArgs(interp, 1, objv, "value");
    return TCL_ERROR;
  }
  boolResult = objv[1]->typePtr == &mariaNullType;
  Tcl_SetObjResult(interp, Tcl_NewBooleanObj(boolResult));
  return TCL_OK;

  return TCL_OK;
}
/*
 * Create new Maria NullObject
 * (similar to Tcl API for example Tcl_NewIntObj)
 */
static Tcl_Obj *Mariatcl_NewNullObj(MariatclState *mariatclState)
{
  Tcl_Obj *objPtr;
  objPtr = Tcl_NewObj();
  objPtr->bytes = NULL;
  objPtr->typePtr = &mariaNullType;
  objPtr->internalRep.otherValuePtr = mariatclState;
  return objPtr;
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_NewNull
 *    usage: maria::newnull
 *
 */

static int Mariatcl_NewNull(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  if (objc != 1)
  {
    Tcl_WrongNumArgs(interp, 1, objv, "");
    return TCL_ERROR;
  }
  Tcl_SetObjResult(interp, Mariatcl_NewNullObj((MariatclState *)clientData));
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_SetServerOption
 *    usage: maria::setserveroption (-
 *
 */
#if (MYSQL_VERSION_ID >= 40107)
static CONST char *MariaServerOpt[] =
    {
        "-multi_statment_on", "-multi_statment_off", "-auto_reconnect_on", "-auto_reconnect_off", NULL};
#endif

static int Mariatcl_SetServerOption(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
#if (MYSQL_VERSION_ID < 40107)
  Tcl_AddErrorInfo(interp, FUNCTION_NOT_AVAILABLE);
  return TCL_ERROR;
#else
  MariaTclHandle *handle;
  int idx;
  enum enum_mysql_set_option mariaServerOption;

  enum serveroption
  {
    MARIA_MSTATMENT_ON_SOPT,
    MARIA_MSTATMENT_OFF_SOPT
  };

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle option")) == 0)
    return TCL_ERROR;

  if (Tcl_GetIndexFromObj(interp, objv[2], MariaServerOpt, "option",
                          0, &idx) != TCL_OK)
    return TCL_ERROR;

  switch (idx)
  {
  case MARIA_MSTATMENT_ON_SOPT:
    mariaServerOption = MYSQL_OPTION_MULTI_STATEMENTS_ON;
    break;
  case MARIA_MSTATMENT_OFF_SOPT:
    mariaServerOption = MYSQL_OPTION_MULTI_STATEMENTS_OFF;
    break;
  default:
    return maria_prim_confl(interp, objc, objv, "Weirdness in server options");
  }
  if (mysql_set_server_option(handle->connection, mariaServerOption) != 0)
  {
    maria_server_confl(interp, objc, objv, handle->connection);
  }
  return TCL_OK;
#endif
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_ShutDown
 *    usage: maria::shutdown handle
 *
 */
static int Mariatcl_ShutDown(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;
#if (MYSQL_VERSION_ID >= 40107)
  if (mysql_shutdown(handle->connection, SHUTDOWN_DEFAULT) != 0)
  {
#else
  if (mysql_shutdown(handle->connection) != 0)
  {
#endif
    maria_server_confl(interp, objc, objv, handle->connection);
  }
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Encoding
 *    usage: maria::encoding handle ?encoding|binary?
 *
 */
static int Mariatcl_Encoding(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  Tcl_HashSearch search;
  Tcl_HashEntry *entryPtr;
  MariaTclHandle *handle, *qhandle;
  char *encodingname;
  Tcl_Encoding encoding;

  if ((handle = maria_prologue(interp, objc, objv, 2, 3, CL_CONN,
                               "handle")) == 0)
    return TCL_ERROR;
  if (objc == 2)
  {
    if (handle->encoding == NULL)
      Tcl_SetObjResult(interp, Tcl_NewStringObj("binary", -1));
    else
      Tcl_SetObjResult(interp, Tcl_NewStringObj(Tcl_GetEncodingName(handle->encoding), -1));
  }
  else
  {
    if (handle->type != HT_CONNECTION)
    {
      Tcl_SetObjResult(interp, Tcl_NewStringObj("encoding set can be used only on connection handle", -1));
      return TCL_ERROR;
    }
    encodingname = Tcl_GetStringFromObj(objv[2], NULL);
    if (strcmp(encodingname, "binary") == 0)
    {
      encoding = NULL;
    }
    else
    {
      encoding = Tcl_GetEncoding(interp, encodingname);
      if (encoding == NULL)
        return TCL_ERROR;
    }
    if (handle->encoding != NULL)
      Tcl_FreeEncoding(handle->encoding);
    handle->encoding = encoding;

    /* change encoding of all subqueries */
    for (entryPtr = Tcl_FirstHashEntry(&statePtr->hash, &search);
         entryPtr != NULL;
         entryPtr = Tcl_NextHashEntry(&search))
    {
      qhandle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);
      if (qhandle->type == HT_QUERY && handle->connection == qhandle->connection)
      {
        qhandle->encoding = encoding;
      }
    }
  }
  return TCL_OK;
}
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Close --
 *    Implements the mariaclose command:
 *    usage: mariaclose ?handle?
 *	                
 *    results:
 *	null string
 */

static int Mariatcl_Close(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])

{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle, *thandle;
  Tcl_HashEntry *entryPtr;
  Tcl_HashEntry *qentries[16];
  Tcl_HashSearch search;

  int i, qfound = 0;

  /* If handle omitted, close all connections. */
  if (objc == 1)
  {
    Mariatcl_CloseAll(clientData);
    return TCL_OK;
  }

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "?handle?")) == 0)
    return TCL_ERROR;

  /* Search all queries and statements on this handle and close those */
  if (handle->type == HT_CONNECTION)
  {
    while (1)
    {
      for (entryPtr = Tcl_FirstHashEntry(&statePtr->hash, &search);
           entryPtr != NULL;
           entryPtr = Tcl_NextHashEntry(&search))
      {

        thandle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);
        if (thandle->connection == handle->connection &&
            thandle->type != HT_CONNECTION)
        {
          qentries[qfound++] = entryPtr;
        }
        if (qfound == 16)
          break;
      }
      if (qfound > 0)
      {
        for (i = 0; i < qfound; i++)
        {
          entryPtr = qentries[i];
          thandle = (MariaTclHandle *)Tcl_GetHashValue(entryPtr);
          Tcl_DeleteHashEntry(entryPtr);
          closeHandle(thandle);
        }
      }
      if (qfound != 16)
        break;
      qfound = 0;
    }
  }
  entryPtr = Tcl_FindHashEntry(&statePtr->hash, Tcl_GetStringFromObj(objv[1], NULL));
  if (entryPtr)
    Tcl_DeleteHashEntry(entryPtr);
  closeHandle(handle);
  return TCL_OK;
}

#ifdef PREPARED_STATEMENT
/*
 *----------------------------------------------------------------------
 *
 * Mariatcl_Prepare --
 *    Implements the maria::prepare command:
 *    usage: maria::prepare handle statements
 *
 *    results:
 *	    prepared statment handle
 */

static int Mariatcl_Prepare(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;

  MariaTclHandle *handle;
  MariaTclHandle *shandle;
  MARIA_STMT *statement;
  char *query;
  int queryLen;
  int resultColumns;
  int paramCount;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle sql-statement")) == 0)
    return TCL_ERROR;

  statement = mysql_stmt_init(handle->connection);
  if (statement == NULL)
  {
    return TCL_ERROR;
  }
  query = (char *)Tcl_GetByteArrayFromObj(objv[2], &queryLen);
  if (mysql_stmt_prepare(statement, query, queryLen))
  {

    mysql_stmt_close(statement);
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  if ((shandle = createHandleFrom(statePtr, handle, HT_STATEMENT)) == NULL)
    return TCL_ERROR;
  shandle->statement = statement;
  shandle->resultMetadata = mysql_stmt_result_metadata(statement);
  shandle->paramMetadata = mysql_stmt_param_metadata(statement);
  /* set result bind memory */
  resultColumns = mysql_stmt_field_count(statement);
  if (resultColumns > 0)
  {
    shandle->bindResult = (MARIA_BIND *)Tcl_Alloc(sizeof(MARIA_BIND) * resultColumns);
    memset(shandle->bindResult, 0, sizeof(MARIA_BIND) * resultColumns);
  }
  paramCount = mysql_stmt_param_count(statement);
  if (resultColumns > 0)
  {
    shandle->bindParam = (MARIA_BIND *)Tcl_Alloc(sizeof(MARIA_BIND) * paramCount);
    memset(shandle->bindParam, 0, sizeof(MARIA_BIND) * paramCount);
  }
  Tcl_SetObjResult(interp, Tcl_NewHandleObj(statePtr, shandle));
  return TCL_OK;
}
static int Mariatcl_ParamMetaData(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle;
  MYSQL_RES *res;
  MYSQL_ROW row;
  Tcl_Obj *colinfo, *resObj;
  unsigned long *lengths;
  int i;
  int colCount;
  MYSQL_FIELD *fld;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "statement-handle")) == 0)
    return TCL_ERROR;
  if (handle->type != HT_STATEMENT)
    return TCL_ERROR;

  resObj = Tcl_GetObjResult(interp);
  printf("statement %p count %d\n", handle->statement, mysql_stmt_param_count(handle->statement));
  res = mysql_stmt_result_metadata(handle->statement);
  printf("res %p\n", res);
  if (res == NULL)
    return TCL_ERROR;

  mysql_field_seek(res, 0);
  while ((fld = mysql_fetch_field(res)) != NULL)
  {
    if ((colinfo = maria_colinfo(interp, objc, objv, fld, objv[2])) != NULL)
    {
      Tcl_ListObjAppendElement(interp, resObj, colinfo);
    }
    else
    {
      goto conflict;
    }
  }
conflict:

  mysql_free_result(res);
  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Mariatcl_PSelect --
 *    Implements the maria::pselect command:
 *    usage: maria::pselect $statement_handle ?arguments...?
 *
 *    results:
 *	    number of returned rows
 */

static int Mariatcl_PSelect(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle sql-statement")) == 0)
    return TCL_ERROR;
  if (handle->type != HT_STATEMENT)
  {
    return TCL_ERROR;
  }
  mysql_stmt_reset(handle->statement);
  if (mysql_stmt_execute(handle->statement))
  {
    return maria_server_confl(interp, objc, objv, handle->connection);
  }
  mysql_stmt_bind_result(handle->statement, handle->bindResult);
  mysql_stmt_store_result(handle->statement);
  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Mariatcl_PFetch --
 *    Implements the maria::pfetch command:
 *    usage: maria::pfetch $statement_handle
 *
 *    results:
 *	    number of returned rows
 */

static int Mariatcl_PFetch(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 2, 2, CL_CONN,
                               "prep-stat-handle")) == 0)
    return TCL_ERROR;
  if (handle->type != HT_STATEMENT)
  {
    return TCL_ERROR;
  }

  return TCL_OK;
}
/*----------------------------------------------------------------------
 *
 * Mariatcl_PExecute --
 *    Implements the maria::pexecute command:
 *    usage: maria::pexecute statement-handle ?arguments...?
 *
 *    results:
 *	    number of effected rows
 */

static int Mariatcl_PExecute(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *const objv[])
{
  MariatclState *statePtr = (MariatclState *)clientData;
  MariaTclHandle *handle;

  if ((handle = maria_prologue(interp, objc, objv, 3, 3, CL_CONN,
                               "handle sql-statement")) == 0)
    return TCL_ERROR;
  if (handle->type != HT_STATEMENT)
  {
    return TCL_ERROR;
  }
  mysql_stmt_reset(handle->statement);

  if (mysql_stmt_param_count(handle->statement) != 0)
  {
    Tcl_SetStringObj(Tcl_GetObjResult(interp), "works only for 0 params", -1);
    return TCL_ERROR;
  }
  if (mysql_stmt_execute(handle->statement))
  {
    Tcl_SetStringObj(Tcl_GetObjResult(interp), mysql_stmt_error(handle->statement), -1);
    return TCL_ERROR;
  }
  return TCL_OK;
}
#endif

/*
 *----------------------------------------------------------------------
 * Mariatcl_Init
 * Perform all initialization for the MYSQL to Tcl interface.
 * Adds additional commands to interp, creates message array, initializes
 * all handles.
 *
 * A call to Mariatcl_Init should exist in Tcl_CreateInterp or
 * Tcl_CreateExtendedInterp.

 */

#ifdef _WINDOWS
__declspec(dllexport)
#endif
int Mariatcl_Init(interp)
    Tcl_Interp *interp;
{
  char nbuf[MARIA_SMALL_SIZE];
  MariatclState *statePtr;

  if (Tcl_InitStubs(interp, "8.1", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgRequire(interp, "Tcl", "8.1", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgProvide(interp, "mariatcl", PACKAGE_VERSION) != TCL_OK)
    return TCL_ERROR;
  /*

   * Initialize the new Tcl commands.
   * Deleting any command will close all connections.
   */
  statePtr = (MariatclState *)Tcl_Alloc(sizeof(MariatclState));
  Tcl_InitHashTable(&statePtr->hash, TCL_STRING_KEYS);
  statePtr->handleNum = 0;

  Tcl_CreateObjCommand(interp, "mariaconnect", Mariatcl_Connect, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariause", Mariatcl_Use, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaescape", Mariatcl_Escape, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariasel", Mariatcl_Sel, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "marianext", Mariatcl_Fetch, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaseek", Mariatcl_Seek, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariamap", Mariatcl_Map, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaexec", Mariatcl_Exec, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaclose", Mariatcl_Close, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariainfo", Mariatcl_Info, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaresult", Mariatcl_Result, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariacol", Mariatcl_Col, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariastate", Mariatcl_State, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariainsertid", Mariatcl_InsertId, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaquery", Mariatcl_Query, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaendquery", Mariatcl_EndQuery, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariabaseinfo", Mariatcl_BaseInfo, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariaping", Mariatcl_Ping, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariachangeuser", Mariatcl_ChangeUser, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "mariareceive", Mariatcl_Receive, (ClientData)statePtr, NULL);

  Tcl_CreateObjCommand(interp, "::maria::connect", Mariatcl_Connect, (ClientData)statePtr, Mariatcl_Kill);
  Tcl_CreateObjCommand(interp, "::maria::use", Mariatcl_Use, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::escape", Mariatcl_Escape, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::sel", Mariatcl_Sel, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::fetch", Mariatcl_Fetch, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::seek", Mariatcl_Seek, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::map", Mariatcl_Map, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::exec", Mariatcl_Exec, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::close", Mariatcl_Close, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::info", Mariatcl_Info, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::result", Mariatcl_Result, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::col", Mariatcl_Col, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::state", Mariatcl_State, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::insertid", Mariatcl_InsertId, (ClientData)statePtr, NULL);
  /* new in mariatcl 2.0 */
  Tcl_CreateObjCommand(interp, "::maria::query", Mariatcl_Query, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::endquery", Mariatcl_EndQuery, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::baseinfo", Mariatcl_BaseInfo, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::ping", Mariatcl_Ping, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::changeuser", Mariatcl_ChangeUser, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::receive", Mariatcl_Receive, (ClientData)statePtr, NULL);
  /* new in mariatcl 3.0 */
  Tcl_CreateObjCommand(interp, "::maria::autocommit", Mariatcl_AutoCommit, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::commit", Mariatcl_Commit, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::rollback", Mariatcl_Rollback, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::nextresult", Mariatcl_NextResult, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::moreresult", Mariatcl_MoreResult, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::warningcount", Mariatcl_WarningCount, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::isnull", Mariatcl_IsNull, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::newnull", Mariatcl_NewNull, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::setserveroption", Mariatcl_SetServerOption, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::shutdown", Mariatcl_ShutDown, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::encoding", Mariatcl_Encoding, (ClientData)statePtr, NULL);
  /* prepared statements */

#ifdef PREPARED_STATEMENT
  Tcl_CreateObjCommand(interp, "::maria::prepare", Mariatcl_Prepare, (ClientData)statePtr, NULL);
  // Tcl_CreateObjCommand(interp,"::maria::parammetadata", Mariatcl_ParamMetaData,(ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::pselect", Mariatcl_PSelect, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::pselect", Mariatcl_PFetch, (ClientData)statePtr, NULL);
  Tcl_CreateObjCommand(interp, "::maria::pexecute", Mariatcl_PExecute, (ClientData)statePtr, NULL);
#endif

  /* Initialize mariastatus global array. */

  clear_msg(interp);

  /* Link the null value element to the corresponding C variable. */
  if ((statePtr->MariaNullvalue = Tcl_Alloc(12)) == NULL)
    return TCL_ERROR;
  strcpy(statePtr->MariaNullvalue, MARIA_NULLV_INIT);
  sprintf(nbuf, "%s(%s)", MARIA_STATUS_ARR, MARIA_STATUS_NULLV);

  /* set null object in mariatcl state */
  /* statePtr->nullObjPtr = Mariatcl_NewNullObj(statePtr); */

  if (Tcl_LinkVar(interp, nbuf, (char *)&statePtr->MariaNullvalue, TCL_LINK_STRING) != TCL_OK)
    return TCL_ERROR;

  /* Register the handle object type */
  Tcl_RegisterObjType(&mariaHandleType);
  /* Register own null type object */
  Tcl_RegisterObjType(&mariaNullType);

  /* A little sanity check.
    * If this message appears you must change the source code and recompile.
   */
  if (strlen(MariaHandlePrefix) == MARIA_HPREFIX_LEN)
    return TCL_OK;
  else
  {
    panic("*** mariatcl (mariatcl.c): handle prefix inconsistency!\n");
    return TCL_ERROR;
  }
}

#ifdef _WINDOWS
__declspec(dllexport)
#endif
int Mariatcl_SafeInit(interp)
    Tcl_Interp *interp;
{
  return Mariatcl_Init(interp);
}
