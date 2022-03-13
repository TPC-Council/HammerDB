/* exp_tty.h - tty support definitions

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#ifndef __EXP_TTY_H__
#define __EXP_TTY_H__

#include "expect_cf.h"

extern int exp_dev_tty;
extern int exp_ioctled_devtty;
extern int exp_stdin_is_tty;
extern int exp_stdout_is_tty;

void exp_tty_raw(int set);
void exp_tty_echo(int set);
void exp_tty_break(Tcl_Interp *interp, int fd);
int exp_tty_raw_noecho(Tcl_Interp *interp, exp_tty *tty_old, int *was_raw, int *was_echo);
int exp_israw(void);
int exp_isecho(void);

void exp_tty_set(Tcl_Interp *interp, exp_tty *tty, int raw, int echo);
int exp_tty_set_simple(exp_tty *tty);
int exp_tty_get_simple(exp_tty *tty);

#endif	/* __EXP_TTY_H__ */
