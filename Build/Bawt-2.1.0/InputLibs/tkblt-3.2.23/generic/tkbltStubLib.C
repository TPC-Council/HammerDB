#ifndef USE_TCL_STUBS
#define USE_TCL_STUBS
#endif

#include <tcl.h>

ClientData tkbltStubsPtr =NULL;

const char* Tkblt_InitStubs(Tcl_Interp* interp, const char* version, int exact)
{
    const char* actualVersion = 
      Tcl_PkgRequireEx(interp, "tkblt", version, exact, &tkbltStubsPtr);

    return (actualVersion && tkbltStubsPtr) ? actualVersion : NULL;
}
