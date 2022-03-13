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

#include "tkbltOp.h"

using namespace Blt;

static int BinaryOpSearch(Blt_OpSpec *specs, int nSpecs, const char *string,
			  int length)
{
  int low = 0;
  int high = nSpecs - 1;
  char c = string[0];
  while (low <= high) {
    int median = (low + high) >> 1;
    Blt_OpSpec *specPtr = specs + median;

    /* Test the first character */
    int compare = c - specPtr->name[0];
    if (compare == 0) {
      /* Now test the entire string */
      compare = strncmp(string, specPtr->name, length);
      if (compare == 0) {
	if ((int)length < specPtr->minChars) {
	  return -2;	/* Ambiguous operation name */
	}
      }
    }
    if (compare < 0) {
      high = median - 1;
    } else if (compare > 0) {
      low = median + 1;
    } else {
      return median;		/* Op found. */
    }
  }
  return -1;				/* Can't find operation */
}

static int LinearOpSearch(Blt_OpSpec *specs, int nSpecs, const char *string,
			  int length)
{
  char c = string[0];
  int nMatches = 0;
  int last = -1;
  int i =0;
  for (Blt_OpSpec *specPtr = specs; i<nSpecs; i++, specPtr++) {
    if ((c == specPtr->name[0]) && 
	(strncmp(string, specPtr->name, length) == 0)) {
      last = i;
      nMatches++;
      if ((int)length == specPtr->minChars) {
	break;
      }
    }
  }
  if (nMatches > 1)
    return -2;			/* Ambiguous operation name */

  if (nMatches == 0)
    return -1;			/* Can't find operation */

  return last;			/* Op found. */
}

void* Blt::GetOpFromObj(Tcl_Interp* interp, int nSpecs, Blt_OpSpec *specs,
		       int operPos, int objc, Tcl_Obj* const objv[],
		       int flags)
{
  Blt_OpSpec *specPtr;
  int n;

  if (objc <= operPos) {		/* No operation argument */
    Tcl_AppendResult(interp, "wrong # args: ", (char *)NULL);
  usage:
    Tcl_AppendResult(interp, "should be one of...", (char *)NULL);
    for (n = 0; n < nSpecs; n++) {
      Tcl_AppendResult(interp, "\n  ", (char *)NULL);
      for (int ii = 0; ii < operPos; ii++) {
	Tcl_AppendResult(interp, Tcl_GetString(objv[ii]), " ", 
			 (char *)NULL);
      }
      specPtr = specs + n;
      Tcl_AppendResult(interp, specPtr->name, " ", specPtr->usage,
		       (char *)NULL);
    }
    return NULL;
  }

  int length;
  const char* string = Tcl_GetStringFromObj(objv[operPos], &length);
  if (flags & BLT_OP_LINEAR_SEARCH)
    n = LinearOpSearch(specs, nSpecs, string, length);
  else
    n = BinaryOpSearch(specs, nSpecs, string, length);

  if (n == -2) {
    char c;

    Tcl_AppendResult(interp, "ambiguous", (char *)NULL);
    if (operPos > 2) {
      Tcl_AppendResult(interp, " ", Tcl_GetString(objv[operPos - 1]), 
		       (char *)NULL);
    }
    Tcl_AppendResult(interp, " operation \"", string, "\" matches: ",
		     (char *)NULL);

    c = string[0];
    for (n = 0; n < nSpecs; n++) {
      specPtr = specs + n;
      if ((c == specPtr->name[0]) &&
	  (strncmp(string, specPtr->name, length) == 0)) {
	Tcl_AppendResult(interp, " ", specPtr->name, (char *)NULL);
      }
    }
    return NULL;

  } else if (n == -1) {	      /* Can't find operation, display help */
    Tcl_AppendResult(interp, "bad", (char *)NULL);
    if (operPos > 2) {
      Tcl_AppendResult(interp, " ", Tcl_GetString(objv[operPos - 1]), 
		       (char *)NULL);
    }
    Tcl_AppendResult(interp, " operation \"", string, "\": ", (char *)NULL);
    goto usage;
  }
  specPtr = specs + n;
  if ((objc < specPtr->minArgs) || 
      ((specPtr->maxArgs > 0) && (objc > specPtr->maxArgs))) {
    int i;

    Tcl_AppendResult(interp, "wrong # args: should be \"", (char *)NULL);
    for (i = 0; i < operPos; i++) {
      Tcl_AppendResult(interp, Tcl_GetString(objv[i]), " ", 
		       (char *)NULL);
    }
    Tcl_AppendResult(interp, specPtr->name, " ", specPtr->usage, "\"",
		     (char *)NULL);
    return NULL;
  }
  return specPtr->proc;
}

