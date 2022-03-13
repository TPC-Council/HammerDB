/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1996-2004 George A Howlett.
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

#include "tkbltGraph.h"
#include "tkbltGrPen.h"
#include "tkbltGrPenOp.h"
#include "tkbltGrPenLine.h"
#include "tkbltGrPenBar.h"

using namespace Blt;

int Blt::PenObjConfigure(Graph* graphPtr, Pen* penPtr, 
			 Tcl_Interp* interp, 
			 int objc, Tcl_Obj* const objv[])
{
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)penPtr->ops(), penPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    if (penPtr->configure() != TCL_OK)
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
  if (objc != 5) {
    Tcl_WrongNumArgs(interp, 3, objv, "cget option");
    return TCL_ERROR;
  }

  Pen* penPtr;
  if (graphPtr->getPen(objv[3], &penPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)penPtr->ops(), 
				      penPtr->optionTable(),
				      objv[4], graphPtr->tkwin_);
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
  if (objc<4)
    return TCL_ERROR;

  Pen* penPtr;
  if (graphPtr->getPen(objv[3], &penPtr) != TCL_OK)
    return TCL_ERROR;

  if (objc <= 5) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)penPtr->ops(), 
				       penPtr->optionTable(), 
				       (objc == 5) ? objv[4] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return PenObjConfigure(graphPtr, penPtr, interp, objc-4, objv+4);
}

static int CreateOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<4)
    return TCL_ERROR;

  if (graphPtr->createPen(Tcl_GetString(objv[3]), objc, objv) != TCL_OK)
    return TCL_ERROR;
  Tcl_SetObjResult(interp, objv[3]);

  return TCL_OK;
}

static int DeleteOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<4)
    return TCL_ERROR;
    
  Pen* penPtr;
  if (graphPtr->getPen(objv[3], &penPtr) != TCL_OK)
    return TCL_ERROR;

  if (penPtr->refCount_ == 0)
    delete penPtr;

  return TCL_OK;
}

static int NamesOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (objc == 3) {
    Tcl_HashSearch iter;
    for (Tcl_HashEntry *hPtr=Tcl_FirstHashEntry(&graphPtr->penTable_, &iter);
	 hPtr; hPtr=Tcl_NextHashEntry(&iter)) {
      Pen* penPtr = (Pen*)Tcl_GetHashValue(hPtr);
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewStringObj(penPtr->name_, -1));
    }
  } 
  else {
    Tcl_HashSearch iter;
    for (Tcl_HashEntry *hPtr=Tcl_FirstHashEntry(&graphPtr->penTable_, &iter);
	 hPtr; hPtr=Tcl_NextHashEntry(&iter)) {
      Pen* penPtr = (Pen*)Tcl_GetHashValue(hPtr);
      for (int ii=3; ii<objc; ii++) {
	char *pattern = Tcl_GetString(objv[ii]);
	if (Tcl_StringMatch(penPtr->name_, pattern)) {
	  Tcl_ListObjAppendElement(interp, listObjPtr, 
				   Tcl_NewStringObj(penPtr->name_, -1));
	  break;
	}
      }
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

static int TypeOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<4)
    return TCL_ERROR;

  Pen* penPtr;
  if (graphPtr->getPen(objv[3], &penPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_SetStringObj(Tcl_GetObjResult(interp), penPtr->typeName(), -1);
  return TCL_OK;
}

const Ensemble Blt::penEnsemble[] = {
  {"cget",      CgetOp, 0},
  {"configure", ConfigureOp, 0},
  {"create",    CreateOp, 0},
  {"delete",    DeleteOp, 0},
  {"names",     NamesOp, 0},
  {"type",      TypeOp, 0},
  { 0,0,0 }
};

