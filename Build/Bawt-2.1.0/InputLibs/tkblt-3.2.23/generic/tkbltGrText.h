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

#ifndef __BltText_h__
#define __BltText_h__

#include <tk.h>

#include "tkbltGrMisc.h"

namespace Blt {
  class Graph;
  class PSOutput;

  typedef struct {
    Tk_Anchor anchor;
    XColor* color;
    Tk_Font font;
    double angle;
    Tk_Justify justify;
  } TextStyleOptions;

  class TextStyle {
  protected:
    Graph* graphPtr_;
    void* ops_;
    GC gc_;
    int manageOptions_;

  public:
    int xPad_;
    int yPad_;

  protected:
    void resetStyle();
    Point2d rotateText(int, int, int, int);

  public:
    TextStyle(Graph*);
    TextStyle(Graph*, TextStyleOptions*);
    virtual ~TextStyle();

    void* ops() {return ops_;}
    void drawText(Drawable, const char*, int, int);
    void drawText(Drawable, const char*, double, double);
    void drawTextBBox(Drawable, const char*, int, int, int*, int*);
    void printText(PSOutput*, const char*, int, int);
    void printText(PSOutput*, const char*, double, double);
    void getExtents(const char*, int*, int*);
  };
};

#endif
