/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1991-2004 George A Howlett.
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

#include <cfloat>
#include <cmath>

#include <tkInt.h>

#include "tkbltGraph.h"
#include "tkbltGraphOp.h"

#include "tkbltGrBind.h"
#include "tkbltGrAxis.h"
#include "tkbltGrAxisOp.h"
#include "tkbltGrXAxisOp.h"
#include "tkbltGrPen.h"
#include "tkbltGrPenBar.h"
#include "tkbltGrPenLine.h"
#include "tkbltGrElem.h"
#include "tkbltGrElemBar.h"
#include "tkbltGrElemLine.h"
#include "tkbltGrMarker.h"
#include "tkbltGrLegd.h"
#include "tkbltGrHairs.h"
#include "tkbltGrDef.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrPSOutput.h"
#include "tkbltInt.h"

using namespace Blt;

#define MARKER_ABOVE	0
#define MARKER_UNDER	1

// OptionSpecs

Graph::Graph(ClientData clientData, Tcl_Interp* interp, 
	     int objc, Tcl_Obj* const objv[])
{
  valid_ =1;
  interp_ = interp;
  tkwin_ = Tk_CreateWindowFromPath(interp_, Tk_MainWindow(interp_), 
				  Tcl_GetString(objv[1]), NULL);
  if (!tkwin_) {
    valid_ =0;
    return;
  }
  display_ = Tk_Display(tkwin_);
  ((TkWindow*)tkwin_)->instanceData = this;

  cmdToken_ = Tcl_CreateObjCommand(interp_, Tk_PathName(tkwin_),
				   GraphInstCmdProc, this,
				   GraphInstCmdDeleteProc);

  flags = RESET;
  nextMarkerId_ = 1;

  inset_ =0;
  titleX_ =0;
  titleY_ =0;
  titleWidth_ =0;
  titleHeight_ =0;
  width_ =0;
  height_ =0;
  left_ =0;
  right_ =0;
  top_ =0;
  bottom_ =0;
  focusPtr_ =NULL;
  halo_ =0;
  drawGC_ =NULL;
  vRange_ =0;
  hRange_ =0;
  vOffset_ =0;
  hOffset_ =0;
  vScale_ =0;
  hScale_ =0;
  cache_ =None;
  cacheWidth_ =0;
  cacheHeight_ =0;

  Tcl_InitHashTable(&axes_.table, TCL_STRING_KEYS);
  Tcl_InitHashTable(&axes_.tagTable, TCL_STRING_KEYS);
  Tcl_InitHashTable(&elements_.table, TCL_STRING_KEYS);
  Tcl_InitHashTable(&elements_.tagTable, TCL_STRING_KEYS);
  Tcl_InitHashTable(&markers_.table, TCL_STRING_KEYS);
  Tcl_InitHashTable(&markers_.tagTable, TCL_STRING_KEYS);
  Tcl_InitHashTable(&penTable_, TCL_STRING_KEYS);

  axes_.displayList = new Chain();
  elements_.displayList = new Chain();
  markers_.displayList = new Chain();
  bindTable_ = new BindTable(this, this);

  // Keep a hold of the associated tkwin until we destroy the graph,
  // otherwise Tk might free it while we still need it.
  Tcl_Preserve(tkwin_);

  Tk_CreateEventHandler(tkwin_, 
			ExposureMask|StructureNotifyMask|FocusChangeMask,
			GraphEventProc, this);
}

Graph::~Graph()
{
  //  GraphOptions* ops = (GraphOptions*)ops_;

  destroyMarkers();
  destroyElements();  // must come before legend and others

  delete crosshairs_;
  delete legend_;
  delete postscript_;

  destroyAxes();
  destroyPens();

  delete bindTable_;

  if (drawGC_)
    Tk_FreeGC(display_, drawGC_);

  if (cache_ != None)
    Tk_FreePixmap(display_, cache_);

  Tk_FreeConfigOptions((char*)ops_, optionTable_, tkwin_);
  Tcl_Release(tkwin_);
  tkwin_ = NULL;

  free (ops_);
}

int Graph::configure()	
{
  GraphOptions* ops = (GraphOptions*)ops_;

  inset_ = ops->borderWidth + ops->highlightWidth;
  if ((ops->reqHeight != Tk_ReqHeight(tkwin_)) ||
      (ops->reqWidth != Tk_ReqWidth(tkwin_)))
    Tk_GeometryRequest(tkwin_, ops->reqWidth, ops->reqHeight);

  Tk_SetInternalBorder(tkwin_, ops->borderWidth);
  XColor* colorPtr = Tk_3DBorderColor(ops->normalBg);

  titleWidth_ =0;
  titleHeight_ =0;
  if (ops->title != NULL) {
    int w, h;
    TextStyle ts(this, &ops->titleTextStyle);
    ts.getExtents(ops->title, &w, &h);
    titleHeight_ = h;
  }

  // Create GCs for interior and exterior regions, and a background GC for
  // clearing the margins with XFillRectangle
  // Margin
  XGCValues gcValues;
  gcValues.foreground = ops->titleTextStyle.color->pixel;
  gcValues.background = colorPtr->pixel;
  unsigned long gcMask = (GCForeground | GCBackground);
  GC newGC = Tk_GetGC(tkwin_, gcMask, &gcValues);
  if (drawGC_ != NULL)
    Tk_FreeGC(display_, drawGC_);
  drawGC_ = newGC;

  // If the -inverted option changed, we need to readjust the pointers
  // to the axes and recompute the their scales.
  adjustAxes();

  // Free the pixmap if we're not buffering the display of elements anymore.
  if (cache_ != None) {
    Tk_FreePixmap(display_, cache_);
    cache_ = None;
  }

  return TCL_OK;
}

void Graph::map()
{
  if (flags & RESET) {
    resetAxes();
    flags &= ~RESET;
    flags |= LAYOUT;
  }

  if (flags & LAYOUT) {
    layoutGraph();
    crosshairs_->map();
    mapAxes();
    mapElements();
    flags &= ~LAYOUT;
    flags |= MAP_MARKERS | CACHE;
  }

  mapMarkers();
}

void Graph::draw()
{
  GraphOptions* ops = (GraphOptions*)ops_;

  flags &= ~REDRAW_PENDING;
  if ((flags & GRAPH_DELETED) || !Tk_IsMapped(tkwin_))
    return;

  // Don't bother computing the layout until the size of the window is
  // something reasonable.
  if ((Tk_Width(tkwin_) <= 1) || (Tk_Height(tkwin_) <= 1))
    return;

  width_ = Tk_Width(tkwin_);
  height_ = Tk_Height(tkwin_);

  map();

  // Create a pixmap the size of the window for double buffering
  Pixmap drawable = Tk_GetPixmap(display_, Tk_WindowId(tkwin_), 
				 width_, height_, Tk_Depth(tkwin_));

  if (cache_ == None || cacheWidth_ != width_ || cacheHeight_ != height_) {
    if (cache_ != None)
      Tk_FreePixmap(display_, cache_);
    cache_ = Tk_GetPixmap(display_, Tk_WindowId(tkwin_), width_, height_, 
			  Tk_Depth(tkwin_));
    cacheWidth_ = width_;
    cacheHeight_ = height_;
    flags |= CACHE;
  }

  // Update cache if needed
  if (flags & CACHE) {
    drawMargins(cache_);

    switch (legend_->position()) {
    case Legend::TOP:
    case Legend::BOTTOM:
    case Legend::RIGHT:
    case Legend::LEFT:
      legend_->draw(cache_);
      break;
    default:
      break;
    }

    // Draw the background of the plotting area with 3D border
    Tk_Fill3DRectangle(tkwin_, cache_, ops->plotBg, 
		       left_-ops->plotBW, 
		       top_-ops->plotBW, 
		       right_-left_+1+2*ops->plotBW,
		       bottom_-top_+1+2*ops->plotBW, 
		       ops->plotBW, ops->plotRelief);
  
    drawAxesGrids(cache_);
    drawAxes(cache_);
    drawAxesLimits(cache_);

    if (!legend_->isRaised()) {
      switch (legend_->position()) {
      case Legend::PLOT:
      case Legend::XY:
	legend_->draw(cache_);
	break;
      default:
	break;
      }
    }

    drawMarkers(cache_, MARKER_UNDER);
    drawElements(cache_);
    drawActiveElements(cache_);

    if (legend_->isRaised()) {
      switch (legend_->position()) {
      case Legend::PLOT:
      case Legend::XY:
	legend_->draw(cache_);
	break;
      default:
	break;
      }
    }

    flags &= ~CACHE;
  }

  XCopyArea(display_, cache_, drawable, drawGC_, 0, 0, Tk_Width(tkwin_),
	    Tk_Height(tkwin_), 0, 0);
  
  drawMarkers(drawable, MARKER_ABOVE);

  // Draw 3D border just inside of the focus highlight ring
  if ((ops->borderWidth > 0) && (ops->relief != TK_RELIEF_FLAT))
    Tk_Draw3DRectangle(tkwin_, drawable, ops->normalBg, 
		       ops->highlightWidth, ops->highlightWidth, 
		       width_ - 2*ops->highlightWidth, 
		       height_ - 2*ops->highlightWidth, 
		       ops->borderWidth, ops->relief);

  // Draw focus highlight ring
  if ((ops->highlightWidth > 0) && (flags & FOCUS)) {
    GC gc = Tk_GCForColor(ops->highlightColor, drawable);
    Tk_DrawFocusHighlight(tkwin_, gc, ops->highlightWidth, drawable);
  }

  // crosshairs
  crosshairs_->draw(drawable);

  XCopyArea(display_, drawable, Tk_WindowId(tkwin_), drawGC_, 
	    0, 0, width_, height_, 0, 0);

  Tk_FreePixmap(display_, drawable);
}

int Graph::print(const char* ident, PSOutput* psPtr)
{
  GraphOptions* ops = (GraphOptions*)ops_;
  PostscriptOptions* pops = (PostscriptOptions*)postscript_->ops_;

  // be sure the window is realized so that relief colors are available
  if (flags & REDRAW_PENDING) {
    flags |= REDRAW_PENDING;
    DisplayGraph(this);
  }

  // We need to know how big a graph to print.  If the graph hasn't been drawn
  // yet, the width and height will be 1.  Instead use the requested size of
  // the widget.  The user can still override this with the -width and -height
  // postscript options.
  if (pops->reqWidth > 0)
    width_ = pops->reqWidth;
  else if (width_ < 2)
    width_ = Tk_ReqWidth(tkwin_);

  if (pops->reqHeight > 0)
    height_ = pops->reqHeight;
  else if (height_ < 2)
    height_ = Tk_ReqHeight(tkwin_);

  psPtr->computeBBox(width_, height_);
  flags |= RESET;

  // Turn on PostScript measurements when computing the graph's layout.
  reconfigure();

  map();

  int x = left_ - ops->plotBW;
  int y = top_ - ops->plotBW;

  int w = (right_ - left_ + 1) + (2*ops->plotBW);
  int h = (bottom_ - top_ + 1) + (2*ops->plotBW);

  int result = psPtr->preamble(ident);
  if (result != TCL_OK)
    goto error;

  psPtr->setFont(ops->titleTextStyle.font);
  if (pops->decorations)
    psPtr->setBackground(Tk_3DBorderColor(ops->plotBg));
  else
    psPtr->setClearBackground();

  psPtr->fillRectangle(x, y, w, h);
  psPtr->append("gsave\n\n");

  // Start
  printMargins(psPtr);

  switch (legend_->position()) {
  case Legend::TOP:
  case Legend::BOTTOM:
  case Legend::RIGHT:
  case Legend::LEFT:
    legend_->print(psPtr);
    break;
  default:
    break;
  }

  printAxesGrids(psPtr);
  printAxes(psPtr);
  printAxesLimits(psPtr);

  if (!legend_->isRaised()) {
    switch (legend_->position()) {
    case Legend::PLOT:
    case Legend::XY:
      legend_->print(psPtr);
      break;
    default:
      break;
    }
  }

  printMarkers(psPtr, MARKER_UNDER);
  printElements(psPtr);
  printActiveElements(psPtr);

  if (legend_->isRaised()) {
    switch (legend_->position()) {
    case Legend::PLOT:
    case Legend::XY:
      legend_->print(psPtr);
      break;
    default:
      break;
    }
  }
  printMarkers(psPtr, MARKER_ABOVE);

  psPtr->append("\n");
  psPtr->append("% Unset clipping\n");
  psPtr->append("grestore\n\n");
  psPtr->append("showpage\n");
  psPtr->append("%Trailer\n");
  psPtr->append("grestore\n");
  psPtr->append("end\n");
  psPtr->append("%EOF\n");

 error:
  width_ = Tk_Width(tkwin_);
  height_ = Tk_Height(tkwin_);
  reconfigure();

  // Redraw the graph in order to re-calculate the layout as soon as
  // possible. This is in the case the crosshairs are active.
  flags |= LAYOUT;
  eventuallyRedraw();

  return result;
}

void Graph::eventuallyRedraw() 
{
  if (flags & GRAPH_DELETED)
    return;

  if (!(flags & REDRAW_PENDING)) {
    flags |= REDRAW_PENDING;
    Tcl_DoWhenIdle(DisplayGraph, this);
  }
}

void Graph::extents(Region2d* regionPtr)
{
  GraphOptions* ops = (GraphOptions*)ops_;

  regionPtr->left = (double)(hOffset_ - ops->xPad);
  regionPtr->top = (double)(vOffset_ - ops->yPad);
  regionPtr->right = (double)(hOffset_ + hRange_ + ops->xPad);
  regionPtr->bottom = (double)(vOffset_ + vRange_ + ops->yPad);
}

int Graph::invoke(const Ensemble* ensemble, int cmdIndex,
		  int objc, Tcl_Obj* const objv[])
{
  while (cmdIndex < objc) {
    int index;
    if (Tcl_GetIndexFromObjStruct(interp_, objv[cmdIndex], ensemble, sizeof(ensemble[0]), "command", 0, &index) != TCL_OK)
      return TCL_ERROR;

    if (ensemble[index].proc)
      return ensemble[index].proc(this, interp_, objc, objv);

    ensemble = ensemble[index].subensemble;
    ++cmdIndex;
  }

  Tcl_WrongNumArgs(interp_, cmdIndex, objv, "option ?arg ...?");
  return TCL_ERROR;
}

void Graph::reconfigure()
{
  configure();
  legend_->configure();
  configureElements();
  configureAxes();
  configureMarkers();
}

// Margins

void Graph::drawMargins(Drawable drawable)
{
  GraphOptions* ops = (GraphOptions*)ops_;
  Rectangle rects[4];

  // Draw the four outer rectangles which encompass the plotting
  // surface. This clears the surrounding area and clips the plot.
  rects[0].x = rects[0].y = rects[3].x = rects[1].x = 0;
  rects[0].width = rects[3].width = width_;
  rects[0].height = top_;
  rects[3].y = bottom_;
  rects[3].height = height_ - bottom_;
  rects[2].y = rects[1].y = top_;
  rects[1].width = left_;
  rects[2].height = rects[1].height = bottom_ - top_;
  rects[2].x = right_;
  rects[2].width = width_ - right_;

  Tk_Fill3DRectangle(tkwin_, drawable, ops->normalBg, 
		     rects[0].x, rects[0].y, rects[0].width, rects[0].height, 
		     0, TK_RELIEF_FLAT);
  Tk_Fill3DRectangle(tkwin_, drawable, ops->normalBg, 
		     rects[1].x, rects[1].y, rects[1].width, rects[1].height, 
		     0, TK_RELIEF_FLAT);
  Tk_Fill3DRectangle(tkwin_, drawable, ops->normalBg, 
		     rects[2].x, rects[2].y, rects[2].width, rects[2].height, 
		     0, TK_RELIEF_FLAT);
  Tk_Fill3DRectangle(tkwin_, drawable, ops->normalBg, 
		     rects[3].x, rects[3].y, rects[3].width, rects[3].height, 
		     0, TK_RELIEF_FLAT);

  // Draw 3D border around the plotting area
  if (ops->plotBW > 0) {
    int x = left_ - ops->plotBW;
    int y = top_ - ops->plotBW;
    int w = (right_ - left_) + (2*ops->plotBW);
    int h = (bottom_ - top_) + (2*ops->plotBW);
    Tk_Draw3DRectangle(tkwin_, drawable, ops->normalBg, 
		       x, y, w, h, ops->plotBW, ops->plotRelief);
  }
  
  if (ops->title) {
    TextStyle ts(this, &ops->titleTextStyle);
    ts.drawText(drawable, ops->title, titleX_, titleY_);
  }
}

void Graph::printMargins(PSOutput* psPtr)
{
  GraphOptions* ops = (GraphOptions*)ops_;
  PostscriptOptions* pops = (PostscriptOptions*)postscript_->ops_;
  Rectangle margin[4];

  margin[0].x = margin[0].y = margin[3].x = margin[1].x = 0;
  margin[0].width = margin[3].width = width_;
  margin[0].height = top_;
  margin[3].y = bottom_;
  margin[3].height = height_ - bottom_;
  margin[2].y = margin[1].y = top_;
  margin[1].width = left_;
  margin[2].height = margin[1].height = bottom_ - top_;
  margin[2].x = right_;
  margin[2].width = width_ - right_;

  // Clear the surrounding margins and clip the plotting surface
  if (pops->decorations)
    psPtr->setBackground(Tk_3DBorderColor(ops->normalBg));
  else
    psPtr->setClearBackground();

  psPtr->append("% Margins\n");
  psPtr->fillRectangles(margin, 4);
    
  if (pops->decorations) {
    psPtr->append("% Interior 3D border\n");
    if (ops->plotBW > 0) {
      int x = left_ - ops->plotBW;
      int y = top_ - ops->plotBW;
      int w = (right_ - left_) + (2*ops->plotBW);
      int h = (bottom_ - top_) + (2*ops->plotBW);
      psPtr->print3DRectangle(ops->normalBg, (double)x, (double)y, w, h,
			      ops->plotBW, ops->plotRelief);
    }
  }

  if (ops->title) {
    psPtr->append("% Graph title\n");
    TextStyle ts(this, &ops->titleTextStyle);
    ts.printText(psPtr, ops->title, titleX_, titleY_);
  }
}

// Pens

void Graph::destroyPens()
{
  Tcl_HashSearch iter;
  for (Tcl_HashEntry *hPtr = Tcl_FirstHashEntry(&penTable_, &iter);
       hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
    Pen* penPtr = (Pen*)Tcl_GetHashValue(hPtr);
    delete penPtr;
  }
  Tcl_DeleteHashTable(&penTable_);
}

int Graph::getPen(Tcl_Obj* objPtr, Pen** penPtrPtr)
{
  *penPtrPtr = NULL;
  const char *name = Tcl_GetString(objPtr);
  if (!name || !name[0])
    return TCL_ERROR;

  Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&penTable_, name);
  if (!hPtr) {
    Tcl_AppendResult(interp_, "can't find pen \"", name, "\" in \"", 
		     Tk_PathName(tkwin_), "\"", NULL);
    return TCL_ERROR;
  }

  *penPtrPtr = (Pen*)Tcl_GetHashValue(hPtr);

  return TCL_OK;
}

// Elements

void Graph::destroyElements()
{
  Tcl_HashSearch iter;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&elements_.table, &iter);
       hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
    Element* elemPtr = (Element*)Tcl_GetHashValue(hPtr);
    legend_->removeElement(elemPtr);
    delete elemPtr;
  }

  Tcl_DeleteHashTable(&elements_.table);
  Tcl_DeleteHashTable(&elements_.tagTable);
  delete elements_.displayList;
}

void Graph::configureElements()
{
  for (ChainLink* link = Chain_FirstLink(elements_.displayList); link;
       link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->configure();
  }
}

void Graph::mapElements()
{
  for (ChainLink* link = Chain_FirstLink(elements_.displayList); link;
       link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->map();
  }
}

void Graph::drawElements(Drawable drawable)
{
  // Draw with respect to the stacking order
  for (ChainLink* link=Chain_LastLink(elements_.displayList); link;
       link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->draw(drawable);
  }
}

void Graph::drawActiveElements(Drawable drawable)
{
  for (ChainLink* link = Chain_LastLink(elements_.displayList); link;
       link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->drawActive(drawable);
  }
}

void Graph::printElements(PSOutput* psPtr)
{
  for (ChainLink* link = Chain_LastLink(elements_.displayList); link;
       link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->print(psPtr);
  }
}

void Graph::printActiveElements(PSOutput* psPtr)
{
  for (ChainLink* link = Chain_LastLink(elements_.displayList); link;
       link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    elemPtr->printActive(psPtr);
  }
}

int Graph::getElement(Tcl_Obj *objPtr, Element **elemPtrPtr)
{
  *elemPtrPtr =NULL;
  const char* name = Tcl_GetString(objPtr);
  if (!name || !name[0])
    return TCL_ERROR;

  Tcl_HashEntry*hPtr = Tcl_FindHashEntry(&elements_.table, name);
  if (!hPtr) {
    Tcl_AppendResult(interp_, "can't find element \"", name, "\" in \"",
		     Tk_PathName(tkwin_), "\"", NULL);
    return TCL_ERROR;
  }

  *elemPtrPtr = (Element*)Tcl_GetHashValue(hPtr);
  return TCL_OK;
}

ClientData Graph::elementTag(const char *tagName)
{
  int isNew;
  Tcl_HashEntry* hPtr = 
    Tcl_CreateHashEntry(&elements_.tagTable, tagName, &isNew);
  return Tcl_GetHashKey(&elements_.tagTable, hPtr);
}

// Markers

void Graph::destroyMarkers()
{
  Tcl_HashSearch iter;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&markers_.table, &iter); 
       hPtr; hPtr=Tcl_NextHashEntry(&iter)) {
    Marker* markerPtr = (Marker*)Tcl_GetHashValue(hPtr);
    delete markerPtr;
  }
  Tcl_DeleteHashTable(&markers_.table);
  Tcl_DeleteHashTable(&markers_.tagTable);
  delete markers_.displayList;
}


void Graph::configureMarkers()
{
  for (ChainLink* link = Chain_FirstLink(markers_.displayList); link;
       link = Chain_NextLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    markerPtr->configure();
  }
}

void Graph::mapMarkers()
{
  for (ChainLink* link = Chain_FirstLink(markers_.displayList); link;
       link = Chain_NextLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    MarkerOptions* mops = (MarkerOptions*)markerPtr->ops();

    if (mops->hide)
      continue;

    if ((flags & MAP_MARKERS) || (markerPtr->flags & MAP_ITEM)) {
      markerPtr->map();
      markerPtr->flags &= ~MAP_ITEM;
    }
  }

  flags &= ~MAP_MARKERS;
}

void Graph::drawMarkers(Drawable drawable, int under)
{
  for (ChainLink* link = Chain_LastLink(markers_.displayList); link;
       link = Chain_PrevLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    MarkerOptions* mops = (MarkerOptions*)markerPtr->ops();

    if ((mops->drawUnder != under) || markerPtr->clipped_ || mops->hide)
      continue;

    if (isElementHidden(markerPtr))
      continue;

    markerPtr->draw(drawable);
  }
}

void Graph::printMarkers(PSOutput* psPtr, int under)
{
  for (ChainLink* link = Chain_LastLink(markers_.displayList); link;
       link = Chain_PrevLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    MarkerOptions* mops = (MarkerOptions*)markerPtr->ops();
    if (mops->drawUnder != under)
      continue;

    if (mops->hide)
      continue;

    if (isElementHidden(markerPtr))
      continue;

    psPtr->format("%% Marker \"%s\" is a %s.\n", 
		  markerPtr->name_, markerPtr->className());
    markerPtr->print(psPtr);
  }
}

ClientData Graph::markerTag(const char* tagName)    
{
  int isNew;
  Tcl_HashEntry* hPtr = Tcl_CreateHashEntry(&markers_.tagTable, tagName,&isNew);
  return Tcl_GetHashKey(&markers_.tagTable, hPtr);
}

Marker* Graph::nearestMarker(int x, int y, int under)
{
  Point2d point;
  point.x = (double)x;
  point.y = (double)y;
  for (ChainLink* link = Chain_FirstLink(markers_.displayList); link;
       link = Chain_NextLink(link)) {
    Marker* markerPtr = (Marker*)Chain_GetValue(link);
    MarkerOptions* mops = (MarkerOptions*)markerPtr->ops();

    if ((markerPtr->flags & MAP_ITEM) || mops->hide)
      continue;

    if (isElementHidden(markerPtr))
      continue;

    if (mops->drawUnder == under)
      if (markerPtr->pointIn(&point))
	return markerPtr;
  }
  return NULL;
}

int Graph::isElementHidden(Marker* markerPtr)
{
  MarkerOptions* mops = (MarkerOptions*)markerPtr->ops();

  if (mops->elemName) {
    Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&elements_.table, mops->elemName);
    if (hPtr) {
      Element* elemPtr = (Element*)Tcl_GetHashValue(hPtr);
      ElementOptions* eops = (ElementOptions*)elemPtr->ops();
      if (!elemPtr->link || eops->hide)
	return 1;
    }
  }
  return 0;
}

// Axis

int Graph::createAxes()
{
  for (int ii=0; ii<4; ii++) {
    int isNew;
    Tcl_HashEntry* hPtr = 
      Tcl_CreateHashEntry(&axes_.table, axisNames[ii].name, &isNew);
    Chain* chain = new Chain();

    Axis* axisPtr = new Axis(this, axisNames[ii].name, ii, hPtr);
    if (!axisPtr)
      return TCL_ERROR;
    AxisOptions* ops = (AxisOptions*)axisPtr->ops();

    Tcl_SetHashValue(hPtr, axisPtr);

    axisPtr->refCount_ = 1;
    axisPtr->use_ =1;
    
    axisPtr->setClass(!(ii&1) ? CID_AXIS_X : CID_AXIS_Y);

    if (Tk_InitOptions(interp_, (char*)axisPtr->ops(), 
		       axisPtr->optionTable(), tkwin_) != TCL_OK)
      return TCL_ERROR;

    if (axisPtr->configure() != TCL_OK)
      return TCL_ERROR;

    if ((axisPtr->margin_ == MARGIN_RIGHT) || (axisPtr->margin_ == MARGIN_TOP))
      ops->hide = 1;

    axisChain_[ii] = chain;
    axisPtr->link = chain->append(axisPtr);
    axisPtr->chain = chain;
  }
  return TCL_OK;
}

int Graph::createAxis(int objc, Tcl_Obj* const objv[])
{
  char *string = Tcl_GetString(objv[3]);
  if (string[0] == '-') {
    Tcl_AppendResult(interp_, "name of axis \"", string, 
		     "\" can't start with a '-'", NULL);
    return TCL_ERROR;
  }

  int isNew;
  Tcl_HashEntry* hPtr = Tcl_CreateHashEntry(&axes_.table, string, &isNew);
  if (!isNew) {
    Tcl_AppendResult(interp_, "axis \"", string, "\" already exists in \"",
		     Tcl_GetString(objv[0]), "\"", NULL);
    return TCL_ERROR;
  }

  Axis* axisPtr = new Axis(this, Tcl_GetString(objv[3]), MARGIN_NONE, hPtr);
  if (!axisPtr)
    return TCL_ERROR;

  Tcl_SetHashValue(hPtr, axisPtr);

  if ((Tk_InitOptions(interp_, (char*)axisPtr->ops(), axisPtr->optionTable(), tkwin_) != TCL_OK) || (AxisObjConfigure(axisPtr, interp_, objc-4, objv+4) != TCL_OK)) {
    delete axisPtr;
    return TCL_ERROR;
  }

  return TCL_OK;
}

void Graph::destroyAxes()
{
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry *hPtr=Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr=Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    delete axisPtr;
  }
  Tcl_DeleteHashTable(&axes_.table);

  for (int ii=0; ii<4; ii++)
    delete axisChain_[ii];

  Tcl_DeleteHashTable(&axes_.tagTable);
  delete axes_.displayList;
}

void Graph::configureAxes()
{
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry *hPtr=Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    axisPtr->configure();
  }
}

void Graph::mapAxes()
{
  GraphOptions* ops = (GraphOptions*)ops_;

  for (int ii=0; ii<4; ii++) {
    int count =0;
    int offset =0;

    Chain* chain = ops->margins[ii].axes;
    for (ChainLink* link=Chain_FirstLink(chain); link; 
	 link = Chain_NextLink(link)) {
      Axis *axisPtr = (Axis*)Chain_GetValue(link);
      AxisOptions* aops = (AxisOptions*)axisPtr->ops();
      if (!axisPtr->use_)
	continue;

      if (aops->reqNumMajorTicks <= 0)
	aops->reqNumMajorTicks = 4;

      if (ops->stackAxes)
	axisPtr->mapStacked(count, ii);
      else 
	axisPtr->map(offset, ii);

      if (aops->showGrid)
	axisPtr->mapGridlines();

      offset += axisPtr->isHorizontal() ? axisPtr->height_ : axisPtr->width_;
      count++;
    }
  }
}

void Graph::drawAxes(Drawable drawable)
{
  GraphOptions* ops = (GraphOptions*)ops_;

  for (int ii=0; ii<4; ii++) {
    for (ChainLink* link = Chain_LastLink(ops->margins[ii].axes); link;
	 link = Chain_PrevLink(link)) {
      Axis *axisPtr = (Axis*)Chain_GetValue(link);
      axisPtr->draw(drawable);
    }
  }
}

void Graph::drawAxesLimits(Drawable drawable)
{
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    axisPtr->drawLimits(drawable);
  }
}

void Graph::drawAxesGrids(Drawable drawable)
{
  GraphOptions* ops = (GraphOptions*)ops_;

  for (int ii=0; ii<4; ii++) {
    for (ChainLink* link = Chain_FirstLink(ops->margins[ii].axes); link;
	 link = Chain_NextLink(link)) {
      Axis *axisPtr = (Axis*)Chain_GetValue(link);
      axisPtr->drawGrids(drawable);
    }
  }
}

void Graph::printAxes(PSOutput* psPtr) 
{
  GraphOptions* ops = (GraphOptions*)ops_;

  for (Margin *mp = ops->margins, *mend = mp + 4; mp < mend; mp++) {
    for (ChainLink* link = Chain_FirstLink(mp->axes); link; 
	 link = Chain_NextLink(link)) {
      Axis *axisPtr = (Axis*)Chain_GetValue(link);
      axisPtr->print(psPtr);
    }
  }
}

void Graph::printAxesGrids(PSOutput* psPtr) 
{
  GraphOptions* ops = (GraphOptions*)ops_;

  for (int ii=0; ii<4; ii++) {
    for (ChainLink* link = Chain_FirstLink(ops->margins[ii].axes); link;
	 link = Chain_NextLink(link)) {
      Axis *axisPtr = (Axis*)Chain_GetValue(link);
      axisPtr->printGrids(psPtr);
    }
  }
}

void Graph::printAxesLimits(PSOutput* psPtr)
{
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    axisPtr->printLimits(psPtr);
  }
}

int Graph::getAxis(Tcl_Obj *objPtr, Axis **axisPtrPtr)
{
  *axisPtrPtr = NULL;
  const char* name = Tcl_GetString(objPtr);
  if (!name || !name[0])
    return TCL_ERROR;

  Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&axes_.table, name);
  if (!hPtr) {
    Tcl_AppendResult(interp_, "can't find axis \"", name, "\" in \"", 
		     Tk_PathName(tkwin_), "\"", NULL);
    return TCL_ERROR;
  }

  *axisPtrPtr = (Axis*)Tcl_GetHashValue(hPtr);
  return TCL_OK;
}

ClientData Graph::axisTag(const char *tagName)
{
  int isNew;
  Tcl_HashEntry *hPtr = Tcl_CreateHashEntry(&axes_.tagTable, tagName, &isNew);
  return Tcl_GetHashKey(&axes_.tagTable, hPtr);
}

void Graph::adjustAxes() 
{
  GraphOptions* ops = (GraphOptions*)ops_;

  if (ops->inverted) {
    ops->leftMargin.axes   = axisChain_[0];
    ops->bottomMargin.axes = axisChain_[1];
    ops->rightMargin.axes  = axisChain_[2];
    ops->topMargin.axes    = axisChain_[3];
  }
  else {
    ops->leftMargin.axes   = axisChain_[1];
    ops->bottomMargin.axes = axisChain_[0];
    ops->rightMargin.axes  = axisChain_[3];
    ops->topMargin.axes    = axisChain_[2];
  }
}

Point2d Graph::map2D(double x, double y, Axis* xAxis, Axis* yAxis)
{
  GraphOptions* ops = (GraphOptions*)ops_;

  Point2d point;
  if (ops->inverted) {
    point.x = yAxis->hMap(y);
    point.y = xAxis->vMap(x);
  }
  else {
    point.x = xAxis->hMap(x);
    point.y = yAxis->vMap(y);
  }
  return point;
}

Point2d Graph::invMap2D(double x, double y, Axis* xAxis, Axis* yAxis)
{
  GraphOptions* ops = (GraphOptions*)ops_;

  Point2d point;
  if (ops->inverted) {
    point.x = xAxis->invVMap(y);
    point.y = yAxis->invHMap(x);
  }
  else {
    point.x = xAxis->invHMap(x);
    point.y = yAxis->invVMap(y);
  }
  return point;
}

void Graph::resetAxes()
{
  // Step 1:  Reset all axes. Initialize the data limits of the axis to
  // impossible values.
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry* hPtr = Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    axisPtr->min_ = axisPtr->valueRange_.min = DBL_MAX;
    axisPtr->max_ = axisPtr->valueRange_.max = -DBL_MAX;
  }

  // Step 2:  For each element that's to be displayed, get the smallest
  // and largest data values mapped to each X and Y-axis.  This
  // will be the axis limits if the user doesn't override them 
  // with -min and -max options.
  for (ChainLink* link = Chain_FirstLink(elements_.displayList); link;
       link = Chain_NextLink(link)) {
    Region2d exts;

    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemops = (ElementOptions*)elemPtr->ops();
    elemPtr->extents(&exts);
    elemops->xAxis->getDataLimits(exts.left, exts.right);
    elemops->yAxis->getDataLimits(exts.top, exts.bottom);
  }

  // Step 3:  Now that we know the range of data values for each axis,
  // set axis limits and compute a sweep to generate tick values.
  for (Tcl_HashEntry* hPtr = Tcl_FirstHashEntry(&axes_.table, &cursor);
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    AxisOptions* ops = (AxisOptions*)axisPtr->ops();
    axisPtr->fixRange();

    double min = axisPtr->min_;
    double max = axisPtr->max_;
    if ((!isnan(axisPtr->scrollMin_)) && (min < axisPtr->scrollMin_))
      min = axisPtr->scrollMin_;

    if ((!isnan(axisPtr->scrollMax_)) && (max > axisPtr->scrollMax_))
      max = axisPtr->scrollMax_;

    if (ops->logScale)
      axisPtr->logScale(min, max);
    else
      axisPtr->linearScale(min, max);
  }
}

Axis* Graph::nearestAxis(int x, int y)
{
  Tcl_HashSearch cursor;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&axes_.table, &cursor); 
       hPtr; hPtr = Tcl_NextHashEntry(&cursor)) {
    Axis *axisPtr = (Axis*)Tcl_GetHashValue(hPtr);
    AxisOptions* ops = (AxisOptions*)axisPtr->ops();
    if (ops->hide || !axisPtr->use_)
      continue;

    if (ops->showTicks) {
      for (ChainLink* link = Chain_FirstLink(axisPtr->tickLabels_); link;
	   link = Chain_NextLink(link)) {	
	TickLabel *labelPtr = (TickLabel*)Chain_GetValue(link);
	double rw, rh;
	Point2d bbox[5];
	getBoundingBox(labelPtr->width, labelPtr->height, ops->tickAngle,
		       &rw, &rh, bbox);
	Point2d t;
	t = anchorPoint(labelPtr->anchorPos.x, labelPtr->anchorPos.y,
			rw, rh, axisPtr->tickAnchor_);
	t.x = x - t.x - (rw * 0.5);
	t.y = y - t.y - (rh * 0.5);

	bbox[4] = bbox[0];
	if (pointInPolygon(&t, bbox, 5)) {
	  return axisPtr;
	}
      }
    }

    if (ops->title) {
      int w, h;
      double rw, rh;
      Point2d bbox[5];
      getTextExtents(ops->titleFont, ops->title, -1, &w, &h);
      getBoundingBox(w, h, axisPtr->titleAngle_, &rw, &rh, bbox);
      Point2d t = anchorPoint(axisPtr->titlePos_.x, axisPtr->titlePos_.y, 
			      rw, rh, axisPtr->titleAnchor_);
      // Translate the point so that the 0,0 is the upper left 
      // corner of the bounding box
      t.x = x - t.x - (rw * 0.5);
      t.y = y - t.y - (rh * 0.5);
	    
      bbox[4] = bbox[0];
      if (pointInPolygon(&t, bbox, 5)) {
	return axisPtr;
      }
    }
    if (ops->lineWidth > 0) {
      if ((x <= axisPtr->right_) && (x >= axisPtr->left_) && 
	  (y <= axisPtr->bottom_) && (y >= axisPtr->top_)) {
	return axisPtr;
      }
    }
  }

  return NULL;
}
 
// Bind

const char** Graph::getTags(ClientData object, ClassId classId, int* num)
{
  const char** tags =NULL;

  switch (classId) {
  case CID_ELEM_BAR:		
  case CID_ELEM_LINE: 
    {
      Element* ptr = (Element*)object;
      ElementOptions* ops = (ElementOptions*)ptr->ops();
      int cnt =0;
      for (const char** pp=ops->tags; *pp; pp++)
	cnt++;
      cnt +=2;

      tags = new const char*[cnt];
      tags[0] = (const char*)elementTag(ptr->name_);
      tags[1] = (const char*)elementTag(ptr->className());
      int ii=2;
      for (const char** pp = ops->tags; *pp; pp++, ii++)
	tags[ii] = (const char*)elementTag(*pp);

      *num = cnt;
      return tags;
    }
    break;
  case CID_AXIS_X:
  case CID_AXIS_Y:
    {
      Axis* ptr = (Axis*)object;
      AxisOptions* ops = (AxisOptions*)ptr->ops();
      int cnt =0;
      for (const char** pp=ops->tags; *pp; pp++)
	cnt++;
      cnt +=2;

      tags = new const char*[cnt];
      tags[0] = (const char*)axisTag(ptr->name_);
      tags[1] = (const char*)axisTag(ptr->className());
      int ii=2;
      for (const char** pp = ops->tags; *pp; pp++, ii++)
	tags[ii] = (const char*)axisTag(*pp);

      *num = cnt;
      return tags;
    }
    break;
  case CID_MARKER_BITMAP:
  case CID_MARKER_LINE:
  case CID_MARKER_POLYGON:
  case CID_MARKER_TEXT:
    {
      Marker* ptr = (Marker*)object;
      MarkerOptions* ops = (MarkerOptions*)ptr->ops();
      int cnt =0;
      for (const char** pp=ops->tags; *pp; pp++)
	cnt++;
      cnt +=2;

      tags = new const char*[cnt];
      tags[0] = (const char*)markerTag(ptr->name_);
      tags[1] = (const char*)markerTag(ptr->className());
      int ii=2;
      for (const char** pp = ops->tags; *pp; pp++, ii++)
	tags[ii] = (const char*)markerTag(*pp);

      *num = cnt;
      return tags;
    }
    break;
  default:
    break;
  }

  return NULL;
}

ClientData Graph::pickEntry(int xx, int yy, ClassId* classIdPtr)
{
  if (flags & (LAYOUT | MAP_MARKERS)) {
    *classIdPtr = CID_NONE;
    return NULL;
  }

  // Sample coordinate is in one of the graph margins. Can only pick an axis.
  Region2d exts;
  extents(&exts);
  if (xx>=exts.right || xx<exts.left || yy>=exts.bottom || yy<exts.top) {
    Axis* axisPtr = nearestAxis(xx, yy);
    if (axisPtr) {
      *classIdPtr = axisPtr->classId();
      return axisPtr;
    }
  }

  // From top-to-bottom check:
  // 1. markers drawn on top (-under false).
  // 2. elements using its display list back to front.
  // 3. markers drawn under element (-under true).
  Marker* markerPtr = nearestMarker(xx, yy, 0);
  if (markerPtr) {
    *classIdPtr = markerPtr->classId();
    return markerPtr;
  }

  GraphOptions* ops = (GraphOptions*)ops_;
  ClosestSearch* searchPtr = &ops->search;
  searchPtr->index = -1;
  searchPtr->x = xx;
  searchPtr->y = yy;
  searchPtr->dist = (double)(searchPtr->halo + 1);
	
  for (ChainLink* link = Chain_LastLink(elements_.displayList); link;
       link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* eops = (ElementOptions*)elemPtr->ops();
    if (eops->hide)
      continue;
    elemPtr->closest();
  }

  // Found an element within the minimum halo distance.
  if (searchPtr->dist <= (double)searchPtr->halo) {
    *classIdPtr = searchPtr->elemPtr->classId();
    return searchPtr->elemPtr;
  }

  markerPtr = nearestMarker(xx, yy, 1);
  if (markerPtr) {
    *classIdPtr = markerPtr->classId();
    return markerPtr;
  }

  *classIdPtr = CID_NONE;
  return NULL;
}

int Graph::getXY(const char* string, int* xPtr, int* yPtr)
{
  if (!string || !*string) {
    *xPtr = -SHRT_MAX;
    *yPtr = -SHRT_MAX;
    return TCL_OK;
  }

  if (*string != '@') {
    Tcl_AppendResult(interp_, "bad position \"", string, 
		     "\": should be \"@x,y\"", (char *)NULL);
    return TCL_ERROR;
  }

  char* comma = (char*)strchr(string + 1, ',');
  if (!comma) {
    Tcl_AppendResult(interp_, "bad position \"", string, 
		     "\": should be \"@x,y\"", (char *)NULL);
    return TCL_ERROR;
  }

  *comma = '\0';
  int x, y;
  int result = ((Tk_GetPixels(interp_, tkwin_, string + 1, &x) == TCL_OK) &&
		(Tk_GetPixels(interp_, tkwin_, comma + 1, &y) == TCL_OK));
  *comma = ',';
  if (!result) {
    Tcl_AppendResult(interp_, ": can't parse position \"", string, "\"",
		     (char *)NULL);
    return TCL_ERROR;
  }

  *xPtr = x;
  *yPtr = y;
  return TCL_OK;
}

// Graphics

void Graph::drawSegments(Drawable drawable, GC gc, 
			 Segment2d* segments, int nSegments)
{
  for (Segment2d *sp = segments, *send = sp + nSegments; sp < send; sp++)
    XDrawLine(display_, drawable, gc, (int)sp->p.x, (int)sp->p.y, (int)sp->q.x, (int)sp->q.y);
}

GC Graph::getPrivateGC(unsigned long gcMask, XGCValues *valuePtr)
{
  Pixmap pixmap = None;
  Drawable drawable = Tk_WindowId(tkwin_);
  Display* display = Tk_Display(tkwin_);
  if (drawable == None)
    drawable = RootWindow(Tk_Display(tkwin_),Tk_ScreenNumber(tkwin_));

  GC gc = XCreateGC(display, drawable, gcMask, valuePtr);
  if (pixmap != None)
    Tk_FreePixmap(display, pixmap);

  return gc;
}

void Graph::freePrivateGC(GC gc)
{
  Tk_FreeXId(display_, (XID)XGContextFromGC(gc));
  XFreeGC(display_, gc);
}

void Graph::setDashes(GC gc, Dashes* dashesPtr)
{
  XSetDashes(display_, gc, dashesPtr->offset, (const char*)dashesPtr->values,
	     (int)strlen((char*)dashesPtr->values));
}
