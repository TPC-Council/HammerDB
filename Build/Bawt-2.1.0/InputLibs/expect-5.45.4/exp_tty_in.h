/* exp_tty_in.h - internal tty support definitions */

/* Definitions for handling termio inclusion are localized here */
/* This file should be included only if direct access to tty structures are */
/* required.  This file is necessary to avoid  mismatch between gcc's and */
/* vendor's include files */

/* Written by Rob Savoye <rob@cygnus.com>. Mon Feb 22 11:16:53 RMT 1993 */

#ifndef __EXP_TTY_IN_H__
#define __EXP_TTY_IN_H__

#include "expect_cf.h"

#ifdef __MACHTEN__
#include "sys/types.h"
#endif

/*
 * Set up some macros to isolate tty differences
 */

/* On some hosts, termio is incomplete (broken) and sgtty is a better
choice.  At the same time, termio has some definitions for modern
stuff like window sizes that sgtty lacks - that's why termio.h
is included even when we claim the basic style is sgtty
*/

/* test for pyramid may be unnecessary, but only Pyramid people have */
/* complained - notably pclink@qus102.qld.npb.telecom.com.au (Rick) */
#if defined(pyr) && defined(HAVE_TERMIO) && defined(HAVE_SGTTYB)
#undef HAVE_SGTTYB
#endif

/* on ISC SVR3.2, termios is skeletal and termio is a better choice.  */
/* sgttyb must also be avoided because it redefines same things that */
/* termio does */
/* note that both SVR3.2 and AIX lacks TCGETS or TCGETA in termios.h */
/* but SVR3.2 lacks both TCSETATTR and TCGETS/A */
#if defined(HAVE_TERMIO) && defined(HAVE_TERMIOS) && !defined(HAVE_TCGETS_OR_TCGETA_IN_TERMIOS_H) && !defined(HAVE_TCSETATTR)
# undef HAVE_TERMIOS
# undef HAVE_SGTTYB
#endif

#if defined(HAVE_TERMIO) && !defined(HAVE_TERMIOS)
#  include <termio.h>
#  undef POSIX
#  define TERMINAL termio
#  ifndef TCGETS
#    define TCGETS	TCGETA
#    define TCSETS	TCSETA
#    define TCSETSW	TCSETAW
#    define TCSETSF	TCSETAF
#  endif
#endif

#if defined(HAVE_SGTTYB) && !defined(HAVE_TERMIOS)
#  undef HAVE_TERMIO
#  undef POSIX
#ifndef TCGETS
#  define TCGETS	TIOCGETP
#  define TCSETS	TIOCSETP
#endif
#ifndef TCSETSW
#  define TCSETSW	TIOCSETN
#endif
#  define TERMINAL sgttyb
#  ifdef HAVE_SYS_FCNTL_H
#    include <sys/fcntl.h>
#  else
#    include <fcntl.h>
#  endif
#  include <sgtty.h>
#  include <sys/ioctl.h>
#endif


#if defined(HAVE_TERMIOS)
#  undef HAVE_TERMIO
#  undef HAVE_SGTTYB
#  include <termios.h>
#  define TERMINAL termios
#  if !defined(TCGETS) || !defined(TCSETS)
#    define TCGETS	TCGETA
#    define TCSETS	TCSETA
#    define TCSETSW	TCSETAW
#    define TCSETSF	TCSETAF
#  endif
#endif

/* This section was written by: Don Libes, NIST, 2/6/90 */

typedef struct TERMINAL exp_tty;
extern exp_tty exp_tty_original;
extern exp_tty exp_tty_current;
extern exp_tty exp_tty_cooked;

#include "exp_tty.h"

#endif	/* __EXP_TTY_IN_H__ */
