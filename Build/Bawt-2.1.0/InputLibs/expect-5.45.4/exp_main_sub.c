/* exp_main_sub.c - miscellaneous subroutines for Expect or Tk main() */

#include "expect_cf.h"
#include <stdio.h>
#include <errno.h>
#ifdef HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#include <sys/types.h>

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#include "tcl.h"
#include "tclInt.h"
#include "exp_rename.h"
#include "exp_prog.h"
#include "exp_command.h"
#include "exp_tty_in.h"
#include "exp_log.h"
#include "exp_event.h"
#ifdef TCL_DEBUGGER
#include "tcldbg.h"
#endif

#ifndef EXP_VERSION
#define EXP_VERSION PACKAGE_VERSION
#endif
#ifdef __CENTERLINE__
#undef	EXP_VERSION
#define	EXP_VERSION		"5.45.4"		/* I give up! */
					/* It is not necessary that number */
					/* be accurate.  It is just here to */
					/* pacify Centerline which doesn't */
					/* seem to be able to get it from */
					/* the Makefile. */
#undef	SCRIPTDIR
#define SCRIPTDIR	"example/"
#undef	EXECSCRIPTDIR
#define EXECSCRIPTDIR	"example/"
#endif
char exp_version[] = PACKAGE_VERSION;
#define NEED_TCL_MAJOR		7
#define NEED_TCL_MINOR		5

char *exp_argv0 = "this program";	/* default program name */
void (*exp_app_exit)() = 0;
void (*exp_event_exit)() = 0;
FILE *exp_cmdfile = 0;
char *exp_cmdfilename = 0;
int exp_cmdlinecmds = FALSE;
int exp_interactive =  FALSE;
int exp_buffer_command_input = FALSE;/* read in entire cmdfile at once */
int exp_fgets();

Tcl_Interp *exp_interp;	/* for use by signal handlers who can't figure out */
			/* the interpreter directly */
int exp_tcl_debugger_available = FALSE;

int exp_getpid;

int exp_strict_write = 0;

int
exp_tty_cooked_echo(
    Tcl_Interp *interp,
    exp_tty *tty_old,
    int *was_raw,
    int *was_echo);

static void
usage(interp)
Tcl_Interp *interp;
{
  char buffer [] = "exit 1";
  expErrorLog("usage: expect [-div] [-c cmds] [[-f] cmdfile] [args]\r\n");

  /* SF #439042 -- Allow overide of "exit" by user / script
   */
  Tcl_Eval(interp, buffer); 
}

/* this clumsiness because pty routines don't know Tcl definitions */
/*ARGSUSED*/
static
void
exp_pty_exit_for_tcl(clientData)
ClientData clientData;
{
  exp_pty_exit();
}

static
void
exp_init_pty_exit()
{
  Tcl_CreateExitHandler(exp_pty_exit_for_tcl,(ClientData)0);
}

/* This can be called twice or even recursively - it's safe. */
void
exp_exit_handlers(clientData)
ClientData clientData;
{
	extern int exp_forked;

	Tcl_Interp *interp = (Tcl_Interp *)clientData;

	/* use following checks to prevent recursion in exit handlers */
	/* if this code ever supports multiple interps, these should */
	/* become interp-specific */

	static int did_app_exit = FALSE;
	static int did_expect_exit = FALSE;

	if (!did_expect_exit) {
		did_expect_exit = TRUE;
		/* called user-defined exit routine if one exists */
		if (exp_onexit_action) {
			int result = Tcl_GlobalEval(interp,exp_onexit_action);
			if (result != TCL_OK) Tcl_BackgroundError(interp);
		}
	} else {
		expDiagLogU("onexit handler called recursively - forcing exit\r\n");
	}

	if (exp_app_exit) {
		if (!did_app_exit) {
			did_app_exit = TRUE;
			(*exp_app_exit)(interp);
		} else {
			expDiagLogU("application exit handler called recursively - forcing exit\r\n");
		}
	}

	if (!exp_disconnected
	    && !exp_forked
	    && (exp_dev_tty != -1)
	    && isatty(exp_dev_tty)) {
	  if (exp_ioctled_devtty) {
		exp_tty_set(interp,&exp_tty_original,exp_dev_tty,0);
	  }
	}
	/* all other files either don't need to be flushed or will be
	   implicitly closed at exit.  Spawned processes are free to continue
	   running, however most will shutdown after seeing EOF on stdin.
	   Some systems also deliver SIGHUP and other sigs to idle processes
	   which will blow them away if not prepared.
	*/

	exp_close_all(interp);
}

static int
history_nextid(interp)
Tcl_Interp *interp;
{
    /* unncessarily tricky coding - if nextid isn't defined,
       maintain our own static version */

    static int nextid = 0;
    CONST char *nextidstr = Tcl_GetVar2(interp,"tcl::history","nextid",0);
    if (nextidstr) {
	/* intentionally ignore failure */
	(void) sscanf(nextidstr,"%d",&nextid);
    }
    return ++nextid;
}

/* this stupidity because Tcl needs commands in writable space */
static char prompt1[] = "prompt1";
static char prompt2[] = "prompt2";

static char *prompt2_default = "+> ";
static char prompt1_default[] = "expect%d.%d> ";

/*ARGSUSED*/
int
Exp_Prompt1ObjCmd(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
int objc;
Tcl_Obj *CONST objv[];		/* Argument objects. */
{
    static char buffer[200];

    Interp *iPtr = (Interp *)interp;

    sprintf(buffer,prompt1_default,iPtr->numLevels,history_nextid(interp));
    Tcl_SetResult(interp,buffer,TCL_STATIC);
    return(TCL_OK);
}

/*ARGSUSED*/
int
Exp_Prompt2ObjCmd(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
int objc;
Tcl_Obj *CONST objv[];
{
    Tcl_SetResult(interp,prompt2_default,TCL_STATIC);
    return(TCL_OK);
}

/*ARGSUSED*/
static int
ignore_procs(interp,s)
Tcl_Interp *interp;
char *s;		/* function name */
{
	return ((s[0] == 'p') &&
		(s[1] == 'r') &&
		(s[2] == 'o') &&
		(s[3] == 'm') &&
		(s[4] == 'p') &&
		(s[5] == 't') &&
		((s[6] == '1') ||
		 (s[6] == '2')) &&
		(s[7] == '\0')
	       );
}

/* handle an error from Tcl_Eval or Tcl_EvalFile */
static void
handle_eval_error(interp,check_for_nostack)
Tcl_Interp *interp;
int check_for_nostack;
{
	char *msg;

	/* if errorInfo has something, print it */
    /* else use what's in the interp result */

	msg = Tcl_GetVar(interp,"errorInfo",TCL_GLOBAL_ONLY);
    if (!msg) msg = Tcl_GetStringResult (interp);
	else if (check_for_nostack) {
		/* suppress errorInfo if generated via */
		/* error ... -nostack */
		if (0 == strncmp("-nostack",msg,8)) return;

		/*
		 * This shouldn't be necessary, but previous test fails
		 * because of recent change John made - see eval_trap_action()
		 * in exp_trap.c for more info
		 */
		if (exp_nostack_dump) {
			exp_nostack_dump = FALSE;
			return;
		}
	}

	/* no \n at end, since ccmd will already have one. */
	/* Actually, this is not true if command is last in */
	/* file and has no newline after it, oh well */
	expErrorLogU(exp_cook(msg,(int *)0));
	expErrorLogU("\r\n");
}

/* user has pressed escape char from interact or somehow requested expect.
If a user-supplied command returns:

TCL_ERROR,	assume user is experimenting and reprompt
TCL_OK,		ditto
TCL_RETURN,	return TCL_OK (assume user just wants to escape() to return)
EXP_TCL_RETURN,	return TCL_RETURN
anything else	return it
*/
int
exp_interpreter(interp,eofObj)
Tcl_Interp *interp;
Tcl_Obj *eofObj;
{
    Tcl_Obj *commandPtr = NULL;
    int code;
    int gotPartial;
    Interp *iPtr = (Interp *)interp;
    int tty_changed = FALSE;
    exp_tty tty_old;
    int was_raw, was_echo;

    Tcl_Channel inChannel, outChannel;
    ExpState *esPtr = expStdinoutGet();
    /*	int fd = fileno(stdin);*/

    expect_key++;
    commandPtr = Tcl_NewObj();
    Tcl_IncrRefCount(commandPtr);

    gotPartial = 0;
    while (TRUE) {
	if (Tcl_IsShared(commandPtr)) {
	    Tcl_DecrRefCount(commandPtr);
	    commandPtr = Tcl_DuplicateObj(commandPtr);
	    Tcl_IncrRefCount(commandPtr);
	}
	outChannel = expStdinoutGet()->channel;
	if (outChannel) {
	    Tcl_Flush(outChannel);
	}
	if (!esPtr->open) {
	  code = EXP_EOF;
	  goto eof;
	}

	/* force terminal state */
	tty_changed = exp_tty_cooked_echo(interp,&tty_old,&was_raw,&was_echo);

	if (!gotPartial) {
	    code = Tcl_Eval(interp,prompt1);
	    if (code == TCL_OK) {
		expStdoutLogU(Tcl_GetStringResult(interp),1);
	    }
	    else expStdoutLog(1,prompt1_default,iPtr->numLevels,history_nextid(interp));
	} else {
	    code = Tcl_Eval(interp,prompt2);
	    if (code == TCL_OK) {
		expStdoutLogU(Tcl_GetStringResult(interp),1);
	    }
	    else expStdoutLogU(prompt2_default,1);
	}

	esPtr->force_read = 1;
	code = exp_get_next_event(interp,&esPtr,1,&esPtr,EXP_TIME_INFINITY,
		esPtr->key);
	/*  check for code == EXP_TCLERROR? */

	if (code != EXP_EOF) {
	    inChannel = expStdinoutGet()->channel;
	    code = Tcl_GetsObj(inChannel, commandPtr);
#ifdef SIMPLE_EVENT
	    if (code == -1 && errno == EINTR) {
		if (Tcl_AsyncReady()) {
		    (void) Tcl_AsyncInvoke(interp,TCL_OK);
		}
		continue;
	    }
#endif
	    if (code < 0) code = EXP_EOF;
	    if ((code == 0) && Tcl_Eof(inChannel) && !gotPartial) code = EXP_EOF;
	}

    eof:
	if (code == EXP_EOF) {
	    if (eofObj) {
		code = Tcl_EvalObjEx(interp,eofObj,0);
	    } else {
		code = TCL_OK;
	    }
	    goto done;
	}

	expDiagWriteObj(commandPtr);
	/* intentionally always write to logfile */
	if (expLogChannelGet()) {
	    Tcl_WriteObj(expLogChannelGet(),commandPtr);
	}
	/* no need to write to stdout, since they will see */
	/* it just from it having been echoed as they are */
	/* typing it */

        /*
         * Add the newline removed by Tcl_GetsObj back to the string.
         */

	if (Tcl_IsShared(commandPtr)) {
	    Tcl_DecrRefCount(commandPtr);
	    commandPtr = Tcl_DuplicateObj(commandPtr);
	    Tcl_IncrRefCount(commandPtr);
	}
	Tcl_AppendToObj(commandPtr, "\n", 1);
	if (!TclObjCommandComplete(commandPtr)) {
	    gotPartial = 1;
	    continue;
	}

	Tcl_AppendToObj(commandPtr, "\n", 1);
	if (!TclObjCommandComplete(commandPtr)) {
	    gotPartial = 1;
	    continue;
	}

	gotPartial = 0;

	if (tty_changed) exp_tty_set(interp,&tty_old,was_raw,was_echo);

	code = Tcl_RecordAndEvalObj(interp, commandPtr, 0);
	Tcl_DecrRefCount(commandPtr);
	commandPtr = Tcl_NewObj();
	Tcl_IncrRefCount(commandPtr);
	switch (code) {
	    char *str;

	    case TCL_OK:
	        str = Tcl_GetStringResult(interp);
		if (*str != 0) {
		    expStdoutLogU(exp_cook(str,(int *)0),1);
		    expStdoutLogU("\r\n",1);
		}
		continue;
	    case TCL_ERROR:
		handle_eval_error(interp,1);
		/* since user is typing by hand, we expect lots */
		/* of errors, and want to give another chance */
		continue;
#define finish(x)	{code = x; goto done;}
	    case TCL_BREAK:
	    case TCL_CONTINUE:
		finish(code);
	    case EXP_TCL_RETURN:
		finish(TCL_RETURN);
	    case TCL_RETURN:
		finish(TCL_OK);
	    default:
		/* note that ccmd has trailing newline */
		expErrorLog("error %d: ",code);
		expErrorLogU(Tcl_GetString(Tcl_GetObjResult(interp)));
		expErrorLogU("\r\n");
		continue;
	}
    }
    /* cannot fall thru here, must jump to label */
 done:
    if (tty_changed) exp_tty_set(interp,&tty_old,was_raw,was_echo);

    Tcl_DecrRefCount(commandPtr);
    return(code);
}

/*ARGSUSED*/
int
Exp_ExpVersionObjCmd(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
	int emajor, umajor;
	char *user_version;	/* user-supplied version string */

    if (objc == 1) {
		Tcl_SetResult(interp,exp_version,TCL_STATIC);
		return(TCL_OK);
	}
    if (objc > 3) {
		exp_error(interp,"usage: expect_version [[-exit] version]");
		return(TCL_ERROR);
	}

    user_version = Tcl_GetString (objv[objc==2?1:2]);
	emajor = atoi(exp_version);
	umajor = atoi(user_version);

	/* first check major numbers */
	if (emajor == umajor) {
		int u, e;

		/* now check minor numbers */
		char *dot = strchr(user_version,'.');
		if (!dot) {
			exp_error(interp,"version number must include a minor version number");
			return TCL_ERROR;
		}

		u = atoi(dot+1);
		dot = strchr(exp_version,'.');
		e = atoi(dot+1);
		if (e >= u) return(TCL_OK);
	}

    if (objc == 2) {
		exp_error(interp,"%s requires Expect version %s (but using %s)",
			exp_argv0,user_version,exp_version);
		return(TCL_ERROR);
	}
	expErrorLog("%s requires Expect version %s (but is using %s)\r\n",
		exp_argv0,user_version,exp_version);

	/* SF #439042 -- Allow overide of "exit" by user / script
	 */
	{
	  char buffer [] = "exit 1";
	  Tcl_Eval(interp, buffer); 
	}
	/*NOTREACHED, but keep compiler from complaining*/
	return TCL_ERROR;
}

static char init_auto_path[] = "\
if {$exp_library != \"\"} {\n\
    lappend auto_path $exp_library\n\
}\n\
if {$exp_exec_library != \"\"} {\n\
    lappend auto_path $exp_exec_library\n\
}";

static void
DeleteCmdInfo (clientData, interp)
     ClientData clientData;
     Tcl_Interp *interp;
{
  ckfree (clientData);
}


int
Expect_Init(interp)
Tcl_Interp *interp;
{
    static int first_time = TRUE;

    Tcl_CmdInfo* close_info  = NULL;
    Tcl_CmdInfo* return_info = NULL;

    if (first_time) {
#ifndef USE_TCL_STUBS
	int tcl_major = atoi(TCL_VERSION);
	char *dot = strchr(TCL_VERSION,'.');
	int tcl_minor = atoi(dot+1);

	if (tcl_major < NEED_TCL_MAJOR || 
	    (tcl_major == NEED_TCL_MAJOR && tcl_minor < NEED_TCL_MINOR)) {

	    char bufa [20];
	    char bufb [20];
	    Tcl_Obj* s = Tcl_NewStringObj (exp_argv0,-1);

	    sprintf(bufa,"%d.%d",tcl_major,tcl_minor);
	    sprintf(bufb,"%d.%d",NEED_TCL_MAJOR,NEED_TCL_MINOR);

	    Tcl_AppendStringsToObj (s,
				    " compiled with Tcl ", bufa,
				    " but needs at least Tcl ", bufb,
				    "\n", NULL);
	    Tcl_SetObjResult (interp, s);
	    return TCL_ERROR;
	}
#endif
    }

#ifndef USE_TCL_STUBS
    if (Tcl_PkgRequire(interp, "Tcl", TCL_VERSION, 0) == NULL) {
      return TCL_ERROR;
    }
#else
    if (Tcl_InitStubs(interp, "8.1", 0) == NULL) {
      return TCL_ERROR;
    }
#endif

    /*
     * 	Save initial close and return for later use
     */

    close_info = (Tcl_CmdInfo*) ckalloc (sizeof (Tcl_CmdInfo));
    if (Tcl_GetCommandInfo(interp, "close", close_info) == 0) {
        ckfree ((char*) close_info);
        return TCL_ERROR;
    }
    return_info = (Tcl_CmdInfo*) ckalloc (sizeof (Tcl_CmdInfo));
    if (Tcl_GetCommandInfo(interp, "return", return_info) == 0){
        ckfree ((char*) close_info);
        ckfree ((char*) return_info);
	return TCL_ERROR;
    }
    Tcl_SetAssocData (interp, EXP_CMDINFO_CLOSE,  DeleteCmdInfo, (ClientData) close_info);
    Tcl_SetAssocData (interp, EXP_CMDINFO_RETURN, DeleteCmdInfo, (ClientData) return_info);

    /*
     * Expect redefines close so we need to save the original (pre-expect)
     * definition so it can be restored before exiting.
     *
     * Needed when expect is dynamically loaded after close has
     * been redefined e.g. the virtual file system in tclkit
     */
    if (TclRenameCommand(interp, "close", "_close.pre_expect") != TCL_OK) {
        return TCL_ERROR;
    }
 
    if (Tcl_PkgProvide(interp, "Expect", PACKAGE_VERSION) != TCL_OK) {
      return TCL_ERROR;
    }

    Tcl_Preserve(interp);
    Tcl_CreateExitHandler(Tcl_Release,(ClientData)interp);

    if (first_time) {
	exp_getpid = getpid();
	exp_init_pty();
	exp_init_pty_exit();
	exp_init_tty(); /* do this only now that we have looked at */
	/* original tty state */
	exp_init_stdio();
	exp_init_sig();
	exp_init_event();
	exp_init_trap();
	exp_init_unit_random();
	exp_init_spawn_ids(interp);
	expChannelInit();
	expDiagInit();
	expLogInit();
	expDiagLogPtrSet(expDiagLogU);
	expErrnoMsgSet(Tcl_ErrnoMsg);

	Tcl_CreateExitHandler(exp_exit_handlers,(ClientData)interp);

	first_time = FALSE;
    }

    /* save last known interp for emergencies */
    exp_interp = interp;

    /* initialize commands */
    exp_init_most_cmds(interp);		/* add misc     cmds to interpreter */
    exp_init_expect_cmds(interp);	/* add expect   cmds to interpreter */
    exp_init_main_cmds(interp);		/* add main     cmds to interpreter */
    exp_init_trap_cmds(interp);		/* add trap     cmds to interpreter */
    exp_init_tty_cmds(interp);		/* add tty      cmds to interpreter */
    exp_init_interact_cmds(interp);	/* add interact cmds to interpreter */

    /* initialize variables */
    exp_init_spawn_id_vars(interp);
    expExpectVarsInit();

    /*
     * For each of the the Tcl variables, "expect_library",
     *"exp_library", and "exp_exec_library", set the variable
     * if it does not already exist.  This mechanism allows the
     * application calling "Expect_Init()" to set these varaibles
     * to alternate locations from where Expect was built.
     */

    if (Tcl_GetVar(interp, "expect_library", TCL_GLOBAL_ONLY) == NULL) {
	Tcl_SetVar(interp,"expect_library",SCRIPTDIR,0);/* deprecated */
    }
    if (Tcl_GetVar(interp, "exp_library", TCL_GLOBAL_ONLY) == NULL) {
	Tcl_SetVar(interp,"exp_library",SCRIPTDIR,0);
    }
    if (Tcl_GetVar(interp, "exp_exec_library", TCL_GLOBAL_ONLY) == NULL) {
	Tcl_SetVar(interp,"exp_exec_library",EXECSCRIPTDIR,0);
    }

    Tcl_Eval(interp,init_auto_path);
    Tcl_ResetResult(interp);

#ifdef TCL_DEBUGGER
    Dbg_IgnoreFuncs(interp,ignore_procs);
#endif

    return TCL_OK;
}

static char sigint_init_default[80];
static char sigterm_init_default[80];
static char debug_init_default[] = "trap {exp_debug 1} SIGINT";

void
exp_parse_argv(interp,argc,argv)
Tcl_Interp *interp;
int argc;
char **argv;
{
	char argc_rep[10]; /* enough space for storing literal rep of argc */

	int sys_rc = TRUE;	/* read system rc file */
	int my_rc = TRUE;	/* read personal rc file */

	int c;
	int rc;

	extern int optind;
	extern char *optarg;
	char *args;		/* ptr to string-rep of all args */
	char *debug_init;

	exp_argv0 = argv[0];

#ifdef TCL_DEBUGGER
	Dbg_ArgcArgv(argc,argv,1);
#endif

	/* initially, we must assume we are not interactive */
	/* this prevents interactive weirdness courtesy of unknown via -c */
	/* after handling args, we can change our mind */
	Tcl_SetVar(interp, "tcl_interactive", "0", TCL_GLOBAL_ONLY);

	/* there's surely a system macro to do this but I don't know what it is */
#define EXP_SIG_EXIT(signalnumber) (0x80|signalnumber)

	sprintf(sigint_init_default, "trap {exit %d} SIGINT", EXP_SIG_EXIT(SIGINT));
	Tcl_Eval(interp,sigint_init_default);
	sprintf(sigterm_init_default,"trap {exit %d} SIGTERM",EXP_SIG_EXIT(SIGTERM));
	Tcl_Eval(interp,sigterm_init_default);

	/*
	 * [#418892]. The '+' character in front of every other option
         * declaration causes 'GNU getopt' to deactivate its
         * non-standard behaviour and switch to POSIX. Other
         * implementations of 'getopt' might recognize the option '-+'
         * because of this, but the following switch will catch this
         * and generate a usage message.
	 */

	while ((c = getopt(argc, argv, "+b:c:dD:f:inN-v")) != EOF) {
		switch(c) {
		case '-':
			/* getopt already handles -- internally, however */
			/* this allows us to abort getopt when dash is at */
			/* the end of another option which is required */
			/* in order to allow things like -n- on #! line */
			goto abort_getopt;
		case 'c': /* command */
			exp_cmdlinecmds = TRUE;
			rc = Tcl_Eval(interp,optarg);
			if (rc != TCL_OK) {
			    expErrorLogU(exp_cook(Tcl_GetVar(interp,"errorInfo",TCL_GLOBAL_ONLY),(int *)0));
			    expErrorLogU("\r\n");
			}
			break;
		case 'd': expDiagToStderrSet(TRUE);
			expDiagLog("expect version %s\r\n",exp_version);
			break;
#ifdef TCL_DEBUGGER
		case 'D':
			exp_tcl_debugger_available = TRUE;
			if (Tcl_GetInt(interp,optarg,&rc) != TCL_OK) {
			    expErrorLog("%s: -D argument must be 0 or 1\r\n",exp_argv0);

			    /* SF #439042 -- Allow overide of "exit" by user / script
			     */
			    {
			      char buffer [] = "exit 1";
			      Tcl_Eval(interp, buffer); 
			    }
			}

			/* set up trap handler before Dbg_On so user does */
			/* not have to see it at first debugger prompt */
			if (0 == (debug_init = getenv("EXPECT_DEBUG_INIT"))) {
				debug_init = debug_init_default;
			}
			Tcl_Eval(interp,debug_init);
			if (rc == 1) Dbg_On(interp,0);
			break;
#endif
		case 'f': /* name of cmd file */
			exp_cmdfilename = optarg;
			break;
		case 'b': /* read cmdfile one part at a time */
			exp_cmdfilename = optarg;
			exp_buffer_command_input = TRUE;
			break;
		case 'i': /* interactive */
			exp_interactive = TRUE;
			break;
		case 'n': /* don't read personal rc file */
			my_rc = FALSE;
			break;
		case 'N': /* don't read system-wide rc file */
			sys_rc = FALSE;
			break;
		case 'v':
			printf("expect version %s\n", exp_version);

			/* SF #439042 -- Allow overide of "exit" by user / script
			 */
			{
			  char buffer [] = "exit 0";
			  Tcl_Eval(interp, buffer); 
			}
			break;
		default: usage(interp);
		}
	}

 abort_getopt:

	for (c = 0;c<argc;c++) {
	    expDiagLog("argv[%d] = ",c);
	    expDiagLogU(argv[c]);
	    expDiagLogU("  ");
	}
	expDiagLogU("\r\n");

	/* if user hasn't explicitly requested we be interactive */
	/* look for a file or some other source of commands */
	if (!exp_interactive) {
		/* get cmd file name, if we haven't got it already */
		if (!exp_cmdfilename && (optind < argc)) {
			exp_cmdfilename = argv[optind];
			optind++;

			/*
			 * [#418892]. Skip a "--" found immediately
			 * behind the name of the script to
			 * execute. Don't try this if there are no
			 * arguments behind the "--" anymore. All
			 * other appearances of "--" are handled by
			 * the "getopt"-loop above.
			 */

			if ((optind < argc) &&
			    (0 == strcmp ("--", argv[optind]))) {
			    optind++;
			}
		}

		if (exp_cmdfilename) {
			if (streq(exp_cmdfilename,"-")) {
				exp_cmdfile = stdin;
				exp_cmdfilename = 0;
			} else if (exp_buffer_command_input) {
				errno = 0;
				exp_cmdfile = fopen(exp_cmdfilename,"r");
				if (exp_cmdfile) {
					exp_cmdfilename = 0;
					expCloseOnExec(fileno(exp_cmdfile));
				} else {
					CONST char *msg;

					if (errno == 0) {
						msg = "could not read - odd file name?";
					} else {
						msg = Tcl_ErrnoMsg(errno);
					}
					expErrorLog("%s: %s\r\n",exp_cmdfilename,msg);

					/* SF #439042 -- Allow overide of "exit" by user / script
					 */
					{
					  char buffer [] = "exit 1";
					  Tcl_Eval(interp, buffer); 
					}
				}
			}
		} else if (!exp_cmdlinecmds) {
			if (isatty(0)) {
				/* no other source of commands, force interactive */
				exp_interactive = TRUE;
			} else {
				/* read cmds from redirected stdin */
				exp_cmdfile = stdin;
			}
		}
	}

	if (exp_interactive) {
		Tcl_SetVar(interp, "tcl_interactive","1",TCL_GLOBAL_ONLY);
	}

	/* collect remaining args and make into argc, argv0, and argv */
	sprintf(argc_rep,"%d",argc-optind);
	Tcl_SetVar(interp,"argc",argc_rep,0);
	expDiagLog("set argc %s\r\n",argc_rep);

	if (exp_cmdfilename) {
		Tcl_SetVar(interp,"argv0",exp_cmdfilename,0);
		expDiagLog("set argv0 \"%s\"\r\n",exp_cmdfilename);
	} else {
		Tcl_SetVar(interp,"argv0",exp_argv0,0);
		expDiagLog("set argv0 \"%s\"\r\n",exp_argv0);
	}

	args = Tcl_Merge(argc-optind,argv+optind);
	expDiagLogU("set argv \"");
	expDiagLogU(args);
	expDiagLogU("\"\r\n");
	Tcl_SetVar(interp,"argv",args,0);
	Tcl_Free(args);

	exp_interpret_rcfiles(interp,my_rc,sys_rc);
}

static void
print_result (interp)
     Tcl_Interp* interp;
{
    char* msg = Tcl_GetStringResult (interp);
    if (msg[0] != 0) {
	expErrorLogU(msg);
	expErrorLogU("\r\n");
    }
}

static void
run_exit (interp)
     Tcl_Interp* interp;
{
    /* SF #439042 -- Allow overide of "exit" by user / script
     */
    char buffer [] = "exit 1";
    Tcl_Eval(interp, buffer); 
}

/* read rc files */
void
exp_interpret_rcfiles(interp,my_rc,sys_rc)
Tcl_Interp *interp;
int my_rc;
int sys_rc;
{
	int rc;

	if (sys_rc) {
	    char file[200];
	    int fd;

	    sprintf(file,"%s/expect.rc",SCRIPTDIR);
	    if (-1 != (fd = open(file,0))) {
		if (TCL_ERROR == (rc = Tcl_EvalFile(interp,file))) {
		    expErrorLog("error executing system initialization file: %s\r\n",file);
		    if (rc != TCL_ERROR)
			expErrorLog("Tcl_Eval = %d\r\n",rc);
		print_result (interp);
		run_exit (interp);
		}
		close(fd);
	    }
	}
	if (my_rc) {
	    char file[200];
	    char *home;
	    int fd;
	    char *getenv();

	    if ((NULL != (home = getenv("DOTDIR"))) ||
		(NULL != (home = getenv("HOME")))) {
		sprintf(file,"%s/.expect.rc",home);
		if (-1 != (fd = open(file,0))) {
		    if (TCL_ERROR == (rc = Tcl_EvalFile(interp,file))) {
			expErrorLog("error executing file: %s\r\n",file);
			if (rc != TCL_ERROR)
				expErrorLog("Tcl_Eval = %d\r\n",rc);
		    print_result (interp);
		    run_exit (interp);
		    }
		    close(fd);
	        }
	    }
	}
}

int
exp_interpret_cmdfilename(interp,filename)
Tcl_Interp *interp;
char *filename;
{
	int rc;

	expDiagLog("executing commands from command file %s\r\n",filename);

	Tcl_ResetResult(interp);
	if (TCL_OK != (rc = Tcl_EvalFile(interp,filename))) {
		/* EvalFile doesn't bother to copy error to errorInfo */
		/* so force it */
		Tcl_AddErrorInfo(interp, "");
		handle_eval_error(interp,0);
	}
	return rc;
}

int
exp_interpret_cmdfile(interp,fp)
Tcl_Interp *interp;
FILE *fp;
{
	int rc = 0;
	int gotPartial;
	int eof;

	Tcl_DString dstring;
	Tcl_DStringInit(&dstring);

	expDiagLogU("executing commands from command file\r\n");

	gotPartial = 0;
	eof = FALSE;
	while (1) {
		char line[BUFSIZ];/* buffer for partial Tcl command */
		char *ccmd;	/* pointer to complete Tcl command */

		if (fgets(line,BUFSIZ,fp) == NULL) {
			if (!gotPartial) break;
			eof = TRUE;
		}
		ccmd = Tcl_DStringAppend(&dstring,line,-1);
		if (!Tcl_CommandComplete(ccmd) && !eof) {
			gotPartial = 1;
			continue;	/* continue collecting command */
		}
		gotPartial = 0;

		rc = Tcl_Eval(interp,ccmd);
		Tcl_DStringFree(&dstring);
		if (rc != TCL_OK) {
			handle_eval_error(interp,0);
			break;
		}
		if (eof) break;
	}
	Tcl_DStringFree(&dstring);
	return rc;
}

static struct exp_cmd_data cmd_data[]  = {
    {"exp_version", Exp_ExpVersionObjCmd, 0,	0,	0},
    {"prompt1",	    Exp_Prompt1ObjCmd,    0,	0,	EXP_NOPREFIX},
    {"prompt2",	    Exp_Prompt2ObjCmd,    0,	0,	EXP_NOPREFIX},
{0}};

void
exp_init_main_cmds(interp)
Tcl_Interp *interp;
{
	exp_create_commands(interp,cmd_data);
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
