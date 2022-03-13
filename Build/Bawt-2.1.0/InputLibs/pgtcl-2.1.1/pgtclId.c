/*-------------------------------------------------------------------------
 *
 * pgtclId.c
 *
 *	Contains Tcl "channel" interface routines, plus useful routines
 *	to convert between strings and pointers.  These are needed because
 *	everything in Tcl is a string, but in C, pointers to data structures
 *	are needed.
 *
 *	ASSUMPTION:  sizeof(long) >= sizeof(void*)
 *
 * Portions Copyright (c) 1996-2004, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  $Id: pgtclId.c 304 2011-09-19 00:55:15Z lbayuk $
 *
 *-------------------------------------------------------------------------
 */

#include <string.h>
#include <errno.h>

#include "pgtclCmds.h"
#include "pgtclId.h"

/*
 * Post-COPY cleanup, common to COPY FROM and COPY TO.
 */
static int
PgEndCopy(Pg_ConnectionId * connid)
{
	connid->res_copyStatus = RES_COPY_NONE;
	PQclear(connid->results[connid->res_copy]);
	connid->results[connid->res_copy] = PQgetResult(connid->conn);
	connid->res_copy = -1;
	return 0;
}

/*
 *	Called when reading data (via gets) for a copy <rel> to stdout.
 */
int
PgInputProc(DRIVER_INPUT_PROTO)
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;
	int			nread;
	char	   *pqbufp;

	connid = (Pg_ConnectionId *) cData;
	conn = connid->conn;

	if (connid->res_copy < 0 ||
	 PQresultStatus(connid->results[connid->res_copy]) != PGRES_COPY_OUT)
	{
		*errorCodePtr = EBUSY;
		return -1;
	}

	/*
	 * Before reading more data from libpq, see if anything was left
	 * over from a previous PQgetCopyData() which was too big to fit
	 * in Tcl's buffer.
	 */
	if (connid->copyBuf != NULL)
	{
		/* How much to return? */
		if (connid->copyBufLeft <= bufSize)
		{
			/* All of it */
			nread = connid->copyBufLeft;
			memcpy(buf, connid->copyBufNext, nread);
			PQfreemem(connid->copyBuf);
			connid->copyBuf = NULL;
		}
		else
		{
			/* Not all of it - just the next bufSize bytes */
			nread = bufSize;
			memcpy(buf, connid->copyBufNext, nread);
			connid->copyBufNext += nread;
			connid->copyBufLeft -= nread;
		}
		return nread;
	}

	/*
	 *  Read data in sync mode (async=0).
	 *  Note libpq allocates the buffer, which will always contain a whole
	 *  record, but it may be bigger than Tcl's buffer.
	 */
	nread = PQgetCopyData(conn, &pqbufp, 0);
	if (nread == -2)
	{
		/* Error case. No way to get libpq's error message over to Tcl? */
		*errorCodePtr = EBUSY;
		return -1;
	}
	if (nread == -1)
	{
		/* All done. No need to call anything like PQendcopy() any more. */
		return PgEndCopy(connid);
 	}
	if (nread == 0) /* Should not happen in sync mode */
		return 0;

	/* If it fits, send the whole thing to Tcl */
	if (nread <= bufSize)
	{
		memcpy(buf, pqbufp, nread);
		PQfreemem(pqbufp);
		return nread;
	}

	/*
	 * If it doesn't fit, give Tcl a full buffer-full and save
	 * the rest for the next call. We must give Tcl a full buffer,
	 * or it will just ask for the remaining bytes.
	 */
	memcpy(buf, pqbufp, bufSize);
	connid->copyBuf = pqbufp;
	connid->copyBufNext = pqbufp + bufSize;
	connid->copyBufLeft = nread - bufSize;
	return bufSize;
}

/*
 *	Called when writing data (via puts) for a copy <rel> from stdin
 */
int
PgOutputProc(DRIVER_OUTPUT_PROTO)
{
	Pg_ConnectionId *connid;
	PGconn	   *conn;

	connid = (Pg_ConnectionId *) cData;
	conn = connid->conn;

	if (connid->res_copy < 0 ||
	  PQresultStatus(connid->results[connid->res_copy]) != PGRES_COPY_IN)
	{
		*errorCodePtr = EBUSY;
		return -1;
	}

	/*
	 * Look for the end of copy terminator: "\\." followed by end of line.
	 * Only look for this at the start of the buffer - it must be written
	 * in its own 'puts'.
	 * (Previous implementations looked for it at the end of each buffer,
	 * but that falsely triggered on some valid data).
	 */
	if (bufSize > 2 && buf[0] == '\\' && buf[1] == '.'
			&& (buf[2] == '\n' || buf[2] == '\r'))
	{
		/* End copy with no client-side error message */
		PQputCopyEnd(conn, NULL);
		PgEndCopy(connid);
		/*
		 * We didn't actually write bufSize bytes to the output channel, but
		 * as far as Tcl cares, the write was successful.
		 */
		return bufSize;
	}

	/* Write the COPY IN data */
	if (PQputCopyData(conn, buf, bufSize) == -1)
	{
		/* No way to pass libpq error message back to Tcl? */
		*errorCodePtr = EIO;
		return -1;
	}
	return bufSize;
}

/*
 * The WatchProc and GetHandleProc are no-ops but must be present.
 */
static void
PgWatchProc(ClientData instanceData, int mask)
{
}

static int
PgGetHandleProc(ClientData instanceData, int direction,
				ClientData *handlePtr)
{
	return TCL_ERROR;
}

Tcl_ChannelType Pg_ConnType = {
	"pgsql",					/* channel type */
	NULL,						/* blockmodeproc */
	PgDelConnectionId,			/* closeproc */
	PgInputProc,				/* inputproc */
	PgOutputProc,				/* outputproc */
	NULL,						/* SeekProc, Not used */
	NULL,						/* SetOptionProc, Not used */
	NULL,						/* GetOptionProc, Not used */
	PgWatchProc,				/* WatchProc, must be defined */
	PgGetHandleProc,			/* GetHandleProc, must be defined */
	NULL						/* Close2Proc, Not used */
};

/*
 * Create and register a new channel for the connection
 */
void
PgSetConnectionId(Tcl_Interp *interp, PGconn *conn)
{
	Tcl_Channel conn_chan;
	Pg_ConnectionId *connid;
	int			i;

	connid = (Pg_ConnectionId *) ckalloc(sizeof(Pg_ConnectionId));
	connid->conn = conn;
	connid->res_count = 0;
	connid->res_last = -1;
	connid->res_max = RES_START;
	connid->res_hardmax = RES_HARD_MAX;
	connid->res_copy = -1;
	connid->res_copyStatus = RES_COPY_NONE;
	connid->copyBuf = NULL;
	connid->results = (PGresult **) ckalloc(sizeof(PGresult *) * RES_START);
	for (i = 0; i < RES_START; i++)
		connid->results[i] = NULL;
	connid->null_string = NULL;
	connid->notify_list = NULL;
	connid->notifier_running = 0;
	connid->interp = NULL;
	connid->notice_command = NULL;
	connid->callbackPtr = NULL;
	connid->callbackInterp = NULL;

	sprintf(connid->id, "pgsql%d", PQsocket(conn));

	connid->notifier_channel = Tcl_MakeTcpClientChannel((ClientData) PQsocket(conn));
	/* Code  executing  outside  of  any Tcl interpreter can call
       Tcl_RegisterChannel with interp as NULL, to indicate  that
       it  wishes  to  hold  a  reference to this channel. Subse-
       quently, the channel can be registered  in  a  Tcl  inter-
       preter and it will only be closed when the matching number
       of calls to Tcl_UnregisterChannel have  been  made.   This
       allows code executing outside of any interpreter to safely
       hold a reference to a channel that is also registered in a
       Tcl interpreter.
	*/
	Tcl_RegisterChannel(NULL, connid->notifier_channel);

	conn_chan = Tcl_CreateChannel(&Pg_ConnType, connid->id, (ClientData) connid,
								  TCL_READABLE | TCL_WRITABLE);

	Tcl_SetChannelOption(interp, conn_chan, "-buffering", "line");
	Tcl_SetChannelOption(interp, conn_chan, "-encoding", "utf-8");
	Tcl_SetResult(interp, connid->id, TCL_VOLATILE);
	Tcl_RegisterChannel(interp, conn_chan);
}


/*
 * Get back the connection from the Id
 */
PGconn *
PgGetConnectionId(Tcl_Interp *interp, CONST84 char *id,
				  Pg_ConnectionId ** connid_p)
{
	Tcl_Channel conn_chan;
	Pg_ConnectionId *connid;

	conn_chan = Tcl_GetChannel(interp, id, 0);
	if (conn_chan == NULL || Tcl_GetChannelType(conn_chan) != &Pg_ConnType)
	{
		Tcl_ResetResult(interp);
		Tcl_AppendResult(interp, id, " is not a valid postgresql connection", 0);
		if (connid_p)
			*connid_p = NULL;
		return (PGconn *) NULL;
	}

	connid = (Pg_ConnectionId *) Tcl_GetChannelInstanceData(conn_chan);
	if (connid_p)
		*connid_p = connid;
	return connid->conn;
}


/*
 * Remove a connection Id from the hash table and
 * close all portals the user forgot.
 */
int
PgDelConnectionId(DRIVER_DEL_PROTO)
{
	Tcl_HashEntry *entry;
	Tcl_HashSearch hsearch;
	Pg_ConnectionId *connid;
	Pg_TclNotifies *notifies;
	Pg_notify_command *notifCmd;
	int			i;

	connid = (Pg_ConnectionId *) cData;

	for (i = 0; i < connid->res_max; i++)
	{
		if (connid->results[i])
			PQclear(connid->results[i]);
	}
	ckfree((void *) connid->results);
	if (connid->null_string)
		ckfree(connid->null_string);
	if (connid->notice_command)
		Tcl_DecrRefCount(connid->notice_command);
	if (connid->copyBuf)
		PQfreemem(connid->copyBuf);

	/* Release associated notify info */
	while ((notifies = connid->notify_list) != NULL)
	{
		connid->notify_list = notifies->next;
		for (entry = Tcl_FirstHashEntry(&notifies->notify_hash, &hsearch);
			 entry != NULL;
			 entry = Tcl_NextHashEntry(&hsearch))
		{
			notifCmd = (Pg_notify_command *)Tcl_GetHashValue(entry);
			if (notifCmd->callback) ckfree(notifCmd->callback);
			ckfree((char *)notifCmd);
		}
		Tcl_DeleteHashTable(&notifies->notify_hash);
		if (notifies->conn_loss_cmd)
			ckfree((void *) notifies->conn_loss_cmd);
		if (notifies->interp)
			Tcl_DontCallWhenDeleted(notifies->interp, PgNotifyInterpDelete,
									(ClientData) notifies);
		ckfree((void *) notifies);
	}

	/*
	 * Turn off the Tcl event source for this connection, and delete any
	 * pending notify and connection-loss events.
	 */
	PgStopNotifyEventSource(connid, TRUE);

	/* Close the libpq connection too */
	PQfinish(connid->conn);
	connid->conn = NULL;

	/*
	 * Kill the notifier channel, too.	We must not do this until after
	 * we've closed the libpq connection, because Tcl will try to close
	 * the socket itself!
	 *
	 * XXX Unfortunately, while this works fine if we are closing due to
	 * explicit pg_disconnect, all Tcl versions through 8.4.1 dump core if
	 * we try to do it during interpreter shutdown.  Not clear why. For
	 * now, we kill the channel during pg_disconnect, but during interp
	 * shutdown we just accept leakage of the (fairly small) amount of
	 * memory taken for the channel state representation. (Note we are not
	 * leaking a socket, since libpq closed that already.) We tell the
	 * difference between pg_disconnect and interpreter shutdown by
	 * testing for interp != NULL, which is an undocumented but apparently
	 * safe way to tell.
	 */
	if (connid->notifier_channel != NULL && interp != NULL)
		Tcl_UnregisterChannel(NULL, connid->notifier_channel);

	/*
	 * Clear any async result callback, if present.
	 */
	PgClearResultCallback(connid);

	/*
	 * We must use Tcl_EventuallyFree because we don't want the connid
	 * struct to vanish instantly if Pg_Notify_EventProc is active for it.
	 * (Otherwise, closing the connection from inside a pg_listen callback
	 * could lead to coredump.)  Pg_Notify_EventProc can detect that the
	 * connection has been deleted from under it by checking connid->conn.
	 */
	Tcl_EventuallyFree((ClientData) connid, TCL_DYNAMIC);

	return 0;
}


/*
 * Find a slot for a new result id.  If the table is full, expand it by
 * a factor of 2.  However, do not expand past the hard max, as the client
 * is probably just not clearing result handles like they should.
 * Returns the result id slot number, or -1 on error.
 */
int
PgSetResultId(Tcl_Interp *interp, CONST84 char *connid_c, PGresult *res)
{
	Tcl_Channel conn_chan;
	Pg_ConnectionId *connid;
	int			resid,
				i;
	char		buf[32];


	conn_chan = Tcl_GetChannel(interp, connid_c, 0);
	if (conn_chan == NULL)
		return -1;
	connid = (Pg_ConnectionId *) Tcl_GetChannelInstanceData(conn_chan);

	/* search, starting at slot after the last one used */
	resid = connid->res_last;
	for (;;)
	{
		/* advance, with wraparound */
		if (++resid >= connid->res_max)
			resid = 0;
		/* this slot empty? */
		if (!connid->results[resid])
		{
			connid->res_last = resid;
			break;				/* success exit */
		}
		/* checked all slots? */
		if (resid == connid->res_last)
			break;				/* failure exit */
	}

	if (connid->results[resid])
	{
		/* no free slot found, so try to enlarge array */
		if (connid->res_max >= connid->res_hardmax)
		{
			Tcl_SetResult(interp, "hard limit on result handles reached",
						  TCL_STATIC);
			return -1;
		}
		connid->res_last = resid = connid->res_max;
		connid->res_max *= 2;
		if (connid->res_max > connid->res_hardmax)
			connid->res_max = connid->res_hardmax;
		connid->results = (PGresult **) ckrealloc((void *) connid->results,
								   sizeof(PGresult *) * connid->res_max);
		for (i = connid->res_last; i < connid->res_max; i++)
			connid->results[i] = NULL;
	}

	connid->results[resid] = res;
	sprintf(buf, "%s.%d", connid_c, resid);
	Tcl_SetResult(interp, buf, TCL_VOLATILE);
	return resid;
}

static int
getresid(Tcl_Interp *interp, CONST84 char *id, Pg_ConnectionId ** connid_p)
{
	Tcl_Channel conn_chan;
	char	   *mark;
	int			resid;
	Pg_ConnectionId *connid;

	if (!(mark = strchr(id, '.')))
		return -1;
	*mark = '\0';
	conn_chan = Tcl_GetChannel(interp, id, 0);
	*mark = '.';
	if (conn_chan == NULL || Tcl_GetChannelType(conn_chan) != &Pg_ConnType)
	{
		Tcl_SetResult(interp, "Invalid connection handle", TCL_STATIC);
		return -1;
	}

	if (Tcl_GetInt(interp, mark + 1, &resid) == TCL_ERROR)
	{
		Tcl_SetResult(interp, "Poorly formated result handle", TCL_STATIC);
		return -1;
	}

	connid = (Pg_ConnectionId *) Tcl_GetChannelInstanceData(conn_chan);

	if (resid < 0 || resid >= connid->res_max || connid->results[resid] == NULL)
	{
		Tcl_SetResult(interp, "Invalid result handle", TCL_STATIC);
		return -1;
	}

	*connid_p = connid;

	return resid;
}


/*
 * Get back the result pointer from the Id
 */
PGresult *
PgGetResultId(Tcl_Interp *interp, CONST84 char *id)
{
	Pg_ConnectionId *connid;
	int			resid;

	if (!id)
		return NULL;
	resid = getresid(interp, id, &connid);
	if (resid == -1)
		return NULL;
	return connid->results[resid];
}


/*
 * Remove a result Id from the hash tables
 */
void
PgDelResultId(Tcl_Interp *interp, CONST84 char *id)
{
	Pg_ConnectionId *connid;
	int			resid;

	resid = getresid(interp, id, &connid);
	if (resid == -1)
		return;
	connid->results[resid] = 0;
}


/*
 * Get the connection Id from the result Id
 */
int
PgGetConnByResultId(Tcl_Interp *interp, CONST84 char *resid_c)
{
	char	   *mark;
	Tcl_Channel conn_chan;

	if (!(mark = strchr(resid_c, '.')))
		goto error_out;
	*mark = '\0';
	conn_chan = Tcl_GetChannel(interp, resid_c, 0);
	*mark = '.';
	if (conn_chan && Tcl_GetChannelType(conn_chan) == &Pg_ConnType)
	{
		Tcl_SetResult(interp, (char *) Tcl_GetChannelName(conn_chan),
					  TCL_VOLATILE);
		return TCL_OK;
	}

error_out:
	Tcl_ResetResult(interp);
	Tcl_AppendResult(interp, resid_c, " is not a valid connection\n", 0);
	return TCL_ERROR;
}




/*-------------------------------------------
  Notify event source

  These functions allow asynchronous notify messages arriving from
  the SQL server to be dispatched as Tcl events.  See the Tcl
  Notifier(3) man page for more info.

  The main trick in this code is that we have to cope with status changes
  between the queueing and the execution of a Tcl event.  For example,
  if the user changes or cancels the pg_listen callback command, we should
  use the new setting; we do that by not resolving the notify relation
  name until the last possible moment.
  We also have to handle closure of the channel or deletion of the interpreter
  to be used for the callback (note that with multiple interpreters,
  the channel can outlive the interpreter it was created by!)
  Upon closure of the channel, we immediately delete the file event handler
  for it, which has the effect of disabling any file-ready events that might
  be hanging about in the Tcl event queue.	But for interpreter deletion,
  we just set any matching interp pointers in the Pg_TclNotifies list to NULL.
  The list item stays around until the connection is deleted.  (This avoids
  trouble with walking through a list whose members may get deleted under us.)

  In the current design, Pg_Notify_FileHandler is a file handler that
  we establish by calling Tcl_CreateFileHandler().	It gets invoked from
  the Tcl event loop whenever the underlying PGconn's socket is read-ready.
  We suck up any available data (to clear the OS-level read-ready condition)
  and then transfer any available PGnotify events into the Tcl event queue.
  Eventually these events will be dispatched to Pg_Notify_EventProc.  When
  we do an ordinary PQexec, we must also transfer PGnotify events into Tcl's
  event queue, since libpq might have read them when we weren't looking.
  ------------------------------------------*/

typedef struct
{
	Tcl_Event	header;			/* Standard Tcl event info */
	PGnotify   *notify;			/* Notify event from libpq, or NULL */
	/* We use a NULL notify pointer to denote a connection-loss event */
	Pg_ConnectionId *connid;	/* Connection for server */
}	NotifyEvent;

/* Dispatch a NotifyEvent that has reached the front of the event queue */

static int
Pg_Notify_EventProc(Tcl_Event *evPtr, int flags)
{
	NotifyEvent *event = (NotifyEvent *) evPtr;
	Pg_TclNotifies *notifies;
	char	   *callback;
    Tcl_Obj	   *callbackobj;
	Pg_notify_command *notifCmd = NULL; /* Init to avoid gcc warning */

	/* We classify SQL notifies as Tcl file events. */
	if (!(flags & TCL_FILE_EVENTS))
		return 0;

	/* If connection's been closed, just forget the whole thing. */
	if (event->connid == NULL)
	{
		if (event->notify)
			PQfreemem(event->notify);
		return 1;
	}

	/*
	 * Preserve/Release to ensure the connection struct doesn't disappear
	 * underneath us.
	 */
	Tcl_Preserve((ClientData) event->connid);

	/*
	 * Loop for each interpreter that has ever registered on the
	 * connection. Each one can get a callback.
	 */

	for (notifies = event->connid->notify_list;
		 notifies != NULL;
		 notifies = notifies->next)
	{
		Tcl_Interp *interp = notifies->interp;

		if (interp == NULL)
			continue;			/* ignore deleted interpreter */

		/*
		 * Find the callback to be executed for this interpreter, if any.
		 */
		if (event->notify)
		{
			/* Ordinary NOTIFY event */
			Tcl_HashEntry *entry;

			entry = Tcl_FindHashEntry(&notifies->notify_hash,
									  event->notify->relname);
			if (entry == NULL)
				continue;		/* no pg_listen in this interpreter */
			notifCmd = (Pg_notify_command *) Tcl_GetHashValue(entry);
			callback = notifCmd->callback;
		}
		else
		{
			/* Connection-loss event */
			callback = notifies->conn_loss_cmd;
		}

		if (callback == NULL)
			continue;			/* nothing to do for this interpreter */

		/*
		 * We have to copy the callback string in case the user executes a
		 * new pg_listen or pg_on_connection_loss during the callback.
		 *
		 * If there is a payload (PostgreSQL >= 9.0) with the notification
		 * event, pass it as an additional argument. Note that the callback
		 * string may contain multiple arguments. Like all Tcl scripts, it
		 * must be a proper list. The payload is appended to it as a single
		 * list element, but only if it is not empty. The callback proc must
		 * accept an optional argument if handles payloads. (This is an
		 * attempt to remain compatible with PostgreSQL < 9.0 before there
		 * was a notification payload.)
		 */

		/* Copy the callback string as a Tcl object */
		callbackobj = Tcl_NewStringObj(callback, -1);
		Tcl_IncrRefCount(callbackobj);

		/*
		 * If a notification event was requested with PID (pg_listen -pid),
		 * append the PID to the command string.
		 * Note this (or the next block) will convert the command to a list.
		 */
		if (event->notify && notifCmd->use_pid)
		{
			Tcl_Obj *pid_obj = Tcl_NewIntObj(event->notify->be_pid);
			Tcl_IncrRefCount(pid_obj);
			Tcl_ListObjAppendElement(interp, callbackobj, pid_obj);
			Tcl_DecrRefCount(pid_obj);
		}

		/* 
		 * If a notification event came with a non-empty payload, append it
		 * to the command string, as a single argument. Note an empty
		 * payload is not passed to the command, for compatibility with
		 * older PostgreSQL versions that do not support the payload.
		 */
		if (event->notify && event->notify->extra && *event->notify->extra)
		{
			Tcl_Obj *payload = Tcl_NewStringObj(event->notify->extra, -1);
			Tcl_IncrRefCount(payload);
			Tcl_ListObjAppendElement(interp, callbackobj, payload);
			Tcl_DecrRefCount(payload);
		}

		/*
		 * Execute the callback.
		 */
		Tcl_Preserve((ClientData) interp);
		if (Tcl_EvalObjEx(interp, callbackobj,
							TCL_EVAL_GLOBAL+TCL_EVAL_DIRECT) != TCL_OK)
		{
			if (event->notify)
				Tcl_AddErrorInfo(interp, "\n    (\"pg_listen\" script)");
			else
				Tcl_AddErrorInfo(interp, "\n    (\"pg_on_connection_loss\" script)");
			Tcl_BackgroundError(interp);
		}
		Tcl_DecrRefCount(callbackobj);
		Tcl_Release((ClientData) interp);

		/*
		 * Check for the possibility that the callback closed the
		 * connection.
		 */
		if (event->connid->conn == NULL)
			break;
	}

	Tcl_Release((ClientData) event->connid);

	if (event->notify)
		PQfreemem(event->notify);

	return 1;
}

/*
 * Transfer any notify events available from libpq into the Tcl event queue.
 * Note that this must be called after each PQexec (to capture notifies
 * that arrive during command execution) as well as in Pg_Notify_FileHandler
 * (to capture notifies that arrive when we're idle).
 */

void
PgNotifyTransferEvents(Pg_ConnectionId * connid)
{
	PGnotify   *notify;

	while ((notify = PQnotifies(connid->conn)) != NULL)
	{
		NotifyEvent *event = (NotifyEvent *) ckalloc(sizeof(NotifyEvent));

		event->header.proc = Pg_Notify_EventProc;
		event->notify = notify;
		event->connid = connid;
		Tcl_QueueEvent((Tcl_Event *) event, TCL_QUEUE_TAIL);
	}

	/*
	 * This is also a good place to check for unexpected closure of the
	 * connection (ie, backend crash), in which case we must shut down the
	 * notify event source to keep Tcl from trying to select() on the now-
	 * closed socket descriptor.  But don't kill on-connection-loss
	 * events; in fact, register one.
	 */
	if (PQsocket(connid->conn) < 0)
		PgConnLossTransferEvents(connid);
}

/*
 * Handle a connection-loss event
 */
void
PgConnLossTransferEvents(Pg_ConnectionId * connid)
{
	if (connid->notifier_running)
	{
		/* Put the on-connection-loss event in the Tcl queue */
		NotifyEvent *event = (NotifyEvent *) ckalloc(sizeof(NotifyEvent));

		event->header.proc = Pg_Notify_EventProc;
		event->notify = NULL;
		event->connid = connid;
		Tcl_QueueEvent((Tcl_Event *) event, TCL_QUEUE_TAIL);
	}

	/*
	 * Shut down the notify event source to keep Tcl from trying to
	 * select() on the now-closed socket descriptor.  And zap any
	 * unprocessed notify events ... but not, of course, the
	 * connection-loss event.
	 */
	PgStopNotifyEventSource(connid, FALSE);
}

/*
 * Cleanup code for coping when an interpreter or a channel is deleted.
 *
 * PgNotifyInterpDelete is registered as an interpreter deletion callback
 * for each extant Pg_TclNotifies structure.
 * NotifyEventDeleteProc is used by PgStopNotifyEventSource to cancel
 * pending Tcl NotifyEvents that reference a dying connection.
 */

void
PgNotifyInterpDelete(ClientData clientData, Tcl_Interp *interp)
{
	/* Mark the interpreter dead, but don't do anything else yet */
	Pg_TclNotifies *notifies = (Pg_TclNotifies *) clientData;

	notifies->interp = NULL;
}

/*
 * Comparison routines for detecting events to be removed by Tcl_DeleteEvents.
 * NB: In (at least) Tcl versions 7.6 through 8.0.3, there is a serious
 * bug in Tcl_DeleteEvents: if there are multiple events on the queue and
 * you tell it to delete the last one, the event list pointers get corrupted,
 * with the result that events queued immediately thereafter get lost.
 * Therefore we daren't tell Tcl_DeleteEvents to actually delete anything!
 * We simply use it as a way of scanning the event queue.  Events matching
 * the about-to-be-deleted connid are marked dead by setting their connid
 * fields to NULL.	Then Pg_Notify_EventProc will do nothing when those
 * events are executed.
 */
static int
NotifyEventDeleteProc(Tcl_Event *evPtr, ClientData clientData)
{
	Pg_ConnectionId *connid = (Pg_ConnectionId *) clientData;

	if (evPtr->proc == Pg_Notify_EventProc)
	{
		NotifyEvent *event = (NotifyEvent *) evPtr;

		if (event->connid == connid && event->notify != NULL)
			event->connid = NULL;
	}
	return 0;
}

/* This version deletes on-connection-loss events too */
static int
AllNotifyEventDeleteProc(Tcl_Event *evPtr, ClientData clientData)
{
	Pg_ConnectionId *connid = (Pg_ConnectionId *) clientData;

	if (evPtr->proc == Pg_Notify_EventProc)
	{
		NotifyEvent *event = (NotifyEvent *) evPtr;

		if (event->connid == connid)
			event->connid = NULL;
	}
	return 0;
}

/*
 * Clear asynchronous query result callback.
 */
void
PgClearResultCallback(Pg_ConnectionId *conn)
{
	if (conn->callbackPtr)    {
	    Tcl_DecrRefCount(conn->callbackPtr);
	    conn->callbackPtr = NULL;
	}
	if (conn->callbackInterp) {
	    Tcl_Release((ClientData) conn->callbackInterp);
	    conn->callbackInterp = NULL;
	}
}

/*
 * Asynchronous query result callback: called on asynchronous query completion
 * if an event is registered for callback on query completion.
 * This feature was originally implemented by msofer.
 */

static int
Pg_Result_EventProc(Tcl_Event *evPtr, int flags)
{
	NotifyEvent *event = (NotifyEvent *) evPtr;

	/* Results can only come from file events. */
	if (!(flags & TCL_FILE_EVENTS))
		return 0;

	/* Only process if the connection is still open. */
	if (event->connid) {
		Pg_ConnectionId *connid = event->connid;
		Tcl_Obj *callbackPtr = connid->callbackPtr;
		Tcl_Interp *interp = connid->callbackInterp;

		/*
		 * Clear the result callback for this connection, so that the callback
		 * script may safely establish a new one.
		 */
		connid->callbackPtr = NULL;
		connid->callbackInterp = NULL;

		if (callbackPtr && interp) {
			if (Tcl_EvalObjEx(interp, callbackPtr, TCL_EVAL_GLOBAL) != TCL_OK) {
				Tcl_BackgroundError(interp);
			}
			Tcl_DecrRefCount(callbackPtr);
			Tcl_Release((ClientData) interp);
		}
	}
	/* never deliver this event twice */
	return 1;
}

/*
 * File handler callback: called when Tcl has detected read-ready on socket.
 * The clientData is a pointer to the associated connection.
 * We can ignore the condition mask since we only ever ask about read-ready.
 */

static void
Pg_Notify_FileHandler(ClientData clientData, int mask)
{
	Pg_ConnectionId *connid = (Pg_ConnectionId *) clientData;

	/*
	 * Consume any data available from the SQL server (this just buffers
	 * it internally to libpq; but it will clear the read-ready
	 * condition).
	 */
	if (PQconsumeInput(connid->conn))
	{
		/* Transfer notify events from libpq to Tcl event queue. */
		PgNotifyTransferEvents(connid);

		/*
		 * If the connection is still alive, and if there is a
		 * callback for results, check if a result is ready. If it is,
		 * transfer the event to the Tcl event queue.
		 */
		if ((PQsocket(connid->conn) >= 0)
			&& connid->callbackPtr
			&& !PQisBusy(connid->conn)) {

			NotifyEvent *event = (NotifyEvent *) ckalloc(sizeof(NotifyEvent));

			event->header.proc = Pg_Result_EventProc;
			event->notify = NULL;
			event->connid = connid;
			Tcl_QueueEvent((Tcl_Event *) event, TCL_QUEUE_TAIL);
		}
	}
	else
	{
		/*
		 * If there is no input but we have read-ready, assume this means
		 * we lost the connection.
		 */
		PgConnLossTransferEvents(connid);
	}
}

/*
 * Start and stop the notify event source for a connection.
 *
 * We do not bother to run the notifier unless at least one pg_listen
 * or pg_on_connection_loss has been executed on the connection.  Currently,
 * once started the notifier is run until the connection is closed.
 *
 * FIXME: if PQreset is executed on the underlying PGconn, the active
 * socket number could change.	How and when should we test for this
 * and update the Tcl file handler linkage?  (For that matter, we'd
 * also have to reissue LISTEN commands for active LISTENs, since the
 * new backend won't know about 'em.  I'm leaving this problem for
 * another day.)
 */

void
PgStartNotifyEventSource(Pg_ConnectionId * connid)
{
	/* Start the notify event source if it isn't already running */
	if (!connid->notifier_running)
	{
		int			pqsock = PQsocket(connid->conn);

		if (pqsock >= 0)
		{
			Tcl_CreateChannelHandler(connid->notifier_channel,
									 TCL_READABLE,
									 Pg_Notify_FileHandler,
									 (ClientData) connid);
			connid->notifier_running = 1;
		}
	}
}

void
PgStopNotifyEventSource(Pg_ConnectionId * connid, char allevents)
{
	/* Remove the event source */
	if (connid->notifier_running)
	{
		Tcl_DeleteChannelHandler(connid->notifier_channel,
								 Pg_Notify_FileHandler,
								 (ClientData) connid);
		connid->notifier_running = 0;
	}

	/* Kill queued Tcl events that reference this channel */
	if (allevents)
		Tcl_DeleteEvents(AllNotifyEventDeleteProc, (ClientData) connid);
	else
		Tcl_DeleteEvents(NotifyEventDeleteProc, (ClientData) connid);
}
