/* 
 * oratcl.h
 *
 * Declarations of externally-visible parts of the Oratcl package.
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef _ORATCL_H
#define _ORATCL_H

#include <tcl.h>

#ifndef _STDIO_H
#include <stdio.h>
#endif

/* prototypes for TCL visible functions */

extern Tcl_ObjCmdProc  Oratcl_Logon;
extern Tcl_ObjCmdProc  Oratcl_Logoff;
extern Tcl_ObjCmdProc  Oratcl_Commit;
extern Tcl_ObjCmdProc  Oratcl_Roll;
extern Tcl_ObjCmdProc  Oratcl_Autocom;
extern Tcl_ObjCmdProc  Oratcl_Lda_List;
extern Tcl_ObjCmdProc  Oratcl_Info;
extern Tcl_ObjCmdProc  Oratcl_Describe;

extern Tcl_ObjCmdProc  Oratcl_Open;
extern Tcl_ObjCmdProc  Oratcl_Close;

extern Tcl_ObjCmdProc  Oratcl_Config;
extern Tcl_ObjCmdProc  Oratcl_Cols;
extern Tcl_ObjCmdProc  Oratcl_Stm_List;

extern Tcl_ObjCmdProc  Oratcl_Parse;
extern Tcl_ObjCmdProc  Oratcl_Bind;
extern Tcl_ObjCmdProc  Oratcl_Exec;
extern Tcl_ObjCmdProc  Oratcl_Fetch;
extern Tcl_ObjCmdProc  Oratcl_Break;

extern Tcl_ObjCmdProc  Oratcl_Sql;
extern Tcl_ObjCmdProc  Oratcl_Bindexec;
extern Tcl_ObjCmdProc  Oratcl_PLexec;

extern Tcl_ObjCmdProc  Oratcl_LongRead;
extern Tcl_ObjCmdProc  Oratcl_LongWrite;

extern Tcl_ObjCmdProc  Oratcl_Message;

#endif /* _ORATCL_H */
