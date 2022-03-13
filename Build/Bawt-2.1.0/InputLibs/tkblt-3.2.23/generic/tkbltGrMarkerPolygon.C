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

#include "tkbltGraph.h"
#include "tkbltGrMarkerPolygon.h"
#include "tkbltGrMarkerOption.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags", 
   "Polygon all", -1, Tk_Offset(PolygonMarkerOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_CUSTOM, "-cap", "cap", "Cap", 
   "butt", -1, Tk_Offset(PolygonMarkerOptions, capStyle),
   0, &capStyleObjOption, 0},
  {TK_OPTION_CUSTOM, "-coords", "coords", "Coords",
   NULL, -1, Tk_Offset(PolygonMarkerOptions, worldPts), 
   TK_OPTION_NULL_OK, &coordsObjOption, 0},
  {TK_OPTION_CUSTOM, "-dashes", "dashes", "Dashes",
   NULL, -1, Tk_Offset(PolygonMarkerOptions, dashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, 0},
  {TK_OPTION_STRING, "-element", "element", "Element", 
   NULL, -1, Tk_Offset(PolygonMarkerOptions, elemName),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_COLOR, "-fill", "fill", "Fill", 
   NULL, -1, Tk_Offset(PolygonMarkerOptions, fill),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_CUSTOM, "-join", "join", "Join", 
   "miter", -1, Tk_Offset(PolygonMarkerOptions, joinStyle),
   0, &joinStyleObjOption, 0},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "LineWidth",
   "1", -1, Tk_Offset(PolygonMarkerOptions, lineWidth), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(PolygonMarkerOptions, hide), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-mapx", "mapX", "MapX",
   "x", -1, Tk_Offset(PolygonMarkerOptions, xAxis), 0, &xAxisObjOption, 0},
  {TK_OPTION_CUSTOM, "-mapy", "mapY", "MapY", 
   "y", -1, Tk_Offset(PolygonMarkerOptions, yAxis), 0, &yAxisObjOption, 0},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline", 
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(PolygonMarkerOptions, outline), 
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_BOOLEAN, "-under", "under", "Under",
   "no", -1, Tk_Offset(PolygonMarkerOptions, drawUnder), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-xoffset", "xOffset", "XOffset",
   "0", -1, Tk_Offset(PolygonMarkerOptions, xOffset), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-yoffset", "yOffset", "YOffset",
   "0", -1, Tk_Offset(PolygonMarkerOptions, yOffset), 0, NULL, 0},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

PolygonMarker::PolygonMarker(Graph* graphPtr, const char* name, 
			     Tcl_HashEntry* hPtr) 
  : Marker(graphPtr, name, hPtr)
{
  ops_ = (PolygonMarkerOptions*)calloc(1, sizeof(PolygonMarkerOptions));
  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);

  screenPts_ =NULL;
  outlineGC_ =NULL;
  fillGC_ =NULL;
  fillPts_ =NULL;
  nFillPts_ =0;
  outlinePts_ =NULL;
  nOutlinePts_ =0;
}

PolygonMarker::~PolygonMarker()
{
  if (fillGC_)
    Tk_FreeGC(graphPtr_->display_, fillGC_);
  if (outlineGC_)
    graphPtr_->freePrivateGC(outlineGC_);
  delete [] fillPts_;
  delete [] outlinePts_;
  delete [] screenPts_;
}

int PolygonMarker::configure()
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;

  // outlineGC
  unsigned long gcMask = (GCLineWidth | GCLineStyle);
  XGCValues gcValues;
  if (ops->outline) {
    gcMask |= GCForeground;
    gcValues.foreground = ops->outline->pixel;
  }
  gcMask |= (GCCapStyle | GCJoinStyle);
  gcValues.cap_style = ops->capStyle;
  gcValues.join_style = ops->joinStyle;
  gcValues.line_style = LineSolid;
  gcValues.dash_offset = 0;
  gcValues.line_width = ops->lineWidth;
  if (LineIsDashed(ops->dashes))
    gcValues.line_style = LineOnOffDash;

  GC newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (LineIsDashed(ops->dashes))
    graphPtr_->setDashes(newGC, &ops->dashes);
  if (outlineGC_)
    graphPtr_->freePrivateGC(outlineGC_);
  outlineGC_ = newGC;

  // fillGC
  gcMask = 0;
  if (ops->fill) {
    gcMask |= GCForeground;
    gcValues.foreground = ops->fill->pixel;
  }
  newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
  if (fillGC_)
    Tk_FreeGC(graphPtr_->display_, fillGC_);
  fillGC_ = newGC;

  return TCL_OK;
}

void PolygonMarker::draw(Drawable drawable)
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;

  // fill region
  if ((nFillPts_ > 0) && (ops->fill)) {
    XPoint* points = new XPoint[nFillPts_];
    if (!points)
      return;

    XPoint* dp = points;
    for (Point2d *sp = fillPts_, *send = sp + nFillPts_; sp < send; sp++) {
      dp->x = (short)sp->x;
      dp->y = (short)sp->y;
      dp++;
    }

    XFillPolygon(graphPtr_->display_, drawable, fillGC_, points, 
		 nFillPts_, Complex, CoordModeOrigin);
    delete [] points;
  }

  // outline
  if ((nOutlinePts_ > 0) && (ops->lineWidth > 0) && (ops->outline))
    graphPtr_->drawSegments(drawable, outlineGC_, outlinePts_, nOutlinePts_);
}

void PolygonMarker::map()
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;

  if (outlinePts_) {
    delete [] outlinePts_;
    outlinePts_ = NULL;
    nOutlinePts_ = 0;
  }

  if (fillPts_) {
    delete [] fillPts_;
    fillPts_ = NULL;
    nFillPts_ = 0;
  }

  if (screenPts_) {
    delete [] screenPts_;
    screenPts_ = NULL;
  }

  if (!ops->worldPts || ops->worldPts->num < 3)
    return;

  // Allocate and fill a temporary array to hold the screen coordinates of
  // the polygon.

  int nScreenPts = ops->worldPts->num + 1;
  Point2d* screenPts = new Point2d[nScreenPts + 1];
  {
    Point2d* dp = screenPts;
    for (Point2d *sp = ops->worldPts->points, *send = sp + ops->worldPts->num; 
	 sp < send; sp++) {
      *dp = mapPoint(sp, ops->xAxis, ops->yAxis);
      dp->x += ops->xOffset;
      dp->y += ops->yOffset;
      dp++;
    }
    *dp = screenPts[0];
  }
  Region2d extents;
  graphPtr_->extents(&extents);

  clipped_ = 1;
  if (ops->fill) {
    Point2d* lfillPts = new Point2d[nScreenPts * 3];
    int n = polyRectClip(&extents, screenPts, ops->worldPts->num,lfillPts);
    if (n < 3)
      delete [] lfillPts;
    else {
      nFillPts_ = n;
      fillPts_ = lfillPts;
      clipped_ = 0;
    }
  }
  if ((ops->outline) && (ops->lineWidth > 0)) { 
    // Generate line segments representing the polygon outline.  The
    // resulting outline may or may not be closed from viewport clipping.
    Segment2d* outlinePts = new Segment2d[nScreenPts];
    if (!outlinePts)
      return;

    // Note that this assumes that the point array contains an extra point
    // that closes the polygon.
    Segment2d* segPtr = outlinePts;
    for (Point2d *sp=screenPts, *send=sp+(nScreenPts - 1); sp < send; sp++) {
      segPtr->p = sp[0];
      segPtr->q = sp[1];
      if (lineRectClip(&extents, &segPtr->p, &segPtr->q)) {
	segPtr++;
      }
    }
    nOutlinePts_ = segPtr - outlinePts;
    outlinePts_ = outlinePts;
    if (nOutlinePts_ > 0)
      clipped_ = 0;
  }

  screenPts_ = screenPts;
}

int PolygonMarker::pointIn(Point2d *samplePtr)
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;

  if (ops->worldPts && (ops->worldPts->num >= 3) && screenPts_)
    return pointInPolygon(samplePtr, screenPts_, ops->worldPts->num + 1);

  return 0;
}

int PolygonMarker::regionIn(Region2d *extsPtr, int enclosed)
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;
    
  if (ops->worldPts && (ops->worldPts->num >= 3) && screenPts_)
    return regionInPolygon(extsPtr, screenPts_, ops->worldPts->num, enclosed);

  return 0;
}

void PolygonMarker::print(PSOutput* psPtr)
{
  PolygonMarkerOptions* ops = (PolygonMarkerOptions*)ops_;

  if (ops->fill) {
    psPtr->printPolyline(fillPts_, nFillPts_);
    psPtr->setForeground(ops->fill);
    psPtr->append("fill\n");
  }

  if ((ops->lineWidth > 0) && (ops->outline)) {
    psPtr->setLineAttributes(ops->outline, ops->lineWidth, &ops->dashes,
			     ops->capStyle, ops->joinStyle);
    psPtr->append("/DashesProc {} def\n");

    psPtr->printSegments(outlinePts_, nOutlinePts_);
  }
}

