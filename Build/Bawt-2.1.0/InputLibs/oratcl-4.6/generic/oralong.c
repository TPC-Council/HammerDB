/*
 * oralong.c
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#include <string.h>

#include "oratclInt.h"
#include "oratclTypes.h"
#include "oratclExtern.h"

int
Oralong_Init (interp)
	Tcl_Interp	*interp;
{
	size_t		x;
	int		debug = 0;
	CONST84 char	*rx;
	Tcl_Obj		*tmp1_obj;

	struct tvars {
		CONST84 char * ns;
		CONST84 char * name;
		CONST84 char * value;
	};

	struct tvars tvars_list [] = {
		{
			"::oratcl::longidx",
			NULL,
			"0"
		},
		{
			"::oratcl::sql",
			"longraw_write",
			"update %s set %s = :lng where rowid = '%s'"
		},
		{
			"::oratcl::sql",
			"longraw_read",
			"select %s from %s where rowid = '%s'"
		},
		{
			"::oratcl::sql",
			"long_write",
			"update %s set %s = :lng where rowid = '%s'"
		},
		{
			"::oratcl::sql",
			"long_read",
			"select %s from %s where rowid = '%s'"
		},
		{
			"::oratcl::oralong",
			"oratcl_ok",
			"0"
		},
		{
			"::oratcl::oralong",
			"oratcl_error",
			"1"
		}
	};


	CONST84 char *script[] = {
	        "proc oralong {command handle args} { "
		"	global errorInfo; "
		"	foreach idx [list rowid table column datavariable] { "
		"		set ::oratcl::oralong($idx) {}; "
		"	}; "
		"	set tcl_res {}; "
		"	set cm(alloc)	[list ::oratcl::long_alloc $handle $args]; "
		"	set cm(free)	[list ::oratcl::long_free $handle]; "
		"	set cm(read)	[list ::oratcl::long_read $handle $args]; "
		"	set cm(write)   [list ::oratcl::long_write $handle $args]; "
		"	if {! [info exists cm($command)]} { "
		"		 set err_txt \"oralong: unknown command option '$command'\"; "
		"		 return -code error $err_txt ; "
		"	}; "
		"	set tcl_rc [catch {eval $cm($command)} tcl_res]; "
		"	if {$tcl_rc} { "
		"		return -code error \"$tcl_res\"; "
		"	}; "
		"	return $tcl_res; "
		"} ",

	        "proc ::oratcl::parse_long_args {args} { "
		"	set argv [lindex $args 0]; "
		"	set argc [llength $argv]; "
		"	for {set argx 0} {$argx < $argc} {incr argx} { "
		"		set option [lindex $argv $argx]; "
		"		if {[incr argx] >= $argc} { "
		"			set err_txt \"oralong: value parameter to $option is missing.\"; "
		"			return -code error $err_txt ; "
		"		}; "
		"		set value [lindex $argv $argx]; "
		"		if {[regexp ^- $option]} { "
		"			set index [string range $option 1 end]; "
		"			set ::oratcl::oralong($index) $value ; "
		"		}; "
		"	}; "
		"} ",

		"proc ::oratcl::long_alloc {handle args} { "
		"	global errorInfo; "
		"	variable longidx ; "
		"	variable longlst; "
		"	variable oralong; "
		"	set fn alloc; "
		"	set tcl_rc [catch {eval ::oratcl::parse_long_args $args} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {[string is space $oralong(rowid)]} { "
		"		set err_txt \"oralong $fn: invalid rowid value.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {[string is space $oralong(table)]} { "
		"		set err_txt \"oralong $fn: invalid table value.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {[string is space $oralong(column)]} { "
		"		set err_txt \"oralong $fn: invalid column value.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set tcl_rc [catch {orainfo logonhandle $handle} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: [oramsg $handle error] $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set loghandle $tcl_res; "
		"	set tcl_rc [catch {oradesc $loghandle $oralong(table)} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: [oramsg $handle error] $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set autotype {}; "
		"	foreach row $tcl_res { "
		"		if {[string equal [lindex $row 0] [string toupper $oralong(column)]]} { "
		"			set autotype [lindex $row 2]; "
		"			::break; "
		"		}; "
		"	}; "
		"	if {[string is space $autotype]} { "
		"		set err_txt \"oralong $fn: error column '$oralong(column)' not found.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {[string equal $autotype LONG]} { "
		"		set longtype long; "
		"	} elseif {[string equal $autotype {LONG RAW}]} { "
		"		set longtype longraw; "
		"	} else { "
		"		set err_txt \"oralong $fn: error unsuported long type '$autotype'.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set lng oralong.$longidx; "
		"	incr longidx; "
		"	set longlst($lng) [list $handle $oralong(table) $oralong(column) $oralong(rowid) $longtype]; "
		"	return $lng; "
		"} ",

	        "proc ::oratcl::long_free {handle} { "
		"	variable oralong; "
		"	variable longlst; "
		"	set fn free; "
		"	if {![info exists longlst($handle)]} { "
		"		set err_txt \"oralong $fn: handle $handle not open.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set tcl_rc [catch {unset longlst($handle)} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set err_txt \"oralong $fn: $tcl_res\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	return -code ok $oralong(oratcl_ok); "
		"} ",

	       "proc ::oratcl::long_read {handle args} { "
		"	global errorInfo; "
		"	variable longlst; "
		"	variable oralong; "
		"	set fn read; "
		"	set tcl_rc [catch {eval ::oratcl::parse_long_args $args} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {![info exists longlst($handle)]} { "
		"		set err_txt \"oralong $fn: handle $handle not open.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set stm [lindex $longlst($handle) 0]; "
		"	set table [lindex $longlst($handle) 1]; "
		"	set column [lindex $longlst($handle) 2]; "
		"	set rowid [lindex $longlst($handle) 3]; "
		"	set longtype [lindex $longlst($handle) 4]; "
		"	upvar 2 $oralong(datavariable) read_res; "
		"	set read_res {}; "
		"	set sql [format $::oratcl::sql(${longtype}_read) $column $table $rowid]; "
		"	set tcl_rc [catch {::oratcl::longread $stm  $sql  read_res  $longtype}  tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: [oramsg $handle error] $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	return -code ok $oralong(oratcl_ok); "
		"} ",

	        "proc ::oratcl::long_write {handle args} { "
		"	global errorInfo; "
		"	variable longlst; "
		"	variable oralong; "
		"	set fn write; "
		"	set tcl_rc [catch {eval ::oratcl::parse_long_args $args} tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	if {![info exists longlst($handle)]} { "
		"		set err_txt \"oralong $fn: handle $handle not open.\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	set stm [lindex $longlst($handle) 0]; "
		"	set table [lindex $longlst($handle) 1]; "
		"	set column [lindex $longlst($handle) 2]; "
		"	set rowid [lindex $longlst($handle) 3]; "
		"	set longtype [lindex $longlst($handle) 4]; "
		"	upvar 2 $oralong(datavariable) datavariable; "
		"	set writevar $datavariable; "
		"	set sql [format $::oratcl::sql(${longtype}_write) $table $column $rowid]; "
		"	set tcl_rc [catch {::oratcl::longwrite $stm  $sql  writevar  $longtype}  tcl_res]; "
		"	if {$tcl_rc} { "
		"		set info $errorInfo; "
		"		set err_txt \"oralong $fn: [oramsg $handle error] $info\"; "
		"		return -code error $err_txt; "
		"	}; "
		"	return -code ok $oralong(oratcl_ok); "
		"} "

	};

	for (x = 0; x < (sizeof(tvars_list)/sizeof(struct tvars)); x++) {

		if (debug) {
			fprintf(stderr, "ns = %s\n", tvars_list[x].ns);
			fprintf(stderr, "name = %s\n", tvars_list[x].name);
			fprintf(stderr, "value = %s\n", tvars_list[x].value);
		}
					
		rx = Tcl_SetVar2((Tcl_Interp *) interp,
				 (CONST char *) tvars_list[x].ns,
				 (CONST char *) tvars_list[x].name,
				 (CONST char *) tvars_list[x].value,
				 0); 

		if (rx == NULL) {
			fprintf(stderr,
				"%sset variable '%s'",
				"Oralong_Init(): Failed to ",
				(CONST char *) tvars_list[x].name);
				return TCL_ERROR;
		}

	}

	for (x = 0; x < (sizeof(script)/sizeof(char const *)); x++) {
		tmp1_obj=Tcl_NewStringObj(script[x], -1);
		Tcl_IncrRefCount(tmp1_obj);
		if (Tcl_EvalObjEx(interp, tmp1_obj, 0) != TCL_OK) {
			fprintf(stderr,
				"%sevaluate internal script at index %zu",
				"Oralong_Init(): Failed to ",
				(size_t) x);
			Tcl_DecrRefCount(tmp1_obj);
			return TCL_ERROR;
		}
		Tcl_DecrRefCount(tmp1_obj);
	}

	return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * Oratcl_LongRead --
 *    Implements the ::oratcl::longread command:
 *    usage: oradesc stm_handle sql_stmt data_var data_type
 *
 *    results:
 *	table information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_LongRead (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;

	OCIDefine       *defnp;		/* define pointer */

	char		*sql;
	int		sql_len = 0;

	char		*btype;
	int		btype_len = 0;

	int		rc, frc, prc;

	ub4		type;
	ub4		p_type;
	ub4		iteration;
	ub4		table;

	int		rowcnt;

	ub1		piece;
	ub2		piece_size;

	char		*piece_data = NULL;
	ub4		piece_len;
	ub2		piece_rcode;

	ub2		bind_type = SQLT_LNG;

	Tcl_DString	uniStr;
	Tcl_DString	resStr;
	Tcl_Obj		*res_obj;

	int		tcl_return = TCL_OK;

	if (objc < 5) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle sql_str datavariable");
		return TCL_ERROR;
	}

	Tcl_DStringInit(&resStr);

	stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
				       Tcl_GetStringFromObj(objv[1], NULL));

	if (stmHashPtr == NULL) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": handle ",
				objv[1],
				" not open");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
	LogPtr = (OratclLogs *) Tcl_GetHashValue(StmPtr->logHashPtr);

	sql = Tcl_GetStringFromObj(objv[2], &sql_len);
	btype = Tcl_GetStringFromObj(objv[4], &btype_len);
	if (*btype == 'l'
	   && strcmp(btype,"longraw") == 0) {
		bind_type = SQLT_LBI;
	}


	piece_data = ckalloc (StmPtr->longpsize + 1);

	piece_data[StmPtr->longpsize] = '\0';
	piece_size = StmPtr->longpsize;
	piece_len = StmPtr->longpsize;

	rc = OCI_StmtPrepare((dvoid *) StmPtr->stmhp,
			     LogPtr->errhp,
			     (text *) sql,
			     (ub4) strlen( (char *) sql),
			     (ub4) OCI_NTV_SYNTAX,
			     (ub4) OCI_DEFAULT);

	Tcl_DStringInit(&StmPtr->ora_err);
	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	rc = OCI_DefineByPos(StmPtr->stmhp,
			     &defnp,
			     LogPtr->errhp,
			     (ub4) 1,
			     (dvoid *) 0,
			     (sb4) INT_MAX,
			     (ub2) bind_type,
			     (dvoid *) 0,
			     (ub2 *) &piece_size,
			     (ub2 *) &piece_rcode,
			     (ub4) OCI_DYNAMIC_FETCH);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	rc = OCI_StmtExecute(LogPtr->svchp,
			     StmPtr->stmhp,
			     LogPtr->errhp,
			     (ub4) 0,
			     (ub4) 0,
			     (OCISnapshot *) NULL,
			     (OCISnapshot *) NULL,
			     OCI_DEFAULT);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	frc = OCI_StmtFetch(StmPtr->stmhp,
			  LogPtr->errhp,
			  1,
			  (ub2) OCI_FETCH_NEXT,
			  (ub4) OCI_DEFAULT);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			frc,
			1,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (frc != OCI_NEED_DATA && frc != 0) {
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	while (frc == OCI_NEED_DATA) {

		prc = OCI_StmtGetPieceInfo(StmPtr->stmhp,
					   LogPtr->errhp,
					   (dvoid *) &defnp,
					   (ub4 *) &type,
					   (ub1 *) &p_type,
					   (ub4 *) &iteration,
					   (ub4 *) &table,	
					   (ub1 *) &piece);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				prc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (prc == OCI_ERROR || prc == OCI_INVALID_HANDLE) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		prc = OCI_StmtSetPieceInfo(defnp,
					   OCI_HTYPE_DEFINE,
					   LogPtr->errhp,
					   (dvoid *) piece_data,
					   (ub4 *) &piece_len,
					   (ub1) piece,
					   (CONST dvoid *) 0,		/* no indicator */
					   (ub2 *) NULL);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				prc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (prc == OCI_ERROR || prc == OCI_INVALID_HANDLE) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		frc = OCI_StmtFetch(StmPtr->stmhp,
				  LogPtr->errhp,
				  1,
				  (ub2) OCI_FETCH_NEXT,
				  (ub4) OCI_DEFAULT);

		piece_data[piece_len] = '\0';

		Tcl_DStringAppend(&resStr, piece_data, piece_len);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				frc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (frc != OCI_NEED_DATA && frc != 0) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

	}

	/*
	 * Convert the result to UTF from external encoding
	 */
	if (StmPtr->utfmode) {
		Tcl_DStringInit(&uniStr);
		Tcl_ExternalToUtfDString(NULL,
					Tcl_DStringValue(&resStr),
					Tcl_DStringLength(&resStr),
					&uniStr);
		res_obj = Tcl_NewStringObj(Tcl_DStringValue(&uniStr),
					   Tcl_DStringLength(&uniStr));
		Tcl_DStringFree(&uniStr);
	} else {
		res_obj = Tcl_NewStringObj(Tcl_DStringValue(&resStr),
					   Tcl_DStringLength(&resStr));
	}
	Tcl_ObjSetVar2(interp, objv[3], NULL, res_obj, TCL_LEAVE_ERR_MSG);

	rowcnt = 0;
	rc = (OCI_AttrGet( (dvoid *) StmPtr->stmhp,
			  (ub4) OCI_HTYPE_STMT,
			  (ub4 *) &rowcnt,
			  (ub4) 0,
			  OCI_ATTR_ROW_COUNT,
			  LogPtr->errhp));

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": OCIAttrGet failed",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* set "rows" to rpc (rows processed count) */
	StmPtr->ora_row = rowcnt;

common_exit:

	Tcl_DStringFree(&resStr);

	if (piece_data != NULL) {
		ckfree ((char *) piece_data);
	}

	return tcl_return;
}

#define ORATCL_LONGWRITE_DEBUG 0

/*
 *----------------------------------------------------------------------
 *
 * Oratcl_LongWrite --
 *    Implements the ::oratcl::longwrite command:
 *    usage: oradesc stm_handle sql_stmt data_var data_type
 *
 *    results:
 *	table information
 *      TCL_OK -
 *      TCL_ERROR -
 *----------------------------------------------------------------------
 */

int
Oratcl_LongWrite (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;
	OratclLogs	*LogPtr;

	OCIBind		*bindp;		/* bind pointer */

	int		rc;

	char		*sql;
	int		sql_len = 0;

	Tcl_DString	outStr;
	char		*pre_data;
	int		pre_data_len = 0;

	char		*type;
	int		type_len = 0;

	int		offset, sofar;
	char		*wherebuf;
	char		*pData;
	ub4		pSize, pLen;

	int		rowcnt;

	ub1		piece;

	ub2		bind_type = SQLT_LNG;

	int		tcl_return = TCL_OK;

	if (objc < 5) {
		Tcl_WrongNumArgs(interp,
				 objc,
				 objv,
				 "stm_handle sql_str datavariable");
		return TCL_ERROR;
	}

	Tcl_DStringInit(&outStr);

	stmHashPtr = Tcl_FindHashEntry(OratclStatePtr->stmHash,
				       Tcl_GetStringFromObj(objv[1], NULL));

	if (stmHashPtr == NULL) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": handle ",
				objv[1],
				" not open");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
	LogPtr = (OratclLogs *) Tcl_GetHashValue(StmPtr->logHashPtr);
	Tcl_DStringInit(&StmPtr->ora_err);
	Tcl_DStringInit(&LogPtr->ora_err);

	sql = Tcl_GetStringFromObj(objv[2], &sql_len);

	pre_data = Tcl_GetStringFromObj(Tcl_ObjGetVar2(interp,
						       objv[3],
						       NULL,
						       TCL_LEAVE_ERR_MSG),
					&pre_data_len);

	if (pre_data_len > 0) {
		if (StmPtr->utfmode) {
			Tcl_UtfToExternalDString(NULL, pre_data, pre_data_len, &outStr);
		} else {
			Tcl_DStringAppend(&outStr, pre_data, pre_data_len);
		}
	}

	type = Tcl_GetStringFromObj(objv[4], &type_len);
	if (*type == 'l'
	   && strcmp(type,"longraw") == 0) {
		bind_type = SQLT_LBI;
	}

	rc = OCI_StmtPrepare((dvoid *) StmPtr->stmhp,
			      LogPtr->errhp,
			      (text *) sql,
			      (ub4) strlen( (char *) sql),
			      (ub4) OCI_NTV_SYNTAX,
			      (ub4) OCI_DEFAULT);

	if (rc != OCI_SUCCESS) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}


	pData = Tcl_DStringValue(&outStr);
	pLen = Tcl_DStringLength(&outStr);

	if (pLen == 0) {

		/*
		 * if assigning the empty string,
		 * then piecewise operations are not needed
		 */
		rc = OCI_BindByName((OCIStmt *) StmPtr->stmhp,
				    (OCIBind **) &bindp,
				    (OCIError *) LogPtr->errhp,
				    (text *) ":lng",
				    (sb4) 4,
				    (dvoid *) pData,
				    (sb4) pLen,
				    (ub2) SQLT_STR,
				    (dvoid *) 0,
				    (ub2 *) 0,
				    (ub2 *) 0,
				    (ub4) 0,
				    (ub4 *) 0,
				    (ub4) OCI_DEFAULT);


	} else {

		rc = OCI_BindByName((OCIStmt *) StmPtr->stmhp,
				    (OCIBind **) &bindp,
				    (OCIError *) LogPtr->errhp,
				    (text *) ":lng",
				    (sb4) 4,
				    (dvoid *) 0,
				    (sb4) INT_MAX,
				    (ub2) bind_type,
				    (dvoid *) 0,
				    (ub2 *) 0,
				    (ub2 *) 0,
				    (ub4) 0,
				    (ub4 *) 0,
				    (ub4) OCI_DATA_AT_EXEC);

	}

	if (rc != OCI_SUCCESS) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	rc = OCI_StmtExecute(LogPtr->svchp,
			     StmPtr->stmhp,
			     LogPtr->errhp,
			     (ub4) 1,
			     (ub4) 0,
			     (OCISnapshot *) NULL,
			     (OCISnapshot *) NULL,
			     OCI_DEFAULT);


	if (rc != OCI_SUCCESS && rc != OCI_NEED_DATA) {
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}


	if (pLen <= StmPtr->longpsize) {
		pSize = pLen;
		piece = OCI_ONE_PIECE;
	} else {
		pSize = StmPtr->longpsize;
		piece = OCI_FIRST_PIECE;
	}

	offset = 1;
	sofar = 0;

	while (sofar < pLen) {

		wherebuf = &pData[offset -1];

		rc = OCI_StmtSetPieceInfo((dvoid *) bindp,
					  OCI_HTYPE_BIND,
					  LogPtr->errhp,
					  (dvoid *) wherebuf,
					  (ub4 *) &pSize,
					  (ub1) piece,
					  (CONST dvoid *) 0,
					  (ub2 *) 0);

		if (rc != OCI_SUCCESS) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&LogPtr->ora_rc,
					&LogPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

#if ORATCL_LONGWRITE_DEBUG
		if (piece == OCI_ONE_PIECE)
			fprintf(stderr, "OCI_ONE_PIECE\n");
		if (piece == OCI_FIRST_PIECE)
			fprintf(stderr, "OCI_FIRST_PIECE\n");
		if (piece == OCI_NEXT_PIECE)
			fprintf(stderr, "OCI_NEXT_PIECE\n");
		if (piece == OCI_LAST_PIECE)
			fprintf(stderr, "OCI_LAST_PIECE\n");
#endif

		rc = OCI_StmtExecute(LogPtr->svchp,
				     StmPtr->stmhp,
				     LogPtr->errhp,
				     (ub4) 1,
				     (ub4) 0,
				     (CONST OCISnapshot *) NULL,
				     (OCISnapshot *) NULL,
				     (ub4) OCI_DEFAULT);

		if (rc != OCI_SUCCESS && rc != OCI_NEED_DATA) {
			Oratcl_Checkerr(interp,
					LogPtr->errhp,
					rc,
					1,
					&StmPtr->ora_rc,
					&StmPtr->ora_err);
			tcl_return = TCL_ERROR;
			goto common_exit;
		}

		if (pSize < StmPtr->longpsize)
			sofar += pSize;
		else if (pSize == pLen)
			sofar = pLen;
		else
			sofar += StmPtr->longpsize;

		if (pLen <= sofar + StmPtr->longpsize) {
			piece = OCI_LAST_PIECE;
			pSize = pLen - sofar;
		} else {
			piece = OCI_NEXT_PIECE;
		}

		offset += StmPtr->longpsize;
	}

	rowcnt = 0;
	rc = (OCI_AttrGet( (dvoid *) StmPtr->stmhp,
			  (ub4) OCI_HTYPE_STMT,
			  (ub4 *) &rowcnt,
			  (ub4) 0,
			  OCI_ATTR_ROW_COUNT,
			  LogPtr->errhp));

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			0,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc == OCI_ERROR || rc == OCI_INVALID_HANDLE) {
		Oratcl_ErrorMsg(interp,
				objv[0],
				": OCIAttrGet failed",
				(Tcl_Obj *) NULL,
				(char *) NULL);
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	/* set "rows" to rpc (rows processed count) */
	StmPtr->ora_row = rowcnt;

common_exit:

	Tcl_DStringFree(&outStr);

	return tcl_return;
}
