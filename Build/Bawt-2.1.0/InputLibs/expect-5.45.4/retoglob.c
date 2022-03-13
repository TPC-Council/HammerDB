/*
 * re2glob - C implementation
 * (c) 2007 ActiveState Software Inc.
 */

#include <tcl.h>

#define DEBUG 0

static void
ExpChopNested _ANSI_ARGS_ ((Tcl_UniChar** xstr,
			    int*          xstrlen,
			    Tcl_UniChar   open,
			    Tcl_UniChar   close));

static Tcl_UniChar*
ExpLiteral _ANSI_ARGS_ ((Tcl_UniChar* nexto,
			 Tcl_UniChar* str,
			 int          strlen));

static Tcl_UniChar*
ExpCollapseStar _ANSI_ARGS_ ((Tcl_UniChar* src,
			      Tcl_UniChar* last));
static Tcl_UniChar*
ExpCollapseQForward _ANSI_ARGS_ ((Tcl_UniChar* src,
				  Tcl_UniChar* last));

static Tcl_UniChar*
ExpCollapseQBack _ANSI_ARGS_ ((Tcl_UniChar* src,
			       Tcl_UniChar* last));

static Tcl_UniChar
ExpBackslash _ANSI_ARGS_ ((char prefix,
			 Tcl_UniChar* str,
			 int          strlen));

static int
ExpCountStar _ANSI_ARGS_ ((Tcl_UniChar* src, Tcl_UniChar* last));


static char*
xxx (Tcl_UniChar* x, int xl)
{
  static Tcl_DString ds;
  Tcl_DStringInit (&ds);
  return Tcl_UniCharToUtfDString (x,xl,&ds);
}


Tcl_Obj*
exp_retoglob (
    Tcl_UniChar* str,
    int          strlen)
{
  /*
   * Output: x2 size of input (literal where every character has to be
   * quoted.
   * Location: For next translated unit, in output.
   * Size of last generated unit, in characters.
   * Stack of output locations at opening parens. x1 size of input.
   * Location for next location on stack.
   */

  static Tcl_UniChar litprefix [] = {'*','*','*','='};
  static Tcl_UniChar areprefix [] = {'*','*','*',':'};
  static Tcl_UniChar areopts   [] = {'(','?'};
  static Tcl_UniChar nocapture [] = {'?',':'};
  static Tcl_UniChar lookhas   [] = {'?','='};
  static Tcl_UniChar looknot   [] = {'?','!'};
  static Tcl_UniChar xcomment  [] = {'?','#'};

  static Tcl_UniChar classa  [] = {'[','.'};
  static Tcl_UniChar classb  [] = {'[','='};
  static Tcl_UniChar classc  [] = {'[',':'};


  int lastsz, expanded;
  Tcl_UniChar*  out;
  Tcl_UniChar*  nexto;
  Tcl_UniChar** paren;
  Tcl_UniChar** nextp;
  Tcl_Obj*     glob = NULL;
  Tcl_UniChar* mark;
  Tcl_UniChar  ch;

  /*
   * Set things up.
   */

  out    = nexto = (Tcl_UniChar*)  Tcl_Alloc (strlen*2*sizeof (Tcl_UniChar));
  paren  = nextp = (Tcl_UniChar**) Tcl_Alloc (strlen*  sizeof (Tcl_UniChar*));
  lastsz = -1;
  expanded = 0;

  /*
   * Start processing ...
   */

#define CHOP(n)  {str += (n); strlen -= (n);}
#define CHOPC(c) {while (*str != (c) && strlen) CHOP(1) ;}
#define EMIT(c)  {lastsz = 1; *nexto++ = (c);}
#define EMITX(c) {lastsz++;   *nexto++ = (c);}
#define MATCH(lit) ((strlen >= (sizeof (lit)/sizeof (Tcl_UniChar))) && (0 == Tcl_UniCharNcmp (str,(lit),sizeof(lit)/sizeof (Tcl_UniChar))))
#define MATCHC(c) (strlen && (*str == (c)))
#define PUSHPAREN {*nextp++ = nexto;}
#define UNEMIT {nexto -= lastsz; lastsz = -1;}
  /* Tcl_UniCharIsDigit ? */
#define MATCH_DIGIT (MATCHC ('0') || MATCHC ('1') || \
	  MATCHC ('2') || MATCHC ('3') || \
	  MATCHC ('4') || MATCHC ('5') || \
	  MATCHC ('6') || MATCHC ('7') || \
	  MATCHC ('8') || MATCHC ('9'))
#define MATCH_HEXDIGIT (MATCH_DIGIT || \
		       MATCHC ('a') || MATCHC ('A') || \
		       MATCHC ('b') || MATCHC ('B') || \
		       MATCHC ('c') || MATCHC ('C') || \
		       MATCHC ('d') || MATCHC ('D') || \
		       MATCHC ('e') || MATCHC ('E') || \
		       MATCHC ('f') || MATCHC ('F'))
#define EMITC(c) {if (((c) == '\\') || \
		      ((c) == '*') || \
		      ((c) == '?') || \
		      ((c) == '$') || \
		      ((c) == '^') || \
		      ((c) == '[')) { \
			EMIT ('\\'); EMITX ((c)); \
		      } else { \
			EMIT ((c));}}
#define MATCH_AREOPTS(c) (c == 'b' || c == 'c' || \
          c == 'e' || c == 'i' || c == 'm' || c == 'n' || \
          c == 'p' || c == 'q' || c == 's' || c == 't' || \
          c == 'w' || c == 'x')

#if DEBUG
#define LOG if (1) fprintf
#define FF fflush (stderr)
#define MARK(s) LOG (stderr,#s "\n"); FF;
#else
#define LOG if (0) fprintf
#define FF 
#define MARK(s) 
#endif

  /* ***= -> literal string follows */

  LOG (stderr,"RE-2-GLOB '%s'\n", xxx(str,strlen)); FF;

  if (MATCH (litprefix)) {
    CHOP (4);
    nexto = ExpLiteral (nexto, str, strlen);
    goto done;
  }

  /* ***: -> RE is ARE. Always for Expect. Therefore ignore */

  if (MATCH (areprefix)) {
    CHOP (4);
    LOG (stderr,"ARE '%s'\n", xxx(str,strlen)); FF;
  }

  /* (?xyz) ARE options, in {bceimnpqstwx}. Not validating that the
   * options are legal. We assume that the RE is valid.
   */

  if (MATCH (areopts)) { /* "(?" */
    Tcl_UniChar* save = str;
    Tcl_UniChar* stop;
    int stoplen;
    int save_strlen = strlen;
    int all_ARE_opts = 1;

    /* First, ensure that this is actually an ARE opts string.
     * It could be something else (e.g., a non-capturing block).
     */
    CHOP (2);
    mark = str; CHOPC (')');
    stop = str;       /* Remember closing parens location, allows */
    stoplen = strlen; /* us to avoid a second CHOPC run later */

    while (mark < str) {
      if (MATCH_AREOPTS(*mark)) {
        mark++;
      } else {
        all_ARE_opts = 0;
        break;
      }
    }

    /* Reset back to our entry point. */
    str    = save;
    strlen = save_strlen;

    if (all_ARE_opts) {
      /* Now actually perform the ARE option processing */
      LOG (stderr, "%s\n", "Processing AREOPTS"); FF;

      CHOP (2);
      mark = str;
      /* Equivalent to CHOPC (')') */
      str    = stop; 
      strlen = stoplen;

      while (mark < str) {
        if (*mark == 'q') {
          CHOP (1);
          nexto = ExpLiteral (nexto, str, strlen);
          goto done;
        } else if (*mark == 'x') {
          expanded = 1;
          LOG (stderr,"EXPANDED\n"); FF;
        }
        mark++;
      }
      CHOP (1);
    }
  }

  while (strlen) {

    LOG (stderr,"'%s' <-- ",xxx(out,nexto-out)); FF;
    LOG (stderr,"'%s'\n",   xxx(str,strlen));    FF;

    if (expanded) {
      /* Expanded syntax, whitespace and comments, ignore. */
      while (MATCHC (' ')  ||
	     MATCHC (0x9) ||
	     MATCHC (0xa)) CHOP (1);
      if (MATCHC ('#')) {
	CHOPC (0xa);
	if (strlen) CHOP (1);
	continue;
      }
    }

    if (MATCHC ('|')) {
      /* branching is too complex */
      goto error;
    } else if (MATCHC ('(')) {
      /* open parens */
      CHOP (1);
      if (MATCH (nocapture)) { /* "?:" */
	/* non capturing -save location */
	PUSHPAREN;
	CHOP (2);
      } else if (MATCH (lookhas) || /* "?=" */
		 MATCH (looknot)) { /* "?!" */
	/* lookahead - ignore */
	CHOP (2);
	ExpChopNested (&str, &strlen, '(', ')');
      } else if (MATCH (xcomment)) { /* "?#" */
	/* comment - ignore */
	CHOPC (')'); CHOP (1);
      } else {
	/* plain capturing */
	PUSHPAREN;
      }
    } else if (MATCHC (')')) {
      /* Closing parens. */
      CHOP (1);
      /* Everything coming after the saved result is new, and
       * collapsed into a single entry for a possible coming operator
       * to handle.
       */
      nextp --; /* Back to last save */
      mark   = *nextp; /* Location where generation for this parens started */
      lastsz = (nexto - mark); /* This many chars generated */
      /* Now lastsz has the correct value for a possibly following
       * UNEMIT
       */
    } else if (MATCHC ('$') || MATCHC ('^')) {
      /* anchor constraints - ignore */
      CHOP (1);
    } else if (MATCHC ('[')) {
      /* Classes - reduce to any char [[=chars=]] [[.chars.]]
       * [[:name:]] [chars] Count brackets to find end.

       * These are a bit complicated ... [= =], [. .], [: {] sequences
       * always have to be complete. '[' does NOT nest otherwise.  And
       * a ']' after the opening '[' (with only '^' allowed to
       * intervene is a character, not the closing bracket. We have to
       * process the class in pieces to handle all this. The Tcl level
       * implementations (0-2 all have bugs one way or other, all
       * different.
       */

      int first   = 1;
      int allowed = 1;
      CHOP (1);
      while (strlen) {
	if (first && MATCHC ('^')) {
	  /* ^ as first keeps allowed ok for one more cycle */
	  CHOP (1);
	  first = 0;
	  continue;
	} else if (allowed && MATCHC (']')) {
	  /* Not a closing bracket! */
	  CHOP (1);
	} else if (MATCHC (']')) {
	  /* Closing bracket found */
	  CHOP (1);
	  break;
	} else if (MATCH (classa) ||
		   MATCH (classb) ||
		   MATCH (classc)) {
	  Tcl_UniChar delim[2];
	  delim[0] = str [1];
	  delim[1] = ']';
	  CHOP (2);
	  while (!MATCH (delim)) CHOP (1);
	  CHOP (2);
	} else {
	  /* Any char in class */
	  CHOP (1);
	}
	/* Reset flags handling start of class */
	allowed = first = 0;
      }

      EMIT ('?');
    } else if (MATCHC ('\\')) {
      /* Escapes */
      CHOP (1);
      if (MATCHC ('d') || MATCHC ('D') ||
	  MATCHC ('s') || MATCHC ('S') ||
	  MATCHC ('w') || MATCHC ('W')) {
	/* Class shorthands - reduce to any char */
	EMIT ('?');
	CHOP (1);
      } else if (MATCHC ('m') || MATCHC ('M') ||
		 MATCHC ('y') || MATCHC ('Y') ||
		 MATCHC ('A') || MATCHC ('Z')) {
	/* constraint escapes - ignore */
	CHOP (1);
      } else if (MATCHC ('B')) {
	/* Backslash */
	EMIT  ('\\');
	EMITX ('\\');
	CHOP (1);
      } else if (MATCHC ('0')) {
	/* Escape NULL */
	EMIT ('\0');
	CHOP (1);
      } else if (MATCHC ('e')) {
	/* Escape ESC */
	EMIT ('\033');
	CHOP (1);
      } else if (MATCHC ('a')) {
	/* Escape \a */
	EMIT (0x7);
	CHOP (1);
      } else if (MATCHC ('b')) {
	/* Escape \b */
	EMIT (0x8);
	CHOP (1);
      } else if (MATCHC ('f')) {
	/* Escape \f */
	EMIT (0xc);
	CHOP (1);
      } else if (MATCHC ('n')) {
	/* Escape \n */
	EMIT (0xa);
	CHOP (1);
      } else if (MATCHC ('r')) {
	/* Escape \r */
	EMIT (0xd);
	CHOP (1);
      } else if (MATCHC ('t')) {
	/* Escape \t */
	EMIT (0x9);
	CHOP (1);
      } else if (MATCHC ('v')) {
	/* Escape \v */
	EMIT (0xb);
	CHOP (1);
      } else if (MATCHC ('c') && (strlen >= 2)) {
	/* Escape \cX - reduce to (.) */
	EMIT ('?');
	CHOP (2);
      } else if (MATCHC ('x')) {
	CHOP (1);
	if (MATCH_HEXDIGIT) {
	  /* Escape hex character */
	  mark = str;
	  while (MATCH_HEXDIGIT) CHOP (1);
	  if ((str - mark) > 2) { mark = str - 2; }
	  ch = ExpBackslash ('x',mark,str-mark);
	  EMITC (ch);
	} else {
	  /* Without hex digits following this is a plain char */
	  EMIT ('x');
	}
      } else if (MATCHC ('u')) {
	/*  Escapes unicode short. */
	CHOP (1);
	mark = str;
	CHOP (4);
	ch = ExpBackslash ('u',mark,str-mark);
	EMITC (ch);
      } else if (MATCHC ('U')) {
	/* Escapes unicode long. */
	CHOP (1);
	mark = str;
	CHOP (8);
	ch = ExpBackslash ('U',mark,str-mark);
	EMITC (ch);
      } else if (MATCH_DIGIT) {
	/* Escapes, octal, and backreferences - reduce (.*) */
	CHOP (1);
	while (MATCH_DIGIT) CHOP (1);
	EMIT ('*');
      } else {
	/* Plain escaped characters - copy over, requote */
	EMITC (*str);
	CHOP (1);
      }
    } else if (MATCHC ('{')) {
      /* Non-greedy and greedy bounds - reduce to (*) */
      CHOP (1);
      if (MATCH_DIGIT) {
	/* Locate closing brace and remove operator */
	CHOPC ('}'); CHOP (1);
	/* Remove optional greedy quantifier */
	if (MATCHC ('?')) { CHOP (1);}
	UNEMIT;
	EMIT ('*');
      } else {
	/* Brace is plain character, copy over */
	EMIT ('{');
	/* CHOP already done */
      }
    } else if (MATCHC ('*') ||
	       MATCHC ('+') ||
	       MATCHC ('?')) {
      /* (Non-)greedy operators - reduce to (*) */
      CHOP (1);
      /* Remove optional greedy quantifier */
      if (MATCHC ('?')) { CHOP (1);}
      UNEMIT;
      EMIT ('*');
    } else if (MATCHC ('.')) {
      /* anychar - copy over */
      EMIT ('?');
      CHOP (1);
    } else {
      /* Plain char, copy over. */
      EMIT (*str);
      CHOP (1);
    }
  }

  LOG (stderr,"'%s' <-- ",xxx(out,nexto-out)); FF;
  LOG (stderr,"'%s'\n",   xxx(str,strlen));    FF;

  /*
   * Clean up the output a bit (collapse *-sequences and absorb ?'s
   * into adjacent *'s.
   */

  MARK (QF)
  nexto = ExpCollapseQForward (out,nexto);
  LOG (stderr,"QF '%s'\n",xxx(out,nexto-out)); FF;

  MARK (QB)
  nexto = ExpCollapseQBack    (out,nexto);
  LOG (stderr,"QB '%s'\n",xxx(out,nexto-out)); FF;

  MARK (QS)
  nexto = ExpCollapseStar     (out,nexto);
  LOG (stderr,"ST '%s'\n",xxx(out,nexto-out)); FF;

  /*
   * Heuristic: if there are more than two *s, the risk is far too
   * large that the result actually is slower than the normal re
   * matching.  So bail out.
   */
  if (ExpCountStar (out,nexto) > 2) {
      goto error;
  }

  /*
   * Check if the result is actually useful.
   * Empty or just a *, or ? are not. A series
   * of ?'s is borderline, as they semi-count
   * the buffer.
   */

  if ((nexto == out) ||
      (((nexto-out) == 1) &&
       ((*out == '*') ||
	(*out == '?')))) {
    goto error;
  }

  /*
   * Result generation and cleanup.
   */
 done:
  LOG (stderr,"RESULT_ '%s'\n", xxx(out,nexto-out)); FF;
  glob = Tcl_NewUnicodeObj (out,(nexto-out));
  goto cleanup;

 error:
  LOG (stderr,"RESULT_ ERROR\n"); FF;

 cleanup:
  Tcl_Free ((char*)out);
  Tcl_Free ((char*)paren);

  return glob;
}

static void
#ifdef _AIX
ExpChopNested (Tcl_UniChar** xstr,
	       int*          xstrlen,
	       Tcl_UniChar   open,
	       Tcl_UniChar   close)
#else
ExpChopNested (xstr,xstrlen, open, close)
     Tcl_UniChar** xstr;
     int*          xstrlen;
     Tcl_UniChar   open;
     Tcl_UniChar   close;
#endif
{
  Tcl_UniChar* str    = *xstr;
  int          strlen = *xstrlen;
  int          level = 0;

  while (strlen) {
    if (MATCHC (open)) {
      level ++;
    } else if (MATCHC (close)) {
      level --;
      if (level < 0) {
	CHOP (1);
	break;
      }
    }
    CHOP (1);
  }

  *xstr = str;
  *xstrlen = strlen;
}

static Tcl_UniChar*
ExpLiteral (nexto, str, strlen)
     Tcl_UniChar* nexto;
     Tcl_UniChar* str;
     int          strlen;
{
  int lastsz;

  LOG (stderr,"LITERAL '%s'\n", xxx(str,strlen)); FF;

  while (strlen) {
    EMITC (*str);
    CHOP (1);
  }
  return nexto;
}

static Tcl_UniChar
#ifdef _AIX
ExpBackslash (char prefix,
	      Tcl_UniChar* str,
	      int          strlen)
#else
ExpBackslash (prefix, str, strlen)
     char prefix;
     Tcl_UniChar* str;
     int          strlen;
#endif
{
  /* strlen <= 8 */
  char buf[20];
  char dst[TCL_UTF_MAX+1];
  Tcl_UniChar ch;
  int at = 0;

  /* Construct an utf backslash sequence we can throw to Tcl */

  buf [at++] = '\\';
  buf [at++] = prefix;
  while (strlen) {
    buf [at++] = *str++;
    strlen --;
  }

  Tcl_UtfBackslash (buf, NULL, dst);
  TclUtfToUniChar (dst, &ch);
  return ch;
}

static Tcl_UniChar*
ExpCollapseStar (src, last)
     Tcl_UniChar* src;
     Tcl_UniChar* last;
{
  Tcl_UniChar* dst, *base;
  int skip = 0;
  int star = 0;

  /* Collapses series of *'s into a single *. State machine. The
   * complexity is due to the need of handling escaped characters.
   */

  LOG (stderr,"Q-STAR\n"); FF;

  for (dst = base = src; src < last;) {

    LOG (stderr,"@%1d /%1d '%s' <-- ", star,skip,xxx(base,dst-base)); FF;
    LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;

    if (skip) {
      skip = 0;
      star = 0;
    } else if (*src == '\\') {
      skip = 1; /* Copy next char, whatever its value */
      star = 0;
    } else if (*src == '*') {
      if (star) {
	/* Previous char was *, do not copy the current * to collapse
	 * the sequence
	 */
	src++;
	continue;
      }
      star = 1; /* *-series starts here */
    } else {
      star = 0;
    }
    *dst++ = *src++;
  }

  LOG (stderr,"@%1d /%1d '%s' <-- ", star,skip,xxx(base,dst-base)); FF;
  LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;

  return dst;
}

static Tcl_UniChar*
ExpCollapseQForward (src, last)
     Tcl_UniChar* src;
     Tcl_UniChar* last;
{
  Tcl_UniChar* dst, *base;
  int skip = 0;
  int quest = 0;

  /* Collapses series of ?'s coming after a *. State machine. The
   * complexity is due to the need of handling escaped characters.
   */

  LOG (stderr,"Q-Forward\n"); FF;

  for (dst = base = src; src < last;) {

    LOG (stderr,"?%1d /%1d '%s' <-- ", quest,skip,xxx(base,dst-base)); FF;
    LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;

    if (skip) {
      skip = 0;
      quest = 0;
    } else if (*src == '\\') {
      skip = 1;
      quest = 0;
      /* Copy next char, whatever its value */
    } else if (*src == '?') {
      if (quest) {
	/* Previous char was *, do not copy the current ? to collapse
	 * the sequence
	 */
	src++;
	continue;
      }
    } else if (*src == '*') {
      quest = 1;
    } else {
      quest = 0;
    }
    *dst++ = *src++;
  }

  LOG (stderr,"?%1d /%1d '%s' <-- ", quest,skip,xxx(base,dst-base)); FF;
  LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;
  return dst;
}

static Tcl_UniChar*
ExpCollapseQBack (src, last)
     Tcl_UniChar* src;
     Tcl_UniChar* last;
{
  Tcl_UniChar* dst, *base;
  int skip = 0;

  /* Collapses series of ?'s coming before a *. State machine. The
   * complexity is due to the need of handling escaped characters.
   */

  LOG (stderr,"Q-Backward\n"); FF;

  for (dst = base = src; src < last;) {
    LOG (stderr,"/%1d '%s' <-- ",skip,xxx(base,dst-base)); FF;
    LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;

    if (skip) {
      skip = 0;
    } else if (*src == '\\') {
      skip = 1;
      /* Copy next char, whatever its value */
    } else if (*src == '*') {
      /* Move backward in the output while the previous character is
       * an unescaped question mark. If there is a previous character,
       * or a character before that..
       */

      while ((((dst-base) > 2)  && (dst[-1] == '?') && (dst[-2] != '\\')) ||
	     (((dst-base) == 1) && (dst[-1] == '?'))) {
	dst --;
      }
    }
    *dst++ = *src++;
  }

  LOG (stderr,"/%1d '%s' <-- \n",skip,xxx(base,dst-base)); FF;
  LOG (stderr,"'%s'\n",   xxx(src,last-src));  FF;
  return dst;
}

static int
ExpCountStar (src, last)
    Tcl_UniChar* src;
    Tcl_UniChar* last;
{
    int skip = 0;
    int stars = 0;

    /* Count number of *'s. State machine. The complexity is due to the
     * need of handling escaped characters.
     */

    for (; src < last; src++) {
	if (skip) {
	    skip = 0;
	} else if (*src == '\\') {
	    skip = 1;
	} else if (*src == '*') {
	    stars++;
	}
    }

    return stars;
}

#undef CHOP
#undef CHOPC
#undef EMIT
#undef EMITX
#undef MATCH
#undef MATCHC
#undef MATCH_DIGIT
#undef MATCH_HEXDIGIT
#undef PUSHPAREN
#undef UNEMIT
