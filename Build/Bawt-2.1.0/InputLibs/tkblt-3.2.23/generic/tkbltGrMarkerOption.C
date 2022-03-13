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
#include <string.h>
#include <float.h>

#include "tkbltGrMarker.h"
#include "tkbltGrMarkerOption.h"
#include "tkbltConfig.h"

using namespace Blt;

static Tcl_Obj* PrintCoordinate(double x);
static int GetCoordinate(Tcl_Interp* interp, Tcl_Obj *objPtr, double *valuePtr);

static Tk_CustomOptionSetProc CoordsSetProc;
static Tk_CustomOptionGetProc CoordsGetProc;
static Tk_CustomOptionFreeProc CoordsFreeProc;
Tk_ObjCustomOption coordsObjOption =
  {
    "coords", CoordsSetProc, CoordsGetProc, RestoreProc, CoordsFreeProc, NULL
  };

static int CoordsSetProc(ClientData clientData, Tcl_Interp* interp,
			 Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			 int offset, char* savePtr, int flags)
{
  Coords** coordsPtrPtr = (Coords**)(widgRec + offset);
  *(double*)savePtr = *(double*)coordsPtrPtr;

  if (!coordsPtrPtr)
    return TCL_OK;

  int objc;
  Tcl_Obj** objv;
  if (Tcl_ListObjGetElements(interp, *objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  if (objc == 0) {
    *coordsPtrPtr = NULL;
    return TCL_OK;
  }

  if (objc & 1) {
    Tcl_AppendResult(interp, "odd number of marker coordinates specified",NULL);
    return TCL_ERROR;
  }

  Coords* coordsPtr = new Coords;
  coordsPtr->num = objc/2;
  coordsPtr->points = new Point2d[coordsPtr->num];

  Point2d* pp = coordsPtr->points;
  for (int ii=0; ii<objc; ii+=2) {
    double x, y;
    if ((GetCoordinate(interp, objv[ii], &x) != TCL_OK) ||
	(GetCoordinate(interp, objv[ii+1], &y) != TCL_OK))
      return TCL_ERROR;
    pp->x = x;
    pp->y = y;
    pp++;
  }

  *coordsPtrPtr = coordsPtr;
  return TCL_OK;
}

static Tcl_Obj* CoordsGetProc(ClientData clientData, Tk_Window tkwin, 
			      char *widgRec, int offset)
{
  Coords* coordsPtr = *(Coords**)(widgRec + offset);

  if (!coordsPtr)
    return Tcl_NewListObj(0, NULL);

  int cnt = coordsPtr->num*2;
  Tcl_Obj** ll = new Tcl_Obj*[cnt];

  Point2d* pp = coordsPtr->points;
  for (int ii=0; ii<cnt; pp++) {
    ll[ii++] = PrintCoordinate(pp->x);
    ll[ii++] = PrintCoordinate(pp->y);
  }

  Tcl_Obj* listObjPtr = Tcl_NewListObj(cnt, ll);
  delete [] ll;
  return listObjPtr;
}

static void CoordsFreeProc(ClientData clientData, Tk_Window tkwin,
			   char *ptr)
{
  Coords* coordsPtr = *(Coords**)ptr;
  if (coordsPtr) {
    delete [] coordsPtr->points;
    delete coordsPtr;
  }
}

static Tk_CustomOptionSetProc CapStyleSetProc;
static Tk_CustomOptionGetProc CapStyleGetProc;
Tk_ObjCustomOption capStyleObjOption =
  {
    "capStyle", CapStyleSetProc, CapStyleGetProc, NULL, NULL, NULL
  };

static int CapStyleSetProc(ClientData clientData, Tcl_Interp* interp,
			   Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			   int offset, char* save, int flags)
{
  int* ptr = (int*)(widgRec + offset);

  Tk_Uid uid = Tk_GetUid(Tcl_GetString(*objPtr));
  int cap;
  if (Tk_GetCapStyle(interp, uid, &cap) != TCL_OK)
    return TCL_ERROR;
  *ptr = cap;

  return TCL_OK;
}

static Tcl_Obj* CapStyleGetProc(ClientData clientData, Tk_Window tkwin, 
			      char *widgRec, int offset)
{
  int* ptr = (int*)(widgRec + offset);
  return Tcl_NewStringObj(Tk_NameOfCapStyle(*ptr), -1);
}

static Tk_CustomOptionSetProc JoinStyleSetProc;
static Tk_CustomOptionGetProc JoinStyleGetProc;
Tk_ObjCustomOption joinStyleObjOption =
  {
    "joinStyle", JoinStyleSetProc, JoinStyleGetProc, NULL, NULL, NULL
  };

static int JoinStyleSetProc(ClientData clientData, Tcl_Interp* interp,
			   Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
			   int offset, char* save, int flags)
{
  int* ptr = (int*)(widgRec + offset);

  Tk_Uid uid = Tk_GetUid(Tcl_GetString(*objPtr));
  int join;
  if (Tk_GetJoinStyle(interp, uid, &join) != TCL_OK)
    return TCL_ERROR;
  *ptr = join;

  return TCL_OK;
}

static Tcl_Obj* JoinStyleGetProc(ClientData clientData, Tk_Window tkwin, 
			      char *widgRec, int offset)
{
  int* ptr = (int*)(widgRec + offset);
  return Tcl_NewStringObj(Tk_NameOfJoinStyle(*ptr), -1);
}

static Tcl_Obj* PrintCoordinate(double x)
{
  if (x == DBL_MAX)
    return Tcl_NewStringObj("+Inf", -1);
  else if (x == -DBL_MAX)
    return Tcl_NewStringObj("-Inf", -1);
  else
    return Tcl_NewDoubleObj(x);
}

static int GetCoordinate(Tcl_Interp* interp, Tcl_Obj *objPtr, double *valuePtr)
{
  const char* expr = Tcl_GetString(objPtr);
  char c = expr[0];
  if ((c == 'I') && (strcmp(expr, "Inf") == 0))
    *valuePtr = DBL_MAX;		/* Elastic upper bound */
  else if ((c == '-') && (expr[1] == 'I') && (strcmp(expr, "-Inf") == 0))
    *valuePtr = -DBL_MAX;		/* Elastic lower bound */
  else if ((c == '+') && (expr[1] == 'I') && (strcmp(expr, "+Inf") == 0))
    *valuePtr = DBL_MAX;		/* Elastic upper bound */
  else if (Tcl_GetDoubleFromObj(interp, objPtr, valuePtr) != TCL_OK)
    return TCL_ERROR;

  return TCL_OK;
}
