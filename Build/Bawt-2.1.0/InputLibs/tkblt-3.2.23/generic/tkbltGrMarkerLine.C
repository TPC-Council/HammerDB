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

#include <float.h>
#include <stdlib.h>

#include <cmath>

#include "tkbltGraph.h"
#include "tkbltGrMarkerLine.h"
#include "tkbltGrMarkerOption.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

#define BOUND(x, lo, hi) (((x) > (hi)) ? (hi) : ((x) < (lo)) ? (lo) : (x))

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags", 
   "Line all", -1, Tk_Offset(LineMarkerOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_CUSTOM, "-cap", "cap", "Cap", 
   "butt", -1, Tk_Offset(LineMarkerOptions, capStyle),
   0, &capStyleObjOption, 0},
  {TK_OPTION_CUSTOM, "-coords", "coords", "Coords",
   NULL, -1, Tk_Offset(LineMarkerOptions, worldPts), 
   TK_OPTION_NULL_OK, &coordsObjOption, 0},
  {TK_OPTION_CUSTOM, "-dashes", "dashes", "Dashes",
   NULL, -1, Tk_Offset(LineMarkerOptions, dashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, 0},
  {TK_OPTION_PIXELS, "-dashoffset", "dashOffset", "DashOffset",
   "0", -1, Tk_Offset(LineMarkerOptions, dashes.offset), 0, NULL, 0},
  {TK_OPTION_STRING, "-element", "element", "Element", 
   NULL, -1, Tk_Offset(LineMarkerOptions, elemName),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_COLOR, "-fill", "fill", "Fill",
   NULL, -1, Tk_Offset(LineMarkerOptions, fillColor),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_CUSTOM, "-join", "join", "Join", 
   "miter", -1, Tk_Offset(LineMarkerOptions, joinStyle),
   0, &joinStyleObjOption, 0},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "LineWidth",
   "1", -1, Tk_Offset(LineMarkerOptions, lineWidth), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(LineMarkerOptions, hide), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-mapx", "mapX", "MapX",
   "x", -1, Tk_Offset(LineMarkerOptions, xAxis), 0, &xAxisObjOption, 0},
  {TK_OPTION_CUSTOM, "-mapy", "mapY", "MapY", 
   "y", -1, Tk_Offset(LineMarkerOptions, yAxis), 0, &yAxisObjOption, 0},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LineMarkerOptions, outlineColor), 
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_BOOLEAN, "-under", "under", "Under",
   "no", -1, Tk_Offset(LineMarkerOptions, drawUnder), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-xoffset", "xOffset", "XOffset",
   "0", -1, Tk_Offset(LineMarkerOptions, xOffset), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-yoffset", "yOffset", "YOffset",
   "0", -1, Tk_Offset(LineMarkerOptions, yOffset), 0, NULL, 0},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

LineMarker::LineMarker(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr) 
  : Marker(graphPtr, name, hPtr)
{
  ops_ = (LineMarkerOptions*)calloc(1, sizeof(LineMarkerOptions));
  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);

  gc_ =NULL;
  segments_ =NULL;
  nSegments_ =0;
}

LineMarker::~LineMarker()
{
  if (gc_)
    graphPtr_->freePrivateGC(gc_);
  delete [] segments_;
}

int LineMarker::configure()
{
  LineMarkerOptions* ops = (LineMarkerOptions*)ops_;

  unsigned long gcMask = (GCLineWidth | GCLineStyle | GCCapStyle | GCJoinStyle);
  XGCValues gcValues;
  if (ops->outlineColor) {
    gcMask |= GCForeground;
    gcValues.foreground = ops->outlineColor->pixel;
  }
  if (ops->fillColor) {
    gcMask |= GCBackground;
    gcValues.background = ops->fillColor->pixel;
  }
  gcValues.cap_style = ops->capStyle;
  gcValues.join_style = ops->joinStyle;
  gcValues.line_width = ops->lineWidth;
  gcValues.line_style = LineSolid;
  if (LineIsDashed(ops->dashes)) {
    gcValues.line_style = 
      (gcMask & GCBackground) ? LineDoubleDash : LineOnOffDash;
  }

  GC newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (gc_)
    graphPtr_->freePrivateGC(gc_);

  if (LineIsDashed(ops->dashes))
    graphPtr_->setDashes(newGC, &ops->dashes);
  gc_ = newGC;

  return TCL_OK;
}

void LineMarker::draw(Drawable drawable)
{
  if (nSegments_ > 0)
    graphPtr_->drawSegments(drawable, gc_, segments_, nSegments_);
}

void LineMarker::map()
{
  LineMarkerOptions* ops = (LineMarkerOptions*)ops_;

  delete [] segments_;
  segments_ = NULL;
  nSegments_ = 0;

  if (!ops->worldPts || (ops->worldPts->num < 2))
    return;

  Region2d extents;
  graphPtr_->extents(&extents);

  // Allow twice the number of world coordinates. The line will represented
  // as series of line segments, not one continous polyline.  This is
  // because clipping against the plot area may chop the line into several
  // disconnected segments.

  Segment2d* segments = new Segment2d[ops->worldPts->num];
  Point2d* srcPtr = ops->worldPts->points;
  Point2d p = mapPoint(srcPtr, ops->xAxis, ops->yAxis);
  p.x += ops->xOffset;
  p.y += ops->yOffset;

  Segment2d* segPtr = segments;
  Point2d* pend;
  for (srcPtr++, pend = ops->worldPts->points + ops->worldPts->num; 
       srcPtr < pend; srcPtr++) {
    Point2d next = mapPoint(srcPtr, ops->xAxis, ops->yAxis);
    next.x += ops->xOffset;
    next.y += ops->yOffset;
    Point2d q = next;

    if (lineRectClip(&extents, &p, &q)) {
      segPtr->p = p;
      segPtr->q = q;
      segPtr++;
    }
    p = next;
  }
  nSegments_ = segPtr - segments;
  segments_ = segments;
  clipped_ = (nSegments_ == 0);
}

int LineMarker::pointIn(Point2d *samplePtr)
{
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;
  return pointInSegments(samplePtr, segments_, nSegments_, 
			 (double)gops->search.halo);
}

int LineMarker::pointInSegments(Point2d* samplePtr, Segment2d* segments,
				int nSegments, double halo)
{
  double minDist = DBL_MAX;
  for (Segment2d *sp = segments, *send = sp + nSegments; sp < send; sp++) {
    Point2d t = getProjection((int)samplePtr->x, (int)samplePtr->y, 
			  &sp->p, &sp->q);
    double right;
    double left;
    if (sp->p.x > sp->q.x) {
      right = sp->p.x;
      left = sp->q.x;
    }
    else {
      right = sp->q.x;
      left = sp->p.x;
    }

    double top;
    double bottom;
    if (sp->p.y > sp->q.y) {
      bottom = sp->p.y;
      top = sp->q.y;
    }
    else {
      bottom = sp->q.y;
      top = sp->p.y;
    }

    Point2d p;
    p.x = BOUND(t.x, left, right);
    p.y = BOUND(t.y, top, bottom);

    double dist = hypot(p.x - samplePtr->x, p.y - samplePtr->y);
    if (dist < minDist)
      minDist = dist;
  }

  return (minDist < halo);
}

int LineMarker::regionIn(Region2d *extsPtr, int enclosed)
{
  LineMarkerOptions* ops = (LineMarkerOptions*)ops_;

  if (!ops->worldPts || ops->worldPts->num < 2)
    return 0;

  if (enclosed) {
    for (Point2d *pp = ops->worldPts->points, *pend = pp + ops->worldPts->num; 
	 pp < pend; pp++) {
      Point2d p = mapPoint(pp, ops->xAxis, ops->yAxis);
      if ((p.x < extsPtr->left) && (p.x > extsPtr->right) &&
	  (p.y < extsPtr->top) && (p.y > extsPtr->bottom)) {
	return 0;
      }
    }
    return 1;
  }
  else {
    int count = 0;
    for (Point2d *pp=ops->worldPts->points, *pend=pp+(ops->worldPts->num - 1); 
	 pp < pend; pp++) {
      Point2d p = mapPoint(pp, ops->xAxis, ops->yAxis);
      Point2d q = mapPoint(pp + 1, ops->xAxis, ops->yAxis);
      if (lineRectClip(extsPtr, &p, &q))
	count++;
    }
    return (count > 0);		/* At least 1 segment passes through
				 * region. */
  }
}

void LineMarker::print(PSOutput* psPtr)
{
  LineMarkerOptions* ops = (LineMarkerOptions*)ops_;

  if (nSegments_ > 0) {
    psPtr->setLineAttributes(ops->outlineColor, ops->lineWidth,
			     &ops->dashes, ops->capStyle, ops->joinStyle);
    if ((LineIsDashed(ops->dashes)) && (ops->fillColor)) {
      psPtr->append("/DashesProc {\n  gsave\n    ");
      psPtr->setBackground(ops->fillColor);
      psPtr->append("    ");
      psPtr->setDashes(NULL);
      psPtr->append("stroke\n");
      psPtr->append("grestore\n");
      psPtr->append("} def\n");
    } 
    else
      psPtr->append("/DashesProc {} def\n");

    psPtr->printSegments(segments_, nSegments_);
  }
}


