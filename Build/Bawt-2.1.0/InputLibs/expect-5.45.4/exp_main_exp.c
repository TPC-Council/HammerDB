/* main.c - main() and some logging routines for expect

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

/* Don't use stubs since we are in the main application. */
#undef USE_TCL_STUBS

#include "expect_cf.h"
#include <stdio.h>
#include "tcl.h"
#include "expect_tcl.h"
#include <stdlib.h>

int
main(argc, argv)
int argc;
char *argv[];
{
	int rc = 0;
	char buffer [30];

	Tcl_Interp *interp = Tcl_CreateInterp();
	Tcl_FindExecutable(argv[0]);

	if (Tcl_Init(interp) == TCL_ERROR) {
	    fprintf(stderr,"Tcl_Init failed: %s\n",Tcl_GetStringResult (interp));
	    (void) exit(1);
	}

	if (Expect_Init(interp) == TCL_ERROR) {
	    fprintf(stderr,"Expect_Init failed: %s\n",Tcl_GetStringResult (interp));
	    (void) exit(1);
	}

	exp_parse_argv(interp,argc,argv);

	/* become interactive if requested or "nothing to do" */
	if (exp_interactive)
		(void) exp_interpreter(interp,(Tcl_Obj *)0);
	else if (exp_cmdfile)
		rc = exp_interpret_cmdfile(interp,exp_cmdfile);
	else if (exp_cmdfilename)
		rc = exp_interpret_cmdfilename(interp,exp_cmdfilename);

	/* assert(exp_cmdlinecmds != 0) */

	/* SF #439042 -- Allow overide of "exit" by user / script
	 */

	sprintf(buffer, "exit %d", rc);
	Tcl_Eval(interp, buffer); 
	/*NOTREACHED*/
	return 0;		/* Needed only to prevent compiler warning. */
}

