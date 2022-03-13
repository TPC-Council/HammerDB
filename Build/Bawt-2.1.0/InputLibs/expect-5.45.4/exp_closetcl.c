#if OBSOLETE
/* exp_closetcl.c - close tcl files */

/* isolated in it's own file since it has hooks into Tcl and exp_clib user */
/* might like to avoid dragging it in */

#include "expect_cf.h"

void (*exp_close_in_child)() = 0;

void
exp_close_tcl_files() {
    /* I don't believe this function is used any longer, at least in
       the Expect program.*/
}
#endif /* OBSOLETE */
