/* exp_strp.c - functions for exp_timestamp */
/*
 * strftime.c
 *
 * Public-domain implementation of ANSI C library routine.
 *
 * It's written in old-style C for maximal portability.
 * However, since I'm used to prototypes, I've included them too.
 *
 * If you want stuff in the System V ascftime routine, add the SYSV_EXT define.
 * For extensions from SunOS, add SUNOS_EXT.
 * For stuff needed to implement the P1003.2 date command, add POSIX2_DATE.
 * For VMS dates, add VMS_EXT.
 * For complete POSIX semantics, add POSIX_SEMANTICS.
 *
 * The code for %c, %x, and %X now follows the 1003.2 specification for
 * the POSIX locale.
 * This version ignores LOCALE information.
 * It also doesn't worry about multi-byte characters.
 * So there.
 *
 * This file is also shipped with GAWK (GNU Awk), gawk specific bits of
 * code are included if GAWK is defined.
 *
 * Arnold Robbins <arnold@skeeve.atl.ga.us>
 * January, February, March, 1991
 * Updated March, April 1992
 * Updated April, 1993
 * Updated February, 1994
 * Updated May, 1994
 * Updated January 1995
 * Updated September 1995
 *
 * Fixes from ado@elsie.nci.nih.gov
 * February 1991, May 1992
 * Fixes from Tor Lillqvist tml@tik.vtt.fi
 * May, 1993
 * Further fixes from ado@elsie.nci.nih.gov
 * February 1994
 * %z code from chip@chinacat.unicom.com
 * Applied September 1995
 *
 *
 * Modified by Don Libes for Expect, 10/93 and 12/95.
 * Forced POSIX semantics.
 * Replaced inline/min/max stuff with a single range function.
 * Removed tzset stuff.
 * Commented out tzname stuff.
 *
 * According to Arnold, the current version of this code can ftp'd from
 * ftp.mathcs.emory.edu:/pub/arnold/strftime.shar.gz
 *
 */

#include "expect_cf.h"
#include "tcl.h"

#include <stdio.h>
#include <ctype.h>
#include "string.h"

/* according to Karl Vogel, time.h is insufficient on Pyramid */
/* following is recommended by autoconf */

#ifdef TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# ifdef HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif



#include <sys/types.h>

#define SYSV_EXT	1	/* stuff in System V ascftime routine */
#define POSIX2_DATE	1	/* stuff in Posix 1003.2 date command */

#if defined(POSIX2_DATE) && ! defined(SYSV_EXT)
#define SYSV_EXT	1
#endif

#if defined(POSIX2_DATE)
#define adddecl(stuff)	stuff
#else
#define adddecl(stuff)
#endif

#ifndef __STDC__
#define const

extern char *getenv();
static int weeknumber();
adddecl(static int iso8601wknum();)
#else

#ifndef strchr
extern char *strchr(const char *str, int ch);
#endif

extern char *getenv(const char *v);

static int weeknumber(const struct tm *timeptr, int firstweekday);
adddecl(static int iso8601wknum(const struct tm *timeptr);)
#endif

/* attempt to use strftime to compute timezone, else fallback to */
/* less portable ways */
#if !defined(HAVE_STRFTIME)
# if defined(HAVE_SV_TIMEZONE)
extern char *tzname[2];
extern int daylight;
# else
#  if defined(HAVE_TIMEZONE)

char           *
zone_name (tp)
struct tm      *tp;
{
	char           *timezone ();
	struct timeval  tv;
	struct timezone tz;

	gettimeofday (&tv, &tz);

	return timezone (tz.tz_minuteswest, tp->tm_isdst);
}

#  endif /* HAVE_TIMEZONE */
# endif /* HAVE_SV_TIMEZONE */
#endif /* HAVE_STRFTIME */

static int
range(low,item,hi)
int low, item, hi;
{
	if (item < low) return low;
	if (item > hi) return hi;
	return item;
}

/* strftime --- produce formatted time */

void
/*size_t*/
#ifndef __STDC__
exp_strftime(/*s,*/ format, timeptr, dstring)
/*char *s;*/
char *format;
const struct tm *timeptr;
Tcl_DString *dstring;
#else
/*exp_strftime(char *s, size_t maxsize, const char *format, const struct tm *timeptr)*/
exp_strftime(char *format, const struct tm *timeptr,Tcl_DString *dstring)
#endif
{
	int copied;	/* used to suppress copying when called recursively */

#if 0
	char *endp = s + maxsize;
	char *start = s;
#endif
	char *percentptr;

	char tbuf[100];
	int i;

	/* various tables, useful in North America */
	static char *days_a[] = {
		"Sun", "Mon", "Tue", "Wed",
		"Thu", "Fri", "Sat",
	};
	static char *days_l[] = {
		"Sunday", "Monday", "Tuesday", "Wednesday",
		"Thursday", "Friday", "Saturday",
	};
	static char *months_a[] = {
		"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
	};
	static char *months_l[] = {
		"January", "February", "March", "April",
		"May", "June", "July", "August", "September",
		"October", "November", "December",
	};
	static char *ampm[] = { "AM", "PM", };

/*	for (; *format && s < endp - 1; format++) {*/
	for (; *format ; format++) {
		tbuf[0] = '\0';
		copied = 0;		/* has not been copied yet */
		percentptr = strchr(format,'%');
		if (percentptr == 0) {
			Tcl_DStringAppend(dstring,format,-1);
			goto out;
		} else if (percentptr != format) {
			Tcl_DStringAppend(dstring,format,percentptr - format);
			format = percentptr;
	        }
#if 0
		if (*format != '%') {
			*s++ = *format;
			continue;
		}
#endif
	again:
		switch (*++format) {
		case '\0':
			Tcl_DStringAppend(dstring,"%",1);
#if 0
			*s++ = '%';
#endif
			goto out;

		case '%':
			Tcl_DStringAppend(dstring,"%",1);
			copied = 1;
			break;
#if 0
			*s++ = '%';
			continue;
#endif

		case 'a':	/* abbreviated weekday name */
			if (timeptr->tm_wday < 0 || timeptr->tm_wday > 6)
				strcpy(tbuf, "?");
			else
				strcpy(tbuf, days_a[timeptr->tm_wday]);
			break;

		case 'A':	/* full weekday name */
			if (timeptr->tm_wday < 0 || timeptr->tm_wday > 6)
				strcpy(tbuf, "?");
			else
				strcpy(tbuf, days_l[timeptr->tm_wday]);
			break;

#ifdef SYSV_EXT
		case 'h':	/* abbreviated month name */
#endif
		case 'b':	/* abbreviated month name */
			if (timeptr->tm_mon < 0 || timeptr->tm_mon > 11)
				strcpy(tbuf, "?");
			else
				strcpy(tbuf, months_a[timeptr->tm_mon]);
			break;

		case 'B':	/* full month name */
			if (timeptr->tm_mon < 0 || timeptr->tm_mon > 11)
				strcpy(tbuf, "?");
			else
				strcpy(tbuf, months_l[timeptr->tm_mon]);
			break;

		case 'c':	/* appropriate date and time representation */
			sprintf(tbuf, "%s %s %2d %02d:%02d:%02d %d",
				days_a[range(0, timeptr->tm_wday, 6)],
				months_a[range(0, timeptr->tm_mon, 11)],
				range(1, timeptr->tm_mday, 31),
				range(0, timeptr->tm_hour, 23),
				range(0, timeptr->tm_min, 59),
				range(0, timeptr->tm_sec, 61),
				timeptr->tm_year + 1900);
			break;

		case 'd':	/* day of the month, 01 - 31 */
			i = range(1, timeptr->tm_mday, 31);
			sprintf(tbuf, "%02d", i);
			break;

		case 'H':	/* hour, 24-hour clock, 00 - 23 */
			i = range(0, timeptr->tm_hour, 23);
			sprintf(tbuf, "%02d", i);
			break;

		case 'I':	/* hour, 12-hour clock, 01 - 12 */
			i = range(0, timeptr->tm_hour, 23);
			if (i == 0)
				i = 12;
			else if (i > 12)
				i -= 12;
			sprintf(tbuf, "%02d", i);
			break;

		case 'j':	/* day of the year, 001 - 366 */
			sprintf(tbuf, "%03d", timeptr->tm_yday + 1);
			break;

		case 'm':	/* month, 01 - 12 */
			i = range(0, timeptr->tm_mon, 11);
			sprintf(tbuf, "%02d", i + 1);
			break;

		case 'M':	/* minute, 00 - 59 */
			i = range(0, timeptr->tm_min, 59);
			sprintf(tbuf, "%02d", i);
			break;

		case 'p':	/* am or pm based on 12-hour clock */
			i = range(0, timeptr->tm_hour, 23);
			if (i < 12)
				strcpy(tbuf, ampm[0]);
			else
				strcpy(tbuf, ampm[1]);
			break;

		case 'S':	/* second, 00 - 61 */
			i = range(0, timeptr->tm_sec, 61);
			sprintf(tbuf, "%02d", i);
			break;

		case 'U':	/* week of year, Sunday is first day of week */
			sprintf(tbuf, "%02d", weeknumber(timeptr, 0));
			break;

		case 'w':	/* weekday, Sunday == 0, 0 - 6 */
			i = range(0, timeptr->tm_wday, 6);
			sprintf(tbuf, "%d", i);
			break;

		case 'W':	/* week of year, Monday is first day of week */
			sprintf(tbuf, "%02d", weeknumber(timeptr, 1));
			break;

		case 'x':	/* appropriate date representation */
			sprintf(tbuf, "%s %s %2d %d",
				days_a[range(0, timeptr->tm_wday, 6)],
				months_a[range(0, timeptr->tm_mon, 11)],
				range(1, timeptr->tm_mday, 31),
				timeptr->tm_year + 1900);
			break;

		case 'X':	/* appropriate time representation */
			sprintf(tbuf, "%02d:%02d:%02d",
				range(0, timeptr->tm_hour, 23),
				range(0, timeptr->tm_min, 59),
				range(0, timeptr->tm_sec, 61));
			break;

		case 'y':	/* year without a century, 00 - 99 */
			i = timeptr->tm_year % 100;
			sprintf(tbuf, "%02d", i);
			break;

		case 'Y':	/* year with century */
			sprintf(tbuf, "%d", 1900 + timeptr->tm_year);
			break;

		case 'Z':	/* time zone name or abbrevation */
#if defined(HAVE_STRFTIME)
			strftime(tbuf,sizeof tbuf,"%Z",timeptr);
#else
# if defined(HAVE_SV_TIMEZONE)
			i = 0;
			if (daylight && timeptr->tm_isdst)
				i = 1;
			strcpy(tbuf, tzname[i]);
# else
			strcpy(tbuf, zone_name (timeptr));
#  if defined(HAVE_TIMEZONE)
#  endif /* HAVE_TIMEZONE */
			/* no timezone available */
			/* feel free to add others here */
# endif /* HAVE_SV_TIMEZONE */
#endif /* HAVE STRFTIME */
			break;

#ifdef SYSV_EXT
		case 'n':	/* same as \n */
			tbuf[0] = '\n';
			tbuf[1] = '\0';
			break;

		case 't':	/* same as \t */
			tbuf[0] = '\t';
			tbuf[1] = '\0';
			break;

		case 'D':	/* date as %m/%d/%y */
			exp_strftime("%m/%d/%y", timeptr, dstring);
			copied = 1;
/*			exp_strftime(tbuf, sizeof tbuf, "%m/%d/%y", timeptr);*/
			break;

		case 'e':	/* day of month, blank padded */
			sprintf(tbuf, "%2d", range(1, timeptr->tm_mday, 31));
			break;

		case 'r':	/* time as %I:%M:%S %p */
			exp_strftime("%I:%M:%S %p", timeptr, dstring);
			copied = 1;
/*			exp_strftime(tbuf, sizeof tbuf, "%I:%M:%S %p", timeptr);*/
			break;

		case 'R':	/* time as %H:%M */
			exp_strftime("%H:%M", timeptr, dstring);
			copied = 1;
/*			exp_strftime(tbuf, sizeof tbuf, "%H:%M", timeptr);*/
			break;

		case 'T':	/* time as %H:%M:%S */
			exp_strftime("%H:%M:%S", timeptr, dstring);
			copied = 1;
/*			exp_strftime(tbuf, sizeof tbuf, "%H:%M:%S", timeptr);*/
			break;
#endif

#ifdef POSIX2_DATE
		case 'C':
			sprintf(tbuf, "%02d", (timeptr->tm_year + 1900) / 100);
			break;


		case 'E':
		case 'O':
			/* POSIX locale extensions, ignored for now */
			goto again;
		case 'V':	/* week of year according ISO 8601 */
			sprintf(tbuf, "%02d", iso8601wknum(timeptr));
			break;

		case 'u':
		/* ISO 8601: Weekday as a decimal number [1 (Monday) - 7] */
			sprintf(tbuf, "%d", timeptr->tm_wday == 0 ? 7 :
					timeptr->tm_wday);
			break;
#endif	/* POSIX2_DATE */
		default:
			tbuf[0] = '%';
			tbuf[1] = *format;
			tbuf[2] = '\0';
			break;
		}
		if (!copied)
			Tcl_DStringAppend(dstring,tbuf,-1);
#if 0
		i = strlen(tbuf);
		if (i) {
			if (s + i < endp - 1) {
				strcpy(s, tbuf);
				s += i;
			} else
				return 0;
#endif
	}
out:;
#if 0
	if (s < endp && *format == '\0') {
		*s = '\0';
		return (s - start);
	} else
		return 0;
#endif
}

/* isleap --- is a year a leap year? */

#ifndef __STDC__
static int
isleap(year)
int year;
#else
static int
isleap(int year)
#endif
{
	return ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
}

#ifdef POSIX2_DATE
/* iso8601wknum --- compute week number according to ISO 8601 */

#ifndef __STDC__
static int
iso8601wknum(timeptr)
const struct tm *timeptr;
#else
static int
iso8601wknum(const struct tm *timeptr)
#endif
{
	/*
	 * From 1003.2:
	 *	If the week (Monday to Sunday) containing January 1
	 *	has four or more days in the new year, then it is week 1;
	 *	otherwise it is the highest numbered week of the previous
	 *	(52 or 53) year, and the next week is week 1.
	 *
	 * ADR: This means if Jan 1 was Monday through Thursday,
	 *	it was week 1, otherwise week 53.
	 * 
	 * XPG4 erroneously included POSIX.2 rationale text in the
	 * main body of the standard. Thus it requires week 53.
	 */

	int weeknum, jan1day;

	/* get week number, Monday as first day of the week */
	weeknum = weeknumber(timeptr, 1);

	/*
	 * With thanks and tip of the hatlo to tml@tik.vtt.fi
	 *
	 * What day of the week does January 1 fall on?
	 * We know that
	 *	(timeptr->tm_yday - jan1.tm_yday) MOD 7 ==
	 *		(timeptr->tm_wday - jan1.tm_wday) MOD 7
	 * and that
	 * 	jan1.tm_yday == 0
	 * and that
	 * 	timeptr->tm_wday MOD 7 == timeptr->tm_wday
	 * from which it follows that. . .
 	 */
	jan1day = timeptr->tm_wday - (timeptr->tm_yday % 7);
	if (jan1day < 0)
		jan1day += 7;

	/*
	 * If Jan 1 was a Monday through Thursday, it was in
	 * week 1.  Otherwise it was last year's highest week, which is
	 * this year's week 0.
	 *
	 * What does that mean?
	 * If Jan 1 was Monday, the week number is exactly right, it can
	 *	never be 0.
	 * If it was Tuesday through Thursday, the weeknumber is one
	 *	less than it should be, so we add one.
	 * Otherwise, Friday, Saturday or Sunday, the week number is
	 * OK, but if it is 0, it needs to be 52 or 53.
	 */
	switch (jan1day) {
	case 1:		/* Monday */
		break;
	case 2:		/* Tuesday */
	case 3:		/* Wednesday */
	case 4:		/* Thursday */
		weeknum++;
		break;
	case 5:		/* Friday */
	case 6:		/* Saturday */
	case 0:		/* Sunday */
		if (weeknum == 0) {
#ifdef USE_BROKEN_XPG4
			/* XPG4 (as of March 1994) says 53 unconditionally */
			weeknum = 53;
#else
			/* get week number of last week of last year */
			struct tm dec31ly;	/* 12/31 last year */
			dec31ly = *timeptr;
			dec31ly.tm_year--;
			dec31ly.tm_mon = 11;
			dec31ly.tm_mday = 31;
			dec31ly.tm_wday = (jan1day == 0) ? 6 : jan1day - 1;
			dec31ly.tm_yday = 364 + isleap(dec31ly.tm_year + 1900);
			weeknum = iso8601wknum(& dec31ly);
#endif
		}
		break;
	}

	if (timeptr->tm_mon == 11) {
		/*
		 * The last week of the year
		 * can be in week 1 of next year.
		 * Sigh.
		 *
		 * This can only happen if
		 *	M   T  W
		 *	29  30 31
		 *	30  31
		 *	31
		 */
		int wday, mday;

		wday = timeptr->tm_wday;
		mday = timeptr->tm_mday;
		if (   (wday == 1 && (mday >= 29 && mday <= 31))
		    || (wday == 2 && (mday == 30 || mday == 31))
		    || (wday == 3 &&  mday == 31))
			weeknum = 1;
	}

	return weeknum;
}
#endif

/* weeknumber --- figure how many weeks into the year */

/* With thanks and tip of the hatlo to ado@elsie.nci.nih.gov */

#ifndef __STDC__
static int
weeknumber(timeptr, firstweekday)
const struct tm *timeptr;
int firstweekday;
#else
static int
weeknumber(const struct tm *timeptr, int firstweekday)
#endif
{
	int wday = timeptr->tm_wday;
	int ret;

	if (firstweekday == 1) {
		if (wday == 0)	/* sunday */
			wday = 6;
		else
			wday--;
	}
	ret = ((timeptr->tm_yday + 7 - wday) / 7);
	if (ret < 0)
		ret = 0;
	return ret;
}
