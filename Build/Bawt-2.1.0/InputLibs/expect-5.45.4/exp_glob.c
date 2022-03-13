/* exp_glob.c - expect functions for doing glob

Based on Tcl's glob functions but modified to support anchors and to
return information about the possibility of future matches

Modifications by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.

*/

#include "expect_cf.h"
#include "tcl.h"
#include "exp_int.h"

/* Proper forward declaration of internal function */
static int
Exp_StringCaseMatch2 _ANSI_ARGS_((CONST Tcl_UniChar *string, /* String. */
				  CONST Tcl_UniChar *stop,   /* First char _after_ string */
				  CONST Tcl_UniChar *pattern,	 /* Pattern, which may contain
								  * special characters. */
				  CONST Tcl_UniChar *pstop,   /* First char _after_ pattern */
				  int nocase));

/* The following functions implement expect's glob-style string matching */
/* Exp_StringMatch allow's implements the unanchored front (or conversely */
/* the '^') feature.  Exp_StringMatch2 does the rest of the work. */

int	/* returns # of CHARS that matched */
Exp_StringCaseMatch(string, strlen, pattern, plen, nocase, offset)		/* INTL */
     Tcl_UniChar *string;
     Tcl_UniChar *pattern;
     int strlen;
     int plen;
     int nocase;
     int *offset;	/* offset in chars from beginning of string where pattern matches */
{
    CONST Tcl_UniChar *s;
    CONST Tcl_UniChar *stop = string + strlen;
    CONST Tcl_UniChar *pstop = pattern + plen;
    int ssm, sm;	/* count of bytes matched or -1 */
    int caret = FALSE;
    int star = FALSE;

#ifdef EXP_INTERNAL_TRACE_GLOB
    expDiagLog("\nESCM pattern(%d)=\"",plen);
    expDiagLogU(expPrintifyUni(pattern,plen));
    expDiagLog("\"\n");
    expDiagLog("      string(%d)=\"",strlen);
    expDiagLogU(expPrintifyUni(string,strlen));
    expDiagLog("\"\n");
    expDiagLog("      nocase=%d\n",nocase);
#endif

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

    sm = Exp_StringCaseMatch2(string,stop,pattern,pstop,nocase);

#ifdef EXP_INTERNAL_TRACE_GLOB
    expDiagLog("@0 => %d\n",sm);
#endif

    if (sm >= 0) return(sm);

    if (caret) return -1;
    if (star) return -1;

    if (*string == '\0') return -1;

    s = string + 1;
    sm = 0;
#if 0
    if ((*pattern != '[') && (*pattern != '?')
	&& (*pattern != '\\') && (*pattern != '$')
	&& (*pattern != '*')) {
	while (*s && (s < stop) && *pattern != *s) {
	    s++;
	    sm++;
	}
    }
    if (sm) {
	printf("skipped %d chars of %d\n", sm, strlen); fflush(stdout);
    }
#endif
    for (;s < stop; s++) {
	ssm = Exp_StringCaseMatch2(s,stop,pattern,pstop,nocase);

#ifdef EXP_INTERNAL_TRACE_GLOB
	expDiagLog("@%d => %d\n",s-string,ssm);
#endif

	if (ssm != -1) {
	    *offset = s-string;
	    return(ssm+sm);
	}
    }
    return -1;
}

/* Exp_StringCaseMatch2 --
 *
 * Like Tcl_StringCaseMatch except that
 * 1: returns number of characters matched, -1 if failed.
 *    (Can return 0 on patterns like "" or "$")
 * 2: does not require pattern to match to end of string
 * 3: Much of code is stolen from Tcl_StringMatch
 * 4: front-anchor is assumed (Tcl_StringMatch retries for non-front-anchor)
*/

static int
Exp_StringCaseMatch2(string,stop,pattern,pstop,nocase)	/* INTL */
     register CONST Tcl_UniChar *string; /* String. */
     register CONST Tcl_UniChar *stop;   /* First char _after_ string */
     register CONST Tcl_UniChar *pattern;	 /* Pattern, which may contain
				 * special characters. */
     register CONST Tcl_UniChar *pstop;   /* First char _after_ pattern */
    int nocase;
{
    Tcl_UniChar ch1, ch2, p;
    int match = 0;	/* # of bytes matched */
    CONST Tcl_UniChar *oldString;

#ifdef EXP_INTERNAL_TRACE_GLOB
    expDiagLog("    ESCM2 pattern=\"");
    expDiagLogU(expPrintifyUni(pattern,pstop-pattern));
    expDiagLog("\"\n");
    expDiagLog("           string=\"");
    expDiagLogU(expPrintifyUni(string,stop-string));
    expDiagLog("\"\n");
    expDiagLog("           nocase=%d\n",nocase);
#endif

    while (1) {
#ifdef EXP_INTERNAL_TRACE_GLOB
	expDiagLog("          * ==========\n");
	expDiagLog("          * pattern=\"");
	expDiagLogU(expPrintifyUni(pattern,pstop-pattern));
	expDiagLog("\"\n");
	expDiagLog("          *  string=\"");
	expDiagLogU(expPrintifyUni(string,stop-string));
	expDiagLog("\"\n");
#endif
	/* If at end of pattern, success! */
	if (pattern >= pstop) {
		return match;
	}

	/* If last pattern character is '$', verify that entire
	 * string has been matched.
	 */
	if ((*pattern == '$') && ((pattern + 1) >= pstop)) {
		if (string == stop) return(match);
		else return(-1);		
	}

	/* Check for a "*" as the next pattern character.  It matches
	 * any substring.  We handle this by calling ourselves
	 * recursively for each postfix of string, until either we match
	 * or we reach the end of the string.
	 *
	 * ZZZ: Check against Tcl core, port optimizations found there over here.
	 */
	
	if (*pattern == '*') {
	    CONST Tcl_UniChar *tail;

	    /*
	     * Skip all successive *'s in the pattern
	     */
	    while ((pattern < pstop) && (*pattern == '*')) {
		++pattern;
	    }

	    if (pattern >= pstop) {
		return((stop-string)+match); /* DEL */
	    }

	    p = *pattern;
	    if (nocase) {
		p = Tcl_UniCharToLower(p);
	    }

	    /* find LONGEST match */

	    /*
	     * NOTES
	     *
	     * The original code used 'strlen' to find the end of the
	     * string. With the recursion coming this was done over and
	     * over again, making this an O(n**2) operation overall. Now
	     * the pointer to the end is passed in from the caller, and
	     * even the topmost context now computes it from start and
	     * length instead of seaching.
	     *
	     * The conversion to unicode also allow us to step back via
	     * decrement, in linear time overall. The previously used
	     * Tcl_UtfPrev crawled to the previous character from the
	     * beginning of the string, another O(n**2) operation.
	     */

	    tail = stop - 1;
	    while (1) {
		int rc;
#ifdef EXP_INTERNAL_TRACE_GLOB
		expDiagLog(" skip back '%c'\n",p);
#endif
		/*
		 * Optimization for matching - cruise through the string
		 * quickly if the next char in the pattern isn't a special
		 * character.
		 *
		 * NOTE: We cruise backwards to keep the semantics of
		 * finding the LONGEST match.
		 *
		 * XXX JH: should this add '&& (p != '$')' ???
		 */
		if ((p != '[') && (p != '?') && (p != '\\')) {
		    if (nocase) {
			while ((tail >= string) && (p != *tail)
			       && (p != Tcl_UniCharToLower(*tail))) {
			    tail--;;
			}
		    } else {
			/*
			 * XXX JH: Should this be (tail > string)?
			 * ZZZ AK: No. tail == string is perfectly acceptable,
			 *         if p == *tail. Backing before string is ok too,
			 *         that is the condition to break the outer loop.
			 */
			while ((tail >= string) && (p != *tail)) { tail --; }
		    }
		}

		/* if we've backed up to before the beginning of string, give up */
		if (tail < string) break;

		rc = Exp_StringCaseMatch2(tail, stop, pattern, pstop, nocase);
#ifdef EXP_INTERNAL_TRACE_GLOB
		expDiagLog(" (*) rc=%d\n",rc);
#endif
		if (rc != -1 ) {
		    return match + (tail - string) + rc;
		    /* match = # of bytes we've skipped before this */
		    /* (...) = # of bytes we've skipped due to "*" */
		    /* rc    = # of bytes we've matched after "*" */
		}

		/* if we've backed up to beginning of string, give up */
		if (tail == string) break;

		tail --;
		if (tail < string) tail = string;
	    }
	    return -1;					/* DEL */
	}
    
	/*
	 * after this point, all patterns must match at least one
	 * character, so check this
	 */

	if (string >= stop) return -1;

	/* Check for a "?" as the next pattern character.  It matches
	 * any single character.
	 */

	if (*pattern == '?') {
	    pattern++;
	    oldString = string;
	    string ++;
	    match ++; /* incr by # of matched chars */
	    continue;
	}

	/* Check for a "[" as the next pattern character.  It is
	 * followed by a list of characters that are acceptable, or by a
	 * range (two characters separated by "-").
	 */
	
	if (*pattern == '[') {
	    Tcl_UniChar ch, startChar, endChar;

#ifdef EXP_INTERNAL_TRACE_GLOB
	    expDiagLog("          class\n");
#endif
	    pattern++;
	    oldString = string;
	    ch = *string++;

	    while (1) {
		if ((pattern >= pstop) || (*pattern == ']')) {
#ifdef EXP_INTERNAL_TRACE_GLOB
		    expDiagLog("          end-of-pattern or class/1\n");
#endif
		    return -1;			/* was 0; DEL */
		}
		startChar = *pattern ++;
		if (nocase) {
		    startChar = Tcl_UniCharToLower(startChar);
		}
		if (*pattern == '-') {
		    pattern++;
		    if (pattern >= pstop) {
#ifdef EXP_INTERNAL_TRACE_GLOB
			expDiagLog("          end-of-pattern/2\n");
#endif
			return -1;		/* DEL */
		    }
		    endChar = *pattern ++;
		    if (nocase) {
			endChar = Tcl_UniCharToLower(endChar);
		    }
		    if (((startChar <= ch) && (ch <= endChar))
			    || ((endChar <= ch) && (ch <= startChar))) {
			/*
			 * Matches ranges of form [a-z] or [z-a].
			 */

#ifdef EXP_INTERNAL_TRACE_GLOB
			expDiagLog("          matched-range\n");
#endif
			break;
		    }
		} else if (startChar == ch) {
#ifdef EXP_INTERNAL_TRACE_GLOB
		    expDiagLog("          matched-char\n");
#endif
		    break;
		}
	    }
	    while ((pattern < pstop) && (*pattern != ']')) {
		pattern++;
	    }
	    if (pattern < pstop) {
		/*
		 * Skip closing bracket if there was any.
		 * Fixes SF Bug 1873404.
		 */
		pattern++;
	    }
#ifdef EXP_INTERNAL_TRACE_GLOB
	    expDiagLog("          skipped remainder of pattern\n");
#endif
	    match += (string - oldString); /* incr by # matched chars */
	    continue;
	}
 
	/* If the next pattern character is backslash, strip it off so
	 * we do exact matching on the character that follows.
	 */
	
	if (*pattern == '\\') {
	    pattern ++;
	    if (pattern >= pstop) {
		return -1;
	    }
	}

	/* There's no special character.  Just make sure that the next
	 * characters of each string match.
	 */
	
	oldString = string;
	ch1 = *string ++;
	ch2 = *pattern ++;
	if (nocase) {
	    if (Tcl_UniCharToLower(ch1) != Tcl_UniCharToLower(ch2)) {
		return -1;
	    }
	} else if (ch1 != ch2) {
	    return -1;
	}
	match += (string - oldString);  /* incr by # matched chars */
    }
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
