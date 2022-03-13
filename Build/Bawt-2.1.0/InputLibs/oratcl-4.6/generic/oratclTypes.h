/*
 * oratclTypes.h
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

typedef sword (*OCIENVCREATE)	(OCIEnv **envp,
				 ub4 mode,
				 dvoid *ctxp,
				 dvoid *(*malocfp)(dvoid *ctxp, size_t size),
				 dvoid *(*ralocfp)(dvoid *ctxp, dvoid *memptr, size_t newsize),
				 void (*mfreefp)(dvoid *ctxp, dvoid *memptr),
				 size_t xtramem_sz,
				 dvoid **usrmempp);
extern OCIENVCREATE	OCI_EnvCreate;

typedef	sword (*OCIINITIALIZE)	(ub4 mode,
				 dvoid *ctxp,
				 dvoid *(*malocfp) (dvoid *ctxp, size_t size),
				 dvoid *(*ralocfp) (dvoid *ctxp, dvoid *memp, size_t newsize),
				 void (*mfreefp) (dvoid *ctxp, dvoid *memptr));
extern OCIINITIALIZE	OCI_Initialize;

typedef sword (*OCIENVINIT)	(OCIEnv **envp,
				 ub4 mode,
				 size_t xtramemsz,
				 dvoid **usrmempp);
extern OCIENVINIT	OCI_EnvInit;

typedef sword (*OCIHANDLEALLOC)	(CONST dvoid *parenth,
				 dvoid **hndlpp,
				 CONST ub4 type,
				 CONST size_t xtramem_sz,
				 dvoid **usrmempp); 
extern OCIHANDLEALLOC	OCI_HandleAlloc;

typedef sword (*OCIHANDLEFREE)	(dvoid *hndlp, CONST ub4 type); 
extern OCIHANDLEFREE	OCI_HandleFree;

typedef sword  (*OCIDESCRIPTORALLOC) (CONST dvoid *parenth,
				      dvoid **descpp,
				      CONST ub4 type,
				      CONST size_t xtramem_sz,
				      dvoid **usrmempp);
extern OCIDESCRIPTORALLOC OCI_DescriptorAlloc;

typedef sword (*OCIDESCRIPTORFREE) (dvoid *descp,
				    CONST ub4 type);
extern OCIDESCRIPTORFREE OCI_DescriptorFree;

typedef sword (*OCIATTRGET)	(dvoid *trgthndlp,
				 ub4 trghndltyp,
				 dvoid *attributep,
				 ub4 *sizep,
				 ub4 attrtype,
				 OCIError *errhp);
extern OCIATTRGET	OCI_AttrGet;

typedef sword (*OCIATTRSET)	(dvoid *trgthndlp,
				 ub4 trghndltyp,
				 dvoid *attributep,
				 ub4 size,
				 ub4 attrtype,
				 OCIError *errhp ); 
extern OCIATTRSET	OCI_AttrSet;

typedef sword (*OCISERVERATTACH) (OCIServer *srvhp,
				  OCIError *errhp,
				  CONST OraText *dblink,
				  sb4 dblink_len,
				  ub4 mode); 
extern OCISERVERATTACH	OCI_ServerAttach;

typedef sword (*OCISERVERDETACH) (OCIServer *srvhp,
				  OCIError *errhp,
				  ub4 mode); 
extern OCISERVERDETACH	OCI_ServerDetach;

typedef sword (*OCISESSIONBEGIN) (OCISvcCtx *svchp,
				  OCIError *errhp,
				  OCISession *usrhp,
				  ub4 credt,
				  ub4 mode); 
extern OCISESSIONBEGIN	OCI_SessionBegin;

typedef sword (*OCISESSIONEND)	(OCISvcCtx *svchp,
				 OCIError *errhp,
				 OCISession *usrhp,
				 ub4 mode); 
extern OCISESSIONEND	OCI_SessionEnd;

typedef sword (*OCIERRORGET)	(dvoid *hndlp,
				 ub4 recordno,
				 OraText *sqlstate,
				 sb4 *errcodep,
				 OraText *bufp,
				 ub4 bufsiz,
				 ub4 type); 
extern OCIERRORGET	OCI_ErrorGet;

typedef sword (*OCITRANSCOMMIT) (OCISvcCtx *svchp,
				 OCIError *errhp,
				 ub4 flags);
extern OCITRANSCOMMIT OCI_TransCommit;

typedef sword (*OCITRANSROLLBACK) (dvoid *svchp,
				  OCIError *errhp,
				  ub4 flags);

extern OCITRANSROLLBACK OCI_TransRollback;

typedef sword (*OCITERMINATE)	(ub4 mode);
extern OCITERMINATE	OCI_Terminate;

typedef	sword (*OCISERVERVERSION) (dvoid *hndlp,
				   OCIError *errhp,
				   OraText *bufp,
				   ub4 bufsz,
				   ub1 hndltype);
extern OCISERVERVERSION OCI_ServerVersion;

typedef	sword (*OCISERVERRELEASE) (dvoid *hndlp,
				   OCIError *errhp,
				   OraText *bufp,
				   ub4 bufsz,
				   ub1 hndltype,
				   ub4 *version);
extern OCISERVERRELEASE OCI_ServerRelease;

typedef	sword (*OCICLIENTVERSION) (sword *major_version,
				   sword *minor_version,
				   sword *update_num,
				   sword *patch_num,
				   sword *port_update_num);
extern OCICLIENTVERSION OCI_ClientVersion;

typedef sword (*OCISTMTPREPARE)	(OCIStmt *stmtp,
				 OCIError *errhp,
				 CONST OraText *stmt,
				 ub4 stmt_len,
				 ub4 language,
				 ub4 mode);
extern OCISTMTPREPARE	OCI_StmtPrepare;

typedef sword (*OCISTMTGETPIECEINFO) (OCIStmt *stmtp,
				      OCIError *errhp,
				      dvoid **hndlpp,
				      ub4 *typep,
				      ub1 *in_outp,
				      ub4 *iterp,
				      ub4 *idxp,
				      ub1 *piecep);
extern OCISTMTGETPIECEINFO	OCI_StmtGetPieceInfo;

typedef sword (*OCISTMTSETPIECEINFO) (dvoid *hndlp,
				      ub4 type, OCIError *errhp,
				      CONST dvoid *bufp,
				      ub4 *alenp,
				      ub1 piece,
				      CONST dvoid *indp,
				      ub2 *rcodep);
extern OCISTMTSETPIECEINFO	OCI_StmtSetPieceInfo;

typedef sword (*OCISTMTEXECUTE)	(OCISvcCtx *svchp,
				 OCIStmt *stmtp,
				 OCIError *errhp,
				 ub4 iters,
				 ub4 rowoff,
				 CONST OCISnapshot *snap_in,
				 OCISnapshot *snap_out,
				 ub4 mode);
extern OCISTMTEXECUTE	OCI_StmtExecute;

typedef sword (*OCISTMTFETCH)	(OCIStmt *stmtp,
				 OCIError *errhp,
				 ub4 nrows,
				 ub2 orientation,
				 ub4 mode);
extern OCISTMTFETCH	OCI_StmtFetch;


typedef sword (*OCIDESCRIBEANY)	(OCISvcCtx *svchp,
				 OCIError *errhp,
				 dvoid *objptr,
				 ub4 objnm_len,
				 ub1 objptr_typ,
				 ub1 info_level,
				 ub1 objtyp,
				 OCIDescribe *dschp);
extern OCIDESCRIBEANY	OCI_DescribeAny;


typedef sword (*OCIPARAMGET)	(dvoid *hndlp,
				 ub4 htype,
				 OCIError *errhp,
				 dvoid **parmdpp,
				 ub4 pos);
extern OCIPARAMGET	OCI_ParamGet;

typedef sword (*OCIPARAMSET)	(dvoid *hdlp,
				 ub4 htyp,
				 OCIError *errhp,
				 CONST dvoid *dscp,
				 ub4 dtyp,
				 ub4 pos);
extern OCIPARAMSET	OCI_ParamSet;

typedef sword (*OCIBREAK)	(dvoid *hndlp, OCIError *errhp);
extern OCIBREAK	OCI_Break;

typedef sword (*OCIRESET)	(dvoid *hndlp, OCIError *errhp);
extern OCIRESET	OCI_Reset;

typedef	sword (*OCIDEFINEBYPOS)	(OCIStmt *stmtp,
				 OCIDefine **defnp,
				 OCIError *errhp,
				 ub4 position,
				 dvoid *valuep,
				 sb4 value_sz,
				 ub2 dty,
				 dvoid *indp,
				 ub2 *rlenp,
				 ub2 *rcodep,
				 ub4 mode);
extern OCIDEFINEBYPOS	OCI_DefineByPos;

typedef sword (*OCIBINDBYNAME)	(OCIStmt *stmtp,
				 OCIBind **bindp,
				 OCIError *errhp,
				 CONST OraText *placeholder,
				 sb4 placeh_len,
				 dvoid *valuep,
				 sb4 value_sz,
				 ub2 dty,
				 dvoid *indp,
				 ub2 *alenp,
				 ub2 *rcodep,
				 ub4 maxarr_len,
				 ub4 *curelep,
				 ub4 mode);
extern OCIBINDBYNAME	OCI_BindByName;

typedef sword (*OCILOBREAD) (OCISvcCtx *svchp,
			     OCIError *errhp,
			     OCILobLocator *locp,
                             ub4 *amtp,
			     ub4 offset,
			     dvoid *bufp,
			     ub4 bufl,
                             dvoid *ctxp,
			     sb4 (*cbfp)(dvoid *ctxp,
					 CONST dvoid *bufp,
					 ub4 len,
					 ub1 piece),
			     ub2 csid,
			     ub1 csfrm);
extern OCILOBREAD OCI_LobRead;

typedef sword (*OCILOBGETLENGTH) (OCISvcCtx *svchp,
				  OCIError *errhp,
				  OCILobLocator *locp,
				  ub4 *lenp);
extern OCILOBGETLENGTH OCI_LobGetLength;

typedef sb4 (*OCICallbackInBind)(void *ictxp,
				 OCIBind *bindp,
				 ub4 iter,
                                 ub4 index,
				 void  **bufpp,
				 ub4 *alenp,
                                 ub1 *piecep,
				 void  **indp);

typedef sb4 (*OCICallbackOutBind)(void *octxp,
				  OCIBind *bindp,
				  ub4 iter,
                                  ub4 index,
				  void  **bufpp,
				  ub4 **alenp,
                                  ub1 *piecep,
				  void  **indp,
                                  ub2 **rcodep);

typedef sword (*OCIBINDDYNAMIC) (OCIBind     *bindp,
				 OCIError    *errhp,
				 void       *ictxp, 
				 OCICallbackInBind  icbfp,
				 void       *octxp,
				 OCICallbackOutBind ocbfp);
extern OCIBINDDYNAMIC OCI_BindDynamic;

typedef sword (*OCINLSGETINFO)  (dvoid *hndlp,
				 OCIError *errhp,
				 OraText *buf,
                    	         size_t buflen,
				 ub2 item);
extern OCINLSGETINFO	OCI_NlsGetInfo;

typedef sword (*OCINLSNUMERICINFOGET) (dvoid *hndl, 
                                       OCIError *errhp, 
                                       sb4 *val, 
                                       ub2 item);
extern OCINLSNUMERICINFOGET	OCI_NlsNumericInfoGet;
