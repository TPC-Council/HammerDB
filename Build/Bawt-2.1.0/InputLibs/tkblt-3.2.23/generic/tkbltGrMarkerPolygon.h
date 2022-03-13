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

#ifndef __BltGrMarkerPolygon_h__
#define __BltGrMarkerPolygon_h__

#include "tkbltGrMarker.h"

namespace Blt {

  typedef struct {
    const char** tags;
    Coords* worldPts;
    const char* elemName;
    Axis* xAxis;
    Axis* yAxis;
    int hide;
    int drawUnder;
    int xOffset;
    int yOffset;

    int capStyle;
    Dashes dashes;
    XColor* fill;
    int joinStyle;
    int lineWidth;
    XColor* outline;
  } PolygonMarkerOptions;

  class PolygonMarker : public Marker {
  protected:
    Point2d *screenPts_;
    GC outlineGC_;
    GC fillGC_;
    Point2d *fillPts_;
    int nFillPts_;
    Segment2d *outlinePts_;
    int nOutlinePts_;

  protected:
    int configure();
    void draw(Drawable);
    void map();
    int pointIn(Point2d*);
    int regionIn(Region2d*, int);
    void print(PSOutput*);

  public:
    PolygonMarker(Graph*, const char*, Tcl_HashEntry*);
    virtual ~PolygonMarker();

    ClassId classId() {return CID_MARKER_POLYGON;}
    const char* className() {return "PolygonMarker";}
    const char* typeName() {return "polygon";}
  };
};

#endif
