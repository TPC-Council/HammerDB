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

#ifndef __BltGrPenLine_h__
#define __BltGrPenLine_h__

#include "tkbltGrPen.h"

namespace Blt {

  typedef enum {
    SYMBOL_NONE, SYMBOL_SQUARE, SYMBOL_CIRCLE, SYMBOL_DIAMOND, SYMBOL_PLUS,
    SYMBOL_CROSS, SYMBOL_SPLUS, SYMBOL_SCROSS, SYMBOL_TRIANGLE, SYMBOL_ARROW
  } SymbolType;

  typedef struct {
    SymbolType type;
    int size;
    XColor* outlineColor;
    int outlineWidth;
    GC outlineGC;
    XColor* fillColor;
    GC fillGC;
  } Symbol;

  typedef struct {
    int errorBarShow;
    int errorBarLineWidth;
    int errorBarCapWidth;
    XColor* errorBarColor;
    int valueShow;
    const char* valueFormat;
    TextStyleOptions valueStyle;

    Symbol symbol;
    int traceWidth;
    Dashes traceDashes;
    XColor* traceColor;
    XColor* traceOffColor;
  } LinePenOptions;

  class LinePen : public Pen {
  public:
    GC traceGC_;
    GC errorBarGC_;

  public:
    LinePen(Graph*, const char*, Tcl_HashEntry*);
    LinePen(Graph*, const char*, void*);
    virtual ~LinePen();

    ClassId classId() {return CID_ELEM_LINE;}
    const char* className() {return "LineElement";}
    const char* typeName() {return "line";}

    int configure();
  };
};

extern const char* symbolObjOption[];

#endif
