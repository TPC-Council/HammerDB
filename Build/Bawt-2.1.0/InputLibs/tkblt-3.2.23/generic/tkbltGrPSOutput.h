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

#ifndef __Blt_GrPSOutput_h__
#define __Blt_GrPSOutput_h__

#include <tk.h>

#define POSTSCRIPT_BUFSIZ ((BUFSIZ*2)-1)

namespace Blt {
  class Graph;
  class Postscript;

  class PSOutput {
  protected:
    Graph* graphPtr_;
    Tcl_DString dString_;
    char scratchArr_[POSTSCRIPT_BUFSIZ+1];

  protected:
    void addComments(const char**);
    void printXColor(XColor*);
    unsigned char reverseBits(unsigned char);
    void byteToHex(unsigned char, char*);
    void setJoinStyle(int);
    void setCapStyle(int);
    void prolog();

  public:
    PSOutput(Graph*);
    virtual ~PSOutput();

    void printPolyline(Point2d*, int);
    void printMaxPolyline(Point2d*, int);
    void printSegments(Segment2d*, int);
    void printRectangle(double, double, int, int);
    void printPolygon(Point2d*, int);
    void print3DRectangle(Tk_3DBorder, double, double, int, int, int, int);

    void fillRectangle(double, double, int, int);
    void fillRectangles(Rectangle*, int);
    void fill3DRectangle(Tk_3DBorder, double, double, int, int, int, int);
    void fillPolygon(Point2d*, int);

    void setFont(Tk_Font); 
    void setLineWidth(int);
    void setBackground(XColor*);
    void setForeground(XColor*);
    void setBackground(Tk_3DBorder);
    void setLineAttributes(XColor*,int, Dashes*, int, int);
    void setClearBackground();
    void setDashes(Dashes*);

    int preamble(const char*);
    void computeBBox(int, int);
    const char* getValue(int*);
    void append(const char*);
    void format(const char*, ...);
    void varAppend(const char*, ...);
  };
};

#endif
