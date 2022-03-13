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

#include "tkbltGraph.h"
#include "tkbltGrBind.h"
#include "tkbltGrXAxisOp.h"
#include "tkbltGrAxis.h"
#include "tkbltGrAxisOp.h"

using namespace Blt;

static Axis* GetAxisFromCmd(ClientData clientData, Tcl_Obj* obj)
{
  Graph* graphPtr = (Graph*)clientData;
  GraphOptions* ops = (GraphOptions*)graphPtr->ops_;

  int margin;
  const char* name = Tcl_GetString(obj);
  if (!strcmp(name,"xaxis"))
    margin = (ops->inverted) ? MARGIN_LEFT : MARGIN_BOTTOM;
  else if (!strcmp(name,"yaxis"))
    margin = (ops->inverted) ? MARGIN_BOTTOM : MARGIN_LEFT;
  else if (!strcmp(name,"x2axis"))
    margin = (ops->inverted) ? MARGIN_RIGHT : MARGIN_TOP;
  else if (!strcmp(name,"y2axis"))
    margin = (ops->inverted) ? MARGIN_TOP : MARGIN_RIGHT;
  else
    return NULL;

  ChainLink* link = Chain_FirstLink(ops->margins[margin].axes);
  return (Axis*)Chain_GetValue(link);
}

static int CgetOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisCgetOp(axisPtr, interp, objc, objv);
}

static int ConfigureOp(ClientData clientData, Tcl_Interp* interp,
		       int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisConfigureOp(axisPtr, interp, objc, objv);
}

static int ActivateOp(ClientData clientData, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisActivateOp(axisPtr, interp, objc, objv);
}

static int BindOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return graphPtr->bindTable_->configure(graphPtr->axisTag(axisPtr->name_), objc-3, objv+3);
}

static int InvTransformOp(ClientData clientData, Tcl_Interp* interp, 
			  int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisInvTransformOp(axisPtr, interp, objc, objv);
}

static int LimitsOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisLimitsOp(axisPtr, interp, objc, objv);
}

static int TransformOp(ClientData clientData, Tcl_Interp* interp, 
		       int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisTransformOp(axisPtr, interp, objc, objv);
}

static int UseOp(ClientData clientData, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  GraphOptions* ops = (GraphOptions*)graphPtr->ops_;

  int margin;
  ClassId classId;
  const char* name = Tcl_GetString(objv[1]);
  if (!strcmp(name,"xaxis")) {
    classId = CID_AXIS_X;
    margin = (ops->inverted) ? MARGIN_LEFT : MARGIN_BOTTOM;
  }
  else if (!strcmp(name,"yaxis")) {
    classId = CID_AXIS_Y;
    margin = (ops->inverted) ? MARGIN_BOTTOM : MARGIN_LEFT;
  }
  else if (!strcmp(name,"x2axis")) {
    classId = CID_AXIS_X;
    margin = (ops->inverted) ? MARGIN_RIGHT : MARGIN_TOP;
  }
  else if (!strcmp(name,"y2axis")) {
    classId = CID_AXIS_Y;
    margin = (ops->inverted) ? MARGIN_TOP : MARGIN_RIGHT;
  }
  else
    return TCL_ERROR;

  Chain* chain = ops->margins[margin].axes;

  if (objc == 3) {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    for (ChainLink* link = Chain_FirstLink(chain); link;
	 link = Chain_NextLink(link)) {
      Axis* axisPtr = (Axis*)Chain_GetValue(link);
      Tcl_ListObjAppendElement(interp, listObjPtr,
			       Tcl_NewStringObj(axisPtr->name_, -1));
    }
    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }

  int axisObjc;  
  Tcl_Obj **axisObjv;
  if (Tcl_ListObjGetElements(interp, objv[3], &axisObjc, &axisObjv) != TCL_OK)
    return TCL_ERROR;

  for (ChainLink* link = Chain_FirstLink(chain); link;
       link = Chain_NextLink(link)) {
    Axis* axisPtr = (Axis*)Chain_GetValue(link);
    axisPtr->link = NULL;
    axisPtr->use_ =0;
    axisPtr->margin_ = MARGIN_NONE;
    // Clear the axis type if it's not currently used
    if (axisPtr->refCount_ == 0)
      axisPtr->setClass(CID_NONE);
  }

  chain->reset();
  for (int ii=0; ii<axisObjc; ii++) {
    Axis* axisPtr;
    if (graphPtr->getAxis(axisObjv[ii], &axisPtr) != TCL_OK)
      return TCL_ERROR;

    if (axisPtr->classId_ == CID_NONE)
      axisPtr->setClass(classId);
    else if (axisPtr->classId_ != classId) {
      Tcl_AppendResult(interp, "wrong type axis \"", 
		       axisPtr->name_, "\": can't use ", 
		       axisPtr->className_, " type axis.", NULL); 
      return TCL_ERROR;
    }
    if (axisPtr->link) {
      // Move the axis from the old margin's "use" list to the new
      axisPtr->chain->unlinkLink(axisPtr->link);
      chain->linkAfter(axisPtr->link, NULL);
    }
    else
      axisPtr->link = chain->append(axisPtr);

    axisPtr->chain = chain;
    axisPtr->use_ =1;
    axisPtr->margin_ = margin;
  }

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int ViewOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Axis* axisPtr = GetAxisFromCmd(clientData, objv[1]);
  return AxisViewOp(axisPtr, interp, objc, objv);
}

const Ensemble Blt::xaxisEnsemble[] = {
  {"activate",     ActivateOp, 0},
  {"bind",         BindOp, 0},
  {"cget",         CgetOp, 0},
  {"configure",    ConfigureOp, 0},
  {"deactivate",   ActivateOp, 0},
  {"invtransform", InvTransformOp, 0},
  {"limits",       LimitsOp, 0},
  {"transform",    TransformOp, 0},
  {"use",          UseOp, 0},
  {"view",         ViewOp, 0},
  { 0,0,0 }
};
