/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1998 George A Howlett.
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

#include <iostream>
#include <sstream>
#include <iomanip>
using namespace std;

#include "tkbltGrBind.h"
#include "tkbltGraph.h"
#include "tkbltGrLegd.h"

using namespace Blt;

static Tk_EventProc BindProc;

BindTable::BindTable(Graph* graphPtr, Pick* pickPtr)
{
  graphPtr_ = graphPtr;
  pickPtr_ = pickPtr;
  grab_ =0;
  table_ = Tk_CreateBindingTable(graphPtr->interp_);
  currentItem_ =NULL;
  currentContext_ =CID_NONE;
  newItem_ =NULL;
  newContext_ =CID_NONE;
  focusItem_ =NULL;
  focusContext_ =CID_NONE;
  //  pickEvent =NULL;
  state_ =0;

  unsigned int mask = (KeyPressMask | KeyReleaseMask | ButtonPressMask |
		       ButtonReleaseMask | EnterWindowMask | LeaveWindowMask |
		       PointerMotionMask);
  Tk_CreateEventHandler(graphPtr->tkwin_, mask, BindProc, this);
}

BindTable::~BindTable()
{
  Tk_DeleteBindingTable(table_);
  unsigned int mask = (KeyPressMask | KeyReleaseMask | ButtonPressMask |
		       ButtonReleaseMask | EnterWindowMask | LeaveWindowMask |
		       PointerMotionMask);
  Tk_DeleteEventHandler(graphPtr_->tkwin_, mask, BindProc, this);
}

int BindTable::configure(ClientData item, int objc, Tcl_Obj* const objv[])
{
  if (objc == 0) {
    Tk_GetAllBindings(graphPtr_->interp_, table_, item);
    return TCL_OK;
  }

  const char *string = Tcl_GetString(objv[0]);
  if (objc == 1) {
    const char* command = 
      Tk_GetBinding(graphPtr_->interp_, table_, item, string);
    if (!command) {
      Tcl_ResetResult(graphPtr_->interp_);
      Tcl_AppendResult(graphPtr_->interp_, "invalid binding event \"", 
		       string, "\"", NULL);
      return TCL_ERROR;
    }
    Tcl_SetStringObj(Tcl_GetObjResult(graphPtr_->interp_), command, -1);
    return TCL_OK;
  }

  const char* seq = string;
  const char* command = Tcl_GetString(objv[1]);
  if (command[0] == '\0')
    return Tk_DeleteBinding(graphPtr_->interp_, table_, item, seq);

  unsigned long mask;
  if (command[0] == '+')
    mask = Tk_CreateBinding(graphPtr_->interp_, table_, 
			    item, seq, command+1, 1);
  else
    mask = Tk_CreateBinding(graphPtr_->interp_, table_, 
			    item, seq, command, 0);
  if (!mask)
    return TCL_ERROR;

  if (mask & (unsigned) ~(ButtonMotionMask|Button1MotionMask
			  |Button2MotionMask|Button3MotionMask|Button4MotionMask
			  |Button5MotionMask|ButtonPressMask|ButtonReleaseMask
			  |EnterWindowMask|LeaveWindowMask|KeyPressMask
			  |KeyReleaseMask|PointerMotionMask|VirtualEventMask)) {
    Tk_DeleteBinding(graphPtr_->interp_, table_, item, seq);
    Tcl_ResetResult(graphPtr_->interp_);
    Tcl_AppendResult(graphPtr_->interp_, "requested illegal events; ",
		     "only key, button, motion, enter, leave, and virtual ",
		     "events may be used", (char *)NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

void BindTable::deleteBindings(ClientData object)
{
  Tk_DeleteAllBindings(table_, object);

  if (currentItem_ == object) {
    currentItem_ =NULL;
    currentContext_ =CID_NONE;
  }

  if (newItem_ == object) {
    newItem_ =NULL;
    newContext_ =CID_NONE;
  }

  if (focusItem_ == object) {
    focusItem_ =NULL;
    focusContext_ =CID_NONE;
  }
}

void BindTable::doEvent(XEvent* eventPtr)
{
  ClientData item = currentItem_;
  ClassId classId = currentContext_;

  if ((eventPtr->type == KeyPress) || (eventPtr->type == KeyRelease)) {
    item = focusItem_;
    classId = focusContext_;
  }
  if (!item)
    return;

  int nTags;
  const char** tagArray = graphPtr_->getTags(item, classId, &nTags);
  Tk_BindEvent(table_, eventPtr, graphPtr_->tkwin_, nTags, (void**)tagArray);

  delete [] tagArray;
}

void BindTable::pickItem(XEvent* eventPtr)
{
  int buttonDown = state_
    & (Button1Mask|Button2Mask|Button3Mask|Button4Mask|Button5Mask);

  // A LeaveNotify event automatically means that there's no current item,
  if (eventPtr->type != LeaveNotify) {
    int x = eventPtr->xcrossing.x;
    int y = eventPtr->xcrossing.y;
    newItem_ = pickPtr_->pickEntry(x, y, &newContext_);
  }
  else {
    newItem_ =NULL;
    newContext_ = CID_NONE;
  }

  // Nothing to do: the current item hasn't changed.
  if ((newItem_ == currentItem_) && !grab_)
    return;

  if (!buttonDown)
    grab_ =0;

  if ((newItem_ != currentItem_) && buttonDown) {
    grab_ =1;
    return;
  }

  grab_ =0;
  currentItem_ = newItem_;
  currentContext_ = newContext_;
}

static void BindProc(ClientData clientData, XEvent* eventPtr)
{
  BindTable* bindPtr = (BindTable*)clientData;
  Tcl_Preserve(bindPtr->graphPtr_);

  switch (eventPtr->type) {
  case ButtonPress:
  case ButtonRelease:
    bindPtr->state_ = eventPtr->xbutton.state;
    break;
  case EnterNotify:
  case LeaveNotify:
    bindPtr->state_ = eventPtr->xcrossing.state;
    break;
  case MotionNotify:
    bindPtr->state_ = eventPtr->xmotion.state;
    break;
  case KeyPress:
  case KeyRelease:
    bindPtr->state_ = eventPtr->xkey.state;
    break;
  }

  bindPtr->pickItem(eventPtr);
  bindPtr->doEvent(eventPtr);

  Tcl_Release(bindPtr->graphPtr_);
}

