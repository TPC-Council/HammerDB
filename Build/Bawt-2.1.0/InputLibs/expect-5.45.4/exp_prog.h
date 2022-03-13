/* exp_prog.h - private symbols common to both expect program and library

Written by: Don Libes, libes@cme.nist.gov, NIST, 12/3/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#ifndef _EXPECT_PROG_H
#define _EXPECT_PROG_H

#include "expect_tcl.h"
#include "exp_int.h"

/* yes, I have a weak mind */
#define streq(x,y)	(0 == strcmp((x),(y)))

/* Constant strings for NewStringObj */
#define LITERAL(s) Tcl_NewStringObj ((s), sizeof(s)-1)

#endif /* _EXPECT_PROG_H */
