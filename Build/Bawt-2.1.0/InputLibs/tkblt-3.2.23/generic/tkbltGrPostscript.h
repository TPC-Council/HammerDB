/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1991-2004 George A Howlett.
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

#ifndef __BltGrPostscript_h__
#define __BltGrPostscript_h__

#include <tk.h>

namespace Blt {
 
  typedef struct {
    int center;
    const char **comments;
    int decorations;
    int footer;
    int greyscale;
    int landscape;
    int level;
    int xPad;
    int yPad;
    int reqPaperWidth;
    int reqPaperHeight;
    int reqWidth;
    int reqHeight;
  } PostscriptOptions;

  class Postscript  {
  public:
    Tk_OptionTable optionTable_;
    void* ops_;
    Graph* graphPtr_;

    int left;
    int bottom;
    int right;
    int top;
    double scale;
    int paperHeight;
    int paperWidth;

  public:
    Postscript(Graph*);
    virtual ~Postscript();
  };
};

#endif
