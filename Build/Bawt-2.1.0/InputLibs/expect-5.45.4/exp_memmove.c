/* memmove - some systems lack this */

#include "expect_cf.h"
#include "tcl.h"

/* like memcpy but can handle overlap */
#ifndef HAVE_MEMMOVE
char *
memmove(dest,src,n)
VOID *dest;
CONST VOID *src;
int n;
{
	char *d;
	CONST char *s;

	d = dest;
	s = src;
	if (s<d && (d < s+n)) {
		for (d+=n, s+=n; 0<n; --n)
			*--d = *--s;
	} else for (;0<n;--n) *d++ = *s++;
	return dest;
}
#endif /* HAVE_MEMMOVE */
