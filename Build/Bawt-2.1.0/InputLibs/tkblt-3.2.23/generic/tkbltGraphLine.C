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

#include <stdlib.h>

#include "tkbltGraphLine.h"
#include "tkbltGraphOp.h"

#include "tkbltGrAxis.h"
#include "tkbltGrXAxisOp.h"
#include "tkbltGrPen.h"
#include "tkbltGrPenOp.h"
#include "tkbltGrPenBar.h"
#include "tkbltGrPenLine.h"
#include "tkbltGrElem.h"
#include "tkbltGrElemOp.h"
#include "tkbltGrElemBar.h"
#include "tkbltGrElemLine.h"
#include "tkbltGrMarker.h"
#include "tkbltGrLegd.h"
#include "tkbltGrHairs.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrDef.h"

using namespace Blt;

static const char* searchModeObjOption[] = {"points", "traces", "auto", NULL};
static const char* searchAlongObjOption[] = {"x", "y", "both", NULL};

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_DOUBLE, "-aspect", "aspect", "Aspect", 
   "0", -1, Tk_Offset(LineGraphOptions, aspect), 0, NULL, RESET},
  {TK_OPTION_BORDER, "-background", "background", "Background",
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(LineGraphOptions, normalBg), 
   0, NULL, CACHE},
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_SYNONYM, "-bm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-bottommargin", 0},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(LineGraphOptions, borderWidth), 
   0, NULL, RESET},
  {TK_OPTION_PIXELS, "-bottommargin", "bottomMargin", "BottomMargin",
   "0", -1, Tk_Offset(LineGraphOptions, bottomMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_CURSOR, "-cursor", "cursor", "Cursor", 
   "crosshair", -1, Tk_Offset(LineGraphOptions, cursor), 
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-foreground", 0},
  {TK_OPTION_FONT, "-font", "font", "Font", 
   STD_FONT_MEDIUM, -1, Tk_Offset(LineGraphOptions, titleTextStyle.font),
   0, NULL, RESET},
  {TK_OPTION_COLOR, "-foreground", "foreground", "Foreground",
   STD_NORMAL_FOREGROUND, -1, 
   Tk_Offset(LineGraphOptions, titleTextStyle.color), 0, NULL, CACHE},
  {TK_OPTION_SYNONYM, "-halo", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-searchhalo", 0},
  {TK_OPTION_PIXELS, "-height", "height", "Height", 
   "4i", -1, Tk_Offset(LineGraphOptions, reqHeight), 0, NULL, RESET},
  {TK_OPTION_COLOR, "-highlightbackground", "highlightBackground",
   "HighlightBackground", 
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(LineGraphOptions, highlightBgColor), 
   0, NULL, CACHE},
  {TK_OPTION_COLOR, "-highlightcolor", "highlightColor", "HighlightColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LineGraphOptions, highlightColor), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-highlightthickness", "highlightThickness",
   "HighlightThickness", 
   "2", -1, Tk_Offset(LineGraphOptions, highlightWidth), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-invertxy", "invertXY", "InvertXY", 
   "no", -1, Tk_Offset(LineGraphOptions, inverted), 0, NULL, RESET},
  {TK_OPTION_JUSTIFY, "-justify", "justify", "Justify", 
   "center", -1, Tk_Offset(LineGraphOptions, titleTextStyle.justify),
   0, NULL, RESET},
  {TK_OPTION_PIXELS, "-leftmargin", "leftMargin", "Margin", 
   "0", -1, Tk_Offset(LineGraphOptions, leftMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_SYNONYM, "-lm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-leftmargin", 0},
  {TK_OPTION_BORDER, "-plotbackground", "plotbackground", "PlotBackground",
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(LineGraphOptions, plotBg), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-plotborderwidth", "plotBorderWidth", "PlotBorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(LineGraphOptions, plotBW), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotpadx", "plotPadX", "PlotPad", 
   "0", -1, Tk_Offset(LineGraphOptions, xPad), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotpady", "plotPadY", "PlotPad", 
   "0", -1, Tk_Offset(LineGraphOptions, yPad), 0, NULL, RESET},
  {TK_OPTION_RELIEF, "-plotrelief", "plotRelief", "Relief", 
   "flat", -1, Tk_Offset(LineGraphOptions, plotRelief), 0, NULL, RESET},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief", 
   "flat", -1, Tk_Offset(LineGraphOptions, relief), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-rightmargin", "rightMargin", "Margin", 
   "0", -1, Tk_Offset(LineGraphOptions, rightMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_SYNONYM, "-rm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-rightmargin", 0},
  {TK_OPTION_PIXELS, "-searchhalo", "searchhalo", "SearchHalo", 
   "2m", -1, Tk_Offset(LineGraphOptions, search.halo), 0, NULL, 0},
  {TK_OPTION_STRING_TABLE, "-searchmode", "searchMode", "SearchMode",
   "points", -1, Tk_Offset(LineGraphOptions, search.mode), 
   0, &searchModeObjOption, 0}, 
  {TK_OPTION_STRING_TABLE, "-searchalong", "searchAlong", "SearchAlong",
   "both", -1, Tk_Offset(LineGraphOptions, search.along), 
   0, &searchAlongObjOption, 0},
  {TK_OPTION_BOOLEAN, "-stackaxes", "stackAxes", "StackAxes", 
   "no", -1, Tk_Offset(LineGraphOptions, stackAxes), 0, NULL, RESET},
  {TK_OPTION_STRING, "-takefocus", "takeFocus", "TakeFocus",
   NULL, -1, Tk_Offset(LineGraphOptions, takeFocus),
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_STRING, "-title", "title", "Title", 
   NULL, -1, Tk_Offset(LineGraphOptions, title), 
   TK_OPTION_NULL_OK, NULL, RESET},
  {TK_OPTION_SYNONYM, "-tm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-topmargin", 0},
  {TK_OPTION_PIXELS, "-topmargin", "topMargin", "TopMargin", 
   "0", -1, Tk_Offset(LineGraphOptions, topMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-width", "width", "Width", 
   "5i", -1, Tk_Offset(LineGraphOptions, reqWidth), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotwidth", "plotWidth", "PlotWidth", 
   "0", -1, Tk_Offset(LineGraphOptions, reqPlotWidth), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotheight", "plotHeight", "PlotHeight", 
   "0", -1, Tk_Offset(LineGraphOptions, reqPlotHeight), 0, NULL, RESET},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

// Create

LineGraph::LineGraph(ClientData clientData, Tcl_Interp* interp, 
		     int objc, Tcl_Obj* const objv[])
  : Graph(clientData, interp, objc, objv)
{
  // problems so far?
  if (!valid_)
    return;

  ops_ = (LineGraphOptions*)calloc(1, sizeof(LineGraphOptions));
  LineGraphOptions* ops = (LineGraphOptions*)ops_;

  Tk_SetClass(tkwin_, "Graph");

  ops->bottomMargin.site = MARGIN_BOTTOM;
  ops->leftMargin.site = MARGIN_LEFT;
  ops->topMargin.site = MARGIN_TOP;
  ops->rightMargin.site = MARGIN_RIGHT;

  ops->titleTextStyle.anchor = TK_ANCHOR_N;
  ops->titleTextStyle.color =NULL;
  ops->titleTextStyle.font =NULL;
  ops->titleTextStyle.angle =0;
  ops->titleTextStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(interp_, optionSpecs);
  if ((Tk_InitOptions(interp_, (char*)ops_, optionTable_, tkwin_) != TCL_OK) || (GraphObjConfigure(this, interp_, objc-2, objv+2) != TCL_OK)) {
    valid_ =0;
    return;
  }

  // do this last after Tk_SetClass set
  legend_ = new Legend(this);
  crosshairs_ = new Crosshairs(this);
  postscript_ = new Postscript(this);

  if (createPen("active", 0, NULL) != TCL_OK) {
    valid_ =0;
    return;
  }

  if (createAxes() != TCL_OK) {
    valid_ =0;
    return;
  }

  adjustAxes();

  Tcl_SetStringObj(Tcl_GetObjResult(interp_), Tk_PathName(tkwin_), -1);
}

LineGraph::~LineGraph()
{
}

int LineGraph::createPen(const char* penName, int objc, Tcl_Obj* const objv[])
{
  int isNew;
  Tcl_HashEntry *hPtr = 
    Tcl_CreateHashEntry(&penTable_, penName, &isNew);
  if (!isNew) {
    Tcl_AppendResult(interp_, "pen \"", penName, "\" already exists in \"",
		     Tk_PathName(tkwin_), "\"", (char *)NULL);
    return TCL_ERROR;
  }

  Pen* penPtr = new LinePen(this, penName, hPtr);
  if (!penPtr)
    return TCL_ERROR;

  Tcl_SetHashValue(hPtr, penPtr);

  if ((Tk_InitOptions(interp_, (char*)penPtr->ops(), penPtr->optionTable(), tkwin_) != TCL_OK) || (PenObjConfigure(this, penPtr, interp_, objc-4, objv+4) != TCL_OK)) {
    delete penPtr;
    return TCL_ERROR;
  }

  return TCL_OK;
}

int LineGraph::createElement(int objc, Tcl_Obj* const objv[])
{
  char *name = Tcl_GetString(objv[3]);
  if (name[0] == '-') {
    Tcl_AppendResult(interp_, "name of element \"", name, 
		     "\" can't start with a '-'", NULL);
    return TCL_ERROR;
  }

  int isNew;
  Tcl_HashEntry* hPtr = 
    Tcl_CreateHashEntry(&elements_.table, name, &isNew);
  if (!isNew) {
    Tcl_AppendResult(interp_, "element \"", name, 
		     "\" already exists in \"", Tcl_GetString(objv[0]), 
		     "\"", NULL);
    return TCL_ERROR;
  }

  Element* elemPtr = new LineElement(this, name, hPtr);
  if (!elemPtr)
    return TCL_ERROR;

  Tcl_SetHashValue(hPtr, elemPtr);

  if ((Tk_InitOptions(interp_, (char*)elemPtr->ops(), elemPtr->optionTable(), tkwin_) != TCL_OK) || (ElementObjConfigure(elemPtr, interp_, objc-4, objv+4) != TCL_OK)) {
    delete elemPtr;
    return TCL_ERROR;
  }

  elemPtr->link = elements_.displayList->append(elemPtr);

  return TCL_OK;
}
