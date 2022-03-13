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
#include "tkbltGrMarkerText.h"
#include "tkbltGrMarkerOption.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_ANCHOR, "-anchor", "anchor", "Anchor", 
   "center", -1, Tk_Offset(TextMarkerOptions, anchor), 0, NULL, 0},
  {TK_OPTION_COLOR, "-background", "background", "Background",
   NULL, -1, Tk_Offset(TextMarkerOptions, fillColor),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags", 
   "Text all", -1, Tk_Offset(TextMarkerOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_CUSTOM, "-coords", "coords", "Coords",
   NULL, -1, Tk_Offset(TextMarkerOptions, worldPts), 
   TK_OPTION_NULL_OK, &coordsObjOption, 0},
  {TK_OPTION_STRING, "-element", "element", "Element", 
   NULL, -1, Tk_Offset(TextMarkerOptions, elemName),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-foreground", 0},
  {TK_OPTION_SYNONYM, "-fill", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_FONT, "-font", "font", "Font", 
   STD_FONT_NORMAL, -1, Tk_Offset(TextMarkerOptions, style.font), 0, NULL, 0},
  {TK_OPTION_COLOR, "-foreground", "foreground", "Foreground",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(TextMarkerOptions, style.color),
   0, NULL, 0},
  {TK_OPTION_JUSTIFY, "-justify", "justify", "Justify",
   "left", -1, Tk_Offset(TextMarkerOptions, style.justify), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(TextMarkerOptions, hide), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-mapx", "mapX", "MapX",
   "x", -1, Tk_Offset(TextMarkerOptions, xAxis), 0, &xAxisObjOption, 0},
  {TK_OPTION_CUSTOM, "-mapy", "mapY", "MapY", 
   "y", -1, Tk_Offset(TextMarkerOptions, yAxis), 0, &yAxisObjOption, 0},
  {TK_OPTION_SYNONYM, "-outline", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-foreground", 0},
  {TK_OPTION_DOUBLE, "-rotate", "rotate", "Rotate", 
   "0", -1, Tk_Offset(TextMarkerOptions, style.angle), 0, NULL, 0},
  {TK_OPTION_STRING, "-text", "text", "Text", 
   NULL, -1, Tk_Offset(TextMarkerOptions, string), TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_BOOLEAN, "-under", "under", "Under",
   "no", -1, Tk_Offset(TextMarkerOptions, drawUnder), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-xoffset", "xOffset", "XOffset",
   "0", -1, Tk_Offset(TextMarkerOptions, xOffset), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-yoffset", "yOffset", "YOffset",
   "0", -1, Tk_Offset(TextMarkerOptions, yOffset), 0, NULL, 0},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

TextMarker::TextMarker(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr) 
  : Marker(graphPtr, name, hPtr)
{
  ops_ = (TextMarkerOptions*)calloc(1, sizeof(TextMarkerOptions));
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  ops->style.anchor =TK_ANCHOR_NW;
  ops->style.color =NULL;
  ops->style.font =NULL;
  ops->style.angle =0;
  ops->style.justify =TK_JUSTIFY_LEFT;

  anchorPt_.x =0;
  anchorPt_.y =0;
  width_ =0;
  height_ =0;
  fillGC_ =NULL;

  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);
}

TextMarker::~TextMarker()
{
}

int TextMarker::configure()
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  ops->style.angle = (float)fmod(ops->style.angle, 360.0);
  if (ops->style.angle < 0.0)
    ops->style.angle += 360.0;

  GC newGC = NULL;
  XGCValues gcValues;
  unsigned long gcMask;
  if (ops->fillColor) {
    gcMask = GCForeground;
    gcValues.foreground = ops->fillColor->pixel;
    newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
  }
  if (fillGC_)
    Tk_FreeGC(graphPtr_->display_, fillGC_);
  fillGC_ = newGC;

  return TCL_OK;
}

void TextMarker::draw(Drawable drawable) 
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  if (!ops->string)
    return;

  if (fillGC_) {
    XPoint points[4];
    for (int ii=0; ii<4; ii++) {
      points[ii].x = (short)(outline_[ii].x + anchorPt_.x);
      points[ii].y = (short)(outline_[ii].y + anchorPt_.y);
    }
    XFillPolygon(graphPtr_->display_, drawable, fillGC_, points, 4,
		 Convex, CoordModeOrigin);
  }

  TextStyle ts(graphPtr_, &ops->style);
  ts.drawText(drawable, ops->string, anchorPt_.x, anchorPt_.y);
}

void TextMarker::map()
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  if (!ops->string)
    return;

  if (!ops->worldPts || (ops->worldPts->num < 1))
    return;

  width_ =0;
  height_ =0;

  int w, h;
  TextStyle ts(graphPtr_, &ops->style);
  ts.getExtents(ops->string, &w, &h);

  double rw;
  double rh;
  graphPtr_->getBoundingBox(w, h, ops->style.angle, &rw, &rh, outline_);
  width_ = (int)rw;
  height_ = (int)rh;
  for (int ii=0; ii<4; ii++) {
    outline_[ii].x += rw * 0.5;
    outline_[ii].y += rh * 0.5;
  }
  outline_[4].x = outline_[0].x;
  outline_[4].y = outline_[0].y;

  Point2d anchorPtr = mapPoint(ops->worldPts->points, ops->xAxis, ops->yAxis);
  anchorPtr = graphPtr_->anchorPoint(anchorPtr.x, anchorPtr.y, 
				     width_, height_, ops->anchor);
  anchorPtr.x += ops->xOffset;
  anchorPtr.y += ops->yOffset;

  Region2d extents;
  extents.left = anchorPtr.x;
  extents.top = anchorPtr.y;
  extents.right = anchorPtr.x + width_ - 1;
  extents.bottom = anchorPtr.y + height_ - 1;
  clipped_ = boxesDontOverlap(graphPtr_, &extents);

  anchorPt_ = anchorPtr;
}

int TextMarker::pointIn(Point2d *samplePtr)
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  if (!ops->string)
    return 0;

  if (ops->style.angle != 0.0) {
    Point2d points[5];

    // Figure out the bounding polygon (isolateral) for the text and see
    // if the point is inside of it.
    for (int ii=0; ii<5; ii++) {
      points[ii].x = outline_[ii].x + anchorPt_.x;
      points[ii].y = outline_[ii].y + anchorPt_.y;
    }
    return pointInPolygon(samplePtr, points, 5);
  } 

  return ((samplePtr->x >= anchorPt_.x) && 
	  (samplePtr->x < (anchorPt_.x + width_)) &&
	  (samplePtr->y >= anchorPt_.y) && 
	  (samplePtr->y < (anchorPt_.y + height_)));
}

int TextMarker::regionIn(Region2d *extsPtr, int enclosed)
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  if (ops->style.angle != 0.0) {
    Point2d points[5];
    for (int ii=0; ii<4; ii++) {
      points[ii].x = outline_[ii].x + anchorPt_.x;
      points[ii].y = outline_[ii].y + anchorPt_.y;
    }
    return regionInPolygon(extsPtr, points, 4, enclosed);
  } 

  if (enclosed)
    return ((anchorPt_.x >= extsPtr->left) &&
	    (anchorPt_.y >= extsPtr->top) && 
	    ((anchorPt_.x + width_) <= extsPtr->right) &&
	    ((anchorPt_.y + height_) <= extsPtr->bottom));

  return !((anchorPt_.x >= extsPtr->right) ||
	   (anchorPt_.y >= extsPtr->bottom) ||
	   ((anchorPt_.x + width_) <= extsPtr->left) ||
	   ((anchorPt_.y + height_) <= extsPtr->top));
}

void TextMarker::print(PSOutput* psPtr)
{
  TextMarkerOptions* ops = (TextMarkerOptions*)ops_;

  if (!ops->string)
    return;

  if (fillGC_) {
    Point2d points[4];
    for (int ii=0; ii<4; ii++) {
      points[ii].x = outline_[ii].x + anchorPt_.x;
      points[ii].y = outline_[ii].y + anchorPt_.y;
    }
    psPtr->setBackground(ops->fillColor);
    psPtr->fillPolygon(points, 4);
  }

  TextStyle ts(graphPtr_, &ops->style);
  ts.printText(psPtr, ops->string, anchorPt_.x, anchorPt_.y);
}
