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

#include "tkbltChain.h"

#include "tkbltGraph.h"
#include "tkbltGrElem.h"
#include "tkbltGrElemOption.h"
#include "tkbltGrPen.h"
#include "tkbltConfig.h"

using namespace Blt;

#define SETRANGE(l) ((l).range = ((l).max > (l).min) ? ((l).max - (l).min) : DBL_EPSILON)
#define SETWEIGHT(l, lo, hi) ((l).min = (lo), (l).max = (hi), SETRANGE(l))

// Defs

static int GetPenStyleFromObj(Tcl_Interp* interp, Graph* graphPtr,
			      Tcl_Obj *objPtr, ClassId classId,
			      PenStyle *stylePtr);
static int ParseValues(Tcl_Interp* interp, Tcl_Obj *objPtr, int *nValuesPtr,
		       double **arrayPtr);

// OptionSpecs

static Tk_CustomOptionSetProc ValuesSetProc;
static Tk_CustomOptionGetProc ValuesGetProc;
static Tk_CustomOptionFreeProc ValuesFreeProc;
Tk_ObjCustomOption valuesObjOption =
  {
    "values", ValuesSetProc, ValuesGetProc, RestoreProc, ValuesFreeProc, NULL
  };

static int ValuesSetProc(ClientData clientData, Tcl_Interp* interp,
		       Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
		       int offset, char* savePtr, int flags)
{
  ElemValues** valuesPtrPtr = (ElemValues**)(widgRec + offset);
  *(double*)savePtr = *(double*)valuesPtrPtr;
  ElementOptions* ops = (ElementOptions*)widgRec;
  Element* elemPtr = ops->elemPtr;

  if (!valuesPtrPtr)
    return TCL_OK;

  Tcl_Obj** objv;
  int objc;
  if (Tcl_ListObjGetElements(interp, *objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  if (objc == 0) {
    *valuesPtrPtr = NULL;
    return TCL_OK;
  }

  const char *string = Tcl_GetString(objv[0]);
  if (objc == 1) {
    if (Blt_VectorExists2(interp, string)) {
      ElemValuesVector* valuesPtr = new ElemValuesVector(elemPtr, string);
      if (valuesPtr->getVector() != TCL_OK) {
	delete valuesPtr;
	return TCL_ERROR;
      }
      *valuesPtrPtr = valuesPtr;
    }
    else
      return TCL_ERROR;
  }
  else {
    double* values;
    int nValues;
    if (ParseValues(interp, *objPtr, &nValues, &values) != TCL_OK)
      return TCL_ERROR;
    ElemValuesSource* valuesPtr = new ElemValuesSource(nValues, values);
    valuesPtr->findRange();
    *valuesPtrPtr = valuesPtr;
  }

  return TCL_OK;
}

static Tcl_Obj* ValuesGetProc(ClientData clientData, Tk_Window tkwin, 
			    char *widgRec, int offset)
{
  ElemValues* valuesPtr = *(ElemValues**)(widgRec + offset);

  if (!valuesPtr)
    return Tcl_NewStringObj("", -1);
    
  int cnt = valuesPtr->nValues();
  if (!cnt)
    return Tcl_NewListObj(0, (Tcl_Obj**)NULL);

  Tcl_Obj** ll = new Tcl_Obj*[cnt];
  for (int ii=0; ii<cnt; ii++)
    ll[ii] = Tcl_NewDoubleObj(valuesPtr->values_[ii]);
  Tcl_Obj* listObjPtr = Tcl_NewListObj(cnt, ll);
  delete [] ll;

  return listObjPtr;
}

static void ValuesFreeProc(ClientData clientData, Tk_Window tkwin, char *ptr)
{
  ElemValues* valuesPtr = *(ElemValues**)ptr;
  delete valuesPtr;
}

static Tk_CustomOptionSetProc PairsSetProc;
static Tk_CustomOptionGetProc PairsGetProc;
static Tk_CustomOptionRestoreProc PairsRestoreProc;
static Tk_CustomOptionFreeProc PairsFreeProc;
Tk_ObjCustomOption pairsObjOption =
  {
    "pairs", PairsSetProc, PairsGetProc, PairsRestoreProc, PairsFreeProc, NULL
  };

static int PairsSetProc(ClientData clientData, Tcl_Interp* interp,
		       Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
		       int offset, char* savePtr, int flags)
{
  ElemCoords* coordsPtr = (ElemCoords*)(widgRec + offset);
  *(double*)savePtr = *(double*)NULL;

  double* values;
  int nValues;
  if (ParseValues(interp, *objPtr, &nValues, &values) != TCL_OK)
    return TCL_ERROR;

  if (nValues == 0)
    return TCL_OK;

  if (nValues & 1) {
    Tcl_AppendResult(interp, "odd number of data points", NULL);
    delete [] values;
    return TCL_ERROR;
  }

  nValues /= 2;
  delete coordsPtr->x;
  coordsPtr->x = new ElemValuesSource(nValues);

  delete coordsPtr->y;
  coordsPtr->y = new ElemValuesSource(nValues);

  int ii=0;
  for (double* p = values; ii<nValues; ii++) {
    coordsPtr->x->values_[ii] = *p++;
    coordsPtr->y->values_[ii] = *p++;
  }
  delete [] values;

  coordsPtr->x->findRange();
  coordsPtr->y->findRange();

  return TCL_OK;
};

static Tcl_Obj* PairsGetProc(ClientData clientData, Tk_Window tkwin, 
			    char *widgRec, int offset)
{
  ElemCoords* coordsPtr = (ElemCoords*)(widgRec + offset);

  if (!coordsPtr || 
      !coordsPtr->x || !coordsPtr->y || 
      !coordsPtr->x->nValues() || !coordsPtr->y->nValues())
    return Tcl_NewListObj(0, (Tcl_Obj**)NULL);

  int cnt = MIN(coordsPtr->x->nValues(), coordsPtr->y->nValues());
  Tcl_Obj** ll = new Tcl_Obj*[2*cnt];
  for (int ii=0, jj=0; ii<cnt; ii++) {
    ll[jj++] = Tcl_NewDoubleObj(coordsPtr->x->values_[ii]);
    ll[jj++] = Tcl_NewDoubleObj(coordsPtr->y->values_[ii]);
  }
  Tcl_Obj* listObjPtr = Tcl_NewListObj(2*cnt, ll);
  delete [] ll;

  return listObjPtr;
};

static void PairsRestoreProc(ClientData clientData, Tk_Window tkwin,
			     char *ptr, char *savePtr)
{
  // do nothing
}

static void PairsFreeProc(ClientData clientData, Tk_Window tkwin, char *ptr)
{
  // do nothing
}

int StyleSetProc(ClientData clientData, Tcl_Interp* interp,
		 Tk_Window tkwin, Tcl_Obj** objPtr, char* widgRec,
		 int offset, char* save, int flags)
{
  Chain* stylePalette = *(Chain**)(widgRec + offset);
  ElementOptions* ops = (ElementOptions*)(widgRec);
  Element* elemPtr = ops->elemPtr;
  size_t size = (size_t)clientData;

  int objc;
  Tcl_Obj** objv;
  if (Tcl_ListObjGetElements(interp, *objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  // Reserve the first entry for the "normal" pen. We'll set the style later
  elemPtr->freeStylePalette(stylePalette);
  ChainLink* link = Chain_FirstLink(stylePalette);
  if (!link) {
    link = new ChainLink(size);
    stylePalette->linkAfter(link, NULL);
  }

  PenStyle* stylePtr = (PenStyle*)Chain_GetValue(link);
  stylePtr->penPtr = NORMALPEN(ops);
  for (int ii = 0; ii<objc; ii++) {
    link = new ChainLink(size);
    stylePtr = (PenStyle*)Chain_GetValue(link);
    stylePtr->weight.min = (double)ii;
    stylePtr->weight.max = (double)ii + 1.0;
    stylePtr->weight.range = 1.0;
    if (GetPenStyleFromObj(interp, elemPtr->graphPtr_, objv[ii], 
			   elemPtr->classId(), 
			   (PenStyle*)stylePtr) != TCL_OK) {
      elemPtr->freeStylePalette(stylePalette);
      return TCL_ERROR;
    }
    stylePalette->linkAfter(link, NULL);
  }

  return TCL_OK;
}

Tcl_Obj* StyleGetProc(ClientData clientData, Tk_Window tkwin, 
		      char *widgRec, int offset)
{
  Chain* stylePalette = *(Chain**)(widgRec + offset);

  // count how many
  int cnt =0;
  for (ChainLink* link = Chain_FirstLink(stylePalette); link; 
       link = Chain_NextLink(link), cnt++) {}
  if (!cnt)
    return Tcl_NewListObj(0, (Tcl_Obj**)NULL);

  Tcl_Obj** ll = new Tcl_Obj*[3*cnt];
  int ii=0;
  for (ChainLink* link = Chain_FirstLink(stylePalette); link; 
       link = Chain_NextLink(link)) {
    PenStyle *stylePtr = (PenStyle*)Chain_GetValue(link);
    ll[ii++] = Tcl_NewStringObj(stylePtr->penPtr->name_, -1);
    ll[ii++] = Tcl_NewDoubleObj(stylePtr->weight.min);
    ll[ii++] = Tcl_NewDoubleObj(stylePtr->weight.max);
  }
  Tcl_Obj *listObjPtr = Tcl_NewListObj(3*cnt,ll);
  delete [] ll;

  return listObjPtr;
}

void StyleRestoreProc(ClientData clientData, Tk_Window tkwin,
		      char *ptr, char *savePtr)
{
  // do nothing
}

void StyleFreeProc(ClientData clientData, Tk_Window tkwin, char *ptr)
{
  // do nothing
}

// Support

static int GetPenStyleFromObj(Tcl_Interp* interp, Graph* graphPtr,
			      Tcl_Obj *objPtr, ClassId classId,
			      PenStyle *stylePtr)
{
  int objc;
  Tcl_Obj **objv;
  if (Tcl_ListObjGetElements(interp, objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  if ((objc != 1) && (objc != 3)) {
    Tcl_AppendResult(interp, "bad style entry \"", 
		     Tcl_GetString(objPtr), 
		     "\": should be \"penName\" or \"penName min max\"", 
		     NULL);
    return TCL_ERROR;
  }

  Pen* penPtr;
  if (graphPtr->getPen(objv[0], &penPtr) != TCL_OK)
    return TCL_ERROR;

  if (objc == 3) {
    double min, max;
    if ((Tcl_GetDoubleFromObj(interp, objv[1], &min) != TCL_OK) ||
	(Tcl_GetDoubleFromObj(interp, objv[2], &max) != TCL_OK))
      return TCL_ERROR;

    SETWEIGHT(stylePtr->weight, min, max);
  }

  penPtr->refCount_++;
  stylePtr->penPtr = penPtr;
  return TCL_OK;
}

void VectorChangedProc(Tcl_Interp* interp, ClientData clientData, 
		       Blt_VectorNotify notify)
{
  ElemValuesVector* valuesPtr = (ElemValuesVector*)clientData;
  if (!valuesPtr)
    return;

  if (notify == BLT_VECTOR_NOTIFY_DESTROY) {
    valuesPtr->freeSource();
    valuesPtr->reset();
  }
  else {
    Blt_Vector* vector;
    Blt_GetVectorById(interp, valuesPtr->source_, &vector);
    if (valuesPtr->fetchValues(vector) != TCL_OK)
      return;
  }

  Element* elemPtr = valuesPtr->elemPtr_;
  Graph* graphPtr = elemPtr->graphPtr_;

  graphPtr->flags |= RESET;
  graphPtr->eventuallyRedraw();
}

static int ParseValues(Tcl_Interp* interp, Tcl_Obj *objPtr, int *nValuesPtr,
		       double **arrayPtr)
{
  int objc;
  Tcl_Obj **objv;
  if (Tcl_ListObjGetElements(interp, objPtr, &objc, &objv) != TCL_OK)
    return TCL_ERROR;

  *arrayPtr = NULL;
  *nValuesPtr = 0;
  if (objc > 0) {
    double* array = new double[objc];
    if (!array) {
      Tcl_AppendResult(interp, "can't allocate new vector", NULL);
      return TCL_ERROR;
    }

    int i=0;
    for (double* p = array; i < objc; i++, p++) {
      if (Tcl_GetDoubleFromObj(interp, objv[i], p) != TCL_OK) {
	delete [] array;
	return TCL_ERROR;
      }
    }
    *arrayPtr = array;
    *nValuesPtr = objc;
  }

  return TCL_OK;
}
