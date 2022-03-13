/* exp_event.h - event definitions */

int exp_get_next_event _ANSI_ARGS_((Tcl_Interp *,ExpState **, int, ExpState **, int, int));
int exp_get_next_event_info _ANSI_ARGS_((Tcl_Interp *, ExpState *));
int exp_dsleep _ANSI_ARGS_((Tcl_Interp *, double));
void exp_init_event _ANSI_ARGS_((void));

extern void (*exp_event_exit) _ANSI_ARGS_((Tcl_Interp *));

void exp_event_disarm _ANSI_ARGS_((ExpState *,Tcl_FileProc *));
void exp_event_disarm_bg _ANSI_ARGS_((ExpState *));
void exp_event_disarm_fg _ANSI_ARGS_((ExpState *));

void exp_arm_background_channelhandler _ANSI_ARGS_((ExpState *));
void exp_disarm_background_channelhandler _ANSI_ARGS_((ExpState *));
void exp_disarm_background_channelhandler_force _ANSI_ARGS_((ExpState *));
void exp_unblock_background_channelhandler _ANSI_ARGS_((ExpState *));
void exp_block_background_channelhandler _ANSI_ARGS_((ExpState *));

void exp_background_channelhandler _ANSI_ARGS_((ClientData,int));

