/* expect.c - expect commands

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include <sys/types.h>
#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <ctype.h>	/* for isspace */
#include <time.h>	/* for time(3) */

#include "expect_cf.h"

#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#include "tclInt.h"

#include "string.h"

#include "exp_rename.h"
#include "exp_prog.h"
#include "exp_command.h"
#include "exp_log.h"
#include "exp_event.h"
#include "exp_tty_in.h"
#include "exp_tstamp.h"	/* this should disappear when interact */
			/* loses ref's to it */
#ifdef TCL_DEBUGGER
#include "tcldbg.h"
#endif

#include "retoglob.c" /* RE 2 GLOB translator C variant */

/* initial length of strings that we can guarantee patterns can match */
int exp_default_match_max =	2000;
#define INIT_EXPECT_TIMEOUT_LIT	"10"	/* seconds */
#define INIT_EXPECT_TIMEOUT	10	/* seconds */
int exp_default_parity =	TRUE;
int exp_default_rm_nulls =	TRUE;
int exp_default_close_on_eof =  TRUE;

/* user variable names */
#define EXPECT_TIMEOUT		"timeout"
#define EXPECT_OUT		"expect_out"

extern int Exp_StringCaseMatch _ANSI_ARGS_((Tcl_UniChar *string, int strlen,
					    Tcl_UniChar *pattern,int plen,
					    int nocase,int *offset));

typedef struct ThreadSpecificData {
    int timeout;
} ThreadSpecificData;

static Tcl_ThreadDataKey dataKey;

/*
 * addr of these placeholders appear as clientData in ExpectCmd * when called
 * as expect_user and expect_tty.  It would be nicer * to invoked
 * expDevttyGet() but C doesn't allow this in an array initialization, sigh.
 */
static ExpState StdinoutPlaceholder;
static ExpState DevttyPlaceholder;

/* 1 ecase struct is reserved for each case in the expect command.  Note that
 * eof/timeout don't use any of theirs, but the algorithm is simpler this way.
 */

struct ecase {	/* case for expect command */
	struct exp_i	*i_list;
	Tcl_Obj *pat;	/* original pattern spec */
	Tcl_Obj *body;	/* ptr to body to be executed upon match */
    Tcl_Obj *gate;	/* For PAT_RE, a gate-keeper glob pattern
			 * which is quicker to match and reduces
			 * the number of calls into expensive RE
			 * matching. Optional.
			 */
#define PAT_EOF		1
#define PAT_TIMEOUT	2
#define PAT_DEFAULT	3
#define PAT_FULLBUFFER	4
#define PAT_GLOB	5 /* glob-style pattern list */
#define PAT_RE		6 /* regular expression */
#define PAT_EXACT	7 /* exact string */
#define PAT_NULL	8 /* ASCII 0 */
#define PAT_TYPES	9 /* used to size array of pattern type descriptions */
	int use;	/* PAT_XXX */
    int simple_start;	/* offset (chars) from start of buffer denoting where a
			 * glob or exact match begins */
	int transfer;	/* if false, leave matched chars in input stream */
	int indices;	/* if true, write indices */
	int iread;	/* if true, reread indirects */
	int timestamp;	/* if true, write timestamps */
#define CASE_UNKNOWN	0
#define CASE_NORM	1
#define CASE_LOWER	2
	int Case;	/* convert case before doing match? */
};

/* descriptions of the pattern types, used for debugging */
char *pattern_style[PAT_TYPES];

struct exp_cases_descriptor {
	int count;
	struct ecase **cases;
};

/* This describes an Expect command */
static
struct exp_cmd_descriptor {
	int cmdtype;			/* bg, before, after */
	int duration;			/* permanent or temporary */
	int timeout_specified_by_flag;	/* if -timeout flag used */
	int timeout;			/* timeout period if flag used */
	struct exp_cases_descriptor ecd;
	struct exp_i *i_list;
} exp_cmds[4];

/* note that exp_cmds[FG] is just a fake, the real contents is stored in some
 * dynamically-allocated variable.  We use exp_cmds[FG] mostly as a well-known
 * address and also as a convenience and so we allocate just a few of its
 * fields that we need.
 */

static void
exp_cmd_init(
    struct exp_cmd_descriptor *cmd,
    int cmdtype,
    int duration)
{
	cmd->duration = duration;
	cmd->cmdtype = cmdtype;
	cmd->ecd.cases = 0;
	cmd->ecd.count = 0;
	cmd->i_list = 0;
}

static int i_read_errno;/* place to save errno, if i_read() == -1, so it
			   doesn't get overwritten before we get to read it */

#ifdef SIMPLE_EVENT
static int alarm_fired;	/* if alarm occurs */
#endif

void exp_background_channelhandlers_run_all();

/* exp_indirect_updateX is called by Tcl when an indirect variable is set */
static char *exp_indirect_update1( /* 1-part Tcl variable names */
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    struct exp_i *exp_i);
static char *exp_indirect_update2( /* 2-part Tcl variable names */
    ClientData clientData,
    Tcl_Interp *interp,	/* Interpreter containing variable. */
    char *name1,	/* Name of variable. */
    char *name2,	/* Second part of variable name. */
    int flags);		/* Information about what happened. */

#ifdef SIMPLE_EVENT
/*ARGSUSED*/
static RETSIGTYPE
sigalarm_handler(int n) /* unused, for compatibility with STDC */
{
	alarm_fired = TRUE;
}
#endif /*SIMPLE_EVENT*/

/* free up everything in ecase */
static void
free_ecase(
    Tcl_Interp *interp,
    struct ecase *ec,
    int free_ilist)		/* if we should free ilist */
{
    if (ec->i_list->duration == EXP_PERMANENT) {
	if (ec->pat)  { Tcl_DecrRefCount(ec->pat); }
	if (ec->gate) { Tcl_DecrRefCount(ec->gate); }
	if (ec->body) { Tcl_DecrRefCount(ec->body); }
    }

    if (free_ilist) {
	ec->i_list->ecount--;
	if (ec->i_list->ecount == 0) {
	    exp_free_i(interp,ec->i_list,exp_indirect_update2);
    }
    }

    ckfree((char *)ec);	/* NEW */
}

/* free up any argv structures in the ecases */
static void
free_ecases(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *eg,
    int free_ilist)		/* if true, free ilists */
{
	int i;

	if (!eg->ecd.cases) return;

	for (i=0;i<eg->ecd.count;i++) {
		free_ecase(interp,eg->ecd.cases[i],free_ilist);
	}
	ckfree((char *)eg->ecd.cases);

	eg->ecd.cases = 0;
	eg->ecd.count = 0;
}


#if 0
/* no standard defn for this, and some systems don't even have it, so avoid */
/* the whole quagmire by calling it something else */
static char *exp_strdup(char *s)
{
	char *news = ckalloc(strlen(s) + 1);
	strcpy(news,s);
	return(news);
}
#endif

/* return TRUE if string appears to be a set of arguments
   The intent of this test is to support the ability of commands to have
   all their args braced as one.  This conflicts with the possibility of
   actually intending to have a single argument.
   The bad case is in expect which can have a single argument with embedded
   \n's although it's rare.  Examples that this code should handle:
   \n		FALSE (pattern)
   \n\n		FALSE
   \n  \n \n	FALSE
   foo		FALSE
   foo\n	FALSE
   \nfoo\n	TRUE  (set of args)
   \nfoo\nbar	TRUE

   Current test is very cheap and almost always right :-)
*/
int 
exp_one_arg_braced(Tcl_Obj *objPtr)	/* INTL */
{
	int seen_nl = FALSE;
	char *p = Tcl_GetString(objPtr);

	for (;*p;p++) {
		if (*p == '\n') {
			seen_nl = TRUE;
			continue;
		}

		if (!isspace(*p)) { /* INTL: ISO space */
			return(seen_nl);
		}
	}
	return FALSE;
}

/* called to execute a command of only one argument - a hack to commands */
/* to be called with all args surrounded by an outer set of braces */
/* Returns a list object containing the new set of arguments */
/* Caller then has to either reinvoke itself, or better, simply replace
 * its current argumnts */
/*ARGSUSED*/
Tcl_Obj*
exp_eval_with_one_arg(
    ClientData clientData,
    Tcl_Interp *interp,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    Tcl_Obj* res = Tcl_NewListObj (1,objv);

#define NUM_STATIC_OBJS 20
    Tcl_Token *tokenPtr;
    CONST char *p;
    CONST char *next;
    int rc;
    int bytesLeft, numWords;
    Tcl_Parse parse;

    /*
     * Prepend the command name and the -nobrace switch so we can
     * reinvoke without recursing.
     */

    Tcl_ListObjAppendElement (interp, res, Tcl_NewStringObj("-nobrace", -1));

    p = Tcl_GetStringFromObj(objv[1], &bytesLeft);

    /*
     * Treat the pattern/action block like a series of Tcl commands.
     * For each command, parse the command words, perform substititions
     * on each word, and add the words to an array of values.  We don't
     * actually evaluate the individual commands, just the substitutions.
     */

    do {
	if (Tcl_ParseCommand(interp, p, bytesLeft, 0, &parse)
	        != TCL_OK) {
	    rc = TCL_ERROR;
	    goto done;
	}
	numWords = parse.numWords;
 	if (numWords > 0) {
	    /*
	     * Generate an array of objects for the words of the command.
	     */
    
	    /*
	     * For each word, perform substitutions then store the
	     * result in the objs array.
	     */
	    
	    for (tokenPtr = parse.tokenPtr; numWords > 0;
		 numWords--, tokenPtr += (tokenPtr->numComponents + 1)) {
		/* FUTURE: Save token information, do substitution later */

		Tcl_Obj* w = Tcl_EvalTokens(interp, tokenPtr+1,
			tokenPtr->numComponents);
		/* w has refCount 1 here, if not NULL */
		if (w == NULL) {
		    Tcl_DecrRefCount (res);
		    res = NULL;
		    goto done;

		}
		Tcl_ListObjAppendElement (interp, res, w);
		Tcl_DecrRefCount (w); /* Local reference goes away */
	    }
	}

	/*
	 * Advance to the next command in the script.
	 */
	next = parse.commandStart + parse.commandSize;
	bytesLeft -= next - p;
	p = next;
	Tcl_FreeParse(&parse);
    } while (bytesLeft > 0);

 done:
    return res;
}

static void
ecase_clear(struct ecase *ec)
{
	ec->i_list = 0;
	ec->pat = 0;
	ec->body = 0;
	ec->transfer = TRUE;
	ec->simple_start = 0;
	ec->indices = FALSE;
	ec->iread = FALSE;
	ec->timestamp = FALSE;
	ec->Case = CASE_NORM;
	ec->use = PAT_GLOB;
    ec->gate = NULL;
}

static struct ecase *
ecase_new(void)
{
	struct ecase *ec = (struct ecase *)ckalloc(sizeof(struct ecase));

	ecase_clear(ec);
	return ec;
}

/*

parse_expect_args parses the arguments to expect or its variants. 
It normally returns TCL_OK, and returns TCL_ERROR for failure.
(It can't return i_list directly because there is no way to differentiate
between clearing, say, expect_before and signalling an error.)

eg (expect_global) is initialized to reflect the arguments parsed
eg->ecd.cases is an array of ecases
eg->ecd.count is the # of ecases
eg->i_list is a linked list of exp_i's which represent the -i info

Each exp_i is chained to the next so that they can be easily free'd if
necessary.  Each exp_i has a reference count.  If the -i is not used
(e.g., has no following patterns), the ref count will be 0.

Each ecase points to an exp_i.  Several ecases may point to the same exp_i.
Variables named by indirect exp_i's are read for the direct values.

If called from a foreground expect and no patterns or -i are given, a
default exp_i is forced so that the command "expect" works right.

The exp_i chain can be broken by the caller if desired.

*/

static int
parse_expect_args(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *eg,
    ExpState *default_esPtr,	/* suggested ExpState if called as expect_user or _tty */
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int i;
    char *string;
    struct ecase ec;	/* temporary to collect args */

    eg->timeout_specified_by_flag = FALSE;

    ecase_clear(&ec);

    /* Allocate an array to store the ecases.  Force array even if 0 */
    /* cases.  This will often be too large (i.e., if there are flags) */
    /* but won't affect anything. */

    eg->ecd.cases = (struct ecase **)ckalloc(sizeof(struct ecase *) * (1+(objc/2)));

    eg->ecd.count = 0;

    for (i = 1;i<objc;i++) {
	int index;
	string = Tcl_GetString(objv[i]);
	if (string[0] == '-') {
	    static char *flags[] = {
		"-glob", "-regexp", "-exact", "-notransfer", "-nocase",
		"-i", "-indices", "-iread", "-timestamp", "-timeout",
		"-nobrace", "--", (char *)0
	    };
	    enum flags {
		EXP_ARG_GLOB, EXP_ARG_REGEXP, EXP_ARG_EXACT,
		EXP_ARG_NOTRANSFER, EXP_ARG_NOCASE, EXP_ARG_SPAWN_ID,
		EXP_ARG_INDICES, EXP_ARG_IREAD, EXP_ARG_TIMESTAMP,
		EXP_ARG_DASH_TIMEOUT, EXP_ARG_NOBRACE, EXP_ARG_DASH
	    };

	    /*
	     * Allow abbreviations of switches and report an error if we
	     * get an invalid switch.
	     */

	    if (Tcl_GetIndexFromObj(interp, objv[i], flags, "flag", 0,
		    &index) != TCL_OK) {
		return TCL_ERROR;
	    }
	    switch ((enum flags) index) {
	    case EXP_ARG_GLOB:
	    case EXP_ARG_DASH:
		i++;
		/* assignment here is not actually necessary */
		/* since cases are initialized this way above */
		/* ec.use = PAT_GLOB; */
		if (i >= objc) {
		    Tcl_WrongNumArgs(interp, 1, objv,"-glob pattern");
		    return TCL_ERROR;
		}
		goto pattern;
	    case EXP_ARG_REGEXP:
		i++;
		if (i >= objc) {
		    Tcl_WrongNumArgs(interp, 1, objv,"-regexp regexp");
		    return TCL_ERROR;
		}
		ec.use = PAT_RE;

		/*
		 * Try compiling the expression so we can report
		 * any errors now rather then when we first try to
		 * use it.
		 */

		if (!(Tcl_GetRegExpFromObj(interp, objv[i],
					   TCL_REG_ADVANCED))) {
		    goto error;
		}

		/* Derive a gate keeper glob pattern which reduces the amount
		 * of RE matching.
		 */

		{
		    Tcl_Obj* g;
		    Tcl_UniChar* str;
		    int strlen;

		    str = Tcl_GetUnicodeFromObj (objv[i], &strlen);
		    g = exp_retoglob (str, strlen);

		    if (g) {
			ec.gate = g;

			expDiagLog("Gate keeper glob pattern for '%s'",Tcl_GetString(objv[i]));
			expDiagLog(" is '%s'. Activating booster.\n",Tcl_GetString(g));
		    } else {
			/* Ignore errors, fall back to regular RE matching */
			expDiagLog("Gate keeper glob pattern for '%s'",Tcl_GetString(objv[i]));
			expDiagLog(" is '%s'. Not usable, disabling the",Tcl_GetString(Tcl_GetObjResult (interp)));
			expDiagLog(" performance booster.\n");
		    }
		}

		goto pattern;
	    case EXP_ARG_EXACT:
		i++;
		if (i >= objc) {
		    Tcl_WrongNumArgs(interp, 1, objv, "-exact string");
		    return TCL_ERROR;
		}
		ec.use = PAT_EXACT;
		goto pattern;
	    case EXP_ARG_NOTRANSFER:
		ec.transfer = 0;
		break;
	    case EXP_ARG_NOCASE:
		ec.Case = CASE_LOWER;
		break;
	    case EXP_ARG_SPAWN_ID:
		i++;
		if (i>=objc) {
		    Tcl_WrongNumArgs(interp, 1, objv, "-i spawn_id");
		    goto error;
		}
		ec.i_list = exp_new_i_complex(interp,
				      Tcl_GetString(objv[i]),
				      eg->duration, exp_indirect_update2);
		if (!ec.i_list) goto error;
		ec.i_list->cmdtype = eg->cmdtype;

		/* link new i_list to head of list */
		ec.i_list->next = eg->i_list;
		eg->i_list = ec.i_list;
		break;
	    case EXP_ARG_INDICES:
		ec.indices = TRUE;
		break;
	    case EXP_ARG_IREAD:
		ec.iread = TRUE;
		break;
	    case EXP_ARG_TIMESTAMP:
		ec.timestamp = TRUE;
		break;
	    case EXP_ARG_DASH_TIMEOUT:
		i++;
		if (i>=objc) {
		    Tcl_WrongNumArgs(interp, 1, objv, "-timeout seconds");
		    goto error;
		}
		if (Tcl_GetIntFromObj(interp, objv[i],
				      &eg->timeout) != TCL_OK) {
		    goto error;
		}
		eg->timeout_specified_by_flag = TRUE;
		break;
	    case EXP_ARG_NOBRACE:
		/* nobrace does nothing but take up space */
		/* on the command line which prevents */
		/* us from re-expanding any command lines */
		/* of one argument that looks like it should */
		/* be expanded to multiple arguments. */
		break;
	    }
	    /*
	     * Keep processing arguments, we aren't ready for the
	     * pattern yet.
	     */
	    continue;
	} else {
	    /*
	     * We have a pattern or keyword.
	     */

	    static char *keywords[] = {
		"timeout", "eof", "full_buffer", "default", "null",
		(char *)NULL
	    };
	    enum keywords {
		EXP_ARG_TIMEOUT, EXP_ARG_EOF, EXP_ARG_FULL_BUFFER,
		EXP_ARG_DEFAULT, EXP_ARG_NULL
	    };

	    /*
	     * Match keywords exactly, otherwise they are patterns.
	     */

	    if (Tcl_GetIndexFromObj(interp, objv[i], keywords, "keyword",
		    1 /* exact */, &index) != TCL_OK) {
		Tcl_ResetResult(interp);
		goto pattern;
	    }
	    switch ((enum keywords) index) {
	    case EXP_ARG_TIMEOUT:
		ec.use = PAT_TIMEOUT;
		break;
	    case EXP_ARG_EOF:
		ec.use = PAT_EOF;
		break;
	    case EXP_ARG_FULL_BUFFER:
		ec.use = PAT_FULLBUFFER;
		break;
	    case EXP_ARG_DEFAULT:
		ec.use = PAT_DEFAULT;
		break;
	    case EXP_ARG_NULL:
		ec.use = PAT_NULL;
		break;
	    }
pattern:
	    /* if no -i, use previous one */
	    if (!ec.i_list) {
		/* if no -i flag has occurred yet, use default */
		if (!eg->i_list) {
		    if (default_esPtr != EXP_SPAWN_ID_BAD) {
			eg->i_list = exp_new_i_simple(default_esPtr,eg->duration);
		    } else {
		        default_esPtr = expStateCurrent(interp,0,0,1);
		        if (!default_esPtr) goto error;
		        eg->i_list = exp_new_i_simple(default_esPtr,eg->duration);
		    }
		}
		ec.i_list = eg->i_list;
	    }
	    ec.i_list->ecount++;

	    /* save original pattern spec */
	    /* keywords such as "-timeout" are saved as patterns here */
	    /* useful for debugging but not otherwise used */

	    ec.pat = objv[i];
	    if (eg->duration == EXP_PERMANENT) {
		Tcl_IncrRefCount(ec.pat);
		if (ec.gate) {
		    Tcl_IncrRefCount(ec.gate);
		}
	    }

	    i++;
	    if (i < objc) {
		ec.body = objv[i];
		if (eg->duration == EXP_PERMANENT) Tcl_IncrRefCount(ec.body);
	    } else {
		ec.body = NULL;
	    }

	    *(eg->ecd.cases[eg->ecd.count] = ecase_new()) = ec;

		/* clear out for next set */
	    ecase_clear(&ec);

	    eg->ecd.count++;
	}
    }

    /* if no patterns at all have appeared force the current */
    /* spawn id to be added to list anyway */

    if (eg->i_list == 0) {
	if (default_esPtr != EXP_SPAWN_ID_BAD) {
	    eg->i_list = exp_new_i_simple(default_esPtr,eg->duration);
	} else {
	    default_esPtr = expStateCurrent(interp,0,0,1);
	    if (!default_esPtr) goto error;
	    eg->i_list = exp_new_i_simple(default_esPtr,eg->duration);
	}
    }

    return(TCL_OK);

 error:
    /* very hard to free case_master_list here if it hasn't already */
    /* been attached to a case, ugh */

    /* note that i_list must be avail to free ecases! */
    free_ecases(interp,eg,0);

    if (eg->i_list)
	exp_free_i(interp,eg->i_list,exp_indirect_update2);
    return(TCL_ERROR);
}

#define EXP_IS_DEFAULT(x)	((x) == EXP_TIMEOUT || (x) == EXP_EOF)

static char yes[] = "yes\r\n";
static char no[] = "no\r\n";

/* this describes status of a successful match */
struct eval_out {
    struct ecase *e;		/* ecase that matched */
    ExpState *esPtr;		/* ExpState that matched */
    Tcl_UniChar* matchbuf;   /* Buffer that matched, */
    int          matchlen;   /* and #chars that matched, or
			      * #chars in buffer at EOF */
    /* This points into the esPtr->input.buffer ! */
};




/*
 *----------------------------------------------------------------------
 *
 * string_case_first --
 *
 *	Find the first instance of a pattern in a string.
 *
 * Results:
 *	Returns the pointer to the first instance of the pattern
 *	in the given string, or NULL if no match was found.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Tcl_UniChar *
string_case_first(	/* INTL */
    register Tcl_UniChar *string,	/* String (unicode). */
    int length,                         /* length of above string */
    register char *pattern)	/* Pattern, which may contain
				 * special characters (utf8). */
{
    Tcl_UniChar *s;
    char *p;
    int offset;
    register int consumed = 0;
    Tcl_UniChar ch1, ch2;
    Tcl_UniChar *bufend = string + length;

    while ((*string != 0) && (string < bufend)) {
	s = string;
	p = pattern;
        while ((*s) && (s < bufend)) {
	    ch1 = *s++;
            consumed++;
	    offset = TclUtfToUniChar(p, &ch2);
	    if (Tcl_UniCharToLower(ch1) != Tcl_UniCharToLower(ch2)) {
		break;
	    }
	    p += offset;
	}
	if (*p == '\0') {
	    return string;
	}
	string++;
        consumed++;
    }
    return NULL;
}

Tcl_UniChar *
string_first(	/* INTL */
    register Tcl_UniChar *string,       /* String (unicode). */
    int length,                         /* length of above string */
    register char *pattern)             /* Pattern, which may contain
                                         * special characters (utf8). */
{
    Tcl_UniChar *s;
    char *p;
    int offset;
    register int consumed = 0;
    Tcl_UniChar ch1, ch2;
    Tcl_UniChar *bufend = string + length;
    
    while ((*string != 0) && (string < bufend)) {
	s = string;
	p = pattern;
        while ((*s) && (s < bufend)) {
	    ch1 = *s++;
            consumed++;
	    offset = TclUtfToUniChar(p, &ch2);
	    if (ch1 != ch2) {
		break;
	    }
	    p += offset;
	}
        if (*p == '\0') {
	    return string;
	}
        string++;
        consumed++;
    }
    return NULL;
}

Tcl_UniChar *
string_first_char(	/* INTL */
    register Tcl_UniChar *string,	/* String. */
    register Tcl_UniChar pattern)
{
    /* unicode based Tcl_UtfFindFirst */

    Tcl_UniChar find;
    
    while (1) {
        find = *string;
	if (find == pattern) {
	    return string;
	}
	if (*string == '\0') {
	    return NULL;
	}
	string ++;
    }
    return NULL;
}

/* like eval_cases, but handles only a single cases that needs a real */
/* string match */
/* returns EXP_X where X is MATCH, NOMATCH, FULLBUFFER, TCLERRROR */
static int
eval_case_string(
    Tcl_Interp *interp,
    struct ecase *e,
    ExpState *esPtr,
    struct eval_out *o,		/* 'output' - i.e., final case of interest */
/* next two args are for debugging, when they change, reprint buffer */
    ExpState **last_esPtr,
    int *last_case,
    char *suffix)
{
    Tcl_RegExp re;
    Tcl_RegExpInfo info;
    Tcl_Obj* buf;
    Tcl_UniChar *str;
    int numchars, flags, dummy, globmatch;
    int result;

    str      = esPtr->input.buffer;
    numchars = esPtr->input.use;

    /* if ExpState or case changed, redisplay debug-buffer */
    if ((esPtr != *last_esPtr) || e->Case != *last_case) {
	expDiagLog("\r\nexpect%s: does \"",suffix);
	expDiagLogU(expPrintifyUni(str,numchars));
	expDiagLog("\" (spawn_id %s) match %s ",esPtr->name,pattern_style[e->use]);
	*last_esPtr = esPtr;
	*last_case = e->Case;
    }

    if (e->use == PAT_RE) {
	expDiagLog("\"");
	expDiagLogU(expPrintify(Tcl_GetString(e->pat)));
	expDiagLog("\"? ");

	if (e->gate) {
	    int plen;
	    Tcl_UniChar* pat = Tcl_GetUnicodeFromObj(e->gate,&plen);

	    expDiagLog("Gate \"");
	    expDiagLogU(expPrintify(Tcl_GetString(e->gate)));
	    expDiagLog("\"? gate=");

	    globmatch = Exp_StringCaseMatch(str, numchars, pat, plen,
					    (e->Case == CASE_NORM) ? 0 : 1,
					    &dummy);
	} else {
	    expDiagLog("(No Gate, RE only) gate=");

	    /* No gate => RE matching always */
	    globmatch = 1;
	}
	if (globmatch < 0) {
	    expDiagLogU(no);
	    /* i.e. no match */
	} else {
	    expDiagLog("yes re=");

	if (e->Case == CASE_NORM) {
	    flags = TCL_REG_ADVANCED;
	} else {
	    flags = TCL_REG_ADVANCED | TCL_REG_NOCASE;
	}
		    
	re = Tcl_GetRegExpFromObj(interp, e->pat, flags);

	    /* ZZZ: Future optimization: Avoid copying */
	    buf = Tcl_NewUnicodeObj (str, numchars);
	    Tcl_IncrRefCount (buf);
	    result = Tcl_RegExpExecObj(interp, re, buf, 0 /* offset */,
		-1 /* nmatches */, 0 /* eflags */);
	    Tcl_DecrRefCount (buf);
	if (result > 0) {
	    o->e = e;

	    /*
	     * Retrieve the byte offset of the end of the
	     * matched string.  
	     */

	    Tcl_RegExpGetInfo(re, &info);
		o->matchlen = info.matches[0].end;
		o->matchbuf = str;
	    o->esPtr = esPtr;
	    expDiagLogU(yes);
	    return(EXP_MATCH);
	} else if (result == 0) {
	    expDiagLogU(no);
	} else { /* result < 0 */
	    return(EXP_TCLERROR);
	}
	}
    } else if (e->use == PAT_GLOB) {
	int match; /* # of chars that matched */

	expDiagLog("\"");
	expDiagLogU(expPrintify(Tcl_GetString(e->pat)));
	expDiagLog("\"? ");
	if (str) {
	    int plen;
	    Tcl_UniChar* pat = Tcl_GetUnicodeFromObj(e->pat,&plen);

	    match = Exp_StringCaseMatch(str,numchars, pat, plen,
		    (e->Case == CASE_NORM) ? 0 : 1,
		    &e->simple_start);
	    if (match != -1) {
		o->e = e;
		o->matchlen = match;
		o->matchbuf = str;
		o->esPtr = esPtr;
		expDiagLogU(yes);
		return(EXP_MATCH);
	    }
	}
	expDiagLogU(no);
    } else if (e->use == PAT_EXACT) {
	int patLength;
	char *pat = Tcl_GetStringFromObj(e->pat, &patLength);
	Tcl_UniChar *p;

	if (e->Case == CASE_NORM) {
	    p = string_first(str, numchars, pat); /* NEW function in this file, see above */
	} else {
	    p = string_case_first(str, numchars, pat);
	}	    

	expDiagLog("\"");
	expDiagLogU(expPrintify(Tcl_GetString(e->pat)));
	expDiagLog("\"? ");
	if (p) {
	    /* Bug 3095935. Go from #bytes to #chars */
	    patLength = Tcl_NumUtfChars (pat, patLength);

	    e->simple_start = p - str;
	    o->e = e;
	    o->matchlen = patLength;
	    o->matchbuf = str;
	    o->esPtr = esPtr;
	    expDiagLogU(yes);
	    return(EXP_MATCH);
	} else expDiagLogU(no);
    } else if (e->use == PAT_NULL) {
	CONST Tcl_UniChar *p;
	expDiagLogU("null? ");
	p = string_first_char (str, 0); /* NEW function in this file, see above */

	if (p) {
	    o->e = e;
	    o->matchlen = p-str; /* #chars */
	    o->matchbuf = str;
	    o->esPtr = esPtr;
	    expDiagLogU(yes);
	    return EXP_MATCH;
	}
	expDiagLogU(no);
    } else if (e->use == PAT_FULLBUFFER) {
        expDiagLogU(Tcl_GetString(e->pat));
	expDiagLogU("? ");
	/* this must be the same test as in expIRead */
	/* We drop one third when are at least 2/3 full */
	/* condition is (size >= max*2/3) <=> (size*3 >= max*2) */
	if (((expSizeGet(esPtr)*3) >= (esPtr->input.max*2)) && (numchars > 0)) {
	    o->e = e;
	    o->matchlen = numchars/3;
	    o->matchbuf = str;
	    o->esPtr = esPtr;
	    expDiagLogU(yes);
	    return(EXP_FULLBUFFER);
	} else {
	    expDiagLogU(no);
	}
    }
    return(EXP_NOMATCH);
}

/* sets o.e if successfully finds a matching pattern, eof, timeout or deflt */
/* returns original status arg or EXP_TCLERROR */
static int
eval_cases(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *eg,
    ExpState *esPtr,
    struct eval_out *o,		/* 'output' - i.e., final case of interest */
/* next two args are for debugging, when they change, reprint buffer */
    ExpState **last_esPtr,
    int *last_case,
    int status,
    ExpState *(esPtrs[]),
    int mcount,
    char *suffix)
{
    int i;
    ExpState *em;   /* ExpState of ecase */
    struct ecase *e;

    if (o->e || status == EXP_TCLERROR || eg->ecd.count == 0) return(status);

    if (status == EXP_TIMEOUT) {
	for (i=0;i<eg->ecd.count;i++) {
	    e = eg->ecd.cases[i];
	    if (e->use == PAT_TIMEOUT || e->use == PAT_DEFAULT) {
		o->e = e;
		break;
	    }
	}
	return(status);
    } else if (status == EXP_EOF) {
	for (i=0;i<eg->ecd.count;i++) {
	    e = eg->ecd.cases[i];
	    if (e->use == PAT_EOF || e->use == PAT_DEFAULT) {
		struct exp_state_list *slPtr;

		for (slPtr=e->i_list->state_list; slPtr ;slPtr=slPtr->next) {
		    em = slPtr->esPtr;
		    if (expStateAnyIs(em) || em == esPtr) {
			o->e = e;
			return(status);
		    }
		}
	    }
	}
	return(status);
    }

    /* the top loops are split from the bottom loop only because I can't */
    /* split'em further. */

    /* The bufferful condition does not prevent a pattern match from */
    /* occurring and vice versa, so it is scanned with patterns */
    for (i=0;i<eg->ecd.count;i++) {
	struct exp_state_list *slPtr;
	int j;

	e = eg->ecd.cases[i];
	if (e->use == PAT_TIMEOUT ||
		e->use == PAT_DEFAULT ||
		e->use == PAT_EOF) continue;

	for (slPtr = e->i_list->state_list; slPtr; slPtr = slPtr->next) {
	    em = slPtr->esPtr;
	    /* if em == EXP_SPAWN_ID_ANY, then user is explicitly asking */
	    /* every case to be checked against every ExpState */
	    if (expStateAnyIs(em)) {
		/* test against each spawn_id */
		for (j=0;j<mcount;j++) {
		    status = eval_case_string(interp,e,esPtrs[j],o,
			    last_esPtr,last_case,suffix);
		    if (status != EXP_NOMATCH) return(status);
		}
	    } else {
		/* reject things immediately from wrong spawn_id */
		if (em != esPtr) continue;

		status = eval_case_string(interp,e,esPtr,o,last_esPtr,last_case,suffix);
		if (status != EXP_NOMATCH) return(status);
	    }
	}
    }
    return(EXP_NOMATCH);
}

static void
ecases_remove_by_expi(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    struct exp_i *exp_i)
{
	int i;

	/* delete every ecase dependent on it */
	for (i=0;i<ecmd->ecd.count;) {
		struct ecase *e = ecmd->ecd.cases[i];
		if (e->i_list == exp_i) {
			free_ecase(interp,e,0);

			/* shift remaining elements down */
			/* but only if there are any left */
			/* Use memmove to handle the overlap */
			/* memcpy breaks */
			if (i+1 != ecmd->ecd.count) {
				memmove(&ecmd->ecd.cases[i],
				       &ecmd->ecd.cases[i+1],
					((ecmd->ecd.count - i) - 1) * 
					sizeof(struct exp_cmd_descriptor *));
			}
			ecmd->ecd.count--;
			if (0 == ecmd->ecd.count) {
				ckfree((char *)ecmd->ecd.cases);
				ecmd->ecd.cases = 0;
			}
		} else {
			i++;
		}
	}
}

/* remove exp_i from list */
static void
exp_i_remove(
    Tcl_Interp *interp,
    struct exp_i **ei,	/* list to remove from */
    struct exp_i *exp_i)	/* element to remove */
{
	/* since it's in middle of list, free exp_i by hand */
	for (;*ei; ei = &(*ei)->next) {
		if (*ei == exp_i) {
			*ei = exp_i->next;
			exp_i->next = 0;
			exp_free_i(interp,exp_i,exp_indirect_update2);
			break;
		}
	}
}

/* remove exp_i from list and remove any dependent ecases */
static void
exp_i_remove_with_ecases(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    struct exp_i *exp_i)
{
	ecases_remove_by_expi(interp,ecmd,exp_i);
	exp_i_remove(interp,&ecmd->i_list,exp_i);
}

/* remove ecases tied to a single direct spawn id */
static void
ecmd_remove_state(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    ExpState *esPtr,
    int direct)
{
    struct exp_i *exp_i, *next;
    struct exp_state_list **slPtr;

    for (exp_i=ecmd->i_list;exp_i;exp_i=next) {
	next = exp_i->next;

	if (!(direct & exp_i->direct)) continue;

	for (slPtr = &exp_i->state_list;*slPtr;) {
	    if (esPtr == ((*slPtr)->esPtr)) {
		struct exp_state_list *tmp = *slPtr;
		*slPtr = (*slPtr)->next;
		exp_free_state_single(tmp);

		/* if last bg ecase, disarm spawn id */
		if ((ecmd->cmdtype == EXP_CMD_BG) && (!expStateAnyIs(esPtr))) {
		    esPtr->bg_ecount--;
		    if (esPtr->bg_ecount == 0) {
			exp_disarm_background_channelhandler(esPtr);
			esPtr->bg_interp = 0;
		    }
		}
		
		continue;
	    }
	    slPtr = &(*slPtr)->next;
	}

	/* if left with no ExpStates (and is direct), get rid of it */
	/* and any dependent ecases */
	if (exp_i->direct == EXP_DIRECT && !exp_i->state_list) {
	    exp_i_remove_with_ecases(interp,ecmd,exp_i);
	}
    }
}

/* this is called from exp_close to clean up the ExpState */
void
exp_ecmd_remove_state_direct_and_indirect(
    Tcl_Interp *interp,
    ExpState *esPtr)
{
	ecmd_remove_state(interp,&exp_cmds[EXP_CMD_BEFORE],esPtr,EXP_DIRECT|EXP_INDIRECT);
	ecmd_remove_state(interp,&exp_cmds[EXP_CMD_AFTER],esPtr,EXP_DIRECT|EXP_INDIRECT);
	ecmd_remove_state(interp,&exp_cmds[EXP_CMD_BG],esPtr,EXP_DIRECT|EXP_INDIRECT);

	/* force it - explanation in exp_tk.c where this func is defined */
	exp_disarm_background_channelhandler_force(esPtr);
}

/* arm a list of background ExpState's */
static void
state_list_arm(
    Tcl_Interp *interp,
    struct exp_state_list *slPtr)
{
    /* for each spawn id in list, arm if necessary */
    for (;slPtr;slPtr=slPtr->next) {
	ExpState *esPtr = slPtr->esPtr;    
	if (expStateAnyIs(esPtr)) continue;

	if (esPtr->bg_ecount == 0) {
	    exp_arm_background_channelhandler(esPtr);
	    esPtr->bg_interp = interp;
	}
	esPtr->bg_ecount++;
    }
}

/* return TRUE if this ecase is used by this fd */
static int
exp_i_uses_state(
    struct exp_i *exp_i,
    ExpState *esPtr)
{
	struct exp_state_list *fdp;

	for (fdp = exp_i->state_list;fdp;fdp=fdp->next) {
		if (fdp->esPtr == esPtr) return 1;
	}
	return 0;
}

static void
ecase_append(
    Tcl_Interp *interp,
    struct ecase *ec)
{
	if (!ec->transfer) Tcl_AppendElement(interp,"-notransfer");
	if (ec->indices) Tcl_AppendElement(interp,"-indices");
	if (!ec->Case) Tcl_AppendElement(interp,"-nocase");

	if (ec->use == PAT_RE) Tcl_AppendElement(interp,"-re");
	else if (ec->use == PAT_GLOB) Tcl_AppendElement(interp,"-gl");
	else if (ec->use == PAT_EXACT) Tcl_AppendElement(interp,"-ex");
	Tcl_AppendElement(interp,Tcl_GetString(ec->pat));
	Tcl_AppendElement(interp,ec->body?Tcl_GetString(ec->body):"");
}

/* append all ecases that match this exp_i */
static void
ecase_by_exp_i_append(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    struct exp_i *exp_i)
{
	int i;
	for (i=0;i<ecmd->ecd.count;i++) {
		if (ecmd->ecd.cases[i]->i_list == exp_i) {
			ecase_append(interp,ecmd->ecd.cases[i]);
		}
	}
}

static void
exp_i_append(
    Tcl_Interp *interp,
    struct exp_i *exp_i)
{
	Tcl_AppendElement(interp,"-i");
	if (exp_i->direct == EXP_INDIRECT) {
		Tcl_AppendElement(interp,exp_i->variable);
	} else {
		struct exp_state_list *fdp;

		/* if more than one element, add braces */
	if (exp_i->state_list->next) {
			Tcl_AppendResult(interp," {",(char *)0);
	}

		for (fdp = exp_i->state_list;fdp;fdp=fdp->next) {
			char buf[25];	/* big enough for a small int */
			sprintf(buf,"%ld", (long)fdp->esPtr);
			Tcl_AppendElement(interp,buf);
		}

	if (exp_i->state_list->next) {
			Tcl_AppendResult(interp,"} ",(char *)0);
	}
}
}

/* return current setting of the permanent expect_before/after/bg */
int
expect_info(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    struct exp_i *exp_i;
    int i;
    int direct = EXP_DIRECT|EXP_INDIRECT;
    char *iflag = 0;
    int all = FALSE;	/* report on all fds */
    ExpState *esPtr = 0;

    static char *flags[] = {"-i", "-all", "-noindirect", (char *)0};
    enum flags {EXP_ARG_I, EXP_ARG_ALL, EXP_ARG_NOINDIRECT};

    /* start with 2 to skip over "cmdname -info" */
    for (i = 2;i<objc;i++) {
	/*
	 * Allow abbreviations of switches and report an error if we
	 * get an invalid switch.
	 */

	int index;
	if (Tcl_GetIndexFromObj(interp, objv[i], flags, "flag", 0,
				&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum flags) index) {
	case EXP_ARG_I:
	    i++;
	    if (i >= objc) {
		Tcl_WrongNumArgs(interp, 1, objv,"-i spawn_id");
		return TCL_ERROR;
	    }
	    break;
	case EXP_ARG_ALL:
	    all = TRUE;
	    break;
	case EXP_ARG_NOINDIRECT:
	    direct &= ~EXP_INDIRECT;
	    break;
	}
    }

    if (all) {
	/* avoid printing out -i when redundant */
	struct exp_i *previous = 0;

	for (i=0;i<ecmd->ecd.count;i++) {
	    if (previous != ecmd->ecd.cases[i]->i_list) {
		exp_i_append(interp,ecmd->ecd.cases[i]->i_list);
		previous = ecmd->ecd.cases[i]->i_list;
	    }
	    ecase_append(interp,ecmd->ecd.cases[i]);
	}
	return TCL_OK;
    }

    if (!iflag) {
	if (!(esPtr = expStateCurrent(interp,0,0,0))) {
	    return TCL_ERROR;
	}
    } else if (!(esPtr = expStateFromChannelName(interp,iflag,0,0,0,"dummy"))) {
	/* not a valid ExpState so assume it is an indirect variable */
	Tcl_ResetResult(interp);
	for (i=0;i<ecmd->ecd.count;i++) {
	    if (ecmd->ecd.cases[i]->i_list->direct == EXP_INDIRECT &&
		    streq(ecmd->ecd.cases[i]->i_list->variable,iflag)) {
		ecase_append(interp,ecmd->ecd.cases[i]);
	    }
	}
	return TCL_OK;
    }
    
    /* print ecases of this direct_fd */
    for (exp_i=ecmd->i_list;exp_i;exp_i=exp_i->next) {
	if (!(direct & exp_i->direct)) continue;
	if (!exp_i_uses_state(exp_i,esPtr)) continue;
	ecase_by_exp_i_append(interp,ecmd,exp_i);
    }

    return TCL_OK;
}

/* Exp_ExpectGlobalObjCmd is invoked to process expect_before/after/background */
/*ARGSUSED*/
int
Exp_ExpectGlobalObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int result = TCL_OK;
    struct exp_i *exp_i, **eip;
    struct exp_state_list *slPtr;   /* temp for interating over state_list */
    struct exp_cmd_descriptor eg;
    int count;
    Tcl_Obj* new_cmd = NULL;

    struct exp_cmd_descriptor *ecmd = (struct exp_cmd_descriptor *) clientData;

    if ((objc == 2) && exp_one_arg_braced(objv[1])) {
	/* expect {...} */

	new_cmd = exp_eval_with_one_arg(clientData,interp,objv);
	if (!new_cmd) return TCL_ERROR;
    } else if ((objc == 3) && streq(Tcl_GetString(objv[1]),"-brace")) {
	/* expect -brace {...} ... fake command line for reparsing */

	Tcl_Obj *new_objv[2];
	new_objv[0] = objv[0];
	new_objv[1] = objv[2];

	new_cmd = exp_eval_with_one_arg(clientData,interp,new_objv);
	if (!new_cmd) return TCL_ERROR;
    }

    if (new_cmd) {
	/* Replace old arguments with result of the reparse */
	Tcl_ListObjGetElements (interp, new_cmd, &objc, (Tcl_Obj***) &objv);
    }

    if (objc > 1 && (Tcl_GetString(objv[1])[0] == '-')) {
	if (exp_flageq("info",Tcl_GetString(objv[1])+1,4)) {
	    int res = expect_info(interp,ecmd,objc,objv);
	    if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
	    return res;
	} 
    }

    exp_cmd_init(&eg,ecmd->cmdtype,EXP_PERMANENT);

    if (TCL_ERROR == parse_expect_args(interp,&eg,EXP_SPAWN_ID_BAD,
	    objc,objv)) {
	if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
	return TCL_ERROR;
    }

    /*
     * visit each NEW direct exp_i looking for spawn ids.
     * When found, remove them from any OLD exp_i's.
     */

    /* visit each exp_i */
    for (exp_i=eg.i_list;exp_i;exp_i=exp_i->next) {
	if (exp_i->direct == EXP_INDIRECT) continue;
	/* for each spawn id, remove it from ecases */
	for (slPtr=exp_i->state_list;slPtr;slPtr=slPtr->next) {
	    ExpState *esPtr = slPtr->esPtr;

	    /* validate all input descriptors */
	    if (!expStateAnyIs(esPtr)) {
		if (!expStateCheck(interp,esPtr,1,1,"expect")) {
		    result = TCL_ERROR;
		    goto cleanup;
		}
	    }
	    
	    /* remove spawn id from exp_i */
	    ecmd_remove_state(interp,ecmd,esPtr,EXP_DIRECT);
	}
    }
	
    /*
     * For each indirect variable, release its old ecases and 
     * clean up the matching spawn ids.
     * Same logic as in "expect_X delete" command.
     */

    for (exp_i=eg.i_list;exp_i;exp_i=exp_i->next) {
	struct exp_i **old_i;

	if (exp_i->direct == EXP_DIRECT) continue;

	for (old_i = &ecmd->i_list;*old_i;) {
	    struct exp_i *tmp;

	    if (((*old_i)->direct == EXP_DIRECT) ||
		    (!streq((*old_i)->variable,exp_i->variable))) {
		old_i = &(*old_i)->next;
		continue;
	    }

	    ecases_remove_by_expi(interp,ecmd,*old_i);
	    
	    /* unlink from middle of list */
	    tmp = *old_i;
	    *old_i = tmp->next;
	    tmp->next = 0;
	    exp_free_i(interp,tmp,exp_indirect_update2);
	}

	/* if new one has ecases, update it */
	if (exp_i->ecount) {
	    /* Note: The exp_indirect_ functions are Tcl_VarTraceProc's, and
	     * are used as such in other places of Expect. We cannot use a
	     * Tcl_Obj* as return value :(
	     */
	    char *msg = exp_indirect_update1(interp,ecmd,exp_i);
	    if (msg) {
		/* unusual way of handling error return */
		/* because of Tcl's variable tracing */
		Tcl_SetResult (interp, msg, TCL_VOLATILE);
		result = TCL_ERROR;
		goto indirect_update_abort;
	    }
	}
    }
    /* empty i_lists have to be removed from global eg.i_list */
    /* before returning, even if during error */
 indirect_update_abort:

    /*
     * New exp_i's that have 0 ecases indicate fd/vars to be deleted.
     * Now that the deletions have been done, discard the new exp_i's.
     */

    for (exp_i=eg.i_list;exp_i;) {
	struct exp_i *next = exp_i->next;

	if (exp_i->ecount == 0) {
	    exp_i_remove(interp,&eg.i_list,exp_i);
	}
	exp_i = next;
    }
    if (result == TCL_ERROR) goto cleanup;

    /*
     * arm all new bg direct fds
     */

    if (ecmd->cmdtype == EXP_CMD_BG) {
	for (exp_i=eg.i_list;exp_i;exp_i=exp_i->next) {
	    if (exp_i->direct == EXP_DIRECT) {
		state_list_arm(interp,exp_i->state_list);
	    }
	}
    }

    /*
     * now that old ecases are gone, add new ecases and exp_i's (both
     * direct and indirect).
     */

    /* append ecases */

    count = ecmd->ecd.count + eg.ecd.count;
    if (eg.ecd.count) {
	int start_index; /* where to add new ecases in old list */

	if (ecmd->ecd.count) {
	    /* append to end */
	    ecmd->ecd.cases = (struct ecase **)ckrealloc((char *)ecmd->ecd.cases, count * sizeof(struct ecase *));
	    start_index = ecmd->ecd.count;
	} else {
	    /* append to beginning */
	    ecmd->ecd.cases = (struct ecase **)ckalloc(eg.ecd.count * sizeof(struct ecase *));
	    start_index = 0;
	}
	memcpy(&ecmd->ecd.cases[start_index],eg.ecd.cases,
		eg.ecd.count*sizeof(struct ecase *));
	ecmd->ecd.count = count;
    }

    /* append exp_i's */
    for (eip = &ecmd->i_list;*eip;eip = &(*eip)->next) {
	/* empty loop to get to end of list */
    }
    /* *exp_i now points to end of list */

    *eip = eg.i_list;	/* connect new list to end of current list */

  cleanup:
    if (result == TCL_ERROR) {
	/* in event of error, free any unreferenced ecases */
	/* but first, split up i_list so that exp_i's aren't */
	/* freed twice */

	for (exp_i=eg.i_list;exp_i;) {
	    struct exp_i *next = exp_i->next;
	    exp_i->next = 0;
	    exp_i = next;
	}
	free_ecases(interp,&eg,1);
    } else {
	if (eg.ecd.cases) ckfree((char *)eg.ecd.cases);
    }

    if (ecmd->cmdtype == EXP_CMD_BG) {
	exp_background_channelhandlers_run_all();
    }

    if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
    return(result);
}

/* adjusts file according to user's size request */
void
expAdjust(ExpState *esPtr)
{
    int new_msize, excess;
    Tcl_UniChar *string;

    /*
     * Resize buffer to user's request * 3 + 1.
     *
     * x3: in case the match straddles two bufferfuls, and to allow
     *     reading a bufferful even when we reach near fullness of two.
     *     (At shuffle time this means we look for 2/3 full buffer and
     *      drop a 1/3, i.e. half of that).
     *
     * NOTE: The unmodified expect got the same effect by comparing
     *       apples and oranges in shuffle mgmt, i.e bytes vs. chars,
     *       and automatically extending the buffer (Tcl_Obj string)
     *       to hold that much.
     *
     * +1: for trailing null.
     */

    new_msize = esPtr->umsize * 3 + 1;

    if (new_msize != esPtr->input.max) {

	if (esPtr->input.use > new_msize) {
	    /*
	     * too much data, forget about data at beginning of buffer
	     */

	    string = esPtr->input.buffer;
	    excess = esPtr->input.use - new_msize; /* #chars */

	    memcpy (string, string + excess, new_msize * sizeof (Tcl_UniChar));
	    esPtr->input.use = new_msize;

	} else {
	    /*
	     * too little data - length < new_mbytes
	     * Make larger if the max is also too small.
	     */

	    if (esPtr->input.max < new_msize) {
	        esPtr->input.buffer = (Tcl_UniChar*) \
		    Tcl_Realloc ((char*)esPtr->input.buffer,
				 new_msize * sizeof (Tcl_UniChar));
	    }
	}

	esPtr->key = expect_key++;
	esPtr->input.max = new_msize;
    }
}

#if OBSOLETE
/* Strip parity */
static void
expParityStrip(
    Tcl_Obj *obj,
    int offsetBytes)
{
    char *p, ch;
    
    int changed = FALSE;
    
    for (p = Tcl_GetString(obj) + offsetBytes;*p;p++) {
	ch = *p & 0x7f;
	if (ch != *p) changed = TRUE;
	else *p &= 0x7f;
    }

    if (changed) {
	/* invalidate the unicode rep */
	if (obj->typePtr->freeIntRepProc) {
	    obj->typePtr->freeIntRepProc(obj);
	}
    }
}

/* This function is only used when debugging.  It checks when a string's
   internal UTF is sane and whether an offset into the string appears to
   be at a UTF boundary.
*/
static void
expValid(
    Tcl_Obj *obj,
    int offset)
{
  char *s, *end;
  int len;

  s = Tcl_GetStringFromObj(obj,&len);

  if (offset > len) {
    printf("offset (%d) > length (%d)\n",offset,len);
    fflush(stdout);
    abort();
  }

  /* first test for null terminator */
  end = s + len;
  if (*end != '\0') {
    printf("obj lacks null terminator\n");
    fflush(stdout);
    abort();
  }

  /* check for valid UTF sequence */
  while (*s) {
    Tcl_UniChar uc;

	s += TclUtfToUniChar(s,&uc);
    if (s > end) {
      printf("UTF out of sync with terminator\n");
      fflush(stdout);
      abort();
    }
  }
  s += offset;
  while (*s) {
    Tcl_UniChar uc;

	s += TclUtfToUniChar(s,&uc);
    if (s > end) {
      printf("UTF from offset out of sync with terminator\n");
      fflush(stdout);
      abort();
    }
  }
}
#endif /*OBSOLETE*/

/* Strip nulls from object, beginning at offset */
static int
expNullStrip(
    ExpUniBuf* buf,
    int offsetChars)
{
    Tcl_UniChar *src, *src2, *dest, *end;
    int newsize;       /* size of obj after all nulls removed */

    src2 = src = dest = buf->buffer + offsetChars;
    end               = buf->buffer + buf->use;

    while (src < end) {
	if (*src) {
	    *dest = *src;
	    dest ++;
	}
	src ++;
    }
    newsize = offsetChars + (dest - src2);
    buf->use = newsize;
    return newsize;
}

/* returns # of bytes read or (non-positive) error of form EXP_XXX */
/* returns 0 for end of file */
/* If timeout is non-zero, set an alarm before doing the read, else assume */
/* the read will complete immediately. */
/*ARGSUSED*/
static int
expIRead( /* INTL */
    Tcl_Interp *interp,
    ExpState *esPtr,
    int timeout,
    int save_flags)
{
    int cc = EXP_TIMEOUT;
    int size;

    /* We drop one third when are at least 2/3 full */
    /* condition is (size >= max*2/3) <=> (size*3 >= max*2) */
    if (expSizeGet(esPtr)*3 >= esPtr->input.max*2)
	exp_buffer_shuffle(interp,esPtr,save_flags,EXPECT_OUT,"expect");
    size = expSizeGet(esPtr);

#ifdef SIMPLE_EVENT
 restart:

    alarm_fired = FALSE;

    if (timeout > -1) {
	signal(SIGALRM,sigalarm_handler);
	alarm((timeout > 0)?timeout:1);
    }
#endif

    cc = Tcl_ReadChars(esPtr->channel, esPtr->input.newchars,
		       esPtr->input.max - esPtr->input.use,
		       0 /* no append */);
    i_read_errno = errno;

    if (cc > 0) {
        memcpy (esPtr->input.buffer + esPtr->input.use,
		Tcl_GetUnicodeFromObj (esPtr->input.newchars, NULL),
		cc * sizeof (Tcl_UniChar));
	esPtr->input.use += cc;
    }

#ifdef SIMPLE_EVENT
    alarm(0);

    if (cc == -1) {
	/* check if alarm went off */
	if (i_read_errno == EINTR) {
	    if (alarm_fired) {
		return EXP_TIMEOUT;
	    } else {
		if (Tcl_AsyncReady()) {
		    int rc = Tcl_AsyncInvoke(interp,TCL_OK);
		    if (rc != TCL_OK) return(exp_tcl2_returnvalue(rc));
		}
		goto restart;
	    }
	}
    }
#endif
    return cc;	
}

/*
 * expRead() does the logical equivalent of a read() for the expect command.
 * This includes figuring out which descriptor should be read from.
 *
 * The result of the read() is left in a spawn_id's buffer rather than
 * explicitly passing it back.  Note that if someone else has modified a buffer
 * either before or while this expect is running (i.e., if we or some event has
 * called Tcl_Eval which did another expect/interact), expRead will also call
 * this a successful read (for the purposes if needing to pattern match against
 * it).
 */

/* if it returns a negative number, it corresponds to a EXP_XXX result */
/* if it returns a non-negative number, it means there is data */
/* (0 means nothing new was actually read, but it should be looked at again) */
int
expRead(
    Tcl_Interp *interp,
    ExpState *(esPtrs[]),		/* If 0, then esPtrOut already known and set */
    int esPtrsMax,			/* number of esPtrs */
    ExpState **esPtrOut,		/* Out variable to leave new ExpState. */
    int timeout,
    int key)
{
    ExpState *esPtr;

    int size;
    int cc;
    int write_count;
    int tcl_set_flags;	/* if we have to discard chars, this tells */
			/* whether to show user locally or globally */

    if (esPtrs == 0) {
	/* we already know the ExpState, just find out what happened */
	cc = exp_get_next_event_info(interp,*esPtrOut);
	tcl_set_flags = TCL_GLOBAL_ONLY;
    } else {
	cc = exp_get_next_event(interp,esPtrs,esPtrsMax,esPtrOut,timeout,key);
	tcl_set_flags = 0;
    }

    esPtr = *esPtrOut;

    if (cc == EXP_DATA_NEW) {
	/* try to read it */
	cc = expIRead(interp,esPtr,timeout,tcl_set_flags);
	
	if (cc == 0 && Tcl_Eof(esPtr->channel)) {
	    cc = EXP_EOF;
	}
    } else if (cc == EXP_DATA_OLD) {
	cc = 0;
    } else if (cc == EXP_RECONFIGURE) {
	return EXP_RECONFIGURE;
    }

    if (cc == EXP_ABEOF) {	/* abnormal EOF */
	/* On many systems, ptys produce EIO upon EOF - sigh */
	if (i_read_errno == EIO) {
	    /* Sun, Cray, BSD, and others */
	    cc = EXP_EOF;
	} else if (i_read_errno == EINVAL) {
	    /* Solaris 2.4 occasionally returns this */
	    cc = EXP_EOF;
	} else {
	    if (i_read_errno == EBADF) {
		exp_error(interp,"bad spawn_id (process died earlier?)");
	    } else {
		exp_error(interp,"i_read(spawn_id fd=%d): %s",esPtr->fdin,
			Tcl_PosixError(interp));
		if (esPtr->close_on_eof) {
		exp_close(interp,esPtr);
	    }
	    }
	    return(EXP_TCLERROR);
	    /* was goto error; */
	}
    }

    /* EOF, TIMEOUT, and ERROR return here */
    /* In such cases, there is no need to update screen since, if there */
    /* was prior data read, it would have been sent to the screen when */
    /* it was read. */
    if (cc < 0) return (cc);

    /*
     * update display
     */

    size = expSizeGet(esPtr);
    if (size) write_count = size - esPtr->printed;
    else write_count = 0;
    
    if (write_count) {
	/*
	 * Show chars to user if they've requested it, UNLESS they're seeing it
	 * already because they're typing it and tty driver is echoing it.
	 * Also send to Diag and Log if appropriate.
	 */
	expLogInteractionU(esPtr,esPtr->input.buffer + esPtr->printed, write_count);
	    
	/*
	 * strip nulls from input, since there is no way for Tcl to deal with
	 * such strings.  Doing it here lets them be sent to the screen, just
	 * in case they are involved in formatting operations
	 */
	if (esPtr->rm_nulls) size = expNullStrip(&esPtr->input,esPtr->printed);
	esPtr->printed = size; /* count'm even if not logging */
    }
    return(cc);
}

/* when buffer fills, copy second half over first and */
/* continue, so we can do matches over multiple buffers */
void
exp_buffer_shuffle( /* INTL */
    Tcl_Interp *interp,
    ExpState *esPtr,
    int save_flags,
    char *array_name,
    char *caller_name)
{
    Tcl_UniChar *str;
    Tcl_UniChar *p;
    int numchars, newlen, skiplen;
    Tcl_UniChar lostChar;

    /*
     * allow user to see data we are discarding
     */

    expDiagLog("%s: set %s(spawn_id) \"%s\"\r\n",
	    caller_name,array_name,esPtr->name);
    Tcl_SetVar2(interp,array_name,"spawn_id",esPtr->name,save_flags);

    /*
     * The internal storage buffer object should only be referred
     * to by the channel that uses it.  We always copy the contents
     * out of the object before passing the data to anyone outside
     * of these routines.  This ensures that the object always has
     * a refcount of 1 so we can safely modify the contents in place.
     */

    str      = esPtr->input.buffer;
    numchars = esPtr->input.use;

    /* We discard 1/3 of the data in the buffer.
     */
    skiplen = numchars/3;
    p       = str + skiplen;

    /*
     * before doing move, show user data we are discarding
     */

    lostChar = *p;
    /* Temporarily stick null in middle of string to terminate */
    *p = 0;

    expDiagLog("%s: set %s(buffer) \"",caller_name,array_name);
    expDiagLogU(expPrintifyUni(str,numchars));
    expDiagLogU("\"\r\n");
    Tcl_SetVar2Ex(interp,array_name,"buffer",
		  Tcl_NewUnicodeObj (str, skiplen),
	    save_flags);

    /*
     * Restore damage done fir display above.
     */
    *p = lostChar;

    /*
     * move the higher 2/3 of the string down over the lower 2/3.
     * This destroys the 1st 1/3.
     */

    newlen = numchars - skiplen;
    memmove(str, p, newlen * sizeof(Tcl_UniChar));
    esPtr->input.use = newlen;

    esPtr->printed -= skiplen;
    if (esPtr->printed < 0) esPtr->printed = 0;
}

/* map EXP_ style return value to TCL_ style return value */
/* not defined to work on TCL_OK */
int
exp_tcl2_returnvalue(int x)
{
	switch (x) {
	case TCL_ERROR:			return EXP_TCLERROR;
	case TCL_RETURN:		return EXP_TCLRET;
	case TCL_BREAK:			return EXP_TCLBRK;
	case TCL_CONTINUE:		return EXP_TCLCNT;
	case EXP_CONTINUE:		return EXP_TCLCNTEXP;
	case EXP_CONTINUE_TIMER:	return EXP_TCLCNTTIMER;
	case EXP_TCL_RETURN:		return EXP_TCLRETTCL;
	}
    /* Must not reach this location. Can happen only if x is an
     * illegal value. Added return to suppress compiler warning.
     */
    return -1000;
}

/* map from EXP_ style return value to TCL_ style return values */
int
exp_2tcl_returnvalue(int x)
{
	switch (x) {
	case EXP_TCLERROR:		return TCL_ERROR;
	case EXP_TCLRET:		return TCL_RETURN;
	case EXP_TCLBRK:		return TCL_BREAK;
	case EXP_TCLCNT:		return TCL_CONTINUE;
	case EXP_TCLCNTEXP:		return EXP_CONTINUE;
	case EXP_TCLCNTTIMER:		return EXP_CONTINUE_TIMER;
	case EXP_TCLRETTCL:		return EXP_TCL_RETURN;
	}
    /* Must not reach this location. Can happen only if x is an
     * illegal value. Added return to suppress compiler warning.
     */
    return -1000;
}

/* variables predefined by expect are retrieved using this routine
which looks in the global space if they are not in the local space.
This allows the user to localize them if desired, and also to
avoid having to put "global" in procedure definitions.
*/
char *
exp_get_var(
    Tcl_Interp *interp,
    char *var)
{
    char *val;

    if (NULL != (val = Tcl_GetVar(interp,var,0 /* local */)))
	return(val);
    return(Tcl_GetVar(interp,var,TCL_GLOBAL_ONLY));
}

static int
get_timeout(Tcl_Interp *interp)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);
    CONST char *t;

    if (NULL != (t = exp_get_var(interp,EXPECT_TIMEOUT))) {
	tsdPtr->timeout = atoi(t);
    }
    return(tsdPtr->timeout);
}

/* make a copy of a linked list (1st arg) and attach to end of another (2nd
arg) */
static int
update_expect_states(
    struct exp_i *i_list,
    struct exp_state_list **i_union)
{
    struct exp_i *p;

    /* for each i_list in an expect statement ... */
    for (p=i_list;p;p=p->next) {
	struct exp_state_list *slPtr;

	/* for each esPtr in the i_list */
	for (slPtr=p->state_list;slPtr;slPtr=slPtr->next) {
	    struct exp_state_list *tmpslPtr;
	    struct exp_state_list *u;

	    if (expStateAnyIs(slPtr->esPtr)) continue;
	    
	    /* check this one against all so far */
	    for (u = *i_union;u;u=u->next) {
		if (slPtr->esPtr == u->esPtr) goto found;
	    }
	    /* if not found, link in as head of list */
	    tmpslPtr = exp_new_state(slPtr->esPtr);
	    tmpslPtr->next = *i_union;
	    *i_union = tmpslPtr;
	    found:;
	}
    }
    return TCL_OK;
}

char *
exp_cmdtype_printable(int cmdtype)
{
	switch (cmdtype) {
	case EXP_CMD_FG: return("expect");
	case EXP_CMD_BG: return("expect_background");
	case EXP_CMD_BEFORE: return("expect_before");
	case EXP_CMD_AFTER: return("expect_after");
	}
    /*#ifdef LINT*/
	return("unknown expect command");
    /*#endif*/
}

/* exp_indirect_update2 is called back via Tcl's trace handler whenever */
/* an indirect spawn id list is changed */
/*ARGSUSED*/
static char *
exp_indirect_update2(
    ClientData clientData,
    Tcl_Interp *interp,	/* Interpreter containing variable. */
    char *name1,	/* Name of variable. */
    char *name2,	/* Second part of variable name. */
    int flags)		/* Information about what happened. */
{
	char *msg;

	struct exp_i *exp_i = (struct exp_i *)clientData;
	exp_configure_count++;
	msg = exp_indirect_update1(interp,&exp_cmds[exp_i->cmdtype],exp_i);

	exp_background_channelhandlers_run_all();

	return msg;
}

static char *
exp_indirect_update1(
    Tcl_Interp *interp,
    struct exp_cmd_descriptor *ecmd,
    struct exp_i *exp_i)
{
	struct exp_state_list *slPtr;	/* temp for interating over state_list */

	/*
	 * disarm any ExpState's that lose all their active spawn ids
	 */

	if (ecmd->cmdtype == EXP_CMD_BG) {
		/* clean up each spawn id used by this exp_i */
		for (slPtr=exp_i->state_list;slPtr;slPtr=slPtr->next) {
			ExpState *esPtr = slPtr->esPtr;

			if (expStateAnyIs(esPtr)) continue;

			/* silently skip closed or preposterous fds */
			/* since we're just disabling them anyway */
			/* preposterous fds will have been reported */
			/* by code in next section already */
			if (!expStateCheck(interp,slPtr->esPtr,1,0,"")) continue;

			/* check before decrementing, ecount may not be */
			/* positive if update is called before ecount is */
			/* properly synchronized */
			if (esPtr->bg_ecount > 0) {
				esPtr->bg_ecount--;
			}
			if (esPtr->bg_ecount == 0) {
				exp_disarm_background_channelhandler(esPtr);
				esPtr->bg_interp = 0;
			}
		}
	}

	/*
	 * reread indirect variable
	 */

	exp_i_update(interp,exp_i);

	/*
	 * check validity of all fd's in variable
	 */

	for (slPtr=exp_i->state_list;slPtr;slPtr=slPtr->next) {
	    /* validate all input descriptors */

	    if (expStateAnyIs(slPtr->esPtr)) continue;

	    if (!expStateCheck(interp,slPtr->esPtr,1,1,
		    exp_cmdtype_printable(ecmd->cmdtype))) {
	    /* Note: Cannot construct a Tcl_Obj* here, the function is a
	     * Tcl_VarTraceProc and the API wants a char*.
	     *
	     * DANGER: The buffer may overflow if either the existing result,
	     * the variable name, or both become to large.
	     */
		static char msg[200];
		sprintf(msg,"%s from indirect variable (%s)",
		    Tcl_GetStringResult (interp),exp_i->variable);
		return msg;
	    }
	}

	/* for each spawn id in list, arm if necessary */
	if (ecmd->cmdtype == EXP_CMD_BG) {
		state_list_arm(interp,exp_i->state_list);
	}

	return (char *)0;
}

int
expMatchProcess(
    Tcl_Interp *interp,
    struct eval_out *eo,	/* final case of interest */
    int cc,			/* EOF, TIMEOUT, etc... */
    int bg,			/* 1 if called from background handler, */
				/* else 0 */
    char *detail)
{
    ExpState *esPtr = 0;
    Tcl_Obj *body = 0;
    Tcl_UniChar *buffer;
    struct ecase *e = 0;	/* points to current ecase */
    int match = -1;		/* characters matched */
    /* uprooted by a NULL */
    int result = TCL_OK;

#define out(indexName, value) \
 expDiagLog("%s: set %s(%s) \"",detail,EXPECT_OUT,indexName); \
 expDiagLogU(expPrintify(value)); \
 expDiagLogU("\"\r\n"); \
 Tcl_SetVar2(interp, EXPECT_OUT,indexName,value,(bg ? TCL_GLOBAL_ONLY : 0));

    /* The numchars argument allows us to avoid sticking a \0 into the buffer */
#define outuni(indexName, value,numchars) \
 expDiagLog("%s: set %s(%s) \"",detail,EXPECT_OUT,indexName); \
 expDiagLogU(expPrintifyUni(value,numchars)); \
 expDiagLogU("\"\r\n"); \
 Tcl_SetVar2Ex(interp, EXPECT_OUT,indexName,Tcl_NewUnicodeObj(value,numchars),(bg ? TCL_GLOBAL_ONLY : 0));

    if (eo->e) {
	e = eo->e;
	body = e->body;
	if (cc != EXP_TIMEOUT) {
	    esPtr = eo->esPtr;
	    match = eo->matchlen;
	    buffer = eo->matchbuf;
	}
    } else if (cc == EXP_EOF) {
	/* read an eof but no user-supplied case */
	esPtr = eo->esPtr;
	match = eo->matchlen;
	buffer = eo->matchbuf;
    }			

    if (match >= 0) {
	char name[20], value[20];
	int i;

	if (e && e->use == PAT_RE) {
	    Tcl_RegExp re;
	    int flags;
	    Tcl_RegExpInfo info;
	    Tcl_Obj *buf;

	    /* No gate keeper required here, we know that the RE
	     * matches, we just do it again to get all the captured
	     * pieces
	     */

	    if (e->Case == CASE_NORM) {
		flags = TCL_REG_ADVANCED;
	    } else {
		flags = TCL_REG_ADVANCED | TCL_REG_NOCASE;
	    }
		    
	    re = Tcl_GetRegExpFromObj(interp, e->pat, flags);
	    Tcl_RegExpGetInfo(re, &info);

	    buf = Tcl_NewUnicodeObj (buffer,esPtr->input.use);
	    for (i=0;i<=info.nsubs;i++) {
		int start, end;
		Tcl_Obj *val;

		start = info.matches[i].start;
		end = info.matches[i].end-1;
		if (start == -1) continue;

		if (e->indices) {
		    /* start index */
		    sprintf(name,"%d,start",i);
		    sprintf(value,"%d",start);
		    out(name,value);

		    /* end index */
		    sprintf(name,"%d,end",i);
		    sprintf(value,"%d",end);
		    out(name,value);
		}

				/* string itself */
		sprintf(name,"%d,string",i);
		val = Tcl_GetRange(buf, start, end);
		expDiagLog("%s: set %s(%s) \"",detail,EXPECT_OUT,name);
		expDiagLogU(expPrintifyObj(val));
		expDiagLogU("\"\r\n");
		Tcl_SetVar2Ex(interp,EXPECT_OUT,name,val,(bg ? TCL_GLOBAL_ONLY : 0));
	    }
	    Tcl_DecrRefCount (buf);
	} else if (e && (e->use == PAT_GLOB || e->use == PAT_EXACT)) {
	    Tcl_UniChar *str;

	    if (e->indices) {
		/* start index */
		sprintf(value,"%d",e->simple_start);
		out("0,start",value);

		/* end index */
		sprintf(value,"%d",e->simple_start + match - 1);
		out("0,end",value);
	    }

	    /* string itself */
	    str = esPtr->input.buffer + e->simple_start;
	    outuni("0,string",str,match);

				/* redefine length of string that */
				/* matched for later extraction */
	    match += e->simple_start;
	} else if (e && e->use == PAT_NULL && e->indices) {
				/* start index */
	    sprintf(value,"%d",match-1);
	    out("0,start",value);
				/* end index */
	    sprintf(value,"%d",match-1);
	    out("0,end",value);
	} else if (e && e->use == PAT_FULLBUFFER) {
	    expDiagLogU("expect_background: full buffer\r\n");
	}
    }

    /* this is broken out of (match > 0) (above) since it can be */
    /* that an EOF occurred with match == 0 */
    if (eo->esPtr) {
	Tcl_UniChar *str;
	int numchars;

	out("spawn_id",esPtr->name);

	str      = esPtr->input.buffer;
	numchars = esPtr->input.use;

	/* Save buf[0..match] */
	outuni("buffer",str,match);

	/* "!e" means no case matched - transfer by default */
	if (!e || e->transfer) {
	    int remainder = numchars-match;
	    /* delete matched chars from input buffer */
	    esPtr->printed -= match;
	    if (numchars != 0) {
		memmove(str,str+match,remainder*sizeof(Tcl_UniChar));
	    }
	    esPtr->input.use = remainder;
	}

	if (cc == EXP_EOF) {
	    /* exp_close() deletes all background bodies */
	    /* so save eof body temporarily */
	    if (body) { Tcl_IncrRefCount(body); }
	    if (esPtr->close_on_eof) {
	    exp_close(interp,esPtr);
	}
    }
    }

    if (body) {
	if (!bg) {
	    result = Tcl_EvalObjEx(interp,body,0);
	} else {
	    result = Tcl_EvalObjEx(interp,body,TCL_EVAL_GLOBAL);
	    if (result != TCL_OK) Tcl_BackgroundError(interp);
	}
	if (cc == EXP_EOF) { Tcl_DecrRefCount(body); }
    }
    return result;
}

/* this function is called from the background when input arrives */
/*ARGSUSED*/
void
exp_background_channelhandler( /* INTL */
    ClientData clientData,
    int mask)
{
  char backup[EXP_CHANNELNAMELEN+1]; /* backup copy of esPtr channel name! */

    ExpState *esPtr;
    Tcl_Interp *interp;
    int cc;			/* number of bytes returned in a single read */
				/* or negative EXP_whatever */
    struct eval_out eo;		/* final case of interest */
    ExpState *last_esPtr;	/* for differentiating when multiple esPtrs */
				/* to print out better debugging messages */
    int last_case;		/* as above but for case */

    /* restore our environment */
    esPtr = (ExpState *)clientData;

    /* backup just in case someone zaps esPtr in the middle of our work! */
    strcpy(backup,esPtr->name); 

    interp = esPtr->bg_interp;

    /* temporarily prevent this handler from being invoked again */
    exp_block_background_channelhandler(esPtr);

    /*
     * if mask == 0, then we've been called because the patterns changed not
     * because the waiting data has changed, so don't actually do any I/O
     */
    if (mask == 0) {
	cc = 0;
    } else {
	esPtr->notifiedMask = mask;
	esPtr->notified = FALSE;
	cc = expRead(interp,(ExpState **)0,0,&esPtr,EXP_TIME_INFINITY,0);
    }

do_more_data:
    eo.e = 0;		/* no final case yet */
    eo.esPtr = 0;		/* no final file selected yet */
    eo.matchlen = 0;		/* nothing matched yet */

    /* force redisplay of buffer when debugging */
    last_esPtr = 0;

    if (cc == EXP_EOF) {
	/* do nothing */
    } else if (cc < 0) { /* EXP_TCLERROR or any other weird value*/
	goto finish;
	/* 
	 * if we were going to do this right, we should differentiate between
	 * things like HP ioctl-open-traps that fall out here and should
	 * rightfully be ignored and real errors that should be reported.  Come
	 * to think of it, the only errors will come from HP ioctl handshake
	 * botches anyway.
	 */
    } else {
	/* normal case, got data */
	/* new data if cc > 0, same old data if cc == 0 */

	/* below here, cc as general status */
	cc = EXP_NOMATCH;
    }

    cc = eval_cases(interp,&exp_cmds[EXP_CMD_BEFORE],
	    esPtr,&eo,&last_esPtr,&last_case,cc,&esPtr,1,"_background");
    cc = eval_cases(interp,&exp_cmds[EXP_CMD_BG],
	    esPtr,&eo,&last_esPtr,&last_case,cc,&esPtr,1,"_background");
    cc = eval_cases(interp,&exp_cmds[EXP_CMD_AFTER],
	    esPtr,&eo,&last_esPtr,&last_case,cc,&esPtr,1,"_background");
    if (cc == EXP_TCLERROR) {
		/* only likely problem here is some internal regexp botch */
		Tcl_BackgroundError(interp);
		goto finish;
    }
    /* special eof code that cannot be done in eval_cases */
    /* or above, because it would then be executed several times */
    if (cc == EXP_EOF) {
	eo.esPtr = esPtr;
	eo.matchlen = expSizeGet(eo.esPtr);
	eo.matchbuf = eo.esPtr->input.buffer;
	expDiagLogU("expect_background: read eof\r\n");
	goto matched;
    }
    if (!eo.e) {
	/* if we get here, there must not have been a match */
	goto finish;
    }

 matched:
    expMatchProcess(interp, &eo, cc, 1 /* bg */,"expect_background");

    /*
     * Event handler will not call us back if there is more input
     * pending but it has already arrived.  bg_status will be
     * "blocked" only if armed.
     */

    /*
     * Connection could have been closed on us.  In this case,
     * exitWhenBgStatusUnblocked will be 1 and we should disable the channel
     * handler and release the esPtr.
     */

    /* First check that the esPtr is even still valid! */
    /* 
     * It isn't sufficient to just check that 'Tcl_GetChannel' still knows about
     * backup since it is possible that esPtr was lost in the background AND
     * another process spawned and reassigned the same name. 
     */
    if (!expChannelStillAlive(esPtr, backup)) {
      expDiagLog("expect channel %s lost in background handler\n",backup);
      return;
    }

    if ((!esPtr->freeWhenBgHandlerUnblocked) && (esPtr->bg_status == blocked)) {
	if (0 != (cc = expSizeGet(esPtr))) {
	    goto do_more_data;
	}
    }
 finish:
    exp_unblock_background_channelhandler(esPtr);
    if (esPtr->freeWhenBgHandlerUnblocked)
	expStateFree(esPtr);
}

/*ARGSUSED*/
int
Exp_ExpectObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int cc;			/* number of chars returned in a single read */
				/* or negative EXP_whatever */
    ExpState *esPtr = 0;

    int i;			/* misc temporary */
    struct exp_cmd_descriptor eg;
    struct exp_state_list *state_list;	/* list of ExpStates to watch */
    struct exp_state_list *slPtr;	/* temp for interating over state_list */
    ExpState **esPtrs;
    int mcount;			/* number of esPtrs to watch */

    struct eval_out eo;		/* final case of interest */

    int result;			/* Tcl result */
    
    time_t start_time_total;	/* time at beginning of this procedure */
    time_t start_time = 0;	/* time when restart label hit */
    time_t current_time = 0;	/* current time (when we last looked)*/
    time_t end_time;		/* future time at which to give up */

    ExpState *last_esPtr;	/* for differentiating when multiple f's */
				/* to print out better debugging messages */
    int last_case;		/* as above but for case */
    int first_time = 1;		/* if not "restarted" */
    
    int key;			/* identify this expect command instance */
    int configure_count;	/* monitor exp_configure_count */

    int timeout;		/* seconds */
    int remtime;		/* remaining time in timeout */
    int reset_timer;		/* should timer be reset after continue? */
    Tcl_Time temp_time;
    Tcl_Obj* new_cmd = NULL;

    if ((objc == 2) && exp_one_arg_braced(objv[1])) {
	/* expect {...} */

	new_cmd = exp_eval_with_one_arg(clientData,interp,objv);
	if (!new_cmd) return TCL_ERROR;
    } else if ((objc == 3) && streq(Tcl_GetString(objv[1]),"-brace")) {
	/* expect -brace {...} ... fake command line for reparsing */

	Tcl_Obj *new_objv[2];
	new_objv[0] = objv[0];
	new_objv[1] = objv[2];

	new_cmd = exp_eval_with_one_arg(clientData,interp,new_objv);
	if (!new_cmd) return TCL_ERROR;
    }

    if (new_cmd) {
	/* Replace old arguments with result of the reparse */
	Tcl_ListObjGetElements (interp, new_cmd, &objc, (Tcl_Obj***) &objv);
    }

    Tcl_GetTime (&temp_time);
    start_time_total = temp_time.sec;
    start_time = start_time_total;
    reset_timer = TRUE;
    
    if (&StdinoutPlaceholder == (ExpState *)clientData) {
	clientData = (ClientData) expStdinoutGet();
    } else if (&DevttyPlaceholder == (ExpState *)clientData) {
	clientData = (ClientData) expDevttyGet();
    }
	
    /* make arg list for processing cases */
    /* do it dynamically, since expect can be called recursively */

    exp_cmd_init(&eg,EXP_CMD_FG,EXP_TEMPORARY);
    state_list = 0;
    esPtrs = 0;
    if (TCL_ERROR == parse_expect_args(interp,&eg, (ExpState *)clientData,
				       objc,objv)) {
	if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
	return TCL_ERROR;
    }

 restart_with_update:
    /* validate all descriptors and flatten ExpStates into array */

    if ((TCL_ERROR == update_expect_states(exp_cmds[EXP_CMD_BEFORE].i_list,&state_list))
	    || (TCL_ERROR == update_expect_states(exp_cmds[EXP_CMD_AFTER].i_list, &state_list))
	    || (TCL_ERROR == update_expect_states(eg.i_list,&state_list))) {
	result = TCL_ERROR;
	goto cleanup;
    }

    /* declare ourselves "in sync" with external view of close/indirect */
    configure_count = exp_configure_count;

    /* count and validate state_list */
    mcount = 0;
    for (slPtr=state_list;slPtr;slPtr=slPtr->next) {
	mcount++;
	/* validate all input descriptors */
	if (!expStateCheck(interp,slPtr->esPtr,1,1,"expect")) {
	    result = TCL_ERROR;
	    goto cleanup;
	}
    }

    /* make into an array */
    esPtrs = (ExpState **)ckalloc(mcount * sizeof(ExpState *));
    for (slPtr=state_list,i=0;slPtr;slPtr=slPtr->next,i++) {
	esPtrs[i] = slPtr->esPtr;
    }

  restart:
    if (first_time) first_time = 0;
    else {
        Tcl_GetTime (&temp_time);
	start_time = temp_time.sec;
    }

    if (eg.timeout_specified_by_flag) {
	timeout = eg.timeout;
    } else {
	/* get the latest timeout */
	timeout = get_timeout(interp);
    }

    key = expect_key++;

    result = TCL_OK;
    last_esPtr = 0;

    /*
     * end of restart code
     */

    eo.e = 0;		/* no final case yet */
    eo.esPtr = 0;	/* no final ExpState selected yet */
    eo.matchlen = 0;	/* nothing matched yet */

    /* timeout code is a little tricky, be very careful changing it */
    if (timeout != EXP_TIME_INFINITY) {
	/* if exp_continue -continue_timer, do not update end_time */
	if (reset_timer) {
	    Tcl_GetTime (&temp_time);
	    current_time = temp_time.sec;
	    end_time = current_time + timeout;
	} else {
	    reset_timer = TRUE;
	}
    }

    /* remtime and current_time updated at bottom of loop */
    remtime = timeout;

    for (;;) {
	if ((timeout != EXP_TIME_INFINITY) && (remtime < 0)) {
	    cc = EXP_TIMEOUT;
	} else {
	    cc = expRead(interp,esPtrs,mcount,&esPtr,remtime,key);
	}

	/*SUPPRESS 530*/
	if (cc == EXP_EOF) {
	    /* do nothing */
	} else if (cc == EXP_TIMEOUT) {
	    expDiagLogU("expect: timed out\r\n");
	} else if (cc == EXP_RECONFIGURE) {
	    reset_timer = FALSE;
	    goto restart_with_update;
	} else if (cc < 0) { /* EXP_TCLERROR or any other weird value*/
	    goto error;
	} else {
	    /* new data if cc > 0, same old data if cc == 0 */
	    
	    /* below here, cc as general status */
	    cc = EXP_NOMATCH;

	    /* force redisplay of buffer when debugging */
	    last_esPtr = 0;
	}

	cc = eval_cases(interp,&exp_cmds[EXP_CMD_BEFORE],
		esPtr,&eo,&last_esPtr,&last_case,cc,esPtrs,mcount,"");
	cc = eval_cases(interp,&eg,
		esPtr,&eo,&last_esPtr,&last_case,cc,esPtrs,mcount,"");
	cc = eval_cases(interp,&exp_cmds[EXP_CMD_AFTER],
		esPtr,&eo,&last_esPtr,&last_case,cc,esPtrs,mcount,"");
	if (cc == EXP_TCLERROR) goto error;
	/* special eof code that cannot be done in eval_cases */
	/* or above, because it would then be executed several times */
	if (cc == EXP_EOF) {
	    eo.esPtr = esPtr;
	    eo.matchlen = expSizeGet(eo.esPtr);
	    eo.matchbuf = eo.esPtr->input.buffer;
	    expDiagLogU("expect: read eof\r\n");
	    break;
	} else if (cc == EXP_TIMEOUT) break;

	/* break if timeout or eof and failed to find a case for it */

	if (eo.e) break;

	/* no match was made with current data, force a read */
	esPtr->force_read = TRUE;

	if (timeout != EXP_TIME_INFINITY) {
	    Tcl_GetTime (&temp_time);
	    current_time = temp_time.sec;
	    remtime = end_time - current_time;
	}
    }

    goto done;

error:
    result = exp_2tcl_returnvalue(cc);
 done:
    if (result != TCL_ERROR) {
	result = expMatchProcess(interp, &eo, cc, 0 /* not bg */,"expect");
    }

 cleanup:
    if (result == EXP_CONTINUE_TIMER) {
	reset_timer = FALSE;
	result = EXP_CONTINUE;
    }

    if ((result == EXP_CONTINUE) && (configure_count == exp_configure_count)) {
	expDiagLogU("expect: continuing expect\r\n");
	goto restart;
    }

    if (state_list) {
	exp_free_state(state_list);
	state_list = 0;
    }
    if (esPtrs) {
	ckfree((char *)esPtrs);
	esPtrs = 0;
    }

    if (result == EXP_CONTINUE) {
	expDiagLogU("expect: continuing expect after update\r\n");
	goto restart_with_update;
    }

    free_ecases(interp,&eg,0);	/* requires i_lists to be avail */
    exp_free_i(interp,eg.i_list,exp_indirect_update2);

    if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
    return(result);
}

/*ARGSUSED*/
static int
Exp_TimestampObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
	char *format = 0;
	time_t seconds = -1;
	int gmt = FALSE;	/* local time by default */
	struct tm *tm;
	Tcl_DString dstring;
    int i;

    static char* options[] = {
	"-format",
	"-gmt",
	"-seconds",
	NULL
    };
    enum options {
	TS_FORMAT,
	TS_GMT,
	TS_SECONDS
    };

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
				&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	case TS_FORMAT:
	    i++;
	    if (i >= objc) goto usage_error;
	    format = Tcl_GetString (objv[i]);
	    break;
	case TS_GMT:
	    gmt = TRUE;
	    break;
	case TS_SECONDS: {
	    int sec;
	    i++;
	    if (i >= objc) goto usage_error;
	    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &sec)) {
		goto usage_error;
	    }
	    seconds = sec;
	}
	    break;
	}
    }

    if (i < objc) goto usage_error;

    if (seconds == -1) {
	time(&seconds);
    }

    if (format) {
	if (gmt) {
	    tm = gmtime(&seconds);
	} else {
	    tm = localtime(&seconds);
	}
	Tcl_DStringInit(&dstring);
	exp_strftime(format,tm,&dstring);
	Tcl_DStringResult(interp,&dstring);
    } else {
	Tcl_SetObjResult (interp, Tcl_NewIntObj (seconds));
    }
	
    return TCL_OK;
 usage_error:
    exp_error(interp,"args: [-seconds #] [-format format] [-gmt]");
    return TCL_ERROR;

}

/* Helper function hnadling the common processing of -d and -i options of
 * various commands.
 */

static int
process_di _ANSI_ARGS_ ((Tcl_Interp* interp,
			 int objc,
			 Tcl_Obj *CONST objv[],		/* Argument objects. */
			 int* at,
			 int* Default,
			 ExpState **esOut,
			 CONST char* cmd));

static int
process_di (
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[],		/* Argument objects. */
    int* at,
    int* Default,
    ExpState **esOut,
    CONST char* cmd)
{
    static char* options[] = {
	"-d",
	"-i",
	NULL
    };
    enum options {
	DI_DEFAULT,
	DI_ID
    };
    int def = FALSE;
    char* chan = NULL;
    int i;
    ExpState *esPtr;

    for (i=1; i<objc; i++) {
	char *name;
	int index;

	name = Tcl_GetString(objv[i]);
	if (name[0] != '-') {
	    break;
	}
	if (Tcl_GetIndexFromObj(interp, objv[i], options, "flag", 0,
				&index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch ((enum options) index) {
	case DI_DEFAULT:
	    def = TRUE;
	    break;
	case DI_ID:
	    i++;
	    if (i >= objc) {
		exp_error(interp,"-i needs argument");
		return(TCL_ERROR);
	    }
	    chan = Tcl_GetString (objv[i]);
	    break;
	}
    }

    if (def && chan) {
	exp_error(interp,"cannot do -d and -i at the same time");
	return(TCL_ERROR);
    }

    /* Not all arguments processed, more than two remaining, only at most one
     * remaining is expected/allowed.
     */
    if (i < (objc-1)) {
	exp_error(interp,"too many arguments");
	return(TCL_OK);
	    }
	    
    if (!def) {
	if (!chan) {
	    esPtr = expStateCurrent(interp,0,0,0);
	} else {
	    esPtr = expStateFromChannelName(interp,chan,0,0,0,(char*)cmd);
	}
	if (!esPtr) return(TCL_ERROR);
    }

    *at = i;
    *Default = def;
    *esOut = esPtr;
    return TCL_OK;
}


/*ARGSUSED*/
int
Exp_MatchMaxObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int size = -1;
    ExpState *esPtr = 0;
    int Default = FALSE;
    int i;

    if (TCL_OK != process_di (interp, objc, objv, &i, &Default, &esPtr, "match_max"))
	return TCL_ERROR;

    /* No size argument */
    if (i == objc) {
	if (Default) {
	    size = exp_default_match_max;
	} else {
	    size = esPtr->umsize;
	}
	Tcl_SetObjResult (interp, Tcl_NewIntObj (size));
	return(TCL_OK);
    }
    
    /*
     * All that's left is to set the size
     */

    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &size)) {
	return TCL_ERROR;
    }

    if (size <= 0) {
	exp_error(interp,"must be positive");
	return(TCL_ERROR);
    }

    if (Default) exp_default_match_max = size;
    else esPtr->umsize = size;

    return(TCL_OK);
}

/*ARGSUSED*/
int
Exp_RemoveNullsObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int value = -1;
    ExpState *esPtr = 0;
    int Default = FALSE;
    int i;

    if (TCL_OK != process_di (interp, objc, objv, &i, &Default, &esPtr, "remove_nulls"))
	return TCL_ERROR;

    /* No flag argument */
    if (i == objc) {
	if (Default) {
	  value = exp_default_rm_nulls;
	} else {
	  value = esPtr->rm_nulls;
	}
	Tcl_SetObjResult (interp, Tcl_NewIntObj (value));
	return(TCL_OK);
    }

    /* all that's left is to set the value */

    if (TCL_OK != Tcl_GetBooleanFromObj (interp, objv[i], &value)) {
	return TCL_ERROR;
    }

    if ((value != 0) && (value != 1)) {
	exp_error(interp,"must be 0 or 1");
	return(TCL_ERROR);
    }

    if (Default) exp_default_rm_nulls = value;
    else esPtr->rm_nulls = value;

    return(TCL_OK);
}

/*ARGSUSED*/
int
Exp_ParityObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int parity;
    ExpState *esPtr = 0;
    int Default = FALSE;
    int i;

    if (TCL_OK != process_di (interp, objc, objv, &i, &Default, &esPtr, "parity"))
	return TCL_ERROR;

    /* No parity argument */
    if (i == objc) {
	if (Default) {
	    parity = exp_default_parity;
	} else {
	    parity = esPtr->parity;
	}
	Tcl_SetObjResult (interp, Tcl_NewIntObj (parity));
	return(TCL_OK);
    }

    /* all that's left is to set the parity */

    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &parity)) {
	return TCL_ERROR;
    }

    if (Default) exp_default_parity = parity;
    else esPtr->parity = parity;

    return(TCL_OK);
}

/*ARGSUSED*/
int
Exp_CloseOnEofObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
    int close_on_eof;
    ExpState *esPtr = 0;
    int Default = FALSE;
    int i;

    if (TCL_OK != process_di (interp, objc, objv, &i, &Default, &esPtr, "close_on_eof"))
	return TCL_ERROR;

    /* No flag argument */
    if (i == objc) {
	if (Default) {
	    close_on_eof = exp_default_close_on_eof;
	} else {
	    close_on_eof = esPtr->close_on_eof;
	}
	Tcl_SetObjResult (interp, Tcl_NewIntObj (close_on_eof));
	return(TCL_OK);
    }

    /* all that's left is to set the close_on_eof */

    if (TCL_OK != Tcl_GetIntFromObj (interp, objv[i], &close_on_eof)) {
	return TCL_ERROR;
    }

    if (Default) exp_default_close_on_eof = close_on_eof;
    else esPtr->close_on_eof = close_on_eof;

    return(TCL_OK);
}

#if DEBUG_PERM_ECASES
/* This big chunk of code is just for debugging the permanent */
/* expect cases */
void
exp_fd_print(struct exp_state_list *slPtr)
{
	if (!slPtr) return;
	printf("%d ",slPtr->esPtr);
	exp_fd_print(slPtr->next);
}

void
exp_i_print(struct exp_i *exp_i)
{
	if (!exp_i) return;
	printf("exp_i %x",exp_i);
	printf((exp_i->direct == EXP_DIRECT)?" direct":" indirect");
	printf((exp_i->duration == EXP_PERMANENT)?" perm":" tmp");
	printf("  ecount = %d\n",exp_i->ecount);
	printf("variable %s, value %s\n",
		((exp_i->variable)?exp_i->variable:"--"),
		((exp_i->value)?exp_i->value:"--"));
	printf("ExpStates: ");
	exp_fd_print(exp_i->state_list); printf("\n");
	exp_i_print(exp_i->next);
}

void
exp_ecase_print(struct ecase *ecase)
{
	printf("pat <%s>\n",ecase->pat);
	printf("exp_i = %x\n",ecase->i_list);
}

void
exp_ecases_print(struct exp_cases_descriptor *ecd)
{
	int i;

	printf("%d cases\n",ecd->count);
	for (i=0;i<ecd->count;i++) exp_ecase_print(ecd->cases[i]);
}

void
exp_cmd_print(struct exp_cmd_descriptor *ecmd)
{
	printf("expect cmd type: %17s",exp_cmdtype_printable(ecmd->cmdtype));
	printf((ecmd->duration==EXP_PERMANENT)?" perm ": "tmp ");
	/* printdict */
	exp_ecases_print(&ecmd->ecd);
	exp_i_print(ecmd->i_list);
}

void
exp_cmds_print(void)
{
	exp_cmd_print(&exp_cmds[EXP_CMD_BEFORE]);
	exp_cmd_print(&exp_cmds[EXP_CMD_AFTER]);
	exp_cmd_print(&exp_cmds[EXP_CMD_BG]);
}

/*ARGSUSED*/
int
cmdX(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST objv[])		/* Argument objects. */
{
	exp_cmds_print();
	return TCL_OK;
}
#endif /*DEBUG_PERM_ECASES*/

void
expExpectVarsInit(void)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    tsdPtr->timeout = INIT_EXPECT_TIMEOUT;
}

static struct exp_cmd_data
cmd_data[]  = {
{"expect",	Exp_ExpectObjCmd,	0,	(ClientData)0,	0},
{"expect_after",Exp_ExpectGlobalObjCmd, 0,	(ClientData)&exp_cmds[EXP_CMD_AFTER],0},
{"expect_before",Exp_ExpectGlobalObjCmd,0,	(ClientData)&exp_cmds[EXP_CMD_BEFORE],0},
{"expect_user",	Exp_ExpectObjCmd,	0,	(ClientData)&StdinoutPlaceholder,0},
{"expect_tty",	Exp_ExpectObjCmd,	0,	(ClientData)&DevttyPlaceholder,0},
{"expect_background",Exp_ExpectGlobalObjCmd,0,	(ClientData)&exp_cmds[EXP_CMD_BG],0},
    {"match_max",	 Exp_MatchMaxObjCmd,     0,	(ClientData)0,	0},
    {"remove_nulls",     Exp_RemoveNullsObjCmd,  0,	(ClientData)0,	0},
    {"parity",	         Exp_ParityObjCmd,       0,	(ClientData)0,	0},
    {"close_on_eof",     Exp_CloseOnEofObjCmd,   0,	(ClientData)0,	0},
    {"timestamp",	 Exp_TimestampObjCmd,    0,	(ClientData)0,	0},
{0}};

void
exp_init_expect_cmds(Tcl_Interp *interp)
{
	exp_create_commands(interp,cmd_data);

	Tcl_SetVar(interp,EXPECT_TIMEOUT,INIT_EXPECT_TIMEOUT_LIT,0);

	exp_cmd_init(&exp_cmds[EXP_CMD_BEFORE],EXP_CMD_BEFORE,EXP_PERMANENT);
	exp_cmd_init(&exp_cmds[EXP_CMD_AFTER ],EXP_CMD_AFTER, EXP_PERMANENT);
	exp_cmd_init(&exp_cmds[EXP_CMD_BG    ],EXP_CMD_BG,    EXP_PERMANENT);
	exp_cmd_init(&exp_cmds[EXP_CMD_FG    ],EXP_CMD_FG,    EXP_TEMPORARY);

	/* preallocate to one element, so future realloc's work */
	exp_cmds[EXP_CMD_BEFORE].ecd.cases = 0;
	exp_cmds[EXP_CMD_AFTER ].ecd.cases = 0;
	exp_cmds[EXP_CMD_BG    ].ecd.cases = 0;

	pattern_style[PAT_EOF] = "eof";
	pattern_style[PAT_TIMEOUT] = "timeout";
	pattern_style[PAT_DEFAULT] = "default";
	pattern_style[PAT_FULLBUFFER] = "full buffer";
	pattern_style[PAT_GLOB] = "glob pattern";
	pattern_style[PAT_RE] = "regular expression";
	pattern_style[PAT_EXACT] = "exact string";
	pattern_style[PAT_NULL] = "null";

#if 0
    Tcl_CreateObjCommand(interp,"x",cmdX,(ClientData)0,exp_deleteProc);
#endif
}

void
exp_init_sig(void) {
#if 0
	signal(SIGALRM,sigalarm_handler);
	signal(SIGINT,sigint_handler);
#endif
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
