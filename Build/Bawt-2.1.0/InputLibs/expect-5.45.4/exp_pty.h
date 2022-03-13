/* exp_pty.h - declarations for pty allocation and testing

Written by: Don Libes, NIST,  3/9/93

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

int exp_pty_test_start(void);
void exp_pty_test_end(void);
int exp_pty_test(char *master_name, char *slave_name, char bank, char *num);
void exp_pty_unlock(void);
int exp_pty_lock(char bank, char *num);
int exp_getptymaster(void);
int exp_getptyslave(int ttycopy, int ttyinit, CONST char *stty_args);

extern char *exp_pty_slave_name;
