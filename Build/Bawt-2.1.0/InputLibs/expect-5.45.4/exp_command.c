/* exp_command.c - the bulk of the Expect commands

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include "expect_cf.h"

#include <stdio.h>
#include <sys/types.h>
/*#include <sys/time.h> seems to not be present on SVR3 systems */
/* and it's not used anyway as far as I can tell */

/* AIX insists that stropts.h be included before ioctl.h, because both */
/* define _IO but only ioctl.h checks first.  Oddly, they seem to be */
/* defined differently! */
#ifdef HAVE_STROPTS_H
#  include <sys/stropts.h>
#endif
#include <sys/ioctl.h>

#ifdef HAVE_SYS_FCNTL_H
#  include <sys/fcntl.h>
#else
#  include <fcntl.h>
#endif
#include <sys/file.h>

#include <errno.h>
#include <signal.h>

#if defined(SIGCLD) && !defined(SIGCHLD)
#define SIGCHLD SIGCLD
#endif

#ifdef HAVE_PTYTRAP
#include <sys/ptyio.h>
#endif

#ifdef CRAY
# ifndef TCSETCTTY
#  if defined(HAVE_TERMIOS)
#   include <termios.h>
#  else
#   include <termio.h>
#  endif
# endif
#endif

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#include <math.h>		/* for log/pow computation in send -h */
#include <ctype.h>		/* all this for ispunct! */

#include "tclInt.h"		/* need OpenFile */
/*#include <varargs.h>		tclInt.h drags in varargs.h.  Since Pyramid */
/*				objects to including varargs.h twice, just */
/*				omit this one. */

#include "tcl.h"
#include "string.h"
#include "expect.h"
#include "expect_tcl.h"
#include "exp_rename.h"
#include "exp_prog.h"
#include "exp_command.h"
#include "exp_log.h"
#include "exp_event.h"
#include "exp_pty.h"
#include "exp_tty_in.h"
#ifdef TCL_DEBUGGER
#include "tcldbg.h"
#endif

/*
 * These constants refer to the UTF string that encodes a null character.
 */

#define NULL_STRING "\300\200" /* hex C080 */
#define NULL_LENGTH 2

#define SPAWN_ID_VARNAME "spawn_id"

void exp_ecmd_remove_state_direct_and_indirect(Tcl_Interp *interp, ExpState *esPtr);


int exp_forked = FALSE;		/* whether we are child process */

/* the following are use to create reserved addresses, to be used as ClientData */
/* args to be used to tell commands how they were called. */
/* The actual values won't be used, only the addresses, but I give them */
/* values out of my irrational fear the compiler might collapse them all. */
static int sendCD_error = 2;	/* called as send_error */
static int sendCD_user = 3;	/* called as send_user */
static int sendCD_proc = 4;	/* called as send or send_spawn */
static int sendCD_tty = 6;	/* called as send_tty */

/*
 * expect_key is just a source for generating a unique stamp.  As each
 * expect/interact command begins, it generates a new key and marks all
 * the spawn ids of interest with it.  Then, if someone comes along and
 * marks them with yet a newer key, the old command will recognize this
 * reexamine the state of the spawned process.
 */
int expect_key = 0;

/*
 * exp_configure_count is incremented whenever a spawned process is closed
 * or an indirect list is modified.  This forces any (stack of) expect or
 * interact commands to reexamine the state of the world and adjust
 * accordingly.
 */
int exp_configure_count = 0;

#ifdef HAVE_PTYTRAP
/* slaveNames provides a mapping from the pty slave names to our */
/* spawn id entry.  This is needed only on HPs for stty, sigh. */
static Tcl_HashTable slaveNames;
#endif /* HAVE_PTYTRAP */

typedef struct ThreadSpecificData {
    /*
     * List of all exp channels currently open.  This is per thread and is
     * used to match up fd's to channels, which rarely occurs.
     */
    
    ExpState *stdinout;
    ExpState *stderrX;   /* grr....stderr is a macro */
    ExpState *devtty;
    ExpState *any; /* for any_spawn_id */

    Tcl_Channel *diagChannel; /* Unused - exp_log.c has its own. */
    Tcl_DString diagDString;  /* Unused */
    int diagEnabled;          /* Unused */

    /* Table of structures for all Tcl channels used as -open argument
     * in a exp_spawn call. For refCounting of Tcl channels used by
     * more than one Expect channel.
     */

    Tcl_HashTable origins;

} ThreadSpecificData;

static Tcl_ThreadDataKey dataKey;

#ifdef FULLTRAPS
static void
init_traps(RETSIGTYPE (*traps[])())
{
    int i;

    for (i=1;i<NSIG;i++) {
	traps[i] = SIG_ERR;
    }
}
#endif

/* Do not terminate format strings with \n!!! */
/*VARARGS*/
void
exp_error TCL_VARARGS_DEF(Tcl_Interp *,arg1)
/*exp_error(va_alist)*/
/*va_dcl*/
{
    Tcl_Interp *interp;
    char *fmt;
    va_list args;
    char buffer[2000];

    interp = TCL_VARARGS_START(Tcl_Interp *,arg1,args);
    fmt = va_arg(args,char *);
    vsprintf(buffer,fmt,args);
    Tcl_SetResult(interp,buffer,TCL_VOLATILE);
    va_end(args);
}

/* returns current ExpState or 0.  If 0, may be immediately followed by return TCL_ERROR. */
struct ExpState *
expStateCurrent(
    Tcl_Interp *interp,
    int opened,
    int adjust,
    int any)
{
    static char *user_spawn_id = "exp0";

    char *name = exp_get_var(interp,SPAWN_ID_VARNAME);
    if (!name) name = user_spawn_id;

    return expStateFromChannelName(interp,name,opened,adjust,any,SPAWN_ID_VARNAME);
}

ExpState *
expStateCheck(
    Tcl_Interp *interp,
    ExpState *esPtr,
    int open,
    int adjust,
    char *msg)
{
    if (open && !esPtr->open) {
	exp_error(interp,"%s: spawn id %s not open",msg,esPtr->name);
	return(0);
    }
    if (adjust) expAdjust(esPtr);
    return esPtr;
}

ExpState *
expStateFromChannelName(
    Tcl_Interp *interp,
    char *name,
    int open,
    int adjust,
    int any,
    char *msg)
{
    ExpState *esPtr;
    Tcl_Channel channel;
    CONST char *chanName;

    if (any) {
	if (0 == strcmp(name,EXP_SPAWN_ID_ANY_LIT)) {
	    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
	    return tsdPtr->any;
	}
    }

    channel = Tcl_GetChannel(interp,name,(int *)0);
    if (!channel) return(0);

    chanName = Tcl_GetChannelName(channel);
    if (!isExpChannelName(chanName)) {
	exp_error(interp,"%s: %s is not an expect channel - use spawn -open to convert",msg,chanName);
	return(0);
    }

    esPtr = (ExpState *)Tcl_GetChannelInstanceData(channel);

    return expStateCheck(interp,esPtr,open,adjust,msg);
}

/* zero out the wait status field */
static void
exp_wait_zero(WAIT_STATUS_TYPE *status)
{
    int i;

    for (i=0;i<sizeof(WAIT_STATUS_TYPE);i++) {
	((char *)status)[i] = 0;
    }
}

/* called just before an ExpState entry is about to be invalidated */
void
exp_state_prep_for_invalidation(
    Tcl_Interp *interp,
    ExpState *esPtr)
{
    exp_ecmd_remove_state_direct_and_indirect(interp,esPtr);

    exp_configure_count++;

    if (esPtr->fg_armed) {
	exp_event_disarm_fg(esPtr);
    }
}

/*ARGSUSED*/
void
exp_trap_on(int master)
{
#ifdef HAVE_PTYTRAP
    if (master == -1) return;
    exp_slave_control(master,1);
#endif /* HAVE_PTYTRAP */
}

int
exp_trap_off(char *name)
{
#ifdef HAVE_PTYTRAP
    ExpState *esPtr;
    int enable = 0;

    Tcl_HashEntry *entry = Tcl_FindHashEntry(&slaveNames,name);
    if (!entry) {
	expDiagLog("exp_trap_off: no entry found for %s\n",name);
	return -1;
    }

    esPtr = (ExpState *)Tcl_GetHashValue(entry);

    exp_slave_control(esPtr->fdin,0);

    return esPtr->fdin;
#else
    return name[0];	/* pacify lint, use arg and return something */
#endif
}

static
void
expBusy(ExpState *esPtr)
{
    int x = open("/dev/null",0);
    if (x != esPtr->fdin) {
	fcntl(x,F_DUPFD,esPtr->fdin);
	close(x);
    }
    expCloseOnExec(esPtr->fdin);
    esPtr->fdBusy = TRUE;
}

int
exp_close(
    Tcl_Interp *interp,
    ExpState *esPtr)
{
    if (0 == expStateCheck(interp,esPtr,1,0,"close")) return TCL_ERROR;
    esPtr->open = FALSE;

    /* restore blocking for some shells that would otherwise be */
    /* surprised finding stdio or /dev/tty nonblocking */
    (void) Tcl_SetChannelOption(interp,esPtr->channel,"-blocking","on");

    /* Since we're closing the channel, not Tcl, we need to get Tcl's
       buffers flushed.  Because the channel was nonblocking, EAGAINs
       could leave things buffered.  They need to be synchronously
       written now! */
    Tcl_Flush(esPtr->channel);

    /*
     * Ignore close errors from ptys.  Ptys on some systems return errors for
     * no evident reason.  Anyway, receiving an error upon pty-close doesn't
     * mean anything anyway as far as I know.  
     */

    close(esPtr->fdin);
    if (esPtr->fd_slave != EXP_NOFD) close(esPtr->fd_slave);
    if (esPtr->fdin != esPtr->fdout) close(esPtr->fdout);

    if (esPtr->chan_orig) {
        esPtr->chan_orig->refCount --;
	if (esPtr->chan_orig->refCount <= 0) {
	    /*
	     * Ignore close errors from Tcl channels.  They indicate things
	     * like broken pipelines, etc, which don't affect our
	     * subsequent handling.
	     */

	    ThreadSpecificData* tsdPtr = TCL_TSD_INIT(&dataKey);
	    char*               cName  = Tcl_GetChannelName(esPtr->chan_orig->channel_orig);
	    Tcl_HashEntry*      entry  = Tcl_FindHashEntry(&tsdPtr->origins,cName);
	    ExpOrigin*          orig   = (ExpOrigin*) Tcl_GetHashValue(entry);

	    Tcl_DeleteHashEntry(entry);
	    ckfree ((char*)orig);

	    if (!esPtr->leaveopen) {
		Tcl_VarEval(interp,"close ", cName, (char *)0);
	    }
	}
    }

#ifdef HAVE_PTYTRAP
    if (esPtr->slave_name) {
	Tcl_HashEntry *entry;

	entry = Tcl_FindHashEntry(&slaveNames,esPtr->slave_name);
	Tcl_DeleteHashEntry(entry);

	ckfree(esPtr->slave_name);
	esPtr->slave_name = 0;
    }
#endif

    exp_state_prep_for_invalidation(interp,esPtr);

    if (esPtr->user_waited) {
	if (esPtr->registered) {
	    Tcl_UnregisterChannel(interp,esPtr->channel);
	    /* at this point esPtr may have been freed so don't touch it
               any longer */
	}
    } else {
	expBusy(esPtr);
    }

    return(TCL_OK);
}

/* report whether this ExpState represents special spawn_id_any */
/* we need a separate function because spawn_id_any is thread-specific */
/* and can't be seen outside this file */
int
expStateAnyIs(ExpState *esPtr)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return (esPtr == tsdPtr->any);
}

int
expDevttyIs(ExpState *esPtr)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return (esPtr == tsdPtr->devtty);
}

int
expStdinoutIs(ExpState *esPtr)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return (tsdPtr->stdinout == esPtr);
}

ExpState *
expStdinoutGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return tsdPtr->stdinout;
}

ExpState *
expDevttyGet()
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    return tsdPtr->devtty;
}

void
exp_init_spawn_id_vars(Tcl_Interp *interp)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    Tcl_SetVar(interp, "user_spawn_id", tsdPtr->stdinout->name,0);
    Tcl_SetVar(interp,"error_spawn_id",  tsdPtr->stderrX->name,0);
    Tcl_SetVar(interp,  "any_spawn_id",   EXP_SPAWN_ID_ANY_LIT,0);

    /* user_spawn_id is NOT /dev/tty which could (at least in theory
     * anyway) be later re-opened on a different fd, while stdin might
     * have been redirected away from /dev/tty
     */

    if (exp_dev_tty != -1) {
	Tcl_SetVar(interp,"tty_spawn_id",tsdPtr->devtty->name,0);
    }
}

void
exp_init_spawn_ids(Tcl_Interp *interp)
{
    static ExpState any_placeholder;  /* can be shared process-wide */
    
    /* note whether 0,1,2 are connected to a terminal so that if we */
    /* disconnect, we can shut these down.  We would really like to */
    /* test if 0,1,2 are our controlling tty, but I don't know any */
    /* way to do that portably.  Anyway, the likelihood of anyone */
    /* disconnecting after redirecting to a non-controlling tty is */
    /* virtually zero. */

    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    tsdPtr->stdinout = expCreateChannel(interp,0,1,isatty(0)?exp_getpid:EXP_NOPID);
    tsdPtr->stdinout->keepForever = 1;
    /* hmm, now here's an example of a output-only descriptor!! */
    tsdPtr->stderrX = expCreateChannel(interp,2,2,isatty(2)?exp_getpid:EXP_NOPID);
    tsdPtr->stderrX->keepForever = 1;

    if (exp_dev_tty != -1) {
	tsdPtr->devtty = expCreateChannel(interp,exp_dev_tty,exp_dev_tty,exp_getpid);
	tsdPtr->devtty->keepForever = 1;
    }

    /* set up a dummy channel to give us something when we need to find out if
       people have passed us "any_spawn_id" */
    tsdPtr->any = &any_placeholder;

    /* Set up the hash table for managing the channels used via
     * -open.
     */

    Tcl_InitHashTable (&tsdPtr->origins, TCL_STRING_KEYS);
}

void
expCloseOnExec(int fd)
{
    (void) fcntl(fd,F_SETFD,1);
}

#define STTY_INIT	"stty_init"

#if 0
/*
 * DEBUGGING UTILITIES - DON'T DELETE */
static void
show_pgrp(
    int fd,
    char *string)
{
    int pgrp;

    fprintf(stderr,"getting pgrp for %s\n",string);
    if (-1 == ioctl(fd,TIOCGETPGRP,&pgrp)) perror("TIOCGETPGRP");
    else fprintf(stderr,"%s pgrp = %d\n",string,pgrp);
    if (-1 == ioctl(fd,TIOCGPGRP,&pgrp)) perror("TIOCGPGRP");
    else fprintf(stderr,"%s pgrp = %d\n",string,pgrp);
    if (-1 == tcgetpgrp(fd,pgrp)) perror("tcgetpgrp");
    else fprintf(stderr,"%s pgrp = %d\n",string,pgrp);
}

static void
set_pgrp(int fd)
{
    int pgrp = getpgrp(0);
    if (-1 == ioctl(fd,TIOCSETPGRP,&pgrp)) perror("TIOCSETPGRP");
    if (-1 == ioctl(fd,TIOCSPGRP,&pgrp)) perror("TIOCSPGRP");
    if (-1 == tcsetpgrp(fd,pgrp)) perror("tcsetpgrp");
}
#endif

static
void
expSetpgrp()
{
#ifdef MIPS_BSD
    /* required on BSD side of MIPS OS <jmsellen@watdragon.waterloo.edu> */
#   include <sysv/sys.s>
    syscall(SYS_setpgrp);
#endif

#ifdef SETPGRP_VOID
    (void) setpgrp();
#else
    (void) setpgrp(0,0);
#endif
}


/*ARGSUSED*/
static void
set_slave_name(
    ExpState *esPtr,
    char *name)
{
#ifdef HAVE_PTYTRAP
    int newptr;
    Tcl_HashEntry *entry;

    /* save slave name */
    esPtr->slave_name = ckalloc(strlen(exp_pty_slave_name)+1);
    strcpy(esPtr->slave_name,exp_pty_slave_name);

    entry = Tcl_CreateHashEntry(&slaveNames,exp_pty_slave_name,&newptr);
    Tcl_SetHashValue(entry,(ClientData)esPtr);
#endif /* HAVE_PTYTRAP */
}

/* arguments are passed verbatim to execvp() */
/*ARGSUSED*/
static int
Exp_SpawnObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    ExpState *esPtr = 0;
    int slave;
    int pid;
#ifdef TIOCNOTTY
    /* tell Saber to ignore non-use of ttyfd */
    /*SUPPRESS 591*/
    int ttyfd;
#endif /* TIOCNOTTY */
    int errorfd;	/* place to stash fileno(stderr) in child */
			/* while we're setting up new stderr */
    int master, k;
    int write_master;	/* write fd of Tcl-opened files */
    int ttyinit = TRUE;
    int ttycopy = TRUE;
    int echo = TRUE;
    int console = FALSE;
    int pty_only = FALSE;
    char** argv;

#ifdef FULLTRAPS
    /* Allow user to reset signals in child */
    /* The following array contains indicates */
    /* whether sig should be DFL or IGN */
    /* ERR is used to indicate no initialization */
    RETSIGTYPE (*traps[NSIG])();
#endif
    int ignore[NSIG];		/* if true, signal in child is ignored */
				/* if false, signal gets default behavior */
    int i;			/* trusty overused temporary */

    char *argv0 = Tcl_GetString (objv[0]);
    char *chanName = 0;
    int leaveopen = FALSE;
    int rc, wc;
    CONST char *stty_init;
    int slave_write_ioctls = 1;
    /* by default, slave will be write-ioctled this many times */
    int slave_opens = 3;
    /* by default, slave will be opened this many times */
    /* first comes from initial allocation */
    /* second comes from stty */
    /* third is our own signal that stty is done */

    int sync_fds[2];
    int sync2_fds[2];
    int status_pipe[2];
    int child_errno;
    char sync_byte;
    int cmdIndex;
    Tcl_Obj* cmdObj;
    char* command;

    static char* options[] = {
	"-console",
	"-ignore",
	"-leaveopen",
	"-noecho",
	"-nottycopy",
	"-nottyinit",
	"-open",
	"-pty",
#ifdef FULLTRAPS
	"-trap",
#endif
	NULL
    };
    enum options {
	SPAWN_CONSOLE
	,SPAWN_IGNORE
	,SPAWN_LEAVEOPEN
	,SPAWN_NOECHO
	,SPAWN_NOTTYCOPY
	,SPAWN_NOTTYINIT
	,SPAWN_OPEN
	,SPAWN_PTY
#ifdef FULLTRAPS
	,SPAWN_TRAP
#endif
    };

    Tcl_Channel channel;
    Tcl_DString dstring;
    Tcl_DStringInit(&dstring);

#ifdef FULLTRAPS
    init_traps(&traps);
#endif
    /* don't ignore any signals in child by default */
    for (i=1;i<NSIG;i++) {
	ignore[i] = FALSE;
    }

    /* Check and process switches */

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	    case SPAWN_NOTTYINIT:
		ttyinit = FALSE;
		slave_write_ioctls--;
		slave_opens--;
		break;
	    case SPAWN_NOTTYCOPY:
		ttycopy = FALSE;
		break;
	    case SPAWN_NOECHO:
		echo = FALSE;
		break;
	    case SPAWN_CONSOLE:
		console = TRUE;
		break;
	    case SPAWN_PTY:
		pty_only = TRUE;
		break;
	    case SPAWN_OPEN:
		i ++;
		if (i >= objc) {
		    exp_error(interp,"usage: -open file-identifier");
		    return TCL_ERROR;
		}
		chanName = Tcl_GetString (objv[i]);
		break;
	    case SPAWN_LEAVEOPEN:
		i ++;
		if (i >= objc) {
		    exp_error(interp,"usage: -open file-identifier");
		    return TCL_ERROR;
		}
		chanName = Tcl_GetString (objv[i]);
		leaveopen = TRUE;
		break;
	    case SPAWN_IGNORE: {
		int sig;
		i ++;
		if (i >= objc) {
		    exp_error(interp,"usage: -ignore signal");
		    return TCL_ERROR;
		}
		sig = exp_string_to_signal(interp,Tcl_GetString (objv[i]));
		if (sig == -1) {
		    exp_error(interp,"usage: -ignore %s: unknown signal name",Tcl_GetString (objv[i]));
		    return TCL_ERROR;
		}
		ignore[sig] = TRUE;
	    }
		break;
#ifdef FULLTRAPS
	    case SPAWN_TRAP: {
		/* objv[i+1] is list of signals */
		/* objv[i+2] is action */

		static char* actions [] = {
		    "SIG_DFL", "SIG_IGN", NULL
		};
		enum actions {
		    ACTION_SIGDFL, ACTION_SIGIGN;
		}
		int theaction;

		int j;
		RETSIGTYPE (*sig_handler)();
		int       lc;	/* number of signals in list */
		Tcl_Obj** lv;	/* list of signals */

		if ((objc - i) < 3) {
		    exp_error(interp,"usage: -trap siglist SIG_DFL or SIG_IGN");
		    return TCL_ERROR;
		}

		/* Check and process action */

		if (Tcl_GetIndexFromObj(interp, objv[i+2], actions, "action", 0,
				&theaction) != TCL_OK) {
		    exp_error(interp,"usage: -trap siglist SIG_DFL or SIG_IGN");
		    return TCL_ERROR;
		}
		switch ((enum actions) theaction) {
		    case ACTION_SIGDFL:
			sig_handler = SIG_DFL;
			break;
		    case ACTION_SIGIGN:
			sig_handler = SIG_IGN;
			break;
		}

		/* Check and process list of signals */

		if (TCL_OK != Tcl_ListObjGetElements (inter, objv[i+1], &lc, &lv)) {
		    expErrorLogU(Tcl_GetStringResult(interp));
		    expErrorLogU("\r\n");
		    exp_error(interp,"usage: -trap {siglist} ...");
		    return TCL_ERROR;
		}

		for (j=0;j<lc;j++) {
		    int sig = exp_string_to_signal(interp,Tcl_GetString (lv[j]));
		    if (sig == -1) {
			return TCL_ERROR;
		    }
		    traps[sig] = sig_handler;
		}

		i += 2;
	    }
		break;
#endif
	}
    }

    /* Additional checking of arguments */

    if (chanName && (i < objc)) {
	exp_error(interp,"usage: -[leave]open [fileXX]");
	return TCL_ERROR;
    }

    if (!pty_only && !chanName && (i == objc)) {
	exp_error(interp,"usage: spawn [spawn-args] program [program-args]");
	return(TCL_ERROR);
    }

    cmdIndex = i;
    cmdObj = objv[i];

    stty_init = exp_get_var(interp,STTY_INIT);
    if (stty_init) {
	slave_write_ioctls++;
	slave_opens++;
    }

/* any extraneous ioctl's that occur in slave must be accounted for
   when trapping, see below in child half of fork */
#if defined(TIOCSCTTY) && !defined(CIBAUD) && !defined(sun) && !defined(hp9000s300)
    slave_write_ioctls++;
    slave_opens++;
#endif

    exp_pty_slave_name = 0;

    Tcl_ReapDetachedProcs();

    if (!chanName) {
	if (echo) {
	    int c = 0;
	    expStdoutLogU(argv0,0);
	    for (c = 1; c < objc; c++) {
		expStdoutLogU(" ",0);
		expStdoutLogU(Tcl_GetString (objv[c]),0);
	    }
	    expStdoutLogU("\r\n",0);
	}

	if (0 > (master = exp_getptymaster())) {
	    /*
	     * failed to allocate pty, try and figure out why
	     * so we can suggest to user what to do about it.
	     */

	    int testfd;

	    if (exp_pty_error) {
		exp_error(interp,"%s",exp_pty_error);
		return TCL_ERROR;
	    }

	    if (expChannelCountGet() > 10) {
		exp_error(interp,"The system only has a finite number of ptys and you have many of them in use.  The usual reason for this is that you forgot (or didn't know) to call \"wait\" after closing each of them.");
		return TCL_ERROR;
	    }

	    testfd = open("/",0);
	    close(testfd);

	    if (testfd != -1) {
		exp_error(interp,"The system has no more ptys.  Ask your system administrator to create more.");
	    } else {
		exp_error(interp,"- You have too many files are open.  Close some files or increase your per-process descriptor limit.");
	    }
	    return(TCL_ERROR);
	}

	/* ordinarily channel creation takes care of close-on-exec
	 * but because that will occur *after* fork, force close-on-exec
	 * now in this case.
	 */
	expCloseOnExec(master);

#define SPAWN_OUT "spawn_out"
	Tcl_SetVar2(interp,SPAWN_OUT,"slave,name",exp_pty_slave_name,0);

	if (pty_only) {
	    write_master = master;
	}
    } else {
	/*
	 * process "-open $channel"
	 */
	int mode, rfd, wfd;
	ClientData rfdc, wfdc;

	if (echo) {
	    expStdoutLogU(argv0,0);
	    expStdoutLogU(" [open ...]\r\n",0);
	}
	if (!(channel = Tcl_GetChannel(interp,chanName,&mode))) {
	    return TCL_ERROR;
	}
	if (!mode) {
	    exp_error(interp,"channel is neither readable nor writable");
	    return TCL_ERROR;
	}
	if (mode & TCL_READABLE) {
	    if (TCL_ERROR == Tcl_GetChannelHandle(channel, TCL_READABLE, &rfdc)) {
		return TCL_ERROR;
	    }
	    rfd = (int)(long) rfdc;
	}
	if (mode & TCL_WRITABLE) {
	    if (TCL_ERROR == Tcl_GetChannelHandle(channel, TCL_WRITABLE, &wfdc)) {
		return TCL_ERROR;
	    }
	    wfd = (int)(long) wfdc;
	}
	master = ((mode & TCL_READABLE)?rfd:wfd);

	/* make a new copy of file descriptor */
	if (-1 == (write_master = master = dup(master))) {
	    exp_error(interp,"fdopen: %s",Tcl_PosixError(interp));
	    return TCL_ERROR;
	}

	/* if writefilePtr is different, dup that too */
	if ((mode & TCL_READABLE) && (mode & TCL_WRITABLE) && (wfd != rfd)) {
	    if (-1 == (write_master = dup(wfd))) {
		exp_error(interp,"fdopen: %s",Tcl_PosixError(interp));
		return TCL_ERROR;
	    }
	}

	/*
	 * It would be convenient now to tell Tcl to close its
	 * file descriptor.  Alas, if involved in a pipeline, Tcl
	 * will be unable to complete a wait on the process.
	 * So simply remember that we meant to close it.  We will
	 * do so later in our own close routine.
	 */
    }

    if (chanName || pty_only) {
	esPtr = expCreateChannel(interp,master,write_master,EXP_NOPID);

	if (chanName) {
	    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
	    Tcl_HashEntry *entry = Tcl_FindHashEntry(&tsdPtr->origins,chanName);

	    if (entry) {
	        esPtr->chan_orig = (ExpOrigin*) Tcl_GetHashValue(entry);
		esPtr->chan_orig->refCount ++;

	    } else {
	        int newptr;
		ExpOrigin* orig = (ExpOrigin*) ckalloc (sizeof (ExpOrigin));

		esPtr->chan_orig   = orig;
		orig->channel_orig = channel;
		orig->refCount     = 1;

		entry = Tcl_CreateHashEntry(&tsdPtr->origins,chanName,&newptr);
		Tcl_SetHashValue(entry, (ClientData) orig);
	    }

	    esPtr->leaveopen = leaveopen;
	}

	if (exp_pty_slave_name) set_slave_name(esPtr,exp_pty_slave_name);

	/* make it appear as if process has been waited for */
	esPtr->sys_waited = TRUE;
	exp_wait_zero(&esPtr->wait);

	/* tell user of new spawn id */
	Tcl_SetVar(interp,SPAWN_ID_VARNAME,esPtr->name,0);

	if (!chanName) {
	    char value[20];

	    /*
	     * open the slave side in the same process to support
	     * the -pty flag.
	     */

	    if (0 > (esPtr->fd_slave = exp_getptyslave(ttycopy,ttyinit,
				    stty_init))) {
		exp_error(interp,"open(slave pty): %s\r\n",Tcl_PosixError(interp));
		return TCL_ERROR;
	    }

	    exp_slave_control(master,1);

	    sprintf(value,"%d",esPtr->fd_slave);
	    Tcl_SetVar2(interp,SPAWN_OUT,"slave,fd",value,0);
	}
	Tcl_SetObjResult (interp, Tcl_NewIntObj (EXP_NOPID));
	expDiagLog("spawn: returns {%s}\r\n",Tcl_GetStringResult(interp));

	return TCL_OK;
    }

    command = Tcl_TranslateFileName(interp,Tcl_GetString (cmdObj),&dstring);
    if (NULL == command) {
	goto parent_error;
    }

    if (-1 == pipe(sync_fds)) {
	exp_error(interp,"too many programs spawned?  could not create pipe: %s",Tcl_PosixError(interp));
	goto parent_error;
    }

    if (-1 == pipe(sync2_fds)) {
	close(sync_fds[0]);
	close(sync_fds[1]);
	exp_error(interp,"too many programs spawned?  could not create pipe: %s",Tcl_PosixError(interp));
	goto parent_error;
    }

    if (-1 == pipe(status_pipe)) {
	close(sync_fds[0]);
	close(sync_fds[1]);
	close(sync2_fds[0]);
	close(sync2_fds[1]);
	exp_error(interp,"too many programs spawned?  could not create pipe: %s",Tcl_PosixError(interp));
	goto parent_error;
    }

    if ((pid = fork()) == -1) {
	exp_error(interp,"fork: %s",Tcl_PosixError(interp));
	goto parent_error;
    }

    if (pid) { /* parent */
	close(sync_fds[1]);
	close(sync2_fds[0]);
	close(status_pipe[1]);

	esPtr = expCreateChannel(interp,master,master,pid);

	if (exp_pty_slave_name) set_slave_name(esPtr,exp_pty_slave_name);

#ifdef CRAY
	setptypid(pid);
#endif

	/*
	 * wait for slave to initialize pty before allowing
	 * user to send to it
	 */ 

	expDiagLog("parent: waiting for sync byte\r\n");
	while (((rc = read(sync_fds[0],&sync_byte,1)) < 0) && (errno == EINTR)) {
	    /* empty */;
	}
	if (rc == -1) {
	    expErrorLogU("parent: sync byte read: ");
	    expErrorLogU(Tcl_ErrnoMsg(errno));
	    expErrorLogU("\r\n");
	    exit(-1);
	}

	/* turn on detection of eof */
	exp_slave_control(master,1);

	/*
	 * tell slave to go on now, now that we have initialized pty
	 */

	expDiagLog("parent: telling child to go ahead\r\n");
	wc = write(sync2_fds[1]," ",1);
	if (wc == -1) {
	    expErrorLog("parent: sync byte write: %s\r\n",Tcl_ErrnoMsg(errno));
	    exit(-1);
	}

	expDiagLog("parent: now unsynchronized from child\r\n");
	close(sync_fds[0]);
	close(sync2_fds[1]);

	/* see if child's exec worked */
	retry:
	switch (read(status_pipe[0],&child_errno,sizeof child_errno)) {
	    case -1:
		if (errno == EINTR) goto retry;
		/* well it's not really the child's errno */
		/* but it can be treated that way */
		child_errno = errno;
		break;
	    case 0:
		/* child's exec succeeded */
		child_errno = 0;
		break;
	    default:
		/* child's exec failed; child_errno contains exec's errno */
		close(status_pipe[0]);
		waitpid(pid, NULL, 0);
		/* in order to get Tcl to set errorcode, we must */
		/* hand set errno */
		errno = child_errno;
		exp_error(interp, "couldn't execute \"%s\": %s",
			command,Tcl_PosixError(interp));
		goto parent_error;
	}
	close(status_pipe[0]);

	/* tell user of new spawn id */
	Tcl_SetVar(interp,SPAWN_ID_VARNAME,esPtr->name,0);

	Tcl_SetObjResult (interp, Tcl_NewIntObj (pid));
	expDiagLog("spawn: returns {%s}\r\n",Tcl_GetStringResult(interp));

	Tcl_DStringFree(&dstring);
	return(TCL_OK);
    }

    /* child process - do not return from here!  all errors must exit() */

    close(sync_fds[0]);
    close(sync2_fds[1]);
    close(status_pipe[0]);
    expCloseOnExec(status_pipe[1]);

    if (exp_dev_tty != -1) {
	close(exp_dev_tty);
	exp_dev_tty = -1;
    }

#ifdef CRAY
    (void) close(master);
#endif

/* ultrix (at least 4.1-2) fails to obtain controlling tty if setsid */
/* is called.  setpgrp works though.  */
#if defined(POSIX) && !defined(ultrix)
#define DO_SETSID
#endif
#ifdef __convex__
#define DO_SETSID
#endif

#ifdef DO_SETSID
    setsid();
#else
#ifdef SYSV3
#ifndef CRAY
    expSetpgrp();
#endif /* CRAY */
#else /* !SYSV3 */
    expSetpgrp();

/* Pyramid lacks this defn */
#ifdef TIOCNOTTY
    ttyfd = open("/dev/tty", O_RDWR);
    if (ttyfd >= 0) {
	(void) ioctl(ttyfd, TIOCNOTTY, (char *)0);
	(void) close(ttyfd);
    }
#endif /* TIOCNOTTY */

#endif /* SYSV3 */
#endif /* DO_SETSID */

    /* save stderr elsewhere to avoid BSD4.4 bogosity that warns */
    /* if stty finds dev(stderr) != dev(stdout) */

    /* save error fd while we're setting up new one */
    errorfd = fcntl(2,F_DUPFD,3);
    /* and here is the macro to restore it */
#define restore_error_fd {close(2);fcntl(errorfd,F_DUPFD,2);}

    close(0);
    close(1);
    close(2);

    /* since we closed fd 0, open of pty slave must return fd 0 */

    /* since exp_getptyslave may have to run stty, (some of which work on fd */
    /* 0 and some of which work on 1) do the dup's inside exp_getptyslave. */

    if (0 > (slave = exp_getptyslave(ttycopy,ttyinit,stty_init))) {
	restore_error_fd

	    if (exp_pty_error) {
		expErrorLog("open(slave pty): %s\r\n",exp_pty_error);
	    } else {
		expErrorLog("open(slave pty): %s\r\n",Tcl_ErrnoMsg(errno));
	    }
	exit(-1);
    }
    /* sanity check */
    if (slave != 0) {
	restore_error_fd
	    expErrorLog("exp_getptyslave: slave = %d but expected 0\n",slave);
	exit(-1);
    }

/* The test for hpux may have to be more specific.  In particular, the */
/* code should be skipped on the hp9000s300 and hp9000s720 (but there */
/* is no documented define for the 720!) */

/*#if defined(TIOCSCTTY) && !defined(CIBAUD) && !defined(sun) && !defined(hpux)*/
#if defined(TIOCSCTTY) && !defined(sun) && !defined(hpux)
    /* 4.3+BSD way to acquire controlling terminal */
    /* according to Stevens - Adv. Prog..., p 642 */
    /* Oops, it appears that the CIBAUD is on Linux also */
    /* so let's try without... */
#ifdef __QNX__
    if (tcsetct(0, getpid()) == -1) {
	restore_error_fd
	    expErrorLog("failed to get controlling terminal using TIOCSCTTY");
	exit(-1);
    }
#else
    (void) ioctl(0,TIOCSCTTY,(char *)0);
    /* ignore return value - on some systems, it is defined but it
     * fails and it doesn't seem to cause any problems.  Or maybe
     * it works but returns a bogus code.  Noone seems to be able
     * to explain this to me.  The systems are an assortment of
     * different linux systems (and FreeBSD 2.5), RedHat 5.2 and
     * Debian 2.0
     */
#endif
#endif

#ifdef CRAY
    (void) setsid();
    (void) ioctl(0,TCSETCTTY,0);
    (void) close(0);
    if (open("/dev/tty", O_RDWR) < 0) {
	restore_error_fd
	    expErrorLog("open(/dev/tty): %s\r\n",Tcl_ErrnoMsg(errno));
	exit(-1);
    }
    (void) close(1);
    (void) close(2);
    (void) dup(0);
    (void) dup(0);
    setptyutmp();	/* create a utmp entry */

    /* _CRAY2 code from Hal Peterson <hrp@cray.com>, Cray Research, Inc. */
#ifdef _CRAY2
    /*
     * Interpose a process between expect and the spawned child to
     * keep the slave side of the pty open to allow time for expect
     * to read the last output.  This is a workaround for an apparent
     * bug in the Unicos pty driver on Cray-2's under Unicos 6.0 (at
     * least).
     */
    if ((pid = fork()) == -1) {
	restore_error_fd
	    expErrorLog("second fork: %s\r\n",Tcl_ErrnoMsg(errno));
	exit(-1);
    }

    if (pid) {
	/* Intermediate process. */
	int status;
	int timeout;
	char *t;

	/* How long should we wait? */
	if (t = exp_get_var(interp,"pty_timeout"))
	    timeout = atoi(t);
	else if (t = exp_get_var(interp,"timeout"))
	    timeout = atoi(t)/2;
	else
	    timeout = 5;

	/* Let the spawned process run to completion. */
	while (wait(&status) < 0 && errno == EINTR)
	    /* empty body */;

	/* Wait for the pty to clear. */
	sleep(timeout);

	/* Duplicate the spawned process's status. */
	if (WIFSIGNALED(status))
	    kill(getpid(), WTERMSIG(status));

	/* The kill may not have worked, but this will. */
	exit(WEXITSTATUS(status));
    }
#endif /* _CRAY2 */
#endif /* CRAY */

    if (console) exp_console_set();

#ifdef FULLTRAPS
    for (i=1;i<NSIG;i++) {
	if (traps[i] != SIG_ERR) {
	    signal(i,traps[i]);
	}
    }
#endif /* FULLTRAPS */

    for (i=1;i<NSIG;i++) {
	signal(i,ignore[i]?SIG_IGN:SIG_DFL);
    }

    /*
     * avoid fflush of cmdfile, logfile, & diagfile since this screws up
     * the parents seek ptr.  There is no portable way to fclose a shared
     * read-stream!!!!
     */

    /* (possibly multiple) masters are closed automatically due to */
    /* earlier fcntl(,,CLOSE_ON_EXEC); */

    /* tell parent that we are done setting up pty */
    /* The actual char sent back is irrelevant. */

    /* expDiagLog("child: telling parent that pty is initialized\r\n");*/
    wc = write(sync_fds[1]," ",1);
    if (wc == -1) {
	restore_error_fd
	    expErrorLog("child: sync byte write: %s\r\n",Tcl_ErrnoMsg(errno));
	exit(-1);
    }
    close(sync_fds[1]);

    /* wait for master to let us go on */
    while (((rc = read(sync2_fds[0],&sync_byte,1)) < 0) && (errno == EINTR)) {
	/* empty */;
    }

    if (rc == -1) {
	restore_error_fd
	    expErrorLog("child: sync byte read: %s\r\n",Tcl_ErrnoMsg(errno));
	exit(-1);
    }
    close(sync2_fds[0]);

    /* expDiagLog("child: now unsynchronized from parent\r\n"); */

    argv = (char**) ckalloc ((objc+1)*sizeof(char*));
    for (k=0, i=cmdIndex;i<objc;k++,i++) {
	argv[k] = ckalloc (1+strlen(Tcl_GetString (objv[i])));
	strcpy (argv[k],Tcl_GetString (objv[i]));
    }
    argv[k] = NULL;

    execvp(command,argv);

    for (k=0,i=cmdIndex;i<objc;k++,i++) {
	ckfree (argv[k]);
    }
    ckfree((char*)argv);

    /* Alas, by now we've closed fd's to stderr, logfile and diagfile.
     * The only reasonable thing to do is to send back the error as part of
     * the program output.  This will be picked up in an expect or interact
     * command.
     */

    /* if exec failed, communicate the reason back to the parent */
    write(status_pipe[1], &errno, sizeof errno);
    exit(-1);
    /*NOTREACHED*/
    parent_error:
    Tcl_DStringFree(&dstring);
    if (esPtr) {
        exp_close(interp,esPtr);
	waitpid(esPtr->pid,(int *)&esPtr->wait,0);
	if (esPtr->registered) {
	    Tcl_UnregisterChannel(interp,esPtr->channel);
	}
    }
    return TCL_ERROR;
}

/*ARGSUSED*/
static int
Exp_ExpPidObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    char *chanName = 0;
    ExpState *esPtr = 0;

    static char* options[] = { "-i", NULL };
    enum options { PID_ID };
    int i;

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	    case PID_ID:
		i++;
		if (i >= objc) goto usage;
		chanName = Tcl_GetString (objv[i]);
		break;
	}
    }

    if (chanName) {
	esPtr = expStateFromChannelName(interp,chanName,0,0,0,"exp_pid");
    } else {
	esPtr = expStateCurrent(interp,0,0,0);
    }
    if (!esPtr) return TCL_ERROR;

    Tcl_SetObjResult (interp, Tcl_NewIntObj (esPtr->pid));
    return TCL_OK;
    usage:
    exp_error(interp,"usage: -i spawn_id");
    return TCL_ERROR;
}

/*ARGSUSED*/
static int
Exp_GetpidDeprecatedObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    expDiagLog("getpid is deprecated, use pid\r\n");
    Tcl_SetObjResult (interp, Tcl_NewIntObj (getpid()));
    return(TCL_OK);
}

/*ARGSUSED*/
static int
Exp_SleepObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    double s;

    if (objc != 2) {
	exp_error(interp,"must have one arg: seconds");
	return TCL_ERROR;
    }

    if (TCL_OK != Tcl_GetDoubleFromObj (interp, objv[1], &s)) {
	if (0 == strlen (Tcl_GetString(objv[1]))) {
	    /* Keep undocumented acceptance of "" as 0 = no delay */
	    return TCL_OK;
	}
	return TCL_ERROR;
    }

    return exp_dsleep(interp,s);
}

struct slow_arg {
    int size;
    double time;
};

/* returns 0 for success, -1 for failure */
static int
get_slow_args(
    Tcl_Interp *interp,
    struct slow_arg *x)
{
    int sc;		/* return from scanf */
    CONST char *s = exp_get_var(interp,"send_slow");
    if (!s) {
	exp_error(interp,"send -s: send_slow has no value");
	return(-1);
    }
    if (2 != (sc = sscanf(s,"%d %lf",&x->size,&x->time))) {
	exp_error(interp,"send -s: found %d value(s) in send_slow but need 2",sc);
	return(-1);
    }
    if (x->size <= 0) {
	exp_error(interp,"send -s: size (%d) in send_slow must be positive", x->size);
	return(-1);
    }
    if (x->time <= 0) {
	exp_error(interp,"send -s: time (%f) in send_slow must be larger",x->time);
	return(-1);
    }
    return(0);
}

/* returns 0 for success, -1 for failure, pos. for Tcl return value */
static int
slow_write(
    Tcl_Interp *interp,
    ExpState *esPtr,
    char *buffer,
    int rembytes,
    struct slow_arg *arg)
{
    int rc;

    while (rembytes > 0) {
	int i, bytelen, charlen;
	char *p;

	p = buffer;
	charlen = (arg->size<rembytes?arg->size:rembytes);

	/* count out the right number of UTF8 chars */
	for (i=0;i<charlen;i++) {
	    p = Tcl_UtfNext(p);
	}
	bytelen = p-buffer;

	if (0 > expWriteChars(esPtr,buffer,bytelen)) { return(-1); }
	rembytes -= bytelen;
	buffer += bytelen;

	/* skip sleep after last write */
	if (rembytes > 0) {
	    rc = exp_dsleep(interp,arg->time);
	    if (rc>0) return rc;
	}
    }
    return(0);
}

struct human_arg {
    float alpha;		/* average interarrival time in seconds */
    float alpha_eow;	/* as above but for eow transitions */
    float c;		/* shape */
    float min, max;
};

/* returns -1 if error, 0 if success */
static int
get_human_args(
    Tcl_Interp *interp,
    struct human_arg *x)
{
    int sc;		/* return from scanf */
    CONST char *s = exp_get_var(interp,"send_human");

    if (!s) {
	exp_error(interp,"send -h: send_human has no value");
	return(-1);
    }
    if (5 != (sc = sscanf(s,"%f %f %f %f %f",
			    &x->alpha,&x->alpha_eow,&x->c,&x->min,&x->max))) {
	if (sc == EOF) sc = 0;	/* make up for overloaded return */
	exp_error(interp,"send -h: found %d value(s) in send_human but need 5",sc);
	return(-1);
    }
    if (x->alpha < 0 || x->alpha_eow < 0) {
	exp_error(interp,"send -h: average interarrival times (%f %f) must be non-negative in send_human", x->alpha,x->alpha_eow);
	return(-1);
    }
    if (x->c <= 0) {
	exp_error(interp,"send -h: variability (%f) in send_human must be positive",x->c);
	return(-1);
    }
    x->c = 1/x->c;

    if (x->min < 0) {
	exp_error(interp,"send -h: minimum (%f) in send_human must be non-negative",x->min);
	return(-1);
    }
    if (x->max < 0) {
	exp_error(interp,"send -h: maximum (%f) in send_human must be non-negative",x->max);
	return(-1);
    }
    if (x->max < x->min) {
	exp_error(interp,"send -h: maximum (%f) must be >= minimum (%f) in send_human",x->max,x->min);
	return(-1);
    }
    return(0);
}

/* Compute random numbers from 0 to 1, for expect's send -h */
/* This implementation sacrifices beauty for portability */
static float
unit_random()
{
    /* current implementation is pathetic but works */
    /* 99991 is largest prime in my CRC - can't hurt, eh? */
    return((float)(1+(rand()%99991))/99991.0);
}

void
exp_init_unit_random()
{
    srand(getpid());
}

/* This function is my implementation of the Weibull distribution. */
/* I've added a max time and an "alpha_eow" that captures the slight */
/* but noticable change in human typists when hitting end-of-word */
/* transitions. */
/* returns 0 for success, -1 for failure, pos. for Tcl return value */
static int
human_write(
    Tcl_Interp *interp,
    ExpState *esPtr,
    char *buffer,
    struct human_arg *arg)
{
    char *sp;
    int size;
    float t;
    float alpha;
    int wc;
    int in_word = TRUE;
    Tcl_UniChar ch;

    expDiagLog("human_write: avg_arr=%f/%f  1/shape=%f  min=%f  max=%f\r\n",
	    arg->alpha,arg->alpha_eow,arg->c,arg->min,arg->max);

    for (sp = buffer;*sp;sp += size) {
	size = Tcl_UtfToUniChar(sp, &ch);
	/* use the end-of-word alpha at eow transitions */
	if (in_word && (Tcl_UniCharIsPunct(ch) || Tcl_UniCharIsSpace(ch)))
	    alpha = arg->alpha_eow;
	else alpha = arg->alpha;
	in_word = !(Tcl_UniCharIsPunct(ch) || Tcl_UniCharIsSpace(ch));

	t = alpha * pow(-log((double)unit_random()),arg->c);

	/* enforce min and max times */
	if (t<arg->min) t = arg->min;
	else if (t>arg->max) t = arg->max;

	/* skip sleep before writing first character */
	if (sp != buffer) {
	    wc = exp_dsleep(interp,(double)t);
	    if (wc > 0) return wc;
	}

	wc = expWriteChars(esPtr, sp, size);
	if (0 > wc) return(wc);
    }
    return(0);
}

struct exp_i *exp_i_pool = 0;
struct exp_state_list *exp_state_list_pool = 0;

#define EXP_I_INIT_COUNT	10
#define EXP_FD_INIT_COUNT	10

struct exp_i *
exp_new_i()
{
    int n;
    struct exp_i *i;

    if (!exp_i_pool) {
	/* none avail, generate some new ones */
	exp_i_pool = i = (struct exp_i *)ckalloc(
	    EXP_I_INIT_COUNT * sizeof(struct exp_i));
	for (n=0;n<EXP_I_INIT_COUNT-1;n++,i++) {
	    i->next = i+1;
	}
	i->next = 0;
    }

    /* now that we've made some, unlink one and give to user */

    i = exp_i_pool;
    exp_i_pool = exp_i_pool->next;
    i->value = 0;
    i->variable = 0;
    i->state_list = 0;
    i->ecount = 0;
    i->next = 0;
    return i;
}

struct exp_state_list *
exp_new_state(ExpState *esPtr)
{
    int n;
    struct exp_state_list *fd;

    if (!exp_state_list_pool) {
	/* none avail, generate some new ones */
	exp_state_list_pool = fd = (struct exp_state_list *)ckalloc(
	    EXP_FD_INIT_COUNT * sizeof(struct exp_state_list));
	for (n=0;n<EXP_FD_INIT_COUNT-1;n++,fd++) {
	    fd->next = fd+1;
	}
	fd->next = 0;
    }

    /* now that we've made some, unlink one and give to user */

    fd = exp_state_list_pool;
    exp_state_list_pool = exp_state_list_pool->next;
    fd->esPtr = esPtr;
    /* fd->next is assumed to be changed by caller */
    return fd;
}

void
exp_free_state(struct exp_state_list *fd_first)
{
    struct exp_state_list *fd, *penultimate;

    if (!fd_first) return;

    /* link entire chain back in at once by first finding last pointer */
    /* making that point back to pool, and then resetting pool to this */

    /* run to end */
    for (fd = fd_first;fd;fd=fd->next) {
	penultimate = fd;
    }
    penultimate->next = exp_state_list_pool;
    exp_state_list_pool = fd_first;
}

/* free a single fd */
void
exp_free_state_single(struct exp_state_list *fd)
{
    fd->next = exp_state_list_pool;
    exp_state_list_pool = fd;
}

void
exp_free_i(
    Tcl_Interp *interp,
    struct exp_i *i,
    Tcl_VarTraceProc *updateproc)/* proc to invoke if indirect is written */
{
    if (i->next) exp_free_i(interp,i->next,updateproc);

    exp_free_state(i->state_list);

    if (i->direct == EXP_INDIRECT) {
	Tcl_UntraceVar(interp,i->variable, TCL_GLOBAL_ONLY|TCL_TRACE_WRITES,
		updateproc, (ClientData)i);
    }

    /* here's the long form
       if duration & direct	free(var)  free(val)
       PERM	  DIR	    		1
       PERM	  INDIR	    1		1
       TMP	  DIR
       TMP	  INDIR			1
       Also if i->variable was a bogus variable name, i->value might not be
       set, so test i->value to protect this
       TMP in this case does NOT mean from the "expect" command.  Rather
       it means "an implicit spawn id from any expect or expect_XXX
       command".  In other words, there was no variable name provided.
    */
    if (i->value
	    && (((i->direct == EXP_DIRECT) && (i->duration == EXP_PERMANENT))
		    || ((i->direct == EXP_INDIRECT) && (i->duration == EXP_TEMPORARY)))) {
	ckfree(i->value);
    } else if (i->duration == EXP_PERMANENT) {
	if (i->value) ckfree(i->value);
	if (i->variable) ckfree(i->variable);
    }

    i->next = exp_i_pool;
    exp_i_pool = i;
}

/* generate a descriptor for a "-i" flag */
/* can only fail on bad direct descriptors */
/* indirect descriptors always succeed */
struct exp_i *
exp_new_i_complex(
    Tcl_Interp *interp,
    char *arg,		/* spawn id list or a variable containing a list */
    int duration,		/* if we have to copy the args */
    /* should only need do this in expect_before/after */
    Tcl_VarTraceProc *updateproc)	/* proc to invoke if indirect is written */
{
    struct exp_i *i;
    char **stringp;

    i = exp_new_i();

    i->direct = (isExpChannelName(arg) || (0 == strcmp(arg, EXP_SPAWN_ID_ANY_LIT))?EXP_DIRECT:EXP_INDIRECT);
#if OBSOLETE
    i->direct = (isdigit(arg[0]) || (arg[0] == '-'))?EXP_DIRECT:EXP_INDIRECT;
#endif
    if (i->direct == EXP_DIRECT) {
	stringp = &i->value;
    } else {
	stringp = &i->variable;
    }

    i->duration = duration;
    if (duration == EXP_PERMANENT) {
	*stringp = ckalloc(strlen(arg)+1);
	strcpy(*stringp,arg);
    } else {
	*stringp = arg;
    }

    i->state_list = 0;
    if (TCL_ERROR == exp_i_update(interp,i)) {
	exp_free_i(interp,i,(Tcl_VarTraceProc *)0);
	return 0;
    }

    /* if indirect, ask Tcl to tell us when variable is modified */

    if (i->direct == EXP_INDIRECT) {
	Tcl_TraceVar(interp, i->variable,
		TCL_GLOBAL_ONLY|TCL_TRACE_WRITES,
		updateproc, (ClientData) i);
    }

    return i;
}

void
exp_i_add_state(
    struct exp_i *i,
    ExpState *esPtr)
{
    struct exp_state_list *new_state;

    new_state = exp_new_state(esPtr);
    new_state->next = i->state_list;
    i->state_list = new_state;
}

/* this routine assumes i->esPtr is meaningful */
/* returns TCL_ERROR only on direct */
/* indirects always succeed */
static int
exp_i_parse_states(
    Tcl_Interp *interp,
    struct exp_i *i)
{
    struct ExpState *esPtr;
    char *p = i->value;
    int argc;
    char **argv;
    int j;

    if (Tcl_SplitList(NULL, p, &argc, &argv) != TCL_OK) goto error;

    for (j = 0; j < argc; j++) {
        esPtr = expStateFromChannelName(interp,argv[j],1,0,1,"");
	if (!esPtr) goto error;
	exp_i_add_state(i,esPtr);
    }
    ckfree((char*)argv);
    return TCL_OK;
    error:
    expDiagLogU("exp_i_parse_states: ");
    expDiagLogU(Tcl_GetStringResult(interp));
    return TCL_ERROR;
}

/* updates a single exp_i struct */
/* return TCL_ERROR only on direct variables */
/* indirect variables always succeed */
int
exp_i_update(
    Tcl_Interp *interp,
    struct exp_i *i)
{
    char *p;	/* string representation of list of spawn ids */

    if (i->direct == EXP_INDIRECT) {
	p = Tcl_GetVar(interp,i->variable,TCL_GLOBAL_ONLY);
	if (!p) {
	    p = "";
	    /* *really* big variable names could blow up expDiagLog! */
	    expDiagLog("warning: indirect variable %s undefined",i->variable);
	}

	if (i->value) {
	    if (streq(p,i->value)) return TCL_OK;

	    /* replace new value with old */
	    ckfree(i->value);
	}
	i->value = ckalloc(strlen(p)+1);
	strcpy(i->value,p);

	exp_free_state(i->state_list);
	i->state_list = 0;
    } else {
	/* no free, because this should only be called on */
	/* "direct" i's once */
	i->state_list = 0;
    }
    return exp_i_parse_states(interp, i);
}

struct exp_i *
exp_new_i_simple(
    ExpState *esPtr,
    int duration)		/* if we have to copy the args */
    /* should only need do this in expect_before/after */
{
    struct exp_i *i;

    i = exp_new_i();

    i->direct = EXP_DIRECT;
    i->duration = duration;

    exp_i_add_state(i,esPtr);

    return i;
}

/*ARGSUSED*/
static int
Exp_SendLogObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    static char* options[] = { "--", NULL };
    enum options { LOG_QUOTE };
    int i;

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	if (((enum options) index) == LOG_QUOTE) {
	    i++;
	    break;
	}
    }

    if (i != (objc-1)) goto usage;

    expLogDiagU(Tcl_GetString (objv[i]));
    return(TCL_OK);

    usage:
    exp_error(interp,"usage: send [args] string");
    return TCL_ERROR;
}


/* I've rewritten this to be unbuffered.  I did this so you could shove */
/* large files through "send".  If you are concerned about efficiency */
/* you should quote all your send args to make them one single argument. */
/*ARGSUSED*/
static int
Exp_SendObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    ExpState *esPtr = 0;
    int rc; 	/* final result of this procedure */
    struct human_arg human_args;
    struct slow_arg slow_args;
#define SEND_STYLE_STRING_MASK	0x07	/* mask to detect a real string arg */
#define SEND_STYLE_PLAIN	0x01
#define SEND_STYLE_HUMAN	0x02
#define SEND_STYLE_SLOW		0x04
#define SEND_STYLE_ZERO		0x10
#define SEND_STYLE_BREAK	0x20
    int send_style = SEND_STYLE_PLAIN;
    int want_cooked = TRUE;
    char *string;		/* string to send */
    int len = -1;		/* length of string to send */
    int zeros;		/* count of how many ascii zeros to send */

    char *chanName = 0;
    struct exp_state_list *state_list;
    struct exp_i *i;
    int j;

    static char *options[] = {
	"-i", "-h", "-s", "-null", "-0", "-raw", "-break", "--", (char *)0
    };
    enum options {
	SEND_SPAWNID, SEND_HUMAN, SEND_SLOW, SEND_NULL, SEND_ZERO,
	SEND_RAW, SEND_BREAK, SEND_LAST
    };

    for (j = 1; j < objc; j++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[j]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[j], options, "flag", 0,
			&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	    case SEND_SPAWNID:
		j++;
		chanName = Tcl_GetString(objv[j]);
		break;

	    case SEND_LAST:
		j++;
		goto getString;

	    case SEND_HUMAN:
		if (-1 == get_human_args(interp,&human_args))
		    return(TCL_ERROR);
		send_style = SEND_STYLE_HUMAN;
		break;

	    case SEND_SLOW:
		if (-1 == get_slow_args(interp,&slow_args))
		    return(TCL_ERROR);
		send_style = SEND_STYLE_SLOW;
		break;

	    case SEND_NULL:
	    case SEND_ZERO:
		j++;
		if (j >= objc) {
		    zeros = 1;
		} else if (Tcl_GetIntFromObj(interp, objv[j], &zeros)
			!= TCL_OK) {
		    return TCL_ERROR;
		}
		if (zeros < 1) return TCL_OK;
		send_style = SEND_STYLE_ZERO;
		string = "<zero(s)>";
		break;

	    case SEND_RAW:
		want_cooked = FALSE;
		break;

	    case SEND_BREAK:
		send_style = SEND_STYLE_BREAK;
		string = "<break>";
		break;
	}
    }

    if (send_style & SEND_STYLE_STRING_MASK) {
	getString:
	if (j != objc-1) {
	    exp_error(interp,"usage: send [args] string");
	    return TCL_ERROR;
	}
	string = Tcl_GetStringFromObj(objv[j], &len);
    } else {
	len = strlen(string);
    }

    if (clientData == &sendCD_user) esPtr = tsdPtr->stdinout;
    else if (clientData == &sendCD_error) esPtr = tsdPtr->stderrX;
    else if (clientData == &sendCD_tty) {
	esPtr = tsdPtr->devtty;
	if (!esPtr) {
	    exp_error(interp,"send_tty: cannot send to controlling terminal in an environment when there is no controlling terminal to send to!");
	    return TCL_ERROR;
	}
    } else if (!chanName) {
	/* we want to check if it is open */
	/* but since stdin could be closed, we have to first */
	/* get the fd and then convert it from 0 to 1 if necessary */
	if (!(esPtr = expStateCurrent(interp,0,0,0))) return(TCL_ERROR);
    }

    if (esPtr) {
	i = exp_new_i_simple(esPtr,EXP_TEMPORARY);
    } else {
	i = exp_new_i_complex(interp,chanName,FALSE,(Tcl_VarTraceProc *)0);
	if (!i) return TCL_ERROR;
    }

#define send_to_stderr	(clientData == &sendCD_error)
#define send_to_proc	(clientData == &sendCD_proc)
#define send_to_user	((clientData == &sendCD_user) ||	\
	    (clientData == &sendCD_tty))

    if (send_to_proc) {
	want_cooked = FALSE;
	expDiagLogU("send: sending \"");
	expDiagLogU(expPrintify(string));
	expDiagLogU("\" to {");
	/* if closing brace doesn't appear, that's because an error */
	/* was encountered before we could send it */
    } else {
	expLogDiagU(string);
    }

    for (state_list=i->state_list;state_list;state_list=state_list->next) {
	esPtr = state_list->esPtr;

	if (send_to_proc) {
	    expDiagLog(" %s ",esPtr->name);
	}

	/* check validity of each - i.e., are they open */
	if (0 == expStateCheck(interp,esPtr,1,0,"send")) {
	    rc = TCL_ERROR;
	    goto finish;
	}
	if (want_cooked) string = exp_cook(string,&len);

	switch (send_style) {
	    case SEND_STYLE_PLAIN:
		rc = expWriteChars(esPtr,string,len);
		break;
	    case SEND_STYLE_SLOW:
		rc = slow_write(interp,esPtr,string,len,&slow_args);
		break;
	    case SEND_STYLE_HUMAN:
		rc = human_write(interp,esPtr,string,&human_args);
		break;
	    case SEND_STYLE_ZERO:
		for (;zeros>0;zeros--) {
		    rc = expWriteChars(esPtr,NULL_STRING,NULL_LENGTH);
		}
		/* catching error on last write is sufficient */
		break;
	    case SEND_STYLE_BREAK:
		exp_tty_break(interp,esPtr->fdout);
		rc = 0;
		break;
	}

	if (rc != 0) {
	    if (rc == -1) {
		exp_error(interp,"write(spawn_id=%d): %s",esPtr->fdout,Tcl_PosixError(interp));
		rc = TCL_ERROR;
	    }
	    goto finish;
	}
    }
    if (send_to_proc) expDiagLogU("}\r\n");

    rc = TCL_OK;
    finish:
    exp_free_i(interp,i,(Tcl_VarTraceProc *)0);
    return rc;
}

/*ARGSUSED*/
static int
Exp_LogFileObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    static char resultbuf[1000];
    char *chanName = 0;
    int leaveOpen = FALSE;
    int logAll = FALSE;
    int append = TRUE;
    char *filename = 0;
    int i;

    static char* options[] = {
	"-a",
	"-info",
	"-leaveopen",
	"-noappend",
	"-open",
	NULL
    };
    enum options {
	LOGFILE_A,
	LOGFILE_INFO,
	LOGFILE_LEAVEOPEN,
	LOGFILE_NOAPPEND,
	LOGFILE_OPEN
    };

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	    case LOGFILE_A:
		logAll = TRUE;
		break;
	    case LOGFILE_INFO:
		resultbuf[0] = '\0';
		if (expLogChannelGet()) {
		    /* FUTURE: Use List-ops to construct a proper Tcl_Obj */
		    if (expLogAllGet()) strcat(resultbuf,"-a ");
		    if (!expLogAppendGet()) strcat(resultbuf,"-noappend ");
		    if (expLogFilenameGet()) {
			strcat(resultbuf,expLogFilenameGet());
		    } else {
			if (expLogLeaveOpenGet()) {
			    strcat(resultbuf,"-leaveopen ");
			}
			strcat(resultbuf,Tcl_GetChannelName(expLogChannelGet()));
		    }
		    Tcl_SetResult(interp,resultbuf,TCL_STATIC);
		}
		return TCL_OK;
	    case LOGFILE_LEAVEOPEN:
		i ++;
		if (i >= objc) goto usage_error;
		chanName = Tcl_GetString (objv[i]);
		leaveOpen = TRUE;
		break;
	    case LOGFILE_NOAPPEND:
		append = FALSE;
		break;
	    case LOGFILE_OPEN:
		i++;
		if (i >= objc) goto usage_error;
		chanName = Tcl_GetString (objv[i]);
		break;
	}
    }
    
    if (i == (objc - 1)) {
	filename = Tcl_GetString (objv[i]);
    } else if (objc > i) {
	/* too many arguments */
	goto usage_error;
    } 
    
    if (chanName && filename) {
	goto usage_error;
    }

    /* check if user merely wants to change logAll (-a) */
    if (expLogChannelGet() && (chanName || filename)) {
	if (filename && (0 == strcmp(filename,expLogFilenameGet()))) {
	    expLogAllSet(logAll);
	    return TCL_OK;
	} else if (chanName &&
		(0 == strcmp(chanName,Tcl_GetChannelName(expLogChannelGet())))) {
	    expLogAllSet(logAll);
	    return TCL_OK;
	} else {
	    exp_error(interp,"cannot start logging without first stopping logging");
	    return TCL_ERROR;
	}
    }

    if (filename) {
	if (TCL_ERROR == expLogChannelOpen(interp,filename,append)) {
	    return TCL_ERROR;
	}
    } else if (chanName) {
	if (TCL_ERROR == expLogChannelSet(interp,chanName)) {
	    return TCL_ERROR;
	}
    } else {
	expLogChannelClose(interp);
	if (logAll) {
	    exp_error(interp,"cannot use -a without a file or channel");
	    return TCL_ERROR;
	}
    }
    expLogAllSet(logAll);
    expLogLeaveOpenSet(leaveOpen);

    return TCL_OK;

    usage_error:
    exp_error(interp,"usage: log_file [-info] [-noappend] [[-a] file] [-[leave]open [open ...]]");
    return TCL_ERROR;
}

/*ARGSUSED*/
static int
Exp_LogUserObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int old_loguser = expLogUserGet();

    if (objc == 0 || (objc == 2 && streq(Tcl_GetString (objv[1]),"-info"))) {
	/* do nothing */
    } else if (objc == 2) {
	int flag;
	if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[1], &flag)) {
	    if (0 == strlen (Tcl_GetString(objv[1]))) {
		/* Keep undocumented acceptance of "" as 0. */
		flag = 0;
	    } else {
		return TCL_ERROR;
	    }
	}
	expLogUserSet(flag);
    } else {
	exp_error(interp,"usage: [-info|1|0]");
    }

    Tcl_SetObjResult (interp, Tcl_NewIntObj (old_loguser));
    return(TCL_OK);
}

#ifdef TCL_DEBUGGER
/*ARGSUSED*/
static int
Exp_DebugObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int now = FALSE;	/* soon if FALSE, now if TRUE */
    int exp_tcl_debugger_was_available = exp_tcl_debugger_available;

    static char* options[] = { "-now", NULL };
    enum options { DEBUG_NOW };
    int i;

    if (objc > 3) goto usage;

    if (objc == 1) {
	Tcl_SetObjResult (interp, Tcl_NewIntObj (exp_tcl_debugger_available));
	return TCL_OK;
    }

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	    case DEBUG_NOW:
		now = TRUE;
		break;
	}
    }

    if (i == objc) {
	if (now) {
	    Dbg_On(interp,1);
	    exp_tcl_debugger_available = 1;
	} else {
	    goto usage;
	}
    } else {
	int flag;
	if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[i], &flag)) {
	    goto usage;
	}
	if (!flag) {
	    Dbg_Off(interp);
	    exp_tcl_debugger_available = 0;
	} else {
	    Dbg_On(interp,now);
	    exp_tcl_debugger_available = 1;
	}
    }
    Tcl_SetObjResult (interp, Tcl_NewBooleanObj (exp_tcl_debugger_was_available));
    return(TCL_OK);
    usage:
    exp_error(interp,"usage: [[-now] 1|0]");
    return TCL_ERROR;
}
#endif


/*ARGSUSED*/
static int
Exp_ExpInternalObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int newChannel = FALSE;
    Tcl_Channel oldChannel;
    static char resultbuf[1000];
    int flag, i;

    static char* options[] = {
	"-f",
	"-info",
	NULL
    };
    enum options {
	INTERNAL_F,
	INTERNAL_INFO
    };

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	    case INTERNAL_INFO:
		/* FUTURE: Construct a proper list Tcl_Obj here */
		/* Should check that there are no arguments coming after -info */

		resultbuf[0] = '\0';
		oldChannel = expDiagChannelGet();
		if (oldChannel) {
		    sprintf(resultbuf,"-f %s ",expDiagFilename());
		}
		strcat(resultbuf,expDiagToStderrGet()?"1":"0");
		Tcl_SetResult(interp,resultbuf,TCL_STATIC);
		return TCL_OK;
	    case INTERNAL_F:
		i ++;
		if (i >= objc) goto usage;
		expDiagChannelClose(interp);
		if (TCL_OK != expDiagChannelOpen(interp,Tcl_GetString (objv[i]))) {
		    return TCL_ERROR;
		}
		newChannel = TRUE;
		break;
	}
    }

    if (i >= objc) goto usage;

    if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[i], &flag)) {
	goto usage;
    }
    
    /* if no -f given, close file */
    if (!newChannel) {
	expDiagChannelClose(interp);
    }

    expDiagToStderrSet(flag);
    return(TCL_OK);
    usage:
    exp_error(interp,"usage: [-f file] 0|1");
    return TCL_ERROR;
}

char *exp_onexit_action = 0;

/*ARGSUSED*/
static int
Exp_ExitObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int value = 0;

    objc--;
    objv++;

    if (objc) {
	if (exp_flageq(Tcl_GetString (objv[0]),"-onexit",3)) {
	    objc--;
	    objv++;
	    if (objc) {
		int len;
		char* act = Tcl_GetStringFromObj (objv[0], &len);

		if (exp_onexit_action)
		    ckfree(exp_onexit_action);

		exp_onexit_action = ckalloc(len + 1);
		strcpy(exp_onexit_action,act);

	    } else if (exp_onexit_action) {
		Tcl_AppendResult(interp,exp_onexit_action,(char *)0);
	    }
	    return TCL_OK;
	} else if (exp_flageq(Tcl_GetString (objv[0]),"-noexit",3)) {
	    objc--;
	    objv++;
	    exp_exit_handlers((ClientData)interp);
	    return TCL_OK;
	}
    }

    if (objc) {
	if (Tcl_GetIntFromObj(interp, objv[0], &value) != TCL_OK) {
	    return TCL_ERROR;
	}
    }

    /*
     * Restore previous definition of close.  Needed when expect is
     * dynamically loaded after close has been redefined
     * e.g.  the virtual file system in tclkit
     */
    Tcl_Eval(interp, "rename _close.pre_expect close");
    Tcl_Exit(value);
    /*NOTREACHED*/
    return TCL_ERROR;
}

/*ARGSUSED*/
static int
Exp_ConfigureObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])	/* Argument objects. */
{
    /* Magic configuration stuff. */
    int i, opt, val;

    static CONST86 char* options [] = {
	"-strictwrite", NULL
    };
    enum options {
	EXP_STRICTWRITE
    };

    if ((objc < 3) || (objc % 2 == 0)) {
	Tcl_WrongNumArgs (interp, 1, objv, "-strictwrite value");
	return TCL_ERROR;
    }

    for (i=1; i < objc; i+=2) {
	if (Tcl_GetIndexFromObj (interp, objv [i], options, "option",
			0, &opt) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch (opt) {
	    case EXP_STRICTWRITE:
		if (Tcl_GetBooleanFromObj (interp, objv [i+1], &val) != TCL_OK) {
		    return TCL_ERROR;
		}
		exp_strict_write = val;
		break;
	}
    }

    return TCL_OK;
}

/*ARGSUSED*/
static int
Exp_CloseObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[]) 	/* Argument objects. */
{
    int onexec_flag = FALSE;	/* true if -onexec seen */
    int close_onexec;
    int slave_flag = FALSE;
    ExpState *esPtr = 0;
    char *chanName = 0;
    int i;

    static char* options[] = {
	"-i",
	"-onexec",
	"-slave",
	NULL
    };
    enum options {
	CLOSE_ID,
	CLOSE_ONEXEC,
	CLOSE_SLAVE
    };

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	    case CLOSE_ID:
		i++;
		if (i == objc) {
		    exp_error(interp,"usage: -i spawn_id");
		    return(TCL_ERROR);
		}
		chanName = Tcl_GetString(objv[i]);
		break;
	    case CLOSE_ONEXEC:
		i++;
		if (i == objc) {
		    on_exec_usage:
		    exp_error(interp,"usage: -onexec 0|1");
		    return(TCL_ERROR);
		}
		onexec_flag = TRUE;
		if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[i], &close_onexec)) {
		    goto on_exec_usage;
		}
		break;
	    case CLOSE_SLAVE:
		slave_flag = TRUE;
		break;
	}
    }

    if (i < objc) {
	/* doesn't look like our format, it must be a Tcl-style file */
	/* handle.  Lucky that formats are easily distinguishable. */
	/* Historical note: we used "close"  long before there was a */
	/* Tcl builtin by the same name. */

        Tcl_CmdInfo* close_info;

	Tcl_ResetResult(interp);

	close_info = (Tcl_CmdInfo*) Tcl_GetAssocData (interp, EXP_CMDINFO_CLOSE, NULL);
	return(close_info->objProc(close_info->objClientData,interp,objc,objv));
    }

    if (chanName) {
	esPtr = expStateFromChannelName(interp,chanName,1,0,0,"close");
    } else {
	esPtr = expStateCurrent(interp,1,0,0);
    }
    if (!esPtr) return TCL_ERROR;

    if (slave_flag) {
	if (esPtr->fd_slave != EXP_NOFD) {
	    close(esPtr->fd_slave);
	    esPtr->fd_slave = EXP_NOFD;

	    exp_slave_control(esPtr->fdin,1);

	    return TCL_OK;
	} else {
	    exp_error(interp,"no such slave");
	    return TCL_ERROR;
	}
    }

    if (onexec_flag) {
	/* heck, don't even bother to check if fd is open or a real */
	/* spawn id, nothing else depends on it */
	fcntl(esPtr->fdin,F_SETFD,close_onexec);
	return TCL_OK;
    }

    return(exp_close(interp,esPtr));
}

/*ARGSUSED*/
static int
tcl_tracer(
    ClientData clientData,
    Tcl_Interp *interp,
    int level,
    CONST char *command,
    Tcl_Command cmdInfo,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int i;

    /* come out on stderr, by using expErrorLog */
    expErrorLog("%2d",level);
    for (i = 0;i<level;i++) expErrorLogU("  ");
    expErrorLogU((char*)command);
    expErrorLogU("\r\n");
    return TCL_OK;
}

static void
tcl_tracer_del(ClientData clientData)
{
    /* Nothing */
}

/*ARGSUSED*/
static int
Exp_StraceObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    static int trace_level = 0;
    static Tcl_Trace trace_handle;

    if (objc > 1 && streq(Tcl_GetString (objv[1]),"-info")) {
	Tcl_SetObjResult (interp, Tcl_NewIntObj (trace_level));
	return TCL_OK;
    }

    if (objc != 2) {
	exp_error(interp,"usage: trace level");
	return(TCL_ERROR);
    }
    /* tracing already in effect, undo it */
    if (trace_level > 0) Tcl_DeleteTrace(interp,trace_handle);

    /* get and save new trace level */

    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[1], &trace_level)) {
	return TCL_ERROR;
    }

    if (trace_level > 0)
	trace_handle = Tcl_CreateObjTrace(interp, trace_level,0,
		tcl_tracer,(ClientData)0,
		tcl_tracer_del);
    return(TCL_OK);
}

/* following defn's are stolen from tclUnix.h */

/*
 * The type of the status returned by wait varies from UNIX system
 * to UNIX system.  The macro below defines it:
 */

#if 0
#ifndef NO_UNION_WAIT
#   define WAIT_STATUS_TYPE union wait
#else
#   define WAIT_STATUS_TYPE int
#endif
#endif /* 0 */

/*
 * following definitions stolen from tclUnix.h
 * (should have been made public!)

 * Supply definitions for macros to query wait status, if not already
 * defined in header files above.
 */

#if 0
#ifndef WIFEXITED
#   define WIFEXITED(stat)  (((*((int *) &(stat))) & 0xff) == 0)
#endif

#ifndef WEXITSTATUS
#   define WEXITSTATUS(stat) (((*((int *) &(stat))) >> 8) & 0xff)
#endif

#ifndef WIFSIGNALED
#   define WIFSIGNALED(stat) (((*((int *) &(stat)))) && ((*((int *) &(stat))) == ((*((int *) &(stat))) & 0x00ff)))
#endif

#ifndef WTERMSIG
#   define WTERMSIG(stat)    ((*((int *) &(stat))) & 0x7f)
#endif

#ifndef WIFSTOPPED
#   define WIFSTOPPED(stat)  (((*((int *) &(stat))) & 0xff) == 0177)
#endif

#ifndef WSTOPSIG
#   define WSTOPSIG(stat)    (((*((int *) &(stat))) >> 8) & 0xff)
#endif
#endif /* 0 */

/* end of stolen definitions */

/* Describe the processes created with Expect's fork.
   This allows us to wait on them later.

   This is maintained as a linked list.  As additional procs are forked,
   new links are added.  As procs disappear, links are marked so that we
   can reuse them later.
*/

struct forked_proc {
    int pid;
    WAIT_STATUS_TYPE wait_status;
    enum {not_in_use, wait_done, wait_not_done} link_status;
    struct forked_proc *next;
} *forked_proc_base = 0;

void
fork_clear_all()
{
    struct forked_proc *f;

    for (f=forked_proc_base;f;f=f->next) {
	f->link_status = not_in_use;
    }
}

void
fork_init(
    struct forked_proc *f,
    int pid)
{
    f->pid = pid;
    f->link_status = wait_not_done;
}

/* make an entry for a new proc */
void
fork_add(int pid)
{
    struct forked_proc *f;

    for (f=forked_proc_base;f;f=f->next) {
	if (f->link_status == not_in_use) break;
    }

    /* add new entry to the front of the list */
    if (!f) {
	f = (struct forked_proc *)ckalloc(sizeof(struct forked_proc));
	f->next = forked_proc_base;
	forked_proc_base = f;
    }
    fork_init(f,pid);
}

/* Provide a last-chance guess for this if not defined already */
#ifndef WNOHANG
#define WNOHANG WNOHANG_BACKUP_VALUE
#endif

/* wait returns are a hodgepodge of things
   If wait fails, something seriously has gone wrong, for example:
   bogus arguments (i.e., incorrect, bogus spawn id)
   no children to wait on
   async event failed
   If wait succeeeds, something happened on a particular pid
   3rd arg is 0 if successfully reaped (if signal, additional fields supplied)
   3rd arg is -1 if unsuccessfully reaped (additional fields supplied)
*/
/*ARGSUSED*/
static int
Exp_WaitObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    char *chanName = 0;
    struct ExpState *esPtr;
    struct forked_proc *fp = 0;	/* handle to a pure forked proc */
    struct ExpState esTmp;	/* temporary memory for either f or fp */
    char spawn_id[20];

    int nowait = FALSE;
    int result = 0;		/* 0 means child was successfully waited on */
				/* -1 means an error occurred */
				/* -2 means no eligible children to wait on */

    static char* options[] = {
	"-i",
	"-nowait",
	NULL
    };
    enum options {
	WAIT_ID,
	WAIT_NOWAIT
    };
    int i;

#define NO_CHILD (-2)

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	    case WAIT_ID:
		i++;
		if (i >= objc) goto usage;
		chanName = Tcl_GetString (objv[i]);
		break;
	    case WAIT_NOWAIT:
		nowait = TRUE;
		break;
	}
    }

    if (!chanName) {
	esPtr = expStateCurrent(interp,0,0,1);
    } else {
	esPtr = expStateFromChannelName(interp,chanName,0,0,1,"wait");
    }
    if (!esPtr) return TCL_ERROR;

    if (!expStateAnyIs(esPtr)) {
	/* check if waited on already */
	/* things opened by "open" or set with -nowait */
	/* are marked sys_waited already */
	if (!esPtr->sys_waited) {
	    if (nowait) {
		Tcl_Pid pid = (Tcl_Pid)(long)esPtr->pid;
		/* should probably generate an error */
		/* if SIGCHLD is trapped. */

		/* pass to Tcl, so it can do wait */
		/* in background */
		Tcl_DetachPids(1,&pid);
		exp_wait_zero(&esPtr->wait);
	    } else {
		while (1) {
		    if (Tcl_AsyncReady()) {
			int rc = Tcl_AsyncInvoke(interp,TCL_OK);
			if (rc != TCL_OK) return(rc);
		    }

		    result = waitpid(esPtr->pid,(int *)&esPtr->wait,0);
		    if (result == esPtr->pid) break;
		    if (result == -1) {
			if (errno == EINTR) continue;
			else break;
		    }
		}
	    }
	}

	/*
	 * Now have Tcl reap anything we just detached. 
	 * This also allows procs user has created with "exec &"
	 * and and associated with an "exec &" process to be reaped.
	 */
	
	Tcl_ReapDetachedProcs();
	exp_rearm_sigchld(interp); /* new */

	strcpy(spawn_id,esPtr->name);
    } else {
	/* wait for any of our own spawned processes */
	/* we call waitpid rather than wait to avoid running into */
	/* someone else's processes.  Yes, according to Ousterhout */
	/* this is the best way to do it. */

	int waited_on_forked_process = 0;

	esPtr = expWaitOnAny();
	if (!esPtr) {
	    /* if it's not a spawned process, maybe its a forked process */
	    for (fp=forked_proc_base;fp;fp=fp->next) {
		if (fp->link_status == not_in_use) continue;
		restart:
		result = waitpid(fp->pid,(int *)&fp->wait_status,WNOHANG);
		if (result == fp->pid) {
		    waited_on_forked_process = 1;
		    break;
		}
		if (result == 0) continue;	/* busy, try next */
		if (result == -1) {
		    if (errno == EINTR) goto restart;
		    else break;
		}
	    }

	    if (waited_on_forked_process) {
		/*
		 * The literal spawn id in the return value from wait appears
		 * as a -1 to indicate a forked process was waited on.  
		 */
		strcpy(spawn_id,"-1");
	    } else {
		result = NO_CHILD;	/* no children */
		Tcl_ReapDetachedProcs();
	    }
	    exp_rearm_sigchld(interp);
	}
    }

    /*  sigh, wedge forked_proc into an ExpState structure so we don't
     *  have to rewrite remaining code (too much)
     */
    if (fp) {
	esPtr = &esTmp;
	esPtr->pid = fp->pid;
	esPtr->wait = fp->wait_status;
    }

    /* non-portable assumption that pid_t can be printed with %d */

    if (result == -1) {
	Tcl_Obj* d = Tcl_NewListObj (0,NULL);

	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (esPtr->pid));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (spawn_id, -1));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (-1));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (errno));
	Tcl_ListObjAppendElement (interp, d, LITERAL ("POSIX"));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_ErrnoId(),-1));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_ErrnoMsg(errno),-1));

	Tcl_SetObjResult (interp, d);
	result = TCL_OK;
    } else if (result == NO_CHILD) {
	exp_error(interp,"no children");
	return TCL_ERROR;
    } else {
	Tcl_Obj* d = Tcl_NewListObj (0,NULL);
	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (esPtr->pid));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (spawn_id,-1));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (0));
	Tcl_ListObjAppendElement (interp, d, Tcl_NewIntObj    (WEXITSTATUS(esPtr->wait)));

	if (WIFSIGNALED(esPtr->wait)) {
	    Tcl_ListObjAppendElement (interp, d, LITERAL ("CHILDKILLED"));
	    Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_SignalId ((int) (WTERMSIG(esPtr->wait))),-1));
	    Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_SignalMsg((int) (WTERMSIG(esPtr->wait))),-1));
	} else if (WIFSTOPPED(esPtr->wait)) {
	    Tcl_ListObjAppendElement (interp, d, LITERAL ("CHILDSUSP"));
	    Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_SignalId ((int) (WSTOPSIG(esPtr->wait))),-1));
	    Tcl_ListObjAppendElement (interp, d, Tcl_NewStringObj (Tcl_SignalMsg((int) (WSTOPSIG(esPtr->wait))),-1));
	}

	Tcl_SetObjResult (interp, d);
    }
			
    if (fp) {
	fp->link_status = not_in_use;
	return ((result == -1)?TCL_ERROR:TCL_OK);		
    }

    esPtr->sys_waited = TRUE;
    esPtr->user_waited = TRUE;

    /* if user has already called close, forget about this entry entirely */
    if (!esPtr->open) {
	if (esPtr->registered) {
	    Tcl_UnregisterChannel(interp,esPtr->channel);
	}
    }

    return ((result == -1)?TCL_ERROR:TCL_OK);

    usage:
    exp_error(interp,"usage: -i spawn_id");
    return(TCL_ERROR);
}

/*ARGSUSED*/
static int
Exp_ForkObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int rc;
    if (objc > 1) {
	exp_error(interp,"usage: fork");
	return(TCL_ERROR);
    }

    rc = fork();
    if (rc == -1) {
	exp_error(interp,"fork: %s",Tcl_PosixError(interp));
	return TCL_ERROR;
    } else if (rc == 0) {
	/* child */
	exp_forked = TRUE;
	exp_getpid = getpid();
	fork_clear_all();
    } else {
	/* parent */
	fork_add(rc);
    }

    /* both child and parent follow remainder of code */
    Tcl_SetObjResult (interp, Tcl_NewIntObj (rc));
    expDiagLog("fork: returns {%s}\r\n",Tcl_GetStringResult(interp));
    return(TCL_OK);
}

/*ARGSUSED*/
static int
Exp_DisconnectObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    
#ifdef TIOCNOTTY
    /* tell CenterLine to ignore non-use of ttyfd */
    /*SUPPRESS 591*/
    int ttyfd;
#endif /* TIOCNOTTY */

    if (objc > 1) {
	exp_error(interp,"usage: disconnect");
	return(TCL_ERROR);
    }

    if (exp_disconnected) {
	exp_error(interp,"already disconnected");
	return(TCL_ERROR);
    }
    if (!exp_forked) {
	exp_error(interp,"can only disconnect child process");
	return(TCL_ERROR);
    }
    exp_disconnected = TRUE;

    /* ignore hangup signals generated by testing ptys in getptymaster */
    /* and other places */
    signal(SIGHUP,SIG_IGN);

    /* reopen prevents confusion between send/expect_user */
    /* accidentally mapping to a real spawned process after a disconnect */

    /* if we're in a child that's about to be disconnected from the
       controlling tty, close and reopen 0, 1, and 2 but associated
       with /dev/null.  This prevents send and expect_user doing
       special things if newly spawned processes accidentally
       get allocated 0, 1, and 2.
    */
	   
    if (isatty(0)) {
	ExpState *stdinout = tsdPtr->stdinout;
	if (stdinout->valid) {
	    exp_close(interp,stdinout);
	    if (stdinout->registered) {
		Tcl_UnregisterChannel(interp,stdinout->channel);
	    }
	}
	open("/dev/null",0);
	open("/dev/null",1);
	/* tsdPtr->stdinout = expCreateChannel(interp,0,1,EXP_NOPID);*/
	/* tsdPtr->stdinout->keepForever = 1;*/
    }
    if (isatty(2)) {
	ExpState *devtty = tsdPtr->devtty;
	
	/* reopen stderr saves error checking in error/log routines. */
	if (devtty->valid) {
	    exp_close(interp,devtty);
	    if (devtty->registered) {
		Tcl_UnregisterChannel(interp,devtty->channel);
	    }
	}
	open("/dev/null",1);
	/* tsdPtr->devtty = expCreateChannel(interp,2,2,EXP_NOPID);*/
	/* tsdPtr->devtty->keepForever = 1;*/
    }

    Tcl_UnsetVar(interp,"tty_spawn_id",TCL_GLOBAL_ONLY);

#ifdef DO_SETSID
    setsid();
#else
#ifdef SYSV3
    /* put process in our own pgrp, and lose controlling terminal */
#ifdef sysV88
    /* With setpgrp first, child ends up with closed stdio */
    /* according to Dave Schmitt <daves@techmpc.csg.gss.mot.com> */
    if (fork()) exit(0);
    expSetpgrp();
#else
    expSetpgrp();
    /*signal(SIGHUP,SIG_IGN); moved out to above */
    if (fork()) exit(0);	/* first child exits (as per Stevens, */
    /* UNIX Network Programming, p. 79-80) */
    /* second child process continues as daemon */
#endif
#else /* !SYSV3 */
    expSetpgrp();

/* Pyramid lacks this defn */
#ifdef TIOCNOTTY
    ttyfd = open("/dev/tty", O_RDWR);
    if (ttyfd >= 0) {
	/* zap controlling terminal if we had one */
	(void) ioctl(ttyfd, TIOCNOTTY, (char *)0);
	(void) close(ttyfd);
    }
#endif /* TIOCNOTTY */

#endif /* SYSV3 */
#endif /* DO_SETSID */
    return(TCL_OK);
}

/*ARGSUSED*/
static int
Exp_OverlayObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int newfd, oldfd;
    int dash_name = 0;
    char *command;
    int k, j;
    char **argv;

    int i;

    for (i=1;i<objc;i++) {
	char *name;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	} else if (streq (name,"-")) {	/* - by itself */
	    dash_name = 1;
	    continue;
	}

	if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &newfd)) {
	    return TCL_ERROR;
	}
	newfd = - newfd; /* Negation rids us of the effect the '-' prefix had. */

	i ++;
	if (i >= objc) {
	    exp_error(interp,"overlay -# requires additional argument");
	    return(TCL_ERROR);
	}
	if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &oldfd)) {
	    return TCL_ERROR;
	}

	expDiagLog("overlay: mapping fd %d to %d\r\n",oldfd,newfd);
	if (oldfd != newfd) (void) dup2(oldfd,newfd);
	else expDiagLog("warning: overlay: old fd == new fd (%d)\r\n",oldfd);
    }

    if (i >= objc) {
	exp_error(interp,"need program name");
	return(TCL_ERROR);
    }

    /* convert to string array for execvp.
     * Take only the arguments after the command name (i+1 ...). The arguments
     * before are arguments of overlay, not of the invoked command. The
     * command name is at index.
     */

    argv = (char**) ckalloc ((objc+1)*sizeof(char*));

    for (k=i+1,j=1;k<objc;k++,j++) {
	argv[j] = ckalloc (1+strlen(Tcl_GetString (objv[k])));
	strcpy (argv[j],Tcl_GetString (objv[k]));
    }
    argv[j] = NULL;

    /* command, handle '-' */
    command = Tcl_GetString (objv[i]);
    argv[0] = ckalloc (2+strlen(command));
    if (dash_name) {
	argv [0][0] = '-';
	strcpy (argv[0]+1,command);
    } else {
	strcpy (argv[0],command);
    }

    signal(SIGINT, SIG_DFL);
    signal(SIGQUIT, SIG_DFL);

    (void) execvp(command,argv);

    for (k=0;k<objc;k++) {
	ckfree (argv[k]);
    }
    ckfree ((char*)argv);

    exp_error(interp,"execvp(%s): %s\r\n",
	    Tcl_GetString(objv[0]),
	    Tcl_PosixError(interp));
    return(TCL_ERROR);
}

/*ARGSUSED*/
int
Exp_InterpreterObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    Tcl_Obj *eofObj = 0;
    int i;
    int index;
    int rc;

    static char *options[] = {
	"-eof", (char *)0
    };
    enum options {
	FLAG_EOF
    };

    for (i = 1; i < objc; i++) {
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	    case FLAG_EOF:
		i++;
		if (i >= objc) {
		    Tcl_WrongNumArgs(interp, 1, objv,"-eof cmd");
		    return TCL_ERROR;
		}
		eofObj = objv[i];
		Tcl_IncrRefCount(eofObj);
		break;
	}
    }

    /* errors and ok, are caught by exp_interpreter() and discarded */
    /* to return TCL_OK, type "return" */
    rc = exp_interpreter(interp,eofObj);
    if (eofObj) {
	Tcl_DecrRefCount(eofObj);
    }
    return rc;
}

/* this command supercede's Tcl's builtin CONTINUE command */
/*ARGSUSED*/
int
Exp_ExpContinueObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    if (objc == 1) {
	return EXP_CONTINUE;
    } else if ((objc == 2) &&
	    (0 == strcmp(Tcl_GetString (objv[1]),"-continue_timer"))) {
	return EXP_CONTINUE_TIMER;
    }

    exp_error(interp,"usage: exp_continue [-continue_timer]\n");
    return(TCL_ERROR);
}

/* most of this is directly from Tcl's definition for return */
/*ARGSUSED*/
int
Exp_InterReturnObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])
{
    /* let Tcl's return command worry about args */
    /* if successful (i.e., TCL_RETURN is returned) */
    /* modify the result, so that we will handle it specially */

    Tcl_CmdInfo* return_info = (Tcl_CmdInfo*)
	Tcl_GetAssocData (interp, EXP_CMDINFO_RETURN, NULL);

    int result = return_info->objProc(return_info->objClientData,interp,objc,objv);
    if (result == TCL_RETURN)
        result = EXP_TCL_RETURN;
    return result;
}

/*ARGSUSED*/
int
Exp_OpenObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    ExpState *esPtr;
    char *chanName = 0;
    int newfd;
    int leaveopen = FALSE;
    Tcl_Channel channel;

    static char* options[] = {
	"-i",
	"-leaveopen",
	NULL
    };
    enum options {
	OPEN_ID,
	OPEN_LEAVEOPEN
    };
    int i;

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	    case OPEN_ID:
		i++;
		if (i >= objc) goto usage;
		chanName = Tcl_GetString (objv[i]);
		break;
	    case OPEN_LEAVEOPEN:
		leaveopen = TRUE;
		break;
	}
    }

    if (!chanName) {
	esPtr = expStateCurrent(interp,1,0,0);
    } else {
	esPtr = expStateFromChannelName(interp,chanName,1,0,0,"exp_open");
    }
    if (!esPtr) return TCL_ERROR;

    /* make a new copy of file descriptor */
    if (-1 == (newfd = dup(esPtr->fdin))) {
	exp_error(interp,"dup: %s",Tcl_PosixError(interp));
	return TCL_ERROR;
    }

    if (!leaveopen) {
	/* remove from Expect's memory in anticipation of passing to Tcl */
	if (esPtr->pid != EXP_NOPID) {
	    Tcl_Pid pid = (Tcl_Pid)(long)esPtr->pid;
	    Tcl_DetachPids(1,&pid);
	    esPtr->pid = EXP_NOPID;
	    esPtr->sys_waited = esPtr->user_waited = TRUE;
	}
	exp_close(interp,esPtr);
    }

    /*
     * Tcl's MakeFileChannel only allows us to pass a single file descriptor
     * but that shouldn't be a problem in practice since all of the channels
     * that Expect generates only have one fd.  Of course, this code won't
     * work if someone creates a pipeline, then passes it to spawn, and then
     * again to exp_open.  For that to work, Tcl would need a new API.
     * Oh, and we're also being rather cavalier with the permissions here,
     * but they're likely to be right for the same reasons.
     */
    channel = Tcl_MakeFileChannel((ClientData)(long)newfd,TCL_READABLE|TCL_WRITABLE);
    Tcl_RegisterChannel(interp, channel);
    Tcl_AppendResult(interp, Tcl_GetChannelName(channel), (char *) NULL);
    return TCL_OK;

    usage:
    exp_error(interp,"usage: -i spawn_id");
    return TCL_ERROR;
}

/* return 1 if a string is substring of a flag */
/* this version is the code used by the macro that everyone calls */
int
exp_flageq_code(
    char *flag,
    char *string,
    int minlen)		/* at least this many chars must match */
{
    for (;*flag;flag++,string++,minlen--) {
	if (*string == '\0') break;
	if (*string != *flag) return 0;
    }
    if (*string == '\0' && minlen <= 0) return 1;
    return 0;
}

void
exp_create_commands(interp,c)
    Tcl_Interp *interp;
    struct exp_cmd_data *c;
{
    Namespace *globalNsPtr = (Namespace *) Tcl_GetGlobalNamespace(interp);
    Namespace *currNsPtr   = (Namespace *) Tcl_GetCurrentNamespace(interp);
    char cmdnamebuf[80];

    for (;c->name;c++) {
	/* if already defined, don't redefine */
	if ((c->flags & EXP_REDEFINE) ||
		!(Tcl_FindHashEntry(&globalNsPtr->cmdTable,c->name) ||
			Tcl_FindHashEntry(&currNsPtr->cmdTable,c->name))) {
	    if (c->objproc)
		Tcl_CreateObjCommand(interp,c->name,
			c->objproc,c->data,exp_deleteObjProc);
	    else
		Tcl_CreateCommand(interp,c->name,c->proc,
			c->data,exp_deleteProc);
	}
	if (!(c->name[0] == 'e' &&
			c->name[1] == 'x' &&
			c->name[2] == 'p')
		&& !(c->flags & EXP_NOPREFIX)) {
	    sprintf(cmdnamebuf,"exp_%s",c->name);
	    if (c->objproc)
		Tcl_CreateObjCommand(interp,cmdnamebuf,c->objproc,c->data,
			exp_deleteObjProc);
	    else
		Tcl_CreateCommand(interp,cmdnamebuf,c->proc,
			c->data,exp_deleteProc);
	}
    }
}

static struct exp_cmd_data cmd_data[]  = {
    {"close",	     Exp_CloseObjCmd,	0,	(ClientData)0,	EXP_REDEFINE},
#ifdef TCL_DEBUGGER
    {"debug",	     Exp_DebugObjCmd,       0,	(ClientData)0,	0},
#endif
    {"exp_internal", Exp_ExpInternalObjCmd, 0,	(ClientData)0,	0},
    {"disconnect",   Exp_DisconnectObjCmd,  0,	(ClientData)0,	0},
    {"exit",	     Exp_ExitObjCmd,        0,	(ClientData)0,	EXP_REDEFINE},
    {"exp_continue", Exp_ExpContinueObjCmd, 0,	(ClientData)0,	0},
    {"fork",	     Exp_ForkObjCmd,        0,	(ClientData)0,	0},
    {"exp_pid",	     Exp_ExpPidObjCmd,      0,	(ClientData)0,	0},
    {"getpid",	     Exp_GetpidDeprecatedObjCmd, 0,	(ClientData)0,	0},
    {"interpreter",  Exp_InterpreterObjCmd, 0,	(ClientData)0,	0},
    {"log_file",     Exp_LogFileObjCmd,     0,	(ClientData)0,	0},
    {"log_user",     Exp_LogUserObjCmd,     0,	(ClientData)0,	0},
    {"exp_open",     Exp_OpenObjCmd,        0,	(ClientData)0,	0},
    {"overlay",	     Exp_OverlayObjCmd,     0,	(ClientData)0,	0},
    {"inter_return", Exp_InterReturnObjCmd, 0,	(ClientData)0,	0},
    {"send",	     Exp_SendObjCmd,	    0,	(ClientData)&sendCD_proc,0},
    {"send_error",   Exp_SendObjCmd,	    0,	(ClientData)&sendCD_error,0},
    {"send_log",     Exp_SendLogObjCmd,     0,	(ClientData)0,	0},
    {"send_tty",     Exp_SendObjCmd,	    0,	(ClientData)&sendCD_tty,0},
    {"send_user",    Exp_SendObjCmd,	    0,	(ClientData)&sendCD_user,0},
    {"sleep",	     Exp_SleepObjCmd,       0,	(ClientData)0,	0},
    {"spawn",	     Exp_SpawnObjCmd,       0,	(ClientData)0,	0},
    {"strace",	     Exp_StraceObjCmd,      0,	(ClientData)0,	0},
    {"wait",	     Exp_WaitObjCmd,        0,	(ClientData)0,	0},
    {"exp_configure",Exp_ConfigureObjCmd,   0,	(ClientData)0,	0},
    {0}};

void
exp_init_most_cmds(Tcl_Interp *interp)
{
    exp_create_commands(interp,cmd_data);

#ifdef HAVE_PTYTRAP
    Tcl_InitHashTable(&slaveNames,TCL_STRING_KEYS);
#endif /* HAVE_PTYTRAP */
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
