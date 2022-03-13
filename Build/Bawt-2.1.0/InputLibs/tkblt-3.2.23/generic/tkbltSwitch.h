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

#ifndef BLT_SWITCH_H
#define BLT_SWITCH_H

#include <stddef.h>

#define BLT_SWITCH_DEFAULTS		(0)
#define BLT_SWITCH_ARGV_PARTIAL		(1<<1)
#define BLT_SWITCH_OBJV_PARTIAL		(1<<1)

  /*
   * Possible flag values for Blt_SwitchSpec structures.  Any bits at or
   * above BLT_SWITCH_USER_BIT may be used by clients for selecting
   * certain entries.
   */
#define BLT_SWITCH_NULL_OK		(1<<0)
#define BLT_SWITCH_DONT_SET_DEFAULT	(1<<3)
#define BLT_SWITCH_SPECIFIED		(1<<4)
#define BLT_SWITCH_USER_BIT		(1<<8)

namespace Blt {

  typedef int (Blt_SwitchParseProc)(ClientData clientData, Tcl_Interp* interp, 
				    const char *switchName, 
				    Tcl_Obj *valueObjPtr, char *record, 
				    int offset, int flags);
  typedef void (Blt_SwitchFreeProc)(char *record, int offset, int flags);

  typedef struct {
    Blt_SwitchParseProc *parseProc; /* Procedure to parse a switch
				     * value and store it in its *
				     * converted form in the data *
				     * record. */

    Blt_SwitchFreeProc *freeProc; /* Procedure to free a switch. */

    ClientData clientData;	/* Arbitrary one-word value used by
				 * switch parser, passed to
				 * parseProc. */
  } Blt_SwitchCustom;

  /*
   * Type values for Blt_SwitchSpec structures.  See the user
   * documentation for details.
   */
  typedef enum {
    BLT_SWITCH_BOOLEAN, 
    BLT_SWITCH_DOUBLE, 
    BLT_SWITCH_BITMASK, 
    BLT_SWITCH_BITMASK_INVERT, 
    BLT_SWITCH_FLOAT, 
    BLT_SWITCH_INT, 
    BLT_SWITCH_INT_NNEG, 
    BLT_SWITCH_INT_POS,
    BLT_SWITCH_LIST, 
    BLT_SWITCH_LONG, 
    BLT_SWITCH_LONG_NNEG, 
    BLT_SWITCH_LONG_POS,
    BLT_SWITCH_OBJ,
    BLT_SWITCH_STRING, 
    BLT_SWITCH_VALUE, 
    BLT_SWITCH_CUSTOM, 
    BLT_SWITCH_END
  } Blt_SwitchTypes;

  typedef struct {
    Blt_SwitchTypes type;	/* Type of option, such as
				 * BLT_SWITCH_COLOR; see definitions
				 * below.  Last option in table must
				 * have type BLT_SWITCH_END. */

    const char *switchName;	/* Switch used to specify option in
				 * argv.  NULL means this spec is part
				 * of a group. */

    const char *help;		/* Help string. */
    int offset;			/* Where in widget record to store
				 * value; use Blt_Offset macro to
				 * generate values for this. */

    int flags;			/* Any combination of the values
				 * defined below. */

    unsigned int mask;

    Blt_SwitchCustom *customPtr; /* If type is BLT_SWITCH_CUSTOM then
				  * this is a pointer to info about how
				  * to parse and print the option.
				  * Otherwise it is irrelevant. */
  } Blt_SwitchSpec;

  extern int ParseSwitches(Tcl_Interp* interp, Blt_SwitchSpec *specPtr, 
			       int objc, Tcl_Obj *const *objv, void *rec,
			       int flags);
  extern void FreeSwitches(Blt_SwitchSpec *specs, void *rec, int flags);
};

#endif /* BLT_SWITCH_H */
