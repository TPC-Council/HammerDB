/* unbuffer.c */

#include <stdio.h>
#include "expect.h"

main(argc,argv)
int argc;
char *argv[];
{
	argv++;
	exp_timeout = -1;
	exp_expectl(exp_spawnv(*argv,argv),exp_end);
}
