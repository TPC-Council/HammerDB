/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1993-2004 George A Howlett.
 *
 *	Permission is hereby granted, free of charge, to any person
 *	obtaining a copy of this software and associated documentation
 *	files (the "Software"), to deal in the Software without
 *	restriction, including without limitation the rights to use,
 *	copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the
 *	Software is furnished to do so, subject to the following
 *	conditions:
 *
 *	The above copyright notice and this permission notice shall be
 *	included in all copies or substantial portions of the
 *	Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 *	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 *	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 *	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 *	OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 *	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 *	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "tkbltGraph.h"
#include "tkbltGrHairs.h"
#include "tkbltGrHairsOp.h"

using namespace Blt;

static int CrosshairsObjConfigure(Graph* graphPtr, Tcl_Interp* interp,
				  int objc, Tcl_Obj* const objv[])
{
  Crosshairs* chPtr = graphPtr->crosshairs_;
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)chPtr->ops(), chPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    if (chPtr->configure() != TCL_OK)
      return TCL_ERROR;
    graphPtr->flags |= mask;
    graphPtr->eventuallyRedraw();

    break; 
  }

  if (!error) {
    Tk_FreeSavedOptions(&savedOptions);
    return TCL_OK;
  }
  else {
    Tcl_SetObjResult(interp, errorResult);
    Tcl_DecrRefCount(errorResult);
    return TCL_ERROR;
  }
}

static int CgetOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc != 4) {
    Tcl_WrongNumArgs(interp, 2, objv, "cget option");
    return TCL_ERROR;
  }

  Crosshairs* chPtr = graphPtr->crosshairs_;
  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)chPtr->ops(), 
				      chPtr->optionTable(),
				      objv[3], graphPtr->tkwin_);
  if (objPtr == NULL)
    return TCL_ERROR;
  else
    Tcl_SetObjResult(interp, objPtr);
  return TCL_OK;
}

static int ConfigureOp(ClientData clientData, Tcl_Interp* interp,
		       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Crosshairs* chPtr = graphPtr->crosshairs_;
  if (objc <= 4) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)chPtr->ops(), 
				       chPtr->optionTable(), 
				       (objc == 4) ? objv[3] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return CrosshairsObjConfigure(graphPtr, interp, objc-3, objv+3);
}

static int OnOp(ClientData clientData, Tcl_Interp* interp, 
		int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Crosshairs *chPtr = graphPtr->crosshairs_;

  chPtr->on();

  return TCL_OK;
}

static int OffOp(ClientData clientData, Tcl_Interp* interp,
		 int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Crosshairs *chPtr = graphPtr->crosshairs_;

  chPtr->off();

  return TCL_OK;
}

static int ToggleOp(ClientData clientData, Tcl_Interp* interp,
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Crosshairs *chPtr = graphPtr->crosshairs_;

  if (chPtr->isOn())
    chPtr->off();
  else
    chPtr->on();

  return TCL_OK;
}

const Ensemble Blt::crosshairsEnsemble[] = {
  {"cget", 	CgetOp, 0},
  {"configure",	ConfigureOp, 0},
  {"off",       OffOp, 0},
  {"on",        OnOp, 0},
  {"toggle",    ToggleOp, 0},
  { 0,0,0 }
};
