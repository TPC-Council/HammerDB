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
#include "tkbltGrAxis.h"
#include "tkbltGrElem.h"
#include "tkbltGrElemOp.h"
#include "tkbltGrElemBar.h"
#include "tkbltGrElemLine.h"
#include "tkbltGrLegd.h"

using namespace Blt;

static int GetIndex(Tcl_Interp* interp, Element* elemPtr, 
		    Tcl_Obj *objPtr, int *indexPtr);
static Tcl_Obj *DisplayListObj(Graph* graphPtr);

int Blt::ElementObjConfigure(Element* elemPtr, Tcl_Interp* interp,
			     int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = elemPtr->graphPtr_;
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)elemPtr->ops(), elemPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    if (elemPtr->configure() != TCL_OK)
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
    Tcl_WrongNumArgs(interp, 3, objv, "elemId option");
    return TCL_ERROR;
  }

  Element* elemPtr;
  if (graphPtr->getElement(objv[3], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)elemPtr->ops(), 
				      elemPtr->optionTable(),
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
    Tcl_WrongNumArgs(interp, 3, objv, "elemId ?option value...?");
    return TCL_ERROR;
  }

  Element* elemPtr;
  if (graphPtr->getElement(objv[3], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  if (objc <= 5) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)elemPtr->ops(), 
				       elemPtr->optionTable(), 
				       (objc == 5) ? objv[4] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return ElementObjConfigure(elemPtr, interp, objc-4, objv+4);
}

static int ActivateOp(ClientData clientData, Tcl_Interp* interp,
		      int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc<3) {
    Tcl_WrongNumArgs(interp, 3, objv, "?elemId? ?index...?");
    return TCL_ERROR;
  }

  // List all the currently active elements
  if (objc == 3) {
    Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);

    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hPtr = Tcl_FirstHashEntry(&graphPtr->elements_.table, &iter); hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
      Element* elemPtr = (Element*)Tcl_GetHashValue(hPtr);
      if (elemPtr->active_)
	Tcl_ListObjAppendElement(interp, listObjPtr,
				 Tcl_NewStringObj(elemPtr->name_, -1));
    }

    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }

  Element* elemPtr;
  if (graphPtr->getElement(objv[3], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  int* indices = NULL;
  int nIndices = -1;
  if (objc > 4) {
    nIndices = objc - 4;
    indices = new int[nIndices];

    int* activePtr = indices;
    for (int ii=4; ii<objc; ii++) {
      if (GetIndex(interp, elemPtr, objv[ii], activePtr) != TCL_OK)
	return TCL_ERROR;
      activePtr++;
    }
  }

  delete [] elemPtr->activeIndices_;
  elemPtr->activeIndices_ = indices;
  elemPtr->nActiveIndices_ = nIndices;

  elemPtr->active_ = 1;

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int BindOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc == 3) {
    Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);

    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&graphPtr->elements_.tagTable, &iter); hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
      char* tagName = 
	(char*)Tcl_GetHashKey(&graphPtr->elements_.tagTable, hPtr);
      Tcl_ListObjAppendElement(interp, listObjPtr,Tcl_NewStringObj(tagName,-1));
    }

    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }

  return graphPtr->bindTable_->configure(graphPtr->elementTag(Tcl_GetString(objv[3])), objc - 4, objv + 4);
}

static int ClosestOp(ClientData clientData, Tcl_Interp* interp,
		     int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<5) {
    Tcl_WrongNumArgs(interp, 3, objv, "x y ?elemName?...");
    return TCL_ERROR;
  }

  GraphOptions* gops = (GraphOptions*)graphPtr->ops_;
  ClosestSearch* searchPtr = &gops->search;

  if (graphPtr->flags & RESET)
    graphPtr->resetAxes();

  int x;
  if (Tcl_GetIntFromObj(interp, objv[3], &x) != TCL_OK) {
    Tcl_AppendResult(interp, ": bad window x-coordinate", NULL);
    return TCL_ERROR;
  }
  int y;
  if (Tcl_GetIntFromObj(interp, objv[4], &y) != TCL_OK) {
    Tcl_AppendResult(interp, ": bad window y-coordinate", NULL);
    return TCL_ERROR;
  }

  searchPtr->x = x;
  searchPtr->y = y;
  searchPtr->index = -1;
  searchPtr->dist = (double)(searchPtr->halo + 1);

  if (objc>5) {
    for (int ii=5; ii<objc; ii++) {
      Element* elemPtr;
      if (graphPtr->getElement(objv[ii], &elemPtr) != TCL_OK)
	return TCL_ERROR;

      ElementOptions* eops = (ElementOptions*)elemPtr->ops();
      if (!eops->hide)
	elemPtr->closest();
    }
  }
  else {
    // Find the closest point from the set of displayed elements,
    // searching the display list from back to front.  That way if
    // the points from two different elements overlay each other
    // exactly, the last one picked will be the topmost.  
    for (ChainLink* link = Chain_LastLink(graphPtr->elements_.displayList);
	 link; link = Chain_PrevLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      ElementOptions* eops = (ElementOptions*)elemPtr->ops();
      if (!eops->hide)
	elemPtr->closest();
    }
  }

  if (searchPtr->dist < (double)searchPtr->halo) {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj("name", -1));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj(searchPtr->elemPtr->name_, -1)); 
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj("index", -1));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewIntObj(searchPtr->index));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj("x", -1));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(searchPtr->point.x));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj("y", -1));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(searchPtr->point.y));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewStringObj("dist", -1));
    Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(searchPtr->dist));
    Tcl_SetObjResult(interp, listObjPtr);
  }

  return TCL_OK;
}

static int CreateOp(ClientData clientData, Tcl_Interp* interp,
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  // may vary in length
  //  if (objc!=4) {
  //    Tcl_WrongNumArgs(interp, 3, objv, "elemId");
  //    return TCL_ERROR;
  //  }
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId...");
    return TCL_ERROR;
  }
  
  if (graphPtr->createElement(objc, objv) != TCL_OK)
    return TCL_ERROR;
  Tcl_SetObjResult(interp, objv[3]);

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int DeactivateOp(ClientData clientData, Tcl_Interp* interp,
			int objc, Tcl_Obj* const objv[])
{
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId...");
    return TCL_ERROR;
  }
  Graph* graphPtr = (Graph*)clientData;
  for (int ii=3; ii<objc; ii++) {
    Element* elemPtr;
    if (graphPtr->getElement(objv[ii], &elemPtr) != TCL_OK)
      return TCL_ERROR;

    delete [] elemPtr->activeIndices_;
    elemPtr->activeIndices_ = NULL;
    elemPtr->nActiveIndices_ = 0;
    elemPtr->active_ = 0;
  }

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int DeleteOp(ClientData clientData, Tcl_Interp* interp,
		    int objc, Tcl_Obj* const objv[])
{
  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId...");
    return TCL_ERROR;
  }
  Graph* graphPtr = (Graph*)clientData;
  for (int ii=3; ii<objc; ii++) {
    Element* elemPtr;
    if (graphPtr->getElement(objv[ii], &elemPtr) != TCL_OK)
      return TCL_ERROR;
    graphPtr->legend_->removeElement(elemPtr);
    delete elemPtr;
  }

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int ExistsOp(ClientData clientData, Tcl_Interp* interp,
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId");
    return TCL_ERROR;
  }

  Tcl_HashEntry *hPtr = 
    Tcl_FindHashEntry(&graphPtr->elements_.table, Tcl_GetString(objv[3]));
  Tcl_SetBooleanObj(Tcl_GetObjResult(interp), (hPtr != NULL));
  return TCL_OK;
}

static int LowerOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId...");
    return TCL_ERROR;
  }

  // Move the links of lowered elements out of the display list into
  // a temporary list
  Chain* chain = new Chain();

  for (int ii=3; ii<objc; ii++) {
    Element* elemPtr;
    if (graphPtr->getElement(objv[ii], &elemPtr) != TCL_OK)
      return TCL_ERROR;

    // look for duplicates
    int ok=1;
    for (ChainLink* link = Chain_FirstLink(chain);
	 link; link = Chain_NextLink(link)) {
      Element* ptr = (Element*)Chain_GetValue(link);
      if (ptr == elemPtr) {
	ok=0;
	break;
      }
    }

    if (ok && elemPtr->link) {
      graphPtr->elements_.displayList->unlinkLink(elemPtr->link); 
      chain->linkAfter(elemPtr->link, NULL); 
    }
  }

  // Append the links to end of the display list
  ChainLink *next;
  for (ChainLink *link = Chain_FirstLink(chain); link; link = next) {
    next = Chain_NextLink(link);
    chain->unlinkLink(link); 
    graphPtr->elements_.displayList->linkAfter(link, NULL); 
  }	
  delete chain;

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  Tcl_SetObjResult(interp, DisplayListObj(graphPtr));
  return TCL_OK;
}

static int NamesOp(ClientData clientData, Tcl_Interp* interp,
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc<3) {
    Tcl_WrongNumArgs(interp, 3, objv, "?pattern...?");
    return TCL_ERROR;
  }

  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (objc == 3) {
    Tcl_HashSearch iter;
    for (Tcl_HashEntry *hPtr = Tcl_FirstHashEntry(&graphPtr->elements_.table, &iter); hPtr != NULL; hPtr = Tcl_NextHashEntry(&iter)) {
      Element* elemPtr = (Element*)Tcl_GetHashValue(hPtr);
      Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }
  }
  else {
    Tcl_HashSearch iter;
    for (Tcl_HashEntry *hPtr = Tcl_FirstHashEntry(&graphPtr->elements_.table, &iter); hPtr != NULL; hPtr = Tcl_NextHashEntry(&iter)) {
      Element* elemPtr = (Element*)Tcl_GetHashValue(hPtr);

      for (int ii=3; ii<objc; ii++) {
	if (Tcl_StringMatch(elemPtr->name_,Tcl_GetString(objv[ii]))) {
	  Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
	  Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
	  break;
	}
      }
    }
  }

  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

static int RaiseOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc<4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId...");
    return TCL_ERROR;
  }

  Chain* chain = new Chain();
  for (int ii=3; ii<objc; ii++) {
    Element* elemPtr;
    if (graphPtr->getElement(objv[ii], &elemPtr) != TCL_OK)
      return TCL_ERROR;

    // look for duplicates
    int ok=1;
    for (ChainLink* link = Chain_FirstLink(chain);
	 link; link = Chain_NextLink(link)) {
      Element* ptr = (Element*)Chain_GetValue(link);
      if (ptr == elemPtr) {
	ok=0;
	break;
      }
    }

    if (ok && elemPtr->link) {
      graphPtr->elements_.displayList->unlinkLink(elemPtr->link); 
      chain->linkAfter(elemPtr->link, NULL); 
    }
  }

  // Prepend the links to beginning of the display list in reverse order
  ChainLink *prev;
  for (ChainLink *link = Chain_LastLink(chain); link; link = prev) {
    prev = Chain_PrevLink(link);
    chain->unlinkLink(link); 
    graphPtr->elements_.displayList->linkBefore(link, NULL); 
  }	
  delete chain;

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  Tcl_SetObjResult(interp, DisplayListObj(graphPtr));
  return TCL_OK;
}

static int ShowOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  // may vary in length
  if (objc<3) {
  //  if (objc!=3 || objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "?nameList?");
    return TCL_ERROR;
  }

  if (objc == 3) {
    Tcl_SetObjResult(interp, DisplayListObj(graphPtr));
    return TCL_OK;
  }

  int elemObjc;
  Tcl_Obj** elemObjv;
  if (Tcl_ListObjGetElements(interp, objv[3], &elemObjc, &elemObjv) != TCL_OK)
    return TCL_ERROR;

  // Collect the named elements into a list
  Chain* chain = new Chain();
  for (int ii=0; ii<elemObjc; ii++) {
    Element* elemPtr;
    if (graphPtr->getElement(elemObjv[ii], &elemPtr) != TCL_OK) {
      delete chain;
      return TCL_ERROR;
    }

    // look for duplicates
    int ok=1;
    for (ChainLink* link = Chain_FirstLink(chain);
	 link; link = Chain_NextLink(link)) {
      Element* ptr = (Element*)Chain_GetValue(link);
      if (ptr == elemPtr) {
	ok=0;
	break;
      }
    }

    if (ok) 
      chain->append(elemPtr);
  }

  // Clear the links from the currently displayed elements
  for (ChainLink* link = Chain_FirstLink(graphPtr->elements_.displayList);
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->link = NULL;
  }
  delete graphPtr->elements_.displayList;
  graphPtr->elements_.displayList = chain;

  // Set links on all the displayed elements
  for (ChainLink* link = Chain_FirstLink(chain); link; 
       link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->link = link;
  }

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();

  Tcl_SetObjResult(interp, DisplayListObj(graphPtr));
  return TCL_OK;
}

static int TypeOp(ClientData clientData, Tcl_Interp* interp,
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc!=4) {
    Tcl_WrongNumArgs(interp, 3, objv, "elemId");
    return TCL_ERROR;
  }

  Element* elemPtr;
  if (graphPtr->getElement(objv[3], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  Tcl_SetStringObj(Tcl_GetObjResult(interp), elemPtr->typeName(), -1);
  return TCL_OK;
}

const Ensemble Blt::elementEnsemble[] = {
  {"activate",   ActivateOp, 0},
  {"bind",       BindOp, 0},
  {"cget",       CgetOp, 0},
  {"closest",    ClosestOp, 0},
  {"configure",  ConfigureOp, 0},
  {"create",     CreateOp,  0},
  {"deactivate", DeactivateOp, 0},
  {"delete",     DeleteOp, 0},
  {"exists",     ExistsOp, 0},
  {"lower",      LowerOp, 0},
  {"names",      NamesOp, 0},
  {"raise",      RaiseOp, 0},
  {"show",       ShowOp, 0},
  {"type",       TypeOp, 0},
  { 0,0,0 }
};

// Support

static Tcl_Obj *DisplayListObj(Graph* graphPtr)
{
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);

  for (ChainLink* link = Chain_FirstLink(graphPtr->elements_.displayList); 
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
    Tcl_ListObjAppendElement(graphPtr->interp_, listObjPtr, objPtr);
  }

  return listObjPtr;
}

static int GetIndex(Tcl_Interp* interp, Element* elemPtr, 
		    Tcl_Obj *objPtr, int *indexPtr)
{
  ElementOptions* ops = (ElementOptions*)elemPtr->ops();

  char *string = Tcl_GetString(objPtr);
  if ((*string == 'e') && (strcmp("end", string) == 0))
    *indexPtr = NUMBEROFPOINTS(ops);
  else if (Tcl_GetIntFromObj(interp, objPtr, indexPtr) != TCL_OK)
    return TCL_ERROR;

  return TCL_OK;
}


