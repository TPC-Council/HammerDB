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

#ifndef __BltGrMarkerLine_h__
#define __BltGrMarkerLine_h__

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
    XColor* fillColor;
    int joinStyle;
    int lineWidth;
    XColor* outlineColor;
  } LineMarkerOptions;

  class LineMarker : public Marker {
  protected:
    GC gc_;
    Segment2d* segments_;
    int nSegments_;

  protected:
    int configure();
    void draw(Drawable);
    void map();
    int pointIn(Point2d*);
    int regionIn(Region2d*, int);
    void print(PSOutput*);
    int pointInSegments(Point2d *samplePtr, Segment2d *segments, 
			int nSegments, double halo);

  public:
    LineMarker(Graph*, const char*, Tcl_HashEntry*);
    virtual ~LineMarker();

    ClassId classId() {return CID_MARKER_LINE;}
    const char* className() {return "LineMarker";}
    const char* typeName() {return "line";}
  };
};

#endif
