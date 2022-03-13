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

#include <tk.h>
#include <tkInt.h>

#include "tkbltGrBind.h"
#include "tkbltGraph.h"
#include "tkbltGrLegd.h"
#include "tkbltGrLegdOp.h"
#include "tkbltGrElem.h"

using namespace Blt;

static Tk_LostSelProc LostSelectionProc;

static int LegendObjConfigure(Graph* graphPtr, Tcl_Interp* interp,
			      int objc, Tcl_Obj* const objv[])
{
  Legend* legendPtr = graphPtr->legend_;
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)legendPtr->ops(),
			legendPtr->optionTable(), 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    if (legendPtr->configure() != TCL_OK)
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

  Legend* legendPtr = graphPtr->legend_;
  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)legendPtr->ops(), 
				      legendPtr->optionTable(),
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
  Legend* legendPtr = graphPtr->legend_;
  if (objc <= 4) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)legendPtr->ops(), 
				       legendPtr->optionTable(), 
				       (objc == 4) ? objv[3] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return LegendObjConfigure(graphPtr, interp, objc-3, objv+3);
}

static int ActivateOp(ClientData clientData, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();

  const char *string = Tcl_GetString(objv[2]);
  int active = (string[0] == 'a') ? 1 : 0;
  int redraw = 0;
  for (int ii=3; ii<objc; ii++) {
    
    const char* pattern = Tcl_GetString(objv[ii]);
    for (ChainLink* link = Chain_FirstLink(graphPtr->elements_.displayList);
	 link; link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      if (Tcl_StringMatch(elemPtr->name_, pattern)) {
	if (active) {
	  if (!elemPtr->labelActive_) {
	    elemPtr->labelActive_ =1;
	    redraw = 1;
	  }
	}
	else {
	  if (elemPtr->labelActive_) {
	    elemPtr->labelActive_ =0;
	    redraw = 1;
	  }
	}
      }
    }
  }

  if (redraw && !ops->hide) {
    graphPtr->flags |= LAYOUT;
    graphPtr->eventuallyRedraw();
  }

  // List active elements in stacking order
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  for (ChainLink* link = Chain_FirstLink(graphPtr->elements_.displayList);
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    if (elemPtr->labelActive_) {
      Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);

  return TCL_OK;
}

static int BindOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc == 3) {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&graphPtr->elements_.tagTable, &iter); hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
      char* tagName = 
	(char*)Tcl_GetHashKey(&graphPtr->elements_.tagTable, hPtr);
      Tcl_Obj *objPtr = Tcl_NewStringObj(tagName, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }

    Tcl_SetObjResult(interp, listObjPtr);
    return TCL_OK;
  }

  return graphPtr->legend_->bindTable_->configure(graphPtr->elementTag(Tcl_GetString(objv[3])), objc - 4, objv + 4);
}

static int CurselectionOp(ClientData clientData, Tcl_Interp* interp, 
			  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (legendPtr->flags & SELECT_SORTED) {
    for (ChainLink* link = Chain_FirstLink(legendPtr->selected_); link;
	 link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
      Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
    }
  }
  else {
    // List of selected entries is in stacking order
    for (ChainLink* link = Chain_FirstLink(graphPtr->elements_.displayList);
	 link; link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);

      if (legendPtr->entryIsSelected(elemPtr)) {
	Tcl_Obj *objPtr = Tcl_NewStringObj(elemPtr->name_, -1);
	Tcl_ListObjAppendElement(interp, listObjPtr, objPtr);
      }
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

static int FocusOp(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;

  legendPtr->focusPtr_ = NULL;
  if (objc == 4) {
    Element* elemPtr;
    if (legendPtr->getElementFromObj(objv[3], &elemPtr) != TCL_OK)
      return TCL_ERROR;

    if (elemPtr) {
      legendPtr->focusPtr_ = elemPtr;

      legendPtr->bindTable_->focusItem_ = (ClientData)elemPtr;
      legendPtr->bindTable_->focusContext_ = elemPtr->classId();
    }
  }

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  if (legendPtr->focusPtr_)
    Tcl_SetStringObj(Tcl_GetObjResult(interp),legendPtr->focusPtr_->name_,-1);

  return TCL_OK;
}

static int GetOp(ClientData clientData, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  if (objc<3)
    return TCL_ERROR;

  Legend* legendPtr = graphPtr->legend_;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();

  if (((ops->hide) == 0) && (legendPtr->nEntries_ > 0)) {
    Element* elemPtr;

    if (legendPtr->getElementFromObj(objv[3], &elemPtr) != TCL_OK)
      return TCL_ERROR;

    if (elemPtr)
      Tcl_SetStringObj(Tcl_GetObjResult(interp), elemPtr->name_, -1);
  }
  return TCL_OK;
}

const Ensemble Blt::legendEnsemble[] = {
  {"activate",     ActivateOp, 0},
  {"bind",         BindOp, 0},
  {"cget",         CgetOp, 0},
  {"configure",    ConfigureOp, 0},
  {"curselection", CurselectionOp, 0},
  {"deactivate",   ActivateOp, 0},
  {"focus",        FocusOp, 0},
  {"get",          GetOp, 0},
  {"selection",    0, selectionEnsemble},
  { 0,0,0 }
};

// Selection Ops

static int SelectionAnchorOp(ClientData clientData, Tcl_Interp* interp, 
			     int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  Element* elemPtr;

  if (legendPtr->getElementFromObj(objv[4], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  // Set both the anchor and the mark. Indicates that a single entry
  // is selected
  legendPtr->selAnchorPtr_ = elemPtr;
  legendPtr->selMarkPtr_ = NULL;
  if (elemPtr)
    Tcl_SetStringObj(Tcl_GetObjResult(interp), elemPtr->name_, -1);

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int SelectionClearallOp(ClientData clientData, Tcl_Interp* interp, 
			       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  legendPtr->clearSelection();

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

static int SelectionIncludesOp(ClientData clientData, Tcl_Interp* interp, 
			       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  Element* elemPtr;
  if (legendPtr->getElementFromObj(objv[4], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  int boo = legendPtr->entryIsSelected(elemPtr);
  Tcl_SetBooleanObj(Tcl_GetObjResult(interp), boo);
  return TCL_OK;
}

static int SelectionMarkOp(ClientData clientData, Tcl_Interp* interp, 
			   int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();
  Element* elemPtr;

  if (legendPtr->getElementFromObj(objv[4], &elemPtr) != TCL_OK)
    return TCL_ERROR;

  if (legendPtr->selAnchorPtr_ == NULL) {
    Tcl_AppendResult(interp, "selection anchor must be set first", NULL);
    return TCL_ERROR;
  }

  if (legendPtr->selMarkPtr_ != elemPtr) {
    // Deselect entry from the list all the way back to the anchor
    ChainLink *link, *next;
    for (link = Chain_LastLink(legendPtr->selected_); link; link = next) {
      next = Chain_PrevLink(link);
      Element *selectPtr = (Element*)Chain_GetValue(link);
      if (selectPtr == legendPtr->selAnchorPtr_)
	break;

      legendPtr->deselectElement(selectPtr);
    }

    legendPtr->flags &= ~SELECT_TOGGLE;
    legendPtr->flags |= SELECT_SET;
    legendPtr->selectRange(legendPtr->selAnchorPtr_, elemPtr);
    Tcl_SetStringObj(Tcl_GetObjResult(interp), elemPtr->name_, -1);
    legendPtr->selMarkPtr_ = elemPtr;

    if (ops->selectCmd)
      legendPtr->eventuallyInvokeSelectCmd();

    graphPtr->flags |= CACHE;
    graphPtr->eventuallyRedraw();
  }
  return TCL_OK;
}

static int SelectionPresentOp(ClientData clientData, Tcl_Interp* interp, 
			      int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  int boo = (Chain_GetLength(legendPtr->selected_) > 0);
  Tcl_SetBooleanObj(Tcl_GetObjResult(interp), boo);
  return TCL_OK;
}

static int SelectionSetOp(ClientData clientData, Tcl_Interp* interp, 
			  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Legend* legendPtr = graphPtr->legend_;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();

  legendPtr->flags &= ~SELECT_TOGGLE;
  const char* string = Tcl_GetString(objv[3]);
  switch (string[0]) {
  case 's':
    legendPtr->flags |= SELECT_SET;
    break;
  case 'c':
    legendPtr->flags |= SELECT_CLEAR;
    break;
  case 't':
    legendPtr->flags |= SELECT_TOGGLE;
    break;
  }

  Element *firstPtr;
  if (legendPtr->getElementFromObj(objv[4], &firstPtr) != TCL_OK)
    return TCL_ERROR;
  ElementOptions* eops = (ElementOptions*)firstPtr->ops();

  if ((eops->hide) && ((legendPtr->flags & SELECT_CLEAR)==0)) {
    Tcl_AppendResult(interp, "can't select hidden node \"", 
		     Tcl_GetString(objv[4]), "\"", (char *)NULL);
    return TCL_ERROR;
  }

  Element* lastPtr = firstPtr;
  if (objc > 5) {
    if (legendPtr->getElementFromObj(objv[5], &lastPtr) != TCL_OK)
      return TCL_ERROR;
    ElementOptions* eops = (ElementOptions*)firstPtr->ops();

    if (eops->hide && ((legendPtr->flags & SELECT_CLEAR) == 0)) {
      Tcl_AppendResult(interp, "can't select hidden node \"", 
		       Tcl_GetString(objv[5]), "\"", (char *)NULL);
      return TCL_ERROR;
    }
  }

  if (firstPtr == lastPtr)
    legendPtr->selectEntry(firstPtr);
  else
    legendPtr->selectRange(firstPtr, lastPtr);

  // Set both the anchor and the mark. Indicates that a single entry is
  // selected
  if (legendPtr->selAnchorPtr_ == NULL)
    legendPtr->selAnchorPtr_ = firstPtr;

  if (ops->exportSelection)
    Tk_OwnSelection(graphPtr->tkwin_, XA_PRIMARY, LostSelectionProc, legendPtr);

  if (ops->selectCmd)
    legendPtr->eventuallyInvokeSelectCmd();

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();

  return TCL_OK;
}

const Ensemble Blt::selectionEnsemble[] = {
  {"anchor",   SelectionAnchorOp, 0},
  {"clear",    SelectionSetOp, 0},
  {"clearall", SelectionClearallOp, 0},
  {"includes", SelectionIncludesOp, 0},
  {"mark",     SelectionMarkOp, 0},
  {"present",  SelectionPresentOp, 0},
  {"set",      SelectionSetOp, 0},
  {"toggle",   SelectionSetOp, 0},
  { 0,0,0 }
};

// Support

static void LostSelectionProc(ClientData clientData)
{
  Legend* legendPtr = (Legend*)clientData;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();
  Graph* graphPtr = legendPtr->graphPtr_;

  if (ops->exportSelection)
    legendPtr->clearSelection();

  graphPtr->flags |= CACHE;
  graphPtr->eventuallyRedraw();
}




