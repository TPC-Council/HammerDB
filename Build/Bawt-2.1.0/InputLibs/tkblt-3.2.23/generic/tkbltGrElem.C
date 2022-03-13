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

#include <float.h>
#include <stdlib.h>
#include <string.h>

#include <cmath>

#include "tkbltGraph.h"
#include "tkbltGrBind.h"
#include "tkbltGrElem.h"
#include "tkbltGrPen.h"
#include "tkbltInt.h"

using namespace Blt;

// Class ElemValues

ElemValues::ElemValues()
{
  values_ =NULL;
  nValues_ =0;
  min_ =0;
  max_ =0;
}

ElemValues::~ElemValues()
{
  delete [] values_;
}

void ElemValues::reset()
{
  delete [] values_;
  values_ =NULL;
  nValues_ =0;
  min_ =0;
  max_ =0;
}

ElemValuesSource::ElemValuesSource(int nn) : ElemValues()
{
  nValues_ = nn;
  values_ = new double[nn];
}

ElemValuesSource::ElemValuesSource(int nn, double* vv) : ElemValues()
{
  nValues_ = nn;
  values_ = vv;
}

ElemValuesSource::~ElemValuesSource()
{
}

void ElemValuesSource::findRange()
{
  if (nValues_<1 || !values_)
    return;

  min_ = DBL_MAX;
  max_ = -DBL_MAX;
  for (int ii=0; ii<nValues_; ii++) {
    if (isfinite(values_[ii])) {
      if (values_[ii] < min_)
	min_ = values_[ii];
      if (values_[ii] > max_)
	max_ = values_[ii];
    }
  }
}

ElemValuesVector::ElemValuesVector(Element* ptr, const char* vecName) 
  : ElemValues()
{
  elemPtr_ = ptr;
  Graph* graphPtr = elemPtr_->graphPtr_;
  source_ = Blt_AllocVectorId(graphPtr->interp_, vecName);
}

ElemValuesVector::~ElemValuesVector()
{
  freeSource();
}

int ElemValuesVector::getVector()
{
  Graph* graphPtr = elemPtr_->graphPtr_;

  Blt_Vector *vecPtr;
  if (Blt_GetVectorById(graphPtr->interp_, source_, &vecPtr) != TCL_OK)
    return TCL_ERROR;

  if (fetchValues(vecPtr) != TCL_OK) {
    freeSource();
    return TCL_ERROR;
  }

  Blt_SetVectorChangedProc(source_, VectorChangedProc, this);
  return TCL_OK;
}

int ElemValuesVector::fetchValues(Blt_Vector* vector)
{
  Graph* graphPtr = elemPtr_->graphPtr_;

  delete [] values_;
  values_ = NULL;
  nValues_ = 0;
  min_ =0;
  max_ =0;

  int ss = Blt_VecLength(vector);
  if (!ss)
    return TCL_OK;

  double* array = new double[ss];
  if (!array) {
    Tcl_AppendResult(graphPtr->interp_, "can't allocate new vector", NULL);
    return TCL_ERROR;
  }

  memcpy(array, Blt_VecData(vector), ss*sizeof(double));
  values_ = array;
  nValues_ = Blt_VecLength(vector);
  min_ = Blt_VecMin(vector);
  max_ = Blt_VecMax(vector);

  return TCL_OK;
}

void ElemValuesVector::freeSource()
{
  if (source_) { 
    Blt_SetVectorChangedProc(source_, NULL, NULL);
    Blt_FreeVectorId(source_); 
    source_ = NULL;
  }
}

// Class Element

Element::Element(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
{
  graphPtr_ = graphPtr;
  name_ = dupstr(name);
  optionTable_ =NULL;
  ops_ =NULL;
  hashPtr_ = hPtr;

  row_ =0;
  col_ =0;
  activeIndices_ =NULL;
  nActiveIndices_ =0;
  xRange_ =0;
  yRange_ =0;
  active_ =0;
  labelActive_ =0;

  link =NULL;
}

Element::~Element()
{
  graphPtr_->bindTable_->deleteBindings(this);

  if (link)
    graphPtr_->elements_.displayList->deleteLink(link);

  if (hashPtr_)
    Tcl_DeleteHashEntry(hashPtr_);

  delete [] name_;

  delete [] activeIndices_;

  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

double Element::FindElemValuesMinimum(ElemValues* valuesPtr, double minLimit)
{
  double min = DBL_MAX;
  if (!valuesPtr)
    return min;

  for (int ii=0; ii<valuesPtr->nValues(); ii++) {
    double x = valuesPtr->values_[ii];
    // What do you do about negative values when using log
    // scale values seems like a grey area. Mirror.
    if (x < 0.0)
      x = -x;
    if ((x > minLimit) && (min > x))
      min = x;
  }
  if (min == DBL_MAX)
    min = minLimit;

  return min;
}

PenStyle** Element::StyleMap()
{
  ElementOptions* ops = (ElementOptions*)ops_;

  int nPoints = NUMBEROFPOINTS(ops);
  int nWeights = MIN(ops->w ? ops->w->nValues() : 0, nPoints);
  double* w = ops->w ? ops->w->values_ : NULL;
  ChainLink* link = Chain_FirstLink(ops->stylePalette);
  PenStyle* stylePtr = (PenStyle*)Chain_GetValue(link);

  // Create a style mapping array (data point index to style), 
  // initialized to the default style.
  PenStyle** dataToStyle = new PenStyle*[nPoints];
  for (int ii=0; ii<nPoints; ii++)
    dataToStyle[ii] = stylePtr;

  for (int ii=0; ii<nWeights; ii++) {
    for (link=Chain_LastLink(ops->stylePalette); link; 
	 link=Chain_PrevLink(link)) {
      stylePtr = (PenStyle*)Chain_GetValue(link);

      if (stylePtr->weight.range > 0.0) {
	double norm = (w[ii] - stylePtr->weight.min) / stylePtr->weight.range;
	if (((norm - 1.0) <= DBL_EPSILON) && 
	    (((1.0 - norm) - 1.0) <= DBL_EPSILON)) {
	  dataToStyle[ii] = stylePtr;
	  break;
	}
      }
    }
  }

  return dataToStyle;
}

void Element::freeStylePalette(Chain* stylePalette)
{
  // Skip the first slot. It contains the built-in "normal" pen of the element
  ChainLink* link = Chain_FirstLink(stylePalette);
  if (link) {
    ChainLink* next;
    for (link=Chain_NextLink(link); link; link=next) {
      next = Chain_NextLink(link);
      PenStyle *stylePtr = (PenStyle*)Chain_GetValue(link);
      Pen* penPtr = stylePtr->penPtr;
      if (penPtr) {
	penPtr->refCount_--;
	if (penPtr->refCount_ == 0)
	  delete penPtr;
      }
      stylePalette->deleteLink(link);
    }
  }
}

