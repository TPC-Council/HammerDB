/*
 *  Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com>
 *
 * Stylized option processing - requires consitent
 * external vars: opt, idx, objc, objv
 */
#ifndef _TCL_OPTS_H
#define _TCL_OPTS_H

#define OPT_PROLOG(option)			\
    if (strcmp(opt, (option)) == 0) {		\
	if (++idx >= objc) {			\
	    Tcl_AppendResult(interp,		\
		"no argument given for ",	\
		(option), " option",		\
		(char *) NULL);			\
	    return TCL_ERROR;			\
	}
#define OPT_POSTLOG()				\
	continue;				\
    }
#define OPTOBJ(option, var)			\
    OPT_PROLOG(option)				\
    var = objv[idx];				\
    OPT_POSTLOG()

#define OPTSTR(option, var)			\
    OPT_PROLOG(option)				\
    var = Tcl_GetStringFromObj(objv[idx], NULL);\
    OPT_POSTLOG()

#define OPTINT(option, var)			\
    OPT_PROLOG(option)				\
    if (Tcl_GetIntFromObj(interp, objv[idx],	\
	    &(var)) != TCL_OK) {		\
	    return TCL_ERROR;			\
    }						\
    OPT_POSTLOG()

#define OPTBOOL(option, var)			\
    OPT_PROLOG(option)				\
    if (Tcl_GetBooleanFromObj(interp, objv[idx],\
	    &(var)) != TCL_OK) {		\
	    return TCL_ERROR;			\
    }						\
    OPT_POSTLOG()

#define OPTBYTE(option, var, lvar)			\
    OPT_PROLOG(option)				\
    var = Tcl_GetByteArrayFromObj(objv[idx], &(lvar));\
    OPT_POSTLOG()

#define OPTBAD(type, list)			\
    Tcl_AppendResult(interp, "bad ", (type),	\
		" \"", opt, "\": must be ",	\
		(list), (char *) NULL)

#endif /* _TCL_OPTS_H */
