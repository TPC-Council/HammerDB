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

#include "tkbltGrBind.h"
#include "tkbltGraph.h"
#include "tkbltGrElem.h"
#include "tkbltGrMarkerOp.h"
#include "tkbltGrMarker.h"
#include "tkbltGrMarkerLine.h"
#include "tkbltGrMarkerPolygon.h"
#include "tkbltGrMarkerText.h"

using namespace Blt;

static int GetMarkerFromObj(Tcl_Interp* interp, Graph* graphPtr, 
			    Tcl_Obj* objPtr, Marker** markerPtrPtr);

#define FIND_ENCLOSED	 (1<<0)
#define FIND_OVERLAPPING (1<<1)

static int MarkerObjConfigure( Graph* graphPtr,Marker* markerPtr,
			       Tcl_Interp* interp, 
			       int objc, Tcl_Obj* const objv[])
{
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)markerPtr->ops(), 
			markerPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    markerPtr->flags |= MAP_ITEM;
    if (markerPtr->configure() != TCL_OK)
      return TCL_ERROR;

    MarkerOptions* ops = (MarkerOptions*)markerPtr->ops();
    if (ops->drawUnder)
      graphPtr->flags |= CACHE;
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

static int CreateMarker(Graph* graphPtr, Tcl_Interp* interp, 
			int objc, Tcl_Obj* const objv[])
{
  int offset = 5;
  const char* name =NULL;
  ostringstream str;
  if (objc == 4) {
    offset = 4;
    str << "marker" << graphPtr->nextMarkerId_++ << ends;
    name = dupstr(str.str().c_str());
  }
  else {
    name = dupstr(Tcl_GetString(objv[4]));
    if (name[0] == '-') {
      delete [] name;
      offset = 4;
      str << "marker" << graphPtr->nextMarkerId_++ << ends;
      name = dupstr(str.str().c_str());
    }
  }

  int isNew;
  Tcl_HashEntry* hPtr =
    Tcl_CreateHashEntry(&graphPtr->markers_.table, name, &isNew);
  if (!isNew) {
    Tcl_AppendResult(graphPtr->interp_, "marker \"", name,
		     "\" already exists in \"", Tcl_GetString(objv[0]),
		     "\"", NULL);
    delete [] name;
    return TCL_ERROR;
  }

  const char* type = Tcl_GetString(objv[3]);
  Marker* markerPtr;
  if (!strcmp(type, "line"))
    markerPtr = new LineMarker(graphPtr, name, hPtr);
  else if (!strcmp(type, "polygon"))
    markerPtr = new PolygonMarker(graphPtr, name, hPtr);
  else if (!strcmp(type, "text"))
    markerPtr = new TextMarker(graphPtr, name, hPtr);
  else {
    Tcl_DeleteHashEntry(hPtr);
    delete [] name;
    Tcl_AppendResult(interp, "unknown marker type ", type, NULL);
    return TCL_ERROR;
  }

  Tcl_SetHashValue(hPtr, markerPtr);

  if ((Tk_InitOptions(graphPtr->interp_, (char*)markerPtr->ops(), markerPtr->optionTable(), graphPtr->tkwin_) != TCL_OK) || (MarkerObjConfigure(graphPtr, markerPtr, interp, objc-offset, objv+offset) != TCL_OK)) {
    delete markerPtr;
    delete [] name;
    return TCL_ERROR;
  }

  // Unlike elements, new markers are drawn on top of old markers
  markerPtr->link = graphPtr->markers_.displayList->prepend(markerPtr);

  Tcl_SetStringObj(Tcl_GetObjResult(interp), name, -1);

  delete [] name;
  return TCL_OK;
}

static int CgetOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=5) {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId option");
    return TCL_ERROR;
  }

  Marker* markerPtr;
  if (GetMarkerFromObj(interp, graphPtr, objv[3], &markerPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)markerPtr->ops(), 
				      markerPtr->optionTable(),
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
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId ?option value...?");
    return TCL_ERROR;
  }

  Marker* markerPtr;
  if (GetMarkerFromObj(interp, graphPtr, objv[3], &markerPtr) != TCL_OK)
    return TCL_ERROR;

  if (objc <= 5) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)markerPtr->ops(), 
				       markerPtr->optionTable(), 
				       (objc == 5) ? objv[4] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return MarkerObjConfigure(graphPtr, markerPtr, interp, objc-4, objv+4);
}

static int BindOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc == 3) {
    Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hp = 
	   Tcl_FirstHashEntry(&graphPtr->markers_.tagTable, &iter); 
	 hp; hp = Tcl_NextHashEntry(&iter)) {

      const char* tag = 
	(const char*)Tcl_GetHashKey(&graphPtr->markers_.tagTable, hp);
      Tcl_Obj* objPtr = Tcl_NewStringObj(tag, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }
    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  } else if (objc >= 4) {
    return graphPtr->bindTable_->configure(graphPtr->markerTag(Tcl_GetString(objv[3])), objc - 4, objv + 4);
  } else {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId ?tag? ?sequence? ?command?");
    return TCL_ERROR;
  }
}

static int CreateOp(ClientData clientData, Tcl_Interp* interp,
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 2, objv, "markerId ?type? ?option value...?");
    return TCL_ERROR;
  }
  if (CreateMarker(graphPtr, interp, objc, objv) != TCL_OK)
    return TCL_ERROR;
  // set in CreateMarker
  // Tcl_SetObjResult(interp, objv[3]);

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int DeleteOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc<4) {
    Tcl_WrongNumArgs(interp, 2, objv, "markerId...");
    return TCL_ERROR;
  }

  int res = TCL_OK;

  for (int ii=3; ii<objc; ii++) {
    Marker* markerPtr;
    const char* string = Tcl_GetString(objv[ii]);
    Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&graphPtr->markers_.table, string);
    if (!hPtr) {
      if (res == TCL_OK) {
	Tcl_AppendResult(interp, "can't find markers in \"",
			 Tk_PathName(graphPtr->tkwin_), "\":", NULL);
      }
      Tcl_AppendResult(interp, " ", Tcl_GetString(objv[ii]), NULL);
      res = TCL_ERROR;
    } else {
      markerPtr = (Marker*)Tcl_GetHashValue(hPtr);
      delete markerPtr;
    }
  }

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return res;
}

static int ExistsOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId");
    return TCL_ERROR;
  }

  Tcl_HashEntry* hPtr =
    Tcl_FindHashEntry(&graphPtr->markers_.table, Tcl_GetString(objv[3]));
  Tcl_SetBooleanObj(Tcl_GetObjResult(interp), (hPtr != NULL));

  return TCL_OK;
}

static int FindOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=8) {
    Tcl_WrongNumArgs(interp, 3, objv, "searchtype left top right bottom");
    return TCL_ERROR;
  }

  const char* string = Tcl_GetString(objv[3]);
  int mode;
  if (strcmp(string, "enclosed") == 0)
    mode = FIND_ENCLOSED;
  else if (strcmp(string, "overlapping") == 0)
    mode = FIND_OVERLAPPING;
  else {
    Tcl_AppendResult(interp, "bad search type \"", string, 
		     ": should be \"enclosed\", or \"overlapping\"",
		     NULL);
    return TCL_ERROR;
  }

  int left, right, top, bottom;
  if ((Tcl_GetIntFromObj(interp, objv[4], &left) != TCL_OK) ||
      (Tcl_GetIntFromObj(interp, objv[5], &top) != TCL_OK) ||
      (Tcl_GetIntFromObj(interp, objv[6], &right) != TCL_OK) ||
      (Tcl_GetIntFromObj(interp, objv[7], &bottom) != TCL_OK)) {
    return TCL_ERROR;
  }

  Region2d extents;
  if (left < right) {
    extents.left = (double)left;
    extents.right = (double)right;
  }
  else {
    extents.left = (double)right;
    extents.right = (double)left;
  }
  if (top < bottom) {
    extents.top = (double)top;
    extents.bottom = (double)bottom;
  }
  else {
    extents.top = (double)bottom;
    extents.bottom = (double)top;
  }

  int enclosed = (mode == FIND_ENCLOSED);
  for (ChainLink* link = Chain_FirstLink(graphPtr->markers_.displayList);
       link; link = Chain_NextLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    MarkerOptions* ops = (MarkerOptions*)markerPtr->ops();
    if (ops->hide)
      continue;

    if (graphPtr->isElementHidden(markerPtr))
      continue;

    if (markerPtr->regionIn(&extents, enclosed)) {
      Tcl_Obj* objPtr = Tcl_GetObjResult(interp);
      Tcl_SetStringObj(objPtr, markerPtr->name_, -1);
      return TCL_OK;
    }
  }

  Tcl_SetStringObj(Tcl_GetObjResult(interp), "", -1);
  return TCL_OK;
}

static int NamesOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (objc == 3) {
    for (ChainLink* link=Chain_FirstLink(graphPtr->markers_.displayList); 
	 link; link = Chain_NextLink(link)) {
      Marker* markerPtr = (Marker*)Chain_GetValue(link);
      Tcl_ListObjAppendElement(interp, listObjPtr,
			       Tcl_NewStringObj(markerPtr->name_, -1));
    }
  } 
  else {
    for (ChainLink* link=Chain_FirstLink(graphPtr->markers_.displayList); 
	 link; link = Chain_NextLink(link)) {
      Marker* markerPtr = (Marker*)Chain_GetValue(link);
      for (int ii = 3; ii<objc; ii++) {
	const char* pattern = (const char*)Tcl_GetString(objv[ii]);
	if (Tcl_StringMatch(markerPtr->name_, pattern)) {
	  Tcl_ListObjAppendElement(interp, listObjPtr,
				   Tcl_NewStringObj(markerPtr->name_, -1));
	  break;
	}
      }
    }
  }

  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

static int RelinkOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4 && objc!=5) {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId ?placeId?");
    return TCL_ERROR;
  }

  Marker* markerPtr;
  if (GetMarkerFromObj(interp, graphPtr, objv[3], &markerPtr) != TCL_OK)
    return TCL_ERROR;

  Marker* placePtr =NULL;
  if (objc == 5)
    if (GetMarkerFromObj(interp, graphPtr, objv[4], &placePtr) != TCL_OK)
      return TCL_ERROR;

  ChainLink* link = markerPtr->link;
  graphPtr->markers_.displayList->unlinkLink(markerPtr->link);

  ChainLink* place = placePtr ? placePtr->link : NULL;

  const char* string = Tcl_GetString(objv[2]);
  if (string[0] == 'l')
    graphPtr->markers_.displayList->linkAfter(link, place);
  else
    graphPtr->markers_.displayList->linkBefore(link, place);

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int TypeOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "markerId");
    return TCL_ERROR;
  }

  Marker* markerPtr;
  if (GetMarkerFromObj(interp, graphPtr, objv[3], &markerPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_SetStringObj(Tcl_GetObjResult(interp), markerPtr->typeName(), -1);
  return TCL_OK;
}

const Ensemble Blt::markerEnsemble[] = {
  {"bind",      BindOp, 0},
  {"cget",      CgetOp, 0},
  {"configure", ConfigureOp, 0},
  {"create",    CreateOp, 0},
  {"delete",    DeleteOp, 0},
  {"exists",    ExistsOp, 0},
  {"find",      FindOp, 0},
  {"lower",     RelinkOp, 0},
  {"names",     NamesOp, 0},
  {"raise",     RelinkOp, 0},
  {"type",      TypeOp, 0},
  { 0,0,0 }
};

// Support

static int GetMarkerFromObj(Tcl_Interp* interp, Graph* graphPtr, 
			    Tcl_Obj *objPtr, Marker** markerPtrPtr)
{
  const char* string = Tcl_GetString(objPtr);
  Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&graphPtr->markers_.table, string);
  if (hPtr) {
    *markerPtrPtr = (Marker*)Tcl_GetHashValue(hPtr);
    return TCL_OK;
  }
  if (interp) {
    Tcl_AppendResult(interp, "can't find marker \"", string, 
		     "\" in \"", Tk_PathName(graphPtr->tkwin_), "\"", NULL);
  }

  return TCL_ERROR;
}

