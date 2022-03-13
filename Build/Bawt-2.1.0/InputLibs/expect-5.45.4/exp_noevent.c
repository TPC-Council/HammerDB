/* interact (with only one process) - give user keyboard control

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

/* This file exists for deficient versions of UNIX that lack select,
poll, or some other multiplexing hook.  Instead, this code uses two
processes per spawned process.  One sends characters from the spawnee
to the spawner; a second send chars the other way.

This will work on any UNIX system.  The only sacrifice is that it
doesn't support multiple processes.  Eventually, it should catch
SIGCHLD on dead processes and do the right thing.  But it is pretty
gruesome to imagine so many processes to do all this.  If you change
it successfully, please mail back the changes to me.  - Don
*/

#include "expect_cf.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/time.h>

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#include "tcl.h"
#include "exp_prog.h"
#include "exp_command.h"	/* for struct ExpState defs */
#include "exp_event.h"

/*ARGSUSED*/
void
exp_arm_background_filehandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_disarm_background_filehandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_disarm_background_filehandler_force(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_unblock_background_filehandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_block_background_filehandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_event_disarm(fd)
int fd;
{
}

/* returns status, one of EOF, TIMEOUT, ERROR or DATA */
/*ARGSUSED*/
int
exp_get_next_event(interp,esPtrs, n,esPtrOut,timeout,key)
Tcl_Interp *interp;
ExpState (*esPtrs)[];
int n;			/* # of esPtrs */
ExpState **esPtrOut;	/* 1st event master, not set if none */
int timeout;		/* seconds */
int key;
{
    if (n > 1) {
	exp_error(interp,"expect not compiled with multiprocess support");
	/* select a different INTERACT_TYPE in Makefile */
	return(TCL_ERROR);
    }

    esPtr = *esPtrOut = esPtrs[0];

    if (esPtr->key != key) {
	esPtr->key = key;
	esPtr->force_read = FALSE;
	return(EXP_DATA_OLD);
    } else if ((!esPtr->force_read) && (esPtr->size != 0)) {
	return(EXP_DATA_OLD);
    }

    return(EXP_DATA_NEW);
}

/*ARGSUSED*/
int
exp_get_next_event_info(interp,esPtr,ready_mask)
Tcl_Interp *interp;
ExpState *esPtr;
int ready_mask;
{
}

/* There is no portable way to do sub-second sleeps on such a system, so */
/* do the next best thing (without a busy loop) and fake it: sleep the right */
/* amount of time over the long run.  Note that while "subtotal" isn't */
/* reinitialized, it really doesn't matter for such a gross hack as random */
/* scheduling pauses will easily introduce occasional one second delays. */
int	/* returns TCL_XXX */
exp_dsleep(interp,sec)
Tcl_Interp *interp;
double sec;
{
	static double subtotal = 0;
	int seconds;

	subtotal += sec;
	if (subtotal < 1) return TCL_OK;
	seconds = subtotal;
	subtotal -= seconds;
 restart:
	if (Tcl_AsyncReady()) {
		int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		if (rc != TCL_OK) return(rc);
	}
	sleep(seconds);
	return TCL_OK;
}

#if 0
/* There is no portable way to do sub-second sleeps on such a system, so */
/* do the next best thing (without a busy loop) and fake it: sleep the right */
/* amount of time over the long run.  Note that while "subtotal" isn't */
/* reinitialized, it really doesn't matter for such a gross hack as random */
/* scheduling pauses will easily introduce occasional one second delays. */
int	/* returns TCL_XXX */
exp_usleep(interp,usec)
Tcl_Interp *interp;
long usec;		/* microseconds */
{
	static subtotal = 0;
	int seconds;

	subtotal += usec;
	if (subtotal < 1000000) return TCL_OK;
	seconds = subtotal/1000000;
	subtotal = subtotal%1000000;
 restart:
	if (Tcl_AsyncReady()) {
		int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		if (rc != TCL_OK) return(exp_tcl2_returnvalue(rc));
	}
	sleep(seconds);
	return TCL_OK;
}
#endif /*0*/

/* set things up for later calls to event handler */
void
exp_init_event()
{
	exp_event_exit = 0;
}
