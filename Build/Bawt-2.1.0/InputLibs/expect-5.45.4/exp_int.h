/* exp_int.h - private symbols common to both expect program and library

Written by: Don Libes, libes@cme.nist.gov, NIST, 12/3/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#ifndef _EXPECT_INT_H
#define _EXPECT_INT_H

#ifndef TRUE
#define FALSE 0
#define TRUE 1
#endif

#ifndef HAVE_MEMCPY
#define memcpy(x,y,len) bcopy(y,x,len)
#endif

#include <errno.h>

void	exp_console_set     _ANSI_ARGS_((void));
void	expDiagLogPtrSet    _ANSI_ARGS_((void (*)_ANSI_ARGS_((char *))));
void	expDiagLogPtr       _ANSI_ARGS_((char *));
void	expDiagLogPtrX      _ANSI_ARGS_((char *,int));
void	expDiagLogPtrStr    _ANSI_ARGS_((char *,char *));
void	expDiagLogPtrStrStr _ANSI_ARGS_((char *,char *,char *));
void	expErrnoMsgSet      _ANSI_ARGS_((char * (*) _ANSI_ARGS_((int))));
char * expErrnoMsg    _ANSI_ARGS_((int));

#ifdef NO_STDLIB_H
#  include "../compat/stdlib.h"
#else
#  include <stdlib.h>		/* for malloc */
#endif /*NO_STDLIB_H*/

#endif /* _EXPECT_INT_H */
