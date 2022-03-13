/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1993-2004 George A Howlett.
 *
 *	Permission is hereby granted, free of charge, to any person
 *	obtaining a copy of this software and associated documentation
 *	files (the "Software"), to deal in the Software without
 *	restriction, including without limitation the rights to use,
 *	copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the
 *	Software is furnished to do so, subject to the following
 *	conditions:
 *
 *	The above copyright notice and this permission notice shall be
 *	included in all copies or substantial portions of the
 *	Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 *	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 *	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 *	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 *	OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 *	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 *	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef __BltGrHairs_h__
#define __BltGrHairs_h__

#include <tk.h>

#include "tkbltGrMisc.h"

namespace Blt {
  class Graph;

  typedef struct {
    XColor* colorPtr;
    Dashes dashes;
    int lineWidth;
    int x;
    int y;
  } CrosshairsOptions;

  class Crosshairs {
  protected:
    Graph* graphPtr_;
    Tk_OptionTable optionTable_;
    void* ops_;

    int visible_;
    GC gc_;
    Point segArr_[4];

  public:
    Crosshairs(Graph*);
    virtual ~Crosshairs();

    int configure();
    void map();
    void draw(Drawable);

    void on();
    void off();
    int isOn() {return visible_;}

    Tk_OptionTable optionTable() {return optionTable_;}
    void* ops() {return ops_;}
  };
};

#endif
