/*
 * oratcl.c
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#if defined(WIN32) || defined(_WIN32)
#ifndef __WIN32__
#define __WIN32__
#endif
#endif

#if defined(__WIN32__)
#include <windows.h>
#endif

#include "oratclInt.h"
#include "oratcl.h"
#include <tcl.h>
#include <fcntl.h>
#include <sys/stat.h>

#ifdef NO_STRING_H
#include <strings.h>
#else
#include <string.h>
#endif

#include <ctype.h>
#include <stdlib.h>

#ifdef __WIN32__
#undef  TCL_STORAGE_CLASS
#define TCL_STORAGE_CLASS  DLLEXPORT

EXTERN Oratcl_Init	_ANSI_ARGS_((Tcl_Interp *interp));

BOOL APIENTRY
DllEntryPoint(hInst, reason, reserved)
HINSTANCE hInst;            /* Library instance handle. */
DWORD reason;               /* Reason this function is being called. */
LPVOID reserved;            /* Not used. */
{
    return TRUE;
}

#define DLOPEN(libname, flags)	LoadLibrary(libname)
#define DLCLOSE(path)		((void *) FreeLibrary((HMODULE) path))
#define DLSYM(handle, symbol, proc, type) \
	(proc = (type) GetProcAddress((HINSTANCE) handle, symbol))

#else			/* __WIN32__ */

#if defined(__hpux)

/* HPUX requires shl_* routines */
#include <dl.h>
#define HMODULE shl_t
#define DLOPEN(libname, flags)	shl_load(libname, \
	BIND_DEFERRED|BIND_VERBOSE|DYNAMIC_PATH, 0L)
#define DLCLOSE(path)		shl_unload((shl_t) path)
#define DLERROR ""
#define DLSYM(handle, symbol, proc, type) \
	if (shl_findsym(&handle, symbol, (short) TYPE_PROCEDURE, \
		(void *) &proc) != 0) { proc = NULL; }

#else			/* __hpux */

#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif
#define HMODULE void *
#define DLOPEN	dlopen
#define DLCLOSE	dlclose
#define DLERROR dlerror()
#define DLSYM(handle, symbol, proc, type) \
	(proc = (type) dlsym(handle, symbol))

#endif			/* __hpux */

#endif			/* __WIN32__ */

#include "oratclTypes.h"

/*
 * prefix is used to identify handles
 * login handles are:  prefix , login index                     e.g. oratcl0
 * statement handles are:  login handle , '.', statement index  e.g. oratcl0.0
 */

#include "oratclExtern.h"

extern int	  Oratcl_Init		_ANSI_ARGS_((Tcl_Interp	*interp));
extern int	  Oralob_Init		_ANSI_ARGS_((Tcl_Interp	*interp));
extern int	  Oralong_Init		_ANSI_ARGS_((Tcl_Interp	*interp));

/*
 * Definitions of the Oracle function vectors. Taken from
 * oratclTypes.h which now only declares the variables, avoiding
 * multiple definitions.
 */

OCIENVCREATE	OCI_EnvCreate;
OCIINITIALIZE	OCI_Initialize;
OCIENVINIT	OCI_EnvInit;
OCIHANDLEALLOC	OCI_HandleAlloc;
OCIHANDLEFREE	OCI_HandleFree;
OCIDESCRIPTORALLOC OCI_DescriptorAlloc;
OCIDESCRIPTORFREE OCI_DescriptorFree;
OCIATTRGET	OCI_AttrGet;
OCIATTRSET	OCI_AttrSet;
OCISERVERATTACH	OCI_ServerAttach;
OCISERVERDETACH	OCI_ServerDetach;
OCISESSIONBEGIN	OCI_SessionBegin;
OCISESSIONEND	OCI_SessionEnd;
OCIERRORGET	OCI_ErrorGet;
OCITRANSCOMMIT OCI_TransCommit;
OCITRANSROLLBACK OCI_TransRollback;
OCITERMINATE	OCI_Terminate;
OCISERVERVERSION OCI_ServerVersion;
OCISERVERRELEASE OCI_ServerRelease;
OCICLIENTVERSION OCI_ClientVersion;
OCISTMTPREPARE	OCI_StmtPrepare;
OCISTMTGETPIECEINFO	OCI_StmtGetPieceInfo;
OCISTMTSETPIECEINFO	OCI_StmtSetPieceInfo;
OCISTMTEXECUTE	OCI_StmtExecute;
OCISTMTFETCH	OCI_StmtFetch;
OCIDESCRIBEANY	OCI_DescribeAny;
OCIPARAMGET	OCI_ParamGet;
OCIPARAMSET	OCI_ParamSet;
OCIBREAK	OCI_Break;
OCIRESET	OCI_Reset;
OCIDEFINEBYPOS	OCI_DefineByPos;
OCIBINDBYNAME	OCI_BindByName;
OCILOBREAD OCI_LobRead;
OCILOBGETLENGTH OCI_LobGetLength;
OCIBINDDYNAMIC OCI_BindDynamic;
OCINLSGETINFO	OCI_NlsGetInfo;
OCINLSNUMERICINFOGET	OCI_NlsNumericInfoGet;

/*
 *----------------------------------------------------------------------
 * Oratcl_ErrorMsg
 *    This procedure generates a Oratcl error message in interpreter.
 *
 * Results: None
 *
 * Side effects:
 *      An error message is generated in interp's result object to
 *      indicate that a command was invoked that resulted in an error.
 *      The message has the form
 *              "obj0 msg0 obj1 msg1"
 *
 *----------------------------------------------------------------------
 */

void
Oratcl_ErrorMsg(interp, obj0, msg0, obj1, msg1)
	Tcl_Interp	*interp;
	Tcl_Obj 	*obj0, *obj1;
	char		*msg0, *msg1;
{
	Tcl_Obj		*newPtr;

	newPtr = Tcl_NewObj();
	if (obj0) {
		Tcl_AppendObjToObj(newPtr, obj0);
	}
	if (msg0) {
		Tcl_AppendToObj(newPtr, msg0, -1);
	}
	if (obj1) {
		Tcl_AppendObjToObj(newPtr, obj1);
	}
	if (msg1) {
		Tcl_AppendToObj(newPtr, msg1, -1);
	}
	Tcl_SetObjResult(interp, newPtr);
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Delete --
 *   close any handles left open when an interpreter is deleted
 *----------------------------------------------------------------------
 */

void
Oratcl_Delete (clientData, interp)
    ClientData clientData;
    Tcl_Interp *interp;
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	OratclLogs	*LogPtr;
	OratclStms	*StmPtr;
	Tcl_HashEntry	*logHashPtr;
	Tcl_HashEntry	*stmHashPtr;
	Tcl_HashSearch  srch;

        if (OratclStatePtr != NULL) {

	/*
	 * Close all open statement handles.
	 */
          if (OratclStatePtr->stmHash != NULL) {
	    for (stmHashPtr = Tcl_FirstHashEntry(OratclStatePtr->stmHash, &srch);
	         stmHashPtr != (Tcl_HashEntry *)NULL;
	         stmHashPtr = Tcl_FirstHashEntry(OratclStatePtr->stmHash, &srch)) {

		    StmPtr = (OratclStms *) Tcl_GetHashValue(stmHashPtr);
		    Oratcl_StmFree(StmPtr);
		    StmPtr = NULL;
		    Tcl_DeleteHashEntry(stmHashPtr);
	    }

	    Tcl_DeleteHashTable(OratclStatePtr->stmHash);
	    ckfree((char *) OratclStatePtr->stmHash);
	    OratclStatePtr->stmHash = NULL;
          }

	/*
	 * Close all open logon handles.
	 */
        if (OratclStatePtr->logHash != NULL) {
	  for (logHashPtr = Tcl_FirstHashEntry(OratclStatePtr->logHash, &srch);
	       logHashPtr != (Tcl_HashEntry *)NULL;
	       logHashPtr = Tcl_FirstHashEntry(OratclStatePtr->logHash, &srch)) {

		  LogPtr = (OratclLogs *) Tcl_GetHashValue(logHashPtr);
		  OCI_SessionEnd(LogPtr->svchp,
			         LogPtr->errhp,
			         LogPtr->usrhp,
			         OCI_DEFAULT);
		  OCI_ServerDetach(LogPtr->srvhp,
				   LogPtr->errhp,
				   (ub4) OCI_DEFAULT);
		  Oratcl_LogFree(LogPtr);
		  Tcl_DeleteHashEntry(logHashPtr);
	  }

	  Tcl_DeleteHashTable(OratclStatePtr->logHash);
	  ckfree((char *) OratclStatePtr->logHash);
	  OratclStatePtr->logHash = NULL;
        }

    }

    /*
     *  Free the hash table.
     */
    if (OratclStatePtr != NULL) {
	ckfree((char *) OratclStatePtr);
	OratclStatePtr = NULL;
    }

}


/*
 *----------------------------------------------------------------------
 * Oratcl_Init --
 *   perform all initialization for the Oracle - Tcl interface.
 *   adds additional commands to interp, creates message array
 *
 *   a call to Oratcl_Init should exist in Tcl_CreateInterp or
 *   Tcl_CreateExtendedInterp.
 *----------------------------------------------------------------------
 */

int
Oratcl_Init (interp)
	Tcl_Interp	*interp;
{
	OratclState	*OratclStatePtr;

	int		rc = 0;

	HMODULE		handle;

#ifdef __WIN32__
	DWORD		last_error;
#else							/* __WIN32__ */
	CONST char	*native;

	Tcl_Obj		*env_obj;
#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
	Tcl_Obj		*tmp_obj = NULL;
#endif
	Tcl_Obj		*pt1_obj = NULL;
	Tcl_Obj		*pt2_obj = NULL;
	Tcl_Obj		*pt3_obj = NULL;

#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
	Tcl_Obj		**pathObjv;
	int		pathObjc;
	Tcl_Obj		*pathList;
#elif ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION == 3))
	char		**pathObjv;
	int		pathObjc;
	Tcl_DString	result;
#endif
	CONST char	*ora_lib = NULL;

#endif							/* __WIN32__ */

#ifdef USE_TCL_STUBS
	if (Tcl_InitStubs(interp, "8.1", 0) == NULL) {
		return TCL_ERROR;
	}
#endif

#ifndef __WIN32__

	/* Load the oracle client library:
	 * if env(ORACLE_LIBRARY) is defined use it.
	 * else use $env(ORACLE_HOME)/lib/libclntsh.SHLIB_SUFFIX
	 */

	ora_lib = Tcl_GetVar2(interp, "env", "ORACLE_LIBRARY", TCL_GLOBAL_ONLY);

	if (ora_lib) {
		native = ora_lib;
	} else {

#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
		pathObjv = (Tcl_Obj **) ckalloc (3 * sizeof(*pathObjv));
#elif ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION == 3))
		Tcl_DStringInit(&result);
		pathObjv = (char **) ckalloc (3 * sizeof(char *));
#endif
		pathObjc = 0;

		env_obj = Tcl_NewStringObj("env(ORACLE_HOME)", -1);
		Tcl_IncrRefCount(env_obj);
		pt1_obj = Tcl_ObjGetVar2(interp,
					env_obj,
					NULL,
					TCL_LEAVE_ERR_MSG);
		Tcl_DecrRefCount(env_obj);
		if (pt1_obj == NULL) {
			return TCL_ERROR;
		}
		pt2_obj = Tcl_NewStringObj("lib", -1);
		pt3_obj = Tcl_NewStringObj("libclntsh"SHLIB_SUFFIX, -1);

		Tcl_IncrRefCount(pt1_obj);
		Tcl_IncrRefCount(pt2_obj);
		Tcl_IncrRefCount(pt3_obj);

#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
		pathObjv[pathObjc++] = pt1_obj;
		pathObjv[pathObjc++] = pt2_obj;
		pathObjv[pathObjc++] = pt3_obj;

		pathList = Tcl_NewListObj(pathObjc, pathObjv);
		Tcl_IncrRefCount(pathList);

		ckfree((char *)pathObjv);
		Tcl_DecrRefCount(pt1_obj);
		Tcl_DecrRefCount(pt2_obj);
		Tcl_DecrRefCount(pt3_obj);

		tmp_obj = Tcl_FSJoinPath(pathList, -1);
		Tcl_IncrRefCount(tmp_obj);
		Tcl_DecrRefCount(pathList);
		native = Tcl_FSGetNativePath(tmp_obj);

#elif ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION == 3))
		pathObjv[pathObjc++] = Tcl_GetString(pt1_obj);
		pathObjv[pathObjc++] = Tcl_GetString(pt2_obj);
		pathObjv[pathObjc++] = Tcl_GetString(pt3_obj);

		Tcl_JoinPath(pathObjc, pathObjv, &result);

		ckfree((char *)pathObjv);
		Tcl_DecrRefCount(pt1_obj);
		Tcl_DecrRefCount(pt2_obj);
		Tcl_DecrRefCount(pt3_obj);
		Tcl_DecrRefCount(env_obj);
		native = Tcl_DStringValue(&result);
#endif

	}

	handle = DLOPEN(native, RTLD_NOW | RTLD_GLOBAL);

	if (handle == NULL) {
		fprintf(stderr, "%s(): Failed to load %s with error %s\n",
			"Oratcl_Init",
			native,
			DLERROR);
		if (ora_lib) {
			fprintf(stderr, 
				"%s(): ORACLE_LIBRARY = %s : file not found.\n",
				"Oratcl_Init",
				native);
		}

		if (ora_lib == NULL) {
#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
			Tcl_DecrRefCount(tmp_obj);
#elif ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION == 3))
			Tcl_DStringFree(&result);
#endif
		}
		return TCL_ERROR;
	}

	if (ora_lib == NULL) {
#if ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION > 3))
		Tcl_DecrRefCount(tmp_obj);
#elif ((TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION == 3))
		Tcl_DStringFree(&result);
#endif
	}

#else

	handle = LoadLibrary(TEXT("OCI.DLL"));
	if (handle == NULL || handle == INVALID_HANDLE_VALUE) {
		last_error = GetLastError();
		fprintf(stderr, "%s(): %s with error %lu",
			"Oratcl_Init",
			"Failed loading oci.dll symbols",
			(unsigned long) last_error);
		return TCL_ERROR;
	}

#endif	/* WIN32 */

	DLSYM(handle, "OCIEnvCreate",	OCI_EnvCreate,	     OCIENVCREATE);
	DLSYM(handle, "OCIInitialize",	OCI_Initialize,	     OCIINITIALIZE);
	DLSYM(handle, "OCIEnvInit",	OCI_EnvInit,	     OCIENVINIT);
	DLSYM(handle, "OCIHandleAlloc",	OCI_HandleAlloc,     OCIHANDLEALLOC);
	DLSYM(handle, "OCIHandleFree",	OCI_HandleFree,	     OCIHANDLEFREE);
	DLSYM(handle, "OCIAttrGet",	OCI_AttrGet,	     OCIATTRGET);
	DLSYM(handle, "OCIAttrSet",	OCI_AttrSet,	     OCIATTRSET);
	DLSYM(handle, "OCIServerAttach", OCI_ServerAttach,   OCISERVERATTACH);
	DLSYM(handle, "OCIServerDetach", OCI_ServerDetach,   OCISERVERDETACH);
	DLSYM(handle, "OCISessionBegin", OCI_SessionBegin,   OCISESSIONBEGIN);
	DLSYM(handle, "OCISessionEnd",	OCI_SessionEnd,	     OCISESSIONEND);
	DLSYM(handle, "OCIErrorGet",	OCI_ErrorGet,	     OCIERRORGET);
	DLSYM(handle, "OCITransCommit",	OCI_TransCommit,     OCITRANSCOMMIT);
	DLSYM(handle, "OCITransRollback", OCI_TransRollback, OCITRANSROLLBACK);
	DLSYM(handle, "OCIServerVersion", OCI_ServerVersion, OCISERVERVERSION);
	DLSYM(handle, "OCIServerRelease", OCI_ServerRelease, OCISERVERRELEASE);
	DLSYM(handle, "OCIClientVersion", OCI_ClientVersion, OCICLIENTVERSION);
	DLSYM(handle, "OCITerminate",	OCI_Terminate,	     OCITERMINATE);
	DLSYM(handle, "OCIParamGet",	OCI_ParamGet,	     OCIPARAMGET);
	DLSYM(handle, "OCIParamSet",	OCI_ParamSet,	     OCIPARAMSET);
	DLSYM(handle, "OCIDescribeAny",	OCI_DescribeAny,     OCIDESCRIBEANY);
	DLSYM(handle, "OCIBreak",	OCI_Break,	     OCIBREAK);
	DLSYM(handle, "OCIReset",	OCI_Reset,	     OCIRESET);
	DLSYM(handle, "OCIDefineByPos",	OCI_DefineByPos,     OCIDEFINEBYPOS);
	DLSYM(handle, "OCIBindByName",	OCI_BindByName,	     OCIBINDBYNAME);
	DLSYM(handle, "OCIBindDynamic",	OCI_BindDynamic,     OCIBINDDYNAMIC);
	DLSYM(handle, "OCINlsGetInfo",	OCI_NlsGetInfo,	     OCINLSGETINFO);
	DLSYM(handle, "OCINlsNumericInfoGet", OCI_NlsNumericInfoGet, OCINLSNUMERICINFOGET);
	DLSYM(handle, "OCIStmtPrepare",	OCI_StmtPrepare,     OCISTMTPREPARE);
	DLSYM(handle, "OCIStmtExecute",	OCI_StmtExecute,     OCISTMTEXECUTE);
	DLSYM(handle, "OCIStmtFetch",	OCI_StmtFetch,	     OCISTMTFETCH);

	DLSYM(handle, "OCIStmtGetPieceInfo", OCI_StmtGetPieceInfo,
		OCISTMTGETPIECEINFO);
	DLSYM(handle, "OCIStmtSetPieceInfo", OCI_StmtSetPieceInfo,
		OCISTMTSETPIECEINFO);
	DLSYM(handle, "OCIDescriptorAlloc",  OCI_DescriptorAlloc, 
		OCIDESCRIPTORALLOC);
	DLSYM(handle, "OCIDescriptorFree",   OCI_DescriptorFree, 
		OCIDESCRIPTORFREE);
	DLSYM(handle, "OCILobRead",          OCI_LobRead, 
		OCILOBREAD);
	DLSYM(handle, "OCILobGetLength",     OCI_LobGetLength, 
		OCILOBGETLENGTH);

	/* sanity check at least one symbol */
	if (OCI_Initialize == NULL) {
	    DLCLOSE(handle);
	    Tcl_AppendResult(interp,
		    "Oratcl_Init failed to find symbols in dll",
		    (char *) NULL);
	    return TCL_ERROR;
	}

	OratclStatePtr = (OratclState *) ckalloc (sizeof(OratclState));

	OratclStatePtr->logHash = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
	Tcl_InitHashTable(OratclStatePtr->logHash, TCL_STRING_KEYS);
	OratclStatePtr->logid = -1;

	OratclStatePtr->stmHash = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
	Tcl_InitHashTable(OratclStatePtr->stmHash, TCL_STRING_KEYS);
	OratclStatePtr->stmid = -1;


	/*
	 * Initialize the new Tcl commands
	 */

	Tcl_CreateObjCommand (interp,
			      "oralogon",
			      Oratcl_Logon,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oralogoff",
			      Oratcl_Logoff,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oracommit",
			      Oratcl_Commit,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraroll",
			      Oratcl_Roll,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraautocom",
			      Oratcl_Autocom,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orainfo",
			      Oratcl_Info,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oramsg",
			      Oratcl_Message,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oradesc",
			      Oratcl_Describe,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraldalist",
			      Oratcl_Lda_List,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraopen",
			      Oratcl_Open,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraclose",
			      Oratcl_Close,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orasql",
			      Oratcl_Sql,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oracols",
			      Oratcl_Cols,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orabindexec",
			      Oratcl_Bindexec,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraplexec",
			      Oratcl_PLexec,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orastmlist",
			      Oratcl_Stm_List,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraconfig",
			      Oratcl_Config,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::longread",
			      Oratcl_LongRead,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::longwrite",
			      Oratcl_LongWrite,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraparse",
			      Oratcl_Parse,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::oraparse",
			      Oratcl_Parse,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orabind",
			      Oratcl_Bind,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::orabind",
			      Oratcl_Bind,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "oraexec",
			      Oratcl_Exec,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::oraexec",
			      Oratcl_Exec,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orafetch",
			      Oratcl_Fetch,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::orafetch",
			      Oratcl_Fetch,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "orabreak",
			      Oratcl_Break,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	Tcl_CreateObjCommand (interp,
			      "::oratcl::orabreak",
			      Oratcl_Break,
			      (ClientData) OratclStatePtr,
			      (Tcl_CmdDeleteProc *) NULL);

	/* set some OCI constants for ease of use */

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		    "OCI_SUCCESS",
		    STR_OCI_SUCCESS,
		    TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		    "OCI_SUCCESS_WITH_INFO",
		    STR_OCI_SUCCESS_WITH_INFO,
		    TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		     "OCI_ERROR",
		     STR_OCI_ERROR,
		     TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		    "OCI_INVALID_HANDLE",
		    STR_OCI_INVALID_HANDLE,
		    TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		     "OCI_STILL_EXECUTING",
		     STR_OCI_STILL_EXECUTING,
		     TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		    "OCI_NO_DATA",
		    STR_OCI_NO_DATA,
		    TCL_LEAVE_ERR_MSG);

	Tcl_SetVar2(interp,
		    "::oratcl::codes",
		    "OCI_NEED_DATA",
		    STR_OCI_NEED_DATA,
		    TCL_LEAVE_ERR_MSG);

	/* callback - clean up procs left open on interpreter deletetion */
	Tcl_CallWhenDeleted(interp,
			    (Tcl_InterpDeleteProc *) Oratcl_Delete,
			    (ClientData) OratclStatePtr);

	rc = Oralob_Init(interp);
	rc = Oralong_Init(interp);

	if (Tcl_PkgProvide(interp, PACKAGE_NAME, PACKAGE_VERSION) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Checkerr
 *   set the oracle return code and error message
 *----------------------------------------------------------------------
 */

void
Oratcl_Checkerr (interp, errhp, rc, flag, rcPtr, errPtr)
	Tcl_Interp	*interp;
	OCIError	*errhp;
	sword		rc;
	int		flag;
	int		*rcPtr;
	Tcl_DString	*errPtr;
{

	Tcl_DString	errStr;
	char		*errstr = NULL;
	sb4		errcode = 0;

	Tcl_DStringInit(&errStr);

	switch (rc) {
		case OCI_SUCCESS_WITH_INFO:
		case OCI_NEED_DATA:
		case OCI_NO_DATA:
		case OCI_ERROR:
		case OCI_STILL_EXECUTING:
			if ((errstr = (char *) ckalloc(ORA_MSG_SIZE)) != NULL) {
				errstr[0] = '\0';
				OCI_ErrorGet ((dvoid *) errhp,
					      (ub4) 1,
					      (text *) NULL,
					      &errcode,
					      (text *) errstr,
					      (ub4) ORA_MSG_SIZE,
					      (ub4) OCI_HTYPE_ERROR); 
				/* remove trailing carriage return from Oracle string */
				errstr[strlen(errstr) - 1] = '\0';
				Tcl_DStringAppend(&errStr, errstr, -1);
				ckfree (errstr);
			}
			break;
		case OCI_SUCCESS:
		case OCI_INVALID_HANDLE:
		case OCI_CONTINUE:
			errcode = rc;
			break;
		default:
			Tcl_DStringAppend(&errStr, "Error - Unknown", -1);
	}

	if (flag==1) {
		Tcl_SetObjResult(interp, 	
				 Tcl_NewStringObj(Tcl_DStringValue(&errStr),
					          Tcl_DStringLength(&errStr)));
	}

	if (rcPtr) {
		*rcPtr = errcode;
	}

	if (errPtr) {
		Tcl_DStringAppend(errPtr,
				  Tcl_DStringValue(&errStr),
				  Tcl_DStringLength(&errStr));
	}

	Tcl_DStringFree(&errStr);
}


/*
 *----------------------------------------------------------------------
 * Oratcl_ColAlloc
 *   return a new OratclCols with nulled pointers and zeroed fields
 *----------------------------------------------------------------------
 */

OratclCols *
Oratcl_ColAlloc(fetchrows)
	int	fetchrows;
{
	OratclCols *ColPtr;

	if ((ColPtr = (OratclCols *) ckalloc(sizeof (OratclCols))) != NULL) {
		ColPtr->next = NULL;
		ColPtr->column.typecode = 0;
		Tcl_DStringInit(&ColPtr->column.typename);
		ColPtr->column.size = 0;
		ColPtr->column.name = NULL;
		ColPtr->column.namesz = 0;
		ColPtr->column.prec = 0;
		ColPtr->column.scale = 0;
		ColPtr->column.nullok = 0;
		ColPtr->column.valuep = NULL;
		ColPtr->column.valuesz	= 0;
		ColPtr->defnp = NULL;
		ColPtr->bindp = NULL;
		ColPtr->nFetchRows = fetchrows;
		if ((ColPtr->indp = (sb2 *) ckalloc (sizeof(ColPtr->indp) * fetchrows)) == NULL) {
			fprintf(stderr, "ColPtr->indp is NULL\n");
		}
		if ((ColPtr->rlenp = (ub2 *) ckalloc (sizeof(ColPtr->rlenp) * fetchrows)) == NULL) {
			fprintf(stderr, "ColPtr->rlenp is NULL\n");
		}
		if ((ColPtr->rcodep = (ub2 *) ckalloc (sizeof(ColPtr->rcodep) * fetchrows)) == NULL) {
			fprintf(stderr, "ColPtr->rcodep is NULL\n");
		}
		ColPtr->indp[0] = 0;
		ColPtr->rlenp[0] = 0;
		ColPtr->rcodep[0] = 0;
		ColPtr->bindPtr = NULL;
		ColPtr->array_values = NULL;
		ColPtr->array_count = 0;
		ColPtr->dty = SQLT_STR;
	}
	return ColPtr;
}


/*
 *----------------------------------------------------------------------
 * Oratcl_ColFree
 *      free elements of OratclCols or list of OratclCols
 *----------------------------------------------------------------------
 */

void
Oratcl_ColFree (ColPtr)
	OratclCols  *ColPtr;
{
	OratclCols  *next;

	while (ColPtr != NULL) {
		next = ColPtr->next;
		
		if (ColPtr->array_values != NULL) {
			Tcl_DecrRefCount(ColPtr->array_values);
		}

		if (ColPtr->column.name != NULL) {
			ckfree((char *) ColPtr->column.name);
		}

		if (ColPtr->column.valuep != NULL) {

			/* 
			 * if column is a LOB, the LobLocator has been stored in valuep
			 */
			if( ( ColPtr->dty == SQLT_CLOB ) || ( ColPtr->dty == SQLT_BLOB ) ){
				int    nRow;
				for( nRow = 0; nRow < ColPtr->nFetchRows; nRow++) {
					OCILobLocator  **pLocator;
					pLocator = (OCILobLocator**)(ColPtr->column.valuep
								   + ColPtr->column.valuesz * nRow);
					if (pLocator) {
						OCI_DescriptorFree((dvoid*)*pLocator,
								   (ub4) OCI_DTYPE_LOB);
					}
				}
			}

			ckfree(ColPtr->column.valuep);

		}

		Tcl_DStringFree(&ColPtr->column.typename);

		if (ColPtr->indp) {
			ckfree ((char *) ColPtr->indp);
		}

		if (ColPtr->rlenp) {
			ckfree ((char *) ColPtr->rlenp);
		}

		if (ColPtr->rcodep) {
			ckfree ((char *) ColPtr->rcodep);
		}

		ckfree((char *) ColPtr);
		ColPtr = next;
	}
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Stmfree
 *      free elements of OratclStms
 *----------------------------------------------------------------------
 */

void
Oratcl_StmFree (StmPtr)
	OratclStms	*StmPtr;
{
	if (StmPtr != NULL) {

		OCI_HandleFree((dvoid *) StmPtr->stmhp,
			       (ub4) OCI_HTYPE_STMT);

		Oratcl_ColFree(StmPtr->col_list);
		Oratcl_ColFree(StmPtr->bind_list);
		Tcl_DecrRefCount(StmPtr->nullvalue);
		if (StmPtr->array_dml_errors != NULL) {
			Tcl_DecrRefCount(StmPtr->array_dml_errors);
		}
		Tcl_DStringFree(&StmPtr->ora_err);
		ckfree((char *) StmPtr);

	}
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Logfree
 *      free elements of OratclLogs
 *----------------------------------------------------------------------
 */

void
Oratcl_LogFree (LogPtr)
	OratclLogs	*LogPtr;
{
	if (LogPtr != NULL) {

		if (LogPtr->usrhp)
			(void) OCI_HandleFree((dvoid *) LogPtr->usrhp,
					      (ub4) OCI_HTYPE_SESSION);
		if (LogPtr->svchp)
			(void) OCI_HandleFree((dvoid *) LogPtr->svchp,
					      (ub4) OCI_HTYPE_SVCCTX);
		if (LogPtr->srvhp)
			(void) OCI_HandleFree((dvoid *) LogPtr->srvhp,
					      (ub4) OCI_HTYPE_SERVER);
		if (LogPtr->errhp)
			(void) OCI_HandleFree((dvoid *) LogPtr->errhp,
					      (ub4) OCI_HTYPE_ERROR);
		if (LogPtr->envhp)
			(void) OCI_HandleFree((dvoid *) LogPtr->envhp,
					      (ub4) OCI_HTYPE_ENV);
		if (LogPtr->failovercallback != NULL) {
			ckfree(LogPtr->failovercallback);
			LogPtr->failovercallback = NULL;
		}

		ckfree((char *) LogPtr);
	}
}


/*
 *----------------------------------------------------------------------
 * Oratcl_ColAppend
 *      appends column results to tcl result
 *----------------------------------------------------------------------
 */

int
Oratcl_ColAppend (interp, StmPtr, listvar, arrayvar, hashType)
	Tcl_Interp	*interp;
	OratclStms	*StmPtr;
	Tcl_Obj		*listvar;
	Tcl_Obj		*arrayvar;
	int		hashType;
{
	int		rn;
	OratclCols 	*ColPtr;
	OratclCols	*col;
	char		*null_str;
	int		idx;
	int		iTcl;

	Tcl_DString	uniStr;
	Tcl_DString	lobStr;
	char 		*tmp = NULL;
	char		*pValue = NULL;
	Tcl_Obj		*val_obj;
	Tcl_Obj		*tmp_obj;
	Tcl_Obj		*lst_obj = NULL;
	OratclLogs	*LogPtr;

	/* quick sanity check */
	rn = StmPtr->fetchidx;
	if (rn < 0 || rn >= StmPtr->fetchmem) {
		/* TMH Does this ever happen ??? if so can it be tested for? */
		return 0;
	}

	if (arrayvar) {
		iTcl = Tcl_UnsetVar2(interp,
				     Tcl_GetStringFromObj(arrayvar, NULL),
				     (char *) NULL,
				     0);
	}

        /*
         * If PL/SQL, use bind_list else use col_list.
         */
	if (StmPtr->sqltype == OCI_STMT_BEGIN ||
	    StmPtr->sqltype == OCI_STMT_DECLARE) {
		ColPtr = StmPtr->bind_list;
	} else {
		ColPtr = StmPtr->col_list;
	}

	null_str = Tcl_GetStringFromObj(StmPtr->nullvalue, NULL);
	LogPtr = (OratclLogs *) Tcl_GetHashValue(StmPtr->logHashPtr);
	if (listvar) {
		lst_obj = Tcl_NewListObj(0, NULL);
	}

	/* 
	 * Check for a LOB column and allocate a buffer piece.
	 * The buffer piece can be used for multiple columns.
	 */
	for (col = ColPtr, idx = 1; col != NULL; col = col->next, idx++) {
		if (( col->dty == SQLT_BLOB ) || ( col->dty == SQLT_CLOB )) {
			pValue = ckalloc( StmPtr->lobpsize + 1 );
			if (pValue == NULL) {
				fprintf(stderr, "error:: pValue is NULL return -1\n");
				return -1;
			}
			pValue[0] = '\0';
			break;
		}
	}

	for (col = ColPtr, idx = 1; col != NULL; col = col->next, idx++) {

		Tcl_DStringInit(&uniStr);
		Tcl_DStringInit(&lobStr);

		/* for cursor type, just return a null */
		/* get pointer to next row column data buffer */

		if ((sb2) col->indp[rn] == -1) {
			if (col->column.typecode == SQLT_CUR) {
				tmp = "";
			} else {
				/* default :: if number "0" else "" */
				if (*null_str == 'd'
				   && strcmp(null_str,"default") == 0) {

					if (col->column.typecode == SQLT_NUM) {
						tmp = "0";
					} else {
						tmp = "";
					}
				} else {
					/* return user defined nullvalue */
					tmp = null_str;
				}
			}
		} else if (col->column.valuesz > 0) {

			/*
			 *  Read the LOB value
			 */

			if (( col->dty == SQLT_BLOB ) || ( col->dty == SQLT_CLOB )) {
				OCILobLocator** pLocator;
				ub4             nLength = 0;
				ub4             nAMTP;
				sword           nStatus;                    
				ub4             nOffset       = 1;

				pLocator = (OCILobLocator**)(col->column.valuep + (rn * col->column.valuesz));

				(void)OCI_LobGetLength( LogPtr->svchp,
							LogPtr->errhp,
							*pLocator,
							&nLength );

				if( nLength > 0 ) {

					nAMTP = nLength;

					do{

						nStatus = OCI_LobRead(LogPtr->svchp,
								      LogPtr->errhp,
								      *pLocator,
								      &nAMTP,
								      (ub4)nOffset,
								      (dvoid*)(pValue),
								      StmPtr->lobpsize,
								      (dvoid *)0,
								      (sb4 (*)(dvoid *, CONST dvoid *, ub4, ub1)) 0,
								      (ub2) 0,
								      (ub1) SQLCS_IMPLICIT);

						if( ( nStatus != OCI_SUCCESS ) && ( nStatus != OCI_NEED_DATA ) ) {
							fprintf(stderr, "nStatus = %d\n", nStatus);
							fprintf(stderr, "error:: return -3\n");
							ckfree(pValue);
							Tcl_DStringFree(&lobStr);
							return -3;
						}

						if( nAMTP == 0 ) {
							fprintf(stderr, "error:: return -4\n");
							ckfree(pValue);
							Tcl_DStringFree(&lobStr);
							return -4;
						}


						Tcl_DStringAppend(&lobStr, pValue, nAMTP);

					} while ( nStatus == OCI_NEED_DATA );

					tmp = Tcl_DStringValue(&lobStr);

				} else {
					tmp = "";
				}                


			} else {
				if (StmPtr->unicode) {
					tmp = (char *) col->column.valuep + (col->column.valuesz +1 ) * sizeof(utext) * rn;
				} else {
					tmp = col->column.valuep + (rn * (col->column.valuesz+1));
				}
			}

			if (StmPtr->utfmode) {
				Tcl_ExternalToUtfDString(NULL,
							 tmp,
							 -1,
							 &uniStr);
				tmp = Tcl_DStringValue(&uniStr);
			}

		} else {
			tmp = "";
		}

		if (arrayvar) {

			if (StmPtr->unicode) {
				val_obj = Tcl_NewUnicodeObj((const Tcl_UniChar *) tmp, col->rlenp[rn]);
			} else {
				val_obj = Tcl_NewStringObj((char *) tmp, strlen(tmp));
			}
			Tcl_IncrRefCount(val_obj);

			if (hashType) {
				tmp_obj = Tcl_NewStringObj((char *) col->column.name,
							   (int) col->column.namesz);
			} else {
				tmp_obj = Tcl_NewIntObj(idx);
			}

			Tcl_IncrRefCount(tmp_obj);
			Tcl_ObjSetVar2(interp,
					arrayvar,
					tmp_obj,
					val_obj,
					TCL_LEAVE_ERR_MSG);
			Tcl_DecrRefCount(tmp_obj);

			Tcl_DecrRefCount(val_obj);
		}

		if (listvar) {
			if (StmPtr->unicode) {
				tmp_obj = Tcl_NewUnicodeObj((const Tcl_UniChar *) tmp, col->rlenp[rn]);
			} else {
				tmp_obj = Tcl_NewStringObj(tmp,strlen(tmp));
			}
			Tcl_IncrRefCount(tmp_obj);
			Tcl_ListObjAppendElement(interp,
						 lst_obj,
						 tmp_obj);
			Tcl_DecrRefCount(tmp_obj);
		}

		Tcl_DStringFree(&uniStr);
		Tcl_DStringFree(&lobStr);
	}

	if (listvar) {
		Tcl_ObjSetVar2(interp, listvar, NULL, lst_obj, 0);
	}

	if (pValue) {
		ckfree(pValue);
	}

	StmPtr->fetchidx += 1;
	StmPtr->append_cnt += 1;
	StmPtr->ora_rc = 0;
	StmPtr->ora_row = StmPtr->append_cnt;
	Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
	return 0;
}


/*
 *----------------------------------------------------------------------
 * Oratcl_ColDescribe
 *   parse result columns, allocate memory for fetches
 *   return -1 on error, 1 if ok
 *----------------------------------------------------------------------
 */

int
Oratcl_ColDescribe (interp, StmPtr)
	Tcl_Interp 	*interp;
	OratclStms	*StmPtr;
{
	OratclLogs	*LogPtr;

	sword		rc;
	ub2		myucs2id = OCI_UCS2ID;
	sb4		mybindmax = 0;

	OratclCols	*new_col_head;
	OratclCols	*new_col;
	OratclCols	*last_col;

	OCIParam	*parmdp;
	ub4		parmcnt;
	ub4		parmix;

	LogPtr = (OratclLogs *) Tcl_GetHashValue(StmPtr->logHashPtr);

	/* get the parameter count info */
	parmcnt = 0;
	rc = OCI_AttrGet( (dvoid *) StmPtr->stmhp,
			 (ub4) OCI_HTYPE_STMT,
			 (ub4 *) &parmcnt,
			 (ub4) 0,
			 OCI_ATTR_PARAM_COUNT,
			 LogPtr->errhp);

	Oratcl_Checkerr(interp,
			LogPtr->errhp,
			rc,
			1,
			&StmPtr->ora_rc,
			&StmPtr->ora_err);

	if (rc != OCI_SUCCESS) {
		return -1;
	}

	new_col_head = Oratcl_ColAlloc(StmPtr->fetchrows);
	if (new_col_head == NULL) {
		return -1;
	}
	new_col      = new_col_head;
	last_col     = new_col_head;

	for (parmix = 1; parmix <= parmcnt; parmix++) {

		rc = OCI_ParamGet((dvoid *) StmPtr->stmhp,
				  (ub4) OCI_HTYPE_STMT,
				  (OCIError *) LogPtr->errhp,
				  (dvoid *) &parmdp,
				  (ub4) parmix);

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (rc != OCI_SUCCESS) {
			Oratcl_ColFree(new_col_head);
			return -1;
		}

		rc = Oratcl_Attributes(interp,
				       LogPtr->errhp,
				       parmdp,
				       &new_col->column,
				       0);
		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);
		if (rc != OCI_SUCCESS) {
			Oratcl_ColFree(new_col_head);
			return -1;
		}

		new_col->dty = SQLT_STR;
		new_col->column.valuesz = new_col->column.size;
		
		switch (new_col->column.typecode) {
		case SQLT_CHR:					/* 1	*/
		case SQLT_CUR:					/* 102	*/
			break;
		case SQLT_LNG:					/* 8	*/
		case SQLT_LBI:					/* 24	*/
			new_col->column.valuesz = StmPtr->longsize;
			break;
		case SQLT_BIN:					/* 23	*/
			new_col->column.valuesz = new_col->column.size * 2;
			break;
		case SQLT_NUM:					/* 2	*/
			new_col->column.valuesz = StmPtr->numbsize;
			break;
		case SQLT_DAT:					/* 12	*/
			new_col->column.valuesz = StmPtr->datesize;
			break;
		case SQLT_RID:					/* 11	*/
		case SQLT_RDD:					/* 104	*/
			new_col->column.valuesz = 140;
			break;
		case SQLT_TIMESTAMP:				/* 187	*/
		case SQLT_TIMESTAMP_TZ:				/* 188  */
		case SQLT_INTERVAL_YM:				/* 189  */
		case SQLT_INTERVAL_DS:				/* 190  */
		case SQLT_TIMESTAMP_LTZ:			/* 232  */
			new_col->column.valuesz = 75;
			break;
		case SQLT_CLOB:                                 /* 112  */
		case SQLT_BLOB:                                 /* 113  */
			new_col->column.valuesz = sizeof(OCILobLocator*);
			new_col->dty = new_col->column.typecode;
			break;
		default:
			/* Should not be reached */
			break;
		}

		StmPtr->fetchmem = StmPtr->fetchrows;

		if ( ( new_col->dty == SQLT_BLOB ) || (new_col->dty == SQLT_CLOB ) ) {
			
			int nRow;
			char *pLocators;
			pLocators = ckalloc (new_col->column.valuesz * StmPtr->fetchrows);
			if (pLocators == NULL) {
				fprintf(stderr, "error:: pLocators is NULL return -1\n");
				return -1;
			}
			for (nRow = 0; nRow < StmPtr->fetchrows; nRow++ ) {
				OCILobLocator **pLocator;
				pLocator = (OCILobLocator**)(pLocators + nRow * new_col->column.valuesz);
				rc = OCI_DescriptorAlloc( (dvoid *)LogPtr->envhp,
							 (dvoid **)pLocator,
							 (ub4)OCI_DTYPE_LOB,
							 (size_t) 0,
							 (dvoid **) 0 );

				Oratcl_Checkerr(interp,
						LogPtr->errhp,
						rc,
						1,
						&StmPtr->ora_rc,
						&StmPtr->ora_err);

				if (rc != OCI_SUCCESS) {
					Oratcl_ColFree(new_col_head);
					return -1;
				}

			}

			new_col->column.valuep = pLocators;
			rc = OCI_DefineByPos(StmPtr->stmhp,
					     &new_col->defnp,
					     LogPtr->errhp,
					     (ub4) parmix,
					     (dvoid *) new_col->column.valuep,
					     (sb4) 0,
					     new_col->dty,
					     (sb2 *) new_col->indp,
					     (ub2 *) new_col->rlenp,
					     (ub2 *) new_col->rcodep,
					     (ub4) OCI_DEFAULT);

		} else {

			if (StmPtr->unicode) {
				mybindmax = (new_col->column.valuesz +1) * sizeof(utext);
				new_col->column.valuep = ckalloc (mybindmax * StmPtr->fetchrows);
			} else {
				mybindmax = new_col->column.valuesz + 1;
				new_col->column.valuep = ckalloc (mybindmax * StmPtr->fetchrows);
			}

			if (new_col->column.valuep == NULL) {
				fprintf(stderr, "error:: new_col->column.valuep is NULL return -1\n");
				return -1;
			}

			rc = OCI_DefineByPos(StmPtr->stmhp,
					     &new_col->defnp,
					     LogPtr->errhp,
					     (ub4) parmix,
					     (dvoid *) new_col->column.valuep,
					     (sb4) mybindmax,
					     new_col->dty,
					     (sb2 *) new_col->indp,
					     (ub2 *) new_col->rlenp,
					     (ub2 *) new_col->rcodep,
					     (ub4) OCI_DEFAULT);

			/* if unicode, we must set the character set attribute */
			if (rc == OCI_SUCCESS && StmPtr->unicode) {
				OCI_AttrSet((dvoid *) new_col->defnp,
					    OCI_HTYPE_DEFINE,
					    &myucs2id,
					    0,
					    OCI_ATTR_CHARSET_ID,
					    LogPtr->errhp);
			}

		}

		Oratcl_Checkerr(interp,
				LogPtr->errhp,
				rc,
				1,
				&StmPtr->ora_rc,
				&StmPtr->ora_err);

		if (rc != OCI_SUCCESS) {
			Oratcl_ColFree(new_col_head);
			return -1;
		}

		last_col = new_col;
		new_col = Oratcl_ColAlloc(StmPtr->fetchrows);
		if (new_col == NULL) {
			Oratcl_ColFree(new_col_head);
			return -1;
		}
		last_col->next = new_col;

	}

	last_col->next = NULL;
	Oratcl_ColFree(new_col);
	Oratcl_ColFree(StmPtr->col_list);
	StmPtr->col_list = new_col_head;

	return (parmcnt);
}


/*
 *----------------------------------------------------------------------
 * Oratcl_Cols --
 *    Implements the oracols command:
 *    usage: oracols stm_handle
 *
 *    results:
 *	latest column names as tcl list
 *      TCL_OK - handle is opened
 *      TCL_ERROR - wrong # args, or handle not opened,
 *----------------------------------------------------------------------
 */

int
Oratcl_Cols (clientData, interp, objc, objv)
	ClientData	clientData;
	Tcl_Interp	*interp;
	int		objc;
	Tcl_Obj		*CONST objv[];
{
	OratclState	*OratclStatePtr = (OratclState *) clientData;
	Tcl_HashEntry	*stmHashPtr;
	OratclStms	*StmPtr;

	int		mode = 1;

	OratclCols	*ColPtr;
	OratclCols	*col;
	int		oColsc;
	Tcl_Obj		**oCols = NULL;
	int		oColslen = 6;
	Tcl_Obj		*oResult;

	static CONST84 char *options[] = {"all",
				   "name",
				   "size",
				   "type",
				   "precision",
				   "scale",
				   "nullok",
				   NULL};

	enum		optindex {OPT_ALL,
				  OPT_NAME,
				  OPT_SIZE,
				  OPT_TYPE,
				  OPT_PREC,
				  OPT_SCALE,
				  OPT_NULLOK};

	int		tcl_return = TCL_OK;

	if (objc == 1 || objc > 3 ) {
		Tcl_WrongNumArgs(interp, objc, objv, "stm_handle ?-option?");
		tcl_return = TCL_ERROR;
		goto common_exit;
	}

	if (objc == 3) {
		if (Tcl_GetIndexFromObj(interp,
					objv[2],
					(CONST84 char **)options,
					"option",
					0,
					&mode)) {
			tcl_return = TCL_ERROR;
			goto common_exit;
		}
	}

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

	oResult = Tcl_GetObjResult(interp);
	oCols = (Tcl_Obj **) ckalloc (oColslen * sizeof(*oCols));

        /*
         * If PL/SQL, use bind_list else use col_list.
         */
        if (StmPtr->sqltype == OCI_STMT_BEGIN ||
            StmPtr->sqltype == OCI_STMT_DECLARE) {
		ColPtr = StmPtr->bind_list;
	} else {
		ColPtr = StmPtr->col_list;
	}

	for (col = ColPtr; col != NULL; col = col->next) {

		oColsc = 0;
		if (mode == OPT_ALL || mode == OPT_NAME) {
			oCols[oColsc++] = Tcl_NewStringObj((char *) col->column.name, -1);
		}
		if (mode == OPT_ALL || mode == OPT_SIZE) {
			oCols[oColsc++] = Tcl_NewIntObj(col->column.size);
		}

		if (mode == OPT_ALL || mode == OPT_TYPE) {
			oCols[oColsc++] = Tcl_NewStringObj(Tcl_DStringValue(&col->column.typename),
							   Tcl_DStringLength(&col->column.typename));
		}

		if (mode == OPT_ALL || mode == OPT_PREC) {
			if (col->column.typecode == 2) {
				oCols[oColsc++] = Tcl_NewIntObj(col->column.prec);
			} else {
				oCols[oColsc++] = Tcl_NewStringObj("",   -1);;
			}
		}

		if (mode == OPT_ALL || mode == OPT_SCALE) {
			if (col->column.typecode == 2) {
				oCols[oColsc++] = Tcl_NewIntObj(col->column.scale);
			} else {
				oCols[oColsc++] = Tcl_NewStringObj("",   -1);;
			}
		}

		if (mode == OPT_ALL || mode == OPT_NULLOK) {
			oCols[oColsc++] = Tcl_NewIntObj(col->column.nullok);
		}

		if (mode == OPT_ALL) {
			Tcl_ListObjAppendElement(interp, oResult, Tcl_NewListObj(oColslen, oCols));
		} else {
			Tcl_ListObjAppendElement(interp, oResult, oCols[0]);
		}
	}

common_exit:

	if (oCols)
		ckfree((char *) oCols);

	return tcl_return;
}


sword
Oratcl_Attributes (interp, errhp, parmh, column, explicit)
	Tcl_Interp	*interp;
	OCIError	*errhp;
	OCIParam	*parmh;
	OratclDesc	*column;
	int		explicit;
{
	text		*namep;
	ub4		namesz;
	sword		rc;
	ub1		prec_ub1;	
	sb2		prec_sb2;	

	/* column name */
	rc = OCI_AttrGet((dvoid*) parmh,
			(ub4) OCI_DTYPE_PARAM,
			(dvoid*) &namep,
			(ub4 *) &column->namesz,
			(ub4) OCI_ATTR_NAME,
			(OCIError *) errhp);

	if (rc != OCI_SUCCESS) {
		return rc;
	}

	column->name = (text *) ckalloc ((size_t) column->namesz + 1);
	memcpy(column->name, namep, (size_t) column->namesz);
	column->name[column->namesz] = '\0';

	/* column length */
	rc = OCI_AttrGet((dvoid*) parmh,
			(ub4) OCI_DTYPE_PARAM,
			(dvoid*) &column->size,
			(ub4 *) 0,
			(ub4) OCI_ATTR_DATA_SIZE,
			(OCIError *) errhp);

	if (rc != OCI_SUCCESS) {
		return rc;
	}

	/* data type code */
	rc = OCI_AttrGet((dvoid*) parmh,
			(ub4) OCI_DTYPE_PARAM,
			(dvoid*) &column->typecode,
			(ub4 *) 0,
			(ub4) OCI_ATTR_DATA_TYPE,
			(OCIError *) errhp);

	if (rc != OCI_SUCCESS) {
		return rc;
	}

	/* precision */
	if (explicit) {
		rc = OCI_AttrGet((dvoid*) parmh,
				(ub4) OCI_DTYPE_PARAM,
				(dvoid*) &prec_ub1,
				(ub4 *) 0,
				(ub4) OCI_ATTR_PRECISION,
				(OCIError *) errhp);

		if (rc != OCI_SUCCESS) {
			return rc;
		}
		column->prec = prec_ub1;
	} else {
		rc = OCI_AttrGet((dvoid*) parmh,
				(ub4) OCI_DTYPE_PARAM,
				(dvoid*) &prec_sb2,
				(ub4 *) 0,
				(ub4) OCI_ATTR_PRECISION,
				(OCIError *) errhp);

		if (rc != OCI_SUCCESS) {
			return rc;
		}

		column->prec = prec_sb2;
	}

	/* scale */
	rc = OCI_AttrGet((dvoid*) parmh,
			(ub4) OCI_DTYPE_PARAM,
			(dvoid*) &column->scale,
			(ub4 *) 0,
			(ub4) OCI_ATTR_SCALE,
			(OCIError *) errhp);

	if (rc != OCI_SUCCESS) {
		return rc;
	}

	/* null allowed */
	rc = OCI_AttrGet( (dvoid*) parmh,
			 (ub4) OCI_DTYPE_PARAM,
			 (ub1 *) &column->nullok,
			 (ub4 *) 0,
			 (ub4) OCI_ATTR_IS_NULL,
			 (OCIError *) errhp);

	if (rc != OCI_SUCCESS) {
		return rc;
	}

	/* data type name */
	switch (column->typecode) {
	case SQLT_CHR:					/* 1	*/
		Tcl_DStringAppend(&column->typename, "VARCHAR2", -1);
		break;
	case SQLT_AFC:					/* 96	*/
		Tcl_DStringAppend(&column->typename, "CHAR", -1);
		break;
	case SQLT_LNG:					/* 8	*/
		Tcl_DStringAppend(&column->typename, "LONG", -1);
		break;
	case SQLT_BIN:					/* 23	*/
		Tcl_DStringAppend(&column->typename, "RAW", -1);
		break;
	case SQLT_LBI:					/* 24	*/
		Tcl_DStringAppend(&column->typename, "LONG RAW", -1);
		break;
	case SQLT_NUM:					/* 2	*/
		Tcl_DStringAppend(&column->typename, "NUMBER", -1);
		break;
	case SQLT_IBFLOAT:				/* 100	*/
		Tcl_DStringAppend(&column->typename, "BINARY_FLOAT", -1);
		break;
	case SQLT_IBDOUBLE:				/* 101	*/
		Tcl_DStringAppend(&column->typename, "BINARY_DOUBLE", -1);
		break;
	case SQLT_DAT:					/* 12	*/
		Tcl_DStringAppend(&column->typename, "DATE", -1);
		break;
	case SQLT_RID:					/* 11	*/
	case SQLT_RDD:					/* 104	*/
		Tcl_DStringAppend(&column->typename, "ROWID", -1);
		break;
	case SQLT_CUR:					/* 102	*/
		Tcl_DStringAppend(&column->typename, "CURSOR", -1);
		break;
	case SQLT_CLOB:
		Tcl_DStringAppend(&column->typename, "CLOB", -1);
		break;
	case SQLT_BLOB:
		Tcl_DStringAppend(&column->typename, "BLOB", -1);
		break;
	case 105:
		Tcl_DStringAppend(&column->typename, "MSLABEL", -1);
		break;
	case 106:
		Tcl_DStringAppend(&column->typename, "RAW MSLABEL", -1);
		break;
	case SQLT_TIMESTAMP:
		Tcl_DStringAppend(&column->typename, "TIMESTAMP", -1);
		break;
	case SQLT_TIMESTAMP_TZ:
		Tcl_DStringAppend(&column->typename, "TIMESTAMP WITH TIME ZONE", -1);
		break;
	case SQLT_INTERVAL_YM:
		Tcl_DStringAppend(&column->typename, "INTERVAL YEAR TO MONTH", -1);
		break;
	case SQLT_INTERVAL_DS:
		Tcl_DStringAppend(&column->typename, "INTERVAL DAY TO SECOND", -1);
		break;
	case SQLT_TIMESTAMP_LTZ:
		Tcl_DStringAppend(&column->typename, "TIMESTAMP WITH LOCAL TIME ZONE", -1);
		break;
	case SQLT_NTY:
		/* named type - get the name */
		rc = OCI_AttrGet((dvoid*) parmh,
				(ub4) OCI_DTYPE_PARAM,
				(dvoid*) &namep,
				(ub4 *) &namesz,
				(ub4) OCI_ATTR_TYPE_NAME,
				(OCIError *) errhp);
		if (rc != OCI_SUCCESS) {
			return rc;
		}
		Tcl_DStringAppend(&column->typename, (char *)namep, namesz);
		break;
	default:
		Tcl_DStringAppend(&column->typename, "UNKNOWN", -1);
	}

	return rc;
}

/* finis */
