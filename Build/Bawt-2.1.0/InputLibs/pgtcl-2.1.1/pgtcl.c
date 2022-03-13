/*-------------------------------------------------------------------------
 *
 * pgtcl.c
 *
 *	libpgtcl is a tcl package for front-ends to interface with PostgreSQL.
 *	It's a Tcl wrapper for libpq.
 *
 * Portions Copyright (c) 1996-2004, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  $Id: pgtcl.c 334 2013-10-04 15:04:44Z lbayuk $
 *
 *-------------------------------------------------------------------------
 */

#include "libpgtcl.h"
#include "pgtclCmds.h"
#include "pgtclId.h"

/* Runtime Tcl version, set below */
double pgtcl_tcl_version;

/*
 * Pgtcl_Init
 *	  initialization package for the PGTCL Tcl package
 *
 */

DLLEXPORT int
Pgtcl_Init(Tcl_Interp *interp)
{

	/*
	 * The version required really should be TCL_VERSION, but this
	 * can be compiled under 8.5 with stubs and still mostly works
	 * with a Tcl 8.4 interpreter, so let 8.4 be the minimum version.
	 */
#ifdef USE_TCL_STUBS
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL)
		return TCL_ERROR;
#endif

	/*
	 * Get the Tcl version at runtime, which may differ from the compile-time
	 * version due to use of Tcl stubs. This is used in some commands to
	 * prevent crashes due to missing stubs functions.
	 */
	if (Tcl_GetDouble(interp,
				Tcl_GetVar(interp, "tcl_version", TCL_GLOBAL_ONLY),
				&pgtcl_tcl_version) != TCL_OK)
		pgtcl_tcl_version = 8.4;  /* A reasonable fallback */

	/*
	 * Note: Removed code to set PGCLIENTENCODING=UNICODE if tcl_version >= 8.1.
	 * That did not work for Windows because the libpq DLL didn't see the
	 * environment change. So now this is done when connecting to the database.
	 */

	/* register all pgtcl commands */
	Tcl_CreateObjCommand(interp,
						 "pg_conndefaults",
						 Pg_conndefaults,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_connect",
						 Pg_connect,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_disconnect",
						 Pg_disconnect,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_exec",
						 Pg_exec,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_select",
						 Pg_select,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_result",
						 Pg_result,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_execute",
						 Pg_execute,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_open",
						 Pg_lo_open,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_close",
						 Pg_lo_close,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_read",
						 Pg_lo_read,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_write",
						 Pg_lo_write,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_lseek",
						 Pg_lo_lseek,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_creat",
						 Pg_lo_creat,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_tell",
						 Pg_lo_tell,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_unlink",
						 Pg_lo_unlink,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_import",
						 Pg_lo_import,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_lo_export",
						 Pg_lo_export,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_listen",
						 Pg_listen,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_sendquery",
						 Pg_sendquery,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_sendquery_prepared",
						 Pg_sendquery_prepared,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_sendquery_params",
						 Pg_sendquery_params,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_getresult",
						 Pg_getresult,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_isbusy",
						 Pg_isbusy,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_blocking",
						 Pg_blocking,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						 "pg_cancelrequest",
						 Pg_cancelrequest,
						 (ClientData)NULL,
						 (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_on_connection_loss",
						  Pg_on_connection_loss,
						  (ClientData) NULL, 
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_escape_string",
						  Pg_escape_string,
						  (ClientData) NULL, 
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_quote",
						  Pg_quote,
						  (ClientData) NULL, 
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_escape_bytea",
						  Pg_escape_bytea,
						  (ClientData) NULL, 
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_unescape_bytea",
						  Pg_unescape_bytea,
						  (ClientData) NULL, 
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_transaction_status",
						  Pg_transaction_status,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_parameter_status",
						  Pg_parameter_status,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_exec_prepared",
						  Pg_exec_prepared,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_exec_params",
						  Pg_exec_params,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_notice_handler",
						  Pg_notice_handler,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_result_callback",
						  Pg_result_callback,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

#ifdef HAVE_PQENCRYPTPASSWORD /* PostgreSQL >= 8.2.0 */
	Tcl_CreateObjCommand(interp,
						  "pg_encrypt_password",
						  Pg_encrypt_password,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);
#endif

#ifdef HAVE_LO_TRUNCATE /* PostgreSQL >= 8.3.0 */
	Tcl_CreateObjCommand(interp,
						  "pg_lo_truncate",
						  Pg_lo_truncate,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);
#endif

#ifdef HAVE_PQDESCRIBEPREPARED /* PostgreSQL >= 8.2.0 */
	Tcl_CreateObjCommand(interp,
						  "pg_describe_cursor",
						  Pg_describe_cursor,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_describe_prepared",
						  Pg_describe_prepared,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);
#endif

	Tcl_CreateObjCommand(interp,
						  "pg_backend_pid",
						  Pg_backend_pid,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_server_version",
						  Pg_server_version,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

#ifdef HAVE_LO_TELL64  /* PostgreSQL >= 9.3.0 */
	Tcl_CreateObjCommand(interp,
						  "pg_lo_tell64",
						  Pg_lo_tell64,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_lo_lseek64",
						  Pg_lo_lseek64,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_lo_truncate64",
						  Pg_lo_truncate64,
						  (ClientData) NULL,
						  (Tcl_CmdDeleteProc *) NULL);
#endif

#ifdef HAVE_PQESCAPELITERAL /* PostgreSQL >= 9.0 */
	Tcl_CreateObjCommand(interp,
						  "pg_escape_literal",
						  Pg_escape_l_i,
						  (ClientData) 1,
						  (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand(interp,
						  "pg_escape_identifier",
						  Pg_escape_l_i,
						  (ClientData) 2,
						  (Tcl_CmdDeleteProc *) NULL);
#endif

	/* Note PACKAGE_VERSION (or VERSION) is provided by the TEA Makefile */
#ifndef PACKAGE_VERSION
#ifdef VERSION
#define PACKAGE_VERSION VERSION
#else
#define PACKAGE_VERSION "0.0"
#endif
#endif
	Tcl_PkgProvide(interp, "Pgtcl", PACKAGE_VERSION);

	return TCL_OK;
}

DLLEXPORT int
Pgtcl_SafeInit(Tcl_Interp *interp)
{
	return Pgtcl_Init(interp);
}
