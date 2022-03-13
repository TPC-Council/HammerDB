/* $Id$ */

#include "db2tcl.h"
#include "db2tclcmds.h"
#ifdef _WINDOWS
   #include <windows.h>
   #include <tk.h>
   #define PACKAGE "db2tcl"
#endif
   #define PACKAGE_VERSION "2.0.1"

#ifdef _WINDOWS
__declspec( dllexport )
#endif
int Db2tcl_Init(interp)
Tcl_Interp * interp;
{
	 if (Tcl_InitStubs(interp, "8.6", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgRequire(interp, "Tcl", "8.6", 0) == NULL)
    return TCL_ERROR;
  if (Tcl_PkgProvide(interp, "db2tcl" , PACKAGE_VERSION) != TCL_OK)
    return TCL_ERROR;

    /* On Windows initialize default channels to prevent incorrect naming of channels */
#ifdef _WINDOWS
  Tk_InitConsoleChannels(interp);
#endif
    /* register all Db2tcl commands */

    Tcl_CreateCommand (interp, "db2_connect", Db2_connect,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_disconnect", Db2_disconnect,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_exec_direct", Db2_exec_direct,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_exec_prepared", Db2_exec_prepared,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_select_direct", Db2_select_direct,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_select_prepared", Db2_select_prepared,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_prepare", Db2_prepare,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_bind_param", Db2_bind_param,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_bind_exec", Db2_bind_exec,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_fetchrow", Db2_fetchrow,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_finish", Db2_finish,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_getnumrows", Db2_getnumrows,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_begin_transaction", Db2_begin_transaction,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_commit_transaction", Db2_commit_transaction,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2_rollback_transaction", Db2_rollback_transaction,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateCommand (interp, "db2", Db2_db2,
		       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_CreateObjCommand (interp, "db2_test", Db2_test,
                       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);

    Tcl_PkgProvide (interp, "db2tcl", "2.0");

    return TCL_OK;
}

#ifdef __WIN32__
#undef  TCL_STORAGE_CLASS
#define TCL_STORAGE_CLASS  DLLEXPORT
#endif

#ifdef _WINDOWS
__declspec( dllexport )
#endif
int Db2tcl_SafeInit(interp) 
Tcl_Interp * interp;
{
    return Db2tcl_Init (interp);
}
