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
#include "tkbltConfig.h"

using namespace Blt;

static Tk_CustomOptionSetProc PenSetProc;
static Tk_CustomOptionGetProc PenGetProc;
static Tk_CustomOptionFreeProc PenFreeProc;
Tk_ObjCustomOption penObjOption =
  {
    "pen", PenSetProc, PenGetProc, RestoreProc, PenFreeProc, NULL
  };

static int PenSetProc(ClientData clientData, Tcl_Interp* interp,
		      Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
		      int offset, char* savePtr, int flags)
{
  Pen** penPtrPtr = (Pen**)(widgRec + offset);
  *(double*)savePtr = *(double*)penPtrPtr;
  
  if (!penPtrPtr)
    return TCL_OK;

  const char* string = Tcl_GetString(*objPtr);
  if (!string || !string[0]) {
    *penPtrPtr = NULL;
    return TCL_OK;
  }

  Graph* graphPtr = getGraphFromWindowData(tkwin);
  Pen* penPtr;
  if (graphPtr->getPen(*objPtr, &penPtr) != TCL_OK)
    return TCL_ERROR;

  penPtr->refCount_++;
  *penPtrPtr = penPtr;

  return TCL_OK;
};

static Tcl_Obj* PenGetProc(ClientData clientData, Tk_Window tkwin, 
			   char *widgRec, int offset)
{
  Pen* penPtr = *(Pen**)(widgRec + offset);
  if (!penPtr)
    return Tcl_NewStringObj("", -1);

  return Tcl_NewStringObj(penPtr->name_, -1);
};

static void PenFreeProc(ClientData clientData, Tk_Window tkwin, char *ptr)
{
  Pen* penPtr = *(Pen**)ptr;
  if (penPtr)
    if (penPtr->refCount_ > 0)
      penPtr->refCount_--;
}


