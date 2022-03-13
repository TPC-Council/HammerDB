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

#include <string.h>
#include <stdlib.h>

#include <iostream>
#include <sstream>
#include <iomanip>
using namespace std;

#include <tcl.h>

#include "tkbltSwitch.h"

using namespace Blt;

#define COUNT_NNEG		0
#define COUNT_POS		1
#define COUNT_ANY		2

static char* Blt_Strdup(const char *string)
{
  size_t size = strlen(string) + 1;
  char* ptr = (char*)malloc(size * sizeof(char));
  if (ptr != NULL) {
    strcpy(ptr, string);
  }
  return ptr;
}

static int Blt_GetCountFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr, int check,
			       long *valuePtr)
{
  long count;
  if (Tcl_GetLongFromObj(interp, objPtr, &count) != TCL_OK)
    return TCL_ERROR;

  switch (check) {
  case COUNT_NNEG:
    if (count < 0) {
      Tcl_AppendResult(interp, "bad value \"", Tcl_GetString(objPtr), 
		       "\": can't be negative", (char *)NULL);
      return TCL_ERROR;
    }
    break;
  case COUNT_POS:
    if (count <= 0) {
      Tcl_AppendResult(interp, "bad value \"", Tcl_GetString(objPtr), 
		       "\": must be positive", (char *)NULL);
      return TCL_ERROR;
    }
    break;
  case COUNT_ANY:
    break;
  }
  *valuePtr = count;
  return TCL_OK;
}

static void DoHelp(Tcl_Interp* interp, Blt_SwitchSpec *specs)
{
  Tcl_DString ds;
  Tcl_DStringInit(&ds);
  Tcl_DStringAppend(&ds, "following switches are available:", -1);
  for (Blt_SwitchSpec *sp = specs; sp->type != BLT_SWITCH_END; sp++) {
    Tcl_DStringAppend(&ds, "\n    ", 4);
    Tcl_DStringAppend(&ds, sp->switchName, -1);
    Tcl_DStringAppend(&ds, " ", 1);
    Tcl_DStringAppend(&ds, sp->help, -1);
  }
  Tcl_AppendResult(interp, Tcl_DStringValue(&ds), (char *)NULL);
  Tcl_DStringFree(&ds);
}

static Blt_SwitchSpec *FindSwitchSpec(Tcl_Interp* interp, Blt_SwitchSpec *specs,
				      const char *name, int length,
				      int needFlags, int hateFlags)
{
  char c = name[1];
  Blt_SwitchSpec *matchPtr = NULL;
  for (Blt_SwitchSpec *sp = specs; sp->type != BLT_SWITCH_END; sp++) {
    if (sp->switchName == NULL)
      continue;

    if (((sp->flags & needFlags) != needFlags) || (sp->flags & hateFlags))
      continue;

    if ((sp->switchName[1] != c) || (strncmp(sp->switchName,name,length)!=0))
      continue;

    if (sp->switchName[length] == '\0')
      return sp;		/* Stop on a perfect match. */

    if (matchPtr != NULL) {
      Tcl_AppendResult(interp, "ambiguous switch \"", name, "\"\n", 
		       (char *) NULL);
      DoHelp(interp, specs);
      return NULL;
    }
    matchPtr = sp;
  }

  if (strcmp(name, "-help") == 0) {
    DoHelp(interp, specs);
    return NULL;
  }

  if (matchPtr == NULL) {
    Tcl_AppendResult(interp, "unknown switch \"", name, "\"\n", 
		     (char *)NULL);
    DoHelp(interp, specs);
    return NULL;
  }

  return matchPtr;
}

static int DoSwitch(Tcl_Interp* interp, Blt_SwitchSpec *sp,
		    Tcl_Obj *objPtr, void *record)
{
  do {
    char *ptr = (char *)record + sp->offset;
    switch (sp->type) {
    case BLT_SWITCH_BOOLEAN:
      {
	int boo;

	if (Tcl_GetBooleanFromObj(interp, objPtr, &boo) != TCL_OK) {
	  return TCL_ERROR;
	}
	if (sp->mask > 0) {
	  if (boo) {
	    *((int *)ptr) |= sp->mask;
	  } else {
	    *((int *)ptr) &= ~sp->mask;
	  }
	} else {
	  *((int *)ptr) = boo;
	}
      }
      break;

    case BLT_SWITCH_DOUBLE:
      if (Tcl_GetDoubleFromObj(interp, objPtr, (double *)ptr) != TCL_OK) {
	return TCL_ERROR;
      }
      break;

    case BLT_SWITCH_OBJ:
      Tcl_IncrRefCount(objPtr);
      *(Tcl_Obj **)ptr = objPtr;
      break;

    case BLT_SWITCH_FLOAT:
      {
	double value;

	if (Tcl_GetDoubleFromObj(interp, objPtr, &value) != TCL_OK) {
	  return TCL_ERROR;
	}
	*(float *)ptr = (float)value;
      }
      break;

    case BLT_SWITCH_INT:
      if (Tcl_GetIntFromObj(interp, objPtr, (int *)ptr) != TCL_OK) {
	return TCL_ERROR;
      }
      break;

    case BLT_SWITCH_INT_NNEG:
      {
	long value;
		
	if (Blt_GetCountFromObj(interp, objPtr, COUNT_NNEG, 
				&value) != TCL_OK) {
	  return TCL_ERROR;
	}
	*(int *)ptr = (int)value;
      }
      break;

    case BLT_SWITCH_INT_POS:
      {
	long value;
		
	if (Blt_GetCountFromObj(interp, objPtr, COUNT_POS, 
				&value) != TCL_OK) {
	  return TCL_ERROR;
	}
	*(int *)ptr = (int)value;
      }
      break;

    case BLT_SWITCH_LIST:
      {
	int argc;

	if (Tcl_SplitList(interp, Tcl_GetString(objPtr), &argc, 
			  (const char ***)ptr) != TCL_OK) {
	  return TCL_ERROR;
	}
      }
      break;

    case BLT_SWITCH_LONG:
      if (Tcl_GetLongFromObj(interp, objPtr, (long *)ptr) != TCL_OK) {
	return TCL_ERROR;
      }
      break;

    case BLT_SWITCH_LONG_NNEG:
      {
	long value;
		
	if (Blt_GetCountFromObj(interp, objPtr, COUNT_NNEG, 
				&value) != TCL_OK) {
	  return TCL_ERROR;
	}
	*(long *)ptr = value;
      }
      break;

    case BLT_SWITCH_LONG_POS:
      {
	long value;
		
	if (Blt_GetCountFromObj(interp, objPtr, COUNT_POS, &value)
	    != TCL_OK) {
	  return TCL_ERROR;
	}
	*(long *)ptr = value;
      }
      break;

    case BLT_SWITCH_STRING: 
      {
	char *value;
		
	value = Tcl_GetString(objPtr);
	value =  (*value == '\0') ?  NULL : Blt_Strdup(value);
	if (*(char **)ptr != NULL) {
	  free(*(char **)ptr);
	}
	*(char **)ptr = value;
      }
      break;

    case BLT_SWITCH_CUSTOM:
      if ((*sp->customPtr->parseProc)(sp->customPtr->clientData, interp,
				      sp->switchName, objPtr, (char *)record, sp->offset, sp->flags) 
	  != TCL_OK) {
	return TCL_ERROR;
      }
      break;

    default: 
      ostringstream str;
      str << sp->type << ends;
      Tcl_AppendResult(interp, "bad switch table: unknown type \"",
		       str.str().c_str(), "\"", NULL);
      return TCL_ERROR;
    }
    sp++;
  } while ((sp->switchName == NULL) && (sp->type != BLT_SWITCH_END));
  return TCL_OK;
}

int Blt::ParseSwitches(Tcl_Interp* interp, Blt_SwitchSpec *specs,
		      int objc, Tcl_Obj* const objv[], void *record,
		      int flags)
{
  Blt_SwitchSpec *sp;
  int needFlags = flags & ~(BLT_SWITCH_USER_BIT - 1);
  int hateFlags = 0;

  /*
   * Pass 1:  Clear the change flags on all the specs so that we 
   *          can check it later.
   */
  for (sp = specs; sp->type != BLT_SWITCH_END; sp++)
    sp->flags &= ~BLT_SWITCH_SPECIFIED;

  /*
   * Pass 2:  Process the arguments that match entries in the specs.
   *		It's an error if the argument doesn't match anything.
   */
  int count;
  for (count = 0; count < objc; count++) {
    char *arg;
    int length;

    arg = Tcl_GetStringFromObj(objv[count], &length);
    if (flags & BLT_SWITCH_OBJV_PARTIAL) {
      /* 
       * If the argument doesn't start with a '-' (not a switch) or is
       * '--', stop processing and return the number of arguments
       * comsumed.
       */
      if (arg[0] != '-') {
	return count;
      }
      if ((arg[1] == '-') && (arg[2] == '\0')) {
	return count + 1; /* include the "--" in the count. */
      }
    }
    sp = FindSwitchSpec(interp, specs, arg, length, needFlags, hateFlags);
    if (sp == NULL) {
      return -1;
    }
    if (sp->type == BLT_SWITCH_BITMASK) {
      char *ptr;

      ptr = (char *)record + sp->offset;
      *((int *)ptr) |= sp->mask;
    } else if (sp->type == BLT_SWITCH_BITMASK_INVERT) {
      char *ptr;
	    
      ptr = (char *)record + sp->offset;
      *((int *)ptr) &= ~sp->mask;
    } else if (sp->type == BLT_SWITCH_VALUE) {
      char *ptr;
	    
      ptr = (char *)record + sp->offset;
      *((int *)ptr) = sp->mask;
    } else {
      count++;
      if (count == objc) {
	Tcl_AppendResult(interp, "value for \"", arg, "\" missing", 
			 (char *) NULL);
	return -1;
      }
      if (DoSwitch(interp, sp, objv[count], record) != TCL_OK) {
	ostringstream str;
	str << "\n    (processing \"" << sp->switchName << "\" switch)" << ends;
	Tcl_AddErrorInfo(interp, str.str().c_str());
	return -1;
      }
    }
    sp->flags |= BLT_SWITCH_SPECIFIED;
  }

  return count;
}

void Blt::FreeSwitches(Blt_SwitchSpec *specs, void *record, int needFlags)
{
  for (Blt_SwitchSpec *sp = specs; sp->type != BLT_SWITCH_END; sp++) {
    if ((sp->flags & needFlags) == needFlags) {
      char *ptr = (char *)record + sp->offset;
      switch (sp->type) {
      case BLT_SWITCH_STRING:
      case BLT_SWITCH_LIST:
	if (*((char **) ptr) != NULL) {
	  free(*((char **) ptr));
	  *((char **) ptr) = NULL;
	}
	break;

      case BLT_SWITCH_OBJ:
	if (*((Tcl_Obj **) ptr) != NULL) {
	  Tcl_DecrRefCount(*((Tcl_Obj **)ptr));
	  *((Tcl_Obj **) ptr) = NULL;
	}
	break;

      case BLT_SWITCH_CUSTOM:
	if ((*(char **)ptr != NULL) && 
	    (sp->customPtr->freeProc != NULL)) {
	  (*sp->customPtr->freeProc)((char *)record, sp->offset, 
				     sp->flags);
	}
	break;

      default:
	break;
      }
    }
  }
}
