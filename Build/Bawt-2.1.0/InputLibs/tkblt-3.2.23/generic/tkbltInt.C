/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1991-2004 George A Howlett.
 *
 *	Permission is hereby granted, free of charge, to any person obtaining
 *	a copy of this software and associated documentation files (the
 *	"Software"), to deal in the Software without restriction, including
 *	without limitation the rights to use, copy, modify, merge, publish,
 *	distribute, sublicense, and/or sell copies of the Software, and to
 *	permit persons to whom the Software is furnished to do so, subject to
 *	the following conditions:
 *
 *	The above copyright notice and this permission notice shall be
 *	included in all copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <tk.h>
#include <iostream>
using namespace std;

extern "C" {
DLLEXPORT Tcl_AppInitProc Tkblt_Init;
DLLEXPORT Tcl_AppInitProc Tkblt_SafeInit;
};

Tcl_AppInitProc Blt_VectorCmdInitProc;
Tcl_AppInitProc Blt_GraphCmdInitProc;

#include "tkbltStubInit.c"

DLLEXPORT int Tkblt_Init(Tcl_Interp* interp)
{
  Tcl_Namespace *nsPtr;

  if (Tcl_InitStubs(interp, TCL_PATCH_LEVEL, 0) == NULL)
    return TCL_ERROR;
  if (Tk_InitStubs(interp, TK_PATCH_LEVEL, 0) == NULL)
    return TCL_ERROR;

  nsPtr = Tcl_FindNamespace(interp, "::blt", (Tcl_Namespace *)NULL, 0);
  if (nsPtr == NULL) {
    nsPtr = Tcl_CreateNamespace(interp, "::blt", NULL, NULL);
    if (nsPtr == NULL)
      return TCL_ERROR;
  }

  if (Blt_VectorCmdInitProc(interp) != TCL_OK)
    return TCL_ERROR;
  if (Blt_GraphCmdInitProc(interp) != TCL_OK)
    return TCL_ERROR;

  if (Tcl_PkgProvideEx(interp, PACKAGE_NAME, PACKAGE_VERSION, (ClientData)&tkbltStubs) != TCL_OK)
    return TCL_ERROR;

  return TCL_OK;
}

DLLEXPORT int Tkblt_SafeInit(Tcl_Interp* interp)
{
  return Tkblt_Init(interp);
}
