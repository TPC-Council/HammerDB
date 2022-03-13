/* exp_log.c - logging routines and other things common to both Expect
   program and library.  Note that this file must NOT have any
   references to Tcl except for including tclInt.h
*/

#include "expect_cf.h"
#include <stdio.h>
/*#include <varargs.h>		tclInt.h drags in varargs.h.  Since Pyramid */
/*				objects to including varargs.h twice, just */
/*				omit this one. */
#include "tclInt.h"
#ifdef NO_STDLIB_H
#include "../compat/stdlib.h"
#else
#include <stdlib.h>		/* for malloc */
#endif
#include <ctype.h>

#include "expect_comm.h"
#include "exp_int.h"
#include "exp_rename.h"
#include "exp_command.h"
#include "exp_log.h"

typedef struct ThreadSpecificData {
    Tcl_Channel diagChannel;
    Tcl_DString diagFilename;
    int diagToStderr;

    Tcl_Channel logChannel;
    Tcl_DString logFilename;	/* if no name, then it came from -open or -leaveopen */
    int logAppend;
    int logLeaveOpen;
    int logAll;			/* if TRUE, write log of all interactions
				 * despite value of logUser - i.e., even if
				 * user is not seeing it (via stdout)
				 */
    int logUser;		/* TRUE if user sees interactions on stdout */
} ThreadSpecificData;

static Tcl_ThreadDataKey dataKey;

/*
 * create a reasonably large buffer for the bulk of the output routines
 * that are not too large
 */
static char bigbuf[2000];

static void expDiagWriteCharsUni _ANSI_ARGS_((Tcl_UniChar *str,int len));

/*
 * Following this are several functions that log the conversation.  Some
 * general notes on all of them:
 */

/*
 * ignore sprintf return value ("character count") because it's not
 * defined in terms of UTF so it would be misinterpreted if we passed
 * it on.
 */

/*
 * if necessary, they could be made more efficient by skipping vsprintf based
 * on booleans
 */

/* Most of them have multiple calls to printf-style functions.  */
/* At first glance, it seems stupid to reformat the same arguments again */
/* but we have no way of telling how long the formatted output will be */
/* and hence cannot allocate a buffer to do so. */
/* Fortunately, in production code, most of the duplicate reformatting */
/* will be skipped, since it is due to handling errors and debugging. */

/*
 * Name: expWriteBytesAndLogIfTtyU
 *
 * Output to channel (and log if channel is stdout or devtty)
 *
 * Returns: TCL_OK or TCL_ERROR;
 */

int
expWriteBytesAndLogIfTtyU(esPtr,buf,lenChars)
    ExpState *esPtr;
    Tcl_UniChar *buf;
    int lenChars;
{
    int wc;
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (esPtr->valid)
	wc = expWriteCharsUni(esPtr,buf,lenChars);

    if (tsdPtr->logChannel && ((esPtr->fdout == 1) || expDevttyIs(esPtr))) {
      Tcl_DString ds;
      Tcl_DStringInit (&ds);
      Tcl_UniCharToUtfDString (buf,lenChars,&ds);
      Tcl_WriteChars(tsdPtr->logChannel,Tcl_DStringValue (&ds), Tcl_DStringLength (&ds));
      Tcl_DStringFree (&ds);
    }
    return wc;
}

/*
 * Name: expLogDiagU
 *
 * Send to the Log (and Diag if open).  This is for writing to the log.
 * (In contrast, expDiagLog... is for writing diagnostics.)
 */

void
expLogDiagU(buf)
char *buf;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    expDiagWriteChars(buf,-1);
    if (tsdPtr->logChannel) {
	Tcl_WriteChars(tsdPtr->logChannel, buf, -1);
    }
}

/*
 * Name: expLogInteractionU
 *
 * Show chars to user if they've requested it, UNLESS they're seeing it
 * already because they're typing it and tty driver is echoing it.
 * Also send to Diag and Log if appropriate.
 */
void
expLogInteractionU(esPtr,buf,buflen)
    ExpState *esPtr;
    Tcl_UniChar *buf;
    int buflen;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (tsdPtr->logAll || (tsdPtr->logUser && tsdPtr->logChannel)) {
      Tcl_DString ds;
      Tcl_DStringInit (&ds);
      Tcl_UniCharToUtfDString (buf,buflen,&ds);
      Tcl_WriteChars(tsdPtr->logChannel,Tcl_DStringValue (&ds), Tcl_DStringLength (&ds));
      Tcl_DStringFree (&ds);
    }

    /* hmm.... if stdout is closed such as by disconnect, loguser
       should be forced FALSE */

    /* don't write to user if they're seeing it already, i.e., typing it! */
    if (tsdPtr->logUser && (!expStdinoutIs(esPtr)) && (!expDevttyIs(esPtr))) {
	ExpState *stdinout = expStdinoutGet();
	if (stdinout->valid) {
	    (void) expWriteCharsUni(stdinout,buf,buflen);
	}
    }
    expDiagWriteCharsUni(buf,buflen);
}

/* send to log if open */
/* send to stderr if debugging enabled */
/* use this for logging everything but the parent/child conversation */
/* (this turns out to be almost nothing) */
/* uppercase L differentiates if from math function of same name */
#define LOGUSER		(tsdPtr->logUser || force_stdout)
/*VARARGS*/
void
expStdoutLog TCL_VARARGS_DEF(int,arg1)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    int force_stdout;
    char *fmt;
    va_list args;

    force_stdout = TCL_VARARGS_START(int,arg1,args);
    fmt = va_arg(args,char *);

    if ((!tsdPtr->logUser) && (!force_stdout) && (!tsdPtr->logAll)) return;

    (void) vsprintf(bigbuf,fmt,args);
    expDiagWriteBytes(bigbuf,-1);
    if (tsdPtr->logAll || (LOGUSER && tsdPtr->logChannel)) Tcl_WriteChars(tsdPtr->logChannel,bigbuf,-1);
    if (LOGUSER) fprintf(stdout,"%s",bigbuf);
    va_end(args);
}

/* just like log but does no formatting */
/* send to log if open */
/* use this function for logging the parent/child conversation */
void
expStdoutLogU(buf,force_stdout)
char *buf;
int force_stdout;	/* override value of logUser */
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    int length;

    if ((!tsdPtr->logUser) && (!force_stdout) && (!tsdPtr->logAll)) return;

    length = strlen(buf);
    expDiagWriteBytes(buf,length);
    if (tsdPtr->logAll || (LOGUSER && tsdPtr->logChannel)) Tcl_WriteChars(tsdPtr->logChannel,buf,-1);
    if (LOGUSER) {
#if (TCL_MAJOR_VERSION > 8) || ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION >= 1))
      Tcl_WriteChars (Tcl_GetStdChannel (TCL_STDOUT), buf, length);
      Tcl_Flush      (Tcl_GetStdChannel (TCL_STDOUT));
#else
      fwrite(buf,1,length,stdout);
#endif
    }
}

/* send to log if open */
/* send to stderr */
/* use this function for error conditions */
/*VARARGS*/
void
expErrorLog TCL_VARARGS_DEF(char *,arg1)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    char *fmt;
    va_list args;

    fmt = TCL_VARARGS_START(char *,arg1,args);
    (void) vsprintf(bigbuf,fmt,args);

    expDiagWriteChars(bigbuf,-1);
    fprintf(stderr,"%s",bigbuf);
    if (tsdPtr->logChannel) Tcl_WriteChars(tsdPtr->logChannel,bigbuf,-1);
    
    va_end(args);
}

/* just like errorlog but does no formatting */
/* send to log if open */
/* use this function for logging the parent/child conversation */
/*ARGSUSED*/
void
expErrorLogU(buf)
char *buf;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    int length = strlen(buf);
    fwrite(buf,1,length,stderr);
    expDiagWriteChars(buf,-1);
    if (tsdPtr->logChannel) Tcl_WriteChars(tsdPtr->logChannel,buf,-1);
}



/* send diagnostics to Diag, Log, and stderr */
/* use this function for recording unusual things in the log */
/*VARARGS*/
void
expDiagLog TCL_VARARGS_DEF(char *,arg1)
{
    char *fmt;
    va_list args;

    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if ((tsdPtr->diagToStderr == 0) && (tsdPtr->diagChannel == 0)) return;

    fmt = TCL_VARARGS_START(char *,arg1,args);

    (void) vsprintf(bigbuf,fmt,args);

    expDiagWriteBytes(bigbuf,-1);
    if (tsdPtr->diagToStderr) {
	fprintf(stderr,"%s",bigbuf);
	if (tsdPtr->logChannel) Tcl_WriteChars(tsdPtr->logChannel,bigbuf,-1);
    }

    va_end(args);
}


/* expDiagLog for unformatted strings
   this also takes care of arbitrary large strings */
void
expDiagLogU(str)
char *str;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if ((tsdPtr->diagToStderr == 0) && (tsdPtr->diagChannel == 0)) return;

    expDiagWriteBytes(str,-1);

    if (tsdPtr->diagToStderr) {
      fprintf(stderr,"%s",str);
      if (tsdPtr->logChannel) Tcl_WriteChars(tsdPtr->logChannel,str,-1);
    }
}

/* expPrintf prints to stderr.  It's just a utility for making
   debugging easier. */

/*VARARGS*/
void
expPrintf TCL_VARARGS_DEF(char *,arg1)
{
  char *fmt;
  va_list args;
  char bigbuf[2000];
  int len, rc;

  fmt = TCL_VARARGS_START(char *,arg1,args);
  len = vsprintf(bigbuf,arg1,args);
 retry:
  rc = write(2,bigbuf,len);
  if ((rc == -1) && (errno == EAGAIN)) goto retry;

  va_end(args);
}


void
expDiagToStderrSet(val)
    int val;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    tsdPtr->diagToStderr = val;
}
    

int
expDiagToStderrGet() {
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->diagToStderr;
}

Tcl_Channel
expDiagChannelGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->diagChannel;
}

void
expDiagChannelClose(interp)
    Tcl_Interp *interp;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->diagChannel) return;
    Tcl_UnregisterChannel(interp,tsdPtr->diagChannel);
    Tcl_DStringFree(&tsdPtr->diagFilename);
    tsdPtr->diagChannel = 0;
}

/* currently this registers the channel, however the exp_internal
   command doesn't currently give the channel name to the user so
   this is kind of useless - but we might change this someday */
int
expDiagChannelOpen(interp,filename)
    Tcl_Interp *interp;
    char *filename;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    char *newfilename;

    Tcl_ResetResult(interp);
    newfilename = Tcl_TranslateFileName(interp,filename,&tsdPtr->diagFilename);
    if (!newfilename) return TCL_ERROR;

    /* Tcl_TildeSubst doesn't store into dstring */
    /* if no ~, so force string into dstring */
    /* this is only needed so that next time around */
    /* we can get dstring for -info if necessary */
    if (Tcl_DStringValue(&tsdPtr->diagFilename)[0] == '\0') {
	Tcl_DStringAppend(&tsdPtr->diagFilename,filename,-1);
    }

    tsdPtr->diagChannel = Tcl_OpenFileChannel(interp,newfilename,"a",0777);
    if (!tsdPtr->diagChannel) {
	Tcl_DStringFree(&tsdPtr->diagFilename);
	return TCL_ERROR;
    }
    Tcl_RegisterChannel(interp,tsdPtr->diagChannel);
    Tcl_SetChannelOption(interp,tsdPtr->diagChannel,"-buffering","none");
    return TCL_OK;
}

void
expDiagWriteObj(obj)
    Tcl_Obj *obj;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->diagChannel) return;

    Tcl_WriteObj(tsdPtr->diagChannel,obj);
}

/* write 8-bit bytes */
void
expDiagWriteBytes(str,len)
char *str;
int len;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->diagChannel) return;

    Tcl_Write(tsdPtr->diagChannel,str,len);
}

/* write UTF chars */
void
expDiagWriteChars(str,len)
char *str;
int len;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->diagChannel) return;

    Tcl_WriteChars(tsdPtr->diagChannel,str,len);
}

/* write Unicode chars */
static void
expDiagWriteCharsUni(str,len)
Tcl_UniChar *str;
int len;
{
    Tcl_DString ds;
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->diagChannel) return;

    Tcl_DStringInit (&ds);
    Tcl_UniCharToUtfDString (str,len,&ds);
    Tcl_WriteChars(tsdPtr->diagChannel,Tcl_DStringValue (&ds), Tcl_DStringLength (&ds));
    Tcl_DStringFree (&ds);
}

char *
expDiagFilename()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return Tcl_DStringValue(&tsdPtr->diagFilename);
}

void
expLogChannelClose(interp)
    Tcl_Interp *interp;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    if (!tsdPtr->logChannel) return;

    if (Tcl_DStringLength(&tsdPtr->logFilename)) {
	/* it's a channel that we created */
	Tcl_UnregisterChannel(interp,tsdPtr->logChannel);
	Tcl_DStringFree(&tsdPtr->logFilename);
    } else {
	/* it's a channel that tcl::open created */
	if (!tsdPtr->logLeaveOpen) {
	    Tcl_UnregisterChannel(interp,tsdPtr->logChannel);
	}
    }
    tsdPtr->logChannel = 0;
    tsdPtr->logAll = 0; /* can't write to log if none open! */
}

/* currently this registers the channel, however the exp_log_file
   command doesn't currently give the channel name to the user so
   this is kind of useless - but we might change this someday */
int
expLogChannelOpen(interp,filename,append)
    Tcl_Interp *interp;
    char *filename;
    int append;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    char *newfilename;
    char mode[2];

    if (append) {
      strcpy(mode,"a");
    } else {
      strcpy(mode,"w");
    }

    Tcl_ResetResult(interp);
    newfilename = Tcl_TranslateFileName(interp,filename,&tsdPtr->logFilename);
    if (!newfilename) return TCL_ERROR;

    /* Tcl_TildeSubst doesn't store into dstring */
    /* if no ~, so force string into dstring */
    /* this is only needed so that next time around */
    /* we can get dstring for -info if necessary */
    if (Tcl_DStringValue(&tsdPtr->logFilename)[0] == '\0') {
	Tcl_DStringAppend(&tsdPtr->logFilename,filename,-1);
    }

    tsdPtr->logChannel = Tcl_OpenFileChannel(interp,newfilename,mode,0777);
    if (!tsdPtr->logChannel) {
	Tcl_DStringFree(&tsdPtr->logFilename);
	return TCL_ERROR;
    }
    Tcl_RegisterChannel(interp,tsdPtr->logChannel);
    Tcl_SetChannelOption(interp,tsdPtr->logChannel,"-buffering","none");
    expLogAppendSet(append);
    return TCL_OK;
}

int
expLogAppendGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->logAppend;
}

void
expLogAppendSet(app)
    int app;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    tsdPtr->logAppend = app;
}

int
expLogAllGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->logAll;
}

void
expLogAllSet(app)
    int app;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    tsdPtr->logAll = app;
    /* should probably confirm logChannel != 0 */
}

int
expLogToStdoutGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->logUser;
}

void
expLogToStdoutSet(app)
    int app;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    tsdPtr->logUser = app;
}

int
expLogLeaveOpenGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->logLeaveOpen;
}

void
expLogLeaveOpenSet(app)
    int app;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    tsdPtr->logLeaveOpen = app;
}

Tcl_Channel
expLogChannelGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    return tsdPtr->logChannel;
}

/* to set to a pre-opened channel (presumably by tcl::open) */
int
expLogChannelSet(interp,name)
    Tcl_Interp *interp;
    char *name;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    int mode;
    
    if (0 == (tsdPtr->logChannel = Tcl_GetChannel(interp,name,&mode))) {
	return TCL_ERROR;
    }
    if (!(mode & TCL_WRITABLE)) {
	tsdPtr->logChannel = 0;
	Tcl_SetResult(interp,"channel is not writable",TCL_VOLATILE);
	return TCL_ERROR;
    }
    return TCL_OK;
}

char *
expLogFilenameGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return Tcl_DStringValue(&tsdPtr->logFilename);
}

int
expLogUserGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return tsdPtr->logUser;
}

void
expLogUserSet(logUser)
    int logUser;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    tsdPtr->logUser = logUser;
}



/* generate printable versions of random ASCII strings.  Primarily used */
/* in diagnostic mode, "expect -d" */
static char *
expPrintifyReal(s)
char *s;
{
	static int destlen = 0;
	static char *dest = 0;
	char *d;		/* ptr into dest */
	unsigned int need;
	Tcl_UniChar ch;

	if (s == 0) return("<null>");

	/* worst case is every character takes 4 to printify */
	need = strlen(s)*6 + 1;
	if (need > destlen) {
		if (dest) ckfree(dest);
		dest = ckalloc(need);
		destlen = need;
	}

	for (d = dest;*s;) {
	    s += Tcl_UtfToUniChar(s, &ch);
	    if (ch == '\r') {
		strcpy(d,"\\r");		d += 2;
	    } else if (ch == '\n') {
		strcpy(d,"\\n");		d += 2;
	    } else if (ch == '\t') {
		strcpy(d,"\\t");		d += 2;
	    } else if ((ch < 0x80) && isprint(UCHAR(ch))) {
		*d = (char)ch;			d += 1;
	    } else {
		sprintf(d,"\\u%04x",ch);	d += 6;
	    }
	}
	*d = '\0';
	return(dest);
}

/* generate printable versions of random ASCII strings.  Primarily used */
/* in diagnostic mode, "expect -d" */
static char *
expPrintifyRealUni(s,numchars)
Tcl_UniChar *s;
int numchars;
{
  static int destlen = 0;
  static char *dest = 0;
  char *d;		/* ptr into dest */
  unsigned int need;
  Tcl_UniChar ch;

  if (s == 0) return("<null>");
  if (numchars == 0) return("");

  /* worst case is every character takes 6 to printify */
  need = numchars*6 + 1;
  if (need > destlen) {
    if (dest) ckfree(dest);
    dest = ckalloc(need);
    destlen = need;
  }

  for (d = dest;numchars > 0;numchars--) {
    ch = *s; s++;

    if (ch == '\r') {
      strcpy(d,"\\r");		d += 2;
    } else if (ch == '\n') {
      strcpy(d,"\\n");		d += 2;
    } else if (ch == '\t') {
      strcpy(d,"\\t");		d += 2;
    } else if ((ch < 0x80) && isprint(UCHAR(ch))) {
      *d = (char)ch;			d += 1;
    } else {
      sprintf(d,"\\u%04x",ch);	d += 6;
    }
  }
  *d = '\0';
  return(dest);
}

char *
expPrintifyObj(obj)
    Tcl_Obj *obj;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    /* don't bother writing into bigbuf if we're not going to ever use it */
    if ((!tsdPtr->diagToStderr) && (!tsdPtr->diagChannel)) return((char *)0);
    
    return expPrintifyReal(Tcl_GetString(obj));
}

char *
expPrintify(s) /* INTL */
char *s;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    /* don't bother writing into bigbuf if we're not going to ever use it */
    if ((!tsdPtr->diagToStderr) && (!tsdPtr->diagChannel)) return((char *)0);

    return expPrintifyReal(s);
}
 
char *
expPrintifyUni(s,numchars) /* INTL */
Tcl_UniChar *s;
int numchars;
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    /* don't bother writing into bigbuf if we're not going to ever use it */
    if ((!tsdPtr->diagToStderr) && (!tsdPtr->diagChannel)) return((char *)0);

    return expPrintifyRealUni(s,numchars);
}
 
void
expDiagInit()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    Tcl_DStringInit(&tsdPtr->diagFilename);
    tsdPtr->diagChannel = 0;
    tsdPtr->diagToStderr = 0;
}

void
expLogInit()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    Tcl_DStringInit(&tsdPtr->logFilename);
    tsdPtr->logChannel = 0;
    tsdPtr->logAll = FALSE;
    tsdPtr->logUser = TRUE;
}
