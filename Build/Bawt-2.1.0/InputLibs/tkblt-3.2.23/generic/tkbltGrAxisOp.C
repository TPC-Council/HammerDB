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

#include <string.h>

#include <cmath>

#include "tkbltGrBind.h"
#include "tkbltGraph.h"
#include "tkbltGrAxis.h"
#include "tkbltGrAxisOp.h"
#include "tkbltGrMisc.h"
#include "tkbltInt.h"

using namespace Blt;

#define EXP10(x)	(pow(10.0,(x)))

static int GetAxisScrollInfo(Tcl_Interp* interp, 
			     int objc, Tcl_Obj* const objv[],
			     double *offsetPtr, double windowSize,
			     double scrollUnits, double scale);

static double Clamp(double x) 
{
  return (x < 0.0) ? 0.0 : (x > 1.0) ? 1.0 : x;
}

int Blt::AxisObjConfigure(Axis* axisPtr, Tcl_Interp* interp,
			  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = axisPtr->graphPtr_;
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)axisPtr->ops(), axisPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    if (axisPtr->configure() != TCL_OK)
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
  if (objc!=5) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId option");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisCgetOp(axisPtr, interp, objc-1, objv+1);
}

static int ConfigureOp(ClientData clientData, Tcl_Interp* interp,
		       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId ?option value?...");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisConfigureOp(axisPtr, interp, objc-1, objv+1);
}

static int ActivateOp(ClientData clientData, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisActivateOp(axisPtr, interp, objc, objv);
}

static int BindOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc == 3) {
    Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&graphPtr->axes_.tagTable, &iter); hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
      char* tagName = (char*)Tcl_GetHashKey(&graphPtr->axes_.tagTable, hPtr);
      Tcl_Obj* objPtr = Tcl_NewStringObj(tagName, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }

    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }
  else
    return graphPtr->bindTable_->configure(graphPtr->axisTag(Tcl_GetString(objv[3])), objc-4, objv+4);
}

static int CreateOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  if (graphPtr->createAxis(objc, objv) != TCL_OK)
    return TCL_ERROR;
  Tcl_SetObjResult(interp, objv[3]);

  return TCL_OK;
}

static int DeleteOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }
    
  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  if (axisPtr->refCount_ == 0)
    delete axisPtr;

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int InvTransformOp(ClientData clientData, Tcl_Interp* interp, 
			  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=5) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId scoord");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisInvTransformOp(axisPtr, interp, objc-1, objv+1);
}

static int LimitsOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisLimitsOp(axisPtr, interp, objc-1, objv+1);
}

static int MarginOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisMarginOp(axisPtr, interp, objc-1, objv+1);
}

static int NamesOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (objc<3) {
    Tcl_WrongNumArgs(interp, 3, objv, "?pattern...?");
    return TCL_ERROR;
  }
  if (objc == 3) {
    Tcl_HashSearch cursor;
    for (Tcl_HashEntry *hPtr = Tcl_FirstHashEntry(&graphPtr->axes_.table, &cursor); hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
      Axis* axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
      Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj(axisPtr->name_, -1));
    }
  } 
  else {
    Tcl_HashSearch cursor;
    for (Tcl_HashEntry *hPtr = Tcl_FirstHashEntry(&graphPtr->axes_.table, &cursor); hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
      Axis* axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
      for (int ii=3; ii<objc; ii++) {
	const char *pattern = (const char*)Tcl_GetString(objv[ii]);
	if (Tcl_StringMatch(axisPtr->name_, pattern)) {
	  Tcl_ListObjAppendElement(interp, listObjPtr, 
				   Tcl_NewStringObj(axisPtr->name_, -1));
	  break;
	}
      }
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);

  return TCL_OK;
}

static int TransformOp(ClientData clientData, Tcl_Interp* interp, 
		       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=5) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId coord");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisTransformOp(axisPtr, interp, objc-1, objv+1);
}

static int TypeOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisTypeOp(axisPtr, interp, objc-1, objv+1);
}

static int ViewOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "axisId");
    return TCL_ERROR;
  }

  Axis* axisPtr;
  if (graphPtr->getAxis(objv[3], &axisPtr) != TCL_OK)
    return TCL_ERROR;

  return AxisViewOp(axisPtr, interp, objc-1, objv+1);
}

const Ensemble Blt::axisEnsemble[] = {
  {"activate",     ActivateOp, 0},
  {"bind",         BindOp, 0},
  {"cget", 	   CgetOp,0 },
  {"configure",    ConfigureOp,0 },
  {"create",       CreateOp, 0},
  {"deactivate",   ActivateOp, 0},
  {"delete",       DeleteOp, 0},
  {"invtransform", InvTransformOp, 0},
  {"limits",       LimitsOp, 0},
  {"margin",       MarginOp, 0},
  {"names",        NamesOp, 0},
  {"transform",    TransformOp, 0},
  {"type",         TypeOp, 0},
  {"view",         ViewOp, 0},
  { 0,0,0 }
};

// Support

double AdjustViewport(double offset, double windowSize)
{
  // Canvas-style scrolling allows the world to be scrolled within the window.
  if (windowSize > 1.0) {
    if (windowSize < (1.0 - offset))
      offset = 1.0 - windowSize;

    if (offset > 0.0)
      offset = 0.0;
  }
  else {
    if ((offset + windowSize) > 1.0)
      offset = 1.0 - windowSize;

    if (offset < 0.0)
      offset = 0.0;
  }
  return offset;
}

static int GetAxisScrollInfo(Tcl_Interp* interp, 
			     int objc, Tcl_Obj* const objv[],
			     double *offsetPtr, double windowSize,
			     double scrollUnits, double scale)
{
  const char *string;
  char c;
  double offset;
  int length;

  offset = *offsetPtr;
  string = Tcl_GetStringFromObj(objv[0], &length);
  c = string[0];
  scrollUnits *= scale;
  if ((c == 's') && (strncmp(string, "scroll", length) == 0)) {
    int count;
    double fract;

    /* Scroll number unit/page */
    if (Tcl_GetIntFromObj(interp, objv[1], &count) != TCL_OK)
      return TCL_ERROR;

    string = Tcl_GetStringFromObj(objv[2], &length);
    c = string[0];
    if ((c == 'u') && (strncmp(string, "units", length) == 0))
      fract = count * scrollUnits;
    else if ((c == 'p') && (strncmp(string, "pages", length) == 0))
      /* A page is 90% of the view-able window. */
      fract = (int)(count * windowSize * 0.9 + 0.5);
    else if ((c == 'p') && (strncmp(string, "pixels", length) == 0))
      fract = count * scale;
    else {
      Tcl_AppendResult(interp, "unknown \"scroll\" units \"", string,
		       "\"", NULL);
      return TCL_ERROR;
    }
    offset += fract;
  } 
  else if ((c == 'm') && (strncmp(string, "moveto", length) == 0)) {
    double fract;

    /* moveto fraction */
    if (Tcl_GetDoubleFromObj(interp, objv[1], &fract) != TCL_OK) {
      return TCL_ERROR;
    }
    offset = fract;
  } 
  else {
    int count;
    double fract;

    /* Treat like "scroll units" */
    if (Tcl_GetIntFromObj(interp, objv[0], &count) != TCL_OK) {
      return TCL_ERROR;
    }
    fract = (double)count * scrollUnits;
    offset += fract;
    /* CHECK THIS: return TCL_OK; */
  }
  *offsetPtr = AdjustViewport(offset, windowSize);
  return TCL_OK;
}

// Common Ops

int AxisCgetOp(Axis* axisPtr, Tcl_Interp* interp, 
	       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = axisPtr->graphPtr_;

  if (objc != 4) {
    Tcl_WrongNumArgs(interp, 2, objv, "cget option");
    return TCL_ERROR;
  }

  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, (char*)axisPtr->ops(),
				      axisPtr->optionTable(),
				      objv[3], graphPtr->tkwin_);
  if (!objPtr)
    return TCL_ERROR;
  else
    Tcl_SetObjResult(interp, objPtr);
  return TCL_OK;
}

int AxisConfigureOp(Axis* axisPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = axisPtr->graphPtr_;

  if (objc <= 4) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)axisPtr->ops(), 
				       axisPtr->optionTable(), 
				       (objc == 4) ? objv[3] : NULL, 
				       graphPtr->tkwin_);
    if (!objPtr)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return AxisObjConfigure(axisPtr, interp, objc-3, objv+3);
}

int AxisActivateOp(Axis* axisPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  AxisOptions* ops = (AxisOptions*)axisPtr->ops();
  Graph* graphPtr = axisPtr->graphPtr_;
  const char *string;

  string = Tcl_GetString(objv[2]);
  axisPtr->active_ = (string[0] == 'a') ? 1 : 0;

  if (!ops->hide && axisPtr->use_) {
    graphPtr->flags |= RESET;
    graphPtr->eventuallyRedraw();
  }

  return TCL_OK;
}

int AxisInvTransformOp(Axis* axisPtr, Tcl_Interp* interp, 
		       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = axisPtr->graphPtr_;

  if (graphPtr->flags & RESET)
    graphPtr->resetAxes();

  int sy;
  if (Tcl_GetIntFromObj(interp, objv[3], &sy) != TCL_OK)
    return TCL_ERROR;

  // Is the axis vertical or horizontal?
  // Check the site where the axis was positioned.  If the axis is
  // virtual, all we have to go on is how it was mapped to an
  // element (using either -mapx or -mapy options).  
  double y = axisPtr->isHorizontal() ? 
    axisPtr->invHMap(sy) : axisPtr->invVMap(sy);

  Tcl_SetDoubleObj(Tcl_GetObjResult(interp), y);
  return TCL_OK;
}

int AxisLimitsOp(Axis* axisPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  AxisOptions* ops = (AxisOptions*)axisPtr->ops();
  Graph* graphPtr = axisPtr->graphPtr_;

  if (graphPtr->flags & RESET)
    graphPtr->resetAxes();

  double min, max;
  if (ops->logScale) {
    min = EXP10(axisPtr->axisRange_.min);
    max = EXP10(axisPtr->axisRange_.max);
  } 
  else {
    min = axisPtr->axisRange_.min;
    max = axisPtr->axisRange_.max;
  }

  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(min));
  Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(max));

  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

int AxisMarginOp(Axis* axisPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  const char *marginName = "";
  if (axisPtr->use_)
    marginName = axisNames[axisPtr->margin_].name;

  Tcl_SetStringObj(Tcl_GetObjResult(interp), marginName, -1);
  return TCL_OK;
}

int AxisTransformOp(Axis* axisPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = axisPtr->graphPtr_;

  if (graphPtr->flags & RESET)
    graphPtr->resetAxes();

  double x;
  if (Tcl_GetDoubleFromObj(interp, objv[3], &x) != TCL_OK)
    return TCL_ERROR;

  if (axisPtr->isHorizontal())
    x = axisPtr->hMap(x);
  else
    x = axisPtr->vMap(x);

  Tcl_SetIntObj(Tcl_GetObjResult(interp), (int)x);
  return TCL_OK;
}

int AxisTypeOp(Axis* axisPtr, Tcl_Interp* interp, 
	       int objc, Tcl_Obj* const objv[])
{
  const char* typeName = "";
  if (axisPtr->use_) {
    switch (axisPtr->classId_) {
    case CID_AXIS_X:
      typeName = "x";
      break;
    case CID_AXIS_Y:
      typeName = "y";
      break;
    default:
      return TCL_OK;
    }
  }

  Tcl_SetStringObj(Tcl_GetObjResult(interp), typeName, -1);
  return TCL_OK;
}

int AxisViewOp(Axis* axisPtr, Tcl_Interp* interp, 
	       int objc, Tcl_Obj* const objv[])
{
  AxisOptions* ops = (AxisOptions*)axisPtr->ops();
  Graph* graphPtr = axisPtr->graphPtr_;
  double worldMin = axisPtr->valueRange_.min;
  double worldMax = axisPtr->valueRange_.max;
  /* Override data dimensions with user-selected limits. */
  if (!isnan(axisPtr->scrollMin_))
    worldMin = axisPtr->scrollMin_;

  if (!isnan(axisPtr->scrollMax_))
    worldMax = axisPtr->scrollMax_;

  double viewMin = axisPtr->min_;
  double viewMax = axisPtr->max_;
  /* Bound the view within scroll region. */ 
  if (viewMin < worldMin)
    viewMin = worldMin;

  if (viewMax > worldMax)
    viewMax = worldMax;

  if (ops->logScale) {
    worldMin = log10(worldMin);
    worldMax = log10(worldMax);
    viewMin  = log10(viewMin);
    viewMax  = log10(viewMax);
  }
  double worldWidth = worldMax - worldMin;
  double viewWidth  = viewMax - viewMin;

  /* Unlike horizontal axes, vertical axis values run opposite of the
   * scrollbar first/last values.  So instead of pushing the axis minimum
   * around, we move the maximum instead. */
  double axisOffset;
  double axisScale;
  if (axisPtr->isHorizontal() != ops->descending) {
    axisOffset  = viewMin - worldMin;
    axisScale = graphPtr->hScale_;
  } else {
    axisOffset  = worldMax - viewMax;
    axisScale = graphPtr->vScale_;
  }
  if (objc == 4) {
    double first = Clamp(axisOffset / worldWidth);
    double last = Clamp((axisOffset + viewWidth) / worldWidth);
    Tcl_Obj *listObjPtr = Tcl_NewListObj(0, NULL);
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(first));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(last));
    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }
  double fract = axisOffset / worldWidth;
  if (GetAxisScrollInfo(interp, objc, objv, &fract, viewWidth / worldWidth, 
			ops->scrollUnits, axisScale) != TCL_OK)
    return TCL_ERROR;

  if (axisPtr->isHorizontal() != ops->descending) {
    ops->reqMin = (fract * worldWidth) + worldMin;
    ops->reqMax = ops->reqMin + viewWidth;
  }
  else {
    ops->reqMax = worldMax - (fract * worldWidth);
    ops->reqMin = ops->reqMax - viewWidth;
  }
  if (ops->logScale) {
    ops->reqMin = EXP10(ops->reqMin);
    ops->reqMax = EXP10(ops->reqMax);
  }

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

