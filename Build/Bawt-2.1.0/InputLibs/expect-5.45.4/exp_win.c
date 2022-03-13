/* exp_win.c - window support

Written by: Don Libes, NIST, 10/25/93

This file is in the public domain.  However, the author and NIST
would appreciate credit if you use this file or parts of it.

*/

#include "expect_cf.h"
#include "tcl.h"

#ifdef NO_STDLIB_H
#include "../compat/stdlib.h"
#else
#include <stdlib.h>
#endif

/* _IBCS2 required on some Intel platforms to allow the include files */
/* to produce a definition for winsize. */
#define _IBCS2 1

/*
 * get everyone's window size definitions
 *
note that this is tricky because (of course) everyone puts them in
different places.  Worse, on some systems, some .h files conflict
and cannot both be included even though both exist.  This is the
case, for example, on SunOS 4.1.3 using gcc where termios.h
conflicts with sys/ioctl.h
 */

#ifdef HAVE_TERMIOS
#  include <termios.h>
#else
#  include <sys/ioctl.h>
#endif

/* Sigh.  On AIX 2.3, termios.h exists but does not define TIOCGWINSZ */
/* Instead, it has to come from ioctl.h.  However, As I said above, this */
/* can't be cavalierly included on all machines, even when it exists. */
#if defined(HAVE_TERMIOS) && !defined(HAVE_TIOCGWINSZ_IN_TERMIOS_H)
#  include <sys/ioctl.h>
#endif

/* SCO defines window size structure in PTEM and TIOCGWINSZ in termio.h */
/* Sigh... */
#if defined(HAVE_SYS_PTEM_H)
#   include <sys/types.h>   /* for stream.h's caddr_t */
#   include <sys/stream.h>  /* for ptem.h's mblk_t */
#   include <sys/ptem.h>
#endif /* HAVE_SYS_PTEM_H */

#include "exp_tty_in.h"
#include "exp_win.h"

#ifdef TIOCGWINSZ
typedef struct winsize exp_winsize;
#define columns ws_col
#define rows ws_row
#define EXP_WIN
#endif

#if !defined(EXP_WIN) && defined(TIOCGSIZE)
typedef struct ttysize exp_winsize;
#define columns ts_cols
#define rows ts_lines
#define EXP_WIN
#endif

#if !defined(EXP_WIN)
typedef struct {
	int columns;
	int rows;
} exp_winsize;
#endif

static exp_winsize winsize = {0, 0};
static exp_winsize win2size = {0, 0};

int exp_window_size_set(fd)
int fd;
{
#ifdef TIOCSWINSZ
	ioctl(fd,TIOCSWINSZ,&winsize);
#endif
#if defined(TIOCSSIZE) && !defined(TIOCSWINSZ)
	ioctl(fd,TIOCSSIZE,&winsize);
#endif
}

int exp_window_size_get(fd)
int fd;
{
#ifdef TIOCGWINSZ
	ioctl(fd,TIOCGWINSZ,&winsize);
#endif
#if defined(TIOCGSIZE) && !defined(TIOCGWINSZ)
	ioctl(fd,TIOCGSIZE,&winsize);
#endif
#if !defined(EXP_WIN)
	winsize.rows = 0;
	winsize.columns = 0;
#endif
}

void
exp_win_rows_set(rows)
char *rows;
{
	winsize.rows = atoi(rows);
	exp_window_size_set(exp_dev_tty);
}

char*
exp_win_rows_get()
{
    static char rows [20];
	exp_window_size_get(exp_dev_tty);
	sprintf(rows,"%d",winsize.rows);
    return rows;
}

void
exp_win_columns_set(columns)
char *columns;
{
	winsize.columns = atoi(columns);
	exp_window_size_set(exp_dev_tty);
}

char*
exp_win_columns_get()
{
    static char columns [20];
	exp_window_size_get(exp_dev_tty);
	sprintf(columns,"%d",winsize.columns);
    return columns;
}

/*
 * separate copy of everything above - used for handling user stty requests
 */

int exp_win2_size_set(fd)
int fd;
{
#ifdef TIOCSWINSZ
			ioctl(fd,TIOCSWINSZ,&win2size);
#endif
#if defined(TIOCSSIZE) && !defined(TIOCSWINSZ)
			ioctl(fd,TIOCSSIZE,&win2size);
#endif
}

int exp_win2_size_get(fd)
int fd;
{
#ifdef TIOCGWINSZ
	ioctl(fd,TIOCGWINSZ,&win2size);
#endif
#if defined(TIOCGSIZE) && !defined(TIOCGWINSZ)
	ioctl(fd,TIOCGSIZE,&win2size);
#endif
}

void
exp_win2_rows_set(fd,rows)
int fd;
char *rows;
{
	exp_win2_size_get(fd);
	win2size.rows = atoi(rows);
	exp_win2_size_set(fd);
}

char*
exp_win2_rows_get(fd)
int fd;
{
    static char rows [20];
	exp_win2_size_get(fd);
	sprintf(rows,"%d",win2size.rows);
#if !defined(EXP_WIN)
	win2size.rows = 0;
	win2size.columns = 0;
#endif
    return rows;
}

void
exp_win2_columns_set(fd,columns)
int fd;
char *columns;
{
	exp_win2_size_get(fd);
	win2size.columns = atoi(columns);
	exp_win2_size_set(fd);
}

char*
exp_win2_columns_get(fd)
int fd;
{
    static char columns [20];
	exp_win2_size_get(fd);
	sprintf(columns,"%d",win2size.columns);
    return columns;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
