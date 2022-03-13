/* 
 * exp_chan.c
 *
 *	Channel driver for Expect channels.
 *      Based on UNIX File channel from TclUnixChan.c
 *
 */

#include <sys/types.h>
#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <ctype.h>	/* for isspace */
#include <time.h>	/* for time(3) */

#include "expect_cf.h"

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#include <errno.h>

#include	"tclInt.h"	/* Internal definitions for Tcl. */

#include "tcl.h"

#include "string.h"

#include "exp_rename.h"
#include "exp_prog.h"
#include "exp_command.h"
#include "exp_log.h"
#include "exp_event.h"
#include "tcldbg.h" /* Dbg_StdinMode */

extern int		expSetBlockModeProc _ANSI_ARGS_((int fd, int mode));
static int		ExpBlockModeProc _ANSI_ARGS_((ClientData instanceData,
			    int mode));
static int		ExpCloseProc _ANSI_ARGS_((ClientData instanceData,
			    Tcl_Interp *interp));
static int		ExpInputProc _ANSI_ARGS_((ClientData instanceData,
		            char *buf, int toRead, int *errorCode));
static int		ExpOutputProc _ANSI_ARGS_((
			    ClientData instanceData, char *buf, int toWrite,
                            int *errorCode));
static void		ExpWatchProc _ANSI_ARGS_((ClientData instanceData,
		            int mask));
static int		ExpGetHandleProc _ANSI_ARGS_((ClientData instanceData,
		            int direction, ClientData *handlePtr));

/*
 * This structure describes the channel type structure for Expect-based IO:
 */

Tcl_ChannelType expChannelType = {
    "exp",				/* Type name. */
    ExpBlockModeProc,			/* Set blocking/nonblocking mode.*/
    ExpCloseProc,			/* Close proc. */
    ExpInputProc,			/* Input proc. */
    ExpOutputProc,			/* Output proc. */
    NULL,				/* Seek proc. */
    NULL,				/* Set option proc. */
    NULL,				/* Get option proc. */
    ExpWatchProc,			/* Initialize notifier. */
    ExpGetHandleProc,			/* Get OS handles out of channel. */
    NULL,				/* Close2 proc */
};

typedef struct ThreadSpecificData {
    /*
     * List of all exp channels currently open.  This is per thread and is
     * used to match up fd's to channels, which rarely occurs.
     */
    
    ExpState *firstExpPtr;
    int channelCount;	 /* this is process-wide as it is used to
			     give user some hint as to why a spawn has failed
			     by looking at process-wide resource usage */
} ThreadSpecificData;

static Tcl_ThreadDataKey dataKey;

/*
 *----------------------------------------------------------------------
 *
 * ExpBlockModeProc --
 *
 *	Helper procedure to set blocking and nonblocking modes on a
 *	file based channel. Invoked by generic IO level code.
 *
 * Results:
 *	0 if successful, errno when failed.
 *
 * Side effects:
 *	Sets the device into blocking or non-blocking mode.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
static int
ExpBlockModeProc(instanceData, mode)
    ClientData instanceData;		/* Exp state. */
    int mode;				/* The mode to set. Can be one of
					 * TCL_MODE_BLOCKING or
					 * TCL_MODE_NONBLOCKING. */
{
    ExpState *esPtr = (ExpState *) instanceData;

    if (esPtr->fdin == 0) {
        /* Forward status to debugger. Required for FIONBIO systems,
	 * which are unable to query the fd for its current state.
	 */
        Dbg_StdinMode (mode);
    }

    /* [Expect SF Bug 1108551] (July 7 2005)
     * Exclude manipulation of the blocking status for stdin/stderr.
     *
     * This is handled by the Tcl core itself and we must absolutely
     * not pull the rug out from under it. The standard setting to
     * non-blocking will mess with the core which had them set to
     * blocking, and makes all its decisions based on that assumption.
     * Setting to non-blocking can cause hangs and crashes.
     *
     * Stdin is ok however, apparently.
     * (Sep 9 2005) No, it is not.
     */

    if ((esPtr->fdin == 0) ||
	(esPtr->fdin == 1) ||
	(esPtr->fdin == 2)) {
      return 0;
    }

    return expSetBlockModeProc (esPtr->fdin, mode);
}

int
expSetBlockModeProc(fd, mode)
    int fd;
    int mode;				/* The mode to set. Can be one of
					 * TCL_MODE_BLOCKING or
					 * TCL_MODE_NONBLOCKING. */
{
    int curStatus;
    /*printf("ExpBlockModeProc(%d)\n",mode);
      printf("fdin = %d\n",fd);*/

#ifndef USE_FIONBIO
    curStatus = fcntl(fd, F_GETFL);
    /*printf("curStatus = %d\n",curStatus);*/
    if (mode == TCL_MODE_BLOCKING) {
	curStatus &= (~(O_NONBLOCK));
    } else {
	curStatus |= O_NONBLOCK;
    }
    /*printf("new curStatus %d\n",curStatus);*/
    if (fcntl(fd, F_SETFL, curStatus) < 0) {
	return errno;
    }
    curStatus = fcntl(fd, F_GETFL);
#else /* USE_FIONBIO */
    if (mode == TCL_MODE_BLOCKING) {
	curStatus = 0;
    } else {
	curStatus = 1;
    }
    if (ioctl(fd, (int) FIONBIO, &curStatus) < 0) {
	return errno;
    }
#endif /* !USE_FIONBIO */
    return 0;
}
/*
 *----------------------------------------------------------------------
 *
 * ExpInputProc --
 *
 *	This procedure is invoked from the generic IO level to read
 *	input from an exp-based channel.
 *
 * Results:
 *	The number of bytes read is returned or -1 on error. An output
 *	argument contains a POSIX error code if an error occurs, or zero.
 *
 * Side effects:
 *	Reads input from the input device of the channel.
 *
 *----------------------------------------------------------------------
 */

static int
ExpInputProc(instanceData, buf, toRead, errorCodePtr)
    ClientData instanceData;		/* Exp state. */
    char *buf;				/* Where to store data read. */
    int toRead;				/* How much space is available
                                         * in the buffer? */
    int *errorCodePtr;			/* Where to store error code. */
{
    ExpState *esPtr = (ExpState *) instanceData;
    int bytesRead;			/* How many bytes were actually
                                         * read from the input device? */

    *errorCodePtr = 0;
    
    /*
     * Assume there is always enough input available. This will block
     * appropriately, and read will unblock as soon as a short read is
     * possible, if the channel is in blocking mode. If the channel is
     * nonblocking, the read will never block.
     */

    bytesRead = read(esPtr->fdin, buf, (size_t) toRead);
    /*printf("ExpInputProc: read(%d,,) = %d\r\n",esPtr->fdin,bytesRead);*/

    /* Emulate EOF on tty for tcl */
    if ((bytesRead == -1) && (errno == EIO) && isatty(esPtr->fdin)) {
	bytesRead = 0;
    }
    if (bytesRead > -1) {
	/* strip parity if requested */
	if (esPtr->parity == 0) {
	    char *end = buf+bytesRead;
	    for (;buf < end;buf++) {
		*buf &= 0x7f;
	    }
	}
        return bytesRead;
    }
    *errorCodePtr = errno;
    return -1;
}

/*
 *----------------------------------------------------------------------
 *
 * ExpOutputProc--
 *
 *	This procedure is invoked from the generic IO level to write
 *	output to an exp channel.
 *
 * Results:
 *	The number of bytes written is returned or -1 on error. An
 *	output argument	contains a POSIX error code if an error occurred,
 *	or zero.
 *
 * Side effects:
 *	Writes output on the output device of the channel.
 *
 *----------------------------------------------------------------------
 */

static int
ExpOutputProc(instanceData, buf, toWrite, errorCodePtr)
    ClientData instanceData;		/* Exp state. */
    char *buf;				/* The data buffer. */
    int toWrite;			/* How many bytes to write? */
    int *errorCodePtr;			/* Where to store error code. */
{
    ExpState *esPtr = (ExpState *) instanceData;
    int written = 0;

    *errorCodePtr = 0;

    if (toWrite < 0) Tcl_Panic("ExpOutputProc: called with negative char count");
    if (toWrite ==0) {
        return 0;
    }

    written = write(esPtr->fdout, buf, (size_t) toWrite);
    if (written == 0) {
      /* This shouldn't happen but I'm told that it does
       * nonetheless (at least on SunOS 4.1.3).  Since this is
       * not a documented return value, the most reasonable
       * thing is to complain here and retry in the hopes that
       * it is some transient condition.  */
      sleep(1);
      expDiagLogU("write() failed to write anything - will sleep(1) and retry...\n");
      *errorCodePtr = EAGAIN;
      return -1;
    } else if (written < 0) {
      *errorCodePtr = errno;
      return -1;
    }
    return written;
}

/*
 *----------------------------------------------------------------------
 *
 * ExpCloseProc --
 *
 *	This procedure is called from the generic IO level to perform
 *	channel-type-specific cleanup when an exp-based channel is closed.
 *
 * Results:
 *	0 if successful, errno if failed.
 *
 * Side effects:
 *	Closes the device of the channel.
 *
 *----------------------------------------------------------------------
 */

/*ARGSUSED*/
static int
ExpCloseProc(instanceData, interp)
    ClientData instanceData;	/* Exp state. */
    Tcl_Interp *interp;		/* For error reporting - unused. */
{
    ExpState *esPtr = (ExpState *) instanceData;
    ExpState **nextPtrPtr;
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    esPtr->registered = FALSE;

#if 0
    /*
      Really should check that we created one first.  Since we're sharing fds
      with Tcl, perhaps a filehandler was created with a plain tcl file - we
      wouldn't want to delete that.  Although if user really close Expect's
      user_spawn_id, it probably doesn't matter anyway.
    */

    Tcl_DeleteFileHandler(esPtr->fdin);
#endif /*0*/

    Tcl_Free((char*)esPtr->input.buffer);
    Tcl_DecrRefCount (esPtr->input.newchars);

    /* Actually file descriptor should have been closed earlier. */
    /* So do nothing here */

    /*
     * Conceivably, the process may not yet have been waited for.  If this
     * becomes a requirement, we'll have to revisit this code.  But for now, if
     * it's just Tcl exiting, the processes will exit on their own soon
     * anyway.
     */

    for (nextPtrPtr = &(tsdPtr->firstExpPtr); (*nextPtrPtr) != NULL;
	 nextPtrPtr = &((*nextPtrPtr)->nextPtr)) {
	if ((*nextPtrPtr) == esPtr) {
	    (*nextPtrPtr) = esPtr->nextPtr;
	    break;
	}
    }
    tsdPtr->channelCount--;

    if (esPtr->bg_status == blocked ||
	    esPtr->bg_status == disarm_req_while_blocked) {
	esPtr->freeWhenBgHandlerUnblocked = 1;
	/*
	 * If we're in the middle of a bg event handler, then the event
	 * handler will have to take care of freeing esPtr.
	 */
    } else {
	expStateFree(esPtr);
    }
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * ExpWatchProc --
 *
 *	Initialize the notifier to watch the fd from this channel.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets up the notifier so that a future event on the channel will
 *	be seen by Tcl.
 *
 *----------------------------------------------------------------------
 */

static void
ExpWatchProc(instanceData, mask)
    ClientData instanceData;		/* The exp state. */
    int mask;				/* Events of interest; an OR-ed
                                         * combination of TCL_READABLE,
                                         * TCL_WRITABLE and TCL_EXCEPTION. */
{
    ExpState *esPtr = (ExpState *) instanceData;

    /*
     * Make sure we only register for events that are valid on this exp.
     * Note that we are passing Tcl_NotifyChannel directly to
     * Tcl_CreateExpHandler with the channel pointer as the client data.
     */

    mask &= esPtr->validMask;
    if (mask) {
	/*printf("  CreateFileHandler: %d (mask = %d)\r\n",esPtr->fdin,mask);*/
	Tcl_CreateFileHandler(esPtr->fdin, mask,
		(Tcl_FileProc *) Tcl_NotifyChannel,
		(ClientData) esPtr->channel);
    } else {
	/*printf("  DeleteFileHandler: %d (mask = %d)\r\n",esPtr->fdin,mask);*/
	Tcl_DeleteFileHandler(esPtr->fdin);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ExpGetHandleProc --
 *
 *	Called from Tcl_GetChannelHandle to retrieve OS handles from
 *	an exp-based channel.
 *
 * Results:
 *	Returns TCL_OK with the fd in handlePtr, or TCL_ERROR if
 *	there is no handle for the specified direction. 
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
ExpGetHandleProc(instanceData, direction, handlePtr)
    ClientData instanceData;	/* The exp state. */
    int direction;		/* TCL_READABLE or TCL_WRITABLE */
    ClientData *handlePtr;	/* Where to store the handle.  */
{
    ExpState *esPtr = (ExpState *) instanceData;

    if (direction & TCL_WRITABLE) {
	*handlePtr = (ClientData) esPtr->fdin;
    }
    if (direction & TCL_READABLE) {
	*handlePtr = (ClientData) esPtr->fdin;
    } else {
	return TCL_ERROR;
    }
    return TCL_OK;
}

int
expChannelCountGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->channelCount;
}

int
expChannelStillAlive(esBackupPtr, backupName)
     ExpState *esBackupPtr;
     char *backupName;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    ExpState *esPtr;

    /* 
     * This utility function is called from 'exp_background_channelhandler'
     * and checks to make sure that backupName can still be found in the 
     * channels linked list at the same address as before.
     *
     * If it can't be (or if the memory address has changed) then it
     * means that it was lost in the background (and possibly another
     * channel was opened and reassigned the same name).
     */

    for (esPtr = tsdPtr->firstExpPtr; esPtr; esPtr = esPtr->nextPtr) {
        if (0 == strcmp(esPtr->name, backupName)) 
            return (esPtr == esBackupPtr);
    }
        
    /* not found; must have been lost in the background */
    return 0;
}

#if 0 /* Converted to macros */
int
expSizeGet(esPtr)
    ExpState *esPtr;
{
    return esPtr->input.use;
}

int
expSizeZero(esPtr)
    ExpState *esPtr;
{
    return (esPtr->input.use == 0);
}
#endif
/* return 0 for success or negative for failure */
int
expWriteChars(esPtr,buffer,lenBytes)
     ExpState *esPtr;
     char *buffer;
     int lenBytes;
{
  int rc;
 retry:
  rc = Tcl_WriteChars(esPtr->channel,buffer,lenBytes);
  if ((rc == -1) && (errno == EAGAIN)) goto retry;

  if (!exp_strict_write) {
    /*
     * 5.41 compatbility behaviour. Ignore any and all write errors
     * the OS may have thrown.
     */
    return 0;
  }

  /* just return 0 rather than positive byte counts */
  return ((rc > 0) ? 0 : rc);
}

int
expWriteCharsUni(esPtr,buffer,lenChars)
     ExpState *esPtr;
     Tcl_UniChar *buffer;
     int lenChars;
{
  int rc;
  Tcl_DString ds;

  Tcl_DStringInit (&ds);
  Tcl_UniCharToUtfDString (buffer,lenChars,&ds);

  rc = expWriteChars(esPtr,Tcl_DStringValue (&ds), Tcl_DStringLength (&ds));

  Tcl_DStringFree (&ds);

  return rc;
}

void
expStateFree(esPtr)
    ExpState *esPtr;
{
  if (esPtr->fdBusy) {
    close(esPtr->fdin);
  }

    esPtr->valid = FALSE;
    
    if (!esPtr->keepForever) {
	ckfree((char *)esPtr);
    }
}

/* close all connections
 * 
 * The kernel would actually do this by default, however Tcl is going to come
 * along later and try to reap its exec'd processes.  If we have inherited any
 * via spawn -open, Tcl can hang if we don't close the connections first.
 */
void
exp_close_all(interp)
Tcl_Interp *interp;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    ExpState *esPtr;
    ExpState *esNextPtr;

    /* Save the nextPtr in a local variable before calling 'exp_close'
       as 'expStateFree' can be called from it under some
       circumstances, possibly causing the memory allocator to smash
       the value in 'esPtr'. - Andreas Kupries
    */

    /* no need to keep things in sync (i.e., tsdPtr, count) since we could only
       be doing this if we're exiting.  Just close everything down. */

    for (esPtr = tsdPtr->firstExpPtr;esPtr;esPtr = esNextPtr) {
        esNextPtr = esPtr->nextPtr;
	exp_close(interp,esPtr);
    }
}

/* wait for any of our own spawned processes we call waitpid rather
 * than wait to avoid running into someone else's processes.  Yes,
 * according to Ousterhout this is the best way to do it.
 * returns the ExpState or 0 if nothing to wait on */
ExpState *
expWaitOnAny()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    int result;
    ExpState *esPtr;

    for (esPtr = tsdPtr->firstExpPtr;esPtr;esPtr = esPtr->nextPtr) {
	if (esPtr->pid == exp_getpid) continue; /* skip ourself */
	if (esPtr->user_waited) continue;	/* one wait only! */
	if (esPtr->sys_waited) break;
      restart:
	result = waitpid(esPtr->pid,&esPtr->wait,WNOHANG);
	if (result == esPtr->pid) break;
	if (result == 0) continue;	/* busy, try next */
	if (result == -1) {
	    if (errno == EINTR) goto restart;
	    else break;
	}
    }
    return esPtr;
}

ExpState *
expWaitOnOne() {
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    ExpState *esPtr;
    int pid;
    /* should really be recoded using the common wait code in command.c */
    WAIT_STATUS_TYPE status;

    pid = wait(&status);
    for (esPtr = tsdPtr->firstExpPtr;esPtr;esPtr = esPtr->nextPtr) {
	if (esPtr->pid == pid) {
	    esPtr->sys_waited = TRUE;
	    esPtr->wait = status;
	    return esPtr;
	}
    }
    /* Should not reach this location. If it happens return a value
     * causing an easy crash */
    return NULL;
}

void
exp_background_channelhandlers_run_all()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    ExpState *esPtr;
    ExpState *esNextPtr;
    ExpState *esPriorPtr = 0;

    /* kick off any that already have input waiting */
    for (esPtr = tsdPtr->firstExpPtr;esPtr; esPriorPtr = esPtr, esPtr = esPtr->nextPtr) {
	/* is bg_interp the best way to check if armed? */
	if (esPtr->bg_interp && !expSizeZero(esPtr)) {
            /* 
             * We save the nextPtr in a local variable before calling
             * 'exp_background_channelhandler' since in some cases
             * 'expStateFree' could end up getting called before it
             * returns, leading to a likely segfault on the next
             * interaction through the for loop.
             */
            esNextPtr = esPtr->nextPtr;
	    exp_background_channelhandler((ClientData)esPtr,0);
            if (esNextPtr != esPtr->nextPtr) {
                /* 
                 * 'expStateFree' must have been called from
                 * underneath us so we know that esPtr->nextPtr is
                 * invalid.  However, it is possible that either the
                 * original nextPtr and/or the priorPtr have been
                 * freed too.  If the esPriorPtr->nextPtr is now
                 * esNextPtr it seems safe to proceed.  Otherwise we
                 * break and end early for safety.
                 */
                if (esPriorPtr && esPriorPtr->nextPtr == esNextPtr) {
                    esPtr = esPriorPtr;
                } else {
                    break; /* maybe set esPtr = tsdPtr->firstExpPtr again? */
                }
            }
	}
    }
}

ExpState *
expCreateChannel(interp,fdin,fdout,pid)
    Tcl_Interp *interp;
    int fdin;
    int fdout;
    int pid;
{
    ExpState *esPtr;
    int mask;
    Tcl_ChannelType *channelTypePtr;
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    channelTypePtr = &expChannelType;

    esPtr = (ExpState *) ckalloc((unsigned) sizeof(ExpState));

    esPtr->nextPtr = tsdPtr->firstExpPtr;
    tsdPtr->firstExpPtr = esPtr;

    sprintf(esPtr->name,"exp%d",fdin);

    /*
     * For now, stupidly assume this.  We we will likely have to revisit this
     * later to prevent people from doing stupid things.
     */
    mask = TCL_READABLE | TCL_WRITABLE;

    /* not sure about this - what about adopted channels */
    esPtr->validMask = mask | TCL_EXCEPTION;
    esPtr->fdin = fdin;
    esPtr->fdout = fdout;

    /* set close-on-exec for everything but std channels */
    /* (system and stty commands need access to std channels) */
    if (fdin != 0 && fdin != 2) {
      expCloseOnExec(fdin);
      if (fdin != fdout) expCloseOnExec(fdout);
    }

    esPtr->fdBusy = FALSE;
    esPtr->channel = Tcl_CreateChannel(channelTypePtr, esPtr->name,
	    (ClientData) esPtr, mask);
    Tcl_RegisterChannel(interp,esPtr->channel);
    esPtr->registered = TRUE;
    Tcl_SetChannelOption(interp,esPtr->channel,"-buffering","none");
    Tcl_SetChannelOption(interp,esPtr->channel,"-blocking","0");
    Tcl_SetChannelOption(interp,esPtr->channel,"-translation","lf");

    esPtr->pid = pid;

    esPtr->input.max    = 1;
    esPtr->input.use    = 0;
    esPtr->input.buffer = (Tcl_UniChar*) Tcl_Alloc (sizeof (Tcl_UniChar));
    esPtr->input.newchars = Tcl_NewObj();
    Tcl_IncrRefCount (esPtr->input.newchars);

    esPtr->umsize = exp_default_match_max;
    /* this will reallocate object with an appropriate sized buffer */
    expAdjust(esPtr);

    esPtr->printed = 0;
    esPtr->echoed = 0;
    esPtr->rm_nulls = exp_default_rm_nulls;
    esPtr->parity = exp_default_parity;
    esPtr->close_on_eof = exp_default_close_on_eof;
    esPtr->key = expect_key++;
    esPtr->force_read = FALSE;
    esPtr->fg_armed = FALSE;
    esPtr->chan_orig = 0;
    esPtr->fd_slave = EXP_NOFD;
#ifdef HAVE_PTYTRAP
    esPtr->slave_name = 0;
#endif /* HAVE_PTYTRAP */
    esPtr->open = TRUE;
    esPtr->notified = FALSE;
    esPtr->user_waited = FALSE;
    esPtr->sys_waited = FALSE;
    esPtr->bg_interp = 0;
    esPtr->bg_status = unarmed;
    esPtr->bg_ecount = 0;
    esPtr->freeWhenBgHandlerUnblocked = FALSE;
    esPtr->keepForever = FALSE;
    esPtr->valid = TRUE;
    tsdPtr->channelCount++;

    return esPtr;
}

void
expChannelInit() {
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    tsdPtr->channelCount = 0;
}
