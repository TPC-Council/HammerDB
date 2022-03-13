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

#ifndef __BltGrElem_h__
#define __BltGrElem_h__

#include <tk.h>

#include "tkbltVector.h"
#include "tkbltChain.h"

#include "tkbltGrMisc.h"
#include "tkbltGrPen.h"
#include "tkbltGrPSOutput.h"

#define SHOW_NONE	0
#define SHOW_X		1
#define SHOW_Y		2
#define SHOW_BOTH	3

#define NUMBEROFPOINTS(e) MIN( (e)->coords.x ? (e)->coords.x->nValues() : 0, \
			       (e)->coords.y ? (e)->coords.y->nValues() : 0 )
#define NORMALPEN(e) ((((e)->normalPenPtr == NULL) ? \
		       (e)->builtinPenPtr : (e)->normalPenPtr))

namespace Blt {
  class Axis;
  class Element;
  class Pen;
  class Postscript;

  class ElemValues {
  protected:
    double min_;
    double max_;
    int nValues_;

  public:
    double* values_;

  public:
    ElemValues();
    virtual ~ElemValues();

    void reset();
    int nValues() {return nValues_;}
    double min() {return min_;}
    double max() {return max_;}
  };

  class ElemValuesSource : public ElemValues
  {
  public:
    ElemValuesSource(int);
    ElemValuesSource(int, double*);
    ~ElemValuesSource();

    void findRange();
  };

  class ElemValuesVector : public ElemValues
  {
  public:
    Element* elemPtr_;
    Blt_VectorId source_;

  public:
    ElemValuesVector(Element*, const char*);
    ~ElemValuesVector();

    int getVector();
    int fetchValues(Blt_Vector*);
    void freeSource();
  };

  typedef struct {
    Segment2d *segments;
    int *map;
    int length;
  } GraphSegments;

  typedef struct {
    ElemValuesSource* x;
    ElemValuesSource* y;
  } ElemCoords;

  typedef struct {
    double min;
    double max;
    double range;
  } Weight;

  typedef struct {
    Weight weight;
    Pen* penPtr;
  } PenStyle;

  typedef struct {
    Element* elemPtr;
    const char* label;
    const char** tags;
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
    Pen* builtinPenPtr;
    Pen* activePenPtr;
    Pen* normalPenPtr;
    PenOptions builtinPen;
  } ElementOptions;

  class Element {
  protected:
    Tk_OptionTable optionTable_;
    void* ops_;

    double xRange_;
    double yRange_;

  public:
    Graph* graphPtr_;
    const char* name_;
    Tcl_HashEntry* hashPtr_;
    unsigned row_;
    unsigned col_;
    int nActiveIndices_;
    int* activeIndices_;
    int active_;		
    int labelActive_;

    ChainLink* link;

  protected:
    double FindElemValuesMinimum(ElemValues*, double);
    PenStyle** StyleMap();

  public:
    Element(Graph*, const char*, Tcl_HashEntry*);
    virtual ~Element();

    virtual int configure() =0;
    virtual void map() =0;
    virtual void extents(Region2d*) =0;
    virtual void draw(Drawable) =0;
    virtual void drawActive(Drawable) =0;
    virtual void drawSymbol(Drawable, int, int, int) =0;
    virtual void closest() =0;
    virtual void print(PSOutput*) =0;
    virtual void printActive(PSOutput*) =0;
    virtual void printSymbol(PSOutput*, double, double, int) =0;

    virtual ClassId classId() =0;
    virtual const char* className() =0;
    virtual const char* typeName() =0;

    void freeStylePalette (Chain*);

    Tk_OptionTable optionTable() {return optionTable_;}
    void* ops() {return ops_;}
  };
};

extern void VectorChangedProc(Tcl_Interp* interp, ClientData clientData, 
			      Blt_VectorNotify notify);


#endif
