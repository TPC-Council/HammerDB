/* exp_select.c - select() interface for Expect

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

/* suppress file-empty warnings produced by some compilers */
void exp_unused() {}

#if 0 /* WHOLE FILE!!!! */
#include "expect_cf.h"
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#ifdef HAVE_SYSSELECT_H
#  include <sys/select.h>	/* Intel needs this for timeval */
#endif

#ifdef HAVE_PTYTRAP
#  include <sys/ptyio.h>
#endif

#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif

#ifdef _AIX
/* AIX has some unusual definition of FD_SET */
#include <sys/select.h>
#endif

#if !defined( FD_SET )  &&  defined( HAVE_SYS_BSDTYPES_H )
    /* like AIX, ISC has it's own definition of FD_SET */
#   include <sys/bsdtypes.h>
#endif /*  ! FD_SET  &&  HAVE_SYS_BSDTYPES_H */

#include "tcl.h"
#include "exp_prog.h"
#include "exp_command.h"	/* for struct exp_f defs */
#include "exp_event.h"

#ifdef HAVE_SYSCONF_H
#include <sys/sysconfig.h>
#endif

#ifndef FD_SET
#define FD_SET(fd,fdset)	(fdset)->fds_bits[0] |= (1<<(fd))
#define FD_CLR(fd,fdset)	(fdset)->fds_bits[0] &= ~(1<<(fd))
#define FD_ZERO(fdset)		(fdset)->fds_bits[0] = 0
#define FD_ISSET(fd,fdset)	(((fdset)->fds_bits[0]) & (1<<(fd)))
#ifndef AUX2
typedef struct fd_set {
	long fds_bits[1];
	/* any implementation so pathetic as to not define FD_SET will just */
	/* have to suffer with only 32 bits worth of fds */
} fd_set;
#endif /* AUX2 */
#endif

static struct timeval zerotime = {0, 0};
static struct timeval anytime = {0, 0};	/* can be changed by user */

/* returns status, one of EOF, TIMEOUT, ERROR or DATA */
int
exp_get_next_event(interp,masters, n,master_out,timeout,key)
Tcl_Interp *interp;
int *masters;
int n;			/* # of masters */
int *master_out;	/* 1st event master, not set if none */
int timeout;		/* seconds */
int key;
{
	static rr = 0;	/* round robin ptr */

	int i;	/* index into in-array */
	struct timeval *t;

	fd_set rdrs;
	fd_set excep;
/* FIXME: This is really gross, but the folks at Lynx said their select is
 *        way hosed and to ignore all exceptions.
 */
#ifdef __Lynx__
#define EXCEP 0
#else
#define EXCEP &excep
#endif

	for (i=0;i<n;i++) {
		struct exp_f *f;
		int m;

		rr++;
		if (rr >= n) rr = 0;

		m = masters[rr];
		f = exp_fs + m;

		if (f->key != key) {
			f->key = key;
			f->force_read = FALSE;
			*master_out = m;
			return(EXP_DATA_OLD);
		} else if ((!f->force_read) && (f->size != 0)) {
			*master_out = m;
			return(EXP_DATA_OLD);
		}
	}

	if (timeout >= 0) {
		t = &anytime;
		t->tv_sec = timeout;
	} else {
		t = NULL;
	}

 restart:
	if (Tcl_AsyncReady()) {
		int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		if (rc != TCL_OK) return(exp_tcl2_returnvalue(rc));

		/* anything in the environment could have changed */
		return EXP_RECONFIGURE;
	}

	FD_ZERO(&rdrs);
	FD_ZERO(&excep);
	for (i = 0;i < n;i++) {
		FD_SET(masters[i],&rdrs);
		FD_SET(masters[i],&excep);
	}

	/* The reason all fd masks are (seemingly) redundantly cast to */
	/* SELECT_MASK_TYPE is that the HP defines its mask in terms of */
	/* of int * and yet defines FD_SET in terms of fd_set. */

	if (-1 == select(exp_fd_max+1,
			(SELECT_MASK_TYPE *)&rdrs,
			(SELECT_MASK_TYPE *)0,
			(SELECT_MASK_TYPE *)EXCEP,
			t)) {
		/* window refreshes trigger EINTR, ignore */
		if (errno == EINTR) goto restart;
		else if (errno == EBADF) {
		    /* someone is rotten */
		    for (i=0;i<n;i++) {
			fd_set suspect;
			FD_ZERO(&suspect);
			FD_SET(masters[i],&suspect);
			if (-1 == select(exp_fd_max+1,
			    		(SELECT_MASK_TYPE *)&suspect,
			    		(SELECT_MASK_TYPE *)0,
					(SELECT_MASK_TYPE *)0,
					&zerotime)) {
				exp_error(interp,"invalid spawn_id (%d)\r",masters[i]);
				return(EXP_TCLERROR);
			}
		   }
	        } else {
			/* not prepared to handle anything else */
			exp_error(interp,"select: %s\r",Tcl_PosixError(interp));
			return(EXP_TCLERROR);
		}
	}

	for (i=0;i<n;i++) {
		rr++;
		if (rr >= n) rr = 0;	/* ">" catches previous readys that */
				/* used more fds then we're using now */

		if (FD_ISSET(masters[rr],&rdrs)) {
			*master_out = masters[rr];
			return(EXP_DATA_NEW);
/*#ifdef HAVE_PTYTRAP*/
		} else if (FD_ISSET(masters[rr], &excep)) {
#ifndef HAVE_PTYTRAP
			*master_out = masters[rr];
			return(EXP_EOF);
#else
			struct request_info ioctl_info;
			if (ioctl(masters[rr],TIOCREQCHECK,&ioctl_info) < 0) {
				exp_DiagLog("ioctl error on TIOCREQCHECK: %s",Tcl_ErrnoMsg(errno));
				break;
			}
			if (ioctl_info.request == TIOCCLOSE) {
				/* eof */
				*master_out = masters[rr];
				return(EXP_EOF);
			}
			if (ioctl(masters[rr], TIOCREQSET, &ioctl_info) < 0)
				expDiagLog("ioctl error on TIOCREQSET after ioctl or open on slave: %s", Tcl_ErrnoMsg(errno));
			/* presumably, we trapped an open here */
			goto restart;
#endif /* HAVE_PTYTRAP */
		}
	}
	return(EXP_TIMEOUT);
}

/*ARGSUSED*/
int
exp_get_next_event_info(interp,fd,ready_mask)
Tcl_Interp *interp;
int fd;
int ready_mask;
{
	/* this function is only used when running with Tk */
	/* hence, it is merely a stub in this file but to */
	/* pacify lint, return something */
	return 0;
}

int	/* returns TCL_XXX */
exp_dsleep(interp,sec)
Tcl_Interp *interp;
double sec;
{
	struct timeval t;

	t.tv_sec = sec;
	t.tv_usec = (sec - t.tv_sec) * 1000000L;
 restart:
	if (Tcl_AsyncReady()) {
		int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		if (rc != TCL_OK) return rc;
	}
	if (-1 == select(1,
			(SELECT_MASK_TYPE *)0,
			(SELECT_MASK_TYPE *)0,
			(SELECT_MASK_TYPE *)0,
			&t)
				&& errno == EINTR)
		goto restart;
	return TCL_OK;
}

#if 0
int	/* returns TCL_XXX */
exp_usleep(interp,usec)
Tcl_Interp *interp;
long usec;		/* microseconds */
{
	struct timeval t;

	t.tv_sec = usec/1000000L;
	t.tv_usec = usec%1000000L;
 restart:
	if (Tcl_AsyncReady()) {
		int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		if (rc != TCL_OK) return(exp_tcl2_returnvalue(rc));
	}
	if (-1 == select(1,
			(SELECT_MASK_TYPE *)0,
			(SELECT_MASK_TYPE *)0,
			(SELECT_MASK_TYPE *)0,
			&t)
				&& errno == EINTR)
		goto restart;
	return TCL_OK;
}
#endif /*0*/

/* set things up for later calls to event handler */
void
exp_init_event()
{
#if 0
#ifdef _SC_OPEN_MAX
	maxfds = sysconf(_SC_OPEN_MAX);
#else
	maxfds = getdtablesize();
#endif
#endif

	exp_event_exit = 0;
}
#endif /* WHOLE FILE !!!! */
