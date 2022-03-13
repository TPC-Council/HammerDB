/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1995-2004 George A Howlett.
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
 *
 * Code for binary data read operation was donated by Harold Kirsch.
 *
 */

/*
 * TODO:
 *	o Add H. Kirsch's vector binary read operation
 *		x binread file0
 *		x binread -file file0
 *
 *	o Add ASCII/binary file reader
 *		x read fileName
 *
 *	o Allow Tcl-based client notifications.
 *		vector x
 *		x notify call Display
 *		x notify delete Display
 *		x notify reorder #1 #2
 */

#include <float.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include <cmath>

#include "tkbltVecInt.h"
#include "tkbltOp.h"
#include "tkbltNsUtil.h"
#include "tkbltSwitch.h"
#include "tkbltInt.h"

using namespace Blt;

extern int Blt_SimplifyLine (Point2d *origPts, int low, int high, 
			     double tolerance, int *indices);

typedef int (VectorCmdProc)(Vector *vPtr, Tcl_Interp* interp, int objc, 
			    Tcl_Obj* const objv[]);
typedef int (QSortCompareProc) (const void *, const void *);

static Blt_SwitchParseProc ObjToFFTVector;
static Blt_SwitchCustom fftVectorSwitch = {
  ObjToFFTVector, NULL, (ClientData)0,
};

static Blt_SwitchParseProc ObjToIndex;
static Blt_SwitchCustom indexSwitch = {
  ObjToIndex, NULL, (ClientData)0,
};

typedef struct {
  Tcl_Obj *formatObjPtr;
  int from, to;
} PrintSwitches;

static Blt_SwitchSpec printSwitches[] = 
  {
    {BLT_SWITCH_OBJ,    "-format", "string",
     Tk_Offset(PrintSwitches, formatObjPtr), 0},
    {BLT_SWITCH_CUSTOM, "-from",   "index",
     Tk_Offset(PrintSwitches, from),         0, 0, &indexSwitch},
    {BLT_SWITCH_CUSTOM, "-to",     "index",
     Tk_Offset(PrintSwitches, to),           0, 0, &indexSwitch},
    {BLT_SWITCH_END}
  };


typedef struct {
  int flags;
} SortSwitches;

#define SORT_DECREASING (1<<0)
#define SORT_UNIQUE	(1<<1)

static Blt_SwitchSpec sortSwitches[] = 
  {
    {BLT_SWITCH_BITMASK, "-decreasing", "",
	Tk_Offset(SortSwitches, flags),   0, SORT_DECREASING},
    {BLT_SWITCH_BITMASK, "-reverse",   "",
	Tk_Offset(SortSwitches, flags),   0, SORT_DECREASING},
    {BLT_SWITCH_BITMASK, "-uniq",     "", 
	Tk_Offset(SortSwitches, flags),   0, SORT_UNIQUE},
    {BLT_SWITCH_END}
  };

typedef struct {
  double delta;
  Vector *imagPtr;	/* Vector containing imaginary part. */
  Vector *freqPtr;	/* Vector containing frequencies. */
  VectorInterpData *dataPtr;
  int mask;			/* Flags controlling FFT. */
} FFTData;


static Blt_SwitchSpec fftSwitches[] = {
  {BLT_SWITCH_CUSTOM, "-imagpart",    "vector",
   Tk_Offset(FFTData, imagPtr), 0, 0, &fftVectorSwitch},
  {BLT_SWITCH_BITMASK, "-noconstant", "",
   Tk_Offset(FFTData, mask), 0, FFT_NO_CONSTANT},
  {BLT_SWITCH_BITMASK, "-spectrum", "",
   Tk_Offset(FFTData, mask), 0, FFT_SPECTRUM},
  {BLT_SWITCH_BITMASK, "-bartlett",  "",
   Tk_Offset(FFTData, mask), 0, FFT_BARTLETT},
  {BLT_SWITCH_DOUBLE, "-delta",   "float",
   Tk_Offset(FFTData, mask), 0, 0, },
  {BLT_SWITCH_CUSTOM, "-frequencies", "vector",
   Tk_Offset(FFTData, freqPtr), 0, 0, &fftVectorSwitch},
  {BLT_SWITCH_END}
};

static int Blt_ExprIntFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr, 
			      int *valuePtr)
{
  // First try to extract the value as a simple integer.
  if (Tcl_GetIntFromObj((Tcl_Interp *)NULL, objPtr, valuePtr) == TCL_OK)
    return TCL_OK;
 
  // Otherwise try to parse it as an expression.
  long lvalue;
  if (Tcl_ExprLong(interp, Tcl_GetString(objPtr), &lvalue) == TCL_OK) {
    *valuePtr = lvalue;
    return TCL_OK;
  }

  return TCL_ERROR;
}

static int Blt_ExprDoubleFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr, 
				 double *valuePtr)
{
  // First try to extract the value as a double precision number.
  if (Tcl_GetDoubleFromObj((Tcl_Interp *)NULL, objPtr, valuePtr) == TCL_OK)
    return TCL_OK;

  // Interpret the empty string "" and "NaN" as NaN.
  int length;
  char *string;
  string = Tcl_GetStringFromObj(objPtr, &length);
  if (length == 0 || (length == 3 && strcmp(string, "NaN") == 0)) {
    *valuePtr = NAN;
    return TCL_OK;
  }

  // Then try to parse it as an expression.
  if (Tcl_ExprDouble(interp, string, valuePtr) == TCL_OK)
    return TCL_OK;

  return TCL_ERROR;
}

static int ObjToFFTVector(ClientData clientData, Tcl_Interp* interp,
			  const char *switchName, Tcl_Obj *objPtr,
			  char *record, int offset, int flags)
{
  FFTData *dataPtr = (FFTData *)record;
  Vector *vPtr;
  Vector **vPtrPtr = (Vector **)(record + offset);
  int isNew;			/* Not used. */
  char *string;

  string = Tcl_GetString(objPtr);
  vPtr = Vec_Create(dataPtr->dataPtr, string, string, string, &isNew);
  if (vPtr == NULL) {
    return TCL_ERROR;
  }
  *vPtrPtr = vPtr;

  return TCL_OK;
}

static int ObjToIndex(ClientData clientData, Tcl_Interp* interp,
		      const char *switchName, Tcl_Obj *objPtr, char *record,
		      int offset, int flags)
{
  Vector *vPtr = (Vector*)clientData;
  int *indexPtr = (int *)(record + offset);
  int index;

  if (Vec_GetIndex(interp, vPtr, Tcl_GetString(objPtr), &index, 
		       INDEX_CHECK, (Blt_VectorIndexProc **)NULL) != TCL_OK) {
    return TCL_ERROR;
  }
  *indexPtr = index;

  return TCL_OK;
}

static Tcl_Obj* GetValues(Vector *vPtr, int first, int last)
{ 
  Tcl_Obj *listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  for (double *vp=vPtr->valueArr+first, *vend=vPtr->valueArr+last; 
       vp <= vend; vp++)
    Tcl_ListObjAppendElement(vPtr->interp, listObjPtr, Tcl_NewDoubleObj(*vp));

  return listObjPtr;
}

static void ReplicateValue(Vector *vPtr, int first, int last, double value)
{ 
  for (double *vp=vPtr->valueArr+first, *vend=vPtr->valueArr+last; 
       vp <= vend; vp++)
    *vp = value; 

  vPtr->notifyFlags |= UPDATE_RANGE; 
}

static int CopyList(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  if (Vec_SetLength(interp, vPtr, objc) != TCL_OK)
    return TCL_ERROR;

  for (int ii = 0; ii < objc; ii++) {
    double value;
    if (Blt_ExprDoubleFromObj(interp, objv[ii], &value) != TCL_OK) {
      Vec_SetLength(interp, vPtr, ii);
      return TCL_ERROR;
    }
    vPtr->valueArr[ii] = value;
  }

  return TCL_OK;
}

static int AppendVector(Vector *destPtr, Vector *srcPtr)
{
  size_t oldSize = destPtr->length;
  size_t newSize = oldSize + srcPtr->last - srcPtr->first + 1;
  if (Vec_ChangeLength(destPtr->interp, destPtr, newSize) != TCL_OK) {
    return TCL_ERROR;
  }
  size_t nBytes = (newSize - oldSize) * sizeof(double);
  memcpy((char *)(destPtr->valueArr + oldSize),
	 (srcPtr->valueArr + srcPtr->first), nBytes);
  destPtr->notifyFlags |= UPDATE_RANGE;
  return TCL_OK;
}

static int AppendList(Vector *vPtr, int objc, Tcl_Obj* const objv[])
{
  Tcl_Interp* interp = vPtr->interp;

  int oldSize = vPtr->length;
  if (Vec_ChangeLength(interp, vPtr, vPtr->length + objc) != TCL_OK)
    return TCL_ERROR;

  int count = oldSize;
  for (int i = 0; i < objc; i++) {
    double value;
    if (Blt_ExprDoubleFromObj(interp, objv[i], &value) != TCL_OK) {
      Vec_ChangeLength(interp, vPtr, count);
      return TCL_ERROR;
    }
    vPtr->valueArr[count++] = value;
  }
  vPtr->notifyFlags |= UPDATE_RANGE;

  return TCL_OK;
}

// Vector instance option commands

static int AppendOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  for (int i = 2; i < objc; i++) {
    Vector* v2Ptr = Vec_ParseElement((Tcl_Interp *)NULL, vPtr->dataPtr, 
				     Tcl_GetString(objv[i]), 
				     (const char **)NULL, NS_SEARCH_BOTH);
    int result;
    if (v2Ptr != NULL)
      result = AppendVector(vPtr, v2Ptr);
    else {
      int nElem;
      Tcl_Obj **elemObjArr;

      if (Tcl_ListObjGetElements(interp, objv[i], &nElem, &elemObjArr) 
	  != TCL_OK) {
	return TCL_ERROR;
      }
      result = AppendList(vPtr, nElem, elemObjArr);
    }

    if (result != TCL_OK)
      return TCL_ERROR;
  }

  if (objc > 2) {
    if (vPtr->flush)
      Vec_FlushCache(vPtr);
    Vec_UpdateClients(vPtr);
  }

  return TCL_OK;
}

static int ClearOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  Vec_FlushCache(vPtr);
  return TCL_OK;
}

static int DeleteOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  // FIXME: Don't delete vector with no indices
  if (objc == 2) {
    Vec_Free(vPtr);
    return TCL_OK;
  }

  // Allocate an "unset" bitmap the size of the vector
  unsigned char* unsetArr = 
    (unsigned char*)calloc(sizeof(unsigned char), (vPtr->length + 7) / 8);
#define SetBit(i) (unsetArr[(i) >> 3] |= (1 << ((i) & 0x07)))
#define GetBit(i) (unsetArr[(i) >> 3] &  (1 << ((i) & 0x07)))

  for (int i = 2; i < objc; i++) {
    char* string = Tcl_GetString(objv[i]);
    if (Vec_GetIndexRange(interp, vPtr, string, (INDEX_COLON | INDEX_CHECK),
			  (Blt_VectorIndexProc **) NULL) != TCL_OK) {
      free(unsetArr);
      return TCL_ERROR;
    }

    // Mark the range of elements for deletion
    for (int j = vPtr->first; j <= vPtr->last; j++)
      SetBit(j);		
  }

  int count = 0;
  for (int i = 0; i < vPtr->length; i++) {
    // Skip elements marked for deletion
    if (GetBit(i))
      continue;

    if (count < i) {
      vPtr->valueArr[count] = vPtr->valueArr[i];
    }
    count++;
  }
  free(unsetArr);
  vPtr->length = count;

  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  return TCL_OK;
}

static int DupOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  for (int i = 2; i < objc; i++) {
    char* name = Tcl_GetString(objv[i]);
    int isNew;
    Vector* v2Ptr = Vec_Create(vPtr->dataPtr, name, name, name, &isNew);
    if (v2Ptr == NULL)
      return TCL_ERROR;

    if (v2Ptr == vPtr)
      continue;

    if (Vec_Duplicate(v2Ptr, vPtr) != TCL_OK)
      return TCL_ERROR;

    if (!isNew) {
      if (v2Ptr->flush)
	Vec_FlushCache(v2Ptr);
      Vec_UpdateClients(v2Ptr);
    }
  }

  return TCL_OK;
}

static int FFTOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  FFTData data;
  memset(&data, 0, sizeof(data));
  data.delta = 1.0;

  char* realVecName = Tcl_GetString(objv[2]);
  int isNew;
  Vector* v2Ptr = Vec_Create(vPtr->dataPtr, realVecName, realVecName, 
			     realVecName, &isNew);
  if (v2Ptr == NULL)
    return TCL_ERROR;

  if (v2Ptr == vPtr) {
    Tcl_AppendResult(interp, "real vector \"", realVecName, "\"", 
		     " can't be the same as the source", (char *)NULL);
    return TCL_ERROR;
  }

  if (ParseSwitches(interp, fftSwitches, objc - 3, objv + 3, &data, 
		    BLT_SWITCH_DEFAULTS) < 0)
    return TCL_ERROR;

  if (Vec_FFT(interp, v2Ptr, data.imagPtr, data.freqPtr, data.delta,
	      data.mask, vPtr) != TCL_OK)
    return TCL_ERROR;

  // Update bookkeeping
  if (!isNew) {
    if (v2Ptr->flush)
      Vec_FlushCache(v2Ptr);
    Vec_UpdateClients(v2Ptr);
  }

  if (data.imagPtr != NULL) {
    if (data.imagPtr->flush)
      Vec_FlushCache(data.imagPtr);
    Vec_UpdateClients(data.imagPtr);
  }

  if (data.freqPtr != NULL) {
    if (data.freqPtr->flush)
      Vec_FlushCache(data.freqPtr);
    Vec_UpdateClients(data.freqPtr);
  }

  return TCL_OK;
}	

static int InverseFFTOp(Vector *vPtr, Tcl_Interp* interp, 
			int objc, Tcl_Obj* const objv[])
{
  char* name = Tcl_GetString(objv[2]);
  Vector *srcImagPtr;
  if (Vec_LookupName(vPtr->dataPtr, name, &srcImagPtr) != TCL_OK )
    return TCL_ERROR;

  name = Tcl_GetString(objv[3]);
  int isNew;
  Vector* destRealPtr = Vec_Create(vPtr->dataPtr, name, name, name, &isNew);
  name = Tcl_GetString(objv[4]);
  Vector* destImagPtr = Vec_Create(vPtr->dataPtr, name, name, name, &isNew);

  if (Vec_InverseFFT(interp, srcImagPtr, destRealPtr, destImagPtr, vPtr) 
      != TCL_OK )
    return TCL_ERROR;

  if (destRealPtr->flush)
    Vec_FlushCache(destRealPtr);
  Vec_UpdateClients(destRealPtr);

  if (destImagPtr->flush)
    Vec_FlushCache(destImagPtr);
  Vec_UpdateClients(destImagPtr);

  return TCL_OK;
}

static int IndexOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  char* string = Tcl_GetString(objv[2]);
  if (Vec_GetIndexRange(interp, vPtr, string, INDEX_ALL_FLAGS, 
			(Blt_VectorIndexProc **) NULL) != TCL_OK)
    return TCL_ERROR;

  int first = vPtr->first;
  int last = vPtr->last;
  if (objc == 3) {
    Tcl_Obj *listObjPtr;

    if (first == vPtr->length) {
      Tcl_AppendResult(interp, "can't get index \"", string, "\"",
		       (char *)NULL);
      return TCL_ERROR;	/* Can't read from index "++end" */
    }
    listObjPtr = GetValues(vPtr, first, last);
    Tcl_SetObjResult(interp, listObjPtr);
  }
  else {
    // FIXME: huh? Why set values here?
    if (first == SPECIAL_INDEX) {
      Tcl_AppendResult(interp, "can't set index \"", string, "\"",
		       (char *)NULL);
      // Tried to set "min" or "max"
      return TCL_ERROR;
    }

    double value;
    if (Blt_ExprDoubleFromObj(interp, objv[3], &value) != TCL_OK)
      return TCL_ERROR;

    if (first == vPtr->length) {
      if (Vec_ChangeLength(interp, vPtr, vPtr->length + 1) != TCL_OK) 
	return TCL_ERROR;
    }

    ReplicateValue(vPtr, first, last, value);
    Tcl_SetObjResult(interp, objv[3]);
    if (vPtr->flush)
      Vec_FlushCache(vPtr);
    Vec_UpdateClients(vPtr);
  }

  return TCL_OK;
}

static int LengthOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  if (objc == 3) {
    int nElem;
    if (Tcl_GetIntFromObj(interp, objv[2], &nElem) != TCL_OK)
      return TCL_ERROR;

    if (nElem < 0) {
      Tcl_AppendResult(interp, "bad vector size \"", 
		       Tcl_GetString(objv[2]), "\"", (char *)NULL);
      return TCL_ERROR;
    }

    if ((Vec_SetSize(interp, vPtr, nElem) != TCL_OK) ||
	(Vec_SetLength(interp, vPtr, nElem) != TCL_OK))
      return TCL_ERROR;

    if (vPtr->flush)
      Vec_FlushCache(vPtr);
    Vec_UpdateClients(vPtr);
  }
  Tcl_SetIntObj(Tcl_GetObjResult(interp), vPtr->length);

  return TCL_OK;
}

static int MapOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  if (objc > 2) {
    if (Vec_MapVariable(interp, vPtr, Tcl_GetString(objv[2])) 
	!= TCL_OK)
      return TCL_ERROR;
  }

  if (vPtr->arrayName != NULL)
    Tcl_SetStringObj(Tcl_GetObjResult(interp), vPtr->arrayName, -1);

  return TCL_OK;
}

static int MaxOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  Tcl_SetDoubleObj(Tcl_GetObjResult(interp), Vec_Max(vPtr));
  return TCL_OK;
}

static int MergeOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  // Allocate an array of vector pointers of each vector to be
  // merged in the current vector.
  Vector** vecArr = (Vector**)malloc(sizeof(Vector *) * objc);
  Vector** vPtrPtr = vecArr;

  int refSize = -1;
  int nElem = 0;
  for (int i = 2; i < objc; i++) {
    Vector *v2Ptr;
    if (Vec_LookupName(vPtr->dataPtr, Tcl_GetString(objv[i]), &v2Ptr)
	!= TCL_OK) {
      free(vecArr);
      return TCL_ERROR;
    }

    // Check that all the vectors are the same length
    int length = v2Ptr->last - v2Ptr->first + 1;
    if (refSize < 0)
      refSize = length;
    else if (length != refSize) {
      Tcl_AppendResult(vPtr->interp, "vectors \"", vPtr->name,
		       "\" and \"", v2Ptr->name, "\" differ in length",
		       (char *)NULL);
      free(vecArr);
      return TCL_ERROR;
    }
    *vPtrPtr++ = v2Ptr;
    nElem += refSize;
  }
  *vPtrPtr = NULL;

  double* valueArr = (double*)malloc(sizeof(double) * nElem);
  if (valueArr == NULL) {
    Tcl_AppendResult(vPtr->interp, "not enough memory to allocate ", 
		     Itoa(nElem), " vector elements", (char *)NULL);
    return TCL_ERROR;
  }

  // Merge the values from each of the vectors into the current vector
  double* valuePtr = valueArr;
  for (int i = 0; i < refSize; i++) {
    for (Vector** vpp = vecArr; *vpp != NULL; vpp++) {
      *valuePtr++ = (*vpp)->valueArr[i + (*vpp)->first];
    }
  }
  free(vecArr);
  Vec_Reset(vPtr, valueArr, nElem, nElem, TCL_DYNAMIC);

  return TCL_OK;
}

static int MinOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  Tcl_SetDoubleObj(Tcl_GetObjResult(interp), Vec_Min(vPtr));
  return TCL_OK;
}

static int NormalizeOp(Vector *vPtr, Tcl_Interp* interp, 
		       int objc, Tcl_Obj* const objv[])
{
  Vec_UpdateRange(vPtr);
  double range = vPtr->max - vPtr->min;
  if (objc > 2) {
    char* string = Tcl_GetString(objv[2]);
    int isNew;
    Vector* v2Ptr = Vec_Create(vPtr->dataPtr, string, string, string, &isNew);
    if (v2Ptr == NULL)
      return TCL_ERROR;

    if (Vec_SetLength(interp, v2Ptr, vPtr->length) != TCL_OK)
      return TCL_ERROR;

    for (int i = 0; i < vPtr->length; i++)
      v2Ptr->valueArr[i] = (vPtr->valueArr[i] - vPtr->min) / range;

    Vec_UpdateRange(v2Ptr);
    if (!isNew) {
      if (v2Ptr->flush) {
	Vec_FlushCache(v2Ptr);
      }
      Vec_UpdateClients(v2Ptr);
    }
  }
  else {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    for (int i = 0; i < vPtr->length; i++) {
      double norm = (vPtr->valueArr[i] - vPtr->min) / range;
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewDoubleObj(norm));
    }
    Tcl_SetObjResult(interp, listObjPtr);
  }

  return TCL_OK;
}

static int NotifyOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  enum optionIndices {
    OPTION_ALWAYS, OPTION_NEVER, OPTION_WHENIDLE, 
    OPTION_NOW, OPTION_CANCEL, OPTION_PENDING
  };
  static const char *optionArr[] = {
    "always", "never", "whenidle", "now", "cancel", "pending", NULL
  };

  int option;
  if (Tcl_GetIndexFromObj(interp, objv[2], optionArr, "qualifier", TCL_EXACT,
			  &option) != TCL_OK)
    return TCL_OK;

  switch (option) {
  case OPTION_ALWAYS:
    vPtr->notifyFlags &= ~NOTIFY_WHEN_MASK;
    vPtr->notifyFlags |= NOTIFY_ALWAYS;
    break;
  case OPTION_NEVER:
    vPtr->notifyFlags &= ~NOTIFY_WHEN_MASK;
    vPtr->notifyFlags |= NOTIFY_NEVER;
    break;
  case OPTION_WHENIDLE:
    vPtr->notifyFlags &= ~NOTIFY_WHEN_MASK;
    vPtr->notifyFlags |= NOTIFY_WHENIDLE;
    break;
  case OPTION_NOW:
    // FIXME: How does this play when an update is pending?
    Blt_Vec_NotifyClients(vPtr);
    break;
  case OPTION_CANCEL:
    if (vPtr->notifyFlags & NOTIFY_PENDING) {
      vPtr->notifyFlags &= ~NOTIFY_PENDING;
      Tcl_CancelIdleCall(Blt_Vec_NotifyClients, (ClientData)vPtr);
    }
    break;
  case OPTION_PENDING:
    int boll = (vPtr->notifyFlags & NOTIFY_PENDING);
    Tcl_SetBooleanObj(Tcl_GetObjResult(interp), boll);
    break;
  }	

  return TCL_OK;
}

static int PopulateOp(Vector *vPtr, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  char* string = Tcl_GetString(objv[2]);
  int isNew;
  Vector* v2Ptr = Vec_Create(vPtr->dataPtr, string, string, string, &isNew);
  if (v2Ptr == NULL)
    return TCL_ERROR;

  // Source vector is empty
  if (vPtr->length == 0)
    return TCL_OK;

  int density;
  if (Tcl_GetIntFromObj(interp, objv[3], &density) != TCL_OK)
    return TCL_ERROR;

  if (density < 1) {
    Tcl_AppendResult(interp, "bad density \"", Tcl_GetString(objv[3]), 
		     "\"", (char *)NULL);
    return TCL_ERROR;
  }
  int size = (vPtr->length - 1) * (density + 1) + 1;
  if (Vec_SetLength(interp, v2Ptr, size) != TCL_OK)
    return TCL_ERROR;

  int count = 0;
  double* valuePtr = v2Ptr->valueArr;
  int i;
  for (i = 0; i < (vPtr->length - 1); i++) {
    double range = vPtr->valueArr[i + 1] - vPtr->valueArr[i];
    double slice = range / (double)(density + 1);
    for (int j = 0; j <= density; j++) {
      *valuePtr = vPtr->valueArr[i] + (slice * (double)j);
      valuePtr++;
      count++;
    }
  }
  count++;
  *valuePtr = vPtr->valueArr[i];
  if (!isNew) {
    if (v2Ptr->flush)
      Vec_FlushCache(v2Ptr);
    Vec_UpdateClients(v2Ptr);
  }

  return TCL_OK;
}

static int ValuesOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  PrintSwitches switches;
  switches.formatObjPtr = NULL;
  switches.from = 0;
  switches.to = vPtr->length - 1;
  indexSwitch.clientData = vPtr;
  if (ParseSwitches(interp, printSwitches, objc - 2, objv + 2, &switches, 
			BLT_SWITCH_DEFAULTS) < 0)
    return TCL_ERROR;

  if (switches.from > switches.to) {
    // swap positions
    int tmp = switches.to;
    switches.to = switches.from;
    switches.from = tmp;
  }

  if (switches.formatObjPtr == NULL) {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    for (int i = switches.from; i <= switches.to; i++)
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewDoubleObj(vPtr->valueArr[i]));

    Tcl_SetObjResult(interp, listObjPtr);
  }
  else {
    Tcl_DString ds;
    Tcl_DStringInit(&ds);
    const char* fmt = Tcl_GetString(switches.formatObjPtr);
    for (int i = switches.from; i <= switches.to; i++) {
      char buffer[200];
      sprintf(buffer, fmt, vPtr->valueArr[i]);
      Tcl_DStringAppend(&ds, buffer, -1);
    }
    Tcl_DStringResult(interp, &ds);
    Tcl_DStringFree(&ds);
  }

  return TCL_OK;
}

static int RangeOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  int first;
  int last;

  if (objc == 2) {
    first = 0;
    last = vPtr->length - 1;
  }
  else if (objc == 4) {
    if ((Vec_GetIndex(interp, vPtr, Tcl_GetString(objv[2]), &first, 
		      INDEX_CHECK, (Blt_VectorIndexProc **) NULL) != TCL_OK) ||
	(Vec_GetIndex(interp, vPtr, Tcl_GetString(objv[3]), &last, 
		      INDEX_CHECK, (Blt_VectorIndexProc **) NULL) != TCL_OK))
      return TCL_ERROR;

  }
  else {
    Tcl_AppendResult(interp, "wrong # args: should be \"",
		     Tcl_GetString(objv[0]), " range ?first last?",
		     (char *)NULL);
    return TCL_ERROR;
  }

  Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (first > last) {
    // Return the list reversed
    for (int i=last; i<=first; i++)
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewDoubleObj(vPtr->valueArr[i]));
  }
  else {
    for (int i=first; i<=last; i++)
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewDoubleObj(vPtr->valueArr[i]));
  }

  Tcl_SetObjResult(interp, listObjPtr);

  return TCL_OK;
}

static int InRange(double value, double min, double max)
{
  double range = max - min;
  if (range < DBL_EPSILON)
    return (fabs(max - value) < DBL_EPSILON);

  double norm = (value - min) / range;
  return ((norm >= -DBL_EPSILON) && ((norm - 1.0) < DBL_EPSILON));
}

enum NativeFormats {
  FMT_UNKNOWN = -1,
  FMT_UCHAR, FMT_CHAR,
  FMT_USHORT, FMT_SHORT,
  FMT_UINT, FMT_INT,
  FMT_ULONG, FMT_LONG,
  FMT_FLOAT, FMT_DOUBLE
};

/*
 *---------------------------------------------------------------------------
 *
 * GetBinaryFormat
 *
 *      Translates a format string into a native type.  Valid formats are
 *
 *		signed		i1, i2, i4, i8
 *		unsigned 	u1, u2, u4, u8
 *		real		r4, r8, r16
 *
 *	There must be a corresponding native type.  For example, this for
 *	reading 2-byte binary integers from an instrument and converting them
 *	to unsigned shorts or ints.
 *
 *---------------------------------------------------------------------------
 */
static enum NativeFormats GetBinaryFormat(Tcl_Interp* interp, char *string,
					  int *sizePtr)
{
  char c = tolower(string[0]);
  if (Tcl_GetInt(interp, string + 1, sizePtr) != TCL_OK) {
    Tcl_AppendResult(interp, "unknown binary format \"", string,
		     "\": incorrect byte size", (char *)NULL);
    return FMT_UNKNOWN;
  }

  switch (c) {
  case 'r':
    if (*sizePtr == sizeof(double))
      return FMT_DOUBLE;
    else if (*sizePtr == sizeof(float))
      return FMT_FLOAT;

    break;

  case 'i':
    if (*sizePtr == sizeof(char))
      return FMT_CHAR;
    else if (*sizePtr == sizeof(int))
      return FMT_INT;
    else if (*sizePtr == sizeof(long))
      return FMT_LONG;
    else if (*sizePtr == sizeof(short))
      return FMT_SHORT;

    break;

  case 'u':
    if (*sizePtr == sizeof(unsigned char))
      return FMT_UCHAR;
    else if (*sizePtr == sizeof(unsigned int))
      return FMT_UINT;
    else if (*sizePtr == sizeof(unsigned long))
      return FMT_ULONG;
    else if (*sizePtr == sizeof(unsigned short))
      return FMT_USHORT;

    break;

  default:
    Tcl_AppendResult(interp, "unknown binary format \"", string,
		     "\": should be either i#, r#, u# (where # is size in bytes)",
		     (char *)NULL);
    return FMT_UNKNOWN;
  }
  Tcl_AppendResult(interp, "can't handle format \"", string, "\"", 
		   (char *)NULL);

  return FMT_UNKNOWN;
}

static int CopyValues(Vector *vPtr, char *byteArr, enum NativeFormats fmt,
		      int size, int length, int swap, int *indexPtr)
{
  if ((swap) && (size > 1)) {
    int nBytes = size * length;
    for (int i = 0; i < nBytes; i += size) {
      unsigned char* p = (unsigned char *)(byteArr + i);
      int left, right;
      for (left = 0, right = size - 1; left < right; left++, right--) {
	p[left] ^= p[right];
	p[right] ^= p[left];
	p[left] ^= p[right];
      }
    }
  }

  int newSize = *indexPtr + length;
  if (newSize > vPtr->length) {
    if (Vec_ChangeLength(vPtr->interp, vPtr, newSize) != TCL_OK)
      return TCL_ERROR;
  }

#define CopyArrayToVector(vPtr, arr)			\
  for (int i = 0, n = *indexPtr; i < length; i++, n++) {	\
    (vPtr)->valueArr[n] = (double)(arr)[i];		\
  }

  switch (fmt) {
  case FMT_CHAR:
    CopyArrayToVector(vPtr, (char *)byteArr);
    break;

  case FMT_UCHAR:
    CopyArrayToVector(vPtr, (unsigned char *)byteArr);
    break;

  case FMT_INT:
    CopyArrayToVector(vPtr, (int *)byteArr);
    break;

  case FMT_UINT:
    CopyArrayToVector(vPtr, (unsigned int *)byteArr);
    break;

  case FMT_LONG:
    CopyArrayToVector(vPtr, (long *)byteArr);
    break;

  case FMT_ULONG:
    CopyArrayToVector(vPtr, (unsigned long *)byteArr);
    break;

  case FMT_SHORT:
    CopyArrayToVector(vPtr, (short int *)byteArr);
    break;

  case FMT_USHORT:
    CopyArrayToVector(vPtr, (unsigned short int *)byteArr);
    break;

  case FMT_FLOAT:
    CopyArrayToVector(vPtr, (float *)byteArr);
    break;

  case FMT_DOUBLE:
    CopyArrayToVector(vPtr, (double *)byteArr);
    break;

  case FMT_UNKNOWN:
    break;
  }
  *indexPtr += length;
  return TCL_OK;
}

/*
 *---------------------------------------------------------------------------
 *
 * BinreadOp --
 *
 *	Reads binary values from a TCL channel. Values are either appended to
 *	the end of the vector or placed at a given index (using the "-at"
 *	option), overwriting existing values.  Data is read until EOF is found
 *	on the channel or a specified number of values are read.  (note that
 *	this is not necessarily the same as the number of bytes).
 *
 *	The following flags are supported:
 *		-swap		Swap bytes
 *		-at index	Start writing data at the index.
 *		-format fmt	Specifies the format of the data.
 *
 *	This binary reader was created and graciously donated by Harald Kirsch
 *	(kir@iitb.fhg.de).  Anything that's wrong is due to my (gah) munging
 *	of the code.
 *
 * Results:
 *	Returns a standard TCL result. The interpreter result will contain the
 *	number of values (not the number of bytes) read.
 *
 * Caveats:
 *	Channel reads must end on an element boundary.
 *
 *---------------------------------------------------------------------------
 */

static int BinreadOp(Vector *vPtr, Tcl_Interp* interp, 
		     int objc, Tcl_Obj* const objv[])
{
  enum NativeFormats fmt;

  char* string = Tcl_GetString(objv[2]);
  int mode;
  Tcl_Channel channel = Tcl_GetChannel(interp, string, &mode);
  if (channel == NULL)
    return TCL_ERROR;

  if ((mode & TCL_READABLE) == 0) {
    Tcl_AppendResult(interp, "channel \"", string,
		     "\" wasn't opened for reading", (char *)NULL);
    return TCL_ERROR;
  }
  int first = vPtr->length;
  fmt = FMT_DOUBLE;
  int size = sizeof(double);
  int swap = 0;
  int count = 0;

  if (objc > 3) {
    string = Tcl_GetString(objv[3]);
    if (string[0] != '-') {
      long int value;
      // Get the number of values to read.
      if (Tcl_GetLongFromObj(interp, objv[3], &value) != TCL_OK)
	return TCL_ERROR;

      if (value < 0) {
	Tcl_AppendResult(interp, "count can't be negative", (char *)NULL);
	return TCL_ERROR;
      }
      count = (size_t)value;
      objc--, objv++;
    }
  }

  // Process any option-value pairs that remain.
  for (int i = 3; i < objc; i++) {
    string = Tcl_GetString(objv[i]);
    if (strcmp(string, "-swap") == 0)
      swap = 1;
    else if (strcmp(string, "-format") == 0) {
      i++;
      if (i >= objc) {
	Tcl_AppendResult(interp, "missing arg after \"", string,
			 "\"", (char *)NULL);
	return TCL_ERROR;
      }

      string = Tcl_GetString(objv[i]);
      fmt = GetBinaryFormat(interp, string, &size);
      if (fmt == FMT_UNKNOWN)
	return TCL_ERROR;
    }
    else if (strcmp(string, "-at") == 0) {
      i++;
      if (i >= objc) {
	Tcl_AppendResult(interp, "missing arg after \"", string,
			 "\"", (char *)NULL);
	return TCL_ERROR;
      }

      string = Tcl_GetString(objv[i]);
      if (Vec_GetIndex(interp, vPtr, string, &first, 0, 
			   (Blt_VectorIndexProc **)NULL) != TCL_OK)
	return TCL_ERROR;

      if (first > vPtr->length) {
	Tcl_AppendResult(interp, "index \"", string,
			 "\" is out of range", (char *)NULL);
	return TCL_ERROR;
      }
    }
  }

#define BUFFER_SIZE 1024
  int arraySize = (count == 0) ? BUFFER_SIZE*size : count*size;

  char* byteArr = (char*)malloc(arraySize);
  // FIXME: restore old channel translation later?
  if (Tcl_SetChannelOption(interp, channel, "-translation","binary") != TCL_OK)
    return TCL_ERROR;

  int total = 0;
  while (!Tcl_Eof(channel)) {
    int bytesRead = Tcl_Read(channel, byteArr, arraySize);
    if (bytesRead < 0) {
      Tcl_AppendResult(interp, "error reading channel: ",
		       Tcl_PosixError(interp), (char *)NULL);
      return TCL_ERROR;
    }

    if ((bytesRead % size) != 0) {
      Tcl_AppendResult(interp, "error reading channel: short read",
		       (char *)NULL);
      return TCL_ERROR;
    }

    int length = bytesRead / size;
    if (CopyValues(vPtr, byteArr, fmt, size, length, swap, &first) != TCL_OK)
      return TCL_ERROR;

    total += length;
    if (count > 0)
      break;
  }
  free(byteArr);

  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  // Set the result as the number of values read
  Tcl_SetIntObj(Tcl_GetObjResult(interp), total);

  return TCL_OK;
}

static int SearchOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  int wantValue = 0;
  char* string = Tcl_GetString(objv[2]);
  if ((string[0] == '-') && (strcmp(string, "-value") == 0)) {
    wantValue = 1;
    objv++, objc--;
  }
  double min;
  if (Blt_ExprDoubleFromObj(interp, objv[2], &min) != TCL_OK)
    return TCL_ERROR;

  double max = min;
  if (objc > 4) {
    Tcl_AppendResult(interp, "wrong # arguments: should be \"",
		     Tcl_GetString(objv[0]), " search ?-value? min ?max?", 
		     (char *)NULL);
    return TCL_ERROR;
  }

  if ((objc > 3) && (Blt_ExprDoubleFromObj(interp, objv[3], &max) != TCL_OK))
    return TCL_ERROR;

  // Bogus range. Don't bother looking
  if ((min - max) >= DBL_EPSILON)
    return TCL_OK;

  Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
  if (wantValue) {
    for (int i = 0; i < vPtr->length; i++) {
      if (InRange(vPtr->valueArr[i], min, max))
	Tcl_ListObjAppendElement(interp, listObjPtr, 
				 Tcl_NewDoubleObj(vPtr->valueArr[i]));
    }
  }
  else {
    for (int i = 0; i < vPtr->length; i++) {
      if (InRange(vPtr->valueArr[i], min, max))
	Tcl_ListObjAppendElement(interp, listObjPtr,
				 Tcl_NewIntObj(i + vPtr->offset));
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);

  return TCL_OK;
}

static int OffsetOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  if (objc == 3) {
    int newOffset;
    if (Tcl_GetIntFromObj(interp, objv[2], &newOffset) != TCL_OK)
      return TCL_ERROR;

    vPtr->offset = newOffset;
  }
  Tcl_SetIntObj(Tcl_GetObjResult(interp), vPtr->offset);

  return TCL_OK;
}

static int RandomOp(Vector *vPtr, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  for (int i = 0; i < vPtr->length; i++)
    vPtr->valueArr[i] = drand48();

  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  return TCL_OK;
}

static int SeqOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  double start;
  if (Blt_ExprDoubleFromObj(interp, objv[2], &start) != TCL_OK)
    return TCL_ERROR;

  double stop;
  if (Blt_ExprDoubleFromObj(interp, objv[3], &stop) != TCL_OK)
    return TCL_ERROR;

  int n = vPtr->length;
  if ((objc > 4) && (Blt_ExprIntFromObj(interp, objv[4], &n) != TCL_OK))
    return TCL_ERROR;

  if (n > 1) {
    if (Vec_SetLength(interp, vPtr, n) != TCL_OK)
      return TCL_ERROR;

    double step = (stop - start) / (double)(n - 1);
    for (int i = 0; i < n; i++)
      vPtr->valueArr[i] = start + (step * i);

    if (vPtr->flush)
      Vec_FlushCache(vPtr);

    Vec_UpdateClients(vPtr);
  }
  return TCL_OK;
}

static int SetOp(Vector *vPtr, Tcl_Interp* interp, 
		 int objc, Tcl_Obj* const objv[])
{
  int nElem;
  Tcl_Obj **elemObjArr;

  // The source can be either a list of numbers or another vector.

  Vector* v2Ptr = Vec_ParseElement((Tcl_Interp *)NULL, vPtr->dataPtr, 
				   Tcl_GetString(objv[2]), NULL, 
				   NS_SEARCH_BOTH);
  int result;
  if (v2Ptr != NULL) {
    if (vPtr == v2Ptr) {
      // Source and destination vectors are the same.  Copy the source
      // first into a temporary vector to avoid memory overlaps.
      Vector* tmpPtr = Vec_New(vPtr->dataPtr);
      result = Vec_Duplicate(tmpPtr, v2Ptr);
      if (result == TCL_OK) {
	result = Vec_Duplicate(vPtr, tmpPtr);
      }
      Vec_Free(tmpPtr);
    }
    else
      result = Vec_Duplicate(vPtr, v2Ptr);
  }
  else if (Tcl_ListObjGetElements(interp, objv[2], &nElem, &elemObjArr) 
	   == TCL_OK)
    result = CopyList(vPtr, interp, nElem, elemObjArr);
  else
    return TCL_ERROR;

  if (result == TCL_OK) {
    // The vector has changed; so flush the array indices (they're wrong
    // now), find the new range of the data, and notify the vector's
    //clients that it's been modified.
    if (vPtr->flush)
      Vec_FlushCache(vPtr);
    Vec_UpdateClients(vPtr);
  }

  return result;
}

static int SimplifyOp(Vector *vPtr, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  double tolerance = 10.0;

  int nPoints = vPtr->length / 2;
  int* simple  = (int*)malloc(nPoints * sizeof(int));
  Point2d* reduced = (Point2d*)malloc(nPoints * sizeof(Point2d));
  Point2d* orig = (Point2d *)vPtr->valueArr;
  int n = Blt_SimplifyLine(orig, 0, nPoints - 1, tolerance, simple);
  for (int i = 0; i < n; i++)
    reduced[i] = orig[simple[i]];

  free(simple);
  Vec_Reset(vPtr, (double *)reduced, n * 2, vPtr->length, TCL_DYNAMIC);
  // The vector has changed; so flush the array indices (they're wrong
  // now), find the new range of the data, and notify the vector's
  // clients that it's been modified.
  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  return TCL_OK;
}

static int SplitOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  int nVectors = objc - 2;
  if ((vPtr->length % nVectors) != 0) {
    Tcl_AppendResult(interp, "can't split vector \"", vPtr->name, 
		     "\" into ", Itoa(nVectors), " even parts.", (char *)NULL);
    return TCL_ERROR;
  }

  if (nVectors > 0) {
    int extra = vPtr->length / nVectors;
    for (int i = 0; i < nVectors; i++) {
      char* string = Tcl_GetString(objv[i+2]);
      int isNew;
      Vector* v2Ptr = Vec_Create(vPtr->dataPtr, string, string, string, &isNew);
      int oldSize = v2Ptr->length;
      int newSize = oldSize + extra;
      if (Vec_SetLength(interp, v2Ptr, newSize) != TCL_OK)
	return TCL_ERROR;

      int j,k;
      for (j = i, k = oldSize; j < vPtr->length; j += nVectors, k++)
	v2Ptr->valueArr[k] = vPtr->valueArr[j];

      Vec_UpdateClients(v2Ptr);
      if (v2Ptr->flush) {
	Vec_FlushCache(v2Ptr);
      }
    }
  }
  return TCL_OK;
}


// Pointer to the array of values currently being sorted.
static Vector **sortVectors;
// Indicates the ordering of the sort. If non-zero, the vectors are sorted in
// decreasing order
static int sortDecreasing;
static int nSortVectors;

static int CompareVectors(void *a, void *b)
{
  int sign = (sortDecreasing) ? -1 : 1;
  for (int i = 0; i < nSortVectors; i++) {
    Vector* vPtr = sortVectors[i];
    double delta = vPtr->valueArr[*(int *)a] - vPtr->valueArr[*(int *)b];
    if (delta < 0.0)
      return (-1 * sign);
    else if (delta > 0.0)
      return (1 * sign);
  }

  return 0;
}

size_t* Blt::Vec_SortMap(Vector **vectors, int nVectors)
{
  Vector *vPtr = *vectors;
  int length = vPtr->last - vPtr->first + 1;
  size_t* map = (size_t*)malloc(sizeof(size_t) * length);
  for (int i = vPtr->first; i <= vPtr->last; i++)
    map[i] = i;

  // Set global variables for sorting routine
  sortVectors = vectors;
  nSortVectors = nVectors;
  qsort((char *)map, length, sizeof(size_t),(QSortCompareProc *)CompareVectors);

  return map;
}

static size_t* SortVectors(Vector *vPtr, Tcl_Interp* interp, 
			   int objc, Tcl_Obj* const objv[])
{

  Vector** vectors = (Vector**)malloc(sizeof(Vector *) * (objc + 1));
  vectors[0] = vPtr;
  size_t* map = NULL;
  for (int i = 0; i < objc; i++) {
    Vector* v2Ptr;
    if (Vec_LookupName(vPtr->dataPtr, Tcl_GetString(objv[i]), 
			   &v2Ptr) != TCL_OK)
      goto error;

    if (v2Ptr->length != vPtr->length) {
      Tcl_AppendResult(interp, "vector \"", v2Ptr->name,
		       "\" is not the same size as \"", vPtr->name, "\"",
		       (char *)NULL);
      goto error;
    }
    vectors[i + 1] = v2Ptr;
  }
  map = Vec_SortMap(vectors, objc + 1);

 error:
  free(vectors);

  return map;
}

static int SortOp(Vector *vPtr, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  sortDecreasing = 0;
  SortSwitches switches;
  switches.flags = 0;
  int i = ParseSwitches(interp, sortSwitches, objc - 2, objv + 2, &switches, 
			BLT_SWITCH_OBJV_PARTIAL);
  if (i < 0)
    return TCL_ERROR;

  objc -= i, objv += i;
  sortDecreasing = (switches.flags & SORT_DECREASING);

  size_t *map = (objc > 2) ? SortVectors(vPtr, interp, objc - 2, objv + 2) :
    Vec_SortMap(&vPtr, 1);

  if (map == NULL)
    return TCL_ERROR;

  int sortLength = vPtr->length;

  // Create an array to store a copy of the current values of the
  // vector. We'll merge the values back into the vector based upon the
  // indices found in the index array.
  size_t nBytes = sizeof(double) * sortLength;
  double* copy = (double*)malloc(nBytes);
  memcpy((char *)copy, (char *)vPtr->valueArr, nBytes);
  if (switches.flags & SORT_UNIQUE) {
    int count =1;
    for (int n = 1; n < sortLength; n++) {
      size_t next = map[n];
      size_t prev = map[n - 1];
      if (copy[next] != copy[prev]) {
	map[count] = next;
	count++;
      }
    }
    sortLength = count;
    nBytes = sortLength * sizeof(double);
  }

  if (sortLength != vPtr->length)
    Vec_SetLength(interp, vPtr, sortLength);

  for (int n = 0; n < sortLength; n++)
    vPtr->valueArr[n] = copy[map[n]];

  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  // Now sort any other vectors in the same fashion.  The vectors must be
  // the same size as the map though
  int result = TCL_ERROR;
  for (int i = 2; i < objc; i++) {
    Vector *v2Ptr;
    if (Vec_LookupName(vPtr->dataPtr, Tcl_GetString(objv[i]), &v2Ptr) != TCL_OK)
      goto error;

    if (sortLength != v2Ptr->length)
      Vec_SetLength(interp, v2Ptr, sortLength);

    memcpy((char *)copy, (char *)v2Ptr->valueArr, nBytes);
    for (int n = 0; n < sortLength; n++)
      v2Ptr->valueArr[n] = copy[map[n]];

    Vec_UpdateClients(v2Ptr);
    if (v2Ptr->flush)
      Vec_FlushCache(v2Ptr);
  }
  result = TCL_OK;

 error:
  free(copy);
  free(map);

  return result;
}

static int InstExprOp(Vector *vPtr, Tcl_Interp* interp, 
		      int objc, Tcl_Obj* const objv[])
{
  if (Blt_ExprVector(interp, Tcl_GetString(objv[2]), (Blt_Vector *)vPtr) != TCL_OK)
    return TCL_ERROR;

  if (vPtr->flush)
    Vec_FlushCache(vPtr);
  Vec_UpdateClients(vPtr);

  return TCL_OK;
}

static int ArithOp(Vector *vPtr, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
{
  double value;
  double scalar;

  Vector* v2Ptr = Vec_ParseElement((Tcl_Interp *)NULL, vPtr->dataPtr, 
				   Tcl_GetString(objv[2]), NULL, 
				   NS_SEARCH_BOTH);
  if (v2Ptr != NULL) {
    int length = v2Ptr->last - v2Ptr->first + 1;
    if (length != vPtr->length) {
      Tcl_AppendResult(interp, "vectors \"", Tcl_GetString(objv[0]), 
		       "\" and \"", Tcl_GetString(objv[2]), 
		       "\" are not the same length", (char *)NULL);
      return TCL_ERROR;
    }

    char* string = Tcl_GetString(objv[1]);
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    switch (string[0]) {
    case '*':
      for (int i = 0, j = v2Ptr->first; i < vPtr->length; i++, j++) {
	value = vPtr->valueArr[i] * v2Ptr->valueArr[j];
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '/':
      for (int i = 0, j = v2Ptr->first; i < vPtr->length; i++, j++) {
	value = vPtr->valueArr[i] / v2Ptr->valueArr[j];
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '-':
      for (int i = 0, j = v2Ptr->first; i < vPtr->length; i++, j++) {
	value = vPtr->valueArr[i] - v2Ptr->valueArr[j];
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '+':
      for (int i = 0, j = v2Ptr->first; i < vPtr->length; i++, j++) {
	value = vPtr->valueArr[i] + v2Ptr->valueArr[j];
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;
    }
    Tcl_SetObjResult(interp, listObjPtr);

  }
  else if (Blt_ExprDoubleFromObj(interp, objv[2], &scalar) == TCL_OK) {
    Tcl_Obj* listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **)NULL);
    char* string = Tcl_GetString(objv[1]);
    switch (string[0]) {
    case '*':
      for (int i = 0; i < vPtr->length; i++) {
	value = vPtr->valueArr[i] * scalar;
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '/':
      for (int i = 0; i < vPtr->length; i++) {
	value = vPtr->valueArr[i] / scalar;
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '-':
      for (int i = 0; i < vPtr->length; i++) {
	value = vPtr->valueArr[i] - scalar;
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;

    case '+':
      for (int i = 0; i < vPtr->length; i++) {
	value = vPtr->valueArr[i] + scalar;
	Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(value));
      }
      break;
    }
    Tcl_SetObjResult(interp, listObjPtr);
  }
  else
    return TCL_ERROR;

  return TCL_OK;
}

static Blt_OpSpec vectorInstOps[] =
  {
    {"*",         1, (void*)ArithOp,     3, 3, "item",},	/*Deprecated*/
    {"+",         1, (void*)ArithOp,     3, 3, "item",},	/*Deprecated*/
    {"-",         1, (void*)ArithOp,     3, 3, "item",},	/*Deprecated*/
    {"/",         1, (void*)ArithOp,     3, 3, "item",},	/*Deprecated*/
    {"append",    1, (void*)AppendOp,    3, 0, "items ?items...?",},
    {"binread",   1, (void*)BinreadOp,   3, 0, "channel ?numValues? ?flags?",},
    {"clear",     1, (void*)ClearOp,     2, 2, "",},
    {"delete",    2, (void*)DeleteOp,    2, 0, "index ?index...?",},
    {"dup",       2, (void*)DupOp,       3, 0, "vecName",},
    {"expr",      1, (void*)InstExprOp,  3, 3, "expression",},
    {"fft",	  1, (void*)FFTOp,	  3, 0, "vecName ?switches?",},
    {"index",     3, (void*)IndexOp,     3, 4, "index ?value?",},
    {"inversefft",3, (void*)InverseFFTOp,4, 4, "vecName vecName",},
    {"length",    1, (void*)LengthOp,    2, 3, "?newSize?",},
    {"max",       2, (void*)MaxOp,       2, 2, "",},
    {"merge",     2, (void*)MergeOp,     3, 0, "vecName ?vecName...?",},
    {"min",       2, (void*)MinOp,       2, 2, "",},
    {"normalize", 3, (void*)NormalizeOp, 2, 3, "?vecName?",},	/*Deprecated*/
    {"notify",    3, (void*)NotifyOp,    3, 3, "keyword",},
    {"offset",    1, (void*)OffsetOp,    2, 3, "?offset?",},
    {"populate",  1, (void*)PopulateOp,  4, 4, "vecName density",},
    {"random",    4, (void*)RandomOp,    2, 2, "",},	/*Deprecated*/
    {"range",     4, (void*)RangeOp,     2, 4, "first last",},
    {"search",    3, (void*)SearchOp,    3, 5, "?-value? value ?value?",},
    {"seq",       3, (void*)SeqOp,       4, 5, "begin end ?num?",},
    {"set",       3, (void*)SetOp,       3, 3, "list",},
    {"simplify",  2, (void*)SimplifyOp,  2, 2, },
    {"sort",      2, (void*)SortOp,      2, 0, "?switches? ?vecName...?",},
    {"split",     2, (void*)SplitOp,     2, 0, "?vecName...?",},
    {"values",    3, (void*)ValuesOp,    2, 0, "?switches?",},
    {"variable",  3, (void*)MapOp,       2, 3, "?varName?",},
  };

static int nInstOps = sizeof(vectorInstOps) / sizeof(Blt_OpSpec);

int Blt::Vec_InstCmd(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Vector* vPtr = (Vector*)clientData;
  vPtr->first = 0;
  vPtr->last = vPtr->length - 1;
  VectorCmdProc *proc =
    (VectorCmdProc*)GetOpFromObj(interp, nInstOps, vectorInstOps, 
				 BLT_OP_ARG1, objc, objv, 0);
  if (proc == NULL)
    return TCL_ERROR;

  return (*proc) (vPtr, interp, objc, objv);
}

#define MAX_ERR_MSG 1023
static char message[MAX_ERR_MSG + 1];
char* Blt::Vec_VarTrace(ClientData clientData, Tcl_Interp* interp, 
		       const char *part1, const char *part2, int flags)
{
  Blt_VectorIndexProc *indexProc;
  Vector* vPtr = (Vector*)clientData;

  if (part2 == NULL) {
    if (flags & TCL_TRACE_UNSETS) {
      free((void*)(vPtr->arrayName));
      vPtr->arrayName = NULL;
      if (vPtr->freeOnUnset)
	Vec_Free(vPtr);
    }

    return NULL;
  }

  int first;
  int last;
  int varFlags;

  if (Vec_GetIndexRange(interp, vPtr, part2, INDEX_ALL_FLAGS, &indexProc)
      != TCL_OK)
    goto error;

  first = vPtr->first;
  last = vPtr->last;
  varFlags = TCL_LEAVE_ERR_MSG | (TCL_GLOBAL_ONLY & flags);
  if (flags & TCL_TRACE_WRITES) {
    // Tried to set "min" or "max"
    if (first == SPECIAL_INDEX)
      return (char *)"read-only index";

    Tcl_Obj* objPtr = Tcl_GetVar2Ex(interp, part1, part2, varFlags);
    if (objPtr == NULL)
      goto error;

    double value;
    if (Blt_ExprDoubleFromObj(interp, objPtr, &value) != TCL_OK) {
      // Single numeric index. Reset the array element to
      // its old value on errors
      if ((last == first) && (first >= 0))
	Tcl_SetVar2Ex(interp, part1, part2, objPtr, varFlags);
      goto error;
    }

    if (first == vPtr->length) {
      if (Vec_ChangeLength((Tcl_Interp *)NULL, vPtr, vPtr->length + 1)
	  != TCL_OK)
	return (char *)"error resizing vector";
    }

    // Set possibly an entire range of values
    ReplicateValue(vPtr, first, last, value);
  }
  else if (flags & TCL_TRACE_READS) {
    Tcl_Obj *objPtr;

    if (vPtr->length == 0) {
      if (Tcl_SetVar2(interp, part1, part2, "", varFlags) == NULL)
	goto error;

      return NULL;
    }

    if  (first == vPtr->length)
      return (char *)"write-only index";

    if (first == last) {
      double value;
      if (first >= 0)
	value = vPtr->valueArr[first];
      else {
	vPtr->first = 0, vPtr->last = vPtr->length - 1;
	value = (*indexProc) ((Blt_Vector *) vPtr);
      }

      objPtr = Tcl_NewDoubleObj(value);
      if (Tcl_SetVar2Ex(interp, part1, part2, objPtr, varFlags) == NULL) {
	Tcl_DecrRefCount(objPtr);
	goto error;
      }
    }
    else {
      objPtr = GetValues(vPtr, first, last);
      if (Tcl_SetVar2Ex(interp, part1, part2, objPtr, varFlags) == NULL)
	Tcl_DecrRefCount(objPtr);
	goto error;
    }
  }
  else if (flags & TCL_TRACE_UNSETS) {
    if ((first == vPtr->length) || (first == SPECIAL_INDEX))
      return (char *)"special vector index";

    // Collapse the vector from the point of the first unset element.
    // Also flush any array variable entries so that the shift is
    // reflected when the array variable is read.
    for (int i = first, j = last + 1; j < vPtr->length; i++, j++)
      vPtr->valueArr[i] = vPtr->valueArr[j];

    vPtr->length -= ((last - first) + 1);
    if (vPtr->flush)
      Vec_FlushCache(vPtr);

  }
  else
    return (char *)"unknown variable trace flag";

  if (flags & (TCL_TRACE_UNSETS | TCL_TRACE_WRITES))
    Vec_UpdateClients(vPtr);

  Tcl_ResetResult(interp);
  return NULL;

 error: 
  strncpy(message, Tcl_GetStringResult(interp), MAX_ERR_MSG);
  message[MAX_ERR_MSG] = '\0';
  return message;
}
