/* interact (using select) - give user keyboard control

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include "expect_cf.h"
#include <stdio.h>
#ifdef HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#include <sys/types.h>
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif
  
#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#include <ctype.h>

#include "tclInt.h"
#include "string.h"

#include "exp_tty_in.h"
#include "exp_rename.h"
#include "exp_prog.h"
#include "exp_command.h"
#include "exp_log.h"
#include "exp_event.h" /* exp_get_next_event decl */

/* Tcl 8.5+ moved this internal - needed for when I compile expect against 8.5. */
#ifndef TCL_REG_BOSONLY
#define TCL_REG_BOSONLY 002000
#endif

typedef struct ThreadSpecificData {
    Tcl_Obj *cmdObjReturn;
    Tcl_Obj *cmdObjInterpreter;
} ThreadSpecificData;

static Tcl_ThreadDataKey dataKey;

#define INTER_OUT "interact_out"
#define out(var,val) \
 expDiagLog("interact: set %s(%s) ",INTER_OUT,var); \
 expDiagLogU(expPrintify(val)); \
 expDiagLogU("\"\r\n"); \
 Tcl_SetVar2(interp,INTER_OUT,var,val,0);

/*
 * tests if we are running this using a real tty
 *
 * these tests are currently only used to control what gets written to the
 * logfile.  Note that removal of the test of "..._is_tty" means that stdin
 * or stdout could be redirected and yet stdout would still be logged.
 * However, it's not clear why anyone would use log_file when these are
 * redirected in the first place.  On the other hand, it is reasonable to
 * run expect as a daemon in which case, stdin/out do not appear to be
 * ttys, yet it makes sense for them to be logged with log_file as if they
 * were.
 */
#if 0
#define real_tty_output(x) (exp_stdout_is_tty && (((x)==1) || ((x)==exp_dev_tty)))
#define real_tty_input(x) (exp_stdin_is_tty && (((x)==0) || ((x)==exp_dev_tty)))
#endif

#define real_tty_output(x) ((x->fdout == 1) || (expDevttyIs(x)))
#define real_tty_input(x) (exp_stdin_is_tty && ((x->fdin==0) || (expDevttyIs(x))))

#define new(x)	(x *)ckalloc(sizeof(x))

struct action {
	Tcl_Obj *statement;
	int tty_reset;		/* if true, reset tty mode upon action */
	int iread;		/* if true, reread indirects */
	int iwrite;		/* if true, write spawn_id element */
	struct action *next;	/* chain only for later for freeing */
};

struct keymap {
	Tcl_Obj *keys;	/* original pattern provided by user */
	int re;		/* true if looking to match a regexp. */
	int null;	/* true if looking to match 0 byte */
	int case_sensitive;
	int echo;	/* if keystrokes should be echoed */
	int writethru;	/* if keystrokes should go through to process */
	int indices;	/* true if should write indices */
	struct action action;
	struct keymap *next;
};

struct output {
	struct exp_i *i_list;
	struct action *action_eof;
	struct output *next;
};

struct input {
	struct exp_i *i_list;
	struct output *output;
	struct action *action_eof;
	struct action *action_timeout;
	struct keymap *keymap;
	int timeout_nominal;		/* timeout nominal */
	int timeout_remaining;		/* timeout remaining */
	struct input *next;
};

/*
 * Once we are handed an ExpState from the event handler, we can figure out
 * which "struct input *" it references by using expStateToInput.  This has is
 * populated by expCreateStateToInput.
 */

struct input *
expStateToInput(
    Tcl_HashTable *hash,
    ExpState *esPtr)
{
    Tcl_HashEntry *entry = Tcl_FindHashEntry(hash,(char *)esPtr);

    if (!entry) {
	/* should never happen */
	return 0;
    }
    return ((struct input *)Tcl_GetHashValue(entry));
}

void
expCreateStateToInput(
    Tcl_HashTable *hash,
    ExpState *esPtr,
    struct input *inp)
{
    Tcl_HashEntry *entry;
    int newPtr;

    entry = Tcl_CreateHashEntry(hash,(char *)esPtr,&newPtr);
    Tcl_SetHashValue(entry,(ClientData)inp);
}

static void free_input(Tcl_Interp *interp, struct input *i);
static void free_keymap(struct keymap *km);
static void free_output(Tcl_Interp *interp, struct output *o);
static void free_action(struct action *a);
static struct action *new_action(struct action **base);
static int inter_eval(
    Tcl_Interp *interp,
    struct action *action,
    ExpState *esPtr);

/* intMatch() accepts user keystrokes and returns one of MATCH,
CANMATCH, or CANTMATCH.  These describe whether the keystrokes match a
key sequence, and could or can't if more characters arrive.  The
function assigns a matching keymap if there is a match or can-match.
A matching keymap is assigned on can-match so we know whether to echo
or not.

intMatch is optimized (if you can call it that) towards a small
number of key mappings, but still works well for large maps, since no
function calls are made, and we stop as soon as there is a single-char
mismatch, and go on to the next one.  A hash table or compiled DFA
probably would not buy very much here for most maps.

The basic idea of how this works is it does a smart sequential search.
At each position of the input string, we attempt to match each of the
keymaps.  If at least one matches, the first match is returned.

If there is a CANMATCH and there are more keymaps to try, we continue
trying.  If there are no more keymaps to try, we stop trying and
return with an indication of the first keymap that can match.

Note that I've hacked up the regexp pattern matcher in two ways.  One
is to force the pattern to always be anchored at the front.  That way,
it doesn't waste time attempting to match later in the string (before
we're ready).  The other is to return can-match.

*/

static int
intMatch(
    ExpState *esPtr,
    struct keymap *keymap,	/* linked list of keymaps */
    struct keymap **km_match,	/* keymap that matches or can match */
    int *matchLen,		/* # of bytes that matched */
    int *skip,			/* # of chars to skip */
    Tcl_RegExpInfo *info)
{
    Tcl_UniChar *string;
    struct keymap *km;
    char *ks;		/* string from a keymap */

    Tcl_UniChar *start_search;	/* where in string to start searching */
    int offset;		/* # of chars from string to start searching */

    Tcl_UniChar *string_end;
    int numchars;
    int rm_nulls;		/* skip nulls if true */
    Tcl_UniChar ch;

    string   = esPtr->input.buffer;
    numchars = esPtr->input.use; /* Actually #chars */

    /* assert (*km == 0) */

    /* a shortcut that should help master output which typically */
    /* is lengthy and has no key maps.  Otherwise it would mindlessly */
    /* iterate on each character anyway. */
    if (!keymap) {
	*skip = numchars;
	return(EXP_CANTMATCH);
    }

    rm_nulls = esPtr->rm_nulls;

    string_end = string + numchars;

    /*
     * Maintain both a character index and a string pointer so we
     * can easily index into either the UTF or the Unicode representations.
     */

    for (start_search = string, offset = 0;
	 start_search < string_end;
	 start_search ++, offset++) {

	ch = *start_search;
	
	if (*km_match) break; /* if we've already found a CANMATCH */
			/* don't bother starting search from positions */
			/* further along the string */

	for (km=keymap;km;km=km->next) {
	    Tcl_UniChar *s;	/* current character being examined */

	    if (km->null) {
		if (ch == 0) {
		    *skip = start_search-string;
		    *matchLen = 1;	/* s - start_search == 1 */
		    *km_match = km;
		    return(EXP_MATCH);
	        }
	    } else if (!km->re) {
		int kslen;
		Tcl_UniChar sch, ksch;
		
		/* fixed string */

		ks = Tcl_GetString(km->keys);
		for (s = start_search;; s++, ks += kslen) {
		    /* if we hit the end of this map, must've matched! */
		    if (*ks == 0) {
			*skip = start_search-string;
			*matchLen = s-start_search;
			*km_match = km;
			return(EXP_MATCH);
		    }

		    /* if we ran out of user-supplied characters, and */
		    /* still haven't matched, it might match if the user */
		    /* supplies more characters next time */

		    if (s == string_end) {
			/* skip to next key entry, but remember */
			/* possibility that this entry might match */
			if (!*km_match) *km_match = km;
			break;
		    }

		    sch = *s;
		    kslen = Tcl_UtfToUniChar(ks, &ksch);
		    
		    if (sch == ksch) continue;
		    if ((sch == '\0') && rm_nulls) {
			kslen = 0;
			continue;
		    }
		    break;
		}
	    } else {
		/* regexp */
		Tcl_RegExp re;
		int flags;
		int result;
		Tcl_Obj* buf;

		re = Tcl_GetRegExpFromObj(NULL, km->keys,
			TCL_REG_ADVANCED|TCL_REG_BOSONLY|TCL_REG_CANMATCH);
		flags = (offset > 0) ? TCL_REG_NOTBOL : 0;

		/* ZZZ: Future optimization: Avoid copying */
		buf = Tcl_NewUnicodeObj (esPtr->input.buffer, esPtr->input.use);
		Tcl_IncrRefCount (buf);
		result = Tcl_RegExpExecObj(NULL, re, buf, offset,
			-1 /* nmatches */, flags);
		Tcl_DecrRefCount (buf);
		if (result > 0) {
		    *km_match = km;
		    *skip = start_search-string;
		    Tcl_RegExpGetInfo(re, info);
		    *matchLen = info->matches[0].end;
		    return EXP_MATCH;
		} else if (result == 0) {
		    Tcl_RegExpGetInfo(re, info);

		    /*
		     * Check to see if there was a partial match starting
		     * at the current character.
		     */
		    if (info->extendStart == 0) {
			if (!*km_match) *km_match = km;
		    }
		}		    
	    }
	}
    }

    if (*km_match) {
	/* report CANMATCH for -re and -ex */

	/*
	 * since canmatch is only detected after we've advanced too far,
	 * adjust start_search back to make other computations simpler
	 */
	start_search--;

	*skip = start_search - string;
	*matchLen = string_end - start_search;
	return(EXP_CANMATCH);
    }
    
    *skip = start_search-string;
    return(EXP_CANTMATCH);
}

/* put regexp result in variables */
static void
intRegExpMatchProcess(
    Tcl_Interp *interp,
    ExpState *esPtr,
    struct keymap *km,	/* ptr for above while parsing */
    Tcl_RegExpInfo *info,
    int offset)
{
    char name[20], value[20];
    int i;
    Tcl_Obj* buf = Tcl_NewUnicodeObj (esPtr->input.buffer,esPtr->input.use);

    for (i=0;i<=info->nsubs;i++) {
	int start, end;
	Tcl_Obj *val;

	start = info->matches[i].start + offset;
	if (start == -1) continue;
	end = (info->matches[i].end-1) + offset;

	if (km->indices) {
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
	expDiagLog("interact: set %s(%s) \"",INTER_OUT,name);
	expDiagLogU(expPrintifyObj(val));
	expDiagLogU("\"\r\n");
	Tcl_SetVar2Ex(interp,INTER_OUT,name,val,0);
    }
    Tcl_DecrRefCount (buf);
}

/*
 * echo chars
 */ 
static void
intEcho(
    ExpState *esPtr,
    int skipBytes,
    int matchBytes)
{
    int seenBytes;	/* either printed or echoed */
    int echoBytes;
    int offsetBytes;

    /* write is unlikely to fail, since we just read from same descriptor */
    seenBytes = esPtr->printed + esPtr->echoed;
    if (skipBytes >= seenBytes) {
	echoBytes = matchBytes;
	offsetBytes = skipBytes;
    } else if ((matchBytes + skipBytes - seenBytes) > 0) {
	echoBytes = matchBytes + skipBytes - seenBytes;
	offsetBytes = seenBytes;
    }

    (void) expWriteCharsUni(esPtr,
			    esPtr->input.buffer + offsetBytes,
		   echoBytes);

    esPtr->echoed = matchBytes + skipBytes - esPtr->printed;
}

/*
 * intRead() does the logical equivalent of a read() for the interact command.
 * Returns # of bytes read or negative number (EXP_XXX) indicating unusual event.
 */
static int
intRead(
    Tcl_Interp *interp,
    ExpState *esPtr,
    int warnOnBufferFull,
    int interruptible,
    int key)
{
    Tcl_UniChar *eobOld;  /* old end of buffer */
    int cc;
    int numchars;
    Tcl_UniChar *str;

    str      = esPtr->input.buffer;
    numchars = esPtr->input.use;
    eobOld   = str + numchars;

    /* We drop one third when are at least 2/3 full */
    /* condition is (size >= max*2/3) <=> (size*3 >= max*2) */
    if (numchars*3 >= esPtr->input.max*2) {
	/*
	 * In theory, interact could be invoked when this situation
	 * already exists, hence the "probably" in the warning below
	 */
	if (warnOnBufferFull) {
	    expDiagLogU("WARNING: interact buffer is full, probably because your\r\n");
	    expDiagLogU("patterns have matched all of it but require more chars\r\n");
	    expDiagLogU("in order to complete the match.\r\n");
	    expDiagLogU("Dumping first half of buffer in order to continue\r\n");
	    expDiagLogU("Recommend you enlarge the buffer or fix your patterns.\r\n");
	}
	exp_buffer_shuffle(interp,esPtr,0,INTER_OUT,"interact");
    }
    if (!interruptible) {
        cc = Tcl_ReadChars(esPtr->channel, esPtr->input.newchars,
			   esPtr->input.max - esPtr->input.use,
			   0 /* no append */);
    } else {
#ifdef SIMPLE_EVENT
        cc = intIRead(esPtr->channel, esPtr->input.newchars,
		      esPtr->input.max - esPtr->input.use,
		      0 /* no append */);
#endif
    }

    if (cc > 0) {
        memcpy (esPtr->input.buffer + esPtr->input.use,
		Tcl_GetUnicodeFromObj (esPtr->input.newchars, NULL),
		cc * sizeof (Tcl_UniChar));
	esPtr->input.use += cc;

	expDiagLog("spawn id %s sent <",esPtr->name);
	expDiagLogU(expPrintifyUni(eobOld,cc));
	expDiagLogU(">\r\n");

	esPtr->key = key;
    }
    return cc;
}



#ifdef SIMPLE_EVENT

/*

The way that the "simple" interact works is that the original Expect
process reads from the tty and writes to the spawned process.  A child
process is forked to read from the spawned process and write to the
tty.  It looks like this:

                        user
                    --> tty >--
                   /           \
                  ^             v
                child        original
               process        Expect
                  ^          process
                  |             v
                   \           /
                    < spawned <
                      process

*/



#ifndef WEXITSTATUS
#define WEXITSTATUS(stat) (((*((int *) &(stat))) >> 8) & 0xff)
#endif

#include <setjmp.h>

#ifdef HAVE_SIGLONGJMP
static sigjmp_buf env;                /* for interruptable read() */
#else
static jmp_buf env;		/* for interruptable read() */
#endif  /* HAVE_SIGLONGJMP */

static int reading;		/* while we are reading */
				/* really, while "env" is valid */
static int deferred_interrupt = FALSE;	/* if signal is received, but not */
				/* in expIRead record this here, so it will */
				/* be handled next time through expIRead */

static void
sigchld_handler()
{
  if (reading) {
#ifdef HAVE_SIGLONGJMP
     siglongjmp(env,1);
#else
    longjmp(env,1);
#endif  /* HAVE_SIGLONGJMP */
  }
  deferred_interrupt = TRUE;
}

#define EXP_CHILD_EOF -100

/*
 * Name: expIRead, do an interruptable read
 *
 * intIRead() reads from chars from the user.
 *
 * It returns early if it detects the death of a proc (either the spawned
 * process or the child (surrogate).
 */
static int
intIRead(
    Tcl_Channel channel,
    Tcl_Obj *obj,
    int size,
    int flags)
{
    int cc = EXP_CHILD_EOF;

    if (deferred_interrupt) return(cc);

    if (
#ifdef HAVE_SIGLONGJMP
	0 == sigsetjmp(env,1)
#else
	0 == setjmp(env)
#endif  /* HAVE_SIGLONGJMP */
	) {
	reading = TRUE;
	cc = Tcl_ReadChars(channel,obj,size,flags);
    }
    reading = FALSE;
    return(cc);
}

/* exit status for the child process created by cmdInteract */
#define CHILD_DIED		-2
#define SPAWNED_PROCESS_DIED	-3

static void
clean_up_after_child(
    Tcl_Interp *interp,
    ExpState *esPtr)
{
    expWaitOnOne(); /* wait for slave */
    expWaitOnOne(); /* wait for child */

    deferred_interrupt = FALSE;
    if (esPtr->close_on_eof) {
    exp_close(interp,esPtr);
}
}
#endif /*SIMPLE_EVENT*/

static int
update_interact_fds(
    Tcl_Interp *interp,
    int *esPtrCount,
    Tcl_HashTable **esPtrToInput,	/* map from ExpStates to "struct inputs" */
    ExpState ***esPtrs,
    struct input *input_base,
    int do_indirect,		/* if true do indirects */
    int *config_count,
    int *real_tty_caller)
{
	struct input *inp;
	struct output *outp;
	struct exp_state_list *fdp;
	int count;

	int real_tty = FALSE;

	*config_count = exp_configure_count;

	count = 0;
	for (inp = input_base;inp;inp=inp->next) {

		if (do_indirect) {
			/* do not update "direct" entries (again) */
			/* they were updated upon creation */
			if (inp->i_list->direct == EXP_INDIRECT) {
				exp_i_update(interp,inp->i_list);
			}
			for (outp = inp->output;outp;outp=outp->next) {
				if (outp->i_list->direct == EXP_INDIRECT) {
					exp_i_update(interp,outp->i_list);
				}
			}
		}

		/* revalidate all input descriptors */
		for (fdp = inp->i_list->state_list;fdp;fdp=fdp->next) {
		    count++;
		    /* have to "adjust" just in case spawn id hasn't had */
		    /* a buffer sized yet */
		    if (!expStateCheck(interp,fdp->esPtr,1,1,"interact")) {
			return(TCL_ERROR);
		    }
		}

		/* revalidate all output descriptors */
		for (outp = inp->output;outp;outp=outp->next) {
			for (fdp = outp->i_list->state_list;fdp;fdp=fdp->next) {
				/* make user_spawn_id point to stdout */
			    if (!expStdinoutIs(fdp->esPtr)) {
				if (!expStateCheck(interp,fdp->esPtr,1,0,"interact"))
				    return(TCL_ERROR);
			    }
			}
		}
	}
	if (!do_indirect) return TCL_OK;

	if (*esPtrToInput == 0) {
	    *esPtrToInput = (Tcl_HashTable *)ckalloc(sizeof(Tcl_HashTable));
	    *esPtrs = (ExpState **)ckalloc(count * sizeof(ExpState *));
	} else {
	    /* if hash table already exists, delete it and start over */
	    Tcl_DeleteHashTable(*esPtrToInput);
	    *esPtrs = (ExpState **)ckrealloc((char *)*esPtrs,count * sizeof(ExpState *));
	}
	Tcl_InitHashTable(*esPtrToInput,TCL_ONE_WORD_KEYS);

	count = 0;
	for (inp = input_base;inp;inp=inp->next) {
	    for (fdp = inp->i_list->state_list;fdp;fdp=fdp->next) {
		/* build map to translate from spawn_id to struct input */
		expCreateStateToInput(*esPtrToInput,fdp->esPtr,inp);

		/* build input to ready() */
		(*esPtrs)[count] = fdp->esPtr;

		if (real_tty_input(fdp->esPtr)) real_tty = TRUE;

		count++;
	    }
	}
	*esPtrCount = count;

	*real_tty_caller = real_tty; /* tell caller if we have found that */
					/* we are using real tty */

	return TCL_OK;
}

/*ARGSUSED*/
static char *
inter_updateproc(
    ClientData clientData,
    Tcl_Interp *interp,	/* Interpreter containing variable. */
    char *name1,	/* Name of variable. */
    char *name2,	/* Second part of variable name. */
    int flags)		/* Information about what happened. */
{
	exp_configure_count++;
	return 0;
}
			
#define finish(x)	{ status = x; goto done; }

static char return_cmd[] = "return";
static char interpreter_cmd[] = "interpreter";

/*ARGSUSED*/
int
Exp_InteractObjCmd(
    ClientData clientData,
    Tcl_Interp *interp,
    int objc,
    Tcl_Obj *CONST initial_objv[])		/* Argument objects. */
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    Tcl_Obj *CONST *objv_copy;	/* original, for error messages */
    Tcl_Obj **objv = (Tcl_Obj **) initial_objv;
    char *string;
    Tcl_UniChar *ustring;

#ifdef SIMPLE_EVENT
    int pid;
#endif /*SIMPLE_EVENT*/

    /*declarations*/
    int input_count;	/* count of struct input descriptors */

    Tcl_HashTable *esPtrToInput = 0;	/* map from ExpState to "struct inputs" */
    ExpState **esPtrs;
    struct keymap *km;	/* ptr for above while parsing */
    Tcl_RegExpInfo reInfo;
    ExpState *u = 0;
    ExpState *esPtr = 0;
    Tcl_Obj *chanName = 0;
    int need_to_close_master = FALSE;	/* if an eof is received */
				/* we use this to defer close until later */

    int next_tty_reset = FALSE;	/* if we've seen a single -reset */
    int next_iread = FALSE;/* if we've seen a single -iread */
    int next_iwrite = FALSE;/* if we've seen a single -iread */
    int next_re = FALSE;	/* if we've seen a single -re */
    int next_null = FALSE;	/* if we've seen the null keyword */
    int next_writethru = FALSE;/*if macros should also go to proc output */
    int next_indices = FALSE;/* if we should write indices */
    int next_echo = FALSE;	/* if macros should be echoed */
    int status = TCL_OK;	/* final return value */
    int i;			/* misc temp */
    int size;			/* size temp */

    int timeout_simple = TRUE;	/* if no or global timeout */

    int real_tty;		/* TRUE if we are interacting with real tty */
    int tty_changed = FALSE;/* true if we had to change tty modes for */
				/* interact to work (i.e., to raw, noecho) */
    int was_raw;
    int was_echo;
    exp_tty tty_old;

    Tcl_Obj *replace_user_by_process = 0; /* for -u flag */

    struct input *input_base;
#define input_user input_base
    struct input *input_default;
    struct input *inp;	/* overused ptr to struct input */
    struct output *outp;	/* overused ptr to struct output */

    int dash_input_count = 0; /* # of "-input"s seen */
    int dash_o_count = 0; /* # of "-o"s seen */
    int arbitrary_timeout;
    int default_timeout;
    struct action action_timeout;	/* common to all */
    struct action action_eof;	/* common to all */
    struct action **action_eof_ptr;	/* allow -input/ouput to */
		/* leave their eof-action assignable by a later */
		/* -eof */
    struct action *action_base = 0;
    struct keymap **end_km;

    int key;
    int configure_count;	/* monitor reconfigure events */
    Tcl_Obj* new_cmd = NULL;

    if ((objc == 2) && exp_one_arg_braced(objv[1])) {
	/* expect {...} */

	new_cmd = exp_eval_with_one_arg(clientData,interp,objv);
	if (!new_cmd) return TCL_ERROR;

	/* Replace old arguments with result of reparse */
	Tcl_ListObjGetElements (interp, new_cmd, &objc, &objv);

    } else if ((objc == 3) && streq(Tcl_GetString(objv[1]),"-brace")) {
	/* expect -brace {...} ... fake command line for reparsing */

	Tcl_Obj *new_objv[2];
	new_objv[0] = objv[0];
	new_objv[1] = objv[2];

	new_cmd = exp_eval_with_one_arg(clientData,interp,new_objv);
	if (!new_cmd) return TCL_ERROR;
	/* Replace old arguments with result of reparse */
	Tcl_ListObjGetElements (interp, new_cmd, &objc, &objv);
    }

    objv_copy = objv;

    objv++;
    objc--;

    default_timeout = EXP_TIME_INFINITY;
    arbitrary_timeout = EXP_TIME_INFINITY;	/* if user specifies */
		/* a bunch of timeouts with EXP_TIME_INFINITY, this will be */
		/* left around for us to find. */

    input_user = new(struct input);
    input_user->i_list = exp_new_i_simple(expStdinoutGet(),EXP_TEMPORARY); /* stdin by default */
    input_user->output = 0;
    input_user->action_eof = &action_eof;
    input_user->timeout_nominal = EXP_TIME_INFINITY;
    input_user->action_timeout = 0;
    input_user->keymap = 0;

    end_km = &input_user->keymap;
    inp = input_user;
    action_eof_ptr = &input_user->action_eof;

    input_default = new(struct input);
    input_default->i_list = exp_new_i_simple((ExpState *)0,EXP_TEMPORARY); /* fix up later */
    input_default->output = 0;
    input_default->action_eof = &action_eof;
    input_default->timeout_nominal = EXP_TIME_INFINITY;
    input_default->action_timeout = 0;
    input_default->keymap = 0;
    input_default->next = 0;		/* no one else */
    input_user->next = input_default;

    /* default and common -eof action */
    action_eof.statement = tsdPtr->cmdObjReturn;
    action_eof.tty_reset = FALSE;
    action_eof.iread = FALSE;
    action_eof.iwrite = FALSE;

    /*
     * Parse the command arguments.
     */
    for (;objc>0;objc--,objv++) {
	string = Tcl_GetString(*objv);
	if (string[0] == '-') {
	    static char *switches[] = {
		"--",		"-exact",	"-re",		"-input",
		"-output",	"-u",		"-o",		"-i",
		"-echo",	"-nobuffer",	"-indices",	"-f",
		"-reset",	"-F",		"-iread",	"-iwrite",
		"-eof",		"-timeout",	"-nobrace",	(char *)0
	    };
	    enum switches {
		EXP_SWITCH_DASH,	EXP_SWITCH_EXACT,
		EXP_SWITCH_REGEXP,	EXP_SWITCH_INPUT,
		EXP_SWITCH_OUTPUT,	EXP_SWITCH_USER,
		EXP_SWITCH_OPPOSITE,	EXP_SWITCH_SPAWN_ID,
		EXP_SWITCH_ECHO,	EXP_SWITCH_NOBUFFER,
		EXP_SWITCH_INDICES,	EXP_SWITCH_FAST,
		EXP_SWITCH_RESET,	EXP_SWITCH_CAPFAST,
		EXP_SWITCH_IREAD,	EXP_SWITCH_IWRITE,
		EXP_SWITCH_EOF,		EXP_SWITCH_TIMEOUT,
		EXP_SWITCH_NOBRACE
	    };
	    int index;

	    /*
	     * Allow abbreviations of switches and report an error if we
	     * get an invalid switch.
	     */

	    if (Tcl_GetIndexFromObj(interp, *objv, switches, "switch", 0,
		    &index) != TCL_OK) {
		goto error;
	    }
	    switch ((enum switches) index) {
		case EXP_SWITCH_DASH:
		case EXP_SWITCH_EXACT:
		    objc--;
		    objv++;
		    goto pattern;
		case EXP_SWITCH_REGEXP:
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"-re pattern");
		    goto error;
		    }
		    next_re = TRUE;
		    objc--;
		    objv++;

		    /*
		     * Try compiling the expression so we can report
		     * any errors now rather then when we first try to
		     * use it.
		     */

		    if (!(Tcl_GetRegExpFromObj(interp, *objv,
			    TCL_REG_ADVANCED|TCL_REG_BOSONLY))) {
		    goto error;
		    }
		    goto pattern;
		case EXP_SWITCH_INPUT:
		    dash_input_count++;
		    if (dash_input_count == 2) {
			inp = input_default;
			input_user->next = input_default;
		    } else if (dash_input_count > 2) {
			struct input *previous_input = inp;
			inp = new(struct input);
			previous_input->next = inp;
		    }
		    inp->output = 0;
		    inp->action_eof = &action_eof;
		    action_eof_ptr = &inp->action_eof;
		    inp->timeout_nominal = default_timeout;
		    inp->action_timeout = &action_timeout;
		    inp->keymap = 0;
		    end_km = &inp->keymap;
		    inp->next = 0;
		    objc--;objv++;
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"-input spawn_id");
		    goto error;
		    }
		    inp->i_list = exp_new_i_complex(interp,Tcl_GetString(*objv),
			    EXP_TEMPORARY,inter_updateproc);
		if (!inp->i_list) {
		    goto error;
		}
		    break;
		case EXP_SWITCH_OUTPUT: {
		    struct output *tmp;

		    /* imply a "-input" */
		    if (dash_input_count == 0) dash_input_count = 1;

		    outp = new(struct output);

				/* link new output in front of others */
		    tmp = inp->output;
		    inp->output = outp;
		    outp->next = tmp;

		    objc--;objv++;
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"-output spawn_id");
		    goto error;
		    }
		    outp->i_list = exp_new_i_complex(interp,Tcl_GetString(*objv),
			    EXP_TEMPORARY,inter_updateproc);
		if (!outp->i_list) {
		    goto error;
		}
		    outp->action_eof = &action_eof;
		    action_eof_ptr = &outp->action_eof;
		    break;
		}
		case EXP_SWITCH_USER:
		    objc--;objv++;
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"-u spawn_id");
		    goto error;
		    }
		    replace_user_by_process = *objv;

		    /* imply a "-input" */
		    if (dash_input_count == 0) dash_input_count = 1;
		    break;
		case EXP_SWITCH_OPPOSITE:
		    /* apply following patterns to opposite side */
		    /* of interaction */

		    end_km = &input_default->keymap;

		    if (dash_o_count > 0) {
			exp_error(interp,"cannot use -o more than once");
			goto error;
		    }
		    dash_o_count++;

		    /* imply two "-input" */
		    if (dash_input_count < 2) {
		      dash_input_count = 2;
		      inp = input_default;
		      action_eof_ptr = &inp->action_eof;
		    }
		    break;
		case EXP_SWITCH_SPAWN_ID:
		    /* substitute master */

		    objc--;objv++;
		    chanName = *objv;
		    /* will be used later on */

		    end_km = &input_default->keymap;

		    /* imply two "-input" */
		    if (dash_input_count < 2) {
			dash_input_count = 2;
			inp = input_default;
			action_eof_ptr = &inp->action_eof;
		    }
		    break;
		case EXP_SWITCH_ECHO:
		    next_echo = TRUE;
		    break;
		case EXP_SWITCH_NOBUFFER:
		    next_writethru = TRUE;
		    break;
		case EXP_SWITCH_INDICES:
		    next_indices = TRUE;
		    break;
		case EXP_SWITCH_RESET:
		    next_tty_reset = TRUE;
		    break;
		case EXP_SWITCH_IREAD:
		    next_iread = TRUE;
		    break;
		case EXP_SWITCH_IWRITE:
			next_iwrite= TRUE;
		    break;
		case EXP_SWITCH_EOF: {
		    struct action *action;

		    objc--;objv++;
		    expDiagLogU("-eof is deprecated, use eof\r\n");
		    *action_eof_ptr = action = new_action(&action_base);
		    action->statement = *objv;
		    action->tty_reset = next_tty_reset;
		    next_tty_reset = FALSE;
		    action->iwrite = next_iwrite;
		    next_iwrite = FALSE;
		    action->iread = next_iread;
		    next_iread = FALSE;
		    break;
		}
		case EXP_SWITCH_TIMEOUT: {
		    int t;
		    struct action *action;
		    expDiagLogU("-timeout is deprecated, use timeout\r\n");

		    objc--;objv++;
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"-timeout time");
			goto error;
		    }

		    if (Tcl_GetIntFromObj(interp, *objv, &t) != TCL_OK) {
		    goto error;
		    }
		    objc--;objv++;
		    if (t != -1)
			arbitrary_timeout = t;
		    /* we need an arbitrary timeout to start */
		    /* search for lowest one later */

		    timeout_simple = FALSE;
		    action = inp->action_timeout = new_action(&action_base);
		    inp->timeout_nominal = t;

		    action->statement = *objv;
		    action->tty_reset = next_tty_reset;
		    next_tty_reset = FALSE;
		    action->iwrite = next_iwrite;
		    next_iwrite = FALSE;
		    action->iread = next_iread;
		    next_iread = FALSE;
		    break;
		}
		case EXP_SWITCH_FAST:
		case EXP_SWITCH_CAPFAST:
		    /* noop compatibility switches for fast mode */
		    break;
		case EXP_SWITCH_NOBRACE:
		    /* nobrace does nothing but take up space */
		    /* on the command line which prevents */
		    /* us from re-expanding any command lines */
		    /* of one argument that looks like it should */
		    /* be expanded to multiple arguments. */
		    break;
	    }
	    continue;
    	} else {
	    static char *options[] = {
		"eof", "timeout", "null", (char *)0
	    };
	    enum options {
		EXP_OPTION_EOF, EXP_OPTION_TIMEOUT, EXP_OPTION_NULL
	    };
	    int index;

	    /*
	     * Match keywords exactly, otherwise they are patterns.
	     */

	    if (Tcl_GetIndexFromObj(interp, *objv, options, "option",
		    1 /* exact */, &index) != TCL_OK) {
		Tcl_ResetResult(interp);
		goto pattern;
	    }
	    switch ((enum options) index) {
		case EXP_OPTION_EOF: {
		    struct action *action;

		    objc--;objv++;
		    *action_eof_ptr = action = new_action(&action_base);

		    action->statement = *objv;

		    action->tty_reset = next_tty_reset;
		    next_tty_reset = FALSE;
		    action->iwrite = next_iwrite;
		    next_iwrite = FALSE;
		    action->iread = next_iread;
		    next_iread = FALSE;
		    break;
		}
		case EXP_OPTION_TIMEOUT: {
		    int t;
		    struct action *action;

		    objc--;objv++;
		    if (objc < 1) {
			Tcl_WrongNumArgs(interp,1,objv_copy,"timeout time [action]");
		    goto error;
		    }
		    if (Tcl_GetIntFromObj(interp, *objv, &t) != TCL_OK) {
		    goto error;
		    }
		    objc--;objv++;

		    /* we need an arbitrary timeout to start */
		    /* search for lowest one later */
		    if (t != -1) arbitrary_timeout = t;

		    timeout_simple = FALSE;
		    action = inp->action_timeout = new_action(&action_base);
		    inp->timeout_nominal = t;

		    if (objc >= 1) {
		      action->statement = *objv;
		    } else {
		      action->statement = 0;
		    }

		    action->tty_reset = next_tty_reset;
		    next_tty_reset = FALSE;
		    action->iwrite = next_iwrite;
		    next_iwrite = FALSE;
		    action->iread = next_iread;
		    next_iread = FALSE;
		    break;
		}
		case EXP_OPTION_NULL:
		    next_null = TRUE;
		    goto pattern;
	    }
	    continue;
	}
    
	/*
	 * pick up the pattern
	 */

	pattern:
	km = new(struct keymap);

	/* so that we can match in order user specified */
	/* link to end of keymap list */
	*end_km = km;
	km->next = 0;
	end_km = &km->next;

	km->echo = next_echo;
	km->writethru = next_writethru;
	km->indices = next_indices;
	km->action.tty_reset = next_tty_reset;
	km->action.iwrite = next_iwrite;
	km->action.iread = next_iread;

	next_indices = next_echo = next_writethru = FALSE;
	next_tty_reset = FALSE;
	next_iwrite = next_iread = FALSE;

	km->keys = *objv;

	km->null = FALSE;
	km->re = 0;
	if (next_re) {
	    km->re = TRUE;
	    next_re = FALSE;
	}
	if (next_null) {
	    km->null = TRUE;
	    next_null = FALSE;
	}

	objc--;objv++;
	if (objc >= 1) {
	    km->action.statement = *objv;
	} else {
	    km->action.statement = 0;
	}

	expDiagLogU("defining key ");
	expDiagLogU(Tcl_GetString(km->keys));
	expDiagLogU(", action ");
	expDiagLogU(km->action.statement?expPrintify(Tcl_GetString(km->action.statement)):"interpreter");
	expDiagLogU("\r\n");

	/* imply a "-input" */
	if (dash_input_count == 0) dash_input_count = 1;
    }

    /* if the user has not supplied either "-output" for the */
    /* default two "-input"s, fix them up here */

    if (!input_user->output) {
	struct output *o = new(struct output);
	if (!chanName) {
	    if (!(esPtr = expStateCurrent(interp,1,1,0))) {
		goto error;
	    }
	    o->i_list = exp_new_i_simple(esPtr,EXP_TEMPORARY);
	} else {
	    o->i_list = exp_new_i_complex(interp,Tcl_GetString(chanName),
		    EXP_TEMPORARY,inter_updateproc);
	    if (!o->i_list) {
		goto error;
	    }
	}
	o->next = 0;	/* no one else */
	o->action_eof = &action_eof;
	input_user->output = o;
    }

    if (!input_default->output) {
	struct output *o = new(struct output);
	o->i_list = exp_new_i_simple(expStdinoutGet(),EXP_TEMPORARY);/* stdout by default */
	o->next = 0;	/* no one else */
	o->action_eof = &action_eof;
	input_default->output = o;
    }

    /* if user has given "-u" flag, substitute process for user */
    /* in first two -inputs */
    if (replace_user_by_process) {
	/* through away old ones */
	exp_free_i(interp,input_user->i_list,   inter_updateproc);
	exp_free_i(interp,input_default->output->i_list,inter_updateproc);

	/* replace with arg to -u */
	input_user->i_list = exp_new_i_complex(interp,
		Tcl_GetString(replace_user_by_process),
		EXP_TEMPORARY,inter_updateproc);
	if (!input_user->i_list) 
	    goto error;
	input_default->output->i_list = exp_new_i_complex(interp,
		Tcl_GetString(replace_user_by_process),
		EXP_TEMPORARY,inter_updateproc);
	if (!input_default->output->i_list) 
	    goto error;
    }

    /*
     * now fix up for default spawn id
     */

    /* user could have replaced it with an indirect, so force update */
    if (input_default->i_list->direct == EXP_INDIRECT) {
	exp_i_update(interp,input_default->i_list);
    }

    if (input_default->i_list->state_list
	    && (input_default->i_list->state_list->esPtr == EXP_SPAWN_ID_BAD)) {
	if (!chanName) {
	    if (!(esPtr = expStateCurrent(interp,1,1,0))) {
		goto error;
	    }
	    input_default->i_list->state_list->esPtr = esPtr;
	} else {
	    /* discard old one and install new one */
	    exp_free_i(interp,input_default->i_list,inter_updateproc);
	    input_default->i_list = exp_new_i_complex(interp,Tcl_GetString(chanName),
		    EXP_TEMPORARY,inter_updateproc);
	    if (!input_default->i_list)
		goto error;
	}
    }

    /*
     * check for user attempting to interact with self
     * they're almost certainly just fooling around
     */

    /* user could have replaced it with an indirect, so force update */
    if (input_user->i_list->direct == EXP_INDIRECT) {
	exp_i_update(interp,input_user->i_list);
    }

    if (input_user->i_list->state_list && input_default->i_list->state_list
	    && (input_user->i_list->state_list->esPtr == input_default->i_list->state_list->esPtr)) {
	exp_error(interp,"cannot interact with self - set spawn_id to a spawned process");
	goto error;
    }

    esPtrs = 0;

    /*
     * all data structures are sufficiently set up that we can now
     * "finish()" to terminate this procedure
     */

    status = update_interact_fds(interp,&input_count,&esPtrToInput,&esPtrs,input_base,1,&configure_count,&real_tty);
    if (status == TCL_ERROR) finish(TCL_ERROR);

    if (real_tty) {
	tty_changed = exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);
    }

    for (inp = input_base,i=0;inp;inp=inp->next,i++) {
	/* start timers */
	inp->timeout_remaining = inp->timeout_nominal;
    }

    key = expect_key++;

    /* declare ourselves "in sync" with external view of close/indirect */
    configure_count = exp_configure_count;
    
#ifndef SIMPLE_EVENT
    /* loop waiting (in event handler) for input */
    for (;;) {
	int te;	/* result of Tcl_Eval */
	int rc;	/* return code from ready.  This is further refined by matcher. */
	int cc;			/* # of chars from read() */
	struct action *action = 0;
	time_t previous_time;
	time_t current_time;
	int matchLen;	/* # of chars matched */
	int skip;		/* # of chars not involved in match */
	int print;		/* # of chars to print */
	int oldprinted;		/* old version of u->printed */
	int change;		/* if action requires cooked mode */
	int attempt_match = TRUE;
	struct input *soonest_input;
	int timeout;	/* current as opposed to default_timeout */
	Tcl_Time temp_time;

	/* calculate how long to wait */
	/* by finding shortest remaining timeout */
	if (timeout_simple) {
	    timeout = default_timeout;
	} else {
	    timeout = arbitrary_timeout;

	    for (inp=input_base;inp;inp=inp->next) {
		if ((inp->timeout_remaining != EXP_TIME_INFINITY) &&
			(inp->timeout_remaining <= timeout)) {
		    soonest_input = inp;
		    timeout = inp->timeout_remaining;
		}
	    }

	    Tcl_GetTime (&temp_time);
	    previous_time = temp_time.sec;
	    /* timestamp here rather than simply saving old */
	    /* current time (after ready()) to account for */
	    /* possibility of slow actions */
	    
	    /* timeout can actually be EXP_TIME_INFINITY here if user */
	    /* explicitly supplied it in a few cases (or */
	    /* the count-down code is broken) */
	}

	/* update the world, if necessary */
	if (configure_count != exp_configure_count) {
	    status = update_interact_fds(interp,&input_count,
		    &esPtrToInput,&esPtrs,input_base,1,
		    &configure_count,&real_tty);
	    if (status) finish(status);
	}

	rc = exp_get_next_event(interp,esPtrs,input_count,&u,timeout,key);
	if (rc == EXP_TCLERROR)
	    goto error;
	if (rc == EXP_RECONFIGURE) continue;
	if (rc == EXP_TIMEOUT) {
	    if (timeout_simple) {
		action = &action_timeout;
		goto got_action;
	    } else {
		action = soonest_input->action_timeout;
		/* arbitrarily pick first fd out of list */
		u = soonest_input->i_list->state_list->esPtr;
	    }
	}
	if (!timeout_simple) {
	    int time_diff;

	    Tcl_GetTime (&temp_time);
	    current_time = temp_time.sec;
	    time_diff = current_time - previous_time;

	    /* update all timers */
	    for (inp=input_base;inp;inp=inp->next) {
		if (inp->timeout_remaining != EXP_TIME_INFINITY) {
		    inp->timeout_remaining -= time_diff;
		    if (inp->timeout_remaining < 0)
			inp->timeout_remaining = 0;
		}
	    }
	}

	/* at this point, we have some kind of event which can be */
	/* immediately processed - i.e. something that doesn't block */

	/* figure out who we are */
	inp = expStateToInput(esPtrToInput,u);

	/* reset timer */
	inp->timeout_remaining = inp->timeout_nominal;

	switch (rc) {
	    case EXP_DATA_NEW:
		cc = intRead(interp,u,1,0,key);
		if (cc > 0 || Tcl_InputBlocked(u->channel)) break;

		rc = EXP_EOF;
		/*
		 * FALLTHRU
		 *
		 * Most systems have read() return 0, allowing
		 * control to fall thru and into this code.  On some
		 * systems (currently HP and new SGI), read() does
		 * see eof, and it must be detected earlier.  Then
		 * control jumps directly to this EXP_EOF label.
		 */
	    case EXP_EOF:
		action = inp->action_eof;
		attempt_match = FALSE;
		skip = expSizeGet(u);
		expDiagLog("interact: received eof from spawn_id %s\r\n",u->name);
		/* actual close is done later so that we have a */
		/* chance to flush out any remaining characters */
		need_to_close_master = TRUE;
		break;
	    case EXP_DATA_OLD:
		cc = 0;
		break;
	    case EXP_TIMEOUT:
		action = inp->action_timeout;
		attempt_match = FALSE;
		skip = expSizeGet(u);
		break;
	}

	km = 0;

	if (attempt_match) {
	    rc = intMatch(u,inp->keymap,&km,&matchLen,&skip,&reInfo);
	    if ((rc == EXP_MATCH) && km && km->re) {
		intRegExpMatchProcess(interp,u,km,&reInfo,skip);
	    }
	} else {
	    attempt_match = TRUE;
	}

	/*
	 * dispose of chars that should be skipped
	 * i.e., chars that cannot possibly be part of a match.
	 */
	if (km && km->writethru) {
	    print = skip + matchLen;
	} else print = skip;

	if (km && km->echo) {
	    intEcho(u,skip,matchLen);
	}
	oldprinted = u->printed;

	/*
	 * If expect has left characters in buffer, it has
	 * already echoed them to the screen, thus we must
	 * prevent them being rewritten.  Unfortunately this
	 * gives the possibility of matching chars that have
	 * already been output, but we do so since the user
	 * could have avoided it by flushing the output
	 * buffers directly.
	 */
	if (print > u->printed) {	/* usual case */
	    for (outp = inp->output;outp;outp=outp->next) {
		struct exp_state_list *fdp;
		for (fdp = outp->i_list->state_list;fdp;fdp=fdp->next) {
		    /* send to channel (and log if chan is stdout or devtty) */
		    /*
		     * Following should eventually be rewritten to ...WriteCharsAnd...
		     */
		    int wc = expWriteBytesAndLogIfTtyU(fdp->esPtr,
						       u->input.buffer + u->printed,
			    print - u->printed);
		    if (wc < 0) {
			expDiagLog("interact: write on spawn id %s failed (%s)\r\n",fdp->esPtr->name,Tcl_PosixError(interp));
			action = outp->action_eof;
			change = (action && action->tty_reset);
			
			if (change && tty_changed)
			    exp_tty_set(interp,&tty_old,was_raw,was_echo);
			te = inter_eval(interp,action,u);

			if (change && real_tty) tty_changed =
						    exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);
			switch (te) {
			    case TCL_BREAK:
			    case TCL_CONTINUE:
				finish(te);
			    case EXP_TCL_RETURN:
				finish(TCL_RETURN);
			    case TCL_RETURN:
				finish(TCL_OK);
			    case TCL_OK:
				/* god knows what the user might */
				/* have done to us in the way of */
				/* closed fds, so .... */
				action = 0;	/* reset action */
				continue;
			    default:
				finish(te);
			}
		    }
		}
	    }
	    u->printed = print;
	}
	
	/* u->printed is now accurate with respect to the buffer */
	/* However, we're about to shift the old data out of the */
	/* buffer.  Thus size, printed, and echoed must be */
	/* updated */
	
	/* first update size based on skip information */
	/* then set skip to the total amount skipped */

	size = expSizeGet(u);
	if (rc == EXP_MATCH) {
	    action = &km->action;

	    skip += matchLen;
	    size -= skip;
	    if (size) {
		ustring = u->input.buffer;
		memmove(ustring, ustring + skip, size * sizeof(Tcl_UniChar));
	    }
	} else {
	    ustring = u->input.buffer;
	    if (skip) {
		size -= skip;
		memcpy(ustring, ustring + skip, size * sizeof(Tcl_UniChar));
	    }
	}
	u->input.use = size;

	/* now update printed based on total amount skipped */

	u->printed -= skip;
	/* if more skipped than printed (i.e., keymap encountered) */
	/* for printed positive */
	if (u->printed < 0) u->printed = 0;

	/* if we are in the middle of a match, force the next event */
	/* to wait for more data to arrive */
	u->force_read = (rc == EXP_CANMATCH);

	/* finally reset echoed if necessary */
	if (rc != EXP_CANMATCH) {
	    if (skip >= oldprinted + u->echoed) u->echoed = 0;
	}

	if (rc == EXP_EOF) {
	  if (u->close_on_eof) {
	    exp_close(interp,u);
	  }
	    need_to_close_master = FALSE;
	}

	if (action) {
got_action:
	    change = (action && action->tty_reset);
	    if (change && tty_changed)
		exp_tty_set(interp,&tty_old,was_raw,was_echo);

	    te = inter_eval(interp,action,u);

	    if (change && real_tty) tty_changed =
					exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);
	    switch (te) {
		case TCL_BREAK:
		case TCL_CONTINUE:
		    finish(te);
		case EXP_TCL_RETURN:
		    finish(TCL_RETURN);
		case TCL_RETURN:
		    finish(TCL_OK);
		case TCL_OK:
		    /* god knows what the user might */
		    /* have done to us in the way of */
		    /* closed fds, so .... */
		    action = 0;	/* reset action */
		    continue;
		default:
		    finish(te);
	    }
	}
    }

#else /* SIMPLE_EVENT */
/*	deferred_interrupt = FALSE;*/
{
		int te;	/* result of Tcl_Eval */
		ExpState *u;    /*master*/
		int rc;	/* return code from ready.  This is further */
			/* refined by matcher. */
		int cc;	/* chars count from read() */
		struct action *action = 0;
		time_t previous_time;
		time_t current_time;
		int matchLen, skip;
		int change;	/* if action requires cooked mode */
		int attempt_match = TRUE;
		struct input *soonest_input;
		int print;		/* # of chars to print */
		int oldprinted;		/* old version of u->printed */

		int timeout;	/* current as opposed to default_timeout */

	if (-1 == (pid = fork())) {
		exp_error(interp,"fork: %s",Tcl_PosixError(interp));
		finish(TCL_ERROR);
	}
	if (pid == 0) {
	    /*
	     * This is a new child process.
	     * It exists only for this interact command and will go away when
	     * the interact returns.
	     *
	     * The purpose of this child process is to read output from the
	     * spawned process and send it to the user tty.
	     * (See diagram above.)
	     */

	    exp_close(interp,expStdinoutGet());

	    u = esPtrs[1];  /* get 2nd ExpState */
	    input_count = 1;

	    while (1) {

		/* calculate how long to wait */
		/* by finding shortest remaining timeout */
		if (timeout_simple) {
			timeout = default_timeout;
		} else {
			timeout = arbitrary_timeout;

			for (inp=input_base;inp;inp=inp->next) {
				if ((inp->timeout_remaining != EXP_TIME_INFINITY) &&
				    (inp->timeout_remaining < timeout))
					soonest_input = inp;
					timeout = inp->timeout_remaining;
			}

			Tcl_GetTime (&temp_time);
			previous_time = temp_time.sec;
			/* timestamp here rather than simply saving old */
			/* current time (after ready()) to account for */
			/* possibility of slow actions */

			/* timeout can actually be EXP_TIME_INFINITY here if user */
			/* explicitly supplied it in a few cases (or */
			/* the count-down code is broken) */
		}

		/* +1 so we can look at the "other" file descriptor */
		rc = exp_get_next_event(interp,esPtrs+1,input_count,&u,timeout,key);
		if (!timeout_simple) {
			int time_diff;

			Tcl_GetTime (&temp_time);
			current_time = temp_time.sec;
			time_diff = current_time - previous_time;

			/* update all timers */
			for (inp=input_base;inp;inp=inp->next) {
				if (inp->timeout_remaining != EXP_TIME_INFINITY) {
					inp->timeout_remaining -= time_diff;
					if (inp->timeout_remaining < 0)
						inp->timeout_remaining = 0;
				}
			}
		}

		/* at this point, we have some kind of event which can be */
		/* immediately processed - i.e. something that doesn't block */

		/* figure out who we are */
		inp = expStateToInput(esPtrToInput,u);

		switch (rc) {
		case EXP_DATA_NEW:
		    cc = intRead(interp,u,0,0,key);
		    if (cc > 0) break;
		    /*
		     * FALLTHRU
		     *
		     * Most systems have read() return 0, allowing
		     * control to fall thru and into this code.  On some
		     * systems (currently HP and new SGI), read() does
		     * see eof, and it must be detected earlier.  Then
		     * control jumps directly to this EXP_EOF label.
		     */
		case EXP_EOF:
			action = inp->action_eof;
			attempt_match = FALSE;
			skip = expSizeGet(u);
			rc = EXP_EOF;
			expDiagLog("interact: child received eof from spawn_id %s\r\n",u->name);
			exp_close(interp,u);
			break;
		case EXP_DATA_OLD:
			cc = 0;
			break;
		}

		km = 0;

		if (attempt_match) {
		    rc = intMatch(u,inp->keymap,&km,&matchLen,&skip,&reInfo);
		    if ((rc == EXP_MATCH) && km && km->re) {
			intRegExpMatchProcess(interp,u,km,&reInfo,skip);
		    }
		} else {
		    attempt_match = TRUE;
		}

		/* dispose of chars that should be skipped */
		
		/* skip is chars not involved in match */
		/* print is with chars involved in match */

		if (km && km->writethru) {
			print = skip + matchLen;
		} else print = skip;

		if (km && km->echo) {
		    intEcho(u,skip,matchLen);
		}
		oldprinted = u->printed;

		/* If expect has left characters in buffer, it has */
		/* already echoed them to the screen, thus we must */
		/* prevent them being rewritten.  Unfortunately this */
		/* gives the possibility of matching chars that have */
		/* already been output, but we do so since the user */
		/* could have avoided it by flushing the output */
		/* buffers directly. */
		if (print > u->printed) {	/* usual case */
		    for (outp = inp->output;outp;outp=outp->next) {
			struct exp_state_list *fdp;
			for (fdp = outp->i_list->state_list;fdp;fdp=fdp->next) {
			    /* send to channel (and log if chan is stdout or devtty) */
			    int wc = expWriteBytesAndLogIfTtyU(fdp->esPtr,
							       u->input.buffer + u->printed,
				    print - u->printed);
			    if (wc < 0) {
				expDiagLog("interact: write on spawn id %s failed (%s)\r\n",fdp->esPtr->name,Tcl_PosixError(interp));
				action = outp->action_eof;

				te = inter_eval(interp,action,u);

				switch (te) {
				    case TCL_BREAK:
				    case TCL_CONTINUE:
					finish(te);
				    case EXP_TCL_RETURN:
					finish(TCL_RETURN);
				    case TCL_RETURN:
					finish(TCL_OK);
				    case TCL_OK:
					/* god knows what the user might */
					/* have done to us in the way of */
					/* closed fds, so .... */
					action = 0;	/* reset action */
					continue;
				    default:
					finish(te);
				}
			    }
			}
		    }
		    u->printed = print;
		}

		/* u->printed is now accurate with respect to the buffer */
		/* However, we're about to shift the old data out of the */
		/* buffer.  Thus size, printed, and echoed must be */
		/* updated */

		/* first update size based on skip information */
		/* then set skip to the total amount skipped */

		size = expSizeGet(u);
		if (rc == EXP_MATCH) {
		    action = &km->action;

		    skip += matchLen;
		    size -= skip;
		    if (size) {
			memcpy(u->buffer, u->buffer + skip, size);
		    }
		} else {
		    if (skip) {
			size -= skip;
			memcpy(u->buffer, u->buffer + skip, size);
		    }
		}
		Tcl_SetObjLength(size);

		/* now update printed based on total amount skipped */

		u->printed -= skip;
		/* if more skipped than printed (i.e., keymap encountered) */
		/* for printed positive */
		if (u->printed < 0) u->printed = 0;

		/* if we are in the middle of a match, force the next event */
		/* to wait for more data to arrive */
		u->force_read = (rc == EXP_CANMATCH);

		/* finally reset echoed if necessary */
		if (rc != EXP_CANMATCH) {
			if (skip >= oldprinted + u->echoed) u->echoed = 0;
		}

		if (action) {
			te = inter_eval(interp,action,u);
			switch (te) {
			case TCL_BREAK:
			case TCL_CONTINUE:
				finish(te);
			case EXP_TCL_RETURN:
				finish(TCL_RETURN);
			case TCL_RETURN:
				finish(TCL_OK);
			case TCL_OK:
				/* god knows what the user might */
				/* have done to us in the way of */
				/* closed fds, so .... */
				action = 0;	/* reset action */
				continue;
			default:
				finish(te);
			}
		}
	    }
	} else {
	    /*
	     * This is the original Expect process.
	     *
	     * It now loops, reading keystrokes from the user tty
	     * and sending them to the spawned process.
	     * (See diagram above.)
	     */

#include <signal.h>

#if defined(SIGCLD) && !defined(SIGCHLD)
#define SIGCHLD SIGCLD
#endif
		expDiagLog("fork = %d\r\n",pid);
		signal(SIGCHLD,sigchld_handler);
/*	restart:*/
/*		tty_changed = exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);*/

	    u = esPtrs[0];  /* get 1st ExpState */
	    input_count = 1;

	    while (1) {
		/* calculate how long to wait */
		/* by finding shortest remaining timeout */
		if (timeout_simple) {
			timeout = default_timeout;
		} else {
			timeout = arbitrary_timeout;

			for (inp=input_base;inp;inp=inp->next) {
				if ((inp->timeout_remaining != EXP_TIME_INFINITY) &&
				    (inp->timeout_remaining < timeout))
					soonest_input = inp;
					timeout = inp->timeout_remaining;
			}

			Tcl_GetTime (&temp_time);
			previous_time = temp_time.sec;
			/* timestamp here rather than simply saving old */
			/* current time (after ready()) to account for */
			/* possibility of slow actions */

			/* timeout can actually be EXP_TIME_INFINITY here if user */
			/* explicitly supplied it in a few cases (or */
			/* the count-down code is broken) */
		}

		rc = exp_get_next_event(interp,esPtrs,input_count,&u,timeout,key);
		if (!timeout_simple) {
			int time_diff;

			Tcl_GetTime (&temp_time);
			current_time = temp_time.sec;
			time_diff = current_time - previous_time;

			/* update all timers */
			for (inp=input_base;inp;inp=inp->next) {
				if (inp->timeout_remaining != EXP_TIME_INFINITY) {
					inp->timeout_remaining -= time_diff;
					if (inp->timeout_remaining < 0)
						inp->timeout_remaining = 0;
				}
			}
		}

		/* at this point, we have some kind of event which can be */
		/* immediately processed - i.e. something that doesn't block */

		/* figure out who we are */
		inp = expStateToInput(esPtrToInput,u);

		switch (rc) {
		case EXP_DATA_NEW:
		        cc = intRead(interp,u,0,1,key);
		        if (cc > 0) {
				break;
			} else if (cc == EXP_CHILD_EOF) {
				/* user could potentially have two outputs in which */
				/* case we might be looking at the wrong one, but */
				/* the likelihood of this is nil */
				action = inp->output->action_eof;
				attempt_match = FALSE;
				skip = expSizeGet(u);
				rc = EXP_EOF;
				expDiagLogU("interact: process died/eof\r\n");
				clean_up_after_child(interp,esPtrs[1]);
				break;
			}
			/*
			 * FALLTHRU
			 *
			 * Most systems have read() return 0, allowing
			 * control to fall thru and into this code.  On some
			 * systems (currently HP and new SGI), read() does
			 * see eof, and it must be detected earlier.  Then
			 * control jumps directly to this EXP_EOF label.
			 */
		case EXP_EOF:
			action = inp->action_eof;
			attempt_match = FALSE;
			skip = expSizeGet(u);
			rc = EXP_EOF;
			expDiagLogU("user sent EOF or disappeared\n\n");
			break;
		case EXP_DATA_OLD:
			cc = 0;
			break;
		}

		km = 0;

		if (attempt_match) {
		    rc = intMatch(u,inp->keymap,&km,&matchLen,&skip,&reInfo);
		    if ((rc == EXP_MATCH) && km && km->re) {
			intRegExpMatchProcess(interp,u,km,&reInfo,skip);
		    }
		} else {
		    attempt_match = TRUE;
		}

		/* dispose of chars that should be skipped */
		
		/* skip is chars not involved in match */
		/* print is with chars involved in match */

		if (km && km->writethru) {
			print = skip + matchLen;
		} else print = skip;

		if (km && km->echo) {
		    intEcho(u,skip,matchLen);
		}
		oldprinted = u->printed;

		/* If expect has left characters in buffer, it has */
		/* already echoed them to the screen, thus we must */
		/* prevent them being rewritten.  Unfortunately this */
		/* gives the possibility of matching chars that have */
		/* already been output, but we do so since the user */
		/* could have avoided it by flushing the output */
		/* buffers directly. */
		if (print > u->printed) {	/* usual case */
		    for (outp = inp->output;outp;outp=outp->next) {
			struct exp_state_list *fdp;
			for (fdp = outp->i_list->state_list;fdp;fdp=fdp->next) {
			    /* send to channel (and log if chan is stdout or devtty) */
			    int wc = expWriteBytesAndLogIfTtyU(fdp->esPtr,
							       u->input.buffer + u->printed,
				    print - u->printed);
			    if (wc < 0) {
				expDiagLog("interact: write on spawn id %s failed (%s)\r\n",fdp->esPtr->name,Tcl_PosixError(interp));
				clean_up_after_child(interp,fdp->esPtr);
				action = outp->action_eof;
				change = (action && action->tty_reset);
				if (change && tty_changed)
				    exp_tty_set(interp,&tty_old,was_raw,was_echo);
				te = inter_eval(interp,action,u);

				if (change && real_tty) tty_changed =
							    exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);
				switch (te) {
				    case TCL_BREAK:
				    case TCL_CONTINUE:
					finish(te);
				    case EXP_TCL_RETURN:
					finish(TCL_RETURN);
				    case TCL_RETURN:
					finish(TCL_OK);
				    case TCL_OK:
					/* god knows what the user might */
					/* have done to us in the way of */
					/* closed fds, so .... */
					action = 0;	/* reset action */
					continue;
				    default:
					finish(te);
				}
			    }
			}
		    }
		    u->printed = print;
		}

		/* u->printed is now accurate with respect to the buffer */
		/* However, we're about to shift the old data out of the */
		/* buffer.  Thus size, printed, and echoed must be */
		/* updated */

		/* first update size based on skip information */
		/* then set skip to the total amount skipped */

		size = expSizeGet(u);
		if (rc == EXP_MATCH) {
		    action = &km->action;

		    skip += matchLen;
		    size -= skip;
		    if (size) {
			memcpy(u->buffer, u->buffer + skip, size);
		    }
		} else {
		    if (skip) {
			size -= skip;
			memcpy(u->buffer, u->buffer + skip, size);
		    }
		}
		Tcl_SetObjLength(size);

		/* now update printed based on total amount skipped */

		u->printed -= skip;
		/* if more skipped than printed (i.e., keymap encountered) */
		/* for printed positive */
		if (u->printed < 0) u->printed = 0;

		/* if we are in the middle of a match, force the next event */
		/* to wait for more data to arrive */
		u->force_read = (rc == EXP_CANMATCH);

		/* finally reset echoed if necessary */
		if (rc != EXP_CANMATCH) {
			if (skip >= oldprinted + u->echoed) u->echoed = 0;
		}

		if (action) {
			change = (action && action->tty_reset);
			if (change && tty_changed)
				exp_tty_set(interp,&tty_old,was_raw,was_echo);

			te = inter_eval(interp,action,u);

			if (change && real_tty) tty_changed =
			   exp_tty_raw_noecho(interp,&tty_old,&was_raw,&was_echo);
			switch (te) {
			case TCL_BREAK:
			case TCL_CONTINUE:
				finish(te);
			case EXP_TCL_RETURN:
				finish(TCL_RETURN);
			case TCL_RETURN:
				finish(TCL_OK);
			case TCL_OK:
				/* god knows what the user might */
				/* have done to us in the way of */
				/* closed fds, so .... */
				action = 0;	/* reset action */
				continue;
			default:
				finish(te);
			}
		}
	    }
	}
}
#endif /* SIMPLE_EVENT */

 done:
#ifdef SIMPLE_EVENT
    /* force child to exit upon eof from master */
    if (pid == 0) {
	exit(SPAWNED_PROCESS_DIED);
    }
#endif /* SIMPLE_EVENT */

    if (need_to_close_master && u->close_on_eof) exp_close(interp,u);

    if (tty_changed) exp_tty_set(interp,&tty_old,was_raw,was_echo);
    if (esPtrs) ckfree((char *)esPtrs);
    if (esPtrToInput) Tcl_DeleteHashTable(esPtrToInput);
    free_input(interp,input_base);
    free_action(action_base);

    if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
    return(status);

 error:
    if (new_cmd) { Tcl_DecrRefCount (new_cmd); }
    return TCL_ERROR;
}

/* version of Tcl_Eval for interact */ 
static int
inter_eval(
    Tcl_Interp *interp,
    struct action *action,
    ExpState *esPtr)
{
    int status;

    if (action->iwrite) {
	out("spawn_id",esPtr->name);
    }

    if (action->statement) {
	status = Tcl_EvalObjEx(interp,action->statement,0);
    } else {
	expStdoutLogU("\r\n",1);
	status = exp_interpreter(interp,(Tcl_Obj *)0);
    }

    return status;
}

static void
free_keymap(struct keymap *km)
{
	if (km == 0) return;
	free_keymap(km->next);

	ckfree((char *)km);
}

static void
free_action(struct action *a)
{
	struct action *next;

	while (a) {
		next = a->next;
		ckfree((char *)a);
		a = next;
	}
}

static void
free_input(
    Tcl_Interp *interp,
    struct input *i)
{
	if (i == 0) return;
	free_input(interp,i->next);

	exp_free_i(interp,i->i_list,inter_updateproc);
	free_output(interp,i->output);
	free_keymap(i->keymap);
	ckfree((char *)i);
}

static struct action *
new_action(struct action **base)
{
	struct action *o = new(struct action);

	/* stick new action into beginning of list of all actions */
	o->next = *base;
	*base = o;

	return o;
}

static void
free_output(
    Tcl_Interp *interp,
    struct output *o)
{
	if (o == 0) return;
	free_output(interp,o->next);
	exp_free_i(interp,o->i_list,inter_updateproc);

	ckfree((char *)o);
}


static struct exp_cmd_data cmd_data[]  = {
{"interact",	Exp_InteractObjCmd,	0,	0,	0},
{0}};

void
exp_init_interact_cmds(Tcl_Interp *interp)
{
    ThreadSpecificData *tsdPtr = TCL_TSD_INIT(&dataKey);

    exp_create_commands(interp,cmd_data);

    tsdPtr->cmdObjReturn = Tcl_NewStringObj("return",6);
    Tcl_IncrRefCount(tsdPtr->cmdObjReturn);
#if 0
    tsdPtr->cmdObjInterpreter = Tcl_NewStringObj("interpreter",11);
    Tcl_IncrRefCount(tsdPtr->cmdObjInterpreter);
#endif
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
