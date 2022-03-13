/* 
 * tclUnixNotify.c --
 *
 *	This file contains Unix-specific procedures for the notifier,
 *	which is the lowest-level part of the Tcl event loop.  This file
 *	works together with ../generic/tclNotify.c.
 *
 * Copyright (c) 1995 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

static char sccsid[] = "@(#) tclUnixNotify.c 1.27 96/01/19 10:30:23";

#include "tclInt.h"
#include "tclPort.h"
#include <signal.h> 

/*
 * The information below is used to provide read, write, and
 * exception masks to select during calls to Tcl_DoOneEvent.
 */

static fd_mask checkMasks[3*MASK_SIZE];
				/* This array is used to build up the masks
				 * to be used in the next call to select.
				 * Bits are set in response to calls to
				 * Tcl_WatchFile. */
static fd_mask readyMasks[3*MASK_SIZE];
				/* This array reflects the readable/writable
				 * conditions that were found to exist by the
				 * last call to select. */
static int numFdBits;		/* Number of valid bits in checkMasks
				 * (one more than highest fd for which
				 * Tcl_WatchFile has been called). */

/*
 *----------------------------------------------------------------------
 *
 * Tcl_WatchFile --
 *
 *	Arrange for Tcl_DoOneEvent to include this file in the masks
 *	for the next call to select.  This procedure is invoked by
 *	event sources, which are in turn invoked by Tcl_DoOneEvent
 *	before it invokes select.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	
 *	The notifier will generate a file event when the I/O channel
 *	given by fd next becomes ready in the way indicated by mask.
 *	If fd is already registered then the old mask will be replaced
 *	with the new one.  Once the event is sent, the notifier will
 *	not send any more events about the fd until the next call to
 *	Tcl_NotifyFile. 
 *
 *----------------------------------------------------------------------
 */

void
Tcl_WatchFile(file, mask)
    Tcl_File file;	/* Generic file handle for a stream. */
    int mask;			/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, and TCL_EXCEPTION:
				 * indicates conditions to wait for
				 * in select. */
{
    int fd, type, index;
    fd_mask bit;

    fd = (int) Tcl_GetFileInfo(file, &type);

    if (type != TCL_UNIX_FD) {
	panic("Tcl_WatchFile: unexpected file type");
    }

    if (fd >= FD_SETSIZE) {
	panic("Tcl_WatchFile can't handle file id %d", fd);
    }

    index = fd/(NBBY*sizeof(fd_mask));
    bit = 1 << (fd%(NBBY*sizeof(fd_mask)));
    if (mask & TCL_READABLE) {
	checkMasks[index] |= bit;
    }
    if (mask & TCL_WRITABLE) {
	(checkMasks+MASK_SIZE)[index] |= bit;
    }
    if (mask & TCL_EXCEPTION) {
	(checkMasks+2*(MASK_SIZE))[index] |= bit;
    }
    if (numFdBits <= fd) {
	numFdBits = fd+1;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_FileReady --
 *
 *	Indicates what conditions (readable, writable, etc.) were
 *	present on a file the last time the notifier invoked select.
 *	This procedure is typically invoked by event sources to see
 *	if they should queue events.
 *
 * Results:
 *	The return value is 0 if none of the conditions specified by mask
 *	was true for fd the last time the system checked.  If any of the
 *	conditions were true, then the return value is a mask of those
 *	that were true.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_FileReady(file, mask)
    Tcl_File file;	/* Generic file handle for a stream. */
    int mask;			/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, and TCL_EXCEPTION:
				 * indicates conditions caller cares about. */
{
    int index, result, type, fd;
    fd_mask bit;

    fd = (int) Tcl_GetFileInfo(file, &type);
    if (type != TCL_UNIX_FD) {
	panic("Tcl_FileReady: unexpected file type");
    }

    index = fd/(NBBY*sizeof(fd_mask));
    bit = 1 << (fd%(NBBY*sizeof(fd_mask)));
    result = 0;
    if ((mask & TCL_READABLE) && (readyMasks[index] & bit)) {
	result |= TCL_READABLE;
    }
    if ((mask & TCL_WRITABLE) && ((readyMasks+MASK_SIZE)[index] & bit)) {
	result |= TCL_WRITABLE;
    }
    if ((mask & TCL_EXCEPTION) && ((readyMasks+(2*MASK_SIZE))[index] & bit)) {
	result |= TCL_EXCEPTION;
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_WaitForEvent --
 *
 *	This procedure does the lowest level wait for events in a
 *	platform-specific manner.  It uses information provided by
 *	previous calls to Tcl_WatchFile, plus the timePtr argument,
 *	to determine what to wait for and how long to wait.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May put the process to sleep for a while, depending on timePtr.
 *	When this procedure returns, an event of interest to the application
 *	has probably, but not necessarily, occurred.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_WaitForEvent(timePtr)
    Tcl_Time *timePtr;		/* Specifies the maximum amount of time
				 * that this procedure should block before
				 * returning.  The time is given as an
				 * interval, not an absolute wakeup time.
				 * NULL means block forever. */
{
    struct timeval timeout, *timeoutPtr;
    int numFound;

    memcpy((VOID *) readyMasks, (VOID *) checkMasks,
	    3*MASK_SIZE*sizeof(fd_mask));
    if (timePtr == NULL) {
	timeoutPtr = NULL;
    } else {
	timeoutPtr = &timeout;
	timeout.tv_sec = timePtr->sec;
	timeout.tv_usec = timePtr->usec;
    }
    numFound = select(numFdBits, (SELECT_MASK *) &readyMasks[0],
	    (SELECT_MASK *) &readyMasks[MASK_SIZE],
	    (SELECT_MASK *) &readyMasks[2*MASK_SIZE], timeoutPtr);

    /*
     * Some systems don't clear the masks after an error, so
     * we have to do it here.
     */

    if (numFound == -1) {
	memset((VOID *) readyMasks, 0, 3*MASK_SIZE*sizeof(fd_mask));
    }

    /*
     * Reset the check masks in preparation for the next call to
     * select.
     */

    numFdBits = 0;
    memset((VOID *) checkMasks, 0, 3*MASK_SIZE*sizeof(fd_mask));
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_Sleep --
 *
 *	Delay execution for the specified number of milliseconds.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Time passes.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_Sleep(ms)
    int ms;			/* Number of milliseconds to sleep. */
{
    static struct timeval delay;
    Tcl_Time before, after;

    /*
     * The only trick here is that select appears to return early
     * under some conditions, so we have to check to make sure that
     * the right amount of time really has elapsed.  If it's too
     * early, go back to sleep again.
     */

    TclGetTime(&before);
    after = before;
    after.sec += ms/1000;
    after.usec += (ms%1000)*1000;
    if (after.usec > 1000000) {
	after.usec -= 1000000;
	after.sec += 1;
    }
    while (1) {
	delay.tv_sec = after.sec - before.sec;
	delay.tv_usec = after.usec - before.usec;
	if (delay.tv_usec < 0) {
	    delay.tv_usec += 1000000;
	    delay.tv_sec -= 1;
	}

	/*
	 * Special note:  must convert delay.tv_sec to int before comparing
	 * to zero, since delay.tv_usec is unsigned on some platforms.
	 */

	if ((((int) delay.tv_sec) < 0)
		|| ((delay.tv_usec == 0) && (delay.tv_sec == 0))) {
	    break;
	}
	(void) select(0, (SELECT_MASK *) 0, (SELECT_MASK *) 0,
		(SELECT_MASK *) 0, &delay);
	TclGetTime(&before);
    }
}







#if 0 /* WHOLE FILE */



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
exp_arm_background_channelhandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_disarm_background_channelhandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_disarm_background_channelhandler_force(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_unblock_background_channelhandler(esPtr)
ExpState *esPtr;
{
}

/*ARGSUSED*/
void
exp_block_background_channelhandler(esPtr)
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
    ExpState *esPtr;

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

#endif /* WHOLE FILE! */
