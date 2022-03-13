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

#ifndef __BltOp_h__
#define __BltOp_h__

#include <tk.h>

#define BLT_OP_BINARY_SEARCH	0
#define BLT_OP_LINEAR_SEARCH	1

namespace Blt {

  typedef struct {
    const char *name;		/* Name of operation */
    int minChars;		/* Minimum # characters to disambiguate */
    void *proc;
    int minArgs;		/* Minimum # args required */
    int maxArgs;		/* Maximum # args required */
    const char *usage;		/* Usage message */
  } Blt_OpSpec;

  typedef enum {
    BLT_OP_ARG0,		/* Op is the first argument. */
    BLT_OP_ARG1,		/* Op is the second argument. */
    BLT_OP_ARG2,		/* Op is the third argument. */
    BLT_OP_ARG3,		/* Op is the fourth argument. */
    BLT_OP_ARG4			/* Op is the fifth argument. */

  } Blt_OpIndex;

  void *GetOpFromObj(Tcl_Interp* interp, int nSpecs, 
		     Blt_OpSpec *specs, int operPos, int objc, 
		     Tcl_Obj* const objv[], int flags);
};

#endif

