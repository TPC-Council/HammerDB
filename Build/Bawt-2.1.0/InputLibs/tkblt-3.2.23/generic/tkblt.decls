library tkblt
interface tkblt

declare 0 generic {
  int Blt_CreateVector(Tcl_Interp* interp, const char *vecName,
		       int size, Blt_Vector** vecPtrPtr)
}

declare 1 generic {
  int Blt_CreateVector2(Tcl_Interp* interp, const char *vecName,
			const char *cmdName, const char *varName,
			int initialSize, Blt_Vector **vecPtrPtr)
}

declare 2 generic {
  int Blt_DeleteVectorByName(Tcl_Interp* interp, const char *vecName)
}

declare 3 generic {
  int Blt_DeleteVector(Blt_Vector *vecPtr)
}

declare 4 generic {
  int Blt_GetVector(Tcl_Interp* interp, const char *vecName,
		    Blt_Vector **vecPtrPtr)
}

declare 5 generic {
  int Blt_GetVectorFromObj(Tcl_Interp* interp, Tcl_Obj *objPtr,
			   Blt_Vector **vecPtrPtr)
}

declare 6 generic {
  int Blt_ResetVector(Blt_Vector *vecPtr, double *dataArr, int n,
		      int arraySize, Tcl_FreeProc *freeProc)
}

declare 7 generic {
  int Blt_ResizeVector(Blt_Vector *vecPtr, int n)
}

declare 8 generic {
  int Blt_VectorExists(Tcl_Interp* interp, const char *vecName)
}

declare 9 generic {
  int Blt_VectorExists2(Tcl_Interp* interp, const char *vecName)
}

declare 10 generic {
  Blt_VectorId Blt_AllocVectorId(Tcl_Interp* interp, const char *vecName)
}

declare 11 generic {
  int Blt_GetVectorById(Tcl_Interp* interp, Blt_VectorId clientId,
			Blt_Vector **vecPtrPtr)
}

declare 12 generic {
  void Blt_SetVectorChangedProc(Blt_VectorId clientId,
				Blt_VectorChangedProc *proc,
				ClientData clientData)
}

declare 13 generic {
  void Blt_FreeVectorId(Blt_VectorId clientId)
}

declare 14 generic {
  const char *Blt_NameOfVectorId(Blt_VectorId clientId)
}

declare 15 generic {
  const char *Blt_NameOfVector(Blt_Vector *vecPtr)
}

declare 16 generic {
  int Blt_ExprVector(Tcl_Interp* interp, char *expr, Blt_Vector *vecPtr)
}

declare 17 generic {
  void Blt_InstallIndexProc(Tcl_Interp* interp, const char *indexName,
			    Blt_VectorIndexProc * procPtr)
}

declare 18 generic {
  double Blt_VecMin(Blt_Vector *vPtr)
}

declare 19 generic {
  double Blt_VecMax(Blt_Vector *vPtr)
}
