/* !BEGIN!: Do not edit below this line. */

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Exported function declarations:
 */

/* 0 */
TKBLT_STORAGE_CLASS int		Blt_CreateVector(Tcl_Interp*interp,
				const char *vecName, int size,
				Blt_Vector**vecPtrPtr);
/* 1 */
TKBLT_STORAGE_CLASS int		Blt_CreateVector2(Tcl_Interp*interp,
				const char *vecName, const char *cmdName,
				const char *varName, int initialSize,
				Blt_Vector **vecPtrPtr);
/* 2 */
TKBLT_STORAGE_CLASS int		Blt_DeleteVectorByName(Tcl_Interp*interp,
				const char *vecName);
/* 3 */
TKBLT_STORAGE_CLASS int		Blt_DeleteVector(Blt_Vector *vecPtr);
/* 4 */
TKBLT_STORAGE_CLASS int		Blt_GetVector(Tcl_Interp*interp, const char *vecName,
				Blt_Vector **vecPtrPtr);
/* 5 */
TKBLT_STORAGE_CLASS int		Blt_GetVectorFromObj(Tcl_Interp*interp,
				Tcl_Obj *objPtr, Blt_Vector **vecPtrPtr);
/* 6 */
TKBLT_STORAGE_CLASS int		Blt_ResetVector(Blt_Vector *vecPtr, double *dataArr,
				int n, int arraySize, Tcl_FreeProc *freeProc);
/* 7 */
TKBLT_STORAGE_CLASS int		Blt_ResizeVector(Blt_Vector *vecPtr, int n);
/* 8 */
TKBLT_STORAGE_CLASS int		Blt_VectorExists(Tcl_Interp*interp,
				const char *vecName);
/* 9 */
TKBLT_STORAGE_CLASS int		Blt_VectorExists2(Tcl_Interp*interp,
				const char *vecName);
/* 10 */
TKBLT_STORAGE_CLASS Blt_VectorId	Blt_AllocVectorId(Tcl_Interp*interp,
				const char *vecName);
/* 11 */
TKBLT_STORAGE_CLASS int		Blt_GetVectorById(Tcl_Interp*interp,
				Blt_VectorId clientId,
				Blt_Vector **vecPtrPtr);
/* 12 */
TKBLT_STORAGE_CLASS void		Blt_SetVectorChangedProc(Blt_VectorId clientId,
				Blt_VectorChangedProc *proc,
				ClientData clientData);
/* 13 */
TKBLT_STORAGE_CLASS void		Blt_FreeVectorId(Blt_VectorId clientId);
/* 14 */
TKBLT_STORAGE_CLASS const char *	Blt_NameOfVectorId(Blt_VectorId clientId);
/* 15 */
TKBLT_STORAGE_CLASS const char *	Blt_NameOfVector(Blt_Vector *vecPtr);
/* 16 */
TKBLT_STORAGE_CLASS int		Blt_ExprVector(Tcl_Interp*interp, char *expr,
				Blt_Vector *vecPtr);
/* 17 */
TKBLT_STORAGE_CLASS void		Blt_InstallIndexProc(Tcl_Interp*interp,
				const char *indexName,
				Blt_VectorIndexProc *procPtr);
/* 18 */
TKBLT_STORAGE_CLASS double		Blt_VecMin(Blt_Vector *vPtr);
/* 19 */
TKBLT_STORAGE_CLASS double		Blt_VecMax(Blt_Vector *vPtr);

typedef struct TkbltStubs {
    int magic;
    void *hooks;

    int (*blt_CreateVector) (Tcl_Interp*interp, const char *vecName, int size, Blt_Vector**vecPtrPtr); /* 0 */
    int (*blt_CreateVector2) (Tcl_Interp*interp, const char *vecName, const char *cmdName, const char *varName, int initialSize, Blt_Vector **vecPtrPtr); /* 1 */
    int (*blt_DeleteVectorByName) (Tcl_Interp*interp, const char *vecName); /* 2 */
    int (*blt_DeleteVector) (Blt_Vector *vecPtr); /* 3 */
    int (*blt_GetVector) (Tcl_Interp*interp, const char *vecName, Blt_Vector **vecPtrPtr); /* 4 */
    int (*blt_GetVectorFromObj) (Tcl_Interp*interp, Tcl_Obj *objPtr, Blt_Vector **vecPtrPtr); /* 5 */
    int (*blt_ResetVector) (Blt_Vector *vecPtr, double *dataArr, int n, int arraySize, Tcl_FreeProc *freeProc); /* 6 */
    int (*blt_ResizeVector) (Blt_Vector *vecPtr, int n); /* 7 */
    int (*blt_VectorExists) (Tcl_Interp*interp, const char *vecName); /* 8 */
    int (*blt_VectorExists2) (Tcl_Interp*interp, const char *vecName); /* 9 */
    Blt_VectorId (*blt_AllocVectorId) (Tcl_Interp*interp, const char *vecName); /* 10 */
    int (*blt_GetVectorById) (Tcl_Interp*interp, Blt_VectorId clientId, Blt_Vector **vecPtrPtr); /* 11 */
    void (*blt_SetVectorChangedProc) (Blt_VectorId clientId, Blt_VectorChangedProc *proc, ClientData clientData); /* 12 */
    void (*blt_FreeVectorId) (Blt_VectorId clientId); /* 13 */
    const char * (*blt_NameOfVectorId) (Blt_VectorId clientId); /* 14 */
    const char * (*blt_NameOfVector) (Blt_Vector *vecPtr); /* 15 */
    int (*blt_ExprVector) (Tcl_Interp*interp, char *expr, Blt_Vector *vecPtr); /* 16 */
    void (*blt_InstallIndexProc) (Tcl_Interp*interp, const char *indexName, Blt_VectorIndexProc *procPtr); /* 17 */
    double (*blt_VecMin) (Blt_Vector *vPtr); /* 18 */
    double (*blt_VecMax) (Blt_Vector *vPtr); /* 19 */
} TkbltStubs;

extern const TkbltStubs *tkbltStubsPtr;

#ifdef __cplusplus
}
#endif

#if defined(USE_TKBLT_STUBS)

/*
 * Inline function declarations:
 */

#define Blt_CreateVector \
	(tkbltStubsPtr->blt_CreateVector) /* 0 */
#define Blt_CreateVector2 \
	(tkbltStubsPtr->blt_CreateVector2) /* 1 */
#define Blt_DeleteVectorByName \
	(tkbltStubsPtr->blt_DeleteVectorByName) /* 2 */
#define Blt_DeleteVector \
	(tkbltStubsPtr->blt_DeleteVector) /* 3 */
#define Blt_GetVector \
	(tkbltStubsPtr->blt_GetVector) /* 4 */
#define Blt_GetVectorFromObj \
	(tkbltStubsPtr->blt_GetVectorFromObj) /* 5 */
#define Blt_ResetVector \
	(tkbltStubsPtr->blt_ResetVector) /* 6 */
#define Blt_ResizeVector \
	(tkbltStubsPtr->blt_ResizeVector) /* 7 */
#define Blt_VectorExists \
	(tkbltStubsPtr->blt_VectorExists) /* 8 */
#define Blt_VectorExists2 \
	(tkbltStubsPtr->blt_VectorExists2) /* 9 */
#define Blt_AllocVectorId \
	(tkbltStubsPtr->blt_AllocVectorId) /* 10 */
#define Blt_GetVectorById \
	(tkbltStubsPtr->blt_GetVectorById) /* 11 */
#define Blt_SetVectorChangedProc \
	(tkbltStubsPtr->blt_SetVectorChangedProc) /* 12 */
#define Blt_FreeVectorId \
	(tkbltStubsPtr->blt_FreeVectorId) /* 13 */
#define Blt_NameOfVectorId \
	(tkbltStubsPtr->blt_NameOfVectorId) /* 14 */
#define Blt_NameOfVector \
	(tkbltStubsPtr->blt_NameOfVector) /* 15 */
#define Blt_ExprVector \
	(tkbltStubsPtr->blt_ExprVector) /* 16 */
#define Blt_InstallIndexProc \
	(tkbltStubsPtr->blt_InstallIndexProc) /* 17 */
#define Blt_VecMin \
	(tkbltStubsPtr->blt_VecMin) /* 18 */
#define Blt_VecMax \
	(tkbltStubsPtr->blt_VecMax) /* 19 */

#endif /* defined(USE_TKBLT_STUBS) */

/* !END!: Do not edit above this line. */
