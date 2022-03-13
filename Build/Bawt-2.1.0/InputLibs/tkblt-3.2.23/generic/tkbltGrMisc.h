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

#ifndef __BltGrMisc_h__
#define __BltGrMisc_h__

#include <iostream>
#include <sstream>
#include <iomanip>
using namespace std;

#include <tk.h>

#ifndef MIN
#   define MIN(x,y) ((x)<(y)?(x):(y))
#endif

#ifndef MAX
#   define MAX(x,y) ((x)>(y)?(x):(y))
#endif

#define	GRAPH_DELETED   (1<<1)
#define REDRAW_PENDING  (1<<2)
#define FOCUS           (1<<3)

#define	MAP_ITEM        (1<<4)

#define RESET           (1<<5)
#define LAYOUT          (1<<6)
#define	MAP_MARKERS     (1<<7)
#define	CACHE           (1<<8)

#define MARGIN_NONE	-1
#define MARGIN_BOTTOM	0		/* x */
#define MARGIN_LEFT	1 		/* y */
#define MARGIN_TOP	2		/* x2 */
#define MARGIN_RIGHT	3		/* y2 */

#define LineIsDashed(d) ((d).values[0] != 0)

namespace Blt {
  class Graph;

  typedef struct {
    int x, y;
  } Point;

  typedef struct {
    int x, y;
    unsigned width, height;
  } Rectangle;

  typedef struct {
    double x;
    double y;
  } Point2d;

  typedef struct {
    Point2d p;
    Point2d q;
  } Segment2d;

  typedef struct {
    double left;
    double right;
    double top;
    double bottom;
  } Region2d;

  typedef enum {
    CID_NONE, CID_AXIS_X, CID_AXIS_Y, CID_ELEM_BAR, CID_ELEM_LINE,
    CID_MARKER_BITMAP, CID_MARKER_IMAGE, CID_MARKER_LINE, CID_MARKER_POLYGON,
    CID_MARKER_TEXT
  } ClassId;

  typedef struct {
    unsigned char values[12];
    int offset;
  } Dashes;

  extern char* dupstr(const char*);
  extern Graph* getGraphFromWindowData(Tk_Window tkwin);

  extern int pointInPolygon(Point2d *samplePtr, Point2d *screenPts, 
			    int nScreenPts);
  extern int polyRectClip(Region2d *extsPtr, Point2d *inputPts,
			  int nInputPts, Point2d *outputPts);
  extern int lineRectClip(Region2d *regionPtr, Point2d *p, Point2d *q);
  extern Point2d getProjection (int x, int y, Point2d *p, Point2d *q);
};

#endif
