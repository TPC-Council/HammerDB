/* pty_bsd.c - routines to allocate ptys - BSD version

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include <stdio.h>		/* tmp for debugging */
#include <stdlib.h>
#include <string.h>
#include <signal.h>

#if defined(SIGCLD) && !defined(SIGCHLD)
#define SIGCHLD SIGCLD
#endif

#include <sys/types.h>
#include <sys/stat.h>
/*** #include <sys/ioctl.h> ***/
#include <sys/file.h>
#include <signal.h>
#include <setjmp.h>
#include "tcl.h"
#include "expect_cf.h"
#include "exp_rename.h"
#include "exp_tty_in.h"
#include "exp_pty.h"

void expDiagLog();
void expDiagLogU();

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

static char	master_name[] = "/dev/ptyXX";	/* master */
static char	 slave_name[] = "/dev/ttyXX";	/* slave */
static char	*tty_type;		/* ptr to char [pt] denoting
					   whether it is a pty or tty */
static char	*tty_bank;		/* ptr to char [p-z] denoting
					   which bank it is */
static char	*tty_num;		/* ptr to char [0-f] denoting
					   which number it is */
char *exp_pty_slave_name;
char *exp_pty_error;

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

#ifdef TIOCGWINSZ
static struct winsize winsize = {0, 0};
#endif
#if defined(TIOCGSIZE) && !defined(TIOCGWINSZ)
static struct ttysize winsize = {0, 0};
#endif

exp_tty exp_tty_original;

#define GET_TTYTYPE	0
#define SET_TTYTYPE	1
static void
ttytype(request,fd,ttycopy,ttyinit,s)
int request;
int fd;
		/* following are used only if request == SET_TTYTYPE */
int ttycopy;	/* if true, copy from /dev/tty */
int ttyinit;	/* if true, initialize to sane state */
char *s;	/* stty args */
{
	static struct	tchars tc;		/* special characters */
	static struct	ltchars lc;		/* local special characters */
	static struct	winsize win;		/* window size */
	static int	lb;			/* local modes */
	static int	l;			/* line discipline */

	if (request == GET_TTYTYPE) {
		if (-1 == ioctl(fd, TIOCGETP, (char *)&exp_tty_original)
		 || -1 == ioctl(fd, TIOCGETC, (char *)&tc)
		 || -1 == ioctl(fd, TIOCGETD, (char *)&l)
		 || -1 == ioctl(fd, TIOCGLTC, (char *)&lc)
		 || -1 == ioctl(fd, TIOCLGET, (char *)&lb)
		 || -1 == ioctl(fd, TIOCGWINSZ, (char *)&win)) {
			knew_dev_tty = FALSE;
			exp_dev_tty = -1;
		}
#ifdef TIOCGWINSZ
		ioctl(fd,TIOCGWINSZ,&winsize);
#endif
#if defined(TIOCGSIZE) && !defined(TIOCGWINSZ)
		ioctl(fd,TIOCGSIZE,&winsize);
#endif
	} else {	/* type == SET_TTYTYPE */
		if (ttycopy && knew_dev_tty) {
			(void) ioctl(fd, TIOCSETP, (char *)&exp_tty_current);
			(void) ioctl(fd, TIOCSETC, (char *)&tc);
			(void) ioctl(fd, TIOCSLTC, (char *)&lc);
			(void) ioctl(fd, TIOCLSET, (char *)&lb);
			(void) ioctl(fd, TIOCSETD, (char *)&l);
			(void) ioctl(fd, TIOCSWINSZ, (char *)&win);
#ifdef TIOCSWINSZ
			ioctl(fd,TIOCSWINSZ,&winsize);
#endif
#if defined(TIOCSSIZE) && !defined(TIOCSWINSZ)
			ioctl(fd,TIOCGSIZE,&winsize);
#endif
		}

#ifdef __CENTERLINE__
#undef DFLT_STTY
#define DFLT_STTY "sane"
#endif

/* Apollo Domain doesn't need this */
#ifdef DFLT_STTY
		if (ttyinit) {
			/* overlay parms originally supplied by Makefile */
			pty_stty(DFLT_STTY,slave_name);
		}
#endif

		/* lastly, give user chance to override any terminal parms */
		if (s) {
			pty_stty(s,slave_name);
		}
	}
}

void
exp_init_pty()
{
	tty_type = & slave_name[strlen("/dev/")];
	tty_bank = &master_name[strlen("/dev/pty")];
	tty_num  = &master_name[strlen("/dev/ptyp")];

	exp_dev_tty = open("/dev/tty",O_RDWR);

#if experimental
	/* code to allocate force expect to get a controlling tty */
	/* even if it doesn't start with one (i.e., under cron). */
	/* This code is not necessary, but helpful for testing odd things. */
	if (exp_dev_tty == -1) {
		/* give ourselves a controlling tty */
		int master = exp_getptymaster();
		fcntl(master,F_SETFD,1);	/* close-on-exec */
		setpgrp(0,0);
		close(0);
		close(1);
		exp_getptyslave(exp_get_var(exp_interp,"stty_init"));
		close(2);
		fcntl(0,F_DUPFD,2);		/* dup 0 onto 2 */
	}
#endif

	knew_dev_tty = (exp_dev_tty != -1);
	if (knew_dev_tty) ttytype(GET_TTYTYPE,exp_dev_tty,0,0,(char *)0);
}

/* returns fd of master end of pseudotty */
int
exp_getptymaster()
{
	int master = -1;
	char *hex, *bank;
	struct stat statbuf;

	exp_pty_error = 0;

	if (exp_pty_test_start() == -1) return -1;

	for (bank = "pqrstuvwxyzPQRSTUVWXYZ";*bank;bank++) {
		*tty_bank = *bank;
		*tty_num = '0';
		if (stat(master_name, &statbuf) < 0) break;
		for (hex = "0123456789abcdef";*hex;hex++) {
			*tty_num = *hex;

			/* generate slave name from master */
			strcpy(slave_name,master_name);
			*tty_type = 't';

			master = exp_pty_test(master_name,slave_name,
						*tty_bank,tty_num);
			if (master >= 0) goto done;
		}
	}
 done:
	exp_pty_test_end();
	exp_pty_slave_name = slave_name;
	return(master);
}

/* see comment in pty_termios.c */
/*ARGSUSED*/
void
exp_slave_control(master,control)
int master;
int control;
{
}

int
exp_getptyslave(ttycopy,ttyinit,stty_args)
int ttycopy;
int ttyinit;
char *stty_args;
{
	int slave;

	if (0 > (slave = open(slave_name, O_RDWR))) return(-1);

	if (0 == slave) {
		/* if opened in a new process, slave will be 0 (and */
		/* ultimately, 1 and 2 as well) */

		/* duplicate 0 onto 1 and 2 to prepare for stty */
		fcntl(0,F_DUPFD,1);
		fcntl(0,F_DUPFD,2);
	}

	ttytype(SET_TTYTYPE,slave,ttycopy,ttyinit,stty_args);
	(void) exp_pty_unlock();
	return(slave);
}

void
exp_pty_exit()
{
	/* a stub so we can do weird things on the cray */
}
