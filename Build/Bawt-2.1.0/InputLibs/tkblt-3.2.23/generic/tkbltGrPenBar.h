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

#ifndef __BltGrPenBar_h__
#define __BltGrPenBar_h__

#include <tk.h>

#include "tkbltGrPen.h"

namespace Blt {

  typedef struct {
    int errorBarShow;
    int errorBarLineWidth;
    int errorBarCapWidth;
    XColor* errorBarColor;
    int valueShow;
    const char *valueFormat;
    TextStyleOptions valueStyle;

    XColor* outlineColor;
    Tk_3DBorder fill;
    int borderWidth;
    int relief;
  } BarPenOptions;

  class BarPen : public Pen {
  public:
    GC fillGC_;
    GC outlineGC_;
    GC errorBarGC_;

  public:
    BarPen(Graph*, const char*, Tcl_HashEntry*);
    BarPen(Graph*, const char*, void*);
    virtual ~BarPen();

    ClassId classId() {return CID_ELEM_BAR;}
    const char* className() {return "BarElement";}
    const char* typeName() {return "bar";}

    int configure();
  };
};

#endif
