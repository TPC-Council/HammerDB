/*
 * oratclInt.h
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef _ORATCLINT_H
#define _ORATCLINT_H

#include <stdarg.h>
#include "oratypes.h"
#include "oradefs.h"
#include <tcl.h>

/* _ANSI_ARGS_ should be defined by tcl.h; ignore if not defined */
#ifndef _ANSI_ARGS_
#define _ANSI_ARGS_() ()
#endif

/* For pre-8.4 Tcl Support */
#ifndef CONST84
#   define CONST84
#endif

/* various limits for arrays of structures, default buffer sizes */
#define ORA_MSG_SIZE    1000    /* oracle error message max size*/
#define NO_DATA_FOUND   1403    /* oracle error # no data for this fetch */

#define ORA_NUMB_SIZE	40
#define MAX_NUMB_SIZE	4000
#define ORA_DATE_SIZE	75
#define MAX_DATE_SIZE	7500
#define ORA_LONG_SIZE	40960
#define MAX_LONG_SIZE	2147483647
#define ORA_BIND_SIZE   4000
#define OLD_MAX_BIND_SIZE	2147483647
#define MAX_BIND_SIZE	4294967294
#define ORA_FETCH_ROWS	10
#define ORA_LOBP_SIZE	10000
#define MAX_LOBP_SIZE	2147483647
#define ORA_LONGP_SIZE  50000
#define MAX_LONGP_SIZE	2147483647

struct OratclDesc {
	ub2		typecode;	/* column type code		*/
	Tcl_DString	typename;	/* column type name		*/
	ub2		size;       	/* column internal size		*/
	text        	*name;		/* column name			*/
	ub4		namesz; 	/* column name length  		*/
	int		prec;		/* precision of numeric		*/
					/* attr can be ub1 or sb2	*/
					/* and we need to handle both	*/
	sb1		scale;		/* scale of numeric		*/
	ub1		nullok; 	/* ok if null			*/
	char		*valuep;	/* Column data pointer		*/
	ub4		valuesz;	/* column display size		*/
};
typedef struct OratclDesc OratclDesc;

/* OratclCols holds information and data of SELECT columns */
struct OratclCols {
	struct OratclCols *next;	 	/* pointer to next OratclCols in list */
	ub2		dty;		
	int		nFetchRows;		/* rows to fetch */
	OCIDefine   	*defnp;			/* define pointer */
	OCIBind		*bindp;			/* bind pointer */
	Tcl_HashEntry	*bindPtr;
	OratclDesc	column;			/* column information	*/
	sb2		*indp;			/* null indicator pointer */
	ub2		*rlenp;			/* actual column length */
	ub2		*rcodep;		/* actual column code */
	int		array_count;
	Tcl_Obj		*array_values;
};
typedef struct OratclCols OratclCols;

/* OratclLogs - oracle logon struct */
typedef struct OratclLogs {
	OCIEnv		*envhp;		/* environment handle	*/
	OCIError	*errhp;		/* error handle		*/
	OCISvcCtx	*svchp;		/* service handle	*/
	OCIServer	*srvhp;		/* server handle	*/
	OCISession	*usrhp;		/* user handle		*/
	int		autocom;	/* autocommit mode	*/
	int		async;		/* blocking mode	*/
	int		logid;		/* login handle id	*/
	int		ora_rc;		/* oracle return code	*/
	Tcl_DString	ora_err;	/* oracle error text	*/
	char		*failovercallback; /* TAF failover	*/
	Tcl_Interp	*interp;	/* for TAF callback	*/
} OratclLogs;

/* use size_t instead */

/* OratclStms - oracle statement struct */
typedef struct OratclStms {
	OCIStmt		*stmhp;		/* statement handle	*/
	OratclCols	*col_list;	/* select columns	*/
	OratclCols	*bind_list;	/* bind vars/values	*/
	int		longsize;	/* long size allocation		*/
	int		bindsize;	/* bind size allocation		*/
	Tcl_Obj		*nullvalue;	/* null display value		*/
	int		fetchrows;	/* rows to fetch		*/
	int		lobpsize;	/* lob piece size allocation	*/
	int		longpsize;	/* long piece size allocation	*/
	int		fetchmem;	/* save value at parse time 	*/
	int		fetchidx;	/* row in cache to fetch	*/
	int		fetch_end;	/* true when fetches exhausted	*/
	ub4		iters;		/* iteration count		*/
	ub4		fetch_cnt;	/* total rows fetched so far	*/
	ub4		append_cnt;	/* total rows appended so far	*/
	ub2		sqltype;	/* the sql type attribute	*/
	Tcl_HashEntry	*logHashPtr;
        int		logid;		/* login handle id		*/
        int		stmid;		/* statement handle id		*/
	int		utfmode;	/* utfmode flag			*/
	int		unicode;	/* unicode flag			*/
	int		numbsize;	/* space to alloc for numbers	*/
	int		datesize;	/* space to alloc for dates	*/
	int		ora_rc;		/* oracle return code		*/
	Tcl_DString	ora_err;	/* oracle error text		*/
	ub4		ora_row;	/* oracle row number		*/
	ub2		ora_peo;	/* oracle parse error offset	*/
	ub2		ora_fcd;	/* oracle function code		*/
	int		array_dml;
	Tcl_Obj		*array_dml_errors;
} OratclStms;

typedef struct OratclState {
        Tcl_HashTable	*logHash;	/* login handle hash		*/
        int		logid;		/* login handle id		*/
        Tcl_HashTable	*stmHash;	/* statement handle hash	*/
        int		stmid;		/* statement handle id		*/
} OratclState;


/*
 * Windows ... quirks. Handle globally, do not care where the actual
 * use of the functions is moved to.
 */

#ifdef __WIN32__
#define strncasecmp strnicmp
#define strcasecmp stricmp
#endif

#endif
