/* pty_termios.c - routines to allocate ptys - termios version

Written by: Don Libes, NIST, 2/6/90

This file is in the public domain.  However, the author and NIST
would appreciate credit if you use this file or parts of it.

*/

#include <stdio.h>
#include <signal.h>

#if defined(SIGCLD) && !defined(SIGCHLD)
#define SIGCHLD SIGCLD
#endif

#include "expect_cf.h"

/*
   The following functions are linked from the Tcl library.  They
   don't cause anything else in the library to be dragged in, so it
   shouldn't cause any problems (e.g., bloat).

   The functions are relatively small but painful enough that I don't care
   to recode them.  You may, if you absolutely want to get rid of any
   vestiges of Tcl.
*/
extern char *TclGetRegError();

#if defined(HAVE_PTMX_BSD) && defined(HAVE_PTMX)
/*
 * Some systems have both PTMX and PTMX_BSD.
 * In fact, alphaev56-dec-osf4.0e has /dev/pts, /dev/pty, /dev/ptym,
 * /dev/ptm, /dev/ptmx, and /dev/ptmx_bsd
 * Suggestion from Martin Buchholz <martin@xemacs.org> is that BSD
 * is usually deprecated and so should be here.
 */
#undef HAVE_PTMX_BSD
#endif

/* Linux and Digital systems can be configured to have both.
According to Ashley Pittman <ashley@ilo.dec.com>, Digital works better
with openpty which supports 4000 while ptmx supports 60. */
#if defined(HAVE_OPENPTY) && defined(HAVE_PTMX)
#undef HAVE_PTMX
#endif

#if defined(HAVE_PTYM) && defined(HAVE_PTMX)
/*
 * HP-UX 10.0 with streams (optional) have both PTMX and PTYM.  I don't
 * know which is preferred but seeing as how the HP trap stuff is so
 * unusual, it is probably safer to stick with the native HP pty support,
 * too.
 */
#undef HAVE_PTMX
#endif

#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#ifdef HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#include <sys/types.h>
#include <sys/stat.h>

#ifdef NO_STDLIB_H
#include "../compat/stdlib.h"
#else
#include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif

#ifdef HAVE_SYSMACROS_H
#include <sys/sysmacros.h>
#endif

#ifdef HAVE_PTYTRAP
#include <sys/ptyio.h>
#endif

#include <sys/file.h>

#ifdef HAVE_SYS_FCNTL_H
#  include <sys/fcntl.h>
#else
#  include <fcntl.h>
#endif

#if defined(_SEQUENT_)
#  include <sys/strpty.h>
#endif

#if defined(HAVE_PTMX) && defined(HAVE_STROPTS_H)
#  include <sys/stropts.h>
#endif

#include "exp_win.h"

#include "exp_tty_in.h"
#include "exp_rename.h"
#include "exp_pty.h"

void expDiagLog();
void expDiagLogPtr();

#include <errno.h>
/*extern char *sys_errlist[];*/

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

/* Convex getpty is different than older-style getpty */
/* Convex getpty is really just a cover function that does the traversal */
/* across the domain of pty names.  It makes no attempt to verify that */
/* they can actually be used.  Indded, the logic in the man page is */
/* wrong because it will allow you to allocate ptys that your own account */
/* already has in use. */
#if defined(HAVE_GETPTY) && defined(CONVEX)
#undef HAVE_GETPTY
#define HAVE_CONVEX_GETPTY
extern char *getpty();
static char *master_name;
static char slave_name[] = "/dev/ptyXX";
static char	*tty_bank;		/* ptr to char [p-z] denoting
					   which bank it is */
static char	*tty_num;		/* ptr to char [0-f] denoting
					   which number it is */
#endif

#if defined(_SEQUENT_) && !defined(HAVE_PTMX)
/* old-style SEQUENT, new-style uses ptmx */
static char *master_name, *slave_name;
#endif /* _SEQUENT */

/* very old SGIs prefer _getpty over ptc */
#if defined(HAVE__GETPTY) && defined(HAVE_PTC) && !defined(HAVE_GETPTY)
#undef HAVE_PTC
#endif

#if defined(HAVE_PTC)
static char slave_name[] = "/dev/ttyqXXX";
/* some machines (e.g., SVR4.0 StarServer) have all of these and */
/* HAVE_PTC works best */
#undef HAVE_GETPTY
#undef HAVE__GETPTY
#endif

#if defined(HAVE__GETPTY) || defined(HAVE_PTC_PTS) || defined(HAVE_PTMX)
static char *slave_name;
#endif

#if defined(HAVE_GETPTY)
#include <sys/vty.h>
static char master_name[MAXPTYNAMELEN];
static char slave_name[MAXPTYNAMELEN];
#endif

#if !defined(HAVE_GETPTY) && !defined(HAVE__GETPTY) && !defined(HAVE_PTC) && !defined(HAVE_PTC_PTS) && !defined(HAVE_PTMX) && !defined(HAVE_CONVEX_GETPTY) && !defined(_SEQUENT_) && !defined(HAVE_SCO_CLIST_PTYS) && !defined(HAVE_OPENPTY)
#ifdef HAVE_PTYM
			/* strange order and missing d is intentional */
static char	banks[] = "pqrstuvwxyzabcefghijklo";
static char	master_name[] = "/dev/ptym/ptyXXXX";
static char	slave_name[] = "/dev/pty/ttyXXXX";
static char	*slave_bank;
static char	*slave_num;
#else
static char	banks[] = "pqrstuvwxyzPQRSTUVWXYZ";
static char	master_name[] = "/dev/ptyXX";
static char	slave_name [] = "/dev/ttyXX";
#endif /* HAVE_PTYM */

static char	*tty_type;		/* ptr to char [pt] denoting
					   whether it is a pty or tty */
static char	*tty_bank;		/* ptr to char [p-z] denoting
					   which bank it is */
static char	*tty_num;		/* ptr to char [0-f] denoting
					   which number it is */
#endif

#if defined(HAVE_SCO_CLIST_PTYS)
#  define MAXPTYNAMELEN 64
static char master_name[MAXPTYNAMELEN];
static char slave_name[MAXPTYNAMELEN];
#endif /* HAVE_SCO_CLIST_PTYS */

#ifdef HAVE_OPENPTY
static char master_name[64];
static char slave_name[64];
#endif

char *exp_pty_slave_name;
char *exp_pty_error;

#if 0
static void
pty_stty(s,name)
char *s;		/* args to stty */
char *name;		/* name of pty */
{
#define MAX_ARGLIST 10240
	char buf[MAX_ARGLIST];	/* overkill is easier */
	RETSIGTYPE (*old)();	/* save old sigalarm handler */
	int pid;
	
	old = signal(SIGCHLD, SIG_DFL);
	switch (pid = fork()) {
	case 0: /* child */
	  exec_stty(STTY_BIN,STTY_BIN,s);
		break;
	case -1: /* fail */
	default: /* parent */
		waitpid(pid);
		break;
	}

	signal(SIGCHLD, old);	/* restore signal handler */
}

exec_stty(s)
char *s;
{
	char *args[50];
	char *cp;
	int argi = 0;
	int quoting = FALSE;
	int in_token = FALSE;	/* TRUE if we are reading a token */

	args[0] = cp = s;
	while (*s) {
		if (quoting) {
			if (*s == '\\' && *(s+1) == '"') { /* quoted quote */
				s++;	/* get past " */
				*cp++ = *s++;
			} else 	if (*s == '\"') { /* close quote */
				end_token
				quoting = FALSE;
			} else *cp++ = *s++; /* suck up anything */
		} else if (*s == '\"') { /* open quote */
			in_token = TRUE;
			quoting = TRUE;
			s++;
		} else if (isspace(*s)) {
			end_token
		} else {
			*cp++ = *s++;
			in_token = TRUE;
		}
	}
	end_token
	args[argi] = (char *) 0; /* terminate argv */
	execvp(args[0],args);
}
#endif /*0*/

static void
pty_stty(s,name)
char *s;		/* args to stty */
char *name;		/* name of pty */
{
#define MAX_ARGLIST 10240
	char buf[MAX_ARGLIST];	/* overkill is easier */
	RETSIGTYPE (*old)();	/* save old sigalarm handler */

#ifdef STTY_READS_STDOUT
	sprintf(buf,"%s %s > %s",STTY_BIN,s,name);
#else
	sprintf(buf,"%s %s < %s",STTY_BIN,s,name);
#endif
	old = signal(SIGCHLD, SIG_DFL);
	system(buf);
	signal(SIGCHLD, old);	/* restore signal handler */
}

int exp_dev_tty;	/* file descriptor to /dev/tty or -1 if none */
static int knew_dev_tty;/* true if we had our hands on /dev/tty at any time */

exp_tty exp_tty_original;

#define GET_TTYTYPE	0
#define SET_TTYTYPE	1
static void
ttytype(request,fd,ttycopy,ttyinit,s)
int request;
int fd;
		/* following are used only if request == SET_TTYTYPE */
int ttycopy;	/* true/false, copy from /dev/tty */
int ttyinit;	/* if true, initialize to sane state */
char *s;	/* stty args */
{
	if (request == GET_TTYTYPE) {
#ifdef HAVE_TCSETATTR
		if (-1 == tcgetattr(fd, &exp_tty_original)) {
#else
		if (-1 == ioctl(fd, TCGETS, (char *)&exp_tty_original)) {
#endif
			knew_dev_tty = FALSE;
			exp_dev_tty = -1;
		}
		exp_window_size_get(fd);
	} else {	/* type == SET_TTYTYPE */
		if (ttycopy && knew_dev_tty) {
#ifdef HAVE_TCSETATTR
			(void) tcsetattr(fd, TCSADRAIN, &exp_tty_current);
#else
			(void) ioctl(fd, TCSETS, (char *)&exp_tty_current);
#endif

			exp_window_size_set(fd);
		}

#ifdef __CENTERLINE__
#undef DFLT_STTY
#define DFLT_STTY "sane"
#endif

/* Apollo Domain doesn't need this */
#ifdef DFLT_STTY
		if (ttyinit) {
			/* overlay parms originally supplied by Makefile */
/* As long as BSD stty insists on stdout == stderr, we can no longer write */
/* diagnostics to parent stderr, since stderr has is now child's */
/* Maybe someday they will fix stty? */
/*			expDiagLogPtrStr("exp_getptyslave: (default) stty %s\n",DFLT_STTY);*/
			pty_stty(DFLT_STTY,slave_name);
		}
#endif

		/* lastly, give user chance to override any terminal parms */
		if (s) {
			/* give user a chance to override any terminal parms */
/*			expDiagLogPtrStr("exp_getptyslave: (user-requested) stty %s\n",s);*/
			pty_stty(s,slave_name);
		}
	}
}

void
exp_init_pty()
{
#if !defined(HAVE_GETPTY) && !defined(HAVE__GETPTY) && !defined(HAVE_PTC) && !defined(HAVE_PTC_PTS) && !defined(HAVE_PTMX) && !defined(HAVE_CONVEX_GETPTY) && !defined(_SEQUENT_) && !defined(HAVE_SCO_CLIST_PTYS) && !defined(HAVE_OPENPTY)
#ifdef HAVE_PTYM
	static char dummy;
	tty_bank =  &master_name[strlen("/dev/ptym/pty")];
	tty_num  =  &master_name[strlen("/dev/ptym/ptyX")];
	slave_bank = &slave_name[strlen("/dev/pty/tty")];
	slave_num  = &slave_name[strlen("/dev/pty/ttyX")];
#else
	tty_bank =  &master_name[strlen("/dev/pty")];
	tty_num  =  &master_name[strlen("/dev/ptyp")];
	tty_type =   &slave_name[strlen("/dev/")];
#endif

#endif /* HAVE_PTYM */


	exp_dev_tty = open("/dev/tty",O_RDWR);
	knew_dev_tty = (exp_dev_tty != -1);
	if (knew_dev_tty) ttytype(GET_TTYTYPE,exp_dev_tty,0,0,(char *)0);
}

#ifndef R_OK
/* 3b2 doesn't define these according to jthomas@nmsu.edu. */
#define R_OK 04
#define W_OK 02
#endif

int
exp_getptymaster()
{
	char *hex, *bank;
	struct stat stat_buf;
	int master = -1;
	int slave = -1;
	int num;

	exp_pty_error = 0;

#define TEST_PTY 1

#if defined(HAVE_PTMX) || defined(HAVE_PTMX_BSD)
#undef TEST_PTY
#if defined(HAVE_PTMX_BSD)
        if ((master = open("/dev/ptmx_bsd", O_RDWR)) == -1) return(-1);
#else
	if ((master = open("/dev/ptmx", O_RDWR)) == -1) return(-1);
#endif
	if ((slave_name = (char *)ptsname(master)) == NULL) {
		close(master);
		return(-1);
	}
	if (grantpt(master)) {
	  static char buf[500];
	  exp_pty_error = buf;
	  sprintf(exp_pty_error,"grantpt(%s) failed - likely reason is that your system administrator (in a rage of blind passion to rid the system of security holes) removed setuid from the utility used internally by grantpt to change pty permissions.  Tell your system admin to reestablish setuid on the utility.  Get the utility name by running Expect under truss or trace.", expErrnoMsg(errno));
	  close(master);
	  return(-1);
	}
	if (-1 == (int)unlockpt(master)) {
	  static char buf[500];
	  exp_pty_error = buf;
	  sprintf(exp_pty_error,"unlockpt(%s) failed.", expErrnoMsg(errno));
	  close(master);
	  return(-1);
	}
#ifdef TIOCFLUSH
	(void) ioctl(master,TIOCFLUSH,(char *)0);
#endif /* TIOCFLUSH */

	exp_pty_slave_name = slave_name;
	return(master);
#endif

#if defined(HAVE__GETPTY)		/* SGI needs it this way */
#undef TEST_PTY
	slave_name = _getpty(&master, O_RDWR, 0600, 0);
	if (slave_name == NULL)
		return (-1);	
	exp_pty_slave_name = slave_name;
	return(master);
#endif

#if defined(HAVE_PTC) && !defined(HAVE__GETPTY)	/* old SGI, version 3 */
#undef TEST_PTY
	master = open("/dev/ptc", O_RDWR);
	if (master >= 0) {
		int ptynum;

		if (fstat(master, &stat_buf) < 0) {
			close(master);
			return(-1);
		}
		ptynum = minor(stat_buf.st_rdev);
		sprintf(slave_name,"/dev/ttyq%d",ptynum);
	}
	exp_pty_slave_name = slave_name;
	return(master);
#endif

#if defined(HAVE_GETPTY) && !defined(HAVE__GETPTY)
#undef TEST_PTY
	master = getpty(master_name, slave_name, O_RDWR);
	/* is it really necessary to verify slave side is usable? */
	exp_pty_slave_name = slave_name;
	return master;
#endif

#if defined(HAVE_PTC_PTS)
#undef TEST_PTY
	master = open("/dev/ptc",O_RDWR);
	if (master >= 0) {
		/* never fails */
		slave_name = ttyname(master);
	}
	exp_pty_slave_name = slave_name;
	return(master);
#endif

#if defined(_SEQUENT_) && !defined(HAVE_PTMX)
#undef TEST_PTY
	/* old-style SEQUENT, new-style uses ptmx */
	master = getpseudotty(&slave_name, &master_name);
	exp_pty_slave_name = slave_name;
	return(master);
#endif /* _SEQUENT_ */

#if defined(HAVE_OPENPTY)
#undef TEST_PTY
	if (openpty(&master, &slave, master_name, 0, 0) != 0) {
		close(master);
		close(slave);
		return -1;
	}
	strcpy(slave_name, ttyname(slave));
	exp_pty_slave_name = slave_name;
	close(slave);
	return master;
#endif /* HAVE_OPENPTY */

#if defined(TEST_PTY)
	/*
	 * all pty allocation mechanisms after this require testing
	 */
	if (exp_pty_test_start() == -1) return -1;

#if !defined(HAVE_CONVEX_GETPTY) && !defined(HAVE_PTYM) && !defined(HAVE_SCO_CLIST_PTYS)
	for (bank = banks;*bank;bank++) {
		*tty_bank = *bank;
		*tty_num = '0';
		if (stat(master_name, &stat_buf) < 0) break;
		for (hex = "0123456789abcdef";*hex;hex++) {
			*tty_num = *hex;
			strcpy(slave_name,master_name);
			*tty_type = 't';
			master = exp_pty_test(master_name,slave_name,*tty_bank,tty_num);
			if (master >= 0) goto done;
		}
	}
#endif

#ifdef HAVE_SCO_CLIST_PTYS
        for (num = 0; ; num++) {
            char num_str [16];

            sprintf (num_str, "%d", num);
            sprintf (master_name, "%s%s", "/dev/ptyp", num_str);
            if (stat (master_name, &stat_buf) < 0)
                break;
            sprintf (slave_name, "%s%s", "/dev/ttyp", num_str);

            master = exp_pty_test(master_name,slave_name,'0',num_str);
            if (master >= 0)
                goto done;
        }
#endif

#ifdef HAVE_PTYM
	/* systems with PTYM follow this idea:

	   /dev/ptym/pty[a-ce-z][0-9a-f]                master pseudo terminals
	   /dev/pty/tty[a-ce-z][0-9a-f]                 slave pseudo terminals
	   /dev/ptym/pty[a-ce-z][0-9][0-9]              master pseudo terminals
	   /dev/pty/tty[a-ce-z][0-9][0-9]               slave pseudo terminals

	   SPPUX (Convex's HPUX compatible) follows the PTYM convention but
	   extends it:

	   /dev/ptym/pty[a-ce-z][0-9][0-9][0-9]         master pseudo terminals
	   /dev/pty/tty[a-ce-z][0-9][0-9][0-9]          slave pseudo terminals

	   The code does not distinguish between HPUX and SPPUX because there
	   is no reason to.  HPUX will merely fail the extended SPPUX tests.
	   In fact, most SPPUX systems will fail simply because few systems
	   will actually have the extended ptys.  However, the tests are
	   fast so it is no big deal.
	 */

	/*
	 * pty[a-ce-z][0-9a-f]
	 */

	for (bank = banks;*bank;bank++) {
		*tty_bank = *bank;
		sprintf(tty_num,"0");
		if (stat(master_name, &stat_buf) < 0) break;
		*(slave_num+1) = '\0';
		for (hex = "0123456789abcdef";*hex;hex++) {
			*tty_num = *hex;
			*slave_bank = *tty_bank;
			*slave_num = *tty_num;
			master = exp_pty_test(master_name,slave_name,*tty_bank,tty_num);
			if (master >= 0) goto done;
		}
	}

	/*
	 * tty[p-za-ce-o][0-9][0-9]
	 */

	for (bank = banks;*bank;bank++) {
		*tty_bank = *bank;
		sprintf(tty_num,"00");
		if (stat(master_name, &stat_buf) < 0) break;
		for (num = 0; num<100; num++) {
			*slave_bank = *tty_bank;
			sprintf(tty_num,"%02d",num);
			strcpy(slave_num,tty_num);
			master = exp_pty_test(master_name,slave_name,*tty_bank,tty_num);
			if (master >= 0) goto done;
		}
	}

	/*
	 * tty[p-za-ce-o][0-9][0-9][0-9]
	 */
	for (bank = banks;*bank;bank++) {
		*tty_bank = *bank;
		sprintf(tty_num,"000");
		if (stat(master_name, &stat_buf) < 0) break;
		for (num = 0; num<1000; num++) {
			*slave_bank = *tty_bank;
			sprintf(tty_num,"%03d",num);
			strcpy(slave_num,tty_num);
			master = exp_pty_test(master_name,slave_name,*tty_bank,tty_num);
			if (master >= 0) goto done;
		}
	}

#endif /* HAVE_PTYM */

#if defined(HAVE_CONVEX_GETPTY)
	for (;;) {
		if ((master_name = getpty()) == NULL) return -1;
 
		strcpy(slave_name,master_name);
		slave_name[5] = 't';/* /dev/ptyXY ==> /dev/ttyXY */

		tty_bank = &slave_name[8];
		tty_num = &slave_name[9];
		master = exp_pty_test(master_name,slave_name,*tty_bank,tty_num);
		if (master >= 0) goto done;
	}
#endif

 done:
	exp_pty_test_end();
	exp_pty_slave_name = slave_name;
	return(master);

#endif /* defined(TEST_PTY) */
}

/* if slave is opened in a child, slave_control(1) must be executed after */
/*   master is opened (when child is opened is irrelevent) */
/* if slave is opened in same proc as master, slave_control(1) must executed */
/*   after slave is opened */
/*ARGSUSED*/
void
exp_slave_control(master,control)
int master;
int control;	/* if 1, enable pty trapping of close/open/ioctl */
{
#ifdef HAVE_PTYTRAP
	ioctl(master, TIOCTRAP, &control);
#endif /* HAVE_PTYTRAP */
}

int
exp_getptyslave(
    int ttycopy,
    int ttyinit,
    CONST char *stty_args)
{
	int slave, slave2;
	char buf[10240];

	if (0 > (slave = open(slave_name, O_RDWR))) {
		static char buf[500];
		exp_pty_error = buf;
		sprintf(exp_pty_error,"open(%s,rw) = %d (%s)",slave_name,slave,expErrnoMsg(errno));
		return(-1);
	}

#if defined(HAVE_PTMX_BSD)
	if (ioctl (slave, I_LOOK, buf) != 0)
		if (ioctl (slave, I_PUSH, "ldterm")) {
			expDiagLogPtrStrStr("ioctl(%d,I_PUSH,\"ldterm\") = %s\n",slave,expErrnoMsg(errno));
	}
#else
#if defined(HAVE_PTMX)
	if (ioctl(slave, I_PUSH, "ptem")) {
		expDiagLogPtrStrStr("ioctl(%d,I_PUSH,\"ptem\") = %s\n",slave,expErrnoMsg(errno));
	}
	if (ioctl(slave, I_PUSH, "ldterm")) {
		expDiagLogPtrStrStr("ioctl(%d,I_PUSH,\"ldterm\") = %s\n",slave,expErrnoMsg(errno));
	}
	if (ioctl(slave, I_PUSH, "ttcompat")) {
		expDiagLogPtrStrStr("ioctl(%d,I_PUSH,\"ttcompat\") = %s\n",slave,expErrnoMsg(errno));
	}
#endif
#endif

	if (0 == slave) {
		/* if opened in a new process, slave will be 0 (and */
		/* ultimately, 1 and 2 as well) */

		/* duplicate 0 onto 1 and 2 to prepare for stty */
		fcntl(0,F_DUPFD,1);
		fcntl(0,F_DUPFD,2);
	}

	ttytype(SET_TTYTYPE,slave,ttycopy,ttyinit,stty_args);

#if 0
#ifdef HAVE_PTYTRAP
	/* do another open, to tell master that slave is done fiddling */
	/* with pty and master does not have to wait to do further acks */
	if (0 > (slave2 = open(slave_name, O_RDWR))) return(-1);
	close(slave2);
#endif /* HAVE_PTYTRAP */
#endif

	(void) exp_pty_unlock();
	return(slave);
}

#ifdef HAVE_PTYTRAP
#include <sys/ptyio.h>
#include <sys/time.h>

/* This function attempts to deal with HP's pty interface.  This
function simply returns an indication of what was trapped (or -1 for
failure), the parent deals with the details.

Originally, I tried to just trap open's but that is not enough.  When
the pty is initialized, ioctl's are generated and if not trapped will
hang the child if no further trapping is done.  (This could occur if
parent spawns a process and then immediatley does a close.)  So
instead, the parent must trap the ioctl's.  It probably suffices to
trap the write ioctl's (and tiocsctty which some hp's need) -
conceivably, stty could be smart enough not to do write's if the tty
settings are already correct.  In that case, we'll have to rethink
this.

Suggestions from HP engineers encouraged.  I cannot imagine how this
interface was intended to be used!

*/
   
int
exp_wait_for_slave_open(fd)
int fd;
{
	fd_set excep;
	struct timeval t;
	struct request_info ioctl_info;
	int rc;
	int found = 0;

	int maxfds = sysconf(_SC_OPEN_MAX);

	t.tv_sec = 30;	/* 30 seconds */
	t.tv_usec = 0;

	FD_ZERO(&excep);
	FD_SET(fd,&excep);

	rc = select(maxfds,
		(SELECT_MASK_TYPE *)0,
		(SELECT_MASK_TYPE *)0,
		(SELECT_MASK_TYPE *)&excep,
		&t);
	if (rc != 1) {
		expDiagLogPtrStr("spawned process never started: %s\r\n",expErrnoMsg(errno));
		return(-1);
	}
	if (ioctl(fd,TIOCREQCHECK,&ioctl_info) < 0) {
		expDiagLogPtrStr("ioctl(TIOCREQCHECK) failed: %s\r\n",expErrnoMsg(errno));
		return(-1);
	}

	found = ioctl_info.request;

	expDiagLogPtrX("trapped pty op = %x",found);
	if (found == TIOCOPEN) {
		expDiagLogPtr(" TIOCOPEN");
	} else if (found == TIOCCLOSE) {
		expDiagLogPtr(" TIOCCLOSE");
	}

#ifdef TIOCSCTTY
	if (found == TIOCSCTTY) {
		expDiagLogPtr(" TIOCSCTTY");
	}
#endif

	if (found & IOC_IN) {
		expDiagLogPtr(" IOC_IN (set)");
	} else if (found & IOC_OUT) {
		expDiagLogPtr(" IOC_OUT (get)");
	}

	expDiagLogPtr("\n");

	if (ioctl(fd, TIOCREQSET, &ioctl_info) < 0) {
		expDiagLogPtrStr("ioctl(TIOCREQSET) failed: %s\r\n",expErrnoMsg(errno));
		return(-1);
	}
	return(found);
}
#endif

void
exp_pty_exit()
{
	/* a stub so we can do weird things on the cray */
}
