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
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>

#include <cmath>

#include "tkbltInt.h"
#include "tkbltVecInt.h"
#include "tkbltNsUtil.h"
#include "tkbltSwitch.h"
#include "tkbltOp.h"

using namespace Blt;

#define DEF_ARRAY_SIZE		64
#define TRACE_ALL  (TCL_TRACE_WRITES | TCL_TRACE_READS | TCL_TRACE_UNSETS)


#define VECTOR_CHAR(c)	((isalnum((unsigned char)(c))) ||		\
			 (c == '_') || (c == ':') || (c == '@') || (c == '.'))

/*
 * VectorClient --
 *
 *	A vector can be shared by several clients.  Each client allocates this
 *	structure that acts as its key for using the vector.  Clients can also
 *	designate a callback routine that is executed whenever the vector is
 *	updated or destroyed.
 *
 */
typedef struct {
  unsigned int magic;		/* Magic value designating whether this really
				 * is a vector token or not */
  Vector* serverPtr;		/* Pointer to the master record of the vector.
				 * If NULL, indicates that the vector has been
				 * destroyed but as of yet, this client hasn't
				 * recognized it. */
  Blt_VectorChangedProc *proc;/* Routine to call when the contents of the
			       * vector change or the vector is deleted. */
  ClientData clientData;	/* Data passed whenever the vector change
				 * procedure is called. */
  ChainLink* link;		/* Used to quickly remove this entry from its
				 * server's client chain. */
} VectorClient;

static Tcl_CmdDeleteProc VectorInstDeleteProc;
extern Tcl_ObjCmdProc VectorObjCmd;
static Tcl_InterpDeleteProc VectorInterpDeleteProc;

typedef struct {
  char *varName;		/* Requested variable name. */
  char *cmdName;		/* Requested command name. */
  int flush;			/* Flush */
  int watchUnset;		/* Watch when variable is unset. */
} CreateSwitches;

static Blt_SwitchSpec createSwitches[] = 
  {
    {BLT_SWITCH_STRING, "-variable", "varName",
     Tk_Offset(CreateSwitches, varName), BLT_SWITCH_NULL_OK},
    {BLT_SWITCH_STRING, "-command", "command",
     Tk_Offset(CreateSwitches, cmdName), BLT_SWITCH_NULL_OK},
    {BLT_SWITCH_BOOLEAN, "-watchunset", "bool",
     Tk_Offset(CreateSwitches, watchUnset), 0},
    {BLT_SWITCH_BOOLEAN, "-flush", "bool",
     Tk_Offset(CreateSwitches, flush), 0},
    {BLT_SWITCH_END}
  };

typedef int (VectorCmdProc)(Vector* vecObjPtr, Tcl_Interp* interp, 
			    int objc, Tcl_Obj* const objv[]);

static char stringRep[200];

const char *Blt::Itoa(int value)
{
  snprintf(stringRep, 200, "%d", value);
  return stringRep;
}

static char* Blt_Strdup(const char *string)
{
  size_t size = strlen(string) + 1;
  char* ptr = (char*)malloc(size * sizeof(char));
  if (ptr != NULL)
    strcpy(ptr, string);

  return ptr;
}

static Vector* FindVectorInNamespace(VectorInterpData *dataPtr,	
				     Blt_ObjectName *objNamePtr)
{
  Tcl_DString dString;
  const char* name = MakeQualifiedName(objNamePtr, &dString);
  Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&dataPtr->vectorTable, name);
  Tcl_DStringFree(&dString);
  if (hPtr != NULL)
    return (Vector*)Tcl_GetHashValue(hPtr);

  return NULL;
}

static Vector* GetVectorObject(VectorInterpData *dataPtr, const char *name,
			       int flags)
{
  Tcl_Interp* interp = dataPtr->interp;
  Blt_ObjectName objName;
  if (!ParseObjectName(interp, name, &objName, BLT_NO_ERROR_MSG | BLT_NO_DEFAULT_NS))
    return NULL;

  Vector* vPtr = NULL;
  if (objName.nsPtr != NULL)
    vPtr = FindVectorInNamespace(dataPtr, &objName);
  else {
    if (flags & NS_SEARCH_CURRENT) {
      objName.nsPtr = Tcl_GetCurrentNamespace(interp);
      vPtr = FindVectorInNamespace(dataPtr, &objName);
    }
    if ((vPtr == NULL) && (flags & NS_SEARCH_GLOBAL)) {
      objName.nsPtr = Tcl_GetGlobalNamespace(interp);
      vPtr = FindVectorInNamespace(dataPtr, &objName);
    }
  }

  return vPtr;
}

void Blt::Vec_UpdateRange(Vector* vPtr)
{
  double* vp = vPtr->valueArr + vPtr->first;
  double* vend = vPtr->valueArr + vPtr->last;
  double min = *vp;
  double max = *vp++;
  for (/* empty */; vp <= vend; vp++) {
    if (min > *vp)
      min = *vp; 
    else if (max < *vp)
      max = *vp; 
  } 
  vPtr->min = min;
  vPtr->max = max;
  vPtr->notifyFlags &= ~UPDATE_RANGE;
}

int Blt::Vec_GetIndex(Tcl_Interp* interp, Vector* vPtr, const char *string,
		     int *indexPtr, int flags, Blt_VectorIndexProc **procPtrPtr)
{
  int value;
  char c = string[0];

  // Treat the index "end" like a numeric index
  if ((c == 'e') && (strcmp(string, "end") == 0)) {
    if (vPtr->length < 1) {
      if (interp != NULL) {
	Tcl_AppendResult(interp, "bad index \"end\": vector is empty", 
			 (char *)NULL);
      }
      return TCL_ERROR;
    }
    *indexPtr = vPtr->length - 1;
    return TCL_OK;
  } else if ((c == '+') && (strcmp(string, "++end") == 0)) {
    *indexPtr = vPtr->length;
    return TCL_OK;
  }
  if (procPtrPtr != NULL) {
    Tcl_HashEntry *hPtr;

    hPtr = Tcl_FindHashEntry(&vPtr->dataPtr->indexProcTable, string);
    if (hPtr != NULL) {
      *indexPtr = SPECIAL_INDEX;
      *procPtrPtr = (Blt_VectorIndexProc*)Tcl_GetHashValue(hPtr);
      return TCL_OK;
    }
  }
  if (Tcl_GetInt(interp, (char *)string, &value) != TCL_OK) {
    long int lvalue;
    /*   
     * Unlike Tcl_GetInt, Tcl_ExprLong needs a valid interpreter, but the
     * interp passed in may be NULL.  So we have to use vPtr->interp and
     * then reset the result.
     */
    if (Tcl_ExprLong(vPtr->interp, (char *)string, &lvalue) != TCL_OK) {
      Tcl_ResetResult(vPtr->interp);
      if (interp != NULL) {
	Tcl_AppendResult(interp, "bad index \"", string, "\"", 
			 (char *)NULL);
      }
      return TCL_ERROR;
    }
    value = (int)lvalue;
  }
  /*
   * Correct the index by the current value of the offset. This makes all
   * the numeric indices non-negative, which is how we distinguish the
   * special non-numeric indices.
   */
  value -= vPtr->offset;

  if ((value < 0) || ((flags & INDEX_CHECK) && (value >= vPtr->length))) {
    if (interp != NULL) {
      Tcl_AppendResult(interp, "index \"", string, "\" is out of range", 
		       (char *)NULL);
    }
    return TCL_ERROR;
  }
  *indexPtr = (int)value;
  return TCL_OK;
}

int Blt::Vec_GetIndexRange(Tcl_Interp* interp, Vector* vPtr, const char *string,
			   int flags, Blt_VectorIndexProc** procPtrPtr)
{
  int ielem;
  char* colon = NULL;
  if (flags & INDEX_COLON)
    colon = (char*)strchr(string, ':');

  if (colon != NULL) {
    if (string == colon) {
      vPtr->first = 0;	/* Default to the first index */
    }
    else {
      int result;

      *colon = '\0';
      result = Vec_GetIndex(interp, vPtr, string, &ielem, flags,
				(Blt_VectorIndexProc **) NULL);
      *colon = ':';
      if (result != TCL_OK) {
	return TCL_ERROR;
      }
      vPtr->first = ielem;
    }
    if (*(colon + 1) == '\0') {
      /* Default to the last index */
      vPtr->last = (vPtr->length > 0) ? vPtr->length - 1 : 0;
    } else {
      if (Vec_GetIndex(interp, vPtr, colon + 1, &ielem, flags,
			   (Blt_VectorIndexProc **) NULL) != TCL_OK) {
	return TCL_ERROR;
      }
      vPtr->last = ielem;
    }
    if (vPtr->first > vPtr->last) {
      if (interp != NULL) {
	Tcl_AppendResult(interp, "bad range \"", string,
			 "\" (first > last)", (char *)NULL);
      }
      return TCL_ERROR;
    }
  } else {
    if (Vec_GetIndex(interp, vPtr, string, &ielem, flags, 
			 procPtrPtr) != TCL_OK) {
      return TCL_ERROR;
    }
    vPtr->last = vPtr->first = ielem;
  }
  return TCL_OK;
}

Vector* Blt::Vec_ParseElement(Tcl_Interp* interp, VectorInterpData *dataPtr,
			     const char* start, const char** endPtr, int flags)
{
  char* p = (char*)start;
  // Find the end of the vector name
  while (VECTOR_CHAR(*p)) {
    p++;
  }
  char saved = *p;
  *p = '\0';

  Vector* vPtr = GetVectorObject(dataPtr, start, flags);
  if (vPtr == NULL) {
    if (interp != NULL) {
      Tcl_AppendResult(interp, "can't find vector \"", start, "\"", 
		       (char *)NULL);
    }
    *p = saved;
    return NULL;
  }
  *p = saved;
  vPtr->first = 0;
  vPtr->last = vPtr->length - 1;
  if (*p == '(') {
    int count, result;

    start = p + 1;
    p++;

    /* Find the matching right parenthesis */
    count = 1;
    while (*p != '\0') {
      if (*p == ')') {
	count--;
	if (count == 0) {
	  break;
	}
      } else if (*p == '(') {
	count++;
      }
      p++;
    }
    if (count > 0) {
      if (interp != NULL) {
	Tcl_AppendResult(interp, "unbalanced parentheses \"", start, 
			 "\"", (char *)NULL);
      }
      return NULL;
    }
    *p = '\0';
    result = Vec_GetIndexRange(interp, vPtr, start, (INDEX_COLON | INDEX_CHECK), (Blt_VectorIndexProc **) NULL);
    *p = ')';
    if (result != TCL_OK) {
      return NULL;
    }
    p++;
  }
  if (endPtr != NULL) {
    *endPtr = p;
  }
  return vPtr;
}

void Blt_Vec_NotifyClients(ClientData clientData)
{
  Vector* vPtr = (Vector*)clientData;
  ChainLink *link, *next;
  Blt_VectorNotify notify;

  notify = (vPtr->notifyFlags & NOTIFY_DESTROYED)
    ? BLT_VECTOR_NOTIFY_DESTROY : BLT_VECTOR_NOTIFY_UPDATE;
  vPtr->notifyFlags &= ~(NOTIFY_UPDATED | NOTIFY_DESTROYED | NOTIFY_PENDING);
  for (link = Chain_FirstLink(vPtr->chain); link; link = next) {
    next = Chain_NextLink(link);
    VectorClient *clientPtr = (VectorClient*)Chain_GetValue(link);
    if ((clientPtr->proc != NULL) && (clientPtr->serverPtr != NULL)) {
      (*clientPtr->proc) (vPtr->interp, clientPtr->clientData, notify);
    }
  }

  // Some clients may not handle the "destroy" callback properly (they
  // should call Blt_FreeVectorId to release the client identifier), so mark
  // any remaining clients to indicate that vector's server has gone away.
  if (notify == BLT_VECTOR_NOTIFY_DESTROY) {
    for (link = Chain_FirstLink(vPtr->chain); link; 
	 link = Chain_NextLink(link)) {
      VectorClient *clientPtr = (VectorClient*)Chain_GetValue(link);
      clientPtr->serverPtr = NULL;
    }
  }
}

void Blt::Vec_UpdateClients(Vector* vPtr)
{
  vPtr->dirty++;
  vPtr->max = vPtr->min = NAN;
  if (vPtr->notifyFlags & NOTIFY_NEVER) {
    return;
  }
  vPtr->notifyFlags |= NOTIFY_UPDATED;
  if (vPtr->notifyFlags & NOTIFY_ALWAYS) {
    Blt_Vec_NotifyClients(vPtr);
    return;
  }
  if (!(vPtr->notifyFlags & NOTIFY_PENDING)) {
    vPtr->notifyFlags |= NOTIFY_PENDING;
    Tcl_DoWhenIdle(Blt_Vec_NotifyClients, vPtr);
  }
}

void Blt::Vec_FlushCache(Vector* vPtr)
{
  Tcl_Interp* interp = vPtr->interp;

  if (vPtr->arrayName == NULL)
    return;

  /* Turn off the trace temporarily so that we can unset all the
   * elements in the array.  */

  Tcl_UntraceVar2(interp, vPtr->arrayName, (char *)NULL,
		  TRACE_ALL | vPtr->varFlags, Vec_VarTrace, vPtr);

  /* Clear all the element entries from the entire array */
  Tcl_UnsetVar2(interp, vPtr->arrayName, (char *)NULL, vPtr->varFlags);

  /* Restore the "end" index by default and the trace on the entire array */
  Tcl_SetVar2(interp, vPtr->arrayName, "end", "", vPtr->varFlags);
  Tcl_TraceVar2(interp, vPtr->arrayName, (char *)NULL,
		TRACE_ALL | vPtr->varFlags, Vec_VarTrace, vPtr);
}

int Blt::Vec_LookupName(VectorInterpData *dataPtr, const char *vecName,
		       Vector** vPtrPtr)
{

  const char *endPtr;
  Vector* vPtr = Vec_ParseElement(dataPtr->interp, dataPtr, vecName, &endPtr, NS_SEARCH_BOTH);
  if (vPtr == NULL)
    return TCL_ERROR;

  if (*endPtr != '\0') {
    Tcl_AppendResult(dataPtr->interp, 
		     "extra characters after vector name", (char *)NULL);
    return TCL_ERROR;
  }

  *vPtrPtr = vPtr;
  return TCL_OK;
}

double Blt::Vec_Min(Vector* vecObjPtr)
{
  double* vp = vecObjPtr->valueArr + vecObjPtr->first;
  double* vend = vecObjPtr->valueArr + vecObjPtr->last;
  double min = *vp++;
  for (/* empty */; vp <= vend; vp++) {
    if (min > *vp)
      min = *vp; 
  } 
  vecObjPtr->min = min;
  return vecObjPtr->min;
}

double Blt::Vec_Max(Vector* vecObjPtr)
{
  double max = NAN;
  double* vp = vecObjPtr->valueArr + vecObjPtr->first;
  double* vend = vecObjPtr->valueArr + vecObjPtr->last;
  max = *vp++;
  for (/* empty */; vp <= vend; vp++) {
    if (max < *vp)
      max = *vp; 
  } 
  vecObjPtr->max = max;
  return vecObjPtr->max;
}

static void DeleteCommand(Vector* vPtr)
{
  Tcl_Interp* interp = vPtr->interp;
  char *qualName;
  Tcl_CmdInfo cmdInfo;
  Tcl_DString dString;
  Blt_ObjectName objName;

  Tcl_DStringInit(&dString);
  objName.name = Tcl_GetCommandName(interp, vPtr->cmdToken);
  objName.nsPtr = GetCommandNamespace(vPtr->cmdToken);
  qualName = MakeQualifiedName(&objName, &dString);
  if (Tcl_GetCommandInfo(interp, qualName, &cmdInfo)) {
    // Disable the callback before deleting the TCL command
    cmdInfo.deleteProc = NULL;	
    Tcl_SetCommandInfo(interp, qualName, &cmdInfo);
    Tcl_DeleteCommandFromToken(interp, vPtr->cmdToken);
  }
  Tcl_DStringFree(&dString);
  vPtr->cmdToken = 0;
}

static void UnmapVariable(Vector* vPtr)
{
  Tcl_Interp* interp = vPtr->interp;

  // Unset the entire array
  Tcl_UntraceVar2(interp, vPtr->arrayName, (char *)NULL,
		  (TRACE_ALL | vPtr->varFlags), Vec_VarTrace, vPtr);
  Tcl_UnsetVar2(interp, vPtr->arrayName, (char *)NULL, vPtr->varFlags);

  if (vPtr->arrayName != NULL) {
    free((void*)(vPtr->arrayName));
    vPtr->arrayName = NULL;
  }
}

int Blt::Vec_MapVariable(Tcl_Interp* interp, Vector* vPtr, const char *path)
{
  Blt_ObjectName objName;
  char *newPath;
  const char *result;
  Tcl_DString dString;

  if (vPtr->arrayName != NULL) {
    UnmapVariable(vPtr);
  }
  if ((path == NULL) || (path[0] == '\0')) {
    return TCL_OK;		/* If the variable pathname is the empty
				 * string, simply return after removing any
				 * existing variable. */
  }
  /* Get the variable name (without the namespace qualifier). */
  if (!ParseObjectName(interp, path, &objName, BLT_NO_DEFAULT_NS)) {
    return TCL_ERROR;
  }
  if (objName.nsPtr == NULL) {
    /* 
     * If there was no namespace qualifier, try harder to see if the
     * variable is non-local.
     */
    objName.nsPtr = GetVariableNamespace(interp, objName.name);
  } 
  Tcl_DStringInit(&dString);
  vPtr->varFlags = 0;
  if (objName.nsPtr != NULL) {	/* Global or namespace variable. */
    newPath = MakeQualifiedName(&objName, &dString);
    vPtr->varFlags |= (TCL_GLOBAL_ONLY);
  } else {			/* Local variable. */
    newPath = (char *)objName.name;
  }

  /*
   * To play it safe, delete the variable first.  This has the benefical
   * side-effect of unmapping the variable from another vector that may be
   * currently associated with it.
   */
  Tcl_UnsetVar2(interp, newPath, (char *)NULL, 0);

  /* 
   * Set the index "end" in the array.  This will create the variable
   * immediately so that we can check its namespace context.
   */
  result = Tcl_SetVar2(interp, newPath, "end", "", TCL_LEAVE_ERR_MSG);
  if (result == NULL) {
    Tcl_DStringFree(&dString);
    return TCL_ERROR;
  }
  /* Create a full-array trace on reads, writes, and unsets. */
  Tcl_TraceVar2(interp, newPath, (char *)NULL, TRACE_ALL, Vec_VarTrace,
		vPtr);
  vPtr->arrayName = Blt_Strdup(newPath);
  Tcl_DStringFree(&dString);
  return TCL_OK;
}

int Blt::Vec_SetSize(Tcl_Interp* interp, Vector* vPtr, int newSize)
{
  if (newSize <= 0) {
    newSize = DEF_ARRAY_SIZE;
  }
  if (newSize == vPtr->size) {
    /* Same size, use the current array. */
    return TCL_OK;
  } 
  if (vPtr->freeProc == TCL_DYNAMIC) {
    /* Old memory was dynamically allocated, so use realloc. */
    double* newArr = (double*)realloc(vPtr->valueArr, newSize * sizeof(double));
    if (newArr == NULL) {
      if (interp != NULL) {
	Tcl_AppendResult(interp, "can't reallocate ", 
			 Itoa(newSize), " elements for vector \"", 
			 vPtr->name, "\"", (char *)NULL); 
      }
      return TCL_ERROR;
    }
    vPtr->size = newSize;
    vPtr->valueArr = newArr;
    return TCL_OK;
  }

  {
    /* Old memory was created specially (static or special allocator).
     * Replace with dynamically allocated memory (malloc-ed). */

    double* newArr = (double*)calloc(newSize, sizeof(double));
    if (newArr == NULL) {
      if (interp != NULL) {
	Tcl_AppendResult(interp, "can't allocate ", 
			 Itoa(newSize), " elements for vector \"", 
			 vPtr->name, "\"", (char *)NULL); 
      }
      return TCL_ERROR;
    }
    {
      int used, wanted;
	    
      /* Copy the contents of the old memory into the new. */
      used = vPtr->length;
      wanted = newSize;
	    
      if (used > wanted) {
	used = wanted;
      }
      /* Copy any previous data */
      if (used > 0) {
	memcpy(newArr, vPtr->valueArr, used * sizeof(double));
      }
    }
	
    /* 
     * We're not using the old storage anymore, so free it if it's not
     * TCL_STATIC.  It's static because the user previously reset the
     * vector with a statically allocated array (setting freeProc to
     * TCL_STATIC).
     */
    if (vPtr->freeProc != TCL_STATIC) {
      if (vPtr->freeProc == TCL_DYNAMIC) {
	free(vPtr->valueArr);
      } else {
	(*vPtr->freeProc) ((char *)vPtr->valueArr);
      }
    }
    vPtr->freeProc = TCL_DYNAMIC; /* Set the type of the new storage */
    vPtr->valueArr = newArr;
    vPtr->size = newSize;
  }
  return TCL_OK;
}

int Blt::Vec_SetLength(Tcl_Interp* interp, Vector* vPtr, int newLength)
{
  if (vPtr->size < newLength) {
    if (Vec_SetSize(interp, vPtr, newLength) != TCL_OK) {
      return TCL_ERROR;
    }
  }
  vPtr->length = newLength;
  vPtr->first = 0;
  vPtr->last = newLength - 1;
  return TCL_OK;
}

int Blt::Vec_ChangeLength(Tcl_Interp* interp, Vector* vPtr, int newLength)
{
  if (newLength < 0) {
    newLength = 0;
  } 
  if (newLength > vPtr->size) {
    int newSize;		/* Size of array in elements */
    
    /* Compute the new size of the array.  It's a multiple of
     * DEF_ARRAY_SIZE. */
    newSize = DEF_ARRAY_SIZE;
    while (newSize < newLength) {
      newSize += newSize;
    }
    if (newSize != vPtr->size) {
      if (Vec_SetSize(interp, vPtr, newSize) != TCL_OK) {
	return TCL_ERROR;
      }
    }
  }
  vPtr->length = newLength;
  vPtr->first = 0;
  vPtr->last = newLength - 1;
  return TCL_OK;
    
}

int Blt::Vec_Reset(Vector* vPtr, double *valueArr, int length,
		  int size, Tcl_FreeProc *freeProc)
{
  if (vPtr->valueArr != valueArr) {	/* New array of values resides
					 * in different memory than
					 * the current vector.  */
    if ((valueArr == NULL) || (size == 0)) {
      /* Empty array. Set up default values */
      valueArr = (double*)malloc(sizeof(double) * DEF_ARRAY_SIZE);
      size = DEF_ARRAY_SIZE;
      if (valueArr == NULL) {
	Tcl_AppendResult(vPtr->interp, "can't allocate ", 
			 Itoa(size), " elements for vector \"", 
			 vPtr->name, "\"", (char *)NULL);
	return TCL_ERROR;
      }
      freeProc = TCL_DYNAMIC;
      length = 0;
    }
    else if (freeProc == TCL_VOLATILE) {
      /* Data is volatile. Make a copy of the value array.  */
      double* newArr = (double*)malloc(size * sizeof(double));
      if (newArr == NULL) {
	Tcl_AppendResult(vPtr->interp, "can't allocate ", 
			 Itoa(size), " elements for vector \"", 
			 vPtr->name, "\"", (char *)NULL);
	return TCL_ERROR;
      }
      memcpy((char *)newArr, (char *)valueArr, 
	     sizeof(double) * length);
      valueArr = newArr;
      freeProc = TCL_DYNAMIC;
    } 

    if (vPtr->freeProc != TCL_STATIC) {
      /* Old data was dynamically allocated. Free it before attaching
       * new data.  */
      if (vPtr->freeProc == TCL_DYNAMIC) {
	free(vPtr->valueArr);
      } else {
	(*freeProc) ((char *)vPtr->valueArr);
      }
    }
    vPtr->freeProc = freeProc;
    vPtr->valueArr = valueArr;
    vPtr->size = size;
  }

  vPtr->length = length;
  if (vPtr->flush) {
    Vec_FlushCache(vPtr);
  }
  Vec_UpdateClients(vPtr);
  return TCL_OK;
}

Vector* Blt::Vec_New(VectorInterpData *dataPtr)
{
  Vector* vPtr = (Vector*)calloc(1, sizeof(Vector));
  vPtr->valueArr = (double*)malloc(sizeof(double) * DEF_ARRAY_SIZE);
  if (vPtr->valueArr == NULL) {
    free(vPtr);
    return NULL;
  }
  vPtr->size = DEF_ARRAY_SIZE;
  vPtr->freeProc = TCL_DYNAMIC;
  vPtr->length = 0;
  vPtr->interp = dataPtr->interp;
  vPtr->hashPtr = NULL;
  vPtr->chain = new Chain();
  vPtr->flush = 0;
  vPtr->min = vPtr->max = NAN;
  vPtr->notifyFlags = NOTIFY_WHENIDLE;
  vPtr->dataPtr = dataPtr;
  return vPtr;
}

void Blt::Vec_Free(Vector* vPtr)
{
  ChainLink* link;

  if (vPtr->cmdToken != 0) {
    DeleteCommand(vPtr);
  }
  if (vPtr->arrayName != NULL) {
    UnmapVariable(vPtr);
  }
  vPtr->length = 0;

  /* Immediately notify clients that vector is going away */
  if (vPtr->notifyFlags & NOTIFY_PENDING) {
    vPtr->notifyFlags &= ~NOTIFY_PENDING;
    Tcl_CancelIdleCall(Blt_Vec_NotifyClients, vPtr);
  }
  vPtr->notifyFlags |= NOTIFY_DESTROYED;
  Blt_Vec_NotifyClients(vPtr);

  for (link = Chain_FirstLink(vPtr->chain); link; link = Chain_NextLink(link)) {
    VectorClient *clientPtr = (VectorClient*)Chain_GetValue(link);
    free(clientPtr);
  }
  delete vPtr->chain;
  if ((vPtr->valueArr != NULL) && (vPtr->freeProc != TCL_STATIC)) {
    if (vPtr->freeProc == TCL_DYNAMIC) {
      free(vPtr->valueArr);
    } else {
      (*vPtr->freeProc) ((char *)vPtr->valueArr);
    }
  }
  if (vPtr->hashPtr != NULL) {
    Tcl_DeleteHashEntry(vPtr->hashPtr);
  }
#ifdef NAMESPACE_DELETE_NOTIFY
  if (vPtr->nsPtr != NULL) {
    Blt_DestroyNsDeleteNotify(vPtr->interp, vPtr->nsPtr, vPtr);
  }
#endif /* NAMESPACE_DELETE_NOTIFY */
  free(vPtr);
}

static void VectorInstDeleteProc(ClientData clientData)
{
  Vector* vPtr = (Vector*)clientData;
  vPtr->cmdToken = 0;
  Vec_Free(vPtr);
}

Vector* Blt::Vec_Create(VectorInterpData *dataPtr, const char *vecName,
		       const char *cmdName, const char *varName, int *isNewPtr)
{
  Tcl_DString dString;
  Blt_ObjectName objName;
  char *qualName;
  Tcl_HashEntry *hPtr;
  Tcl_Interp* interp = dataPtr->interp;

  int isNew = 0;
  Vector* vPtr = NULL;

  if (!ParseObjectName(interp, vecName, &objName, 0))
    return NULL;

  Tcl_DStringInit(&dString);
  if ((objName.name[0] == '#') && (strcmp(objName.name, "#auto") == 0)) {

    do {	/* Generate a unique vector name. */
      char string[200];

      snprintf(string, 200, "vector%d", dataPtr->nextId++);
      objName.name = string;
      qualName = MakeQualifiedName(&objName, &dString);
      hPtr = Tcl_FindHashEntry(&dataPtr->vectorTable, qualName);
    } while (hPtr != NULL);
  } else {
    const char *p;

    for (p = objName.name; *p != '\0'; p++) {
      if (!VECTOR_CHAR(*p)) {
	Tcl_AppendResult(interp, "bad vector name \"", objName.name,
			 "\": must contain digits, letters, underscore, or period",
			 (char *)NULL);
	goto error;
      }
    }
    qualName = MakeQualifiedName(&objName, &dString);
    vPtr = Vec_ParseElement((Tcl_Interp *)NULL, dataPtr, qualName, 
				NULL, NS_SEARCH_CURRENT);
  }
  if (vPtr == NULL) {
    hPtr = Tcl_CreateHashEntry(&dataPtr->vectorTable, qualName, &isNew);
    vPtr = Vec_New(dataPtr);
    vPtr->hashPtr = hPtr;
    vPtr->nsPtr = objName.nsPtr;

    vPtr->name = (const char*)Tcl_GetHashKey(&dataPtr->vectorTable, hPtr);
#ifdef NAMESPACE_DELETE_NOTIFY
    Blt_CreateNsDeleteNotify(interp, objName.nsPtr, vPtr, 
			     VectorInstDeleteProc);
#endif /* NAMESPACE_DELETE_NOTIFY */
    Tcl_SetHashValue(hPtr, vPtr);
  }
  if (cmdName != NULL) {
    Tcl_CmdInfo cmdInfo;

    if ((cmdName == vecName) ||
	((cmdName[0] == '#') && (strcmp(cmdName, "#auto")==0))) {
      cmdName = qualName;
    } 
    if (Tcl_GetCommandInfo(interp, (char *)cmdName, &cmdInfo)) {
      if (vPtr != cmdInfo.objClientData) {
	Tcl_AppendResult(interp, "command \"", cmdName,
			 "\" already exists", (char *)NULL);
	goto error;
      }
      /* We get here only if the old name is the same as the new. */
      goto checkVariable;
    }
  }
  if (vPtr->cmdToken != 0) {
    DeleteCommand(vPtr);	/* Command already exists, delete old first */
  }
  if (cmdName != NULL) {
    Tcl_DString dString2;
	
    Tcl_DStringInit(&dString2);
    if (cmdName != qualName) {
      if (!ParseObjectName(interp, cmdName, &objName, 0)) {
	goto error;
      }
      cmdName = MakeQualifiedName(&objName, &dString2);
    }
    vPtr->cmdToken = Tcl_CreateObjCommand(interp, (char *)cmdName, Vec_InstCmd,
					  vPtr, VectorInstDeleteProc);
    Tcl_DStringFree(&dString2);
  }
 checkVariable:
  if (varName != NULL) {
    if ((varName[0] == '#') && (strcmp(varName, "#auto") == 0)) {
      varName = qualName;
    }
    if (Vec_MapVariable(interp, vPtr, varName) != TCL_OK) {
      goto error;
    }
  }

  Tcl_DStringFree(&dString);
  *isNewPtr = isNew;
  return vPtr;

 error:
  Tcl_DStringFree(&dString);
  if (vPtr != NULL) {
    Vec_Free(vPtr);
  }
  return NULL;
}

int Blt::Vec_Duplicate(Vector* destPtr, Vector* srcPtr)
{
  size_t nBytes;
  size_t length;

  if (destPtr == srcPtr) {
    /* Copying the same vector. */
  }
  length = srcPtr->last - srcPtr->first + 1;
  if (Vec_ChangeLength(destPtr->interp, destPtr, length) != TCL_OK) {
    return TCL_ERROR;
  }
  nBytes = length * sizeof(double);
  memcpy(destPtr->valueArr, srcPtr->valueArr + srcPtr->first, nBytes);
  destPtr->offset = srcPtr->offset;
  return TCL_OK;
}


static int VectorNamesOp(ClientData clientData, Tcl_Interp* interp,
			 int objc, Tcl_Obj* const objv[])
{
  VectorInterpData* dataPtr = (VectorInterpData*)clientData;
  Tcl_Obj *listObjPtr;

  listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **) NULL);
  if (objc == 2) {
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch cursor;

    for (hPtr = Tcl_FirstHashEntry(&dataPtr->vectorTable, &cursor);
	 hPtr != NULL; hPtr = Tcl_NextHashEntry(&cursor)) {
      char *name = (char*)Tcl_GetHashKey(&dataPtr->vectorTable, hPtr);
      Tcl_ListObjAppendElement(interp, listObjPtr, 
			       Tcl_NewStringObj(name, -1));
    }
  } else {
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch cursor;

    for (hPtr = Tcl_FirstHashEntry(&dataPtr->vectorTable, &cursor);
	 hPtr != NULL; hPtr = Tcl_NextHashEntry(&cursor)) {
      char *name = (char*)Tcl_GetHashKey(&dataPtr->vectorTable, hPtr);
      int i;
      for (i = 2; i < objc; i++) {
	char *pattern;

	pattern = Tcl_GetString(objv[i]);
	if (Tcl_StringMatch(name, pattern)) {
	  Tcl_ListObjAppendElement(interp, listObjPtr, 
				   Tcl_NewStringObj(name, -1));
	  break;
	}
      }
    }
  }
  Tcl_SetObjResult(interp, listObjPtr);
  return TCL_OK;
}

static int VectorCreate2(ClientData clientData, Tcl_Interp* interp,
			 int argStart, int objc, Tcl_Obj* const objv[])
{
  VectorInterpData *dataPtr = (VectorInterpData*)clientData;
  Vector* vPtr;
  int count, i;
  CreateSwitches switches;

  // Handle switches to the vector command and collect the vector name
  // arguments into an array.
  count = 0;
  vPtr = NULL;
  for (i = argStart; i < objc; i++) {
    char *string;

    string = Tcl_GetString(objv[i]);
    if (string[0] == '-') {
      break;
    }
  }
  count = i - argStart;
  if (count == 0) {
    Tcl_AppendResult(interp, "no vector names supplied", (char *)NULL);
    return TCL_ERROR;
  }
  memset(&switches, 0, sizeof(switches));
  if (ParseSwitches(interp, createSwitches, objc - i, objv + i, 
			&switches, BLT_SWITCH_DEFAULTS) < 0) {
    return TCL_ERROR;
  }
  if (count > 1) {
    if (switches.cmdName != NULL) {
      Tcl_AppendResult(interp, 
		       "can't specify more than one vector with \"-command\" switch",
		       (char *)NULL);
      goto error;
    }
    if (switches.varName != NULL) {
      Tcl_AppendResult(interp,
		       "can't specify more than one vector with \"-variable\" switch",
		       (char *)NULL);
      goto error;
    }
  }
  for (i = 0; i < count; i++) {
    char *leftParen, *rightParen;
    char *string;
    int isNew;
    int size, first, last;

    size = first = last = 0;
    string = Tcl_GetString(objv[i + argStart]);
    leftParen = strchr(string, '(');
    rightParen = strchr(string, ')');
    if (((leftParen != NULL) && (rightParen == NULL)) ||
	((leftParen == NULL) && (rightParen != NULL)) ||
	(leftParen > rightParen)) {
      Tcl_AppendResult(interp, "bad vector specification \"", string,
		       "\"", (char *)NULL);
      goto error;
    }
    if (leftParen != NULL) {
      int result;
      char *colon;

      *rightParen = '\0';
      colon = strchr(leftParen + 1, ':');
      if (colon != NULL) {

	/* Specification is in the form vecName(first:last) */
	*colon = '\0';
	result = Tcl_GetInt(interp, leftParen + 1, &first);
	if ((*(colon + 1) != '\0') && (result == TCL_OK)) {
	  result = Tcl_GetInt(interp, colon + 1, &last);
	  if (first > last) {
	    Tcl_AppendResult(interp, "bad vector range \"",
			     string, "\"", (char *)NULL);
	    result = TCL_ERROR;
	  }
	  size = (last - first) + 1;
	}
	*colon = ':';
      } else {
	/* Specification is in the form vecName(size) */
	result = Tcl_GetInt(interp, leftParen + 1, &size);
      }
      *rightParen = ')';
      if (result != TCL_OK) {
	goto error;
      }
      if (size < 0) {
	Tcl_AppendResult(interp, "bad vector size \"", string, "\"",
			 (char *)NULL);
	goto error;
      }
    }
    if (leftParen != NULL) {
      *leftParen = '\0';
    }
    /*
     * By default, we create a TCL command by the name of the vector.
     */
    vPtr = Vec_Create(dataPtr, string,
			  (switches.cmdName == NULL) ? string : switches.cmdName,
			  (switches.varName == NULL) ? string : switches.varName, &isNew);
    if (leftParen != NULL) {
      *leftParen = '(';
    }
    if (vPtr == NULL) {
      goto error;
    }
    vPtr->freeOnUnset = switches.watchUnset;
    vPtr->flush = switches.flush;
    vPtr->offset = first;
    if (size > 0) {
      if (Vec_ChangeLength(interp, vPtr, size) != TCL_OK) {
	goto error;
      }
    }
    if (!isNew) {
      if (vPtr->flush) {
	Vec_FlushCache(vPtr);
      }
      Vec_UpdateClients(vPtr);
    }
  }
  FreeSwitches(createSwitches, (char *)&switches, 0);
  if (vPtr != NULL) {
    /* Return the name of the last vector created  */
    Tcl_SetStringObj(Tcl_GetObjResult(interp), vPtr->name, -1);
  }
  return TCL_OK;
 error:
  FreeSwitches(createSwitches, (char *)&switches, 0);
  return TCL_ERROR;
}

static int VectorCreateOp(ClientData clientData, Tcl_Interp* interp,
			  int objc, Tcl_Obj* const objv[])
{
  return VectorCreate2(clientData, interp, 2, objc, objv);
}

static int VectorDestroyOp(ClientData clientData, Tcl_Interp* interp,
			   int objc,Tcl_Obj* const objv[])
{
  VectorInterpData *dataPtr = (VectorInterpData*)clientData;

  for (int ii=2; ii<objc; ii++) {
    Vector* vPtr;
    if (Vec_LookupName(dataPtr, Tcl_GetString(objv[ii]), &vPtr) != TCL_OK)
      return TCL_ERROR;
    Vec_Free(vPtr);
  }
  return TCL_OK;
}

static int VectorExprOp(ClientData clientData, Tcl_Interp* interp,
			int objc,    Tcl_Obj* const objv[])
{
  return Blt_ExprVector(interp, Tcl_GetString(objv[2]), (Blt_Vector* )NULL);
}

static Blt_OpSpec vectorCmdOps[] =
  {
    {"create", 1, (void*)VectorCreateOp, 3, 0,
     "vecName ?vecName...? ?switches...?",},
    {"destroy", 1, (void*)VectorDestroyOp, 3, 0,
     "vecName ?vecName...?",},
    {"expr", 1, (void*)VectorExprOp, 3, 3, "expression",},
    {"names", 1, (void*)VectorNamesOp, 2, 3, "?pattern?...",},
  };

static int nCmdOps = sizeof(vectorCmdOps) / sizeof(Blt_OpSpec);

int VectorObjCmd(ClientData clientData, Tcl_Interp* interp,
		 int objc, Tcl_Obj* const objv[])
{
  VectorCmdProc *proc;

  if (objc > 1) {
    char *string;
    char c;
    int i;
    Blt_OpSpec *specPtr;

    string = Tcl_GetString(objv[1]);
    c = string[0];
    for (specPtr = vectorCmdOps, i = 0; i < nCmdOps; i++, specPtr++) {
      if ((c == specPtr->name[0]) &&
	  (strcmp(string, specPtr->name) == 0)) {
	goto doOp;
      }
    }
    // The first argument is not an operation, so assume that its
    // actually the name of a vector to be created
    return VectorCreate2(clientData, interp, 1, objc, objv);
  }
 doOp:
  /* Do the usual vector operation lookup now. */
  proc = (VectorCmdProc*)GetOpFromObj(interp, nCmdOps, vectorCmdOps, 
				      BLT_OP_ARG1, objc, objv,0);
  if (proc == NULL) {
    return TCL_ERROR;
  }
  return (*proc) ((Vector*)clientData, interp, objc, objv);
}

static void VectorInterpDeleteProc(ClientData clientData, Tcl_Interp* interp)
{
  VectorInterpData *dataPtr = (VectorInterpData*)clientData;
  Tcl_HashEntry *hPtr;
  Tcl_HashSearch cursor;
    
  for (hPtr = Tcl_FirstHashEntry(&dataPtr->vectorTable, &cursor);
       hPtr != NULL; hPtr = Tcl_NextHashEntry(&cursor)) {
    Vector* vPtr = (Vector*)Tcl_GetHashValue(hPtr);
    vPtr->hashPtr = NULL;
    Vec_Free(vPtr);
  }
  Tcl_DeleteHashTable(&dataPtr->vectorTable);

  /* If any user-defined math functions were installed, remove them.  */
  Vec_UninstallMathFunctions(&dataPtr->mathProcTable);
  Tcl_DeleteHashTable(&dataPtr->mathProcTable);

  Tcl_DeleteHashTable(&dataPtr->indexProcTable);
  Tcl_DeleteAssocData(interp, VECTOR_THREAD_KEY);
  free(dataPtr);
}

VectorInterpData* Blt::Vec_GetInterpData(Tcl_Interp* interp)
{
  VectorInterpData *dataPtr;
  Tcl_InterpDeleteProc *proc;

  dataPtr = (VectorInterpData *)
    Tcl_GetAssocData(interp, VECTOR_THREAD_KEY, &proc);
  if (dataPtr == NULL) {
    dataPtr = (VectorInterpData*)malloc(sizeof(VectorInterpData));
    dataPtr->interp = interp;
    dataPtr->nextId = 0;
    Tcl_SetAssocData(interp, VECTOR_THREAD_KEY, VectorInterpDeleteProc,
		     dataPtr);
    Tcl_InitHashTable(&dataPtr->vectorTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&dataPtr->mathProcTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&dataPtr->indexProcTable, TCL_STRING_KEYS);
    Vec_InstallMathFunctions(&dataPtr->mathProcTable);
    Vec_InstallSpecialIndices(&dataPtr->indexProcTable);
    srand48((long)time((time_t *) NULL));
  }
  return dataPtr;
}

/* C Application interface to vectors */

int Blt_CreateVector2(Tcl_Interp* interp, const char *vecName,
		      const char *cmdName, const char *varName,
		      int initialSize, Blt_Vector* *vecPtrPtr)
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Vector* vPtr;
  int isNew;
  char *nameCopy;

  if (initialSize < 0) {
    Tcl_AppendResult(interp, "bad vector size \"", Itoa(initialSize),
		     "\"", (char *)NULL);
    return TCL_ERROR;
  }
  dataPtr = Vec_GetInterpData(interp);

  nameCopy = Blt_Strdup(vecName);
  vPtr = Vec_Create(dataPtr, nameCopy, cmdName, varName, &isNew);
  free(nameCopy);

  if (vPtr == NULL) {
    return TCL_ERROR;
  }
  if (initialSize > 0) {
    if (Vec_ChangeLength(interp, vPtr, initialSize) != TCL_OK) {
      return TCL_ERROR;
    }
  }
  if (vecPtrPtr != NULL) {
    *vecPtrPtr = (Blt_Vector* ) vPtr;
  }
  return TCL_OK;
}

int Blt_CreateVector(Tcl_Interp* interp, const char *name, int size,
		     Blt_Vector* *vecPtrPtr)
{
  return Blt_CreateVector2(interp, name, name, name, size, vecPtrPtr);
}

int Blt_DeleteVector(Blt_Vector* vecPtr)
{
  Vector* vPtr = (Vector* )vecPtr;

  Vec_Free(vPtr);
  return TCL_OK;
}

int Blt_DeleteVectorByName(Tcl_Interp* interp, const char *name)
{
  // If the vector name was passed via a read-only string (e.g. "x"), the
  // Vec_ParseElement routine will segfault when it tries to write into
  // the string.  Therefore make a writable copy and free it when we're done.
  char* nameCopy = Blt_Strdup(name);
  VectorInterpData *dataPtr = Vec_GetInterpData(interp);
  Vector* vPtr;
  int result = Vec_LookupName(dataPtr, nameCopy, &vPtr);
  free(nameCopy);

  if (result != TCL_OK)
    return TCL_ERROR;

  Vec_Free(vPtr);
  return TCL_OK;
}

int Blt_VectorExists2(Tcl_Interp* interp, const char *vecName)
{
  VectorInterpData *dataPtr;

  dataPtr = Vec_GetInterpData(interp);
  if (GetVectorObject(dataPtr, vecName, NS_SEARCH_BOTH) != NULL) {
    return 1;
  }
  return 0;
}

int Blt_VectorExists(Tcl_Interp* interp, const char *vecName)
{
  char *nameCopy;
  int result;

  /*
   * If the vector name was passed via a read-only string (e.g. "x"), the
   * Blt_VectorParseName routine will segfault when it tries to write into
   * the string.  Therefore make a writable copy and free it when we're
   * done.
   */
  nameCopy = Blt_Strdup(vecName);
  result = Blt_VectorExists2(interp, nameCopy);
  free(nameCopy);
  return result;
}

int Blt_GetVector(Tcl_Interp* interp, const char *name, Blt_Vector* *vecPtrPtr)
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Vector* vPtr;
  char *nameCopy;
  int result;

  dataPtr = Vec_GetInterpData(interp);
  /*
   * If the vector name was passed via a read-only string (e.g. "x"), the
   * Blt_VectorParseName routine will segfault when it tries to write into
   * the string.  Therefore make a writable copy and free it when we're
   * done.
   */
  nameCopy = Blt_Strdup(name);
  result = Vec_LookupName(dataPtr, nameCopy, &vPtr);
  free(nameCopy);
  if (result != TCL_OK) {
    return TCL_ERROR;
  }
  Vec_UpdateRange(vPtr);
  *vecPtrPtr = (Blt_Vector* ) vPtr;
  return TCL_OK;
}

int Blt_GetVectorFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr,
			 Blt_Vector* *vecPtrPtr)
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Vector* vPtr;

  dataPtr = Vec_GetInterpData(interp);
  if (Vec_LookupName(dataPtr, Tcl_GetString(objPtr), &vPtr) != TCL_OK) {
    return TCL_ERROR;
  }
  Vec_UpdateRange(vPtr);
  *vecPtrPtr = (Blt_Vector* ) vPtr;
  return TCL_OK;
}

int Blt_ResetVector(Blt_Vector* vecPtr,	double *valueArr, int length,
		    int size, Tcl_FreeProc *freeProc)
{
  Vector* vPtr = (Vector* )vecPtr;

  if (size < 0) {
    Tcl_AppendResult(vPtr->interp, "bad array size", (char *)NULL);
    return TCL_ERROR;
  }
  return Vec_Reset(vPtr, valueArr, length, size, freeProc);
}

int Blt_ResizeVector(Blt_Vector* vecPtr, int length)
{
  Vector* vPtr = (Vector* )vecPtr;

  if (Vec_ChangeLength((Tcl_Interp *)NULL, vPtr, length) != TCL_OK) {
    Tcl_AppendResult(vPtr->interp, "can't resize vector \"", vPtr->name,
		     "\"", (char *)NULL);
    return TCL_ERROR;
  }
  if (vPtr->flush) {
    Vec_FlushCache(vPtr);
  }
  Vec_UpdateClients(vPtr);
  return TCL_OK;
}

Blt_VectorId Blt_AllocVectorId(Tcl_Interp* interp, const char *name)
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Vector* vPtr;
  VectorClient *clientPtr;
  Blt_VectorId clientId;
  int result;
  char *nameCopy;

  dataPtr = Vec_GetInterpData(interp);
  /*
   * If the vector name was passed via a read-only string (e.g. "x"), the
   * Blt_VectorParseName routine will segfault when it tries to write into
   * the string.  Therefore make a writable copy and free it when we're
   * done.
   */
  nameCopy = Blt_Strdup(name);
  result = Vec_LookupName(dataPtr, nameCopy, &vPtr);
  free(nameCopy);

  if (result != TCL_OK) {
    return (Blt_VectorId) 0;
  }
  /* Allocate a new client structure */
  clientPtr = (VectorClient*)calloc(1, sizeof(VectorClient));
  clientPtr->magic = VECTOR_MAGIC;

  /* Add the new client to the server's list of clients */
  clientPtr->link = vPtr->chain->append(clientPtr);
  clientPtr->serverPtr = vPtr;
  clientId = (Blt_VectorId) clientPtr;
  return clientId;
}

void Blt_SetVectorChangedProc(Blt_VectorId clientId,
			      Blt_VectorChangedProc *proc,
			      ClientData clientData)
{
  VectorClient *clientPtr = (VectorClient *)clientId;

  if (clientPtr->magic != VECTOR_MAGIC) {
    return;			/* Not a valid token */
  }
  clientPtr->clientData = clientData;
  clientPtr->proc = proc;
}

void Blt_FreeVectorId(Blt_VectorId clientId)
{
  VectorClient *clientPtr = (VectorClient *)clientId;

  if (clientPtr->magic != VECTOR_MAGIC)
    return;

  if (clientPtr->serverPtr != NULL) {
    // Remove the client from the server's list
    clientPtr->serverPtr->chain->deleteLink(clientPtr->link);
  }
  free(clientPtr);
}

const char* Blt_NameOfVectorId(Blt_VectorId clientId) 
{
  VectorClient *clientPtr = (VectorClient *)clientId;

  if ((clientPtr->magic != VECTOR_MAGIC) || (clientPtr->serverPtr == NULL)) {
    return NULL;
  }
  return clientPtr->serverPtr->name;
}

const char* Blt_NameOfVector(Blt_Vector* vecPtr) /* Vector to query. */
{
  Vector* vPtr = (Vector* )vecPtr;
  return vPtr->name;
}

int Blt_GetVectorById(Tcl_Interp* interp, Blt_VectorId clientId,
		      Blt_Vector* *vecPtrPtr)
{
  VectorClient *clientPtr = (VectorClient *)clientId;

  if (clientPtr->magic != VECTOR_MAGIC) {
    Tcl_AppendResult(interp, "bad vector token", (char *)NULL);
    return TCL_ERROR;
  }
  if (clientPtr->serverPtr == NULL) {
    Tcl_AppendResult(interp, "vector no longer exists", (char *)NULL);
    return TCL_ERROR;
  }
  Vec_UpdateRange(clientPtr->serverPtr);
  *vecPtrPtr = (Blt_Vector* ) clientPtr->serverPtr;
  return TCL_OK;
}

void Blt_InstallIndexProc(Tcl_Interp* interp, const char *string, 
			  Blt_VectorIndexProc *procPtr) 
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Tcl_HashEntry *hPtr;
  int isNew;

  dataPtr = Vec_GetInterpData(interp);
  hPtr = Tcl_CreateHashEntry(&dataPtr->indexProcTable, string, &isNew);
  if (procPtr == NULL) {
    Tcl_DeleteHashEntry(hPtr);
  } else {
    Tcl_SetHashValue(hPtr, procPtr);
  }
}

#define SWAP(a,b) tempr=(a);(a)=(b);(b)=tempr

/* routine by Brenner
 * data is the array of complex data points, perversely
 * starting at 1
 * nn is the number of complex points, i.e. half the length of data
 * isign is 1 for forward, -1 for inverse
 */
static void four1(double *data, unsigned long nn, int isign)
{
  unsigned long n,mmax,m,j,istep,i;
  double wtemp,wr,wpr,wpi,wi,theta;
  double tempr,tempi;
    
  n=nn << 1;
  j=1;
  for (i = 1;i<n;i+=2) {
    if (j > i) {
      SWAP(data[j],data[i]);
      SWAP(data[j+1],data[i+1]);
    }
    m=n >> 1;
    while (m >= 2 && j > m) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }
  mmax=2;
  while (n > mmax) {
    istep=mmax << 1;
    theta=isign*(6.28318530717959/mmax);
    wtemp=sin(0.5*theta);
    wpr = -2.0*wtemp*wtemp;
    wpi=sin(theta);
    wr=1.0;
    wi=0.0;
    for (m=1;m<mmax;m+=2) {
      for (i=m;i<=n;i+=istep) {
	j=i+mmax;
	tempr=wr*data[j]-wi*data[j+1];
	tempi=wr*data[j+1]+wi*data[j];
	data[j]=data[i]-tempr;
	data[j+1]=data[i+1]-tempi;
	data[i] += tempr;
	data[i+1] += tempi;
      }
      wr=(wtemp=wr)*wpr-wi*wpi+wr;
      wi=wi*wpr+wtemp*wpi+wi;
    }
    mmax=istep;
  }
}
#undef SWAP

static int 
smallest_power_of_2_not_less_than(int x)
{
  int pow2 = 1;

  while (pow2 < x){
    pow2 <<= 1;
  }
  return pow2;
}

int Blt::Vec_FFT(Tcl_Interp* interp, Vector* realPtr, Vector* phasesPtr,
		Vector* freqPtr, double delta, int flags, Vector* srcPtr) 
{
  int length;
  int pow2len;
  double *paddedData;
  int i;
  double Wss = 0.0;
  /* TENTATIVE */
  int middle = 1;
  int noconstant;

  noconstant = (flags & FFT_NO_CONSTANT) ? 1 : 0;

  /* Length of the original vector. */
  length = srcPtr->last - srcPtr->first + 1;
  /* new length */
  pow2len = smallest_power_of_2_not_less_than( length );

  /* We do not do in-place FFTs */
  if (realPtr == srcPtr) {
    Tcl_AppendResult(interp, "real vector \"", realPtr->name, 
		     "\" can't be the same as the source", (char *)NULL);
    return TCL_ERROR;
  }
  if (phasesPtr != NULL) {
    if (phasesPtr == srcPtr) {
      Tcl_AppendResult(interp, "imaginary vector \"", phasesPtr->name, 
		       "\" can't be the same as the source", (char *)NULL);
      return TCL_ERROR;
    }
    if (Vec_ChangeLength(interp, phasesPtr, 
			     pow2len/2-noconstant+middle) != TCL_OK) {
      return TCL_ERROR;
    }
  }
  if (freqPtr != NULL) {
    if (freqPtr == srcPtr) {
      Tcl_AppendResult(interp, "frequency vector \"", freqPtr->name, 
		       "\" can't be the same as the source", (char *)NULL);
      return TCL_ERROR;
    }
    if (Vec_ChangeLength(interp, freqPtr, 
			     pow2len/2-noconstant+middle) != TCL_OK) {
      return TCL_ERROR;
    }
  }

  /* Allocate memory zero-filled array. */
  paddedData = (double*)calloc(pow2len * 2, sizeof(double));
  if (paddedData == NULL) {
    Tcl_AppendResult(interp, "can't allocate memory for padded data",
		     (char *)NULL);
    return TCL_ERROR;
  }
    
  /*
   * Since we just do real transforms, only even locations will be
   * filled with data.
   */
  if (flags & FFT_BARTLETT) {	/* Bartlett window 1 - ( (x - N/2) / (N/2) ) */
    double Nhalf = pow2len*0.5;
    double Nhalf_1 = 1.0 / Nhalf;
    double w;

    for (i = 0; i < length; i++) {
      w = 1.0 - fabs( (i-Nhalf) * Nhalf_1 );
      Wss += w;
      paddedData[2*i] = w * srcPtr->valueArr[i];
    }
    for(/*empty*/; i < pow2len; i++) {
      w = 1.0 - fabs((i-Nhalf) * Nhalf_1);
      Wss += w;
    }
  } else {			/* Squared window, i.e. no data windowing. */
    for (i = 0; i < length; i++) { 
      paddedData[2*i] = srcPtr->valueArr[i]; 
    }
    Wss = pow2len;
  }
    
  /* Fourier */
  four1(paddedData-1, pow2len, 1);
    
  /*
    for(i=0;i<pow2len;i++){
    printf( "(%f %f) ", paddedData[2*i], paddedData[2*i+1] );
    }
  */
    
  /* the spectrum is the modulus of the transforms, scaled by 1/N^2 */
  /* or 1/(N * Wss) for windowed data */
  if (flags & FFT_SPECTRUM) {
    double re, im, reS, imS;
    double factor = 1.0 / (pow2len*Wss);
    double *v = realPtr->valueArr;
	
    for (i = 0 + noconstant; i < pow2len / 2; i++) {
      re = paddedData[2*i];
      im = paddedData[2*i+1];
      reS = paddedData[2*pow2len-2*i-2];
      imS = paddedData[2*pow2len-2*i-1];
      v[i - noconstant] = factor * (
# if 0
				    hypot( paddedData[2*i], paddedData[2*i+1] )
				    + hypot(
					    paddedData[pow2len*2-2*i-2],
					    paddedData[pow2len*2-2*i-1]
					    )
# else
				    sqrt( re*re + im* im ) + sqrt( reS*reS + imS*imS )
# endif
				    );
    }
  } else {
    for(i = 0 + noconstant; i < pow2len / 2 + middle; i++) {
      realPtr->valueArr[i - noconstant] = paddedData[2*i];
    }
  }
  if( phasesPtr != NULL ){
    for (i = 0 + noconstant; i < pow2len / 2 + middle; i++) {
      phasesPtr->valueArr[i-noconstant] = paddedData[2*i+1];
    }
  }
    
  /* Compute frequencies */
  if (freqPtr != NULL) {
    double N = pow2len;
    double denom = 1.0 / N / delta;
    for( i=0+noconstant; i<pow2len/2+middle; i++ ){
      freqPtr->valueArr[i-noconstant] = ((double) i) * denom;
    }
  }
    
  /* Memory is necessarily dynamic, because nobody touched it ! */
  free(paddedData);
    
  realPtr->offset = 0;
  return TCL_OK;
}


int Blt::Vec_InverseFFT(Tcl_Interp* interp, Vector* srcImagPtr, 
		       Vector* destRealPtr, Vector* destImagPtr, Vector* srcPtr)
{
  int length;
  int pow2len;
  double *paddedData;
  int i;
  double oneOverN;

  if ((destRealPtr == srcPtr) || (destImagPtr == srcPtr )){
    /* we do not do in-place FFTs */
    return TCL_ERROR;
  }
  length = srcPtr->last - srcPtr->first + 1;

  /* minus one because of the magical middle element! */
  pow2len = smallest_power_of_2_not_less_than( (length-1)*2 );
  oneOverN = 1.0 / pow2len;

  if (Vec_ChangeLength(interp, destRealPtr, pow2len) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Vec_ChangeLength(interp, destImagPtr, pow2len) != TCL_OK) {
    return TCL_ERROR;
  }

  if( length != (srcImagPtr->last - srcImagPtr->first + 1) ){
    Tcl_AppendResult(srcPtr->interp,
		     "the length of the imagPart vector must ",
		     "be the same as the real one", (char *)NULL);
    return TCL_ERROR;
  }

  paddedData = (double*)malloc( pow2len*2*sizeof(double) );
  if( paddedData == NULL ){
    if (interp != NULL) {
      Tcl_AppendResult(interp, "memory allocation failed", (char *)NULL);
    }
    return TCL_ERROR;
  }
  for(i=0;i<pow2len*2;i++) { paddedData[i] = 0.0; }
  for(i=0;i<length-1;i++){
    paddedData[2*i] = srcPtr->valueArr[i];
    paddedData[2*i+1] = srcImagPtr->valueArr[i];
    paddedData[pow2len*2 - 2*i - 2 ] = srcPtr->valueArr[i+1];
    paddedData[pow2len*2 - 2*i - 1 ] = - srcImagPtr->valueArr[i+1];
  }
  /* mythical middle element */
  paddedData[(length-1)*2] = srcPtr->valueArr[length-1];
  paddedData[(length-1)*2+1] = srcImagPtr->valueArr[length-1];

  /*
    for(i=0;i<pow2len;i++){
    printf( "(%f %f) ", paddedData[2*i], paddedData[2*i+1] );
    }
  */

  /* fourier */
  four1( paddedData-1, pow2len, -1 );

  /* put values in their places, normalising by 1/N */
  for(i=0;i<pow2len;i++){
    destRealPtr->valueArr[i] = paddedData[2*i] * oneOverN;
    destImagPtr->valueArr[i] = paddedData[2*i+1] * oneOverN;
  }

  /* memory is necessarily dynamic, because nobody touched it ! */
  free( paddedData );

  return TCL_OK;
}

static double FindSplit(Point2d *points, int i, int j, int *split)	
{    
  double maxDist2;
    
  maxDist2 = -1.0;
  if ((i + 1) < j) {
    int k;
    double a, b, c;	

    /* 
     * 
     *  dist2 P(k) =  |  1  P(i).x  P(i).y  |
     *		  |  1  P(j).x  P(j).y  |
     *                |  1  P(k).x  P(k).y  |
     *       ------------------------------------------
     *       (P(i).x - P(j).x)^2 + (P(i).y - P(j).y)^2
     */

    a = points[i].y - points[j].y;
    b = points[j].x - points[i].x;
    c = (points[i].x * points[j].y) - (points[i].y * points[j].x);
    for (k = (i + 1); k < j; k++) {
      double dist2;

      dist2 = (points[k].x * a) + (points[k].y * b) + c;
      if (dist2 < 0.0) {
	dist2 = -dist2;	
      }
      if (dist2 > maxDist2) {
	maxDist2 = dist2;	/* Track the maximum. */
	*split = k;
      }
    }
    /* Correction for segment length---should be redone if can == 0 */
    maxDist2 *= maxDist2 / (a * a + b * b);
  } 
  return maxDist2;
}

// Douglas-Peucker line simplification algorithm */
int Blt_SimplifyLine(Point2d *inputPts, int low, int high, double tolerance,
		     int *indices)
{
#define StackPush(a)	s++, stack[s] = (a)
#define StackPop(a)	(a) = stack[s], s--
#define StackEmpty()	(s < 0)
#define StackTop()	stack[s]
  int *stack;
  int split = -1; 
  double dist2, tolerance2;
  int s = -1;			/* Points to top stack item. */
  int count;

  stack = (int*)malloc(sizeof(int) * (high - low + 1));
  StackPush(high);
  count = 0;
  indices[count++] = 0;
  tolerance2 = tolerance * tolerance;
  while (!StackEmpty()) {
    dist2 = FindSplit(inputPts, low, StackTop(), &split);
    if (dist2 > tolerance2) {
      StackPush(split);
    } else {
      indices[count++] = StackTop();
      StackPop(low);
    }
  } 
  free(stack);
  return count;
}

