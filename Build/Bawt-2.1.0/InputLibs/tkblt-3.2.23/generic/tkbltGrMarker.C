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
#include <float.h>

#include <cmath>

#include "tkbltGraph.h"
#include "tkbltGrBind.h"
#include "tkbltGrMarker.h"
#include "tkbltGrAxis.h"
#include "tkbltGrMisc.h"

using namespace Blt;

Marker::Marker(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
{
  optionTable_ =NULL;
  ops_ =NULL;

  graphPtr_ =graphPtr;  
  name_ = dupstr(name);
  hashPtr_ = hPtr;
  link =NULL;
  flags =0;
  clipped_ =0;
}

Marker::~Marker()
{
  graphPtr_->bindTable_->deleteBindings(this);

  if (link)
    graphPtr_->markers_.displayList->deleteLink(link);

  if (hashPtr_)
    Tcl_DeleteHashEntry(hashPtr_);

  delete [] name_;

  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

double Marker::HMap(Axis *axisPtr, double x)
{
  AxisOptions* ops = (AxisOptions*)axisPtr->ops();

  if (x == DBL_MAX)
    x = 1.0;
  else if (x == -DBL_MAX)
    x = 0.0;
  else {
    if (ops->logScale) {
      if (x > 0.0)
	x = log10(x);
      else if (x < 0.0)
	x = 0.0;
    }
    x = (x - axisPtr->axisRange_.min) * axisPtr->axisRange_.scale;
  }
  if (ops->descending)
    x = 1.0 - x;

  // Horizontal transformation
  return (x * axisPtr->screenRange_ + axisPtr->screenMin_);
}

double Marker::VMap(Axis *axisPtr, double y)
{
  AxisOptions* ops = (AxisOptions*)axisPtr->ops();

  if (y == DBL_MAX)
    y = 1.0;
  else if (y == -DBL_MAX)
    y = 0.0;
  else {
    if (ops->logScale) {
      if (y > 0.0)
	y = log10(y);
      else if (y < 0.0)
	y = 0.0;
    }
    y = (y - axisPtr->axisRange_.min) * axisPtr->axisRange_.scale;
  }
  if (ops->descending)
    y = 1.0 - y;

  // Vertical transformation
  return (((1.0 - y) * axisPtr->screenRange_) + axisPtr->screenMin_);
}

Point2d Marker::mapPoint(Point2d* pointPtr, Axis* xAxis, Axis* yAxis)
{
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;
  Point2d result;
  if (gops->inverted) {
    result.x = HMap(yAxis, pointPtr->y);
    result.y = VMap(xAxis, pointPtr->x);
  }
  else {
    result.x = HMap(xAxis, pointPtr->x);
    result.y = VMap(yAxis, pointPtr->y);
  }

  return result;
}

int Marker::boxesDontOverlap(Graph* graphPtr_, Region2d *extsPtr)
{
  return (((double)graphPtr_->right_ < extsPtr->left) ||
	  ((double)graphPtr_->bottom_ < extsPtr->top) ||
	  (extsPtr->right < (double)graphPtr_->left_) ||
	  (extsPtr->bottom < (double)graphPtr_->top_));
}

int Marker::regionInPolygon(Region2d *regionPtr, Point2d *points, int nPoints,
			    int enclosed)
{
  if (enclosed) {
    // All points of the polygon must be inside the rectangle.
    for (Point2d *pp = points, *pend = pp + nPoints; pp < pend; pp++) {
      if ((pp->x < regionPtr->left) || (pp->x > regionPtr->right) ||
	  (pp->y < regionPtr->top) || (pp->y > regionPtr->bottom)) {
	return 0;	/* One point is exterior. */
      }
    }
    return 1;
  }
  else {
    // If any segment of the polygon clips the bounding region, the
    // polygon overlaps the rectangle.
    points[nPoints] = points[0];
    for (Point2d *pp = points, *pend = pp + nPoints; pp < pend; pp++) {
      Point2d p = *pp;
      Point2d q = *(pp + 1);
      if (lineRectClip(regionPtr, &p, &q))
	return 1;
    }

    // Otherwise the polygon and rectangle are either disjoint or
    // enclosed.  Check if one corner of the rectangle is inside the polygon.
    Point2d r;
    r.x = regionPtr->left;
    r.y = regionPtr->top;

    return pointInPolygon(&r, points, nPoints);
  }
}

