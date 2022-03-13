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

#ifndef _BLT_VECTOR_H
#define _BLT_VECTOR_H

#include <tcl.h>

#ifdef BUILD_tkblt
#   define TKBLT_STORAGE_CLASS DLLEXPORT
#else
#   ifdef USE_TCL_STUBS
#      define TKBLT_STORAGE_CLASS /* */
#   else
#      define TKBLT_STORAGE_CLASS DLLIMPORT
#   endif
#endif


typedef enum {
  BLT_VECTOR_NOTIFY_UPDATE = 1, /* The vector's values has been updated */
  BLT_VECTOR_NOTIFY_DESTROY	/* The vector has been destroyed and the client
				 * should no longer use its data (calling
				 * Blt_FreeVectorId) */
} Blt_VectorNotify;

typedef struct _Blt_VectorId *Blt_VectorId;

typedef void (Blt_VectorChangedProc)(Tcl_Interp* interp, ClientData clientData,
				     Blt_VectorNotify notify);

typedef struct {
  double *valueArr;		/* Array of values (possibly malloc-ed) */
  int numValues;		/* Number of values in the array */
  int arraySize;		/* Size of the allocated space */
  double min, max;		/* Minimum and maximum values in the vector */
  int dirty;			/* Indicates if the vector has been updated */
  int reserved;		/* Reserved for future use */

} Blt_Vector;

typedef double (Blt_VectorIndexProc)(Blt_Vector * vecPtr);

typedef enum {
  BLT_MATH_FUNC_SCALAR = 1,	/* The function returns a single double
				 * precision value. */
  BLT_MATH_FUNC_VECTOR	/* The function processes the entire vector. */
} Blt_MathFuncType;

/*
 * To be safe, use the macros below, rather than the fields of the
 * structure directly.
 *
 * The Blt_Vector is basically an opaque type.  But it's also the
 * actual memory address of the vector itself.  I wanted to make the
 * API as unobtrusive as possible.  So instead of giving you a copy of
 * the vector, providing various functions to access and update the
 * vector, you get your hands on the actual memory (array of doubles)
 * shared by all the vector's clients.
 *
 * The trade-off for speed and convenience is safety.  You can easily
 * break things by writing into the vector when other clients are
 * using it.  Use Blt_ResetVector to get around this.  At least the
 * macros are a reminder it isn't really safe to reset the data
 * fields, except by the API routines.  
 */
#define Blt_VecData(v)		((v)->valueArr)
#define Blt_VecLength(v)	((v)->numValues)
#define Blt_VecSize(v)		((v)->arraySize)
#define Blt_VecDirty(v)		((v)->dirty)

#ifdef __cplusplus
extern "C" {
#endif
  TKBLT_STORAGE_CLASS int Blt_CreateVector(Tcl_Interp* interp, const char *vecName,
			      int size, Blt_Vector** vecPtrPtr);
  TKBLT_STORAGE_CLASS int Blt_CreateVector2(Tcl_Interp* interp, const char *vecName,
			       const char *cmdName, const char *varName,
			       int initialSize, Blt_Vector **vecPtrPtr);
  TKBLT_STORAGE_CLASS int Blt_DeleteVectorByName(Tcl_Interp* interp, const char *vecName);
  TKBLT_STORAGE_CLASS int Blt_DeleteVector(Blt_Vector *vecPtr);
  TKBLT_STORAGE_CLASS int Blt_GetVector(Tcl_Interp* interp, const char *vecName,
			   Blt_Vector **vecPtrPtr);
  TKBLT_STORAGE_CLASS int Blt_GetVectorFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr,
				  Blt_Vector **vecPtrPtr);
  TKBLT_STORAGE_CLASS int Blt_ResetVector(Blt_Vector *vecPtr, double *dataArr, int n,
			     int arraySize, Tcl_FreeProc *freeProc);
  TKBLT_STORAGE_CLASS int Blt_ResizeVector(Blt_Vector *vecPtr, int n);
  TKBLT_STORAGE_CLASS int Blt_VectorExists(Tcl_Interp* interp, const char *vecName);
  TKBLT_STORAGE_CLASS int Blt_VectorExists2(Tcl_Interp* interp, const char *vecName);
  TKBLT_STORAGE_CLASS Blt_VectorId Blt_AllocVectorId(Tcl_Interp* interp, const char *vecName);
  TKBLT_STORAGE_CLASS int Blt_GetVectorById(Tcl_Interp* interp, Blt_VectorId clientId,
			       Blt_Vector **vecPtrPtr);
  TKBLT_STORAGE_CLASS void Blt_SetVectorChangedProc(Blt_VectorId clientId,
				       Blt_VectorChangedProc *proc,
				       ClientData clientData);
  TKBLT_STORAGE_CLASS void Blt_FreeVectorId(Blt_VectorId clientId);
  TKBLT_STORAGE_CLASS const char *Blt_NameOfVectorId(Blt_VectorId clientId);
  TKBLT_STORAGE_CLASS const char *Blt_NameOfVector(Blt_Vector *vecPtr);
  TKBLT_STORAGE_CLASS int Blt_ExprVector(Tcl_Interp* interp, char *expr, Blt_Vector *vecPtr);
  TKBLT_STORAGE_CLASS void Blt_InstallIndexProc(Tcl_Interp* interp, const char *indexName,
				   Blt_VectorIndexProc * procPtr);
  TKBLT_STORAGE_CLASS double Blt_VecMin(Blt_Vector *vPtr);
  TKBLT_STORAGE_CLASS double Blt_VecMax(Blt_Vector *vPtr);
#ifdef __cplusplus
}
#endif

#include "tkbltDecls.h"

#endif /* _BLT_VECTOR_H */
