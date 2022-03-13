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

#ifndef __BltGrElemBar_h__
#define __BltGrElemBar_h__

#include <cmath>

#include <tk.h>

#include "tkbltGrElem.h"
#include "tkbltGrPenBar.h"

namespace Blt {

  typedef struct {
    float x1;
    float y1;
    float x2;
    float y2;
  } BarRegion;

  typedef struct {
    Weight weight;
    BarPen* penPtr;
    Rectangle* bars;
    int nBars;
    GraphSegments xeb;
    GraphSegments yeb;
    int symbolSize;
    int errorBarCapWidth;
  } BarStyle;

  typedef struct {
    Element* elemPtr;
    const char *label;
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
    BarPen* builtinPenPtr;
    BarPen* activePenPtr;
    BarPen* normalPenPtr;
    BarPenOptions builtinPen;

    // derived
    double barWidth;
    const char *groupName;
  } BarElementOptions;

  class BarElement : public Element {
  protected:
    BarPen* builtinPenPtr;
    int* barToData_;
    Rectangle* bars_;
    int* activeToData_;
    Rectangle* activeRects_;
    int nBars_;
    int nActive_;
    GraphSegments xeb_;
    GraphSegments yeb_;

  protected:
    void ResetStylePalette(Chain*);
    void checkStacks(Axis*, Axis*, double*, double*);
    void mergePens(BarStyle**);
    void mapActive();
    void reset();
    void mapErrorBars(BarStyle**);
    void drawSegments(Drawable, BarPen*, Rectangle*, int);
    void drawValues(Drawable, BarPen*, Rectangle*, int, int*);
    void printSegments(PSOutput*, BarPen*, Rectangle*, int);
    void printValues(PSOutput*, BarPen*, Rectangle*, int, int*);

  public:
    BarElement(Graph*, const char*, Tcl_HashEntry*);
    virtual ~BarElement();

    ClassId classId() {return CID_ELEM_BAR;}
    const char* className() {return "BarElement";}
    const char* typeName() {return "bar";}

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
