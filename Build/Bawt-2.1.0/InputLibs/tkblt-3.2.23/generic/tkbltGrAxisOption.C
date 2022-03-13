/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1993-2004 George A Howlett.
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

#include <stdlib.h>

#include <cmath>

#include "tkbltGraph.h"
#include "tkbltGrAxis.h"
#include "tkbltGrAxisOption.h"
#include "tkbltConfig.h"
#include "tkbltInt.h"

using namespace Blt;

static Tk_CustomOptionSetProc AxisSetProc;
static Tk_CustomOptionGetProc AxisGetProc;
static Tk_CustomOptionFreeProc AxisFreeProc;
Tk_ObjCustomOption xAxisObjOption =
  {
    "xaxis", AxisSetProc, AxisGetProc, RestoreProc, AxisFreeProc,
    (ClientData)CID_AXIS_X
  };
Tk_ObjCustomOption yAxisObjOption =
  {
    "yaxis", AxisSetProc, AxisGetProc, RestoreProc, AxisFreeProc,
    (ClientData)CID_AXIS_Y
  };

static int AxisSetProc(ClientData clientData, Tcl_Interp* interp,
		       Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
		       int offset, char* savePtr, int flags)
{
  Axis** axisPtrPtr = (Axis**)(widgRec + offset);
  *(double*)savePtr = *(double*)axisPtrPtr;
  
  if (!axisPtrPtr)
    return TCL_OK;

  Graph* graphPtr = getGraphFromWindowData(tkwin);
#ifdef _WIN64
  ClassId classId = (ClassId)((long long)clientData);
#else
  ClassId classId = (ClassId)((long)clientData);
#endif

  Axis *axisPtr;
  if (graphPtr->getAxis(*objPtr, &axisPtr) != TCL_OK)
    return TCL_ERROR;

  if (classId != CID_NONE) {
    // Set the axis type on the first use of it.
    if ((axisPtr->refCount_ == 0) || (axisPtr->classId_ == CID_NONE))
      axisPtr->setClass(classId);

    else if (axisPtr->classId_ != classId) {
      Tcl_AppendResult(interp, "axis \"", Tcl_GetString(*objPtr),
		       "\" is already in use on an opposite ", 
		       axisPtr->className_, "-axis", 
		       NULL);
      return TCL_ERROR;
    }
    axisPtr->refCount_++;
  }

  *axisPtrPtr = axisPtr;
  return TCL_OK;
};

static Tcl_Obj* AxisGetProc(ClientData clientData, Tk_Window tkwin, 
			    char *widgRec, int offset)
{
  Axis* axisPtr = *(Axis**)(widgRec + offset);
  if (!axisPtr)
    return Tcl_NewStringObj("", -1);

  return Tcl_NewStringObj(axisPtr->name_, -1);
};

static void AxisFreeProc(ClientData clientData, Tk_Window tkwin, char *ptr)
{
  Axis* axisPtr = *(Axis**)ptr;
  if (axisPtr) {
    axisPtr->refCount_--;
    if (axisPtr->refCount_ == 0)
      delete axisPtr;
  }
}

static Tk_CustomOptionSetProc LimitSetProc;
static Tk_CustomOptionGetProc LimitGetProc;
Tk_ObjCustomOption limitObjOption =
  {
    "limit", LimitSetProc, LimitGetProc, NULL, NULL, NULL
  };

static int LimitSetProc(ClientData clientData, Tcl_Interp* interp,
			Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			int offset, char* save, int flags)
{
  double* limitPtr = (double*)(widgRec + offset);
  const char* string = Tcl_GetString(*objPtr);
  if (!string || !string[0]) {
    *limitPtr = NAN;
    return TCL_OK;
  }

  if (Tcl_GetDoubleFromObj(interp, *objPtr, limitPtr) != TCL_OK)
    return TCL_ERROR;

  return TCL_OK;
}

static Tcl_Obj* LimitGetProc(ClientData clientData, Tk_Window tkwin, 
			     char *widgRec, int offset)
{
  double limit = *(double*)(widgRec + offset);
  Tcl_Obj* objPtr;

  if (!isnan(limit))
    objPtr = Tcl_NewDoubleObj(limit);
  else
    objPtr = Tcl_NewStringObj("", -1);

  return objPtr;
}

static Tk_CustomOptionSetProc TicksSetProc;
static Tk_CustomOptionGetProc TicksGetProc;
static Tk_CustomOptionFreeProc TicksFreeProc;
Tk_ObjCustomOption ticksObjOption =
  {
    "ticks", TicksSetProc, TicksGetProc, RestoreProc, TicksFreeProc, NULL
  };

static int TicksSetProc(ClientData clientData, Tcl_Interp* interp,
			Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			int offset, char* savePtr, int flags)
{
  Ticks** ticksPtrPtr = (Ticks**)(widgRec + offset);
  *(double*)savePtr = *(double*)ticksPtrPtr;

  if (!ticksPtrPtr)
    return TCL_OK;

  int objc;
  Tcl_Obj** objv;
  if (Tcl_ListObjGetElements(interp, *objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  Ticks* ticksPtr = NULL;
  if (objc > 0) {
    ticksPtr = new Ticks(objc);
    for (int ii=0; ii<objc; ii++) {
      double value;
      if (Tcl_GetDoubleFromObj(interp, objv[ii], &value) != TCL_OK) {
	delete ticksPtr;
	return TCL_ERROR;
      }
      ticksPtr->values[ii] = value;
    }
    ticksPtr->nTicks = objc;
  }

  *ticksPtrPtr = ticksPtr;

  return TCL_OK;
}

static Tcl_Obj* TicksGetProc(ClientData clientData, Tk_Window tkwin, 
			     char *widgRec, int offset)
{
  Ticks* ticksPtr = *(Ticks**)(widgRec + offset);

  if (!ticksPtr)
    return Tcl_NewListObj(0, NULL);

  int cnt = ticksPtr->nTicks;
  Tcl_Obj** ll = new Tcl_Obj*[cnt];
  for (int ii = 0; ii<cnt; ii++)
    ll[ii] = Tcl_NewDoubleObj(ticksPtr->values[ii]);

  Tcl_Obj* listObjPtr = Tcl_NewListObj(cnt, ll);
  delete [] ll;

  return listObjPtr;
}

static void TicksFreeProc(ClientData clientData, Tk_Window tkwin,
			 char *ptr)
{
  Ticks* ticksPtr = *(Ticks**)ptr;
  delete ticksPtr;
}

static Tk_CustomOptionSetProc ObjectSetProc;
static Tk_CustomOptionGetProc ObjectGetProc;
static Tk_CustomOptionFreeProc ObjectFreeProc;
Tk_ObjCustomOption objectObjOption =
  {
    "object", ObjectSetProc, ObjectGetProc, RestoreProc, ObjectFreeProc, NULL,
  };

static int ObjectSetProc(ClientData clientData, Tcl_Interp* interp,
			Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			int offset, char* savePtr, int flags)
{
  Tcl_Obj** objectPtrPtr = (Tcl_Obj**)(widgRec + offset);
  *(double*)savePtr = *(double*)objectPtrPtr;

  if (!objectPtrPtr)
    return TCL_OK;

  Tcl_IncrRefCount(*objPtr);
  *objectPtrPtr = *objPtr;

  return TCL_OK;
}
    
static Tcl_Obj* ObjectGetProc(ClientData clientData, Tk_Window tkwin, 
			      char *widgRec, int offset)
{
  Tcl_Obj** objectPtrPtr = (Tcl_Obj**)(widgRec + offset);

  if (!objectPtrPtr)
    return Tcl_NewObj();

  return *objectPtrPtr;
}

static void ObjectFreeProc(ClientData clientData, Tk_Window tkwin,
			   char *ptr)
{
  Tcl_Obj* objectPtr = *(Tcl_Obj**)ptr;
  if (objectPtr)
    Tcl_DecrRefCount(objectPtr);
}

