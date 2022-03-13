/*
 * Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com>
 * Copyright (C) 2000 Ajuba Solutions
 *
 * TLS (aka SSL) Channel - can be layered on any bi-directional
 * Tcl_Channel (Note: Requires Trf Core Patch)
 *
 * This was built from scratch based upon observation of OpenSSL 0.9.2B
 *
 * Addition credit is due for Andreas Kupries (a.kupries@westend.com), for
 * providing the Tcl_ReplaceChannel mechanism and working closely with me
 * to enhance it to support full fileevent semantics.
 *
 * Also work done by the follow people provided the impetus to do this "right":
 *	tclSSL (Colin McCormack, Shared Technology)
 *	SSLtcl (Peter Antman)
 *
 */

#include "tlsInt.h"

/*
 * Forward declarations
 */
static int  TlsBlockModeProc _ANSI_ARGS_((ClientData instanceData, int mode));
static int  TlsCloseProc _ANSI_ARGS_((ClientData instanceData, Tcl_Interp *interp));
static int  TlsInputProc _ANSI_ARGS_((ClientData instanceData, char *buf, int bufSize, int *errorCodePtr));
static int  TlsOutputProc _ANSI_ARGS_((ClientData instanceData, CONST char *buf, int toWrite, int *errorCodePtr));
static int  TlsGetOptionProc _ANSI_ARGS_((ClientData instanceData, Tcl_Interp *interp, CONST84 char *optionName, Tcl_DString *dsPtr));
static void TlsWatchProc _ANSI_ARGS_((ClientData instanceData, int mask));
static int  TlsGetHandleProc _ANSI_ARGS_((ClientData instanceData, int direction, ClientData *handlePtr));
static int  TlsNotifyProc _ANSI_ARGS_((ClientData instanceData, int mask));
#if 0
static void TlsChannelHandler _ANSI_ARGS_((ClientData clientData, int mask));
#endif
static void TlsChannelHandlerTimer _ANSI_ARGS_((ClientData clientData));

/*
 * TLS Channel Type
 */
static Tcl_ChannelType *tlsChannelType = NULL;

/*
 *-------------------------------------------------------------------
 *
 * Tls_ChannelType --
 *
 *	Return the correct TLS channel driver info
 *
 * Results:
 *	The correct channel driver for the current version of Tcl.
 *
 * Side effects:
 *	None.
 *
 *-------------------------------------------------------------------
 */
Tcl_ChannelType *Tls_ChannelType(void) {
	unsigned int size;

	/*
	 * Initialize the channel type if necessary
	 */
	if (tlsChannelType == NULL) {
		/*
		 * Allocation of a new channeltype structure is not easy, because of
		 * the various verson of the core and subsequent changes to the
		 * structure. The main challenge is to allocate enough memory for
		 * modern versions even if this extsension is compiled against one
		 * of the older variant!
		 *
		 * (1) Versions before stubs (8.0.x) are simple, because they are
		 *     supported only if the extension is compiled against exactly
		 *     that version of the core.
		 *
		 * (2) With stubs we just determine the difference between the older
		 *     and modern variant and overallocate accordingly if compiled
		 *     against an older variant.
		 */
		size = sizeof(Tcl_ChannelType); /* Base size */

		tlsChannelType = (Tcl_ChannelType *) ckalloc(size);
		memset((VOID *) tlsChannelType, 0, size);

		/*
		 * Common elements of the structure (no changes in location or name)
		 * close2Proc, seekProc, setOptionProc stay NULL.
		 */

		tlsChannelType->typeName	= "tls";
		tlsChannelType->closeProc	= TlsCloseProc;
		tlsChannelType->inputProc	= TlsInputProc;
		tlsChannelType->outputProc	= TlsOutputProc;
		tlsChannelType->getOptionProc	= TlsGetOptionProc;
		tlsChannelType->watchProc	= TlsWatchProc;
		tlsChannelType->getHandleProc	= TlsGetHandleProc;

		/*
		 * Compiled against 8.3.2+. Direct access to all elements possible. Use
		 * channelTypeVersion information to select the values to use.
		 */

		/*
		 * For the 8.3.2 core we present ourselves as a version 2
		 * driver. This means a special value in version (ex
		 * blockModeProc), blockModeProc in a different place and of
		 * course usage of the handlerProc.
		 */
		tlsChannelType->version       = TCL_CHANNEL_VERSION_2;
		tlsChannelType->blockModeProc = TlsBlockModeProc;
		tlsChannelType->handlerProc   = TlsNotifyProc;
	}

	return(tlsChannelType);
}

/*
 *-------------------------------------------------------------------
 *
 * TlsBlockModeProc --
 *
 *	This procedure is invoked by the generic IO level
 *       to set blocking and nonblocking modes
 * Results:
 *	0 if successful, errno when failed.
 *
 * Side effects:
 *	Sets the device into blocking or nonblocking mode.
 *
 *-------------------------------------------------------------------
 */
static int TlsBlockModeProc(ClientData instanceData, int mode) {
	State *statePtr = (State *) instanceData;

	if (mode == TCL_MODE_NONBLOCKING) {
		statePtr->flags |= TLS_TCL_ASYNC;
	} else {
		statePtr->flags &= ~(TLS_TCL_ASYNC);
	}

	return(0);
}

/*
 *-------------------------------------------------------------------
 *
 * TlsCloseProc --
 *
 *	This procedure is invoked by the generic IO level to perform
 *	channel-type-specific cleanup when a SSL socket based channel
 *	is closed.
 *
 *	Note: we leave the underlying socket alone, is this right?
 *
 * Results:
 *	0 if successful, the value of Tcl_GetErrno() if failed.
 *
 * Side effects:
 *	Closes the socket of the channel.
 *
 *-------------------------------------------------------------------
 */
static int TlsCloseProc(ClientData instanceData, Tcl_Interp *interp) {
	State *statePtr = (State *) instanceData;

	dprintf("TlsCloseProc(%p)", (void *) statePtr);

	Tls_Clean(statePtr);
	Tcl_EventuallyFree((ClientData)statePtr, Tls_Free);

	dprintf("Returning TCL_OK");

	return(TCL_OK);

	/* Interp is unused. */
	interp = interp;
}

/*
 *------------------------------------------------------*
 *
 *	Tls_WaitForConnect --
 *
 *	Sideeffects:
 *		Issues SSL_accept or SSL_connect
 *
 *	Result:
 *		None.
 *
 *------------------------------------------------------*
 */
int Tls_WaitForConnect(State *statePtr, int *errorCodePtr, int handshakeFailureIsPermanent) {
	unsigned long backingError;
	int err, rc;
	int bioShouldRetry;

	dprintf("WaitForConnect(%p)", (void *) statePtr);
	dprintFlags(statePtr);

	if (!(statePtr->flags & TLS_TCL_INIT)) {
		dprintf("Tls_WaitForConnect called on already initialized channel -- returning with immediate success");
		*errorCodePtr = 0;
		return(0);
	}

	if (statePtr->flags & TLS_TCL_HANDSHAKE_FAILED) {
		/*
		 * Different types of operations have different requirements
		 * SSL being established
		 */
		if (handshakeFailureIsPermanent) {
			dprintf("Asked to wait for a TLS handshake that has already failed.  Returning fatal error");
			*errorCodePtr = ECONNABORTED;
		} else {
			dprintf("Asked to wait for a TLS handshake that has already failed.  Returning soft error");
			*errorCodePtr = ECONNRESET;
		}
		return(-1);
	}

	for (;;) {
		/* Not initialized yet! */
		if (statePtr->flags & TLS_TCL_SERVER) {
			dprintf("Calling SSL_accept()");

			err = SSL_accept(statePtr->ssl);
		} else {
			dprintf("Calling SSL_connect()");

			err = SSL_connect(statePtr->ssl);
		}

		if (err > 0) {
			dprintf("That seems to have gone okay");

			err = BIO_flush(statePtr->bio);

			if (err <= 0) {
				dprintf("Flushing the lower layers failed, this will probably terminate this session");
			}
		}

		rc = SSL_get_error(statePtr->ssl, err);

		dprintf("Got error: %i (rc = %i)", err, rc);

		bioShouldRetry = 0;
		if (err <= 0) {
			if (rc == SSL_ERROR_WANT_CONNECT || rc == SSL_ERROR_WANT_ACCEPT || rc == SSL_ERROR_WANT_READ || rc == SSL_ERROR_WANT_WRITE) {
				bioShouldRetry = 1;
			} else if (BIO_should_retry(statePtr->bio)) {
				bioShouldRetry = 1;
			} else if (rc == SSL_ERROR_SYSCALL && Tcl_GetErrno() == EAGAIN) {
				bioShouldRetry = 1;
			}
		} else {
			if (!SSL_is_init_finished(statePtr->ssl)) {
				bioShouldRetry = 1;
			}
		}

		if (bioShouldRetry) {
			dprintf("The I/O did not complete -- but we should try it again");

			if (statePtr->flags & TLS_TCL_ASYNC) {
				dprintf("Returning EAGAIN so that it can be retried later");

				*errorCodePtr = EAGAIN;

				return(-1);
			} else {
				dprintf("Doing so now");

				continue;
			}
		}

		dprintf("We have either completely established the session or completely failed it -- there is no more need to ever retry it though");
		break;
	}


	*errorCodePtr = EINVAL;

	switch (rc) {
		case SSL_ERROR_NONE:
			/* The connection is up, we are done here */
			dprintf("The connection is up");
			break;
		case SSL_ERROR_ZERO_RETURN:
			dprintf("SSL_ERROR_ZERO_RETURN: Connect returned an invalid value...")
			return(-1);
		case SSL_ERROR_SYSCALL:
			backingError = ERR_get_error();

			if (backingError == 0 && err == 0) {
				dprintf("EOF reached")
				*errorCodePtr = ECONNRESET;
			} else if (backingError == 0 && err == -1) {
				dprintf("I/O error occured (errno = %lu)", (unsigned long) Tcl_GetErrno());
				*errorCodePtr = Tcl_GetErrno();
				if (*errorCodePtr == ECONNRESET) {
					*errorCodePtr = ECONNABORTED;
				}
			} else {
				dprintf("I/O error occured (backingError = %lu)", backingError);
				*errorCodePtr = backingError;
				if (*errorCodePtr == ECONNRESET) {
					*errorCodePtr = ECONNABORTED;
				}
			}

			statePtr->flags |= TLS_TCL_HANDSHAKE_FAILED;

			return(-1);
		case SSL_ERROR_SSL:
			dprintf("Got permanent fatal SSL error, aborting immediately");
			Tls_Error(statePtr, (char *)ERR_reason_error_string(ERR_get_error()));
			statePtr->flags |= TLS_TCL_HANDSHAKE_FAILED;
			*errorCodePtr = ECONNABORTED;
			return(-1);
		case SSL_ERROR_WANT_CONNECT:
		case SSL_ERROR_WANT_ACCEPT:
		case SSL_ERROR_WANT_X509_LOOKUP:
		default:
			dprintf("We got a confusing reply: %i", rc);
			*errorCodePtr = Tcl_GetErrno();
			dprintf("ERR(%d, %d) ", rc, *errorCodePtr);
			return(-1);
	}

#if 0
	if (statePtr->flags & TLS_TCL_SERVER) {
		dprintf("This is an TLS server, checking the certificate for the peer");

		err = SSL_get_verify_result(statePtr->ssl);
		if (err != X509_V_OK) {
			dprintf("Invalid certificate, returning in failure");

			Tls_Error(statePtr, (char *)X509_verify_cert_error_string(err));
			statePtr->flags |= TLS_TCL_HANDSHAKE_FAILED;
			*errorCodePtr = ECONNABORTED;
			return(-1);
		}
	}
#endif

	dprintf("Removing the \"TLS_TCL_INIT\" flag since we have completed the handshake");
	statePtr->flags &= ~TLS_TCL_INIT;

	dprintf("Returning in success");
	*errorCodePtr = 0;

	return(0);
}

/*
 *-------------------------------------------------------------------
 *
 * TlsInputProc --
 *
 *	This procedure is invoked by the generic IO level
 *       to read input from a SSL socket based channel.
 *
 * Results:
 *	The number of bytes read is returned or -1 on error. An output
 *	argument contains the POSIX error code on error, or zero if no
 *	error occurred.
 *
 * Side effects:
 *	Reads input from the input device of the channel.
 *
 *-------------------------------------------------------------------
 */

static int TlsInputProc(ClientData instanceData, char *buf, int bufSize, int *errorCodePtr) {
	unsigned long backingError;
	State *statePtr = (State *) instanceData;
	int bytesRead;
	int tlsConnect;
	int err;

	*errorCodePtr = 0;

	dprintf("BIO_read(%d)", bufSize);

	if (statePtr->flags & TLS_TCL_CALLBACK) {
		/* don't process any bytes while verify callback is running */
		dprintf("Callback is running, reading 0 bytes");
		return(0);
	}

	dprintf("Calling Tls_WaitForConnect");
	tlsConnect = Tls_WaitForConnect(statePtr, errorCodePtr, 0);
	if (tlsConnect < 0) {
		dprintf("Got an error waiting to connect (tlsConnect = %i, *errorCodePtr = %i)", tlsConnect, *errorCodePtr);

		bytesRead = -1;
		if (*errorCodePtr == ECONNRESET) {
			dprintf("Got connection reset");
			/* Soft EOF */
			*errorCodePtr = 0;
			bytesRead = 0;
		}

		return(bytesRead);
	}

	/*
	 * We need to clear the SSL error stack now because we sometimes reach
	 * this function with leftover errors in the stack.  If BIO_read
	 * returns -1 and intends EAGAIN, there is a leftover error, it will be
	 * misconstrued as an error, not EAGAIN.
	 *
	 * Alternatively, we may want to handle the <0 return codes from
	 * BIO_read specially (as advised in the RSA docs).  TLS's lower level BIO
	 * functions play with the retry flags though, and this seems to work
	 * correctly.  Similar fix in TlsOutputProc. - hobbs
	 */
	ERR_clear_error();
	bytesRead = BIO_read(statePtr->bio, buf, bufSize);
	dprintf("BIO_read -> %d", bytesRead);

	err = SSL_get_error(statePtr->ssl, bytesRead);

#if 0
	if (bytesRead <= 0) {
		if (BIO_should_retry(statePtr->bio)) {
			dprintf("I/O failed, will retry based on EAGAIN");
			*errorCodePtr = EAGAIN;
		}
	}
#endif

	switch (err) {
		case SSL_ERROR_NONE:
			dprintBuffer(buf, bytesRead);
			break;
		case SSL_ERROR_SSL:
			dprintf("SSL negotiation error, indicating that the connection has been aborted");

			Tls_Error(statePtr, TCLTLS_SSL_ERROR(statePtr->ssl, bytesRead));
			*errorCodePtr = ECONNABORTED;
			bytesRead = -1;

			break;
		case SSL_ERROR_SYSCALL:
			backingError = ERR_get_error();

			if (backingError == 0 && bytesRead == 0) {
				dprintf("EOF reached")
				*errorCodePtr = 0;
				bytesRead = 0;
			} else if (backingError == 0 && bytesRead == -1) {
				dprintf("I/O error occured (errno = %lu)", (unsigned long) Tcl_GetErrno());
				*errorCodePtr = Tcl_GetErrno();
				bytesRead = -1;
			} else {
				dprintf("I/O error occured (backingError = %lu)", backingError);
				*errorCodePtr = backingError;
				bytesRead = -1;
			}

			break;
		case SSL_ERROR_ZERO_RETURN:
			dprintf("Got SSL_ERROR_ZERO_RETURN, this means an EOF has been reached");
			bytesRead = 0;
			*errorCodePtr = 0;
			break;
		case SSL_ERROR_WANT_READ:
			dprintf("Got SSL_ERROR_WANT_READ, mapping this to EAGAIN");
			bytesRead = -1;
			*errorCodePtr = EAGAIN;
			break;
		default:
			dprintf("Unknown error (err = %i), mapping to EOF", err);
			*errorCodePtr = 0;
			bytesRead = 0;
			break;
	}

	dprintf("Input(%d) -> %d [%d]", bufSize, bytesRead, *errorCodePtr);
	return(bytesRead);
}

/*
 *-------------------------------------------------------------------
 *
 * TlsOutputProc --
 *
 *	This procedure is invoked by the generic IO level
 *       to write output to a SSL socket based channel.
 *
 * Results:
 *	The number of bytes written is returned. An output argument is
 *	set to a POSIX error code if an error occurred, or zero.
 *
 * Side effects:
 *	Writes output on the output device of the channel.
 *
 *-------------------------------------------------------------------
 */

static int TlsOutputProc(ClientData instanceData, CONST char *buf, int toWrite, int *errorCodePtr) {
	unsigned long backingError;
	State *statePtr = (State *) instanceData;
	int written, err;
	int tlsConnect;

	*errorCodePtr = 0;

	dprintf("BIO_write(%p, %d)", (void *) statePtr, toWrite);
	dprintBuffer(buf, toWrite);

	if (statePtr->flags & TLS_TCL_CALLBACK) {
		dprintf("Don't process output while callbacks are running")
		written = -1;
		*errorCodePtr = EAGAIN;
		return(-1);
	}

	dprintf("Calling Tls_WaitForConnect");
	tlsConnect = Tls_WaitForConnect(statePtr, errorCodePtr, 1);
	if (tlsConnect < 0) {
		dprintf("Got an error waiting to connect (tlsConnect = %i, *errorCodePtr = %i)", tlsConnect, *errorCodePtr);

		written = -1;
		if (*errorCodePtr == ECONNRESET) {
			dprintf("Got connection reset");
			/* Soft EOF */
			*errorCodePtr = 0;
			written = 0;
		}

		return(written);
	}

	if (toWrite == 0) {
		dprintf("zero-write");
		err = BIO_flush(statePtr->bio);

		if (err <= 0) {
			dprintf("Flushing failed");

			*errorCodePtr = EIO;
			written = 0;
			return(-1);
		}

		written = 0;
		*errorCodePtr = 0;
		return(0);
	}

	/*
	 * We need to clear the SSL error stack now because we sometimes reach
	 * this function with leftover errors in the stack.  If BIO_write
	 * returns -1 and intends EAGAIN, there is a leftover error, it will be
	 * misconstrued as an error, not EAGAIN.
	 *
	 * Alternatively, we may want to handle the <0 return codes from
	 * BIO_write specially (as advised in the RSA docs).  TLS's lower level
	 * BIO functions play with the retry flags though, and this seems to
	 * work correctly.  Similar fix in TlsInputProc. - hobbs
	 */
	ERR_clear_error();
	written = BIO_write(statePtr->bio, buf, toWrite);
	dprintf("BIO_write(%p, %d) -> [%d]", (void *) statePtr, toWrite, written);

	err = SSL_get_error(statePtr->ssl, written);
	switch (err) {
		case SSL_ERROR_NONE:
			if (written < 0) {
				written = 0;
			}
			break;
		case SSL_ERROR_WANT_WRITE:
			dprintf("Got SSL_ERROR_WANT_WRITE, mapping it to EAGAIN");
			*errorCodePtr = EAGAIN;
			written = -1;
			break;
		case SSL_ERROR_WANT_READ:
			dprintf(" write R BLOCK");
			break;
		case SSL_ERROR_WANT_X509_LOOKUP:
			dprintf(" write X BLOCK");
			break;
		case SSL_ERROR_ZERO_RETURN:
			dprintf(" closed");
			written = 0;
			*errorCodePtr = 0;
			break;
		case SSL_ERROR_SYSCALL:
			backingError = ERR_get_error();

			if (backingError == 0 && written == 0) {
				dprintf("EOF reached")
				*errorCodePtr = 0;
				written = 0;
			} else if (backingError == 0 && written == -1) {
				dprintf("I/O error occured (errno = %lu)", (unsigned long) Tcl_GetErrno());
				*errorCodePtr = Tcl_GetErrno();
				written = -1;
			} else {
				dprintf("I/O error occured (backingError = %lu)", backingError);
				*errorCodePtr = backingError;
				written = -1;
			}

			break;
		case SSL_ERROR_SSL:
			Tls_Error(statePtr, TCLTLS_SSL_ERROR(statePtr->ssl, written));
			*errorCodePtr = ECONNABORTED;
			written = -1;
			break;
		default:
			dprintf(" unknown err: %d", err);
			break;
	}

	dprintf("Output(%d) -> %d", toWrite, written);
	return(written);
}

/*
 *-------------------------------------------------------------------
 *
 * TlsGetOptionProc --
 *
 *	Computes an option value for a SSL socket based channel, or a
 *	list of all options and their values.
 *
 * Results:
 *	A standard Tcl result. The value of the specified option or a
 *	list of all options and	their values is returned in the
 *	supplied DString.
 *
 * Side effects:
 *	None.
 *
 *-------------------------------------------------------------------
 */
static int
TlsGetOptionProc(ClientData instanceData,	/* Socket state. */
	Tcl_Interp *interp,		/* For errors - can be NULL. */
	CONST84 char *optionName,	/* Name of the option to
					 * retrieve the value for, or
					 * NULL to get all options and
					 * their values. */
	Tcl_DString *dsPtr)		/* Where to store the computed value
					 * initialized by caller. */
{
    State *statePtr = (State *) instanceData;

   Tcl_Channel downChan = Tls_GetParent(statePtr, TLS_TCL_FASTPATH);
   Tcl_DriverGetOptionProc *getOptionProc;

    getOptionProc = Tcl_ChannelGetOptionProc(Tcl_GetChannelType(downChan));
    if (getOptionProc != NULL) {
        return (*getOptionProc)(Tcl_GetChannelInstanceData(downChan), interp, optionName, dsPtr);
    } else if (optionName == (char*) NULL) {
        /*
         * Request is query for all options, this is ok.
         */
         return TCL_OK;
    }
    /*
     * Request for a specific option has to fail, we don't have any.
     */
    return TCL_ERROR;
}

/*
 *-------------------------------------------------------------------
 *
 * TlsWatchProc --
 *
 *	Initialize the notifier to watch Tcl_Files from this channel.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets up the notifier so that a future event on the channel
 *	will be seen by Tcl.
 *
 *-------------------------------------------------------------------
 */

static void
TlsWatchProc(ClientData instanceData,	/* The socket state. */
             int mask)			/* Events of interest; an OR-ed
                                         * combination of TCL_READABLE,
                                         * TCL_WRITABLE and TCL_EXCEPTION. */
{
    Tcl_Channel     downChan;
    State *statePtr = (State *) instanceData;

    dprintf("TlsWatchProc(0x%x)", mask);

    /* Pretend to be dead as long as the verify callback is running. 
     * Otherwise that callback could be invoked recursively. */
    if (statePtr->flags & TLS_TCL_CALLBACK) {
        dprintf("Callback is on-going, doing nothing");
        return;
    }

    dprintFlags(statePtr);

    downChan = Tls_GetParent(statePtr, TLS_TCL_FASTPATH);

    if (statePtr->flags & TLS_TCL_HANDSHAKE_FAILED) {
        dprintf("Asked to watch a socket with a failed handshake -- nothing can happen here");

	dprintf("Unregistering interest in the lower channel");
	(Tcl_GetChannelType(downChan))->watchProc(Tcl_GetChannelInstanceData(downChan), 0);

	statePtr->watchMask = 0;

        return;
    }

	statePtr->watchMask = mask;

	/* No channel handlers any more. We will be notified automatically
	 * about events on the channel below via a call to our
	 * 'TransformNotifyProc'. But we have to pass the interest down now.
	 * We are allowed to add additional 'interest' to the mask if we want
	 * to. But this transformation has no such interest. It just passes
	 * the request down, unchanged.
	 */


        dprintf("Registering our interest in the lower channel (chan=%p)", (void *) downChan);
	(Tcl_GetChannelType(downChan))
	    ->watchProc(Tcl_GetChannelInstanceData(downChan), mask);

	/*
	 * Management of the internal timer.
	 */

	if (statePtr->timer != (Tcl_TimerToken) NULL) {
            dprintf("A timer was found, deleting it");
	    Tcl_DeleteTimerHandler(statePtr->timer);
	    statePtr->timer = (Tcl_TimerToken) NULL;
	}

	if (mask & TCL_READABLE) {
		if (Tcl_InputBuffered(statePtr->self) > 0 || BIO_ctrl_pending(statePtr->bio) > 0) {
			/*
			 * There is interest in readable events and we actually have
			 * data waiting, so generate a timer to flush that.
			 */
			dprintf("Creating a new timer since data appears to be waiting");
			statePtr->timer = Tcl_CreateTimerHandler(TLS_TCL_DELAY, TlsChannelHandlerTimer, (ClientData) statePtr);
		}
	}
}

/*
 *-------------------------------------------------------------------
 *
 * TlsGetHandleProc --
 *
 *	Called from Tcl_GetChannelFile to retrieve o/s file handler
 *	from the SSL socket based channel.
 *
 * Results:
 *	The appropriate Tcl_File or NULL if not present. 
 *
 * Side effects:
 *	None.
 *
 *-------------------------------------------------------------------
 */
static int TlsGetHandleProc(ClientData instanceData, int direction, ClientData *handlePtr) {
	State *statePtr = (State *) instanceData;

	return(Tcl_GetChannelHandle(Tls_GetParent(statePtr, TLS_TCL_FASTPATH), direction, handlePtr));
}

/*
 *-------------------------------------------------------------------
 *
 * TlsNotifyProc --
 *
 *	Handler called by Tcl to inform us of activity
 *	on the underlying channel.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May process the incoming event by itself.
 *
 *-------------------------------------------------------------------
 */

static int TlsNotifyProc(ClientData instanceData, int mask) {
	State *statePtr = (State *) instanceData;
	int errorCode;

	/*
	 * An event occured in the underlying channel.  This
	 * transformation doesn't process such events thus returns the
	 * incoming mask unchanged.
	 */
	if (statePtr->timer != (Tcl_TimerToken) NULL) {
		/*
		 * Delete an existing timer. It was not fired, yet we are
		 * here, so the channel below generated such an event and we
		 * don't have to. The renewal of the interest after the
		 * execution of channel handlers will eventually cause us to
		 * recreate the timer (in WatchProc).
		 */
		Tcl_DeleteTimerHandler(statePtr->timer);
		statePtr->timer = (Tcl_TimerToken) NULL;
	}

	if (statePtr->flags & TLS_TCL_CALLBACK) {
		dprintf("Returning 0 due to callback");
		return 0;
	}

	dprintf("Calling Tls_WaitForConnect");
	errorCode = 0;
	if (Tls_WaitForConnect(statePtr, &errorCode, 1) < 0) {
		if (errorCode == EAGAIN) {
			dprintf("Async flag could be set (didn't check) and errorCode == EAGAIN:  Returning 0");

			return 0;
		}

		dprintf("Tls_WaitForConnect returned an error");
	}

	dprintf("Returning %i", mask);

	return(mask);
}

#if 0
/*
 *------------------------------------------------------*
 *
 *      TlsChannelHandler --
 *
 *      ------------------------------------------------*
 *      Handler called by Tcl as a result of
 *      Tcl_CreateChannelHandler - to inform us of activity
 *      on the underlying channel.
 *      ------------------------------------------------*
 *
 *      Sideeffects:
 *              May generate subsequent calls to
 *              Tcl_NotifyChannel.
 *
 *      Result:
 *              None.
 *
 *------------------------------------------------------*
 */

static void
TlsChannelHandler (clientData, mask)
    ClientData     clientData;
    int            mask;
{
    State *statePtr = (State *) clientData;

    dprintf("HANDLER(0x%x)", mask);
    Tcl_Preserve( (ClientData)statePtr);

    if (mask & TCL_READABLE) {
	BIO_set_flags(statePtr->p_bio, BIO_FLAGS_READ);
    } else {
	BIO_clear_flags(statePtr->p_bio, BIO_FLAGS_READ);
    }

    if (mask & TCL_WRITABLE) {
	BIO_set_flags(statePtr->p_bio, BIO_FLAGS_WRITE);
    } else {
	BIO_clear_flags(statePtr->p_bio, BIO_FLAGS_WRITE);
    }

    mask = 0;
    if (BIO_wpending(statePtr->bio)) {
	mask |= TCL_WRITABLE;
    }
    if (BIO_pending(statePtr->bio)) {
	mask |= TCL_READABLE;
    }

    /*
     * The following NotifyChannel calls seems to be important, but
     * we don't know why.  It looks like if the mask is ever non-zero
     * that it will enter an infinite loop.
     *
     * Notify the upper channel of the current BIO state so the event
     * continues to propagate up the chain.
     *
     * stanton: It looks like this could result in an infinite loop if
     * the upper channel doesn't cause ChannelHandler to be removed
     * before Tcl_NotifyChannel calls channel handlers on the lower channel.
     */
    
    Tcl_NotifyChannel(statePtr->self, mask);
    
    if (statePtr->timer != (Tcl_TimerToken)NULL) {
	Tcl_DeleteTimerHandler(statePtr->timer);
	statePtr->timer = (Tcl_TimerToken)NULL;
    }
    if ((mask & TCL_READABLE) && Tcl_InputBuffered(statePtr->self) > 0) {
	/*
	 * Data is waiting, flush it out in short time
	 */
	statePtr->timer = Tcl_CreateTimerHandler(TLS_TCL_DELAY,
		TlsChannelHandlerTimer, (ClientData) statePtr);
    }
    Tcl_Release( (ClientData)statePtr);
}
#endif

/*
 *------------------------------------------------------*
 *
 *	TlsChannelHandlerTimer --
 *
 *	------------------------------------------------*
 *	Called by the notifier (-> timer) to flush out
 *	information waiting in channel buffers.
 *	------------------------------------------------*
 *
 *	Sideeffects:
 *		As of 'TlsChannelHandler'.
 *
 *	Result:
 *		None.
 *
 *------------------------------------------------------*
 */

static void TlsChannelHandlerTimer(ClientData clientData) {
	State *statePtr = (State *) clientData;
	int mask = 0;

	dprintf("Called");

	statePtr->timer = (Tcl_TimerToken) NULL;

	if (BIO_wpending(statePtr->bio)) {
		dprintf("[chan=%p] BIO writable", statePtr->self);

		mask |= TCL_WRITABLE;
	}

	if (BIO_pending(statePtr->bio)) {
		dprintf("[chan=%p] BIO readable", statePtr->self);

		mask |= TCL_READABLE;
	}

	dprintf("Notifying ourselves");
	Tcl_NotifyChannel(statePtr->self, mask);

	dprintf("Returning");

	return;
}

Tcl_Channel Tls_GetParent(State *statePtr, int maskFlags) {
	dprintf("Requested to get parent of channel %p", statePtr->self);

	if ((statePtr->flags & ~maskFlags) & TLS_TCL_FASTPATH) {
		dprintf("Asked to get the parent channel while we are using FastPath -- returning NULL");
		return(NULL);
	}

	return(Tcl_GetStackedChannel(statePtr->self));
}
