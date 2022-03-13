/* exp_clib.c - top-level functions in the expect C library, libexpect.a

Written by: Don Libes, libes@cme.nist.gov, NIST, 12/3/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#include "expect_cf.h"
#include "exp_command.h"
#include <stdio.h>
#include <setjmp.h>
#ifdef HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#include <sys/types.h>
#include <sys/ioctl.h>

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

#ifdef CRAY
# ifndef TCSETCTTY
#  if defined(HAVE_TERMIOS)
#   include <termios.h>
#  else
#   include <termio.h>
#  endif
# endif
#endif

#ifdef HAVE_SYS_FCNTL_H
#  include <sys/fcntl.h>
#else
#  include <fcntl.h>
#endif

#ifdef HAVE_STRREDIR_H
#include <sys/strredir.h>
# ifdef SRIOCSREDIR
#  undef TIOCCONS
# endif
#endif

#include <signal.h>
/*#include <memory.h> - deprecated - ANSI C moves them into string.h */
#include "string.h"

#include <errno.h>

#include <unistd.h>

#ifdef NO_STDLIB_H

/*
 * Tcl's compat/stdlib.h
 */

/*
 * stdlib.h --
 *
 *	Declares facilities exported by the "stdlib" portion of
 *	the C library.  This file isn't complete in the ANSI-C
 *	sense;  it only declares things that are needed by Tcl.
 *	This file is needed even on many systems with their own
 *	stdlib.h (e.g. SunOS) because not all stdlib.h files
 *	declare all the procedures needed here (such as strtod).
 *
 * Copyright (c) 1991 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: exp_clib.c,v 5.38 2010/07/01 00:53:49 eee Exp $
 */

#ifndef _STDLIB
#define _STDLIB

extern void		abort _ANSI_ARGS_((void));
extern double		atof _ANSI_ARGS_((CONST char *string));
extern int		atoi _ANSI_ARGS_((CONST char *string));
extern long		atol _ANSI_ARGS_((CONST char *string));
extern char *		calloc _ANSI_ARGS_((unsigned int numElements,
			    unsigned int size));
extern void		exit _ANSI_ARGS_((int status));
extern int		free _ANSI_ARGS_((char *blockPtr));
extern char *		getenv _ANSI_ARGS_((CONST char *name));
extern char *		malloc _ANSI_ARGS_((unsigned int numBytes));
extern void		qsort _ANSI_ARGS_((VOID *base, int n, int size,
			    int (*compar)(CONST VOID *element1, CONST VOID
			    *element2)));
extern char *		realloc _ANSI_ARGS_((char *ptr, unsigned int numBytes));
extern double		strtod _ANSI_ARGS_((CONST char *string, char **endPtr));
extern long		strtol _ANSI_ARGS_((CONST char *string, char **endPtr,
			    int base));
extern unsigned long	strtoul _ANSI_ARGS_((CONST char *string,
			    char **endPtr, int base));

#endif /* _STDLIB */

/*
 * end of Tcl's compat/stdlib.h
 */

#else
#include <stdlib.h>		/* for malloc */
#endif

#include <tcl.h>
#include "expect.h"
#define TclRegError exp_TclRegError

/*
 * regexp code - from tcl8.0.4/generic/regexp.c
 */

/*
 * TclRegComp and TclRegExec -- TclRegSub is elsewhere
 *
 *	Copyright (c) 1986 by University of Toronto.
 *	Written by Henry Spencer.  Not derived from licensed software.
 *
 *	Permission is granted to anyone to use this software for any
 *	purpose on any computer system, and to redistribute it freely,
 *	subject to the following restrictions:
 *
 *	1. The author is not responsible for the consequences of use of
 *		this software, no matter how awful, even if they arise
 *		from defects in it.
 *
 *	2. The origin of this software must not be misrepresented, either
 *		by explicit claim or by omission.
 *
 *	3. Altered versions must be plainly marked as such, and must not
 *		be misrepresented as being the original software.
 *
 * Beware that some of this code is subtly aware of the way operator
 * precedence is structured in regular expressions.  Serious changes in
 * regular-expression syntax might require a total rethink.
 *
 * *** NOTE: this code has been altered slightly for use in Tcl: ***
 * *** 1. Use ckalloc and ckfree instead of  malloc and free.	 ***
 * *** 2. Add extra argument to regexp to specify the real	 ***
 * ***    start of the string separately from the start of the	 ***
 * ***    current search. This is needed to search for multiple	 ***
 * ***    matches within a string.				 ***
 * *** 3. Names have been changed, e.g. from regcomp to		 ***
 * ***    TclRegComp, to avoid clashes with other 		 ***
 * ***    regexp implementations used by applications. 		 ***
 * *** 4. Added errMsg declaration and TclRegError procedure	 ***
 * *** 5. Various lint-like things, such as casting arguments	 ***
 * ***	  in procedure calls.					 ***
 *
 * *** NOTE: This code has been altered for use in MT-Sturdy Tcl ***
 * *** 1. All use of static variables has been changed to access ***
 * ***    fields of a structure.                                 ***
 * *** 2. This in addition to changes to TclRegError makes the   ***
 * ***    code multi-thread safe.                                ***
 *
 * RCS: @(#) $Id: exp_clib.c,v 5.38 2010/07/01 00:53:49 eee Exp $
 */

#if 0
#include "tclInt.h"
#include "tclPort.h"
#endif

/*
 * The variable below is set to NULL before invoking regexp functions
 * and checked after those functions.  If an error occurred then TclRegError
 * will set the variable to point to a (static) error message.  This
 * mechanism unfortunately does not support multi-threading, but the
 * procedures TclRegError and TclGetRegError can be modified to use
 * thread-specific storage for the variable and thereby make the code
 * thread-safe.
 */

static char *errMsg = NULL;

/*
 * The "internal use only" fields in regexp.h are present to pass info from
 * compile to execute that permits the execute phase to run lots faster on
 * simple cases.  They are:
 *
 * regstart	char that must begin a match; '\0' if none obvious
 * reganch	is the match anchored (at beginning-of-line only)?
 * regmust	string (pointer into program) that match must include, or NULL
 * regmlen	length of regmust string
 *
 * Regstart and reganch permit very fast decisions on suitable starting points
 * for a match, cutting down the work a lot.  Regmust permits fast rejection
 * of lines that cannot possibly match.  The regmust tests are costly enough
 * that TclRegComp() supplies a regmust only if the r.e. contains something
 * potentially expensive (at present, the only such thing detected is * or +
 * at the start of the r.e., which can involve a lot of backup).  Regmlen is
 * supplied because the test in TclRegExec() needs it and TclRegComp() is
 * computing it anyway.
 */

/*
 * Structure for regexp "program".  This is essentially a linear encoding
 * of a nondeterministic finite-state machine (aka syntax charts or
 * "railroad normal form" in parsing technology).  Each node is an opcode
 * plus a "next" pointer, possibly plus an operand.  "Next" pointers of
 * all nodes except BRANCH implement concatenation; a "next" pointer with
 * a BRANCH on both ends of it is connecting two alternatives.  (Here we
 * have one of the subtle syntax dependencies:  an individual BRANCH (as
 * opposed to a collection of them) is never concatenated with anything
 * because of operator precedence.)  The operand of some types of node is
 * a literal string; for others, it is a node leading into a sub-FSM.  In
 * particular, the operand of a BRANCH node is the first node of the branch.
 * (NB this is *not* a tree structure:  the tail of the branch connects
 * to the thing following the set of BRANCHes.)  The opcodes are:
 */

/* definition	number	opnd?	meaning */
#define	END	0	/* no	End of program. */
#define	BOL	1	/* no	Match "" at beginning of line. */
#define	EOL	2	/* no	Match "" at end of line. */
#define	ANY	3	/* no	Match any one character. */
#define	ANYOF	4	/* str	Match any character in this string. */
#define	ANYBUT	5	/* str	Match any character not in this string. */
#define	BRANCH	6	/* node	Match this alternative, or the next... */
#define	BACK	7	/* no	Match "", "next" ptr points backward. */
#define	EXACTLY	8	/* str	Match this string. */
#define	NOTHING	9	/* no	Match empty string. */
#define	STAR	10	/* node	Match this (simple) thing 0 or more times. */
#define	PLUS	11	/* node	Match this (simple) thing 1 or more times. */
#define	OPEN	20	/* no	Mark this point in input as start of #n. */
			/*	OPEN+1 is number 1, etc. */
#define	CLOSE	(OPEN+NSUBEXP)	/* no	Analogous to OPEN. */

/*
 * Opcode notes:
 *
 * BRANCH	The set of branches constituting a single choice are hooked
 *		together with their "next" pointers, since precedence prevents
 *		anything being concatenated to any individual branch.  The
 *		"next" pointer of the last BRANCH in a choice points to the
 *		thing following the whole choice.  This is also where the
 *		final "next" pointer of each individual branch points; each
 *		branch starts with the operand node of a BRANCH node.
 *
 * BACK		Normal "next" pointers all implicitly point forward; BACK
 *		exists to make loop structures possible.
 *
 * STAR,PLUS	'?', and complex '*' and '+', are implemented as circular
 *		BRANCH structures using BACK.  Simple cases (one character
 *		per match) are implemented with STAR and PLUS for speed
 *		and to minimize recursive plunges.
 *
 * OPEN,CLOSE	...are numbered at compile time.
 */

/*
 * A node is one char of opcode followed by two chars of "next" pointer.
 * "Next" pointers are stored as two 8-bit pieces, high order first.  The
 * value is a positive offset from the opcode of the node containing it.
 * An operand, if any, simply follows the node.  (Note that much of the
 * code generation knows about this implicit relationship.)
 *
 * Using two bytes for the "next" pointer is vast overkill for most things,
 * but allows patterns to get big without disasters.
 */
#define	OP(p)	(*(p))
#define	NEXT(p)	(((*((p)+1)&0377)<<8) + (*((p)+2)&0377))
#define	OPERAND(p)	((p) + 3)

/*
 * See regmagic.h for one further detail of program structure.
 */


/*
 * Utility definitions.
 */
#ifndef CHARBITS
#define	UCHARAT(p)	((int)*(unsigned char *)(p))
#else
#define	UCHARAT(p)	((int)*(p)&CHARBITS)
#endif

#define	FAIL(m)	{ TclRegError(m); return(NULL); }
#define	ISMULT(c)	((c) == '*' || (c) == '+' || (c) == '?')
#define	META	"^$.[()|?+*\\"

/*
 * Flags to be passed up and down.
 */
#define	HASWIDTH	01	/* Known never to match null string. */
#define	SIMPLE		02	/* Simple enough to be STAR/PLUS operand. */
#define	SPSTART		04	/* Starts with * or +. */
#define	WORST		0	/* Worst case. */

/*
 * Global work variables for TclRegComp().
 */
struct regcomp_state  {
    char *regparse;		/* Input-scan pointer. */
    int regnpar;		/* () count. */
    char *regcode;		/* Code-emit pointer; &regdummy = don't. */
    long regsize;		/* Code size. */
};

static char regdummy;

/*
 * The first byte of the regexp internal "program" is actually this magic
 * number; the start node begins in the second byte.
 */
#define	MAGIC	0234


/*
 * Forward declarations for TclRegComp()'s friends.
 */

static char *		reg _ANSI_ARGS_((int paren, int *flagp,
			    struct regcomp_state *rcstate));
static char *		regatom _ANSI_ARGS_((int *flagp,
			    struct regcomp_state *rcstate));
static char *		regbranch _ANSI_ARGS_((int *flagp,
			    struct regcomp_state *rcstate));
static void		regc _ANSI_ARGS_((int b,
			    struct regcomp_state *rcstate));
static void		reginsert _ANSI_ARGS_((int op, char *opnd,
			    struct regcomp_state *rcstate));
static char *		regnext _ANSI_ARGS_((char *p));
static char *		regnode _ANSI_ARGS_((int op,
			    struct regcomp_state *rcstate));
static void 		regoptail _ANSI_ARGS_((char *p, char *val));
static char *		regpiece _ANSI_ARGS_((int *flagp,
			    struct regcomp_state *rcstate));
static void 		regtail _ANSI_ARGS_((char *p, char *val));

#ifdef STRCSPN
static int strcspn _ANSI_ARGS_((char *s1, char *s2));
#endif

/*
 - TclRegComp - compile a regular expression into internal code
 *
 * We can't allocate space until we know how big the compiled form will be,
 * but we can't compile it (and thus know how big it is) until we've got a
 * place to put the code.  So we cheat:  we compile it twice, once with code
 * generation turned off and size counting turned on, and once "for real".
 * This also means that we don't allocate space until we are sure that the
 * thing really will compile successfully, and we never have to move the
 * code and thus invalidate pointers into it.  (Note that it has to be in
 * one piece because free() must be able to free it all.)
 *
 * Beware that the optimization-preparation code in here knows about some
 * of the structure of the compiled regexp.
 */
regexp *
TclRegComp(exp)
char *exp;
{
	register regexp *r;
	register char *scan;
	register char *longest;
	register int len;
	int flags;
	struct regcomp_state state;
	struct regcomp_state *rcstate= &state;

	if (exp == NULL)
		FAIL("NULL argument");

	/* First pass: determine size, legality. */
	rcstate->regparse = exp;
	rcstate->regnpar = 1;
	rcstate->regsize = 0L;
	rcstate->regcode = &regdummy;
	regc(MAGIC, rcstate);
	if (reg(0, &flags, rcstate) == NULL)
		return(NULL);

	/* Small enough for pointer-storage convention? */
	if (rcstate->regsize >= 32767L)		/* Probably could be 65535L. */
		FAIL("regexp too big");

	/* Allocate space. */
	r = (regexp *)ckalloc(sizeof(regexp) + (unsigned)rcstate->regsize);
	if (r == NULL)
		FAIL("out of space");

	/* Second pass: emit code. */
	rcstate->regparse = exp;
	rcstate->regnpar = 1;
	rcstate->regcode = r->program;
	regc(MAGIC, rcstate);
	if (reg(0, &flags, rcstate) == NULL) {
	  ckfree ((char*) r);
	  return(NULL);
	}

	/* Dig out information for optimizations. */
	r->regstart = '\0';	/* Worst-case defaults. */
	r->reganch = 0;
	r->regmust = NULL;
	r->regmlen = 0;
	scan = r->program+1;			/* First BRANCH. */
	if (OP(regnext(scan)) == END) {		/* Only one top-level choice. */
		scan = OPERAND(scan);

		/* Starting-point info. */
		if (OP(scan) == EXACTLY)
			r->regstart = *OPERAND(scan);
		else if (OP(scan) == BOL)
			r->reganch++;

		/*
		 * If there's something expensive in the r.e., find the
		 * longest literal string that must appear and make it the
		 * regmust.  Resolve ties in favor of later strings, since
		 * the regstart check works with the beginning of the r.e.
		 * and avoiding duplication strengthens checking.  Not a
		 * strong reason, but sufficient in the absence of others.
		 */
		if (flags&SPSTART) {
			longest = NULL;
			len = 0;
			for (; scan != NULL; scan = regnext(scan))
				if (OP(scan) == EXACTLY && ((int) strlen(OPERAND(scan))) >= len) {
					longest = OPERAND(scan);
					len = strlen(OPERAND(scan));
				}
			r->regmust = longest;
			r->regmlen = len;
		}
	}

	return(r);
}

/*
 - reg - regular expression, i.e. main body or parenthesized thing
 *
 * Caller must absorb opening parenthesis.
 *
 * Combining parenthesis handling with the base level of regular expression
 * is a trifle forced, but the need to tie the tails of the branches to what
 * follows makes it hard to avoid.
 */
static char *
reg(paren, flagp, rcstate)
int paren;			/* Parenthesized? */
int *flagp;
struct regcomp_state *rcstate;
{
	register char *ret;
	register char *br;
	register char *ender;
	register int parno = 0;
	int flags;

	*flagp = HASWIDTH;	/* Tentatively. */

	/* Make an OPEN node, if parenthesized. */
	if (paren) {
		if (rcstate->regnpar >= NSUBEXP)
			FAIL("too many ()");
		parno = rcstate->regnpar;
		rcstate->regnpar++;
		ret = regnode(OPEN+parno,rcstate);
	} else
		ret = NULL;

	/* Pick up the branches, linking them together. */
	br = regbranch(&flags,rcstate);
	if (br == NULL)
		return(NULL);
	if (ret != NULL)
		regtail(ret, br);	/* OPEN -> first. */
	else
		ret = br;
	if (!(flags&HASWIDTH))
		*flagp &= ~HASWIDTH;
	*flagp |= flags&SPSTART;
	while (*rcstate->regparse == '|') {
		rcstate->regparse++;
		br = regbranch(&flags,rcstate);
		if (br == NULL)
			return(NULL);
		regtail(ret, br);	/* BRANCH -> BRANCH. */
		if (!(flags&HASWIDTH))
			*flagp &= ~HASWIDTH;
		*flagp |= flags&SPSTART;
	}

	/* Make a closing node, and hook it on the end. */
	ender = regnode((paren) ? CLOSE+parno : END,rcstate);	
	regtail(ret, ender);

	/* Hook the tails of the branches to the closing node. */
	for (br = ret; br != NULL; br = regnext(br))
		regoptail(br, ender);

	/* Check for proper termination. */
	if (paren && *rcstate->regparse++ != ')') {
		FAIL("unmatched ()");
	} else if (!paren && *rcstate->regparse != '\0') {
		if (*rcstate->regparse == ')') {
			FAIL("unmatched ()");
		} else
			FAIL("junk on end");	/* "Can't happen". */
		/* NOTREACHED */
	}

	return(ret);
}

/*
 - regbranch - one alternative of an | operator
 *
 * Implements the concatenation operator.
 */
static char *
regbranch(flagp, rcstate)
int *flagp;
struct regcomp_state *rcstate;
{
	register char *ret;
	register char *chain;
	register char *latest;
	int flags;

	*flagp = WORST;		/* Tentatively. */

	ret = regnode(BRANCH,rcstate);
	chain = NULL;
	while (*rcstate->regparse != '\0' && *rcstate->regparse != '|' &&
				*rcstate->regparse != ')') {
		latest = regpiece(&flags, rcstate);
		if (latest == NULL)
			return(NULL);
		*flagp |= flags&HASWIDTH;
		if (chain == NULL)	/* First piece. */
			*flagp |= flags&SPSTART;
		else
			regtail(chain, latest);
		chain = latest;
	}
	if (chain == NULL)	/* Loop ran zero times. */
		(void) regnode(NOTHING,rcstate);

	return(ret);
}

/*
 - regpiece - something followed by possible [*+?]
 *
 * Note that the branching code sequences used for ? and the general cases
 * of * and + are somewhat optimized:  they use the same NOTHING node as
 * both the endmarker for their branch list and the body of the last branch.
 * It might seem that this node could be dispensed with entirely, but the
 * endmarker role is not redundant.
 */
static char *
regpiece(flagp, rcstate)
int *flagp;
struct regcomp_state *rcstate;
{
	register char *ret;
	register char op;
	register char *next;
	int flags;

	ret = regatom(&flags,rcstate);
	if (ret == NULL)
		return(NULL);

	op = *rcstate->regparse;
	if (!ISMULT(op)) {
		*flagp = flags;
		return(ret);
	}

	if (!(flags&HASWIDTH) && op != '?')
		FAIL("*+ operand could be empty");
	*flagp = (op != '+') ? (WORST|SPSTART) : (WORST|HASWIDTH);

	if (op == '*' && (flags&SIMPLE))
		reginsert(STAR, ret, rcstate);
	else if (op == '*') {
		/* Emit x* as (x&|), where & means "self". */
		reginsert(BRANCH, ret, rcstate);			/* Either x */
		regoptail(ret, regnode(BACK,rcstate));		/* and loop */
		regoptail(ret, ret);			/* back */
		regtail(ret, regnode(BRANCH,rcstate));		/* or */
		regtail(ret, regnode(NOTHING,rcstate));		/* null. */
	} else if (op == '+' && (flags&SIMPLE))
		reginsert(PLUS, ret, rcstate);
	else if (op == '+') {
		/* Emit x+ as x(&|), where & means "self". */
		next = regnode(BRANCH,rcstate);			/* Either */
		regtail(ret, next);
		regtail(regnode(BACK,rcstate), ret);		/* loop back */
		regtail(next, regnode(BRANCH,rcstate));		/* or */
		regtail(ret, regnode(NOTHING,rcstate));		/* null. */
	} else if (op == '?') {
		/* Emit x? as (x|) */
		reginsert(BRANCH, ret, rcstate);			/* Either x */
		regtail(ret, regnode(BRANCH,rcstate));		/* or */
		next = regnode(NOTHING,rcstate);		/* null. */
		regtail(ret, next);
		regoptail(ret, next);
	}
	rcstate->regparse++;
	if (ISMULT(*rcstate->regparse))
		FAIL("nested *?+");

	return(ret);
}

/*
 - regatom - the lowest level
 *
 * Optimization:  gobbles an entire sequence of ordinary characters so that
 * it can turn them into a single node, which is smaller to store and
 * faster to run.  Backslashed characters are exceptions, each becoming a
 * separate node; the code is simpler that way and it's not worth fixing.
 */
static char *
regatom(flagp, rcstate)
int *flagp;
struct regcomp_state *rcstate;
{
	register char *ret;
	int flags;

	*flagp = WORST;		/* Tentatively. */

	switch (*rcstate->regparse++) {
	case '^':
		ret = regnode(BOL,rcstate);
		break;
	case '$':
		ret = regnode(EOL,rcstate);
		break;
	case '.':
		ret = regnode(ANY,rcstate);
		*flagp |= HASWIDTH|SIMPLE;
		break;
	case '[': {
			register int clss;
			register int classend;

			if (*rcstate->regparse == '^') {	/* Complement of range. */
				ret = regnode(ANYBUT,rcstate);
				rcstate->regparse++;
			} else
				ret = regnode(ANYOF,rcstate);
			if (*rcstate->regparse == ']' || *rcstate->regparse == '-')
				regc(*rcstate->regparse++,rcstate);
			while (*rcstate->regparse != '\0' && *rcstate->regparse != ']') {
				if (*rcstate->regparse == '-') {
					rcstate->regparse++;
					if (*rcstate->regparse == ']' || *rcstate->regparse == '\0')
						regc('-',rcstate);
					else {
						clss = UCHARAT(rcstate->regparse-2)+1;
						classend = UCHARAT(rcstate->regparse);
						if (clss > classend+1)
							FAIL("invalid [] range");
						for (; clss <= classend; clss++)
							regc((char)clss,rcstate);
						rcstate->regparse++;
					}
				} else
					regc(*rcstate->regparse++,rcstate);
			}
			regc('\0',rcstate);
			if (*rcstate->regparse != ']')
				FAIL("unmatched []");
			rcstate->regparse++;
			*flagp |= HASWIDTH|SIMPLE;
		}
		break;
	case '(':
		ret = reg(1, &flags, rcstate);
		if (ret == NULL)
			return(NULL);
		*flagp |= flags&(HASWIDTH|SPSTART);
		break;
	case '\0':
	case '|':
	case ')':
		FAIL("internal urp");	/* Supposed to be caught earlier. */
		/* NOTREACHED */
	case '?':
	case '+':
	case '*':
		FAIL("?+* follows nothing");
		/* NOTREACHED */
	case '\\':
		if (*rcstate->regparse == '\0')
			FAIL("trailing \\");
		ret = regnode(EXACTLY,rcstate);
		regc(*rcstate->regparse++,rcstate);
		regc('\0',rcstate);
		*flagp |= HASWIDTH|SIMPLE;
		break;
	default: {
			register int len;
			register char ender;

			rcstate->regparse--;
			len = strcspn(rcstate->regparse, META);
			if (len <= 0)
				FAIL("internal disaster");
			ender = *(rcstate->regparse+len);
			if (len > 1 && ISMULT(ender))
				len--;		/* Back off clear of ?+* operand. */
			*flagp |= HASWIDTH;
			if (len == 1)
				*flagp |= SIMPLE;
			ret = regnode(EXACTLY,rcstate);
			while (len > 0) {
				regc(*rcstate->regparse++,rcstate);
				len--;
			}
			regc('\0',rcstate);
		}
		break;
	}

	return(ret);
}

/*
 - regnode - emit a node
 */
static char *			/* Location. */
regnode(op, rcstate)
int op;
struct regcomp_state *rcstate;
{
	register char *ret;
	register char *ptr;

	ret = rcstate->regcode;
	if (ret == &regdummy) {
		rcstate->regsize += 3;
		return(ret);
	}

	ptr = ret;
	*ptr++ = (char)op;
	*ptr++ = '\0';		/* Null "next" pointer. */
	*ptr++ = '\0';
	rcstate->regcode = ptr;

	return(ret);
}

/*
 - regc - emit (if appropriate) a byte of code
 */
static void
regc(b, rcstate)
int b;
struct regcomp_state *rcstate;
{
	if (rcstate->regcode != &regdummy)
		*rcstate->regcode++ = (char)b;
	else
		rcstate->regsize++;
}

/*
 - reginsert - insert an operator in front of already-emitted operand
 *
 * Means relocating the operand.
 */
static void
reginsert(op, opnd, rcstate)
int op;
char *opnd;
struct regcomp_state *rcstate;
{
	register char *src;
	register char *dst;
	register char *place;

	if (rcstate->regcode == &regdummy) {
		rcstate->regsize += 3;
		return;
	}

	src = rcstate->regcode;
	rcstate->regcode += 3;
	dst = rcstate->regcode;
	while (src > opnd)
		*--dst = *--src;

	place = opnd;		/* Op node, where operand used to be. */
	*place++ = (char)op;
	*place++ = '\0';
	*place = '\0';
}

/*
 - regtail - set the next-pointer at the end of a node chain
 */
static void
regtail(p, val)
char *p;
char *val;
{
	register char *scan;
	register char *temp;
	register int offset;

	if (p == &regdummy)
		return;

	/* Find last node. */
	scan = p;
	for (;;) {
		temp = regnext(scan);
		if (temp == NULL)
			break;
		scan = temp;
	}

	if (OP(scan) == BACK)
		offset = scan - val;
	else
		offset = val - scan;
	*(scan+1) = (char)((offset>>8)&0377);
	*(scan+2) = (char)(offset&0377);
}

/*
 - regoptail - regtail on operand of first argument; nop if operandless
 */
static void
regoptail(p, val)
char *p;
char *val;
{
	/* "Operandless" and "op != BRANCH" are synonymous in practice. */
	if (p == NULL || p == &regdummy || OP(p) != BRANCH)
		return;
	regtail(OPERAND(p), val);
}

/*
 * TclRegExec and friends
 */

/*
 * Global work variables for TclRegExec().
 */
struct regexec_state  {
    char *reginput;		/* String-input pointer. */
    char *regbol;		/* Beginning of input, for ^ check. */
    char **regstartp;	/* Pointer to startp array. */
    char **regendp;		/* Ditto for endp. */
};

/*
 * Forwards.
 */
static int 		regtry _ANSI_ARGS_((regexp *prog, char *string,
			    struct regexec_state *restate));
static int 		regmatch _ANSI_ARGS_((char *prog,
			    struct regexec_state *restate));
static int 		regrepeat _ANSI_ARGS_((char *p,
			    struct regexec_state *restate));

#ifdef DEBUG
int regnarrate = 0;
void regdump _ANSI_ARGS_((regexp *r));
static char *regprop _ANSI_ARGS_((char *op));
#endif

/*
 - TclRegExec - match a regexp against a string
 */
int
TclRegExec(prog, string, start)
register regexp *prog;
register char *string;
char *start;
{
	register char *s;
	struct regexec_state state;
	struct regexec_state *restate= &state;

	/* Be paranoid... */
	if (prog == NULL || string == NULL) {
		TclRegError("NULL parameter");
		return(0);
	}

	/* Check validity of program. */
	if (UCHARAT(prog->program) != MAGIC) {
		TclRegError("corrupted program");
		return(0);
	}

	/* If there is a "must appear" string, look for it. */
	if (prog->regmust != NULL) {
		s = string;
		while ((s = strchr(s, prog->regmust[0])) != NULL) {
			if (strncmp(s, prog->regmust, (size_t) prog->regmlen)
			    == 0)
				break;	/* Found it. */
			s++;
		}
		if (s == NULL)	/* Not present. */
			return(0);
	}

	/* Mark beginning of line for ^ . */
	restate->regbol = start;

	/* Simplest case:  anchored match need be tried only once. */
	if (prog->reganch)
		return(regtry(prog, string, restate));

	/* Messy cases:  unanchored match. */
	s = string;
	if (prog->regstart != '\0')
		/* We know what char it must start with. */
		while ((s = strchr(s, prog->regstart)) != NULL) {
			if (regtry(prog, s, restate))
				return(1);
			s++;
		}
	else
		/* We don't -- general case. */
		do {
			if (regtry(prog, s, restate))
				return(1);
		} while (*s++ != '\0');

	/* Failure. */
	return(0);
}

/*
 - regtry - try match at specific point
 */
static int			/* 0 failure, 1 success */
regtry(prog, string, restate)
regexp *prog;
char *string;
struct regexec_state *restate;
{
	register int i;
	register char **sp;
	register char **ep;

	restate->reginput = string;
	restate->regstartp = prog->startp;
	restate->regendp = prog->endp;

	sp = prog->startp;
	ep = prog->endp;
	for (i = NSUBEXP; i > 0; i--) {
		*sp++ = NULL;
		*ep++ = NULL;
	}
	if (regmatch(prog->program + 1,restate)) {
		prog->startp[0] = string;
		prog->endp[0] = restate->reginput;
		return(1);
	} else
		return(0);
}

/*
 - regmatch - main matching routine
 *
 * Conceptually the strategy is simple:  check to see whether the current
 * node matches, call self recursively to see whether the rest matches,
 * and then act accordingly.  In practice we make some effort to avoid
 * recursion, in particular by going through "ordinary" nodes (that don't
 * need to know whether the rest of the match failed) by a loop instead of
 * by recursion.
 */
static int			/* 0 failure, 1 success */
regmatch(prog, restate)
char *prog;
struct regexec_state *restate;
{
    register char *scan;	/* Current node. */
    char *next;		/* Next node. */

    scan = prog;
#ifdef DEBUG
    if (scan != NULL && regnarrate)
	fprintf(stderr, "%s(\n", regprop(scan));
#endif
    while (scan != NULL) {
#ifdef DEBUG
	if (regnarrate)
	    fprintf(stderr, "%s...\n", regprop(scan));
#endif
	next = regnext(scan);

	switch (OP(scan)) {
	    case BOL:
		if (restate->reginput != restate->regbol) {
		    return 0;
		}
		break;
	    case EOL:
		if (*restate->reginput != '\0') {
		    return 0;
		}
		break;
	    case ANY:
		if (*restate->reginput == '\0') {
		    return 0;
		}
		restate->reginput++;
		break;
	    case EXACTLY: {
		register int len;
		register char *opnd;

		opnd = OPERAND(scan);
		/* Inline the first character, for speed. */
		if (*opnd != *restate->reginput) {
		    return 0 ;
		}
		len = strlen(opnd);
		if (len > 1 && strncmp(opnd, restate->reginput, (size_t) len)
			!= 0) {
		    return 0;
		}
		restate->reginput += len;
		break;
	    }
	    case ANYOF:
		if (*restate->reginput == '\0'
			|| strchr(OPERAND(scan), *restate->reginput) == NULL) {
		    return 0;
		}
		restate->reginput++;
		break;
	    case ANYBUT:
		if (*restate->reginput == '\0'
			|| strchr(OPERAND(scan), *restate->reginput) != NULL) {
		    return 0;
		}
		restate->reginput++;
		break;
	    case NOTHING:
		break;
	    case BACK:
		break;
	    case OPEN+1:
	    case OPEN+2:
	    case OPEN+3:
	    case OPEN+4:
	    case OPEN+5:
	    case OPEN+6:
	    case OPEN+7:
	    case OPEN+8:
	    case OPEN+9: {
		register int no;
		register char *save;

	doOpen:
		no = OP(scan) - OPEN;
		save = restate->reginput;

		if (regmatch(next,restate)) {
		    /*
		     * Don't set startp if some later invocation of the
		     * same parentheses already has.
		     */
		    if (restate->regstartp[no] == NULL) {
			restate->regstartp[no] = save;
		    }
		    return 1;
		} else {
		    return 0;
		}
	    }
	    case CLOSE+1:
	    case CLOSE+2:
	    case CLOSE+3:
	    case CLOSE+4:
	    case CLOSE+5:
	    case CLOSE+6:
	    case CLOSE+7:
	    case CLOSE+8:
	    case CLOSE+9: {
		register int no;
		register char *save;

	doClose:
		no = OP(scan) - CLOSE;
		save = restate->reginput;

		if (regmatch(next,restate)) {
				/*
				 * Don't set endp if some later
				 * invocation of the same parentheses
				 * already has.
				 */
		    if (restate->regendp[no] == NULL)
			restate->regendp[no] = save;
		    return 1;
		} else {
		    return 0;
		}
	    }
	    case BRANCH: {
		register char *save;

		if (OP(next) != BRANCH) { /* No choice. */
		    next = OPERAND(scan); /* Avoid recursion. */
		} else {
		    do {
			save = restate->reginput;
			if (regmatch(OPERAND(scan),restate))
			    return(1);
			restate->reginput = save;
			scan = regnext(scan);
		    } while (scan != NULL && OP(scan) == BRANCH);
		    return 0;
		}
		break;
	    }
	    case STAR:
	    case PLUS: {
		register char nextch;
		register int no;
		register char *save;
		register int min;

		/*
		 * Lookahead to avoid useless match attempts
		 * when we know what character comes next.
		 */
		nextch = '\0';
		if (OP(next) == EXACTLY)
		    nextch = *OPERAND(next);
		min = (OP(scan) == STAR) ? 0 : 1;
		save = restate->reginput;
		no = regrepeat(OPERAND(scan),restate);
		while (no >= min) {
		    /* If it could work, try it. */
		    if (nextch == '\0' || *restate->reginput == nextch)
			if (regmatch(next,restate))
			    return(1);
		    /* Couldn't or didn't -- back up. */
		    no--;
		    restate->reginput = save + no;
		}
		return(0);
	    }
	    case END:
		return(1);	/* Success! */
	    default:
		if (OP(scan) > OPEN && OP(scan) < OPEN+NSUBEXP) {
		    goto doOpen;
		} else if (OP(scan) > CLOSE && OP(scan) < CLOSE+NSUBEXP) {
		    goto doClose;
		}
		TclRegError("memory corruption");
		return 0;
	}

	scan = next;
    }

    /*
     * We get here only if there's trouble -- normally "case END" is
     * the terminating point.
     */
    TclRegError("corrupted pointers");
    return(0);
}

/*
 - regrepeat - repeatedly match something simple, report how many
 */
static int
regrepeat(p, restate)
char *p;
struct regexec_state *restate;
{
	register int count = 0;
	register char *scan;
	register char *opnd;

	scan = restate->reginput;
	opnd = OPERAND(p);
	switch (OP(p)) {
	case ANY:
		count = strlen(scan);
		scan += count;
		break;
	case EXACTLY:
		while (*opnd == *scan) {
			count++;
			scan++;
		}
		break;
	case ANYOF:
		while (*scan != '\0' && strchr(opnd, *scan) != NULL) {
			count++;
			scan++;
		}
		break;
	case ANYBUT:
		while (*scan != '\0' && strchr(opnd, *scan) == NULL) {
			count++;
			scan++;
		}
		break;
	default:		/* Oh dear.  Called inappropriately. */
		TclRegError("internal foulup");
		count = 0;	/* Best compromise. */
		break;
	}
	restate->reginput = scan;

	return(count);
}

/*
 - regnext - dig the "next" pointer out of a node
 */
static char *
regnext(p)
register char *p;
{
	register int offset;

	if (p == &regdummy)
		return(NULL);

	offset = NEXT(p);
	if (offset == 0)
		return(NULL);

	if (OP(p) == BACK)
		return(p-offset);
	else
		return(p+offset);
}

#ifdef DEBUG

static char *regprop();

/*
 - regdump - dump a regexp onto stdout in vaguely comprehensible form
 */
void
regdump(r)
regexp *r;
{
	register char *s;
	register char op = EXACTLY;	/* Arbitrary non-END op. */
	register char *next;


	s = r->program + 1;
	while (op != END) {	/* While that wasn't END last time... */
		op = OP(s);
		printf("%2d%s", s-r->program, regprop(s));	/* Where, what. */
		next = regnext(s);
		if (next == NULL)		/* Next ptr. */
			printf("(0)");
		else 
			printf("(%d)", (s-r->program)+(next-s));
		s += 3;
		if (op == ANYOF || op == ANYBUT || op == EXACTLY) {
			/* Literal string, where present. */
			while (*s != '\0') {
				putchar(*s);
				s++;
			}
			s++;
		}
		putchar('\n');
	}

	/* Header fields of interest. */
	if (r->regstart != '\0')
		printf("start `%c' ", r->regstart);
	if (r->reganch)
		printf("anchored ");
	if (r->regmust != NULL)
		printf("must have \"%s\"", r->regmust);
	printf("\n");
}

/*
 - regprop - printable representation of opcode
 */
static char *
regprop(op)
char *op;
{
	register char *p;
	static char buf[50];

	(void) strcpy(buf, ":");

	switch (OP(op)) {
	case BOL:
		p = "BOL";
		break;
	case EOL:
		p = "EOL";
		break;
	case ANY:
		p = "ANY";
		break;
	case ANYOF:
		p = "ANYOF";
		break;
	case ANYBUT:
		p = "ANYBUT";
		break;
	case BRANCH:
		p = "BRANCH";
		break;
	case EXACTLY:
		p = "EXACTLY";
		break;
	case NOTHING:
		p = "NOTHING";
		break;
	case BACK:
		p = "BACK";
		break;
	case END:
		p = "END";
		break;
	case OPEN+1:
	case OPEN+2:
	case OPEN+3:
	case OPEN+4:
	case OPEN+5:
	case OPEN+6:
	case OPEN+7:
	case OPEN+8:
	case OPEN+9:
		sprintf(buf+strlen(buf), "OPEN%d", OP(op)-OPEN);
		p = NULL;
		break;
	case CLOSE+1:
	case CLOSE+2:
	case CLOSE+3:
	case CLOSE+4:
	case CLOSE+5:
	case CLOSE+6:
	case CLOSE+7:
	case CLOSE+8:
	case CLOSE+9:
		sprintf(buf+strlen(buf), "CLOSE%d", OP(op)-CLOSE);
		p = NULL;
		break;
	case STAR:
		p = "STAR";
		break;
	case PLUS:
		p = "PLUS";
		break;
	default:
		if (OP(op) > OPEN && OP(op) < OPEN+NSUBEXP) {
		    sprintf(buf+strlen(buf), "OPEN%d", OP(op)-OPEN);
		    p = NULL;
		    break;
		} else if (OP(op) > CLOSE && OP(op) < CLOSE+NSUBEXP) {
		    sprintf(buf+strlen(buf), "CLOSE%d", OP(op)-CLOSE);
		    p = NULL;
		} else {
		    TclRegError("corrupted opcode");
		}
		break;
	}
	if (p != NULL)
		(void) strcat(buf, p);
	return(buf);
}
#endif

/*
 * The following is provided for those people who do not have strcspn() in
 * their C libraries.  They should get off their butts and do something
 * about it; at least one public-domain implementation of those (highly
 * useful) string routines has been published on Usenet.
 */
#ifdef STRCSPN
/*
 * strcspn - find length of initial segment of s1 consisting entirely
 * of characters not from s2
 */

static int
strcspn(s1, s2)
char *s1;
char *s2;
{
	register char *scan1;
	register char *scan2;
	register int count;

	count = 0;
	for (scan1 = s1; *scan1 != '\0'; scan1++) {
		for (scan2 = s2; *scan2 != '\0';)	/* ++ moved down. */
			if (*scan1 == *scan2++)
				return(count);
		count++;
	}
	return(count);
}
#endif

/*
 *----------------------------------------------------------------------
 *
 * TclRegError --
 *
 *	This procedure is invoked by the regexp code when an error
 *	occurs.  It saves the error message so it can be seen by the
 *	code that called Spencer's code.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The value of "string" is saved in "errMsg".
 *
 *----------------------------------------------------------------------
 */

void
exp_TclRegError(string)
    char *string;			/* Error message. */
{
    errMsg = string;
}

char *
TclGetRegError()
{
    return errMsg;
}

/*
 * end of regexp definitions and code
 */

/*
 * stolen from exp_log.c - this function is called from the Expect library
 * but the one that the library supplies calls Tcl functions.  So we supply
 * our own.
 */

static
void
expDiagLogU(str)
     char *str;
{
  if (exp_is_debugging) {
    fprintf(stderr,str);
    if (exp_logfile) fprintf(exp_logfile,str);
  }
}

/*
 * expect-specific definitions and code
 */

#include "expect.h"
#include "exp_int.h"

/* exp_glob.c - expect functions for doing glob
 *
 * Based on Tcl's glob functions but modified to support anchors and to
 * return information about the possibility of future matches
 *
 * Modifications by: Don Libes, NIST, 2/6/90
 */

/* The following functions implement expect's glob-style string
 * matching Exp_StringMatch allow's implements the unanchored front
 * (or conversely the '^') feature.  Exp_StringMatch2 does the rest of
 * the work.
 */

/* Exp_StringMatch2 --
 *
 * Like Tcl_StringMatch except that
 * 1) returns number of characters matched, -1 if failed.
 *	(Can return 0 on patterns like "" or "$")
 * 2) does not require pattern to match to end of string
 * 3) much of code is stolen from Tcl_StringMatch
 * 4) front-anchor is assumed (Tcl_StringMatch retries for non-front-anchor)
 */
static
int
Exp_StringMatch2(string,pattern)
    register char *string;	/* String. */
    register char *pattern;	/* Pattern, which may contain
				 * special characters. */
{
    char c2;
    int match = 0;	/* # of chars matched */

    while (1) {
	/* If at end of pattern, success! */
	if (*pattern == 0) {
		return match;
	}

	/* If last pattern character is '$', verify that entire
	 * string has been matched.
	 */
	if ((*pattern == '$') && (pattern[1] == 0)) {
		if (*string == 0) return(match);
		else return(-1);		
	}

	/* Check for a "*" as the next pattern character.  It matches
	 * any substring.  We handle this by calling ourselves
	 * recursively for each postfix of string, until either we
	 * match or we reach the end of the string.
	 */
	
	if (*pattern == '*') {
	    int head_len;
	    char *tail;
	    pattern += 1;
	    if (*pattern == 0) {
		return(strlen(string)+match); /* DEL */
	    }
	    /* find longest match - switched to this on 12/31/93 */
	    head_len = strlen(string);	/* length before tail */
	    tail = string + head_len;
	    while (head_len >= 0) {
		int rc;

		if (-1 != (rc = Exp_StringMatch2(tail, pattern))) {
		    return rc + match + head_len;	/* DEL */
		}
		tail--;
		head_len--;
	    }
	    return -1;					/* DEL */
	}
    
	/*
	 * after this point, all patterns must match at least one
	 * character, so check this
	 */

	if (*string == 0) return -1;

	/* Check for a "?" as the next pattern character.  It matches
	 * any single character.
	 */

	if (*pattern == '?') {
	    goto thisCharOK;
	}

	/* Check for a "[" as the next pattern character.  It is followed
	 * by a list of characters that are acceptable, or by a range
	 * (two characters separated by "-").
	 */
	
	if (*pattern == '[') {
	    pattern += 1;
	    while (1) {
		if ((*pattern == ']') || (*pattern == 0)) {
		    return -1;			/* was 0; DEL */
		}
		if (*pattern == *string) {
		    break;
		}
		if (pattern[1] == '-') {
		    c2 = pattern[2];
		    if (c2 == 0) {
			return -1;		/* DEL */
		    }
		    if ((*pattern <= *string) && (c2 >= *string)) {
			break;
		    }
		    if ((*pattern >= *string) && (c2 <= *string)) {
			break;
		    }
		    pattern += 2;
		}
		pattern += 1;
	    }

	    while (*pattern != ']') {
		if (*pattern == 0) {
		    pattern--;
		    break;
	        }
		pattern += 1;
	    }
	    goto thisCharOK;
	}
    
	/* If the next pattern character is backslash, strip it off
	 * so we do exact matching on the character that follows.
	 */
	
	if (*pattern == '\\') {
	    pattern += 1;
	    if (*pattern == 0) {
		return -1;
	    }
	}

	/* There's no special character.  Just make sure that the next
	 * characters of each string match.
	 */
	
	if (*pattern != *string) {
	    return -1;
	}

	thisCharOK: pattern += 1;
	string += 1;
	match++;
    }
}


static
int	/* returns # of chars that matched */
Exp_StringMatch(string, pattern,offset)
char *string;
char *pattern;
int *offset;	/* offset from beginning of string where pattern matches */
{
	char *s;
	int sm;	/* count of chars matched or -1 */
	int caret = FALSE;
	int star = FALSE;

	*offset = 0;

	if (pattern[0] == '^') {
		caret = TRUE;
		pattern++;
	} else if (pattern[0] == '*') {
		star = TRUE;
	}

	/*
	 * test if pattern matches in initial position.
	 * This handles front-anchor and 1st iteration of non-front-anchor.
	 * Note that 1st iteration must be tried even if string is empty.
	 */

	sm = Exp_StringMatch2(string,pattern);
	if (sm >= 0) return(sm);

	if (caret) return -1;
	if (star) return -1;

	if (*string == '\0') return -1;

	for (s = string+1;*s;s++) {
 		sm = Exp_StringMatch2(s,pattern);
		if (sm != -1) {
			*offset = s-string;
			return(sm);
		}
	}
	return -1;
}


#define EXP_MATCH_MAX	2000
/* public */
char *exp_buffer = 0;
char *exp_buffer_end = 0;
char *exp_match = 0;
char *exp_match_end = 0;
int exp_match_max = EXP_MATCH_MAX;	/* bytes */
int exp_full_buffer = FALSE;		/* don't return on full buffer */
int exp_remove_nulls = TRUE;
int exp_timeout = 10;			/* seconds */
int exp_pty_timeout = 5;		/* seconds - see CRAY below */
int exp_autoallocpty = TRUE;		/* if TRUE, we do allocation */
int exp_pty[2];				/* master is [0], slave is [1] */
int exp_pid;
char *exp_stty_init = 0;		/* initial stty args */
int exp_ttycopy = TRUE;			/* copy tty parms from /dev/tty */
int exp_ttyinit = TRUE;			/* set tty parms to sane state */
int exp_console = FALSE;		/* redirect console */
void (*exp_child_exec_prelude)() = 0;
void (*exp_close_in_child)() = 0;

#ifdef HAVE_SIGLONGJMP
sigjmp_buf exp_readenv;		/* for interruptable read() */
#else
jmp_buf exp_readenv;		/* for interruptable read() */
#endif /* HAVE_SIGLONGJMP */

int exp_reading = FALSE;	/* whether we can longjmp or not */

int exp_is_debugging = FALSE;
FILE *exp_debugfile = 0;

FILE *exp_logfile = 0;
int exp_logfile_all = FALSE;	/* if TRUE, write log of all interactions */
int exp_loguser = TRUE;		/* if TRUE, user sees interactions on stdout */


char *exp_printify();
int exp_getptymaster();
int exp_getptyslave();

#define sysreturn(x)	return(errno = x, -1)

void exp_init_pty();

/*
   The following functions are linked from the Tcl library.  They
   don't cause anything else in the library to be dragged in, so it
   shouldn't cause any problems (e.g., bloat).

   The functions are relatively small but painful enough that I don't care
   to recode them.  You may, if you absolutely want to get rid of any
   vestiges of Tcl.
*/

static unsigned int bufsiz = 2*EXP_MATCH_MAX;

static struct f {
	int valid;

	char *buffer;		/* buffer of matchable chars */
	char *buffer_end;	/* one beyond end of matchable chars */
	char *match_end;	/* one beyond end of matched string */
	int msize;		/* size of allocate space */
				/* actual size is one larger for null */
} *fs = 0;

static int fd_alloc_max = -1;	/* max fd allocated */

/* translate fd or fp to fd */
static struct f *
fdfp2f(fd,fp)
int fd;
FILE *fp;
{
	if (fd == -1) return(fs + fileno(fp));
	else return(fs + fd);
}

static struct f *
fd_new(fd)
int fd;
{
	int i, low;
	struct f *fp;
	struct f *newfs;	/* temporary, so we don't lose old fs */

	if (fd > fd_alloc_max) {
		if (!fs) {	/* no fd's yet allocated */
			newfs = (struct f *)malloc(sizeof(struct f)*(fd+1));
			low = 0;
		} else {		/* enlarge fd table */
			newfs = (struct f *)realloc((char *)fs,sizeof(struct f)*(fd+1));
			low = fd_alloc_max+1;
		}
		fs = newfs;
		fd_alloc_max = fd;
		for (i = low; i <= fd_alloc_max; i++) { /* init new entries */
			fs[i].valid = FALSE;
		}
	}

	fp = fs+fd;

	if (!fp->valid) {
		/* initialize */
		fp->buffer = malloc((unsigned)(bufsiz+1));
		if (!fp->buffer) return 0;
		fp->msize = bufsiz;
		fp->valid = TRUE;
	}
	fp->buffer_end = fp->buffer;
	fp->match_end = fp->buffer;
	return fp;

}

static
void
exp_setpgrp()
{
#ifdef MIPS_BSD
    /* required on BSD side of MIPS OS <jmsellen@watdragon.waterloo.edu> */
#   include <sysv/sys.s>
    syscall(SYS_setpgrp);
#endif

#ifdef SETPGRP_VOID
    (void) setpgrp();
#else
    (void) setpgrp(0,0);
#endif
}

/* returns fd of master side of pty */
int
exp_spawnv(file,argv)
char *file;
char *argv[];	/* some compiler complains about **argv? */
{
	int cc;
	int errorfd;	/* place to stash fileno(stderr) in child */
			/* while we're setting up new stderr */
	int ttyfd;
	int sync_fds[2];
	int sync2_fds[2];
	int status_pipe[2];
	int child_errno;
	char sync_byte;
#ifdef PTYTRAP_DIES
	int slave_write_ioctls = 1;
		/* by default, slave will be write-ioctled this many times */
#endif

	static int first_time = TRUE;

	if (first_time) {
		first_time = FALSE;
		exp_init_pty();
		exp_init_tty();
		expDiagLogPtrSet(expDiagLogU);

		/*
		 * TIP 27; It is unclear why this code produces a
		 * warning. The equivalent code in exp_main_sub.c
		 * (line 512) does not generate a warning !
		 */

		expErrnoMsgSet(Tcl_ErrnoMsg);
	}

	if (!file || !argv) sysreturn(EINVAL);
	if (!argv[0] || strcmp(file,argv[0])) {
		exp_debuglog("expect: warning: file (%s) != argv[0] (%s)\n",
			file,
			argv[0]?argv[0]:"");
	}

#ifdef PTYTRAP_DIES
/* any extraneous ioctl's that occur in slave must be accounted for
when trapping, see below in child half of fork */
#if defined(TIOCSCTTY) && !defined(CIBAUD) && !defined(sun) && !defined(hp9000s300)
	slave_write_ioctls++;
#endif
#endif /*PTYTRAP_DIES*/

	if (exp_autoallocpty) {
		if (0 > (exp_pty[0] = exp_getptymaster())) sysreturn(ENODEV);
	}
	fcntl(exp_pty[0],F_SETFD,1);	/* close on exec */
#ifdef PTYTRAP_DIES
	exp_slave_control(exp_pty[0],1);*/
#endif

	if (!fd_new(exp_pty[0])) {
		errno = ENOMEM;
		return -1;
	}

	if (-1 == (pipe(sync_fds))) {
		return -1;
	}
	if (-1 == (pipe(sync2_fds))) {
		close(sync_fds[0]);
		close(sync_fds[1]);
		return -1;
	}

	if (-1 == pipe(status_pipe)) {
		close(sync_fds[0]);
		close(sync_fds[1]);
		close(sync2_fds[0]);
		close(sync2_fds[1]);
		return -1;
	}

	if ((exp_pid = fork()) == -1) return(-1);
	if (exp_pid) {
		/* parent */
		close(sync_fds[1]);
		close(sync2_fds[0]);
		close(status_pipe[1]);

		if (!exp_autoallocpty) close(exp_pty[1]);

#ifdef PTYTRAP_DIES
#ifdef HAVE_PTYTRAP
		if (exp_autoallocpty) {
			/* trap initial ioctls in a feeble attempt to not */
			/* block the initially.  If the process itself */
			/* ioctls /dev/tty, such blocks will be trapped */
			/* later during normal event processing */

			while (slave_write_ioctls) {
				int cc;

				cc = exp_wait_for_slave_open(exp_pty[0]);
#if defined(TIOCSCTTY) && !defined(CIBAUD) && !defined(sun) && !defined(hp9000s300)
				if (cc == TIOCSCTTY) slave_write_ioctls = 0;
#endif
				if (cc & IOC_IN) slave_write_ioctls--;
				else if (cc == -1) {
					printf("failed to trap slave pty");
					return -1;
				}
			}
		}
#endif
#endif /*PTYTRAP_DIES*/

		/*
		 * wait for slave to initialize pty before allowing
		 * user to send to it
		 */ 

		exp_debuglog("parent: waiting for sync byte\r\n");
		cc = read(sync_fds[0],&sync_byte,1);
		if (cc == -1) {
		  exp_errorlog("parent sync byte read: %s\r\n",Tcl_ErrnoMsg(errno));
		  return -1;
		}

		/* turn on detection of eof */
		exp_slave_control(exp_pty[0],1);

		/*
		 * tell slave to go on now now that we have initialized pty
		 */

		exp_debuglog("parent: telling child to go ahead\r\n");
		cc = write(sync2_fds[1]," ",1);
		if (cc == -1) {
		  exp_errorlog("parent sync byte write: %s\r\n",Tcl_ErrnoMsg(errno));
		  return -1;
		}

		exp_debuglog("parent: now unsynchronized from child\r\n");

		close(sync_fds[0]);
		close(sync2_fds[1]);

		/* see if child's exec worked */

	retry:
		switch (read(status_pipe[0],&child_errno,sizeof child_errno)) {
		case -1:
			if (errno == EINTR) goto retry;
			/* well it's not really the child's errno */
			/* but it can be treated that way */
			child_errno = errno;
			break;
		case 0:
			/* child's exec succeeded */
			child_errno = 0;
			break;
		default:
			/* child's exec failed; err contains exec's errno  */
			waitpid(exp_pid, NULL, 0);
			errno = child_errno;
			exp_pty[0] = -1;
		}
		close(status_pipe[0]);
		return(exp_pty[0]);
	}

	/*
	 * child process - do not return from here!  all errors must exit()
	 */

	close(sync_fds[0]);
	close(sync2_fds[1]);
	close(status_pipe[0]);
	fcntl(status_pipe[1],F_SETFD,1);	/* close on exec */

#ifdef CRAY
	(void) close(exp_pty[0]);
#endif

/* ultrix (at least 4.1-2) fails to obtain controlling tty if setsid */
/* is called.  setpgrp works though.  */
#if defined(POSIX) && !defined(ultrix)
#define DO_SETSID
#endif
#ifdef __convex__
#define DO_SETSID
#endif

#ifdef DO_SETSID
	setsid();
#else
#ifdef SYSV3
#ifndef CRAY
	exp_setpgrp();
#endif /* CRAY */
#else /* !SYSV3 */
	exp_setpgrp();

#ifdef TIOCNOTTY
	ttyfd = open("/dev/tty", O_RDWR);
	if (ttyfd >= 0) {
		(void) ioctl(ttyfd, TIOCNOTTY, (char *)0);
		(void) close(ttyfd);
	}
#endif /* TIOCNOTTY */

#endif /* SYSV3 */
#endif /* DO_SETSID */

	/* save error fd while we're setting up new one */
	errorfd = fcntl(2,F_DUPFD,3);
	/* and here is the macro to restore it */
#define restore_error_fd {close(2);fcntl(errorfd,F_DUPFD,2);}

	if (exp_autoallocpty) {

	    close(0);
	    close(1);
	    close(2);

	    /* since we closed fd 0, open of pty slave must return fd 0 */

	    if (0 > (exp_pty[1] = exp_getptyslave(exp_ttycopy,exp_ttyinit,
						exp_stty_init))) {
		restore_error_fd
		fprintf(stderr,"open(slave pty): %s\n",Tcl_ErrnoMsg(errno));
		exit(-1);
	    }
	    /* sanity check */
	    if (exp_pty[1] != 0) {
		restore_error_fd
		fprintf(stderr,"exp_getptyslave: slave = %d but expected 0\n",
								exp_pty[1]);
		exit(-1);
	    }
	} else {
		if (exp_pty[1] != 0) {
			close(0);	fcntl(exp_pty[1],F_DUPFD,0);
		}
		close(1);		fcntl(0,F_DUPFD,1);
		close(2);		fcntl(0,F_DUPFD,1);
		close(exp_pty[1]);
	}



/* The test for hpux may have to be more specific.  In particular, the */
/* code should be skipped on the hp9000s300 and hp9000s720 (but there */
/* is no documented define for the 720!) */

#if defined(TIOCSCTTY) && !defined(sun) && !defined(hpux)
	/* 4.3+BSD way to acquire controlling terminal */
	/* according to Stevens - Adv. Prog..., p 642 */
#ifdef __QNX__ /* posix in general */
	if (tcsetct(0, getpid()) == -1) {
	  restore_error_fd
	  expErrorLog("failed to get controlling terminal using TIOCSCTTY");
	  exit(-1);
	}
#else
	(void) ioctl(0,TIOCSCTTY,(char *)0);
	/* ignore return value - on some systems, it is defined but it
	 * fails and it doesn't seem to cause any problems.  Or maybe
	 * it works but returns a bogus code.  Noone seems to be able
	 * to explain this to me.  The systems are an assortment of
	 * different linux systems (and FreeBSD 2.5), RedHat 5.2 and
	 * Debian 2.0
	 */
#endif
#endif

#ifdef CRAY
 	(void) setsid();
 	(void) ioctl(0,TCSETCTTY,0);
 	(void) close(0);
 	if (open("/dev/tty", O_RDWR) < 0) {
		restore_error_fd
 		fprintf(stderr,"open(/dev/tty): %s\r\n",Tcl_ErrnoMsg(errno));
 		exit(-1);
 	}
 	(void) close(1);
 	(void) close(2);
 	(void) dup(0);
 	(void) dup(0);
	setptyutmp();	/* create a utmp entry */

	/* _CRAY2 code from Hal Peterson <hrp@cray.com>, Cray Research, Inc. */
#ifdef _CRAY2
	/*
	 * Interpose a process between expect and the spawned child to
	 * keep the slave side of the pty open to allow time for expect
	 * to read the last output.  This is a workaround for an apparent
	 * bug in the Unicos pty driver on Cray-2's under Unicos 6.0 (at
	 * least).
	 */
	if ((pid = fork()) == -1) {
		restore_error_fd
		fprintf(stderr,"second fork: %s\r\n",Tcl_ErrnoMsg(errno));
		exit(-1);
	}

	if (pid) {
 		/* Intermediate process. */
		int status;
		int timeout;
		char *t;

		/* How long should we wait? */
		timeout = exp_pty_timeout;

		/* Let the spawned process run to completion. */
 		while (wait(&status) < 0 && errno == EINTR)
			/* empty body */;

		/* Wait for the pty to clear. */
		sleep(timeout);

		/* Duplicate the spawned process's status. */
		if (WIFSIGNALED(status))
			kill(getpid(), WTERMSIG(status));

		/* The kill may not have worked, but this will. */
 		exit(WEXITSTATUS(status));
	}
#endif /* _CRAY2 */
#endif /* CRAY */

	if (exp_console) {
#ifdef SRIOCSREDIR
		int fd;

		if ((fd = open("/dev/console", O_RDONLY)) == -1) {
			restore_error_fd
			fprintf(stderr, "spawn %s: cannot open console, check permissions of /dev/console\n",argv[0]);
			exit(-1);
		}
		if (ioctl(fd, SRIOCSREDIR, 0) == -1) {
			restore_error_fd
			fprintf(stderr, "spawn %s: cannot redirect console, check permissions of /dev/console\n",argv[0]);
		}
		close(fd);
#endif

#ifdef TIOCCONS
		int on = 1;
		if (ioctl(0,TIOCCONS,(char *)&on) == -1) {
			restore_error_fd
			fprintf(stderr, "spawn %s: cannot open console, check permissions of /dev/console\n",argv[0]);
			exit(-1);
		}
#endif /* TIOCCONS */
	}

	/* tell parent that we are done setting up pty */
	/* The actual char sent back is irrelevant. */

	/* exp_debuglog("child: telling parent that pty is initialized\r\n");*/
	cc = write(sync_fds[1]," ",1);
	if (cc == -1) {
		restore_error_fd
		fprintf(stderr,"child: sync byte write: %s\r\n",Tcl_ErrnoMsg(errno));
		exit(-1);
	}
	close(sync_fds[1]);

	/* wait for master to let us go on */
	cc = read(sync2_fds[0],&sync_byte,1);
	if (cc == -1) {
		restore_error_fd
		exp_errorlog("child: sync byte read: %s\r\n",Tcl_ErrnoMsg(errno));
		exit(-1);
	}
	close(sync2_fds[0]);

	/* exp_debuglog("child: now unsynchronized from parent\r\n"); */

	/* (possibly multiple) masters are closed automatically due to */
	/* earlier fcntl(,,CLOSE_ON_EXEC); */

	/* just in case, allow user to explicitly close other files */
	if (exp_close_in_child) (*exp_close_in_child)();

	/* allow user to do anything else to child */
	if (exp_child_exec_prelude) (*exp_child_exec_prelude)();

        (void) execvp(file,argv);

	/* Unfortunately, by now we've closed fd's to stderr, logfile
	 * and debugfile.  The only reasonable thing to do is to send
	 * *back the error as part of the program output.  This will
	 * be *picked up in an expect or interact command.
	 */

	write(status_pipe[1], &errno, sizeof errno);
	exit(-1);
	/*NOTREACHED*/
}

/* returns fd of master side of pty */
/*VARARGS*/
int
exp_spawnl TCL_VARARGS_DEF(char *,arg1)
/*exp_spawnl(va_alist)*/
/*va_dcl*/
{
	va_list args; /* problematic line here */
	int i;
	char *arg, **argv;

	arg = TCL_VARARGS_START(char *,arg1,args);
	/*va_start(args);*/
	for (i=1;;i++) {
		arg = va_arg(args,char *);
		if (!arg) break;
	}
	va_end(args);
	if (i == 0) sysreturn(EINVAL);
	if (!(argv = (char **)malloc((i+1)*sizeof(char *)))) sysreturn(ENOMEM);
	argv[0] = TCL_VARARGS_START(char *,arg1,args);
	/*va_start(args);*/
	for (i=1;;i++) {
		argv[i] = va_arg(args,char *);
		if (!argv[i]) break;
	}
	i = exp_spawnv(argv[0],argv+1);
	free((char *)argv);
	return(i);
}

/* allow user-provided fd to be passed to expect funcs */
int
exp_spawnfd(fd)
int fd;
{
	if (!fd_new(fd)) {
		errno = ENOMEM;
		return -1;
	}
	return fd;	
}

/* remove nulls from s.  Initially, the number of chars in s is c, */
/* not strlen(s).  This count does not include the trailing null. */
/* returns number of nulls removed. */
static int
rm_nulls(s,c)
char *s;
int c;
{
	char *s2 = s;	/* points to place in original string to put */
			/* next non-null character */
	int count = 0;
	int i;

	for (i=0;i<c;i++,s++) {
		if (0 == *s) {
			count++;
			continue;
		}
		if (count) *s2 = *s;
		s2++;
	}
	return(count);
}

static int i_read_errno;/* place to save errno, if i_read() == -1, so it
			   doesn't get overwritten before we get to read it */

/*ARGSUSED*/
static void
sigalarm_handler(n)
int n;			/* signal number, unused by us */
{
#ifdef REARM_SIG
	signal(SIGALRM,sigalarm_handler);
#endif

#ifdef HAVE_SIGLONGJMP
	siglongjmp(exp_readenv,1);
#else
	longjmp(exp_readenv,1);
#endif /* HAVE_SIGLONGJMP */
}

/* interruptable read */
static int
i_read(fd,fp,buffer,length,timeout)
int fd;
FILE *fp;
char *buffer;
int length;
int timeout;
{
	int cc = -2;

	/* since setjmp insists on returning 1 upon longjmp(,0), */
	/* longjmp(,2 (EXP_RESTART)) instead. */

	/* no need to set alarm if -1 (infinite) or 0 (poll with */
	/* guaranteed data) */

	if (timeout > 0) alarm(timeout);

	/* restart read if setjmp returns 0 (first time) or 2 (EXP_RESTART). */
	/* abort if setjmp returns 1 (EXP_ABORT). */
#ifdef HAVE_SIGLONGJMP
        if (EXP_ABORT != sigsetjmp(exp_readenv,1)) {
#else
	if (EXP_ABORT != setjmp(exp_readenv)) {
#endif /* HAVE_SIGLONGJMP */
		exp_reading = TRUE;
		if (fd == -1) {
			int c;
			c = getc(fp);
			if (c == EOF) {
/*fprintf(stderr,"<<EOF>>",c);fflush(stderr);*/
				if (feof(fp)) cc = 0;
				else cc = -1;
			} else {
/*fprintf(stderr,"<<%c>>",c);fflush(stderr);*/
				buffer[0] = c;
				cc = 1;
			}
		} else {
#ifndef HAVE_PTYTRAP
			cc = read(fd,buffer,length);
#else
#  include <sys/ptyio.h>

			fd_set rdrs;
			fd_set excep;

		restart:
			FD_ZERO(&rdrs);
			FD_ZERO(&excep);
			FD_SET(fd,&rdrs);
			FD_SET(fd,&excep);
			if (-1 == (cc = select(fd+1,
					 (SELECT_MASK_TYPE *)&rdrs,
					 (SELECT_MASK_TYPE *)0,
					 (SELECT_MASK_TYPE *)&excep,
					 (struct timeval *)0))) {
				/* window refreshes trigger EINTR, ignore */
				if (errno == EINTR) goto restart;
			}
			if (FD_ISSET(fd,&rdrs)) {
				cc = read(fd,buffer,length);
			} else if (FD_ISSET(fd,&excep)) {
				struct request_info ioctl_info;
				ioctl(fd,TIOCREQCHECK,&ioctl_info);
				if (ioctl_info.request == TIOCCLOSE) {
					cc = 0; /* indicate eof */
				} else {
					ioctl(fd, TIOCREQSET, &ioctl_info);
					/* presumably, we trapped an open here */
					goto restart;
				}
			}
#endif /* HAVE_PTYTRAP */
		}
#if 0
		/* can't get fread to return early! */
		else {
			if (!(cc = fread(buffer,1,length,fp))) {
				if (ferror(fp)) cc = -1;
			}
		}
#endif
		i_read_errno = errno;	/* errno can be overwritten by the */
					/* time we return */
	}
	exp_reading = FALSE;

	if (timeout > 0) alarm(0);
	return(cc);
}

/* I tried really hard to make the following two functions share the code */
/* that makes the ecase array, but I kept running into a brick wall when */
/* passing var args into the funcs and then again into a make_cases func */
/* I would very much appreciate it if someone showed me how to do it right */

/* takes triplets of args, with a final "exp_last" arg */
/* triplets are type, pattern, and then int to return */
/* returns negative value if error (or EOF/timeout) occurs */
/* some negative values can also have an associated errno */

/* the key internal variables that this function depends on are:
	exp_buffer
	exp_buffer_end
	exp_match_end
*/
static int
expectv(fd,fp,ecases)
int fd;
FILE *fp;
struct exp_case *ecases;
{
	int cc = 0;		/* number of chars returned in a single read */
	int buf_length;		/* numbers of chars in exp_buffer */
	int old_length;		/* old buf_length */
	int first_time = TRUE;	/* force old buffer to be tested before */
				/* additional reads */
	int polled = 0;		/* true if poll has caused read() to occur */

	struct exp_case *ec;	/* points to current ecase */

	time_t current_time;	/* current time (when we last looked)*/
	time_t end_time;	/* future time at which to give up */
	int remtime;		/* remaining time in timeout */

	struct f *f;
	int return_val;
	int sys_error = 0;
#define return_normally(x)	{return_val = x; goto cleanup;}
#define return_errno(x)	{sys_error = x; goto cleanup;}

	f = fdfp2f(fd,fp);
	if (!f) return_errno(ENOMEM);

	exp_buffer = f->buffer;
	exp_buffer_end = f->buffer_end;
	exp_match_end = f->match_end;

	buf_length = exp_buffer_end - exp_match_end;
	if (buf_length) {
		/*
		 * take end of previous match to end of buffer
		 * and copy to beginning of buffer
		 */
		memmove(exp_buffer,exp_match_end,buf_length);
	}			
	exp_buffer_end = exp_buffer + buf_length;
	*exp_buffer_end = '\0';

	if (!ecases) return_errno(EINVAL);

	/* compile if necessary */
	for (ec=ecases;ec->type != exp_end;ec++) {
		if ((ec->type == exp_regexp) && !ec->re) {
			TclRegError((char *)0);
			if (!(ec->re = TclRegComp(ec->pattern))) {
				fprintf(stderr,"regular expression %s is bad: %s",ec->pattern,TclGetRegError());
				return_errno(EINVAL);
			  }
		  }
	}

	/* get the latest buffer size.  Double the user input for two */
	/* reasons.  1) Need twice the space in case the match */
	/* straddles two bufferfuls, 2) easier to hack the division by */
	/* two when shifting the buffers later on */

	bufsiz = 2*exp_match_max;
	if (f->msize != bufsiz) {
		/* if truncated, forget about some data */
		if (buf_length > bufsiz) {
			/* copy end of buffer down */

			/* copy one less than what buffer can hold to avoid */
			/* triggering buffer-full handling code below */
			/* which will immediately dump the first half */
			/* of the buffer */
			memmove(exp_buffer,exp_buffer+(buf_length - bufsiz)+1,
				bufsiz-1);
			buf_length = bufsiz-1;
		}
		exp_buffer = realloc(exp_buffer,bufsiz+1);
		if (!exp_buffer) return_errno(ENOMEM);
		exp_buffer[buf_length] = '\0';
		exp_buffer_end = exp_buffer + buf_length;
		f->msize = bufsiz;
	}

	/* some systems (i.e., Solaris) require fp be flushed when switching */
	/* directions - do this again afterwards */
	if (fd == -1) fflush(fp);

	if (exp_timeout != -1) signal(SIGALRM,sigalarm_handler);

	/* remtime and current_time updated at bottom of loop */
	remtime = exp_timeout;

	time(&current_time);
	end_time = current_time + remtime;

	for (;;) {
		/* when buffer fills, copy second half over first and */
		/* continue, so we can do matches over multiple buffers */
		if (buf_length == bufsiz) {
			int first_half, second_half;

			if (exp_full_buffer) {
				exp_debuglog("expect: full buffer\r\n");
				exp_match = exp_buffer;
				exp_match_end = exp_buffer + buf_length;
				exp_buffer_end = exp_match_end;
				return_normally(EXP_FULLBUFFER);
			}
			first_half = bufsiz/2;
			second_half = bufsiz - first_half;

			memcpy(exp_buffer,exp_buffer+first_half,second_half);
			buf_length = second_half;
			exp_buffer_end = exp_buffer + second_half;
		}

		/*
		 * always check first if pattern is already in buffer
		 */
		if (first_time) {
			first_time = FALSE;
			goto after_read;
		}

		/*
		 * check for timeout
 		 * we should timeout if either
 		 *   1) exp_timeout > remtime <= 0 (normal)
 		 *   2) exp_timeout == 0 and we have polled at least once
		 * 
		 */
		if (((exp_timeout > remtime) && (remtime <= 0)) ||
 		    ((exp_timeout == 0) && polled)) {
			exp_debuglog("expect: timeout\r\n");
			exp_match_end = exp_buffer;
			return_normally(EXP_TIMEOUT);
		}

 		/* remember that we have actually checked at least once */
 		polled = 1;

		cc = i_read(fd,fp,
				exp_buffer_end,
				bufsiz - buf_length,
				remtime);

		if (cc == 0) {
			exp_debuglog("expect: eof\r\n");
			return_normally(EXP_EOF);	/* normal EOF */
		} else if (cc == -1) {			/* abnormal EOF */
			/* ptys produce EIO upon EOF - sigh */
			if (i_read_errno == EIO) {
				/* convert to EOF indication */
				exp_debuglog("expect: eof\r\n");
				return_normally(EXP_EOF);
			}
			exp_debuglog("expect: error (errno = %d)\r\n",i_read_errno);
			return_errno(i_read_errno);
		} else if (cc == -2) {
			exp_debuglog("expect: timeout\r\n");
			exp_match_end = exp_buffer;
			return_normally(EXP_TIMEOUT);
		}

		old_length = buf_length;
		buf_length += cc;
		exp_buffer_end += buf_length;

		if (exp_logfile_all || (exp_loguser && exp_logfile)) {
			fwrite(exp_buffer + old_length,1,cc,exp_logfile);
		}
		if (exp_loguser) fwrite(exp_buffer + old_length,1,cc,stdout);
		if (exp_debugfile) fwrite(exp_buffer + old_length,1,cc,exp_debugfile);

		/* if we wrote to any logs, flush them */
		if (exp_debugfile) fflush(exp_debugfile);
		if (exp_loguser) {
			fflush(stdout);
			if (exp_logfile) fflush(exp_logfile);
		}

		/* remove nulls from input, so we can use C-style strings */
		/* doing it here lets them be sent to the screen, just */
		/*  in case they are involved in formatting operations */
		if (exp_remove_nulls) {
			buf_length -= rm_nulls(exp_buffer + old_length, cc);
		}
		/* cc should be decremented as well, but since it will not */
		/* be used before being set again, there is no need */
		exp_buffer_end = exp_buffer + buf_length;
		*exp_buffer_end = '\0';
                exp_match_end = exp_buffer;

	after_read:
		exp_debuglog("expect: does {%s} match ",exp_printify(exp_buffer));
		/* pattern supplied */
		for (ec=ecases;ec->type != exp_end;ec++) {
			int matched = -1;

			exp_debuglog("{%s}? ",exp_printify(ec->pattern));
			if (ec->type == exp_glob) {
				int offset;
				matched = Exp_StringMatch(exp_buffer,ec->pattern,&offset);
				if (matched >= 0) {
					exp_match = exp_buffer + offset;
					exp_match_end = exp_match + matched;
				}
			} else if (ec->type == exp_exact) {
				char *p = strstr(exp_buffer,ec->pattern);
				if (p) {
					matched = 1;
					exp_match = p;
					exp_match_end = p + strlen(ec->pattern);
				}
			} else if (ec->type == exp_null) {
				char *p;

				for (p=exp_buffer;p<exp_buffer_end;p++) {
					if (*p == 0) {
						matched = 1;
						exp_match = p;
						exp_match_end = p+1;
					}
				}
			} else {
				TclRegError((char *)0);
				if (TclRegExec(ec->re,exp_buffer,exp_buffer)) {
					matched = 1;
					exp_match = ec->re->startp[0];
					exp_match_end = ec->re->endp[0];
				} else if (TclGetRegError()) {
			    		fprintf(stderr,"r.e. match (pattern %s) failed: %s",ec->pattern,TclGetRegError());
				}
			}

			if (matched != -1) {
				exp_debuglog("yes\nexp_buffer is {%s}\n",
						exp_printify(exp_buffer));
				return_normally(ec->value);
			} else exp_debuglog("no\n");
		}

		/*
		 * Update current time and remaining time.
		 * Don't bother if we are waiting forever or polling.
		 */
		if (exp_timeout > 0) {
			time(&current_time);
			remtime = end_time - current_time;
		}
	}
 cleanup:
	f->buffer     = exp_buffer;
	f->buffer_end = exp_buffer_end;
	f->match_end  = exp_match_end;

	/* some systems (i.e., Solaris) require fp be flushed when switching */
	/* directions - do this before as well */
	if (fd == -1) fflush(fp);

	if (sys_error) {
		errno = sys_error;
		return -1;
	}
	return return_val;
}

int
exp_fexpectv(fp,ecases)
FILE *fp;
struct exp_case *ecases;
{
	return(expectv(-1,fp,ecases));
}

int
exp_expectv(fd,ecases)
int fd;
struct exp_case *ecases;
{
	return(expectv(fd,(FILE *)0,ecases));
}

/*VARARGS*/
int
exp_expectl TCL_VARARGS_DEF(int,arg1)
/*exp_expectl(va_alist)*/
/*va_dcl*/
{
	va_list args;
	int fd;
	struct exp_case *ec, *ecases;
	int i;
	enum exp_type type;

	fd = TCL_VARARGS_START(int,arg1,args);
	/* va_start(args);*/
	/* fd = va_arg(args,int);*/
	/* first just count the arg sets */
	for (i=0;;i++) {
		type = va_arg(args,enum exp_type);
		if (type == exp_end) break;

		/* Ultrix 4.2 compiler refuses enumerations comparison!? */
		if ((int)type < 0 || (int)type >= (int)exp_bogus) {
			fprintf(stderr,"bad type (set %d) in exp_expectl\n",i);
			sysreturn(EINVAL);
		}

		va_arg(args,char *);		/* COMPUTED BUT NOT USED */
		if (type == exp_compiled) {
			va_arg(args,regexp *);	/* COMPUTED BUT NOT USED */
		}
		va_arg(args,int);		/* COMPUTED BUT NOT USED*/
	}
	va_end(args);

	if (!(ecases = (struct exp_case *)
				malloc((1+i)*sizeof(struct exp_case))))
		sysreturn(ENOMEM);

	/* now set up the actual cases */
	fd = TCL_VARARGS_START(int,arg1,args);
	/*va_start(args);*/
	/*va_arg(args,int);*/		/*COMPUTED BUT NOT USED*/
	for (ec=ecases;;ec++) {
		ec->type = va_arg(args,enum exp_type);
		if (ec->type == exp_end) break;
		ec->pattern = va_arg(args,char *);
		if (ec->type == exp_compiled) {
			ec->re = va_arg(args,regexp *);
		} else {
			ec->re = 0;
		}
		ec->value = va_arg(args,int);
	}
	va_end(args);
	i = expectv(fd,(FILE *)0,ecases);

	for (ec=ecases;ec->type != exp_end;ec++) {
		/* free only if regexp and we compiled it for user */
		if (ec->type == exp_regexp) {
			free((char *)ec->re);
		}
	}
	free((char *)ecases);
	return(i);
}

int
exp_fexpectl TCL_VARARGS_DEF(FILE *,arg1)
/*exp_fexpectl(va_alist)*/
/*va_dcl*/
{
	va_list args;
	FILE *fp;
	struct exp_case *ec, *ecases;
	int i;
	enum exp_type type;

	fp = TCL_VARARGS_START(FILE *,arg1,args);
	/*va_start(args);*/
	/*fp = va_arg(args,FILE *);*/
	/* first just count the arg-pairs */
	for (i=0;;i++) {
		type = va_arg(args,enum exp_type);
		if (type == exp_end) break;

		/* Ultrix 4.2 compiler refuses enumerations comparison!? */
		if ((int)type < 0 || (int)type >= (int)exp_bogus) {
			fprintf(stderr,"bad type (set %d) in exp_expectl\n",i);
			sysreturn(EINVAL);
		}

		va_arg(args,char *);		/* COMPUTED BUT NOT USED */
		if (type == exp_compiled) {
			va_arg(args,regexp *);	/* COMPUTED BUT NOT USED */
		}
		va_arg(args,int);		/* COMPUTED BUT NOT USED*/
	}
	va_end(args);

	if (!(ecases = (struct exp_case *)
					malloc((1+i)*sizeof(struct exp_case))))
		sysreturn(ENOMEM);

#if 0
	va_start(args);
	va_arg(args,FILE *);		/*COMPUTED, BUT NOT USED*/
#endif
	(void) TCL_VARARGS_START(FILE *,arg1,args);

	for (ec=ecases;;ec++) {
		ec->type = va_arg(args,enum exp_type);
		if (ec->type == exp_end) break;
		ec->pattern = va_arg(args,char *);
		if (ec->type == exp_compiled) {
			ec->re = va_arg(args,regexp *);
		} else {
			ec->re = 0;
		}
		ec->value = va_arg(args,int);
	}
	va_end(args);
	i = expectv(-1,fp,ecases);

	for (ec=ecases;ec->type != exp_end;ec++) {
		/* free only if regexp and we compiled it for user */
		if (ec->type == exp_regexp) {
			free((char *)ec->re);
		}
	}
	free((char *)ecases);
	return(i);
}

/* like popen(3) but works in both directions */
FILE *
exp_popen(program)
char *program;
{
	FILE *fp;
	int ec;

	if (0 > (ec = exp_spawnl("sh","sh","-c",program,(char *)0))) return(0);
	if (!(fp = fdopen(ec,"r+"))) return(0);
	setbuf(fp,(char *)0);
	return(fp);
}

int
exp_disconnect()
{
	int ttyfd;

#ifndef EALREADY
#define EALREADY 37
#endif

	/* presumably, no stderr, so don't bother with error message */
	if (exp_disconnected) sysreturn(EALREADY);
	exp_disconnected = TRUE;

	freopen("/dev/null","r",stdin);
	freopen("/dev/null","w",stdout);
	freopen("/dev/null","w",stderr);

#ifdef POSIX
	setsid();
#else
#ifdef SYSV3
	/* put process in our own pgrp, and lose controlling terminal */
	exp_setpgrp();
	signal(SIGHUP,SIG_IGN);
	if (fork()) exit(0);	/* first child exits (as per Stevens, */
	/* UNIX Network Programming, p. 79-80) */
	/* second child process continues as daemon */
#else /* !SYSV3 */
	exp_setpgrp();
/* Pyramid lacks this defn */
#ifdef TIOCNOTTY
	ttyfd = open("/dev/tty", O_RDWR);
	if (ttyfd >= 0) {
		/* zap controlling terminal if we had one */
		(void) ioctl(ttyfd, TIOCNOTTY, (char *)0);
		(void) close(ttyfd);
	}
#endif /* TIOCNOTTY */
#endif /* SYSV3 */
#endif /* POSIX */
	return(0);
}

/* send to log if open and debugging enabled */
/* send to stderr if debugging enabled */
/* use this function for recording unusual things in the log */
/*VARARGS*/
void
exp_debuglog TCL_VARARGS_DEF(char *,arg1)
{
    char *fmt;
    va_list args;

    fmt = TCL_VARARGS_START(char *,arg1,args);
    if (exp_debugfile) vfprintf(exp_debugfile,fmt,args);
    if (exp_is_debugging) {
	vfprintf(stderr,fmt,args);
	if (exp_logfile) vfprintf(exp_logfile,fmt,args);
    }

    va_end(args);
}


/* send to log if open */
/* send to stderr */
/* use this function for error conditions */
/*VARARGS*/
void
exp_errorlog TCL_VARARGS_DEF(char *,arg1)
{
    char *fmt;
    va_list args;
    
    fmt = TCL_VARARGS_START(char *,arg1,args);
    vfprintf(stderr,fmt,args);
    if (exp_debugfile) vfprintf(exp_debugfile,fmt,args);
    if (exp_logfile) vfprintf(exp_logfile,fmt,args);
    va_end(args);
}

#include <ctype.h>

char *
exp_printify(s)
char *s;
{
	static int destlen = 0;
	static char *dest = 0;
	char *d;		/* ptr into dest */
	unsigned int need;

	if (s == 0) return("<null>");

	/* worst case is every character takes 4 to printify */
	need = strlen(s)*4 + 1;
	if (need > destlen) {
		if (dest) ckfree(dest);
		dest = ckalloc(need);
		destlen = need;
	}

	for (d = dest;*s;s++) {
		if (*s == '\r') {
			strcpy(d,"\\r");		d += 2;
		} else if (*s == '\n') {
			strcpy(d,"\\n");		d += 2;
		} else if (*s == '\t') {
			strcpy(d,"\\t");		d += 2;
		} else if (isascii(*s) && isprint(*s)) {
			*d = *s;			d += 1;
		} else {
			sprintf(d,"\\x%02x",*s & 0xff);	d += 4;
		}
	}
	*d = '\0';
	return(dest);
}
