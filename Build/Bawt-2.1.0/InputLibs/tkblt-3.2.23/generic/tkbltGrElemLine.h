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

#ifndef __BltGrElemLine_h__
#define __BltGrElemLine_h__

#include <tk.h>

#include "tkbltGraph.h"
#include "tkbltGrElem.h"
#include "tkbltGrPenLine.h"

namespace Blt {

  typedef struct {
    Point2d *screenPts;
    int nScreenPts;
    int *styleMap;
    int *map;
  } MapInfo;

  typedef struct {
    Point2d *points;
    int length;
    int *map;
  } GraphPoints;

  typedef struct {
    int start;
    GraphPoints screenPts;
  } bltTrace;

  typedef struct {
    Weight weight;
    LinePen* penPtr;
    GraphPoints symbolPts;
    GraphSegments xeb;
    GraphSegments yeb;
    int symbolSize;
    int errorBarCapWidth;
  } LineStyle;

  typedef struct {
    Element* elemPtr;
    const char* label;
    char** tags;
    Axis* xAxis;
    Axis* yAxis;
    ElemCoords coords;
    ElemValues* w;
    ElemValues* xError;
    ElemValues* yError;
    ElemValues* xHigh;
    ElemValues* xLow;
    ElemValues* yHigh;
    ElemValues* yLow;
    int hide;
    int legendRelief;
    Chain* stylePalette;
    LinePen *builtinPenPtr;
    LinePen *activePenPtr;
    LinePen *normalPenPtr;
    LinePenOptions builtinPen;

    // derived
    Tk_3DBorder fillBg;
    int reqMaxSymbols;
    double rTolerance;
    int scaleSymbols;
    int reqSmooth;
    int penDir;
  } LineElementOptions;

  class LineElement : public Element {
  public:
    enum PenDirection {INCREASING, DECREASING, BOTH_DIRECTIONS};
    enum Smoothing {LINEAR, STEP, CUBIC, QUADRATIC, CATROM};

  protected:
    LinePen* builtinPenPtr;
    Smoothing smooth_;
    Point2d *fillPts_;
    int nFillPts_;
    GraphPoints symbolPts_;
    GraphPoints activePts_;
    GraphSegments xeb_;
    GraphSegments yeb_;
    int symbolInterval_;
    int symbolCounter_;
    Chain* traces_;

    void drawCircle(Display*, Drawable, LinePen*, int, Point2d*, int);
    void drawSquare(Display*, Drawable, LinePen*, int, Point2d*, int);
    void drawSCross(Display*, Drawable, LinePen*, int, Point2d*, int);
    void drawCross(Display*, Drawable, LinePen*, int, Point2d*, int);
    void drawDiamond(Display*, Drawable, LinePen*, int, Point2d*, int);
    void drawArrow(Display*, Drawable, LinePen*, int, Point2d*, int);

  protected:
    int scaleSymbol(int);
    void getScreenPoints(MapInfo*);
    void reducePoints(MapInfo*, double);
    void generateSteps(MapInfo*);
    void generateSpline(MapInfo*);
    void generateParametricSpline(MapInfo*);
    void mapSymbols(MapInfo*);
    void mapActiveSymbols();
    void mergePens(LineStyle**);
    int outCode(Region2d*, Point2d*);
    int clipSegment(Region2d*, int, int, Point2d*, Point2d*);
    void saveTrace(int, int, MapInfo*);
    void freeTraces();
    void mapTraces(MapInfo*);
    void mapFillArea(MapInfo*);
    void mapErrorBars(LineStyle**);
    void reset();
    int closestTrace();
    void closestPoint(ClosestSearch*);
    void drawSymbols(Drawable, LinePen*, int, int, Point2d*);
    void drawTraces(Drawable, LinePen*);
    void drawValues(Drawable, LinePen*, int, Point2d*, int*);
    void setLineAttributes(PSOutput*, LinePen*);
    void printTraces(PSOutput*, LinePen*);
    void printValues(PSOutput*, LinePen*, int, Point2d*, int*);
    void printSymbols(PSOutput*, LinePen*, int, int, Point2d*);
    double distanceToLine(int, int, Point2d*, Point2d*, Point2d*);
    double distanceToX(int, int, Point2d*, Point2d*, Point2d*);
    double distanceToY(int, int, Point2d*, Point2d*, Point2d*);
    int simplify(Point2d*, int, int, double, int*);
    double findSplit(Point2d*, int, int, int*);

    int naturalSpline(Point2d*, int, Point2d*, int);
    int quadraticSpline(Point2d*, int, Point2d*, int);
    int naturalParametricSpline(Point2d*, int, Region2d*, int, Point2d*, int);
    int catromParametricSpline(Point2d*, int, Point2d*, int);

  public:
    LineElement(Graph*, const char*, Tcl_HashEntry*);
    virtual ~LineElement();

    ClassId classId() {return CID_ELEM_LINE;}
    const char* className() {return "LineElement";}
    const char* typeName() {return "line";}

    int configure();
    void map();
    void extents(Region2d*);
    void closest();
    void draw(Drawable);
    void drawActive(Drawable);
    void drawSymbol(Drawable, int, int, int);
    void print(PSOutput*);
    void printActive(PSOutput*);
    void printSymbol(PSOutput*, double, double, int);
  };
};

#endif
