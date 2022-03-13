/*
 * oradefs.h
 *
 * Oracle interface to Tcl
 *
 * Copyright 2017 Todd M. Helfter
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef _ORADEFS_H
#define _ORADEFS_H


/* OCI Error Codes */
#define OCI_SUCCESS		0
#define OCI_SUCCESS_WITH_INFO	1
#define OCI_NO_DATA		100
#define OCI_ERROR		-1
#define OCI_INVALID_HANDLE	-2
#define OCI_NEED_DATA		99
#define OCI_STILL_EXECUTING	-3123
#define OCI_CONTINUE		-24200

/* OCI Error Codes Strings */
#define STR_OCI_SUCCESS			"0"
#define STR_OCI_SUCCESS_WITH_INFO	"1"
#define STR_OCI_NEED_DATA		"99"
#define STR_OCI_NO_DATA			"100"
#define STR_OCI_ERROR			"-1"
#define STR_OCI_INVALID_HANDLE		"-2"
#define STR_OCI_STILL_EXECUTING		"-3123"

#define OCI_ATTR_ROW_COUNT	9

/* OCI Statement Types */

#define  OCI_STMT_SELECT  1   /* select statement */
#define  OCI_STMT_UPDATE  2   /* update statement */
#define  OCI_STMT_DELETE  3   /* delete statement */
#define  OCI_STMT_INSERT  4   /* Insert Statement */
#define  OCI_STMT_CREATE  5   /* create statement */
#define  OCI_STMT_DROP    6   /* drop statement */
#define  OCI_STMT_ALTER   7   /* alter statement */
#define  OCI_STMT_BEGIN   8   /* begin ... (pl/sql statement)*/
#define  OCI_STMT_DECLARE 9   /* declare .. (pl/sql statement ) */
#define  OCI_STMT_MERGE   16  /* merge statement (see Oracle bug #4879692) */


/*-------------------------Credential Types----------------------------------*/
#define OCI_CRED_RDBMS      1                  /* database username/password */
#define OCI_CRED_EXT        2             /* externally provided credentials */
#define OCI_CRED_PROXY      3                        /* proxy authentication */
#define OCI_CRED_RESERVED_1 4                                    /* reserved */
/*---------------------------------------------------------------------------*/


/* Fetching Constants */

#define OCI_FETCH_CURRENT	0x01
#define OCI_FETCH_NEXT		0x02
#define OCI_FETCH_FIRST		0x04
#define OCI_FETCH_LAST		0x08
#define OCI_FETCH_PRIOR		0x10
#define OCI_FETCH_ABSOLUTE	0x20
#define OCI_FETCH_RELATIVE	0x40
#define OCI_FETCH_RESERVED_1	0x80


/* Handle Types */
#define OCI_HTYPE_FIRST			1
#define OCI_HTYPE_ENV			1
#define OCI_HTYPE_ERROR			2
#define OCI_HTYPE_SVCCTX		3
#define OCI_HTYPE_STMT			4
#define OCI_HTYPE_BIND			5
#define OCI_HTYPE_DEFINE		6
#define OCI_HTYPE_DESCRIBE		7
#define OCI_HTYPE_SERVER		8
#define OCI_HTYPE_SESSION		9
#define OCI_HTYPE_AUTHINFO		OCI_HTYPE_SESSION
#define OCI_HTYPE_TRANS			10
#define OCI_HTYPE_COMPLEXOBJECT		11
#define OCI_HTYPE_SECURITY		12
#define OCI_HTYPE_SUBSCRIPTION		13
#define OCI_HTYPE_DIRPATH_CTX		14
#define OCI_HTYPE_DIRPATH_COLUMN_ARRAY	15
#define OCI_HTYPE_DIRPATH_STREAM	16
#define OCI_HTYPE_PROC			17
#define OCI_HTYPE_DIRPATH_FN_CTX	18
#define OCI_HTYPE_DIRPATH_FN_COL_ARRAY	19
#define OCI_HTYPE_XADSESSION		20
#define OCI_HTYPE_XADTABLE		21
#define OCI_HTYPE_XADFIELD		22
#define OCI_HTYPE_XADGRANULE		23
#define OCI_HTYPE_XADRECORD		24
#define OCI_HTYPE_XADIO			25
#define OCI_HTYPE_CPOOL			26
#define OCI_HTYPE_SPOOL			27
#define OCI_HTYPE_LAST			27


/* Handle Definitions */
typedef struct OCIEnv           OCIEnv;
typedef struct OCIError         OCIError;
typedef struct OCISvcCtx        OCISvcCtx;
typedef struct OCIStmt          OCIStmt;
typedef struct OCIBind          OCIBind;
typedef struct OCIDefine        OCIDefine;
typedef struct OCIDescribe      OCIDescribe;
typedef struct OCIServer        OCIServer;
typedef struct OCISession       OCISession;
typedef struct OCIComplexObject OCIComplexObject;
typedef struct OCITrans         OCITrans;
typedef struct OCISecurity      OCISecurity;
typedef struct OCISubscription  OCISubscription;
typedef struct OCICPool         OCICPool;
typedef struct OCISPool         OCISPool;
typedef struct OCIAuthInfo      OCIAuthInfo;


/* Descriptor Types */
#define OCI_DTYPE_FIRST			50
#define OCI_DTYPE_LOB			50
#define OCI_DTYPE_SNAP			51
#define OCI_DTYPE_RSET			52
#define OCI_DTYPE_PARAM			53
#define OCI_DTYPE_ROWID			54
#define OCI_DTYPE_COMPLEXOBJECTCOMP	55
#define OCI_DTYPE_FILE			56
#define OCI_DTYPE_AQENQ_OPTIONS		57
#define OCI_DTYPE_AQDEQ_OPTIONS		58
#define OCI_DTYPE_AQMSG_PROPERTIES	59
#define OCI_DTYPE_AQAGENT		60
#define OCI_DTYPE_LOCATOR		61
#define OCI_DTYPE_INTERVAL_YM		62
#define OCI_DTYPE_INTERVAL_DS		63
#define OCI_DTYPE_AQNFY_DESCRIPTOR	 64
#define OCI_DTYPE_DATE			65
#define OCI_DTYPE_TIME			66
#define OCI_DTYPE_TIME_TZ		67
#define OCI_DTYPE_TIMESTAMP		68
#define OCI_DTYPE_TIMESTAMP_TZ		69
#define OCI_DTYPE_TIMESTAMP_LTZ		70
#define OCI_DTYPE_UCB			71
#define OCI_DTYPE_SRVDN			72
#define OCI_DTYPE_SIGNATURE		73
#define OCI_DTYPE_RESERVED_1		74
#define OCI_DTYPE_LAST			74


/* Descriptor Definitions */
typedef struct OCISnapshot      	OCISnapshot;
typedef struct OCIResult        	OCIResult;
typedef struct OCILobLocator    	OCILobLocator;
typedef struct OCIParam         	OCIParam;
typedef struct OCIComplexObjectComp	OCIComplexObjectComp;
typedef struct OCIRowid 		OCIRowid;
typedef struct OCIDateTime 		OCIDateTime;
typedef struct OCIInterval 		OCIInterval;
typedef struct OCIUcb           	OCIUcb;
typedef struct OCIServerDNs     	OCIServerDNs;


/* piecewise constants */
#define OCI_ONE_PIECE		0
#define OCI_FIRST_PIECE		1
#define OCI_NEXT_PIECE		2
#define OCI_LAST_PIECE		3


/* Input Data Tyupes */
#define SQLT_CHR		1
#define SQLT_NUM		2
#define SQLT_INT		3
#define SQLT_FLT		4
#define SQLT_STR		5
#define SQLT_VNU		6
#define SQLT_PDN		7
#define SQLT_LNG		8
#define SQLT_VCS		9
#define SQLT_NON		10
#define SQLT_RID		11
#define SQLT_DAT		12
#define SQLT_VBI		15
#define SQLT_BFLOAT		21
#define SQLT_BDOUBLE		22
#define SQLT_BIN		23
#define SQLT_LBI		24
#define SQLT_UIN		68
#define SQLT_SLS		91
#define SQLT_LVC		94
#define SQLT_LVB		95
#define SQLT_AFC		96
#define SQLT_AVC		97
#define SQLT_IBFLOAT		100
#define SQLT_IBDOUBLE		101
#define SQLT_CUR		102
#define SQLT_RDD		104
#define SQLT_LAB		105
#define SQLT_OSL		106
#define SQLT_NTY		108
#define SQLT_REF 		110
#define SQLT_CLOB		112
#define SQLT_BLOB		113
#define SQLT_BFILEE		114
#define SQLT_CFILEE		115
#define SQLT_RSET		116
#define SQLT_NCO		122
#define SQLT_VST		155
#define SQLT_ODT		156
#define SQLT_DATE		184
#define SQLT_TIME		185
#define SQLT_TIME_TZ		186
#define SQLT_TIMESTAMP		187
#define SQLT_TIMESTAMP_TZ	188
#define SQLT_INTERVAL_YM	189
#define SQLT_INTERVAL_DS	190
#define SQLT_TIMESTAMP_LTZ	232
#define SQLT_PNTY		241


/* Parsing Syntax Types */
#define OCI_NTV_SYNTAX 1
#define OCI_V7_SYNTAX 2
#define OCI_V8_SYNTAX 3


/*------------------------Bind and Define Options----------------------------*/
#define OCI_SB2_IND_PTR   0x01                                     /* unused */
#define OCI_DATA_AT_EXEC  0x02                       /* data at execute time */
#define OCI_DYNAMIC_FETCH 0x02                          /* fetch dynamically */
#define OCI_PIECEWISE     0x04                    /* piecewise DMLs or fetch */
#define OCI_DEFINE_RESERVED_1 0x08                               /* reserved */
#define OCI_BIND_RESERVED_2   0x10                               /* reserved */
#define OCI_DEFINE_RESERVED_2 0x20                               /* reserved */
/*---------------------------------------------------------------------------*/


/* Initialization Modes */
#define OCI_DEFAULT			0x00000000 
#define OCI_THREADED			0x00000001
#define OCI_OBJECT			0x00000002
#define OCI_EVENTS			0x00000004
#define OCI_RESERVED1			0x00000008
#define OCI_SHARED			0x00000010
#define OCI_RESERVED2			0x00000020
#define OCI_NO_UCB			0x00000040
#define OCI_NO_MUTEX			0x00000080
#define OCI_SHARED_EXT			0x00000100
#define OCI_CACHE			0x00000200
#define OCI_ALWAYS_BLOCKING		0x00000400
#define OCI_NO_CACHE			0x00000800
#define OCI_USE_LDAP			0x00001000
#define OCI_REG_LDAPONLY		0x00002000
#define OCI_UTF16			0x00004000
#define OCI_AFC_PAD_ON			0x00008000
#define OCI_ENVCR_RESERVED3		0x00010000
#define OCI_NEW_LENGTH_SEMANTICS	0x00020000
#define OCI_NO_MUTEX_STMT		0x00040000
#define OCI_MUTEX_ENV_ONLY		0x00080000
#define OCI_STM_RESERVED4		0x00100000


/* Statement States */
#define OCI_STMT_STATE_INITIALIZED	0x0001
#define OCI_STMT_STATE_EXECUTED		0x0002
#define OCI_STMT_STATE_END_OF_FETCH	0x0003


/*------------------------ Prepare Modes ------------------------------------*/
#define OCI_NO_SHARING        0x01      /* turn off statement handle sharing */
#define OCI_PREP_RESERVED_1   0x02                               /* reserved */
#define OCI_PREP_AFC_PAD_ON   0x04          /* turn on blank padding for AFC */
#define OCI_PREP_AFC_PAD_OFF  0x08         /* turn off blank padding for AFC */
/*---------------------------------------------------------------------------*/


/*----------------------- Execution Modes -----------------------------------*/
#define OCI_BATCH_MODE        0x01
#define OCI_EXACT_FETCH       0x02
#define OCI_KEEP_FETCH_STATE  0x04
#define OCI_STMT_SCROLLABLE_READONLY 0x08
#define OCI_DESCRIBE_ONLY     0x10
#define OCI_COMMIT_ON_SUCCESS 0x20
#define OCI_NON_BLOCKING      0x40
#define OCI_BATCH_ERRORS      0x80
#define OCI_PARSE_ONLY        0x100
#define OCI_EXACT_FETCH_RESERVED_1 0x200
#define OCI_SHOW_DML_WARNINGS 0x400
#define OCI_EXEC_RESERVED_2   0x800
#define OCI_DESC_RESERVED_1   0x1000
/*---------------------------------------------------------------------------*/



/*------------------------Authentication Modes-------------------------------*/
#define OCI_MIGRATE         0x0001                /* migratable auth context */
#define OCI_SYSDBA          0x0002               /* for SYSDBA authorization */
#define OCI_SYSOPER         0x0004              /* for SYSOPER authorization */
#define OCI_PRELIM_AUTH     0x0008          /* for preliminary authorization */
#define OCIP_ICACHE         0x0010 /* Private OCI cache mode to notify cache */
#define OCI_AUTH_RESERVED_1 0x0020                               /* reserved */
#define OCI_STMT_CACHE      0x0040                /* enable OCI Stmt Caching */
#define OCI_SYSASM          0x00008000		 /* for SYSASM authorization */

/*---------------------------------------------------------------------------*/



/* Attribute Constants */

#define OCI_ATTR_FNCODE  1                          /* the OCI function code */
#define OCI_ATTR_OBJECT   2 /* is the environment initialized in object mode */
#define OCI_ATTR_NONBLOCKING_MODE  3                    /* non blocking mode */
#define OCI_ATTR_SQLCODE  4                                  /* the SQL verb */
#define OCI_ATTR_ENV  5                            /* the environment handle */
#define OCI_ATTR_SERVER 6                               /* the server handle */
#define OCI_ATTR_SESSION 7                        /* the user session handle */
#define OCI_ATTR_TRANS   8                         /* the transaction handle */
#define OCI_ATTR_ROW_COUNT   9                  /* the rows processed so far */
#define OCI_ATTR_SQLFNCODE 10               /* the SQL verb of the statement */
#define OCI_ATTR_PREFETCH_ROWS  11    /* sets the number of rows to prefetch */
#define OCI_ATTR_NESTED_PREFETCH_ROWS 12 /* the prefetch rows of nested table*/
#define OCI_ATTR_PREFETCH_MEMORY 13         /* memory limit for rows fetched */
#define OCI_ATTR_NESTED_PREFETCH_MEMORY 14   /* memory limit for nested rows */
#define OCI_ATTR_CHAR_COUNT  15 
                    /* this specifies the bind and define size in characters */
#define OCI_ATTR_PDSCL   16                          /* packed decimal scale */
#define OCI_ATTR_FSPRECISION OCI_ATTR_PDSCL   
                                          /* fs prec for datetime data types */
#define OCI_ATTR_PDPRC   17                         /* packed decimal format */
#define OCI_ATTR_LFPRECISION OCI_ATTR_PDPRC 
                                          /* fs prec for datetime data types */
#define OCI_ATTR_PARAM_COUNT 18       /* number of column in the select list */
#define OCI_ATTR_ROWID   19                                     /* the rowid */
#define OCI_ATTR_CHARSET  20                      /* the character set value */
#define OCI_ATTR_NCHAR   21                                    /* NCHAR type */
#define OCI_ATTR_USERNAME 22                           /* username attribute */
#define OCI_ATTR_PASSWORD 23                           /* password attribute */
#define OCI_ATTR_STMT_TYPE   24                            /* statement type */
#define OCI_ATTR_INTERNAL_NAME   25             /* user friendly global name */
#define OCI_ATTR_EXTERNAL_NAME   26      /* the internal name for global txn */
#define OCI_ATTR_XID     27           /* XOPEN defined global transaction id */
#define OCI_ATTR_TRANS_LOCK 28                                            /* */
#define OCI_ATTR_TRANS_NAME 29    /* string to identify a global transaction */
#define OCI_ATTR_HEAPALLOC 30                /* memory allocated on the heap */
#define OCI_ATTR_CHARSET_ID 31                           /* Character Set ID */
#define OCI_ATTR_CHARSET_FORM 32                       /* Character Set Form */
#define OCI_ATTR_MAXDATA_SIZE 33       /* Maximumsize of data on the server  */
#define OCI_ATTR_CACHE_OPT_SIZE 34              /* object cache optimal size */
#define OCI_ATTR_CACHE_MAX_SIZE 35   /* object cache maximum size percentage */
#define OCI_ATTR_PINOPTION 		36
#define OCI_ATTR_ALLOC_DURATION		37
#define OCI_ATTR_PIN_DURATION 		38        
#define OCI_ATTR_FDO          		39
#define OCI_ATTR_POSTPROCESSING_CALLBACK 40
#define OCI_ATTR_POSTPROCESSING_CONTEXT 41
#define OCI_ATTR_ROWS_RETURNED		42
#define OCI_ATTR_FOCBK        		43
#define OCI_ATTR_IN_V8_MODE   		44
#define OCI_ATTR_LOBEMPTY     		45
#define OCI_ATTR_SESSLANG     		46
#define OCI_ATTR_VISIBILITY             47
#define OCI_ATTR_RELATIVE_MSGID         48
#define OCI_ATTR_SEQUENCE_DEVIATION     49
#define OCI_ATTR_CONSUMER_NAME          50
#define OCI_ATTR_DEQ_MODE               51
#define OCI_ATTR_NAVIGATION             52
#define OCI_ATTR_WAIT                   53
#define OCI_ATTR_DEQ_MSGID              54
#define OCI_ATTR_PRIORITY               55
#define OCI_ATTR_DELAY                  56
#define OCI_ATTR_EXPIRATION             57
#define OCI_ATTR_CORRELATION            58
#define OCI_ATTR_ATTEMPTS               59
#define OCI_ATTR_RECIPIENT_LIST         60
#define OCI_ATTR_EXCEPTION_QUEUE        61
#define OCI_ATTR_ENQ_TIME               62
#define OCI_ATTR_MSG_STATE              63
#define OCI_ATTR_AGENT_NAME             64
#define OCI_ATTR_AGENT_ADDRESS          65
#define OCI_ATTR_AGENT_PROTOCOL         66
#define OCI_ATTR_SENDER_ID              68
#define OCI_ATTR_ORIGINAL_MSGID         69
#define OCI_ATTR_QUEUE_NAME             70
#define OCI_ATTR_NFY_MSGID              71
#define OCI_ATTR_MSG_PROP               72
#define OCI_ATTR_NUM_DML_ERRORS         73
#define OCI_ATTR_DML_ROW_OFFSET         74
#define OCI_ATTR_DATEFORMAT             75
#define OCI_ATTR_BUF_ADDR               76
#define OCI_ATTR_BUF_SIZE               77
#define OCI_ATTR_DIRPATH_MODE           78
#define OCI_ATTR_DIRPATH_NOLOG          79
#define OCI_ATTR_DIRPATH_PARALLEL       80
#define OCI_ATTR_NUM_ROWS               81
#define OCI_ATTR_COL_COUNT              82
#define OCI_ATTR_STREAM_OFFSET          83
#define OCI_ATTR_SHARED_HEAPALLOC       84
#define OCI_ATTR_SERVER_GROUP           85
#define OCI_ATTR_MIGSESSION             86
#define OCI_ATTR_NOCACHE                87
#define OCI_ATTR_MEMPOOL_SIZE           88
#define OCI_ATTR_MEMPOOL_INSTNAME       89
#define OCI_ATTR_MEMPOOL_APPNAME        90
#define OCI_ATTR_MEMPOOL_HOMENAME       91
#define OCI_ATTR_MEMPOOL_MODEL          92
#define OCI_ATTR_MODES                  93
#define OCI_ATTR_SUBSCR_NAME            94
#define OCI_ATTR_SUBSCR_CALLBACK        95
#define OCI_ATTR_SUBSCR_CTX             96
#define OCI_ATTR_SUBSCR_PAYLOAD         97
#define OCI_ATTR_SUBSCR_NAMESPACE       98
#define OCI_ATTR_PROXY_CREDENTIALS      99
#define OCI_ATTR_INITIAL_CLIENT_ROLES	100
#define OCI_ATTR_UNK			101
#define OCI_ATTR_NUM_COLS         	102
#define OCI_ATTR_LIST_COLUMNS     	103
#define OCI_ATTR_RDBA             	104
#define OCI_ATTR_CLUSTERED        	105
#define OCI_ATTR_PARTITIONED      	106
#define OCI_ATTR_INDEX_ONLY       	107
#define OCI_ATTR_LIST_ARGUMENTS   	108
#define OCI_ATTR_LIST_SUBPROGRAMS 	109
#define OCI_ATTR_REF_TDO          	110
#define OCI_ATTR_LINK             	111
#define OCI_ATTR_MIN              	112
#define OCI_ATTR_MAX              	113
#define OCI_ATTR_INCR             	114
#define OCI_ATTR_CACHE            	115
#define OCI_ATTR_ORDER            	116
#define OCI_ATTR_HW_MARK          	117
#define OCI_ATTR_TYPE_SCHEMA      	118
#define OCI_ATTR_TIMESTAMP        	119
#define OCI_ATTR_NUM_ATTRS        120
#define OCI_ATTR_NUM_PARAMS       121
#define OCI_ATTR_OBJID            122
#define OCI_ATTR_PTYPE            123
#define OCI_ATTR_PARAM            124
#define OCI_ATTR_OVERLOAD_ID      125
#define OCI_ATTR_TABLESPACE       126
#define OCI_ATTR_TDO              127
#define OCI_ATTR_LTYPE            128                           /* list type */
#define OCI_ATTR_PARSE_ERROR_OFFSET 129                /* Parse Error offset */
#define OCI_ATTR_IS_TEMPORARY     130          /* whether table is temporary */
#define OCI_ATTR_IS_TYPED         131              /* whether table is typed */
#define OCI_ATTR_DURATION         132         /* duration of temporary table */
#define OCI_ATTR_IS_INVOKER_RIGHTS 133                  /* is invoker rights */
#define OCI_ATTR_OBJ_NAME         134           /* top level schema obj name */
#define OCI_ATTR_OBJ_SCHEMA       135                         /* schema name */
#define OCI_ATTR_OBJ_ID           136          /* top level schema object id */
#define OCI_ATTR_DIRPATH_SORTED_INDEX    137 /* index that data is sorted on */
#define OCI_ATTR_DIRPATH_INDEX_MAINT_METHOD 138
#define OCI_ATTR_DIRPATH_FILE               139      /* DB file to load into */
#define OCI_ATTR_DIRPATH_STORAGE_INITIAL    140       /* initial extent size */
#define OCI_ATTR_DIRPATH_STORAGE_NEXT       141          /* next extent size */
#define OCI_ATTR_TRANS_TIMEOUT              142       /* transaction timeout */
#define OCI_ATTR_SERVER_STATUS              143/* state of the server handle */
#define OCI_ATTR_STATEMENT                  144 /* statement txt in stmt hdl */
#define OCI_ATTR_NO_CACHE                   145
#define OCI_ATTR_DEQCOND                    146         /* dequeue condition */
#define OCI_ATTR_RESERVED_2                 147                  /* reserved */
#define OCI_ATTR_SUBSCR_RECPT               148 /* recepient of subscription */
#define OCI_ATTR_SUBSCR_RECPTPROTO          149    /* protocol for recepient */
#define OCI_ATTR_DIRPATH_EXPR_TYPE  150        /* expr type of OCI_ATTR_NAME */
#define OCI_ATTR_DIRPATH_INPUT      151    /* input in text or stream format */
#define OCI_DIRPATH_INPUT_TEXT     0x01
#define OCI_DIRPATH_INPUT_STREAM   0x02
#define OCI_DIRPATH_INPUT_UNKNOWN  0x04
#define OCI_ATTR_LDAP_HOST       153              /* LDAP host to connect to */
#define OCI_ATTR_LDAP_PORT       154              /* LDAP port to connect to */
#define OCI_ATTR_BIND_DN         155                              /* bind DN */
#define OCI_ATTR_LDAP_CRED       156       /* credentials to connect to LDAP */
#define OCI_ATTR_WALL_LOC        157               /* client wallet location */
#define OCI_ATTR_LDAP_AUTH       158           /* LDAP authentication method */
#define OCI_ATTR_LDAP_CTX        159        /* LDAP adminstration context DN */
#define OCI_ATTR_SERVER_DNS      160      /* list of registration server DNs */
#define OCI_ATTR_DN_COUNT        161             /* the number of server DNs */
#define OCI_ATTR_SERVER_DN       162                  /* server DN attribute */
#define OCI_ATTR_MAXCHAR_SIZE               163     /* max char size of data */
#define OCI_ATTR_CURRENT_POSITION           164 /* for scrollable result sets*/
#define OCI_ATTR_RESERVED_3                 165                  /* reserved */
#define OCI_ATTR_RESERVED_4                 166                  /* reserved */
#define OCI_ATTR_DIRPATH_FN_CTX             167  /* fn ctx ADT attrs or args */
#define OCI_ATTR_DIGEST_ALGO                168          /* digest algorithm */
#define OCI_ATTR_CERTIFICATE                169               /* certificate */
#define OCI_ATTR_SIGNATURE_ALGO             170       /* signature algorithm */
#define OCI_ATTR_CANONICAL_ALGO             171    /* canonicalization algo. */
#define OCI_ATTR_PRIVATE_KEY                172               /* private key */
#define OCI_ATTR_DIGEST_VALUE               173              /* digest value */
#define OCI_ATTR_SIGNATURE_VAL              174           /* signature value */
#define OCI_ATTR_SIGNATURE                  175                 /* signature */
#define OCI_ATTR_STMTCACHESIZE              176     /* size of the stm cache */

#define OCI_ATTR_CLIENT_IDENTIFIER          278  /* value of client id to set*/
#define OCI_ATTR_MODULE                     366        /* module for tracing */
#define OCI_ATTR_CLIENT_INFO                368               /* client info */
#define OCI_ATTR_DRIVER_NAME                424               /* Driver Name */



/* Server Handle Attribute Values */
#define OCI_SERVER_NOT_CONNECTED        0x0
#define OCI_SERVER_NORMAL               0x1



/* Attributes common to Columns and Stored Procs */
#define OCI_ATTR_DATA_SIZE      1                /* maximum size of the data */
#define OCI_ATTR_DATA_TYPE      2     /* the SQL type of the column/argument */
#define OCI_ATTR_DISP_SIZE      3                        /* the display size */
#define OCI_ATTR_NAME           4         /* the name of the column/argument */
#define OCI_ATTR_PRECISION      5                /* precision if number type */
#define OCI_ATTR_SCALE          6                    /* scale if number type */
#define OCI_ATTR_IS_NULL        7                            /* is it null ? */
#define OCI_ATTR_TYPE_NAME      8
  /* name of the named data type or a package name for package private types */
#define OCI_ATTR_SCHEMA_NAME    9             /* the schema name */
#define OCI_ATTR_SUB_NAME       10      /* type name if package private type */
#define OCI_ATTR_POSITION       11
                    /* relative position of col/arg in the list of cols/args */
/* complex object retrieval parameter attributes */
#define OCI_ATTR_COMPLEXOBJECTCOMP_TYPE         50
#define OCI_ATTR_COMPLEXOBJECTCOMP_TYPE_LEVEL   51
#define OCI_ATTR_COMPLEXOBJECT_LEVEL            52
#define OCI_ATTR_COMPLEXOBJECT_COLL_OUTOFLINE   53

/* Only Columns */
#define OCI_ATTR_DISP_NAME      100                      /* the display name */

/*Only Stored Procs */
#define OCI_ATTR_OVERLOAD       210           /* is this position overloaded */
#define OCI_ATTR_LEVEL          211            /* level for structured types */
#define OCI_ATTR_HAS_DEFAULT    212                   /* has a default value */
#define OCI_ATTR_IOMODE         213                         /* in, out inout */
#define OCI_ATTR_RADIX          214                       /* returns a radix */
#define OCI_ATTR_NUM_ARGS       215             /* total number of arguments */

/* only named type attributes */
#define OCI_ATTR_TYPECODE                  216       /* object or collection */
#define OCI_ATTR_COLLECTION_TYPECODE       217     /* varray or nested table */
#define OCI_ATTR_VERSION                   218      /* user assigned version */
#define OCI_ATTR_IS_INCOMPLETE_TYPE        219 /* is this an incomplete type */
#define OCI_ATTR_IS_SYSTEM_TYPE            220              /* a system type */
#define OCI_ATTR_IS_PREDEFINED_TYPE        221          /* a predefined type */
#define OCI_ATTR_IS_TRANSIENT_TYPE         222           /* a transient type */
#define OCI_ATTR_IS_SYSTEM_GENERATED_TYPE  223      /* system generated type */
#define OCI_ATTR_HAS_NESTED_TABLE          224 /* contains nested table attr */
#define OCI_ATTR_HAS_LOB                   225        /* has a lob attribute */
#define OCI_ATTR_HAS_FILE                  226       /* has a file attribute */
#define OCI_ATTR_COLLECTION_ELEMENT        227 /* has a collection attribute */
#define OCI_ATTR_NUM_TYPE_ATTRS            228  /* number of attribute types */
#define OCI_ATTR_LIST_TYPE_ATTRS           229    /* list of type attributes */
#define OCI_ATTR_NUM_TYPE_METHODS          230     /* number of type methods */
#define OCI_ATTR_LIST_TYPE_METHODS         231       /* list of type methods */
#define OCI_ATTR_MAP_METHOD                232         /* map method of type */
#define OCI_ATTR_ORDER_METHOD              233       /* order method of type */

/* only collection element */
#define OCI_ATTR_NUM_ELEMS                 234         /* number of elements */

/* only type methods */
#define OCI_ATTR_ENCAPSULATION             235        /* encapsulation level */
#define OCI_ATTR_IS_SELFISH                236             /* method selfish */
#define OCI_ATTR_IS_VIRTUAL                237                    /* virtual */
#define OCI_ATTR_IS_INLINE                 238                     /* inline */
#define OCI_ATTR_IS_CONSTANT               239                   /* constant */
#define OCI_ATTR_HAS_RESULT                240                 /* has result */
#define OCI_ATTR_IS_CONSTRUCTOR            241                /* constructor */
#define OCI_ATTR_IS_DESTRUCTOR             242                 /* destructor */
#define OCI_ATTR_IS_OPERATOR               243                   /* operator */
#define OCI_ATTR_IS_MAP                    244               /* a map method */
#define OCI_ATTR_IS_ORDER                  245               /* order method */
#define OCI_ATTR_IS_RNDS                   246  /* read no data state method */
#define OCI_ATTR_IS_RNPS                   247      /* read no process state */
#define OCI_ATTR_IS_WNDS                   248 /* write no data state method */
#define OCI_ATTR_IS_WNPS                   249     /* write no process state */

#define OCI_ATTR_DESC_PUBLIC               250              /* public object */

/* Object Cache Enhancements : attributes for User Constructed Instances     */
#define OCI_ATTR_CACHE_CLIENT_CONTEXT      251
#define OCI_ATTR_UCI_CONSTRUCT             252
#define OCI_ATTR_UCI_DESTRUCT              253
#define OCI_ATTR_UCI_COPY                  254
#define OCI_ATTR_UCI_PICKLE                255
#define OCI_ATTR_UCI_UNPICKLE              256
#define OCI_ATTR_UCI_REFRESH               257

/* for type inheritance */
#define OCI_ATTR_IS_SUBTYPE                258
#define OCI_ATTR_SUPERTYPE_SCHEMA_NAME     259
#define OCI_ATTR_SUPERTYPE_NAME            260

/* for schemas */
#define OCI_ATTR_LIST_OBJECTS              261  /* list of objects in schema */

/* for database */
#define OCI_ATTR_NCHARSET_ID               262                /* char set id */
#define OCI_ATTR_LIST_SCHEMAS              263            /* list of schemas */
#define OCI_ATTR_MAX_PROC_LEN              264       /* max procedure length */
#define OCI_ATTR_MAX_COLUMN_LEN            265     /* max column name length */
#define OCI_ATTR_CURSOR_COMMIT_BEHAVIOR    266     /* cursor commit behavior */
#define OCI_ATTR_MAX_CATALOG_NAMELEN       267         /* catalog namelength */
#define OCI_ATTR_CATALOG_LOCATION          268           /* catalog location */
#define OCI_ATTR_SAVEPOINT_SUPPORT         269          /* savepoint support */
#define OCI_ATTR_NOWAIT_SUPPORT            270             /* nowait support */
#define OCI_ATTR_AUTOCOMMIT_DDL            271             /* autocommit DDL */
#define OCI_ATTR_LOCKING_MODE              272               /* locking mode */

/* for externally initialized context */
#define OCI_ATTR_APPCTX_SIZE               273
#define OCI_ATTR_APPCTX_LIST               274
#define OCI_ATTR_APPCTX_NAME               275
#define OCI_ATTR_APPCTX_ATTR               276
#define OCI_ATTR_APPCTX_VALUE              277
#define OCI_ATTR_CLIENT_IDENTIFIER         278
#define OCI_ATTR_IS_FINAL_TYPE             279
#define OCI_ATTR_IS_INSTANTIABLE_TYPE      280
#define OCI_ATTR_IS_FINAL_METHOD           281
#define OCI_ATTR_IS_INSTANTIABLE_METHOD    282
#define OCI_ATTR_IS_OVERRIDING_METHOD      283
#define OCI_ATTR_CHAR_USED                 285
#define OCI_ATTR_CHAR_SIZE                 286
#define OCI_ATTR_IS_JAVA_TYPE              287
#define OCI_ATTR_DISTINGUISHED_NAME        300
#define OCI_ATTR_KERBEROS_TICKET           301
#define OCI_ATTR_ORA_DEBUG_JDWP            302
#define OCI_ATTR_RESERVED_14               303
/* End Describe Handle Attributes */ 


/*-------------------------Object Ptr Types----------------------------------*/
#define OCI_OTYPE_NAME 1                                      /* object name */
#define OCI_OTYPE_REF  2                                       /* REF to TDO */
#define OCI_OTYPE_PTR  3                                       /* PTR to TDO */
/*---------------------------------------------------------------------------*/


/*--------------------------- OCI Parameter Types ---------------------------*/
#define OCI_PTYPE_UNK           0                               /* unknown   */
#define OCI_PTYPE_TABLE         1                               /* table     */
#define OCI_PTYPE_VIEW          2                               /* view      */
#define OCI_PTYPE_PROC          3                               /* procedure */
#define OCI_PTYPE_FUNC          4                               /* function  */
#define OCI_PTYPE_PKG           5                               /* package   */
#define OCI_PTYPE_TYPE          6                       /* user-defined type */
#define OCI_PTYPE_SYN           7                               /* synonym   */
#define OCI_PTYPE_SEQ           8                               /* sequence  */
#define OCI_PTYPE_COL           9                               /* column    */
#define OCI_PTYPE_ARG           10                              /* argument  */
#define OCI_PTYPE_LIST          11                              /* list      */
#define OCI_PTYPE_TYPE_ATTR     12          /* user-defined type's attribute */
#define OCI_PTYPE_TYPE_COLL     13              /* collection type's element */
#define OCI_PTYPE_TYPE_METHOD   14             /* user-defined type's method */
#define OCI_PTYPE_TYPE_ARG      15    /* user-defined type method's argument */
#define OCI_PTYPE_TYPE_RESULT   16      /* user-defined type method's result */
#define OCI_PTYPE_SCHEMA        17                                 /* schema */
#define OCI_PTYPE_DATABASE      18                               /* database */
/*---------------------------------------------------------------------------*/


/*----------------------- Fail Over Events ----------------------------------*/
#define OCI_FO_END		0x00000001
#define OCI_FO_ABORT		0x00000002
#define OCI_FO_REAUTH		0x00000004
#define OCI_FO_BEGIN		0x00000008
#define OCI_FO_ERROR		0x00000010
/*------------------------- Fail Over Types ---------------------------------*/
#define OCI_FO_NONE		0x00000001
#define OCI_FO_SESSION		0x00000002
#define OCI_FO_SELECT		0x00000004
#define OCI_FO_TXNAL		0x00000008
/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
#define OCI_NLS_DAYNAME1      1                    /* Native name for Monday */
#define OCI_NLS_DAYNAME2      2                   /* Native name for Tuesday */
#define OCI_NLS_DAYNAME3      3                 /* Native name for Wednesday */
#define OCI_NLS_DAYNAME4      4                  /* Native name for Thursday */
#define OCI_NLS_DAYNAME5      5                    /* Native name for Friday */
#define OCI_NLS_DAYNAME6      6              /* Native name for for Saturday */
#define OCI_NLS_DAYNAME7      7                /* Native name for for Sunday */
#define OCI_NLS_ABDAYNAME1    8        /* Native abbreviated name for Monday */
#define OCI_NLS_ABDAYNAME2    9       /* Native abbreviated name for Tuesday */
#define OCI_NLS_ABDAYNAME3    10    /* Native abbreviated name for Wednesday */
#define OCI_NLS_ABDAYNAME4    11     /* Native abbreviated name for Thursday */
#define OCI_NLS_ABDAYNAME5    12       /* Native abbreviated name for Friday */
#define OCI_NLS_ABDAYNAME6    13 /* Native abbreviated name for for Saturday */
#define OCI_NLS_ABDAYNAME7    14   /* Native abbreviated name for for Sunday */
#define OCI_NLS_MONTHNAME1    15                  /* Native name for January */
#define OCI_NLS_MONTHNAME2    16                 /* Native name for February */
#define OCI_NLS_MONTHNAME3    17                    /* Native name for March */
#define OCI_NLS_MONTHNAME4    18                    /* Native name for April */
#define OCI_NLS_MONTHNAME5    19                      /* Native name for May */
#define OCI_NLS_MONTHNAME6    20                     /* Native name for June */
#define OCI_NLS_MONTHNAME7    21                     /* Native name for July */
#define OCI_NLS_MONTHNAME8    22                   /* Native name for August */
#define OCI_NLS_MONTHNAME9    23                /* Native name for September */
#define OCI_NLS_MONTHNAME10   24                  /* Native name for October */
#define OCI_NLS_MONTHNAME11   25                 /* Native name for November */
#define OCI_NLS_MONTHNAME12   26                 /* Native name for December */
#define OCI_NLS_ABMONTHNAME1  27      /* Native abbreviated name for January */
#define OCI_NLS_ABMONTHNAME2  28     /* Native abbreviated name for February */
#define OCI_NLS_ABMONTHNAME3  29        /* Native abbreviated name for March */
#define OCI_NLS_ABMONTHNAME4  30        /* Native abbreviated name for April */
#define OCI_NLS_ABMONTHNAME5  31          /* Native abbreviated name for May */
#define OCI_NLS_ABMONTHNAME6  32         /* Native abbreviated name for June */
#define OCI_NLS_ABMONTHNAME7  33         /* Native abbreviated name for July */
#define OCI_NLS_ABMONTHNAME8  34       /* Native abbreviated name for August */
#define OCI_NLS_ABMONTHNAME9  35    /* Native abbreviated name for September */
#define OCI_NLS_ABMONTHNAME10 36      /* Native abbreviated name for October */
#define OCI_NLS_ABMONTHNAME11 37     /* Native abbreviated name for November */
#define OCI_NLS_ABMONTHNAME12 38     /* Native abbreviated name for December */
#define OCI_NLS_YES           39   /* Native string for affirmative response */
#define OCI_NLS_NO            40                 /* Native negative response */
#define OCI_NLS_AM            41           /* Native equivalent string of AM */
#define OCI_NLS_PM            42           /* Native equivalent string of PM */
#define OCI_NLS_AD            43           /* Native equivalent string of AD */
#define OCI_NLS_BC            44           /* Native equivalent string of BC */
#define OCI_NLS_DECIMAL       45                        /* decimal character */
#define OCI_NLS_GROUP         46                          /* group separator */
#define OCI_NLS_DEBIT         47                   /* Native symbol of debit */
#define OCI_NLS_CREDIT        48                  /* Native sumbol of credit */
#define OCI_NLS_DATEFORMAT    49                       /* Oracle date format */
#define OCI_NLS_INT_CURRENCY  50            /* International currency symbol */
#define OCI_NLS_LOC_CURRENCY  51                   /* Locale currency symbol */
#define OCI_NLS_LANGUAGE      52                            /* Language name */
#define OCI_NLS_ABLANGUAGE    53           /* Abbreviation for language name */
#define OCI_NLS_TERRITORY     54                           /* Territory name */
#define OCI_NLS_CHARACTER_SET 55                       /* Character set name */
#define OCI_NLS_LINGUISTIC_NAME    56                     /* Linguistic name */
#define OCI_NLS_CALENDAR      57                            /* Calendar name */
#define OCI_NLS_DUAL_CURRENCY 78                     /* Dual currency symbol */
#define OCI_NLS_WRITINGDIR    79               /* Language writing direction */
#define OCI_NLS_ABTERRITORY   80                   /* Territory Abbreviation */
#define OCI_NLS_DDATEFORMAT   81               /* Oracle default date format */
#define OCI_NLS_DTIMEFORMAT   82               /* Oracle default time format */
#define OCI_NLS_SFDATEFORMAT  83       /* Local string formatted date format */
#define OCI_NLS_SFTIMEFORMAT  84       /* Local string formatted time format */
#define OCI_NLS_NUMGROUPING   85                   /* Number grouping fields */
#define OCI_NLS_LISTSEP       86                           /* List separator */
#define OCI_NLS_MONDECIMAL    87               /* Monetary decimal character */
#define OCI_NLS_MONGROUP      88                 /* Monetary group separator */
#define OCI_NLS_MONGROUPING   89                 /* Monetary grouping fields */
#define OCI_NLS_INT_CURRENCYSEP 90       /* International currency separator */
#define OCI_NLS_CHARSET_MAXBYTESZ 91     /* Maximum character byte size      */
#define OCI_NLS_CHARSET_FIXEDWIDTH 92    /* Fixed-width charset byte size    */
#define OCI_NLS_CHARSET_ID    93                         /* Character set id */
#define OCI_NLS_NCHARSET_ID   94                        /* NCharacter set id */

#define OCI_NLS_MAXBUFSZ   100 /* Max buffer size may need for OCINlsGetInfo */

#define OCI_NLS_BINARY            0x1           /* for the binary comparison */
#define OCI_NLS_LINGUISTIC        0x2           /* for linguistic comparison */
#define OCI_NLS_CASE_INSENSITIVE  0x10    /* for case-insensitive comparison */

#define OCI_NLS_UPPERCASE         0x20               /* convert to uppercase */
#define OCI_NLS_LOWERCASE         0x40               /* convert to lowercase */

#define OCI_NLS_CS_IANA_TO_ORA   0   /* Map charset name from IANA to Oracle */
#define OCI_NLS_CS_ORA_TO_IANA   1   /* Map charset name from Oracle to IANA */
#define OCI_NLS_LANG_ISO_TO_ORA  2   /* Map language name from ISO to Oracle */
#define OCI_NLS_LANG_ORA_TO_ISO  3   /* Map language name from Oracle to ISO */
#define OCI_NLS_TERR_ISO_TO_ORA  4   /* Map territory name from ISO to Oracle*/
#define OCI_NLS_TERR_ORA_TO_ISO  5   /* Map territory name from Oracle to ISO*/
#define OCI_NLS_TERR_ISO3_TO_ORA 6   /* Map territory name from 3-letter ISO */
                                     /* abbreviation to Oracle               */
#define OCI_NLS_TERR_ORA_TO_ISO3 7   /* Map territory name from Oracle to    */
                                     /* 3-letter ISO abbreviation            */
#define OCI_NLS_LOCALE_A2_ISO_TO_ORA 8
                                      /*Map locale name from A2 ISO to oracle*/
#define OCI_NLS_LOCALE_A2_ORA_TO_ISO 9
                                      /*Map locale name from oracle to A2 ISO*/
/*---------------------------------------------------------------------------*/

/*--------------------------Failover Callback Structure ---------------------*/
typedef sb4 (*OCICallbackFailover)(dvoid *svcctx,
					 dvoid *envctx,
					 dvoid *fo_ctx,
					 ub4 fo_type,
					 ub4 fo_event);

typedef struct
{
  OCICallbackFailover callback_function;
  dvoid *fo_ctx;
}
OCIFocbkStruct;


#define SQLCS_IMPLICIT 1		/* for CHAR, VARCHAR2, CLOB w/o a specified set */
#define SQLCS_NCHAR    2                /* for NCHAR, NCHAR VARYING, NCLOB */
#define SQLCS_EXPLICIT 3		/* for CHAR, etc, with "CHARACTER SET ..." syntax */
#define SQLCS_FLEXIBLE 4		/* for PL/SQL "flexible" parameters */
#define SQLCS_LIT_NULL 5		/* for typecheck of NULL and empty_clob() lits */


#define OCI_UTF16ID           1000                       /* UTF16 charset ID */
#define OCI_UCS2ID            1000                       /* UTF16 charset ID */
#endif  /* _ORADEFS_H */
