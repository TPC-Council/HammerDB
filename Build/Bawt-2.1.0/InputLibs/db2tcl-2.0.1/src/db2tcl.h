/* $Id$ */

#ifndef LIBDB2TCL_H
#define LIBDB2TCL_H

#include <tcl.h>

extern int Db_Init(Tcl_Interp *interp);
extern int Db2tcl_Init(Tcl_Interp *interp);
extern int Db_SafeInit(Tcl_Interp *interp);

#endif	 /* LIBDB2TCL_H */
