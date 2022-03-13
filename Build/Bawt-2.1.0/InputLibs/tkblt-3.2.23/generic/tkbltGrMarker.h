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

#ifndef __BltGrMarker_h__
#define __BltGrMarker_h__

#include <tk.h>

#include "tkbltChain.h"

#include "tkbltGrMisc.h"
#include "tkbltGrPSOutput.h"

namespace Blt {
  class Graph;
  class Postscript;
  class Axis;

  typedef struct {
    Point2d* points;
    int num;
  } Coords;

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
  } MarkerOptions;

  class Marker {
  protected:
    Tk_OptionTable optionTable_;
    void* ops_;

  public:
    Graph* graphPtr_;
    const char *name_;
    Tcl_HashEntry* hashPtr_;
    ChainLink* link;
    unsigned int flags;		
    int clipped_;

  protected:
    double HMap(Axis*, double);
    double VMap(Axis*, double);
    Point2d mapPoint(Point2d*, Axis*, Axis*);
    int boxesDontOverlap(Graph*, Region2d*);
    int regionInPolygon(Region2d *extsPtr, Point2d *points, 
			int nPoints, int enclosed);

  public:
    Marker(Graph*, const char*, Tcl_HashEntry*);
    virtual ~Marker();

    virtual int configure() =0;
    virtual void draw(Drawable) =0;
    virtual void map() =0;
    virtual int pointIn(Point2d*) =0;
    virtual int regionIn(Region2d*, int) =0;
    virtual void print(PSOutput*) =0;

    virtual ClassId classId() =0;
    virtual const char* className() =0;
    virtual const char* typeName() =0;

    Tk_OptionTable optionTable() {return optionTable_;}
    void* ops() {return ops_;}
  };
};

#endif
