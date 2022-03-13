/* command.h - definitions for expect commands

Written by: Don Libes, NIST, 2/6/90

Design and implementation of this program was paid for by U.S. tax
dollars.  Therefore it is public domain.  However, the author and NIST
would appreciate credit if this program or parts of it are used.
*/

#ifdef HAVE_SYS_WAIT_H
  /* ISC doesn't def WNOHANG unless _POSIX_SOURCE is def'ed */
# ifdef WNOHANG_REQUIRES_POSIX_SOURCE
#  define _POSIX_SOURCE
# endif
# include <sys/wait.h>
# ifdef WNOHANG_REQUIRES_POSIX_SOURCE
#  undef _POSIX_SOURCE
# endif
#endif

#ifdef __APPLE__
/* From: "Daniel A. Steffen" <steffen@ics.mq.edu.au> */
# undef panic
#endif

#include <tclPort.h>

#define EXP_CHANNELNAMELEN (16 + TCL_INTEGER_SPACE)

EXTERN char *		exp_get_var _ANSI_ARGS_((Tcl_Interp *,char *));

EXTERN int exp_default_match_max;
EXTERN int exp_default_parity;
EXTERN int exp_default_rm_nulls;
EXTERN int exp_default_close_on_eof;

EXTERN int		exp_one_arg_braced _ANSI_ARGS_((Tcl_Obj *));

EXTERN Tcl_Obj*		exp_eval_with_one_arg _ANSI_ARGS_((ClientData,
				Tcl_Interp *, struct Tcl_Obj * CONST objv[]));

EXTERN void		exp_lowmemcpy _ANSI_ARGS_((char *,char *,int));

EXTERN int exp_flageq_code _ANSI_ARGS_((char *,char *,int));

#define exp_flageq(flag,string,minlen) \
(((string)[0] == (flag)[0]) && (exp_flageq_code(((flag)+1),((string)+1),((minlen)-1))))

/* exp_flageq for single char flags */
#define exp_flageq1(flag,string) \
	((string[0] == flag) && (string[1] == '\0'))

#define EXP_SPAWN_ID_USER		0
#define EXP_SPAWN_ID_ANY_LIT		"-1"

#define EXP_CHANNEL_PREFIX "exp"
#define EXP_CHANNEL_PREFIX_LENGTH 3
#define isExpChannelName(name) \
    (0 == strncmp(name,EXP_CHANNEL_PREFIX,EXP_CHANNEL_PREFIX_LENGTH))

#define exp_is_stdinfd(x)	((x) == 0)
#define exp_is_devttyfd(x)	((x) == exp_dev_tty)

#define EXP_NOPID	0	/* Used when there is no associated pid to */
				/* wait for.  For example: */
				/* 1) When fd opened by someone else, e.g., */
				/* Tcl's open */
				/* 2) When entry not in use */
				/* 3) To tell user pid of "spawn -open" */
				/* 4) stdin, out, error */

#define EXP_NOFD	-1

/* these are occasionally useful to distinguish between various expect */
/* commands and are also used as array indices into the per-fd eg[] arrays */
#define EXP_CMD_BEFORE	0
#define EXP_CMD_AFTER	1
#define EXP_CMD_BG	2
#define EXP_CMD_FG	3

/*
 * This structure describes per-instance state of an Exp channel.
 */

typedef struct ExpOrigin {
  int         refCount;       /* Number of times this channel is used. */
  Tcl_Channel channel_orig;   /* If opened by someone else, i.e. tcl::open */
} ExpOrigin;


typedef struct ExpUniBuf {
    Tcl_UniChar* buffer;    /* char buffer, holdings unicode chars (fixed width) */
    int          max;       /* number of CHARS the buffer has space for (== old msize) */
    int          use;       /* number of CHARS the buffer is currently holding */
    Tcl_Obj*     newchars;  /* Object to hold newly read characters */
} ExpUniBuf;

typedef struct ExpState {
    Tcl_Channel channel;	/* Channel associated with this file. */
    char name[EXP_CHANNELNAMELEN+1]; /* expect and interact set variables
				   to channel name, so for efficiency
				   cache it here */
    int fdin;		/* input fd */
    int fdout;		/* output fd - usually the same as fdin, although
			   may be different if channel opened by tcl::open */
    ExpOrigin* chan_orig;   /* If opened by someone else, i.e. tcl::open */
    int fd_slave;	/* slave fd if "spawn -pty" used */

    /* this may go away if we find it is not needed */
    /* it might be needed by inherited channels */
    int validMask;		/* OR'ed combination of TCL_READABLE,
				 * TCL_WRITABLE, or TCL_EXCEPTION: indicates
				 * which operations are valid on the file. */

    int pid;		/* pid or EXP_NOPID if no pid */

    ExpUniBuf input;    /* input buffer */

    int umsize;	        /* # of bytes (min) that is guaranteed to match */
			/* this comes from match_max command */
    int printed;	/* # of characters! written to stdout (if logging on) */
                        /* but not actually returned via a match yet */
    int echoed;	        /* additional # of characters (beyond "printed" above) */
                        /* echoed back but not actually returned via a match */
                        /* yet.  This supports interact -echo */

    int rm_nulls;	/* if nulls should be stripped before pat matching */
    int open;		/* if fdin/fdout open */
    int user_waited;    /* if user has issued "wait" command */
    int sys_waited;	/* if wait() (or variant) has been called */
    int registered;	/* if channel registered */
    WAIT_STATUS_TYPE wait;	/* raw status from wait() */
    int parity;	        /* if parity should be preserved */
    int close_on_eof;   /* if channel should be closed automatically on eof */
    int key;	        /* unique id that identifies what command instance */
                        /* last touched this buffer */
    int force_read;	/* force read to occur (even if buffer already has */
                        /* data).  This supports interact CAN_MATCH */
    int notified;	/* If Tcl_NotifyChannel has been called and we */
		        /* have not yet read from the channel. */
    int notifiedMask;	/* Mask reported when notified. */

    int fg_armed;	/* If we have requested Tk_CreateFileHandler to be */
			/* responding to foreground events.  Note that */
		        /* other handlers can have stolen it away so this */
			/* doesn't necessarily mean the handler is set.  */
			/* However, if fg_armed is 0, then the handlers */
			/* definitely needs to be set.  The significance of */
			/* this flag is so we can remember to turn it off. */
#ifdef HAVE_PTYTRAP
    char *slave_name;   /* Full name of slave, i.e., /dev/ttyp0 */
#endif /* HAVE_PTYTRAP */
    /* may go away */
    int leaveopen;	/* If we should not call Tcl's close when we close - */
                        /* only relevant if Tcl does the original open */

    Tcl_Interp *bg_interp;	/* interp to process the bg cases */
    int bg_ecount;		/* number of background ExpStates */
    enum {
	blocked,	/* blocked because we are processing the */
			/* file handler */
	armed,		/* normal state when bg handler in use */
	unarmed,	/* no bg handler in use */
	disarm_req_while_blocked	/* while blocked, a request */
				/* was received to disarm it.  Rather than */
				/* processing the request immediately, defer */
				/* it so that when we later try to unblock */
				/* we will see at that time that it should */
				/* instead be disarmed */
    } bg_status;

    /*
     * If the channel is freed while in the middle of a bg event handler,
     * remember that and defer freeing of the ExpState structure until
     * it is safe.
     */
    int freeWhenBgHandlerUnblocked;

    /* If channel is closed but not yet waited on, we tie up the fd by
     * attaching it to /dev/null.  We play this little game so that we
     * can embed the fd in the channel name.  If we didn't tie up the
     * fd, we'd get channel name collisions.  I'd consider naming the
     * channels independently of the fd, but this makes debugging easier.
     */
    int fdBusy;

    /* 
     * stdinout and stderr never go away so that our internal refs to them
     * don't have to be invalidated.  Having to worry about invalidating them
     * would be a major pain.  */
    int keepForever;

    /*  Remember that "reserved" esPtrs are no longer in use. */
    int valid;
    
    struct ExpState *nextPtr;	/* Pointer to next file in list of all
				 * file channels. */
} ExpState;

#define EXP_SPAWN_ID_BAD	((ExpState *)0)

#define EXP_TIME_INFINITY	-1

extern Tcl_ChannelType expChannelType;

#define EXP_TEMPORARY	1	/* expect */
#define EXP_PERMANENT	2	/* expect_after, expect_before, expect_bg */

#define EXP_DIRECT	1
#define EXP_INDIRECT	2

EXTERN void		expAdjust _ANSI_ARGS_((ExpState *));
EXTERN int		expWriteChars _ANSI_ARGS_((ExpState *,char *,int));
EXTERN int		expWriteCharsUni _ANSI_ARGS_((ExpState *,Tcl_UniChar *,int));
EXTERN void		exp_buffer_shuffle _ANSI_ARGS_((Tcl_Interp *,ExpState *,int,char *,char *));
EXTERN int		exp_close _ANSI_ARGS_((Tcl_Interp *,ExpState *));
EXTERN void		exp_close_all _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_ecmd_remove_fd_direct_and_indirect 
				_ANSI_ARGS_((Tcl_Interp *,int));
EXTERN void		exp_trap_on _ANSI_ARGS_((int));
EXTERN int		exp_trap_off _ANSI_ARGS_((char *));

EXTERN void		exp_strftime(char *format, const struct tm *timeptr,Tcl_DString *dstring);

#define exp_deleteProc (void (*)())0
#define exp_deleteObjProc (void (*)())0

EXTERN int expect_key;
EXTERN int exp_configure_count;	/* # of times descriptors have been closed */
				/* or indirect lists have been changed */
EXTERN int exp_nostack_dump;	/* TRUE if user has requested unrolling of */
				/* stack with no trace */

EXTERN void		exp_init_pty _ANSI_ARGS_((void));
EXTERN void		exp_pty_exit _ANSI_ARGS_((void));
EXTERN void		exp_init_tty _ANSI_ARGS_((void));
EXTERN void		exp_init_stdio _ANSI_ARGS_((void));
/*EXTERN void		exp_init_expect _ANSI_ARGS_((Tcl_Interp *));*/
EXTERN void		exp_init_spawn_ids _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_spawn_id_vars _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_trap _ANSI_ARGS_((void));
EXTERN void		exp_init_send _ANSI_ARGS_((void));
EXTERN void		exp_init_unit_random _ANSI_ARGS_((void));
EXTERN void		exp_init_sig _ANSI_ARGS_((void));
EXTERN void		expChannelInit _ANSI_ARGS_((void));
EXTERN int		expChannelCountGet _ANSI_ARGS_((void));
EXTERN int              expChannelStillAlive _ANSI_ARGS_((ExpState *, char *));

EXTERN int		exp_tcl2_returnvalue _ANSI_ARGS_((int));
EXTERN int		exp_2tcl_returnvalue _ANSI_ARGS_((int));

EXTERN void		exp_rearm_sigchld _ANSI_ARGS_((Tcl_Interp *));
EXTERN int		exp_string_to_signal _ANSI_ARGS_((Tcl_Interp *,char *));

EXTERN char *exp_onexit_action;

#define exp_new(x)	(x *)malloc(sizeof(x))

struct exp_state_list {
	ExpState *esPtr;
	struct exp_state_list *next;
};

/* describes a -i flag */
struct exp_i {
	int cmdtype;	/* EXP_CMD_XXX.  When an indirect update is */
			/* triggered by Tcl, this helps tell us in what */
			/* exp_i list to look in. */
	int direct;	/* if EXP_DIRECT, then the spawn ids have been given */
			/* literally, else indirectly through a variable */
	int duration;	/* if EXP_PERMANENT, char ptrs here had to be */
			/* malloc'd because Tcl command line went away - */
			/* i.e., in expect_before/after */
	char *variable;
	char *value;	/* if type == direct, this is the string that the */
			/* user originally supplied to the -i flag.  It may */
			/* lose relevance as the fd_list is manipulated */
			/* over time.  If type == direct, this is  the */
			/* cached value of variable use this to tell if it */
			/* has changed or not, and ergo whether it's */
			/* necessary to reparse. */

	int ecount;	/* # of ecases this is used by */

	struct exp_state_list *state_list;
	struct exp_i *next;
};

EXTERN struct exp_i *	exp_new_i_complex _ANSI_ARGS_((Tcl_Interp *,
					char *, int, Tcl_VarTraceProc *));
EXTERN struct exp_i *	exp_new_i_simple _ANSI_ARGS_((ExpState *,int));
EXTERN struct exp_state_list *exp_new_state _ANSI_ARGS_((ExpState *));
EXTERN void		exp_free_i _ANSI_ARGS_((Tcl_Interp *,struct exp_i *,
					Tcl_VarTraceProc *));
EXTERN void		exp_free_state _ANSI_ARGS_((struct exp_state_list *));
EXTERN void		exp_free_state_single _ANSI_ARGS_((struct exp_state_list *));
EXTERN int		exp_i_update _ANSI_ARGS_((Tcl_Interp *,
					struct exp_i *));

/*
 * definitions for creating commands
 */

#define EXP_NOPREFIX	1	/* don't define with "exp_" prefix */
#define EXP_REDEFINE	2	/* stomp on old commands with same name */

#define exp_proc(cmdproc) 0, cmdproc

struct exp_cmd_data {
	char		*name;
	Tcl_ObjCmdProc	*objproc;
	Tcl_CmdProc	*proc;
	ClientData	data;
	int 		flags;
};

EXTERN void		exp_create_commands _ANSI_ARGS_((Tcl_Interp *,
						struct exp_cmd_data *));
EXTERN void		exp_init_main_cmds _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_expect_cmds _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_most_cmds _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_trap_cmds _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_interact_cmds _ANSI_ARGS_((Tcl_Interp *));
EXTERN void		exp_init_tty_cmds();

EXTERN ExpState *	expStateCheck _ANSI_ARGS_((Tcl_Interp *,ExpState *,int,int,char *));
EXTERN ExpState *       expStateCurrent _ANSI_ARGS_((Tcl_Interp *,int,int,int));
EXTERN ExpState *       expStateFromChannelName _ANSI_ARGS_((Tcl_Interp *,char *,int,int,int,char *));
EXTERN void		expStateFree _ANSI_ARGS_((ExpState *));

EXTERN ExpState *	expCreateChannel _ANSI_ARGS_((Tcl_Interp *,int,int,int));
EXTERN ExpState *	expWaitOnAny _ANSI_ARGS_((void));
EXTERN ExpState *	expWaitOnOne _ANSI_ARGS_((void));
EXTERN void		expExpectVarsInit _ANSI_ARGS_((void));
EXTERN int		expStateAnyIs _ANSI_ARGS_((ExpState *));
EXTERN int		expDevttyIs _ANSI_ARGS_((ExpState *));
EXTERN int		expStdinoutIs _ANSI_ARGS_((ExpState *));
EXTERN ExpState *	expStdinoutGet _ANSI_ARGS_((void));
EXTERN ExpState *	expDevttyGet _ANSI_ARGS_((void));

/* generic functions that really should be provided by Tcl */
#if 0 /* Redefined as macros. */
EXTERN int		expSizeGet _ANSI_ARGS_((ExpState *));
EXTERN int		expSizeZero _ANSI_ARGS_((ExpState *));
#else
#define expSizeGet(esPtr)  ((esPtr)->input.use)
#define expSizeZero(esPtr) (((esPtr)->input.use) == 0)
#endif

#define EXP_CMDINFO_CLOSE  "expect/cmdinfo/close"
#define EXP_CMDINFO_RETURN "expect/cmdinfo/return"

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
