/* exp_poll.c - This file contains UNIX specific procedures for
 * poll-based notifier, which is the lowest-level part of the Tcl
 * event loop.  This file works together with ../generic/tclNotify.c.
 *
 * Design and implementation of this program was paid for by U.S. tax
 * dollars.  Therefore it is public domain.  However, the author and
 * NIST would appreciate credit if this program or parts of it are
 * used.
 *
 * Written by Don Libes, NIST, 2/6/90
 * Rewritten by Don Libes, 2/96 for new Tcl notifier paradigm.
 * Rewritten again by Don Libes, 8/97 for yet another Tcl notifier paradigm.
 */

#include "tclInt.h"
#include "tclPort.h"
#include <signal.h> 

#include <poll.h>
#include <sys/types.h>

#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif

/* Some systems require that the poll array be non-empty so provide a
 * 1-elt array for starters.  It will be ignored as soon as it grows
 * larger.
 */

static struct pollfd initialFdArray;
static struct pollfd *fdArray = &initialFdArray;
static int fdsInUse = 0;	/* space in use */
static int fdsMaxSpace = 1;	/* space that has actually been allocated */

/*
 * tclUnixNotify.c --
 *
 *	This file contains the implementation of the select-based
 *	Unix-specific notifier, which is the lowest-level part of the
 *	Tcl event loop.  This file works together with
 *	../generic/tclNotify.c.
 *
 * Copyright (c) 1995-1997 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tclUnixNotfy.c 1.42 97/07/02 20:55:44
 */

/*
 * This structure is used to keep track of the notifier info for a 
 * a registered file.
 */

typedef struct FileHandler {
    int fd;
    int mask;			/* Mask of desired events: TCL_READABLE,
				 * etc. */
    int readyMask;		/* Mask of events that have been seen since the
				 * last time file handlers were invoked for
				 * this file. */
    Tcl_FileProc *proc;		/* Procedure to call, in the style of
				 * Tcl_CreateFileHandler. */
    ClientData clientData;	/* Argument to pass to proc. */
    int pollArrayIndex;		/* index into poll array */
    struct FileHandler *nextPtr;/* Next in list of all files we care about. */
} FileHandler;

/*
 * The following structure is what is added to the Tcl event queue when
 * file handlers are ready to fire.
 */

typedef struct FileHandlerEvent {
    Tcl_Event header;		/* Information that is standard for
				 * all events. */
    int fd;			/* File descriptor that is ready.  Used
				 * to find the FileHandler structure for
				 * the file (can't point directly to the
				 * FileHandler structure because it could
				 * go away while the event is queued). */
} FileHandlerEvent;

/*
 * The following static structure contains the state information for the
 * select based implementation of the Tcl notifier.
 */

static struct {
    FileHandler *firstFileHandlerPtr;
				/* Pointer to head of file handler list. */
    fd_mask checkMasks[3*MASK_SIZE];
				/* This array is used to build up the masks
				 * to be used in the next call to select.
				 * Bits are set in response to calls to
				 * Tcl_CreateFileHandler. */
    fd_mask readyMasks[3*MASK_SIZE];
				/* This array reflects the readable/writable
				 * conditions that were found to exist by the
				 * last call to select. */
    int numFdBits;		/* Number of valid bits in checkMasks
				 * (one more than highest fd for which
				 * Tcl_WatchFile has been called). */
} notifier;

/*
 * The following static indicates whether this module has been initialized.
 */

static int initialized = 0;

/*
 * Static routines defined in this file.
 */

static void		InitNotifier _ANSI_ARGS_((void));
static void		NotifierExitHandler _ANSI_ARGS_((
			    ClientData clientData));
static int		FileHandlerEventProc _ANSI_ARGS_((Tcl_Event *evPtr,
			    int flags));

/*
 *----------------------------------------------------------------------
 *
 * InitNotifier --
 *
 *	Initializes the notifier state.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates a new exit handler.
 *
 *----------------------------------------------------------------------
 */

static void
InitNotifier()
{
    initialized = 1;
    memset(&notifier, 0, sizeof(notifier));
    Tcl_CreateExitHandler(NotifierExitHandler, NULL);
}

/*
 *----------------------------------------------------------------------
 *
 * NotifierExitHandler --
 *
 *	This function is called to cleanup the notifier state before
 *	Tcl is unloaded.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Destroys the notifier window.
 *
 *----------------------------------------------------------------------
 */

static void
NotifierExitHandler(clientData)
    ClientData clientData;		/* Not used. */
{
    initialized = 0;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_SetTimer --
 *
 *	This procedure sets the current notifier timer value.  This
 *	interface is not implemented in this notifier because we are
 *	always running inside of Tcl_DoOneEvent.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_SetTimer(timePtr)
    Tcl_Time *timePtr;		/* Timeout value, may be NULL. */
{
    /*
     * The interval timer doesn't do anything in this implementation,
     * because the only event loop is via Tcl_DoOneEvent, which passes
     * timeout values to Tcl_WaitForEvent.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_CreateFileHandler --
 *
 *	This procedure registers a file handler with the Xt notifier.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Creates a new file handler structure and registers one or more
 *	input procedures with Xt.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_CreateFileHandler(fd, mask, proc, clientData)
    int fd;			/* Handle of stream to watch. */
    int mask;			/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, and TCL_EXCEPTION:
				 * indicates conditions under which
				 * proc should be called. */
    Tcl_FileProc *proc;		/* Procedure to call for each
				 * selected event. */
    ClientData clientData;	/* Arbitrary data to pass to proc. */
{
    FileHandler *filePtr;
    int index, bit;
    int cur_fd_index;
    
    if (!initialized) {
	InitNotifier();
    }

    for (filePtr = notifier.firstFileHandlerPtr; filePtr != NULL;
	    filePtr = filePtr->nextPtr) {
	if (filePtr->fd == fd) {
	    break;
	}
    }
    if (filePtr == NULL) {
	filePtr = (FileHandler*) ckalloc(sizeof(FileHandler)); /* MLK */
	filePtr->fd = fd;
	filePtr->readyMask = 0;
	filePtr->nextPtr = notifier.firstFileHandlerPtr;
	notifier.firstFileHandlerPtr = filePtr;
    }
    filePtr->proc = proc;
    filePtr->clientData = clientData;
    filePtr->pollArrayIndex = fdsInUse;
    cur_fd_index = fdsInUse;

    fdsInUse++;
    if (fdsInUse > fdsMaxSpace) {
	if (fdArray != &initialFdArray) ckfree((char *)fdArray);
	fdArray = (struct pollfd *)ckalloc(fdsInUse*sizeof(struct pollfd));
	fdsMaxSpace = fdsInUse;
    }

    fdArray[cur_fd_index].fd = fd;

    /* I know that POLLIN/OUT is right.  But I have no idea if POLLPRI
     * corresponds well to TCL_EXCEPTION.
     */

    if (mask & TCL_READABLE) {
        fdArray[cur_fd_index].events = POLLIN;
    }
    if (mask & TCL_WRITABLE) {
        fdArray[cur_fd_index].events = POLLOUT;
    }
    if (mask & TCL_EXCEPTION) {
        fdArray[cur_fd_index].events = POLLPRI;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_DeleteFileHandler --
 *
 *	Cancel a previously-arranged callback arrangement for
 *	a file.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If a callback was previously registered on file, remove it.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DeleteFileHandler(fd)
    int fd;		/* Stream id for which to remove callback procedure. */
{
    FileHandler *filePtr, *prevPtr, *lastPtr;
    int index, bit, mask, i;
    int cur_fd_index;

    if (!initialized) {
	InitNotifier();
    }

    /*
     * Find the entry for the given file (and return if there
     * isn't one).
     */

    for (prevPtr = NULL, filePtr = notifier.firstFileHandlerPtr; ;
	    prevPtr = filePtr, filePtr = filePtr->nextPtr) {
	if (filePtr == NULL) {
	    return;
	}
	if (filePtr->fd == fd) {
	    break;
	}
    }

    /*
     * Clean up information in the callback record.
     */

    if (prevPtr == NULL) {
	notifier.firstFileHandlerPtr = filePtr->nextPtr;
    } else {
	prevPtr->nextPtr = filePtr->nextPtr;
    }

    /* back to poll-specific code - DEL */

    cur_fd_index = filePtr->pollArrayIndex;
    fdsInUse--;

    /* if this one is last, do nothing special */
    /* else swap with one at end of array */

    if (cur_fd_index != fdsInUse) {
	int lastfd_in_array = fdArray[fdsInUse].fd;
	memcpy(&fdArray[cur_fd_index],&fdArray[fdsInUse],sizeof(struct pollfd));

	/* update index to reflect new location in array */
	/* first find link corresponding to last element in array */
	    
	for (lastPtr = notifier.firstFileHandlerPtr; filePtr; lastPtr = lastPtr->nextPtr) {
	    if (lastPtr->fd == lastfd_in_array) {
		lastPtr->pollArrayIndex = cur_fd_index;
		break;
	    }
	}
    }

    fdsInUse--;

    ckfree((char *) filePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * FileHandlerEventProc --
 *
 *	This procedure is called by Tcl_ServiceEvent when a file event
 *	reaches the front of the event queue.  This procedure is
 *	responsible for actually handling the event by invoking the
 *	callback for the file handler.
 *
 * Results:
 *	Returns 1 if the event was handled, meaning it should be removed
 *	from the queue.  Returns 0 if the event was not handled, meaning
 *	it should stay on the queue.  The only time the event isn't
 *	handled is if the TCL_FILE_EVENTS flag bit isn't set.
 *
 * Side effects:
 *	Whatever the file handler's callback procedure does.
 *
 *----------------------------------------------------------------------
 */

static int
FileHandlerEventProc(evPtr, flags)
    Tcl_Event *evPtr;		/* Event to service. */
    int flags;			/* Flags that indicate what events to
				 * handle, such as TCL_FILE_EVENTS. */
{
    FileHandler *filePtr;
    FileHandlerEvent *fileEvPtr = (FileHandlerEvent *) evPtr;
    int mask;

    if (!(flags & TCL_FILE_EVENTS)) {
	return 0;
    }

    /*
     * Search through the file handlers to find the one whose handle matches
     * the event.  We do this rather than keeping a pointer to the file
     * handler directly in the event, so that the handler can be deleted
     * while the event is queued without leaving a dangling pointer.
     */

    for (filePtr = notifier.firstFileHandlerPtr; filePtr != NULL;
	    filePtr = filePtr->nextPtr) {
	if (filePtr->fd != fileEvPtr->fd) {
	    continue;
	}

	/*
	 * The code is tricky for two reasons:
	 * 1. The file handler's desired events could have changed
	 *    since the time when the event was queued, so AND the
	 *    ready mask with the desired mask.
	 * 2. The file could have been closed and re-opened since
	 *    the time when the event was queued.  This is why the
	 *    ready mask is stored in the file handler rather than
	 *    the queued event:  it will be zeroed when a new
	 *    file handler is created for the newly opened file.
	 */

	mask = filePtr->readyMask & filePtr->mask;
	filePtr->readyMask = 0;
	if (mask != 0) {
	    (*filePtr->proc)(filePtr->clientData, mask);
	}
	break;
    }
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_WaitForEvent --
 *
 *	This function is called by Tcl_DoOneEvent to wait for new
 *	events on the message queue.  If the block time is 0, then
 *	Tcl_WaitForEvent just polls without blocking.
 *
 * Results:
 *	Returns -1 if the select would block forever, otherwise
 *	returns 0.
 *
 * Side effects:
 *	Queues file events that are detected by the select.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_WaitForEvent(timePtr)
    Tcl_Time *timePtr;		/* Maximum block time, or NULL. */
{
    FileHandler *filePtr;
    FileHandlerEvent *fileEvPtr;
    int timeout;
    struct timeval *timeoutPtr;

    int bit, index, mask, numFound;

    if (!initialized) {
	InitNotifier();
    }

    /*
     * Set up the timeout structure.  Note that if there are no events to
     * check for, we return with a negative result rather than blocking
     * forever.
     */

    if (timePtr) {
        timeout = timePtr->sec*1000 + timePtr->usec/1000;

    } else if (notifier.numFdBits == 0) {
	return -1;
    } else {
	timeoutPtr = NULL;
    }

    numFound = poll(fdArray,fdsInUse,timeout);

    /*
     * Queue all detected file events before returning.
     */

    for (filePtr = notifier.firstFileHandlerPtr;
	    (filePtr != NULL) && (numFound > 0);
	    filePtr = filePtr->nextPtr) {
	index = filePtr->pollArrayIndex;
        mask = 0;

        if (fdArray[index].revents & POLLIN) {
	    mask |= TCL_READABLE;
        }
        if (fdArray[index].revents & POLLOUT) {
	    mask |= TCL_WRITABLE;
        }
        /* I have no idea if this is right ... */
        if (fdArray[index].revents & (POLLPRI|POLLERR|POLLHUP|POLLNVAL)) {
	    mask |= TCL_EXCEPTION;
        }

	if (!mask) {
	    continue;
	} else {
	    numFound--;
	}

	/*
	 * Don't bother to queue an event if the mask was previously
	 * non-zero since an event must still be on the queue.
	 */

	if (filePtr->readyMask == 0) {
	    fileEvPtr = (FileHandlerEvent *) ckalloc(
		sizeof(FileHandlerEvent));
	    fileEvPtr->header.proc = FileHandlerEventProc;
	    fileEvPtr->fd = filePtr->fd;
	    Tcl_QueueEvent((Tcl_Event *) fileEvPtr, TCL_QUEUE_TAIL);
	}
	filePtr->readyMask = mask;
    }
    return 0;
}

