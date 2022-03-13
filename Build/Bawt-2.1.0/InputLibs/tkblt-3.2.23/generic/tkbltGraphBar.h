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

#ifndef __BltGraphBar_h__
#define __BltGraphBar_h__

#include <tk.h>

#include "tkbltGraph.h"

namespace Blt {

  typedef struct {
    double value;
    Axis* xAxis;
    Axis* yAxis;
  } BarSetKey;

  class BarGroup {
  public:
    int nSegments;
    Axis* xAxis;
    Axis* yAxis;
    double sum;
    int count;
    double lastY;
    size_t index;

  public:
    BarGroup();
  };

  typedef struct {
    double aspect;
    Tk_3DBorder normalBg;
    int borderWidth;
    Margin margins[4];
    Tk_Cursor cursor;
    TextStyleOptions titleTextStyle;
    int reqHeight;
    XColor* highlightBgColor;
    XColor* highlightColor;
    int highlightWidth;
    int inverted;
    Tk_3DBorder plotBg;
    int plotBW;
    int xPad;
    int yPad;
    int plotRelief;
    int relief;
    ClosestSearch search;
    int stackAxes;
    const char *takeFocus; // nor used in C code
    const char *title;
    int reqWidth;
    int reqPlotWidth;
    int reqPlotHeight;

    // bar graph
    int barMode;
    double barWidth;
    double baseline;
  } BarGraphOptions;

  class BarGraph : public Graph {
  public:
    enum BarMode {INFRONT, STACKED, ALIGNED, OVERLAP};

  public:
    BarGroup* barGroups_;
    int nBarGroups_;
    Tcl_HashTable setTable_;
    int maxBarSetSize_;

  protected:
    void resetAxes();
    void mapElements();
    void initBarSets();
    void destroyBarSets();
    void resetBarSets();
    void computeBarStacks();

  public:
    BarGraph(ClientData, Tcl_Interp*, int, Tcl_Obj* const []);
    virtual ~BarGraph();

    int configure();
    int createPen(const char*, int, Tcl_Obj* const []);
    int createElement(int, Tcl_Obj* const []);
  };
};

#endif
