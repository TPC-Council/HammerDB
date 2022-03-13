/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1991-2004 George A Howlett.
 *
 *	Permission is hereby granted, free of charge, to any person obtaining
 *	a copy of this software and associated documentation files (the
 *	"Software"), to deal in the Software without restriction, including
 *	without limitation the rights to use, copy, modify, merge, publish,
 *	distribute, sublicense, and/or sell copies of the Software, and to
 *	permit persons to whom the Software is furnished to do so, subject to
 *	the following conditions:
 *
 *	The above copyright notice and this permission notice shall be
 *	included in all copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <tk.h>

#include "tkbltGraph.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrPostscriptOp.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

int Blt::PostscriptObjConfigure(Graph* graphPtr, Tcl_Interp* interp, 
				int objc, Tcl_Obj* const objv[])
{
  Postscript* setupPtr = graphPtr->postscript_;
  Tk_SavedOptions savedOptions;
  int mask =0;
  int error;
  Tcl_Obj* errorResult;

  for (error=0; error<=1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char*)setupPtr->ops_, setupPtr->optionTable_, 
			objc, objv, graphPtr->tkwin_, &savedOptions, &mask)
	  != TCL_OK)
	continue;
    }
    else {
      errorResult = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(errorResult);
      Tk_RestoreSavedOptions(&savedOptions);
    }

    break; 
  }

  if (!error) {
    Tk_FreeSavedOptions(&savedOptions);
    return TCL_OK;
  }
  else {
    Tcl_SetObjResult(interp, errorResult);
    Tcl_DecrRefCount(errorResult);
    return TCL_ERROR;
  }
}

static int CgetOp(ClientData clientData, Tcl_Interp* interp, 
		  int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  if (objc != 4) {
    Tcl_WrongNumArgs(interp, 2, objv, "cget option");
    return TCL_ERROR;
  }

  Postscript *setupPtr = graphPtr->postscript_;
  Tcl_Obj* objPtr = Tk_GetOptionValue(interp, 
				      (char*)setupPtr->ops_, 
				      setupPtr->optionTable_,
				      objv[3], graphPtr->tkwin_);
  if (objPtr == NULL)
    return TCL_ERROR;
  else
    Tcl_SetObjResult(interp, objPtr);
  return TCL_OK;
}

static int ConfigureOp(ClientData clientData, Tcl_Interp* interp, 
		       int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;
  Postscript* setupPtr = graphPtr->postscript_;
  if (objc <= 4) {
    Tcl_Obj* objPtr = Tk_GetOptionInfo(interp, (char*)setupPtr->ops_, 
				       setupPtr->optionTable_, 
				       (objc == 4) ? objv[3] : NULL, 
				       graphPtr->tkwin_);
    if (objPtr == NULL)
      return TCL_ERROR;
    else
      Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
  } 
  else
    return PostscriptObjConfigure(graphPtr, interp, objc-3, objv+3);
}

static int OutputOp(ClientData clientData, Tcl_Interp* interp, 
		    int objc, Tcl_Obj* const objv[])
{
  Graph* graphPtr = (Graph*)clientData;

  const char *fileName = NULL;
  Tcl_Channel channel = NULL;
  if (objc > 3) {
    fileName = Tcl_GetString(objv[3]);
    if (fileName[0] != '-') {
      // First argument is the file name
      objv++, objc--;

      channel = Tcl_OpenFileChannel(interp, fileName, "w", 0666);
      if (!channel)
	return TCL_ERROR;

      if (Tcl_SetChannelOption(interp, channel, "-translation", "binary") 
	  != TCL_OK)
	return TCL_ERROR;
    }
  }

  PSOutput* psPtr = new PSOutput(graphPtr);
  
  if (PostscriptObjConfigure(graphPtr, interp, objc-3, objv+3) != TCL_OK) {
    if (channel)
      Tcl_Close(interp, channel);
    delete psPtr;
    return TCL_ERROR;
  }

  if (graphPtr->print(fileName, psPtr) != TCL_OK) {
    if (channel)
      Tcl_Close(interp, channel);
    delete psPtr;
    return TCL_ERROR;
  }

  int length;
  const char* buffer = psPtr->getValue(&length);
  if (channel) {
    int nBytes = Tcl_Write(channel, buffer, length);
    if (nBytes < 0) {
      Tcl_AppendResult(interp, "error writing file \"", fileName, "\": ",
		       Tcl_PosixError(interp), (char *)NULL);
      if (channel)
	Tcl_Close(interp, channel);
      delete psPtr;
      return TCL_ERROR;
    }
    Tcl_Close(interp, channel);
  }
  else
    Tcl_SetStringObj(Tcl_GetObjResult(interp), buffer, length);

  delete psPtr;

  return TCL_OK;
}

const Ensemble Blt::postscriptEnsemble[] = {
  {"cget",      CgetOp, 0},
  {"configure", ConfigureOp, 0},
  {"output",    OutputOp, 0},
  { 0,0,0 }
};
