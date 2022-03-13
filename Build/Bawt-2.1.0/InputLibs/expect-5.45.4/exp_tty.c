/* exp_tty.c - tty support routines */

#include "expect_cf.h"
#include <stdio.h>
#include <signal.h>
#include "string.h"

#ifdef HAVE_SYS_FCNTL_H
#  include <sys/fcntl.h>
#else
#  include <fcntl.h>
#endif

#include <sys/stat.h>

#ifdef HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#include <sys/types.h>

/* Needed for Mac */
#include <termios.h>

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#if defined(SIGCLD) && !defined(SIGCHLD)
#define SIGCHLD SIGCLD
#endif

#include "tcl.h"
#include "exp_prog.h"
#include "exp_rename.h"
#include "exp_tty_in.h"
#include "exp_command.h"
#include "exp_log.h"
#include "exp_win.h"
#include "exp_event.h"

static int is_raw = FALSE;
static int is_noecho = FALSE;

int exp_ioctled_devtty = FALSE;
int exp_stdin_is_tty;
int exp_stdout_is_tty;

/*static*/ extern exp_tty exp_tty_current, exp_tty_cooked;
#define tty_current exp_tty_current
#define tty_cooked exp_tty_cooked

int
exp_israw(void)
{
	return is_raw;
}

int
exp_isecho(void)
{
	return !is_noecho;
}

/* if set == 1, set it to raw, else unset it */
void
exp_tty_raw(int set)
{
	if (set == 1) {
		is_raw = TRUE;
#if defined(HAVE_TERMIOS) || defined(HAVE_TERMIO) /* had POSIX too */
		tty_current.c_iflag = 0;
		tty_current.c_oflag = 0;
		tty_current.c_lflag &= ECHO;  /* disable everything but echo */
		tty_current.c_cc[VMIN] = 1;
		tty_current.c_cc[VTIME] = 0;
	} else {
		tty_current.c_iflag = tty_cooked.c_iflag;
		tty_current.c_oflag = tty_cooked.c_oflag;
/*		tty_current.c_lflag = tty_cooked.c_lflag;*/
/* attempt 2	tty_current.c_lflag = tty_cooked.c_lflag & ~ECHO;*/
		/* retain current echo setting */
		tty_current.c_lflag = (tty_cooked.c_lflag & ~ECHO) | (tty_current.c_lflag & ECHO);
		tty_current.c_cc[VMIN] = tty_cooked.c_cc[VMIN];
		tty_current.c_cc[VTIME] = tty_cooked.c_cc[VTIME];
#else
#  if defined(HAVE_SGTTYB)
		tty_current.sg_flags |= RAW;
	} else {
		tty_current.sg_flags = tty_cooked.sg_flags;
#  endif
#endif
		is_raw = FALSE;
	}
}
	
void
exp_tty_echo(int set)
{
	if (set == 1) {
		is_noecho = FALSE;
#if defined(HAVE_TERMIOS) || defined(HAVE_TERMIO) /* had POSIX too */
		tty_current.c_lflag |= ECHO;
	} else {
		tty_current.c_lflag &= ~ECHO;
#else
		tty_current.sg_flags |= ECHO;
	} else {
		tty_current.sg_flags &= ~ECHO;
#endif
		is_noecho = TRUE;
	}
}

int
exp_tty_set_simple(exp_tty *tty)
{
#ifdef HAVE_TCSETATTR
	return(tcsetattr(exp_dev_tty, TCSADRAIN,tty));
#else
	return(ioctl    (exp_dev_tty, TCSETSW  ,tty));
#endif
}

int
exp_tty_get_simple(exp_tty *tty)
{
#ifdef HAVE_TCSETATTR
	return(tcgetattr(exp_dev_tty,         tty));
#else
	return(ioctl    (exp_dev_tty, TCGETS, tty));
#endif
}

/* returns 0 if nothing changed */
/* if something changed, the out parameters are changed as well */
int
exp_tty_raw_noecho(
    Tcl_Interp *interp,
    exp_tty *tty_old,
    int *was_raw,
    int *was_echo)
{
	if (exp_disconnected) return(0);
	if (is_raw && is_noecho) return(0);
	if (exp_dev_tty == -1) return(0);

	*tty_old = tty_current;		/* save old parameters */
	*was_raw = is_raw;
	*was_echo = !is_noecho;
	expDiagLog("tty_raw_noecho: was raw = %d  echo = %d\r\n",is_raw,!is_noecho);

	exp_tty_raw(1);
	exp_tty_echo(-1);

	if (exp_tty_set_simple(&tty_current) == -1) {
		expErrorLog("ioctl(raw): %s\r\n",Tcl_PosixError(interp));

		/* SF #439042 -- Allow overide of "exit" by user / script
		 */
		{
		  char buffer [] = "exit 1";
		  Tcl_Eval(interp, buffer); 
		}
	}

	exp_ioctled_devtty = TRUE;
	return(1);
}

/* returns 0 if nothing changed */
/* if something changed, the out parameters are changed as well */
int
exp_tty_cooked_echo(
    Tcl_Interp *interp,
    exp_tty *tty_old,
    int *was_raw,
    int *was_echo)
{
	if (exp_disconnected) return(0);
	if (!is_raw && !is_noecho) return(0);
	if (exp_dev_tty == -1) return(0);

	*tty_old = tty_current;		/* save old parameters */
	*was_raw = is_raw;
	*was_echo = !is_noecho;
	expDiagLog("tty_cooked_echo: was raw = %d  echo = %d\r\n",is_raw,!is_noecho);

	exp_tty_raw(-1);
	exp_tty_echo(1);

	if (exp_tty_set_simple(&tty_current) == -1) {
		expErrorLog("ioctl(noraw): %s\r\n",Tcl_PosixError(interp));

		/* SF #439042 -- Allow overide of "exit" by user / script
		 */
		{
		  char buffer [] = "exit 1";
		  Tcl_Eval(interp, buffer); 
		}
	}
	exp_ioctled_devtty = TRUE;

	return(1);
}

void
exp_tty_set(
    Tcl_Interp *interp,
    exp_tty *tty,
    int raw,
    int echo)
{
	if (exp_tty_set_simple(tty) == -1) {
		expErrorLog("ioctl(set): %s\r\n",Tcl_PosixError(interp));

		/* SF #439042 -- Allow overide of "exit" by user / script
		 */
		{
		  char buffer [] = "exit 1";
		  Tcl_Eval(interp, buffer); 
		}
	}
	is_raw = raw;
	is_noecho = !echo;
	tty_current = *tty;
	expDiagLog("tty_set: raw = %d, echo = %d\r\n",is_raw,!is_noecho);
	exp_ioctled_devtty = TRUE;
}	

#if 0
/* avoids scoping problems */
void
exp_update_cooked_from_current() {
	tty_cooked = tty_current;
}

int
exp_update_real_tty_from_current() {
	return(exp_tty_set_simple(&tty_current));
}

int
exp_update_current_from_real_tty() {
	return(exp_tty_get_simple(&tty_current));
}
#endif

void
exp_init_stdio()
{
	exp_stdin_is_tty = isatty(0);
	exp_stdout_is_tty = isatty(1);

	setbuf(stdout,(char *)0);	/* unbuffer stdout */
}

/*ARGSUSED*/
void
exp_tty_break(
    Tcl_Interp *interp,
    int fd)
{
#ifdef POSIX
	tcsendbreak(fd,0);
#else
# ifdef TIOCSBRK
	ioctl(fd,TIOCSBRK,0);
	exp_dsleep(interp,0.25); /* sleep for at least a quarter of a second */
	ioctl(fd,TIOCCBRK,0);
# else
	/* dunno how to do this - ignore */
# endif
#endif
}

/* take strings with newlines and insert carriage-returns.  This allows user */
/* to write send_user strings without always putting in \r. */
/* If len == 0, use strlen to compute it */
/* NB: if terminal is not in raw mode, nothing is done. */
char *
exp_cook(
    char *s,
    int *len)	/* current and new length of s */
{
	static int destlen = 0;
	static char *dest = 0;
	char *d;		/* ptr into dest */
	unsigned int need;

	if (s == 0) return("<null>");

	if (!is_raw) return(s);

	/* worst case is every character takes 2 to represent */
	need = 1 + 2*(len?*len:strlen(s));
	if (need > destlen) {
		if (dest) ckfree(dest);
		dest = ckalloc(need);
		destlen = need;
	}

	for (d = dest;*s;s++) {
		if (*s == '\n') {
			*d++ = '\r';
			*d++ = '\n';
		} else {
			*d++ = *s;
		}
	}
	*d = '\0';
	if (len) *len = d-dest;
	return(dest);
}

static int		/* returns TCL_whatever */
exec_stty(
    Tcl_Interp *interp,
    int argc,
    char **argv,
    int devtty)		/* if true, redirect to /dev/tty */
{
	int i;
	int rc;

	Tcl_Obj *cmdObj = Tcl_NewStringObj("",0);
	Tcl_IncrRefCount(cmdObj);

	Tcl_AppendStringsToObj(cmdObj,"exec ",(char *)0);
	Tcl_AppendStringsToObj(cmdObj,STTY_BIN,(char *)0);
	for (i=1;i<argc;i++) {
	    Tcl_AppendStringsToObj(cmdObj," ",argv[i],(char *)0);
	}
	if (devtty) Tcl_AppendStringsToObj(cmdObj,
#ifdef STTY_READS_STDOUT
		" >/dev/tty",
#else
		" </dev/tty",
#endif
		(char *)0);

	Tcl_ResetResult(interp);

	/*
	 * normally, I wouldn't set one of Tcl's own variables, but in this
	 * case, I only want to see if Tcl resets it to non-NONE, and I don't
	 * know any other way of doing it
	 */

	Tcl_SetVar(interp,"errorCode","NONE",0);
	rc = Tcl_EvalObjEx(interp,cmdObj,TCL_EVAL_DIRECT);

	Tcl_DecrRefCount(cmdObj);

	/* if stty-reads-stdout, stty will fail since Exec */
	/* will detect the stderr.  Only by examining errorCode */
	/* can we tell if a real error occurred. */	

#ifdef STTY_READS_STDOUT
	if (rc == TCL_ERROR) {
		char *ec = Tcl_GetVar(interp,"errorCode",TCL_GLOBAL_ONLY);
		if (ec && !streq(ec,"NONE")) return TCL_ERROR;
	}
#endif
	return TCL_OK;
}

/*ARGSUSED*/
static int
Exp_SttyCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int argc,
    char **argv)
{
	/* redirection symbol is not counted as a stty arg in terms */
	/* of recognition. */
	int saw_unknown_stty_arg = FALSE;
	int saw_known_stty_arg = FALSE;
	int no_args = TRUE;

	int rc = TCL_OK;
	int cooked = FALSE;
	int was_raw, was_echo;

	char **redirect;	/* location of "<" */
	char *infile = 0;
	int fd;			/* (slave) fd of infile */
	int master = -1;	/* master fd of infile */
	char **argv0 = argv;

	for (argv=argv0+1;*argv;argv++) {
		if (argv[0][0] == '<') {
			redirect = argv;
			infile = *(argv+1);
			if (!infile) {
				expErrorLog("usage: < ttyname");
				return TCL_ERROR;
			}
			if (streq(infile,"/dev/tty")) {
				infile = 0;
				*argv = 0;
				*(argv+1) = 0;
				argc -= 2;
			} else {
				master = exp_trap_off(infile);
				if (-1 == (fd = open(infile,2))) {
					expErrorLog("couldn't open %s: %s",
					 infile,Tcl_PosixError(interp));
					return TCL_ERROR;
				}
			}
			break;
		}
	}

	if (!infile) {		/* work on /dev/tty */
		was_raw = exp_israw();
		was_echo = exp_isecho();

		for (argv=argv0+1;*argv;argv++) {
			if (streq(*argv,"raw") ||
			    streq(*argv,"-cooked")) {
				exp_tty_raw(1);
				saw_known_stty_arg = TRUE;
				no_args = FALSE;
				exp_ioctled_devtty = TRUE;
			} else if (streq(*argv,"-raw") ||
				   streq(*argv,"cooked")) {
				cooked = TRUE;
				exp_tty_raw(-1);
				saw_known_stty_arg = TRUE;
				no_args = FALSE;
				exp_ioctled_devtty = TRUE;
			} else if (streq(*argv,"echo")) {
				exp_tty_echo(1);
				saw_known_stty_arg = TRUE;
				no_args = FALSE;
				exp_ioctled_devtty = TRUE;
			} else if (streq(*argv,"-echo")) {
				exp_tty_echo(-1);
				saw_known_stty_arg = TRUE;
				no_args = FALSE;
				exp_ioctled_devtty = TRUE;
			} else if (streq(*argv,"rows")) {
				if (*(argv+1)) {
					exp_win_rows_set(*(argv+1));
					argv++;
					no_args = FALSE;
					exp_ioctled_devtty = TRUE;
				} else {
		    Tcl_SetResult (interp, exp_win_rows_get(), TCL_VOLATILE);
					return TCL_OK;
				}
			} else if (streq(*argv,"columns")) {
				if (*(argv+1)) {
					exp_win_columns_set(*(argv+1));
					argv++;
					no_args = FALSE;
					exp_ioctled_devtty = TRUE;
				} else {
		    Tcl_SetResult (interp, exp_win_columns_get(), TCL_VOLATILE);
					return TCL_OK;
				}
			} else {
				saw_unknown_stty_arg = TRUE;
			}
		}
		/* if any unknown args, let real stty try */
		if (saw_unknown_stty_arg || no_args) {
			if (saw_unknown_stty_arg) {
			    exp_ioctled_devtty = TRUE;
			}

			/* let real stty try */
			rc = exec_stty(interp,argc,argv0,1);

			/* find out what weird options user asked for */
			if (exp_tty_get_simple(&tty_current) == -1) {
				exp_error(interp,"stty: ioctl(get): %s\r\n",Tcl_PosixError(interp));
				rc = TCL_ERROR;
			}
			if (cooked) {
				/* find out user's new defn of 'cooked' */
				tty_cooked = tty_current;
			}
		} else if (saw_known_stty_arg) {
			if (exp_tty_set_simple(&tty_current) == -1) {
			    if (exp_disconnected || (exp_dev_tty == -1) || !isatty(exp_dev_tty)) {
				expErrorLog("stty: impossible in this context\n");
				expErrorLog("are you disconnected or in a batch, at, or cron script?");
				/* user could've conceivably closed /dev/tty as well */
			    }
			    exp_error(interp,"stty: ioctl(user): %s\r\n",Tcl_PosixError(interp));
			    rc = TCL_ERROR;
			}
		}

		/* if no result, make a crude one */
		if (0 == strcmp(Tcl_GetString(Tcl_GetObjResult(interp)),"")) {
		    char buf [11];
		    sprintf(buf,"%sraw %secho",
			    (was_raw?"":"-"),
			    (was_echo?"":"-"));
		    Tcl_SetResult (interp, buf, TCL_VOLATILE);
		}
	} else {
		/* a different tty */

		/* temporarily zap redirect */
		char *redirect_save = *redirect;
		*redirect = 0;

		for (argv=argv0+1;*argv;argv++) {
			if (streq(*argv,"rows")) {
				if (*(argv+1)) {
					exp_win2_rows_set(fd,*(argv+1));
					argv++;
					no_args = FALSE;
				} else {
		    Tcl_SetResult (interp, exp_win2_rows_get(fd), TCL_VOLATILE);
					goto done;
				}
			} else if (streq(*argv,"columns")) {
				if (*(argv+1)) {
					exp_win2_columns_set(fd,*(argv+1));
					argv++;
					no_args = FALSE;
				} else {
		    Tcl_SetResult (interp, exp_win2_columns_get(fd), TCL_VOLATILE);
					goto done;
				}
			} else if (streq(*argv,"<")) {
				break;
			} else {
				saw_unknown_stty_arg = TRUE;
				break;
			}
		}

		/* restore redirect */
		*redirect = redirect_save;

		close(fd);	/* no more use for this, from now on */
				/* pass by name */

		if (saw_unknown_stty_arg || no_args) {
#ifdef STTY_READS_STDOUT
			/* switch "<" to ">" */
			char original_redirect_char = (*redirect)[0];
			(*redirect)[0] = '>';
			/* stderr unredirected so we can get it directly! */
#endif
			rc = exec_stty(interp,argc,argv0,0);
#ifdef STTY_READS_STDOUT
			/* restore redirect - don't know if necessary */
			(*redirect)[0] = original_redirect_char;
#endif
		}
	}
 done:
	exp_trap_on(master);

	return rc;
}

/*ARGSUSED*/
static int
Exp_SystemCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int argc,
    char **argv)
{
	int result = TCL_OK;
	RETSIGTYPE (*old)();	/* save old sigalarm handler */
#define MAX_ARGLIST 10240
	int i;

	WAIT_STATUS_TYPE waitStatus;
	int systemStatus
;
	int abnormalExit = FALSE;
	char buf[MAX_ARGLIST];
	char *bufp = buf;
	int total_len = 0, arg_len;

	int stty_args_recognized = TRUE;
	int cmd_is_stty = FALSE;
	int cooked = FALSE;
	int was_raw, was_echo;

	if (argc == 1) return TCL_OK;

	if (streq(argv[1],"stty")) {
		expDiagLogU("system stty is deprecated, use stty\r\n");

		cmd_is_stty = TRUE;
		was_raw = exp_israw();
		was_echo = exp_isecho();
	}

	if (argc > 2 && cmd_is_stty) {
		exp_ioctled_devtty = TRUE;

		for (i=2;i<argc;i++) {
			if (streq(argv[i],"raw") ||
			    streq(argv[i],"-cooked")) {
				exp_tty_raw(1);
			} else if (streq(argv[i],"-raw") ||
				   streq(argv[i],"cooked")) {
				cooked = TRUE;
				exp_tty_raw(-1);
			} else if (streq(argv[i],"echo")) {
				exp_tty_echo(1);
			} else if (streq(argv[i],"-echo")) {
				exp_tty_echo(-1);
			} else stty_args_recognized = FALSE;
		}

		/* if unknown args, fall thru and let real stty have a go */
		if (stty_args_recognized) {
	    if (
#ifdef HAVE_TCSETATTR
		tcsetattr(exp_dev_tty,TCSADRAIN, &tty_current) == -1
#else
		ioctl(exp_dev_tty, TCSETSW, &tty_current) == -1
#endif
		) {
			    if (exp_disconnected || (exp_dev_tty == -1) || !isatty(exp_dev_tty)) {
				expErrorLog("system stty: impossible in this context\n");
				expErrorLog("are you disconnected or in a batch, at, or cron script?");
				/* user could've conceivably closed /dev/tty as well */
			    }
			    exp_error(interp,"system stty: ioctl(user): %s\r\n",Tcl_PosixError(interp));
			    return(TCL_ERROR);
			}
			if (cmd_is_stty) {
			    char buf [11];
			    sprintf(buf,"%sraw %secho",
				    (was_raw?"":"-"),
				    (was_echo?"":"-"));
			    Tcl_SetResult (interp, buf, TCL_VOLATILE);
			}
			return(TCL_OK);
		}
	}

	for (i = 1;i<argc;i++) {
		total_len += (1 + (arg_len = strlen(argv[i])));
		if (total_len > MAX_ARGLIST) {
			exp_error(interp,"args too long (>=%d chars)",
				total_len);
			return(TCL_ERROR);
		}
		memcpy(bufp,argv[i],arg_len);
		bufp += arg_len;
		/* no need to check bounds, we accted for it earlier */
		memcpy(bufp," ",1);
		bufp += 1;
	}

	*(bufp-1) = '\0';

	old = signal(SIGCHLD, SIG_DFL);
	systemStatus = system(buf);
	signal(SIGCHLD, old);	/* restore signal handler */
	expDiagLogU("system(");
	expDiagLogU(buf);
	expDiagLog(") = %d\r\n",i);

	if (systemStatus == -1) {
		exp_error(interp,Tcl_PosixError(interp));
		return TCL_ERROR;
	}
	*(int *)&waitStatus = systemStatus;

	if (!stty_args_recognized) {
		/* find out what weird options user asked for */
	if (
#ifdef HAVE_TCSETATTR
	    tcgetattr(exp_dev_tty, &tty_current) == -1
#else
	    ioctl(exp_dev_tty, TCGETS, &tty_current) == -1
#endif
	    ) {
			expErrorLog("ioctl(get): %s\r\n",Tcl_PosixError(interp));

			/* SF #439042 -- Allow overide of "exit" by user / script
			 */
			{
			  char buffer [] = "exit 1";
			  Tcl_Eval(interp, buffer); 
			}
		}
		if (cooked) {
			/* find out user's new defn of 'cooked' */
			tty_cooked = tty_current;
		}
	}

	if (cmd_is_stty) {
	    char buf [11];
	    sprintf(buf,"%sraw %secho",
		    (was_raw?"":"-"),
		    (was_echo?"":"-"));
	    Tcl_SetResult (interp, buf, TCL_VOLATILE);
	}

/* following macros stolen from Tcl's tclUnix.h file */
/* we can't include the whole thing because it depends on other macros */
/* that come out of Tcl's Makefile, sigh */

#if 0

#undef WIFEXITED
#ifndef WIFEXITED
#   define WIFEXITED(stat)  (((*((int *) &(stat))) & 0xff) == 0)
#endif

#undef WEXITSTATUS
#ifndef WEXITSTATUS
#   define WEXITSTATUS(stat) (((*((int *) &(stat))) >> 8) & 0xff)
#endif

#undef WIFSIGNALED
#ifndef WIFSIGNALED
#   define WIFSIGNALED(stat) (((*((int *) &(stat)))) && ((*((int *) &(stat))) == ((*((int *) &(stat))) & 0x00ff)))
#endif

#undef WTERMSIG
#ifndef WTERMSIG
#   define WTERMSIG(stat)    ((*((int *) &(stat))) & 0x7f)
#endif

#undef WIFSTOPPED
#ifndef WIFSTOPPED
#   define WIFSTOPPED(stat)  (((*((int *) &(stat))) & 0xff) == 0177)
#endif

#undef WSTOPSIG
#ifndef WSTOPSIG
#   define WSTOPSIG(stat)    (((*((int *) &(stat))) >> 8) & 0xff)
#endif

#endif /* 0 */

/* stolen from Tcl.    Again, this is embedded in another routine */
/* (CleanupChildren in tclUnixAZ.c) that we can't use directly. */

	if (!WIFEXITED(waitStatus) || (WEXITSTATUS(waitStatus) != 0)) {
	    char msg1[20], msg2[20];
	    int pid = 0;	/* fake a pid, since system() won't tell us */ 

	    result = TCL_ERROR;
	    sprintf(msg1, "%d", pid);
	    if (WIFEXITED(waitStatus)) {
		sprintf(msg2, "%d", WEXITSTATUS(waitStatus));
		Tcl_SetErrorCode(interp, "CHILDSTATUS", msg1, msg2,
			(char *) NULL);
		abnormalExit = TRUE;
	    } else if (WIFSIGNALED(waitStatus)) {
		CONST char *p;
	
		p = Tcl_SignalMsg((int) (WTERMSIG(waitStatus)));
		Tcl_SetErrorCode(interp, "CHILDKILLED", msg1,
			Tcl_SignalId((int) (WTERMSIG(waitStatus))), p,
			(char *) NULL);
		Tcl_AppendResult(interp, "child killed: ", p, "\n",
			(char *) NULL);
	    } else if (WIFSTOPPED(waitStatus)) {
		CONST char *p;

		p = Tcl_SignalMsg((int) (WSTOPSIG(waitStatus)));
		Tcl_SetErrorCode(interp, "CHILDSUSP", msg1,
			Tcl_SignalId((int) (WSTOPSIG(waitStatus))), p, (char *) NULL);
		Tcl_AppendResult(interp, "child suspended: ", p, "\n",
			(char *) NULL);
	    } else {
		Tcl_AppendResult(interp,
			"child wait status didn't make sense\n",
			(char *) NULL);
	    }
	}

    if (abnormalExit && (Tcl_GetStringResult (interp)[0] == 0)) {
	Tcl_AppendResult(interp, "child process exited abnormally",
		(char *) NULL);
    }

    return result;
}

static struct exp_cmd_data
cmd_data[]  = {
{"stty",	exp_proc(Exp_SttyCmd),	0,	0},
{"system",	exp_proc(Exp_SystemCmd),	0,	0},
{0}};

void
exp_init_tty_cmds(struct Tcl_Interp *interp)
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
