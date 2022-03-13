/* $Id$ */

#ifndef DB2TCLCMDS_H
#define DB2TCLCMDS_H

#ifdef _WINDOWS
#define snprintf _snprintf
#endif

#include <tcl.h>
#include <sqlcli.h>

#define MAX_UID_LENGTH 18
#define MAX_PWD_LENGTH 30
#define MAX_STMT_LEN   255
#define MAX_COLUMNS    255
#define MAX_ID_LENGTH  255

#ifndef CONST84
#define CONST84
#endif

typedef struct FieldBuffer { 
  /* description of the field */
  SQLSMALLINT dbtype;
  SQLCHAR    *cbuf;           /* ptr to name of select-list item */
  SQLSMALLINT cbufl;          /* length of select-list item name */
  SQLINTEGER  dsize;          /* max display size if field is a SQLCHAR */
  SQLUINTEGER prec;
  SQLSMALLINT scale;
  SQLSMALLINT nullok;

  /* Our storage space for the field data as it's fetched */
  SQLSMALLINT ftype;          /* external datatype we wish to get             */
  short       indp;           /* null/trunc indicator variable                */
  void       *buffer;         /* data buffer (poSQLINTEGERs to sv data)       */
  SQLINTEGER  bufferSize;     /* length of data buffer                        */
  SQLINTEGER  rlen;           /* length of returned data                      */
} FieldBuffer;

typedef struct Db2Connection
{
    char id[MAX_ID_LENGTH + 1];

    char database[SQL_MAX_DSN_LENGTH + 1];
    char user[MAX_UID_LENGTH + 1];
    char password[MAX_PWD_LENGTH + 1];

    SQLHANDLE hdbc;
    
    SQLCHAR sql_state[5];
    SQLINTEGER native_error;
    SQLCHAR error_msg[SQL_MAX_MESSAGE_LENGTH + 1];
    SQLSMALLINT size_error_msg;
    SQLRETURN rc;

} Db2Connection;

/* Registered Tcl functions */

extern int Db2_connect(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_disconnect(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_exec_direct(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_exec_prepared(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_select_direct(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_select_prepared(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_prepare(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_bind_param(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_bind_exec(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_finish(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_fetchrow(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_getnumrows(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_begin_transaction(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_commit_transaction(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_rollback_transaction(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_db2(
		ClientData cData, 
		Tcl_Interp *interp, 
		int argc, 
		CONST84 char *argv[]);

extern int Db2_test (ClientData clientData,
                     Tcl_Interp * interp,
                     int objc, 
		     struct Tcl_Obj * CONST * objv);

#endif	 /* DB2TCLCMDS_H */
