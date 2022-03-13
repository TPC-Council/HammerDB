/* Dbg.c - Tcl Debugger - See cmdHelp() for commands

Written by: Don Libes, NIST, 3/23/93

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include <stdio.h>

#ifndef HAVE_STRCHR
#define strchr(s,c) index(s,c)
#endif /* HAVE_STRCHR */

#if 0
/* tclInt.h drags in stdlib.  By claiming no-stdlib, force it to drag in */
/* Tcl's compat version.  This avoids having to test for its presence */
/* which is too tricky - configure can't generate two cf files, so when */
/* Expect (or any app) uses the debugger, there's no way to get the info */
/* about whether stdlib exists or not, except pointing the debugger at */
/* an app-dependent .h file and I don't want to do that. */
#define NO_STDLIB_H
#endif


#include "tclInt.h"
/*#include <varargs.h>		tclInt.h drags in varargs.h.  Since Pyramid */
/*				objects to including varargs.h twice, just */
/*				omit this one. */
/*#include "string.h"		tclInt.h drags this in, too! */
#include "tcldbg.h"

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

static int simple_interactor (Tcl_Interp *interp, ClientData data);
static int zero (Tcl_Interp *interp, char *string);

/* most of the static variables in this file may be */
/* moved into Tcl_Interp */

static Dbg_InterProc *interactor = &simple_interactor;
static ClientData interdata = 0;
static Dbg_IgnoreFuncsProc *ignoreproc = &zero;
static Dbg_OutputProc *printproc = 0;
static ClientData printdata = 0;
static int stdinmode;

static void print _ANSI_ARGS_(TCL_VARARGS(Tcl_Interp *,interp));

static int debugger_active = FALSE;

/* this is not externally documented anywhere as of yet */
char *Dbg_VarName = "dbg";

#define DEFAULT_COMPRESS	0
static int compress = DEFAULT_COMPRESS;
#define DEFAULT_WIDTH		75	/* leave a little space for printing */
					/*  stack level */
static int buf_width = DEFAULT_WIDTH;

static int main_argc = 1;
static char *default_argv = "application";
static char **main_argv = &default_argv;

static Tcl_Trace debug_handle;
static int step_count = 1;	/* count next/step */

#define FRAMENAMELEN 10		/* enough to hold strings like "#4" */
static char viewFrameName[FRAMENAMELEN];/* destination frame name for up/down */

static CallFrame *goalFramePtr;	/* destination for next/return */
static int goalNumLevel;	/* destination for Next */

static enum debug_cmd {
	none, step, next, ret, cont, up, down, where, Next
} debug_cmd = step;

/* info about last action to use as a default */
static enum debug_cmd last_action_cmd = next;
static int last_step_count = 1;

/* this acts as a strobe (while testing breakpoints).  It is set to true */
/* every time a new debugger command is issued that is an action */
static int debug_new_action;

#define NO_LINE -1	/* if break point is not set by line number */

struct breakpoint {
	int id;
	Tcl_Obj *file;	/* file where breakpoint is */
	int line;	/* line where breakpoint is */
	int re;		/* 1 if this is regexp pattern */
	Tcl_Obj *pat;	/* pattern defining where breakpoint can be */
	Tcl_Obj *expr;	/* expr to trigger breakpoint */
	Tcl_Obj *cmd;	/* cmd to eval at breakpoint */
	struct breakpoint *next, *previous;
};

static struct breakpoint *break_base = 0;
static int breakpoint_max_id = 0;

static struct breakpoint *
breakpoint_new()
{
	struct breakpoint *b = (struct breakpoint *)ckalloc(sizeof(struct breakpoint));
	if (break_base) break_base->previous = b;
	b->next = break_base;
	b->previous = 0;
	b->id = breakpoint_max_id++;
	b->file = 0;
	b->line = NO_LINE;
	b->pat = 0;
	b->re = 0;
	b->expr = 0;
	b->cmd = 0;
	break_base = b;
	return(b);
}

static
void
breakpoint_print(interp,b)
Tcl_Interp *interp;
struct breakpoint *b;
{
    print(interp,"breakpoint %d: ",b->id);

    if (b->re) {
	print(interp,"-re \"%s\" ",Tcl_GetString(b->pat));
    } else if (b->pat) {
	print(interp,"-glob \"%s\" ",Tcl_GetString(b->pat));
    } else if (b->line != NO_LINE) {
	if (b->file) {
	    print(interp,"%s:",Tcl_GetString(b->file));
	}
	print(interp,"%d ",b->line);
    }

    if (b->expr)
	print(interp,"if {%s} ",Tcl_GetString(b->expr));

    if (b->cmd)
	print(interp,"then {%s}",Tcl_GetString(b->cmd));

    print(interp,"\n");
}

static void
save_re_matches(interp, re, objPtr)
Tcl_Interp *interp;
Tcl_RegExp re;
Tcl_Obj *objPtr;
{
    Tcl_RegExpInfo info;
    int i, start;
    char name[20];

    Tcl_RegExpGetInfo(re, &info); 
    for (i=0;i<=info.nsubs;i++) {
	start = info.matches[i].start;
	/* end = info.matches[i].end-1;*/

	if (start == -1) continue;

	sprintf(name,"%d",i);
	Tcl_SetVar2Ex(interp, Dbg_VarName, name, Tcl_GetRange(objPtr,
		info.matches[i].start, info.matches[i].end-1), 0);
    }
}

/* return 1 to break, 0 to continue */
static int
breakpoint_test(interp,cmd,bp)
Tcl_Interp *interp;
char *cmd;		/* command about to be executed */
struct breakpoint *bp;	/* breakpoint to test */
{
    if (bp->re) {
        int found = 0;
	Tcl_Obj *cmdObj;
	Tcl_RegExp re = Tcl_GetRegExpFromObj(NULL, bp->pat,
		TCL_REG_ADVANCED);
	cmdObj = Tcl_NewStringObj(cmd,-1);
	Tcl_IncrRefCount(cmdObj);
	if (Tcl_RegExpExecObj(NULL, re, cmdObj, 0 /* offset */,
		-1 /* nmatches */, 0 /* eflags */) > 0) {
	    save_re_matches(interp, re, cmdObj);
	    found = 1;
	}
	Tcl_DecrRefCount(cmdObj);
	if (!found) return 0;
    } else if (bp->pat) {
	if (0 == Tcl_StringMatch(cmd,
		Tcl_GetString(bp->pat))) return 0;
    } else if (bp->line != NO_LINE) {
	/* not yet implemented - awaiting support from Tcl */
	return 0;
    }

    if (bp->expr) {
	int value;

	/* ignore errors, since they are likely due to */
	/* simply being out of scope a lot */
	if (TCL_OK != Tcl_ExprBooleanObj(interp,bp->expr,&value)
		|| (value == 0)) return 0;
    }

    if (bp->cmd) {
	Tcl_EvalObjEx(interp, bp->cmd, 0);
    } else {
	breakpoint_print(interp,bp);
    }

    return 1;
}

static char *already_at_top_level = "already at top level";

/* similar to TclGetFrame but takes two frame ptrs and a direction.
If direction is up,   search up stack from curFrame
If direction is down, simulate searching down stack by
		      seaching up stack from origFrame
*/
static
int
TclGetFrame2(interp, origFramePtr, string, framePtrPtr, dir)
    Tcl_Interp *interp;
    CallFrame *origFramePtr;	/* frame that is true top-of-stack */
    char *string;		/* String describing frame. */
    CallFrame **framePtrPtr;	/* Store pointer to frame here (or NULL
				 * if global frame indicated). */
    enum debug_cmd dir;	/* look up or down the stack */
{
    Interp *iPtr = (Interp *) interp;
    int level, result;
    CallFrame *framePtr;	/* frame currently being searched */

    CallFrame *curFramePtr = iPtr->varFramePtr;

    /*
     * Parse string to figure out which level number to go to.
     */

    result = 1;
    if (*string == '#') {
	if (Tcl_GetInt(interp, string+1, &level) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (level < 0) {
	    levelError:
	    Tcl_AppendResult(interp, "bad level \"", string, "\"",
		    (char *) NULL);
	    return TCL_ERROR;
	}
	framePtr = origFramePtr; /* start search here */
	
    } else if (isdigit(*string)) {
	if (Tcl_GetInt(interp, string, &level) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (dir == up) {
		if (curFramePtr == 0) {
			Tcl_SetResult(interp,already_at_top_level,TCL_STATIC);
			return TCL_ERROR;
		}
		level = curFramePtr->level - level;
		framePtr = curFramePtr; /* start search here */
	} else {
		if (curFramePtr != 0) {
			level = curFramePtr->level + level;
		}
		framePtr = origFramePtr; /* start search here */
	}
    } else {
	level = curFramePtr->level - 1;
	result = 0;
    }

    /*
     * Figure out which frame to use.
     */

    if (level == 0) {
	framePtr = NULL;
    } else {
	for (;framePtr != NULL;	framePtr = framePtr->callerVarPtr) {
	    if (framePtr->level == level) {
		break;
	    }
	}
	if (framePtr == NULL) {
	    goto levelError;
	}
    }
    *framePtrPtr = framePtr;
    return result;
}


static char *printify(s)
char *s;
{
    static int destlen = 0;
    char *d;		/* ptr into dest */
    unsigned int need;
    static char buf_basic[DEFAULT_WIDTH+1];
    static char *dest = buf_basic;
    Tcl_UniChar ch;

    if (s == 0) return("<null>");

    /* worst case is every character takes 4 to printify */
    need = strlen(s)*6;
    if (need > destlen) {
	if (dest && (dest != buf_basic)) ckfree(dest);
	dest = (char *)ckalloc(need+1);
	destlen = need;
    }

    for (d = dest;*s;) {
	s += Tcl_UtfToUniChar(s, &ch);
	if (ch == '\b') {
	    strcpy(d,"\\b");		d += 2;
	} else if (ch == '\f') {
	    strcpy(d,"\\f");		d += 2;
	} else if (ch == '\v') {
	    strcpy(d,"\\v");		d += 2;
	} else if (ch == '\r') {
	    strcpy(d,"\\r");		d += 2;
	} else if (ch == '\n') {
	    strcpy(d,"\\n");		d += 2;
	} else if (ch == '\t') {
	    strcpy(d,"\\t");		d += 2;
	} else if ((unsigned)ch < 0x20) { /* unsigned strips parity */
	    sprintf(d,"\\%03o",ch);		d += 4;
	} else if (ch == 0177) {
	    strcpy(d,"\\177");		d += 4;
	} else if ((ch < 0x80) && isprint(UCHAR(ch))) {
	    *d = (char)ch;		d += 1;
	} else {
	    sprintf(d,"\\u%04x",ch);	d += 6;
	}
    }
    *d = '\0';
    return(dest);
}

static
char *
print_argv(interp,argc,argv)
Tcl_Interp *interp;
int argc;
char *argv[];
{
	static int buf_width_max = DEFAULT_WIDTH;
	static char buf_basic[DEFAULT_WIDTH+1];	/* basic buffer */
	static char *buf = buf_basic;
	int space;		/* space remaining in buf */
	int len;
	char *bufp;
	int proc;		/* if current command is "proc" */
	int arg_index;

	if (buf_width > buf_width_max) {
		if (buf && (buf != buf_basic)) ckfree(buf);
		buf = (char *)ckalloc(buf_width + 1);
		buf_width_max = buf_width;
	}

	proc = (0 == strcmp("proc",argv[0]));
	sprintf(buf,"%.*s",buf_width,argv[0]);
	len = strlen(buf);
	space = buf_width - len;
	bufp = buf + len;
	argc--; argv++;
	arg_index = 1;
	
	while (argc && (space > 0)) {
		CONST char *elementPtr;
		CONST char *nextPtr;
		int wrap;

		/* braces/quotes have been stripped off arguments */
		/* so put them back.  We wrap everything except lists */
		/* with one argument.  One exception is to always wrap */
		/* proc's 2nd arg (the arg list), since people are */
		/* used to always seeing it this way. */

		if (proc && (arg_index > 1)) wrap = TRUE;
		else {
			(void) TclFindElement(interp,*argv,
#if TCL_MAJOR_VERSION >= 8
					      -1,
#endif
				&elementPtr,&nextPtr,(int *)0,(int *)0);
			if (*elementPtr == '\0') wrap = TRUE;
			else if (*nextPtr == '\0') wrap = FALSE;
			else wrap = TRUE;
		}

		/* wrap lists (or null) in braces */
		if (wrap) {
			sprintf(bufp," {%.*s}",space-3,*argv);
		} else {
			sprintf(bufp," %.*s",space-1,*argv);
		}
		len = strlen(buf);
		space = buf_width - len;
		bufp = buf + len;
		argc--; argv++;
		arg_index++;
	}

	if (compress) {
		/* this copies from our static buf to printify's static buf */
		/* and back to our static buf */
		strncpy(buf,printify(buf),buf_width);
	}

	/* usually but not always right, but assume truncation if buffer is */
	/* full.  this avoids tiny but odd-looking problem of appending "}" */
	/* to truncated lists during {}-wrapping earlier */
	if (strlen(buf) == buf_width) {
		buf[buf_width-1] = buf[buf_width-2] = buf[buf_width-3] = '.';
	}

	return(buf);
}

#if TCL_MAJOR_VERSION >= 8
static
char *
print_objv(interp,objc,objv)
Tcl_Interp *interp;
int objc;
Tcl_Obj *objv[];
{
    char **argv;
    int argc;
    int len;
    argv = (char **)ckalloc(objc+1 * sizeof(char *));
    for (argc=0 ; argc<objc ; argc++) {
	argv[argc] = Tcl_GetStringFromObj(objv[argc],&len);
    }
    argv[argc] = NULL;
    return(print_argv(interp,argc,argv));
}
#endif

static
void
PrintStackBelow(interp,curf,viewf)
Tcl_Interp *interp;
CallFrame *curf;	/* current FramePtr */
CallFrame *viewf;	/* view FramePtr */
{
	char ptr;	/* graphically indicate where we are in the stack */

	/* indicate where we are in the stack */
	ptr = ((curf == viewf)?'*':' ');

	if (curf == 0) {
		print(interp,"%c0: %s\n",
				ptr,print_argv(interp,main_argc,main_argv));
	} else {
		PrintStackBelow(interp,curf->callerVarPtr,viewf);
		print(interp,"%c%d: %s\n",ptr,curf->level,
#if TCL_MAJOR_VERSION >= 8
	      print_objv(interp,curf->objc,curf->objv)
#else
	      print_argv(interp,curf->argc,curf->argv)
#endif
	      );
	}
}

static
void
PrintStack(interp,curf,viewf,objc,objv,level)
Tcl_Interp *interp;
CallFrame *curf;	/* current FramePtr */
CallFrame *viewf;	/* view FramePtr */
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
char *level;
{
	PrintStackBelow(interp,curf,viewf);
    print(interp," %s: %s\n",level,print_objv(interp,objc,objv));
}

/* return 0 if goal matches current frame or goal can't be found */
/*	anywere in frame stack */
/* else return 1 */
/* This catches things like a proc called from a Tcl_Eval which in */
/* turn was not called from a proc but some builtin such as source */
/* or Tcl_Eval.  These builtin calls to Tcl_Eval lose any knowledge */
/* the FramePtr from the proc, so we have to search the entire */
/* stack frame to see if it's still there. */
static int
GoalFrame(goal,iptr)
CallFrame *goal;
Interp *iptr;
{
	CallFrame *cf = iptr->varFramePtr;

	/* if at current level, return success immediately */
	if (goal == cf) return 0;

	while (cf) {
		cf = cf->callerVarPtr;
		if (goal == cf) {
			/* found, but since it's above us, fail */
			return 1;
		}
	}
	return 0;
}

#if 0
static char *cmd_print(cmdtype)
enum debug_cmd cmdtype;
{
	switch (cmdtype) {
	case none:  return "cmd: none";
	case step:  return "cmd: step";
	case next:  return "cmd: next";
	case ret:   return "cmd: ret";
	case cont:  return "cmd: cont";
	case up:    return "cmd: up";
	case down:  return "cmd: down";
	case where: return "cmd: where";
	case Next:  return "cmd: Next";
	}
	return "cmd: Unknown";
}
#endif

/* debugger's trace handler */

static int
debugger_trap _ANSI_ARGS_ ((
     ClientData clientData,
     Tcl_Interp *interp,
     int level,
     CONST char *command,
     Tcl_Command commandInfo,
     int objc,
     struct Tcl_Obj * CONST * objv));


/*ARGSUSED*/
static int
debugger_trap(clientData,interp,level,command,commandInfo,objc,objv)
     ClientData clientData;		/* not used */
     Tcl_Interp *interp;
     int level;			/* positive number if called by Tcl, -1 if */
				/* called by Dbg_On in which case we don't */
				/* know the level */
     CONST char *command;
     Tcl_Command commandInfo; /* Unused */
     int objc;
     struct Tcl_Obj * CONST * objv;
{
	char level_text[6];	/* textual representation of level */

	int break_status;
	Interp *iPtr = (Interp *)interp;

	CallFrame *trueFramePtr;	/* where the pc is */
	CallFrame *viewFramePtr;	/* where up/down are */

	int print_command_first_time = TRUE;
	static int debug_suspended = FALSE;

	struct breakpoint *b;

    char* thecmd;

	/* skip commands that are invoked interactively */
    if (debug_suspended) return TCL_OK;

    thecmd = Tcl_GetString (objv[0]);
	/* skip debugger commands */
    if (thecmd[1] == '\0') {
	switch (thecmd[0]) {
		case 'n':
		case 's':
		case 'c':
		case 'r':
		case 'w':
		case 'b':
		case 'u':
	case 'd': return TCL_OK;
		}
	}

    if ((*ignoreproc)(interp,thecmd)) return TCL_OK;

	/* if level is unknown, use "?" */
	sprintf(level_text,(level == -1)?"?":"%d",level);

	/* save so we can restore later */
	trueFramePtr = iPtr->varFramePtr;

	/* do not allow breaking while testing breakpoints */
	debug_suspended = TRUE;

	/* test all breakpoints to see if we should break */
	/* if any successful breakpoints, start interactor */
	debug_new_action = FALSE;	/* reset strobe */
	break_status = FALSE;		/* no successful breakpoints yet */
	for (b = break_base;b;b=b->next) {
		break_status |= breakpoint_test(interp,command,b);
	}
	if (break_status) {
		if (!debug_new_action) {
			goto start_interact;
		}

		/* if s or n triggered by breakpoint, make "s 1" */
		/* (and so on) refer to next command, not this one */
		/* step_count++;*/
		goto end_interact;
	}

	switch (debug_cmd) {
	case cont:
		goto finish;
	case step:
		step_count--;
		if (step_count > 0) goto finish;
		goto start_interact;
	case next:
		/* check if we are back at the same level where the next */
		/* command was issued.  Also test */
		/* against all FramePtrs and if no match, assume that */
		/* we've missed a return, and so we should break  */
/*		if (goalFramePtr != iPtr->varFramePtr) goto finish;*/
		if (GoalFrame(goalFramePtr,iPtr)) goto finish;
		step_count--;
		if (step_count > 0) goto finish;
		goto start_interact;
	case Next:
		/* check if we are back at the same level where the next */
		/* command was issued.  */
		if (goalNumLevel < iPtr->numLevels) goto finish;
		step_count--;
		if (step_count > 0) goto finish;
		goto start_interact;
	case ret:
		/* same comment as in "case next" */
		if (goalFramePtr != iPtr->varFramePtr) goto finish;
		goto start_interact;
    /* DANGER: unhandled cases! none, up, down, where */
	}

start_interact:
	if (print_command_first_time) {
		print(interp,"%s: %s\n",
				level_text,print_argv(interp,1,&command));
		print_command_first_time = FALSE;
	}
	/* since user is typing a command, don't interrupt it immediately */
	debug_cmd = cont;
	debug_suspended = TRUE;

	/* interactor won't return until user gives a debugger cmd */
	(*interactor)(interp,interdata);
end_interact:

	/* save this so it can be restored after "w" command */
	viewFramePtr = iPtr->varFramePtr;

	if (debug_cmd == up || debug_cmd == down) {
		/* calculate new frame */
		if (-1 == TclGetFrame2(interp,trueFramePtr,viewFrameName,
					&iPtr->varFramePtr,debug_cmd)) {
	    print(interp,"%s\n",Tcl_GetStringResult (interp));
			Tcl_ResetResult(interp);
		}
		goto start_interact;
	}

	/* reset view back to normal */
	iPtr->varFramePtr = trueFramePtr;

#if 0
	/* allow trapping */
	debug_suspended = FALSE;
#endif

	switch (debug_cmd) {
	case cont:
	case step:
		goto finish;
	case next:
		goalFramePtr = iPtr->varFramePtr;
		goto finish;
	case Next:
		goalNumLevel = iPtr->numLevels;
		goto finish;
	case ret:
		goalFramePtr = iPtr->varFramePtr;
		if (goalFramePtr == 0) {
			print(interp,"nowhere to return to\n");
			break;
		}
		goalFramePtr = goalFramePtr->callerVarPtr;
		goto finish;
	case where:
	PrintStack(interp,iPtr->varFramePtr,viewFramePtr,objc,objv,level_text);
		break;
	}

	/* restore view and restart interactor */
	iPtr->varFramePtr = viewFramePtr;
	goto start_interact;

 finish:
	debug_suspended = FALSE;
	return TCL_OK;
}

/*ARGSUSED*/
static
int
cmdNext(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
	debug_new_action = TRUE;
	debug_cmd = *(enum debug_cmd *)clientData;

	last_action_cmd = debug_cmd;

    if (objc == 1) {
	step_count = 1;
    } else if (TCL_OK != Tcl_GetIntFromObj (interp, objv[1], &step_count)) {
	return TCL_ERROR;
    }

	last_step_count = step_count;
	return(TCL_RETURN);
}

/*ARGSUSED*/
static
int
cmdDir(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
    char* frame;
    debug_cmd = *(enum debug_cmd *)clientData;

    if (objc == 1) {
	frame = "1";
    } else {
	frame = Tcl_GetString (objv[1]);
    }

    strncpy(viewFrameName,frame,FRAMENAMELEN);
	return TCL_RETURN;
}

/*ARGSUSED*/
static
int
cmdSimple(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
	debug_new_action = TRUE;
	debug_cmd = *(enum debug_cmd *)clientData;
	last_action_cmd = debug_cmd;

	return TCL_RETURN;
}

static
void
breakpoint_destroy(b)
struct breakpoint *b;
{
	if (b->file) Tcl_DecrRefCount(b->file);
	if (b->pat) Tcl_DecrRefCount(b->pat);
	if (b->cmd) Tcl_DecrRefCount(b->cmd);
	if (b->expr) Tcl_DecrRefCount(b->expr);

	/* unlink from chain */
	if ((b->previous == 0) && (b->next == 0)) {
		break_base = 0;
	} else if (b->previous == 0) {
		break_base = b->next;
		b->next->previous = 0;
	} else if (b->next == 0) {
		b->previous->next = 0;
	} else {
		b->previous->next = b->next;
		b->next->previous = b->previous;
	}

	ckfree((char *)b);
}

static void
savestr(objPtr,str)
Tcl_Obj **objPtr;
char *str;
{
    *objPtr = Tcl_NewStringObj(str, -1);
    Tcl_IncrRefCount(*objPtr);
}

/*ARGSUSED*/
static
int
cmdWhere(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
    static char* options [] = {
	"-compress",
	"-width",
	NULL
    };
    enum options {
	WHERE_COMPRESS,
	WHERE_WIDTH
    };
    int i;

    if (objc == 1) {
		debug_cmd = where;
		return TCL_RETURN;
	}

    /* Check and process switches */

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
		}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
				&index) != TCL_OK) {
	    goto usage;
	}
	switch ((enum options) index) {
	case WHERE_COMPRESS:
	    i++;
	    if (i >= objc) {
		print(interp,"%d\n",compress);
		break;
	    }
	    if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[i], &buf_width))
		goto usage;
	    break;
	case WHERE_WIDTH:
	    i++;
	    if (i >= objc) {
		print(interp,"%d\n",buf_width);
		break;
	}
	    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &buf_width))
		goto usage;
	    break;
	}
    }

    if (i < objc) goto usage;

	return TCL_OK;

 usage:
    print(interp,"usage: w [-width #] [-compress 0|1]\n");
    return TCL_ERROR;
}

#define breakpoint_fail(msg) {error_msg = msg; goto break_fail;}

/*ARGSUSED*/
static
int
cmdBreak(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
	struct breakpoint *b;
	char *error_msg;

    static char* options [] = {
	"-glob",
	"-regexp",
	"if",
	"then",
	NULL
    };
    enum options {
	BREAK_GLOB,
	BREAK_RE,
	BREAK_IF,
	BREAK_THEN
    };
    int i;
    int index;


    /* No arguments, list breakpoints */
    if (objc == 1) {
		for (b = break_base;b;b=b->next) breakpoint_print(interp,b);
		return(TCL_OK);
	}

    /* Process breakpoint deletion (-, -x) */

    /* Copied from exp_prog.h */
#define streq(x,y)	(0 == strcmp((x),(y)))

    if (objc == 2) {
	int id;

	if (streq (Tcl_GetString (objv[1]),"-")) {
			while (break_base) {
				breakpoint_destroy(break_base);
			}
			breakpoint_max_id = 0;
			return(TCL_OK);
	}

	if ((Tcl_GetString (objv[1])[0] == '-') &&
	    (TCL_OK == Tcl_GetIntFromObj (interp, objv[1], &id))) {
	    id = -id;

			for (b = break_base;b;b=b->next) {
				if (b->id == id) {
					breakpoint_destroy(b);
					if (!break_base) breakpoint_max_id = 0;
					return(TCL_OK);
				}
			}
			Tcl_SetResult(interp,"no such breakpoint",TCL_STATIC);
			return(TCL_ERROR);
		}
	}

	b = breakpoint_new();

    /* Process switches */

    i = 1;
    if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
			    &index) == TCL_OK) {
	switch ((enum options) index) {
	case BREAK_GLOB:
	    i++;
	    if (i == objc) breakpoint_fail("no pattern?");
	    savestr(&b->pat,Tcl_GetString (objv[i]));
	    i++;
	    break;
	case BREAK_RE:
	    i++;
	    if (i == objc) breakpoint_fail("bad regular expression");
		    b->re = 1;
	    savestr(&b->pat,Tcl_GetString (objv[i]));
	    if (Tcl_GetRegExpFromObj(interp, b->pat, TCL_REG_ADVANCED) == NULL) {
			breakpoint_destroy(b);
			return TCL_ERROR;
		    }
	    i++;
	    break;
	case BREAK_IF:   break;
	case BREAK_THEN: break;
		}
		} else {
		/* look for [file:]line */
		char *colon;
		char *linep;	/* pointer to beginning of line number */
	char* ref = Tcl_GetString (objv[i]);
	colon = strchr(ref,':');
		if (colon) {
			*colon = '\0';
	    savestr(&b->file,ref);
			*colon = ':';
			linep = colon + 1;
		} else {
	    linep = ref;
			/* get file from current scope */
			/* savestr(&b->file, ?); */
		}

		if (TCL_OK == Tcl_GetInt(interp,linep,&b->line)) {
	    i++;
			print(interp,"setting breakpoints by line number is currently unimplemented - use patterns or expressions\n");
		} else {
			/* not an int? - unwind & assume it is an expression */

			if (b->file) Tcl_DecrRefCount(b->file);
		}

	}

    if (i < objc) {
		int do_if = FALSE;

	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
				&index) == TCL_OK) {
	    switch ((enum options) index) {
	    case BREAK_IF:
		i++;
		do_if = TRUE;
		/* Consider next word as expression */
		break;
	    case BREAK_THEN:
		/* No 'if expression' guard here, do nothing */
		break;
	    case BREAK_GLOB:
	    case BREAK_RE:
			do_if = TRUE;
		/* Consider current word as expression, without a preceding 'if' */
		break;
	    }
	} else {
	    /* Consider current word as expression, without a preceding 'if' */
			do_if = TRUE;
		}

		if (do_if) {
	    if (i == objc) breakpoint_fail("if what");
	    savestr(&b->expr,Tcl_GetString (objv[i]));
	    i++;
		}
	}

    if (i < objc) {
	/* Remainder is a command */
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
				&index) == TCL_OK) {
	    switch ((enum options) index) {
	    case BREAK_THEN:
		i++;
		break;
	    case BREAK_IF:
	    case BREAK_GLOB:
	    case BREAK_RE:
		break;
		}
		}

	if (i == objc) breakpoint_fail("then what?");

	savestr(&b->cmd,Tcl_GetString (objv[i]));
	}

    Tcl_SetObjResult (interp, Tcl_NewIntObj (b->id));
	return(TCL_OK);

 break_fail:
	breakpoint_destroy(b);
	Tcl_SetResult(interp,error_msg,TCL_STATIC);
	return(TCL_ERROR);
}

static char *help[] = {
"s [#]		step into procedure",
"n [#]		step over procedure",
"N [#]		step over procedures, commands, and arguments",
"c		continue",
"r		continue until return to caller",
"u [#]		move scope up level",
"d [#]		move scope down level",
"		go to absolute frame if # is prefaced by \"#\"",
"w		show stack (\"where\")",
"w -w [#]	show/set width",
"w -c [0|1]	show/set compress",
"b		show breakpoints",
"b [-r regexp-pattern] [if expr] [then command]",
"b [-g glob-pattern]   [if expr] [then command]",
"b [[file:]#]          [if expr] [then command]",
"		if pattern given, break if command resembles pattern",
"		if # given, break on line #",
"		if expr given, break if expr true",
"		if command given, execute command at breakpoint",
"b -#		delete breakpoint",
"b -		delete all breakpoints",
0};

/*ARGSUSED*/
static
int
cmdHelp(clientData, interp, objc, objv)
ClientData clientData;
Tcl_Interp *interp;
     int objc;
     Tcl_Obj *CONST objv[];		/* Argument objects. */
{
	char **hp;

	for (hp=help;*hp;hp++) {
		print(interp,"%s\n",*hp);
	}

	return(TCL_OK);
}

/* occasionally, we print things larger buf_max but not by much */
/* see print statements in PrintStack routines for examples */
#define PAD 80

/*VARARGS*/
static void
print TCL_VARARGS_DEF(Tcl_Interp *,arg1)
{
	Tcl_Interp *interp;
	char *fmt;
	va_list args;

	interp = TCL_VARARGS_START(Tcl_Interp *,arg1,args);
	fmt = va_arg(args,char *);
	if (!printproc) vprintf(fmt,args);
	else {
		static int buf_width_max = DEFAULT_WIDTH+PAD;
		static char buf_basic[DEFAULT_WIDTH+PAD+1];
		static char *buf = buf_basic;

		if (buf_width+PAD > buf_width_max) {
			if (buf && (buf != buf_basic)) ckfree(buf);
			buf = (char *)ckalloc(buf_width+PAD+1);
			buf_width_max = buf_width+PAD;
		}

		vsprintf(buf,fmt,args);
		(*printproc)(interp,buf,printdata);
	}
	va_end(args);
}

/*ARGSUSED*/
Dbg_InterStruct
Dbg_Interactor(interp,inter_proc,data)
Tcl_Interp *interp;
Dbg_InterProc *inter_proc;
ClientData data;
{
	Dbg_InterStruct tmp;

	tmp.func = interactor;
	tmp.data = interdata;
	interactor = (inter_proc?inter_proc:simple_interactor);
	interdata = data;
	return tmp;
}

/*ARGSUSED*/
Dbg_IgnoreFuncsProc *
Dbg_IgnoreFuncs(interp,proc)
Tcl_Interp *interp;
Dbg_IgnoreFuncsProc *proc;
{
	Dbg_IgnoreFuncsProc *tmp = ignoreproc;
	ignoreproc = (proc?proc:zero);
	return tmp;
}

/*ARGSUSED*/
Dbg_OutputStruct
Dbg_Output(interp,proc,data)
Tcl_Interp *interp;
Dbg_OutputProc *proc;
ClientData data;
{
	Dbg_OutputStruct tmp;

	tmp.func = printproc;
	tmp.data = printdata;
	printproc = proc;
	printdata = data;
	return tmp;
}

/*ARGSUSED*/
int
Dbg_Active(interp)
Tcl_Interp *interp;
{
	return debugger_active;
}

char **
Dbg_ArgcArgv(argc,argv,copy)
int argc;
char *argv[];
int copy;
{
	char **alloc;

	main_argc = argc;

	if (!copy) {
		main_argv = argv;
		alloc = 0;
	} else {
		main_argv = alloc = (char **)ckalloc((argc+1)*sizeof(char *));
		while (argc-- >= 0) {
			*main_argv++ = *argv++;
		}
		main_argv = alloc;
	}
	return alloc;
}

static struct cmd_list {
	char *cmdname;
    Tcl_ObjCmdProc *cmdproc;
	enum debug_cmd cmdtype;
} cmd_list[]  = {
		{"n", cmdNext,   next},
		{"s", cmdNext,   step},
		{"N", cmdNext,   Next},
		{"c", cmdSimple, cont},
		{"r", cmdSimple, ret},
		{"w", cmdWhere,  none},
		{"b", cmdBreak,  none},
		{"u", cmdDir,    up},
		{"d", cmdDir,    down},
		{"h", cmdHelp,   none},
		{0}
};

/* this may seem excessive, but this avoids the explicit test for non-zero */
/* in the caller, and chances are that that test will always be pointless */
/*ARGSUSED*/
static int
zero (Tcl_Interp *interp, char *string)
{
	return 0;
}

extern int expSetBlockModeProc _ANSI_ARGS_((int fd, int mode));

static int
simple_interactor(Tcl_Interp *interp, ClientData data)
{
	int rc;
	char *ccmd;		/* pointer to complete command */
	char line[BUFSIZ+1];	/* space for partial command */
	int newcmd = TRUE;
	Interp *iPtr = (Interp *)interp;

	Tcl_DString dstring;
	Tcl_DStringInit(&dstring);

	/* Force blocking if necessary */

	if (stdinmode == TCL_MODE_NONBLOCKING) {
	  expSetBlockModeProc(0, TCL_MODE_BLOCKING);
	}

	newcmd = TRUE;
	while (TRUE) {
		struct cmd_list *c;

		if (newcmd) {
#if TCL_MAJOR_VERSION < 8
			print(interp,"dbg%d.%d> ",iPtr->numLevels,iPtr->curEventNum+1);
#else
			/* unncessarily tricky coding - if nextid
			   isn't defined, maintain our own static
			   version */

			static int nextid = 0;
			CONST char *nextidstr = Tcl_GetVar2(interp,"tcl::history","nextid",0);
			if (nextidstr) {
				sscanf(nextidstr,"%d",&nextid);
			}
			print(interp,"dbg%d.%d> ",iPtr->numLevels,nextid++);
#endif
		} else {
			print(interp,"dbg+> ");
		}
		fflush(stdout);

		rc = read(0,line,BUFSIZ);
		if (0 >= rc) {
			if (!newcmd) line[0] = 0;
			else exit(0);
		} else line[rc] = '\0';

		ccmd = Tcl_DStringAppend(&dstring,line,rc);
		if (!Tcl_CommandComplete(ccmd)) {
			newcmd = FALSE;
			continue;	/* continue collecting command */
		}
		newcmd = TRUE;

		/* if user pressed return with no cmd, use previous one */
		if ((ccmd[0] == '\n' || ccmd[0] == '\r') && ccmd[1] == '\0') {

			/* this loop is guaranteed to exit through break */
			for (c = cmd_list;c->cmdname;c++) {
				if (c->cmdtype == last_action_cmd) break;
			}

			/* recreate textual version of command */
			Tcl_DStringAppend(&dstring,c->cmdname,-1);

			if (c->cmdtype == step ||
			    c->cmdtype == next ||
			    c->cmdtype == Next) {
				char num[10];

				sprintf(num," %d",last_step_count);
				Tcl_DStringAppend(&dstring,num,-1);
			}
		}

#if TCL_MAJOR_VERSION == 7 && TCL_MINOR_VERSION < 4
		rc = Tcl_RecordAndEval(interp,ccmd,0);
#else
		rc = Tcl_RecordAndEval(interp,ccmd,TCL_NO_EVAL);
		rc = Tcl_Eval(interp,ccmd);
#endif
		Tcl_DStringFree(&dstring);

		switch (rc) {
		case TCL_OK:
	    {
		char* res = Tcl_GetStringResult (interp);
		if (*res != 0)
		    print(interp,"%s\n",res);
	    }
			continue;
		case TCL_ERROR:
			print(interp,"%s\n",Tcl_GetVar(interp,"errorInfo",TCL_GLOBAL_ONLY));
			/* since user is typing by hand, we expect lots
			   of errors, and want to give another chance */
			continue;
		case TCL_BREAK:
		case TCL_CONTINUE:
#define finish(x)	{rc = x; goto done;}
			finish(rc);
		case TCL_RETURN:
			finish(TCL_OK);
		default:
			/* note that ccmd has trailing newline */
			print(interp,"error %d: %s\n",rc,ccmd);
			continue;
		}
	}
	/* cannot fall thru here, must jump to label */
 done:
	Tcl_DStringFree(&dstring);

	/* Restore old blocking mode */
	if (stdinmode == TCL_MODE_NONBLOCKING) {
	  expSetBlockModeProc(0, TCL_MODE_NONBLOCKING);
	}
	return(rc);
}

static char init_auto_path[] = "lappend auto_path $dbg_library";

static void
init_debugger(interp)
Tcl_Interp *interp;
{
	struct cmd_list *c;

	for (c = cmd_list;c->cmdname;c++) {
	Tcl_CreateObjCommand(interp,c->cmdname,c->cmdproc,
			(ClientData)&c->cmdtype,(Tcl_CmdDeleteProc *)0);
	}

    debug_handle = Tcl_CreateObjTrace(interp,10000,0,
				      debugger_trap,(ClientData)0, NULL);

	debugger_active = TRUE;
	Tcl_SetVar2(interp,Dbg_VarName,"active","1",0);
#ifdef DBG_SCRIPTDIR
	Tcl_SetVar(interp,"dbg_library",DBG_SCRIPTDIR,0);
#endif
	Tcl_Eval(interp,init_auto_path);

}

/* allows any other part of the application to jump to the debugger */
/*ARGSUSED*/
void
Dbg_On(interp,immediate)
Tcl_Interp *interp;
int immediate;		/* if true, stop immediately */
			/* should only be used in safe places */
			/* i.e., when Tcl_Eval can be called */
{
	if (!debugger_active) init_debugger(interp);

	/* Initialize debugger in single-step mode.  Note: if the
	  command reader is already active, it's too late which is why
	  we also statically initialize debug_cmd to step. */
	debug_cmd = step;
	step_count = 1;

#define LITERAL(s) Tcl_NewStringObj ((s), sizeof(s)-1)

	if (immediate) {
	Tcl_Obj* fake_cmd = LITERAL ( "--interrupted-- (command_unknown)");

	Tcl_IncrRefCount (fake_cmd);
	debugger_trap((ClientData)0,interp,-1,Tcl_GetString (fake_cmd),0,1,&fake_cmd);
/*		(*interactor)(interp);*/
	Tcl_DecrRefCount (fake_cmd);
	}
}

void
Dbg_Off(interp)
Tcl_Interp *interp;
{
	struct cmd_list *c;

	if (!debugger_active) return;

	for (c = cmd_list;c->cmdname;c++) {
		Tcl_DeleteCommand(interp,c->cmdname);
	}

	Tcl_DeleteTrace(interp,debug_handle);
	debugger_active = FALSE;
	Tcl_UnsetVar(interp,Dbg_VarName,TCL_GLOBAL_ONLY);

	/* initialize for next use */
	debug_cmd = step;
	step_count = 1;
}

/* allows any other part of the application to tell the debugger where the Tcl channel for stdin is. */
/*ARGSUSED*/
void
Dbg_StdinMode(mode)
     int mode;
{
  stdinmode = mode;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
