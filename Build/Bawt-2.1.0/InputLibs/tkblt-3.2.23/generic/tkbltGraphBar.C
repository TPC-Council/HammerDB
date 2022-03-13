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

#include "tkbltGraphBar.h"
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

// BarGroup

BarGroup::BarGroup()
{
  nSegments =0;
  xAxis =NULL;
  yAxis =NULL;
  sum =0;
  count =0;
  lastY =0;
  index =0;
}

// BarGraph

static const char* barmodeObjOption[] = 
  {"normal", "stacked", "aligned", "overlap", NULL};
static const char* searchModeObjOption[] = {"points", "traces", "auto", NULL};
static const char* searchAlongObjOption[] = {"x", "y", "both", NULL};

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_DOUBLE, "-aspect", "aspect", "Aspect", 
   "0", -1, Tk_Offset(BarGraphOptions, aspect), 0, NULL, RESET},
  {TK_OPTION_BORDER, "-background", "background", "Background",
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(BarGraphOptions, normalBg), 
   0, NULL, CACHE},
  {TK_OPTION_STRING_TABLE, "-barmode", "barMode", "BarMode", 
   "normal", -1, Tk_Offset(BarGraphOptions, barMode), 
   0, &barmodeObjOption, RESET},
  {TK_OPTION_DOUBLE, "-barwidth", "barWidth", "BarWidth", 
   ".9", -1, Tk_Offset(BarGraphOptions, barWidth), 0, NULL, RESET},
  {TK_OPTION_DOUBLE, "-baseline", "baseline", "Baseline", 
   "0", -1, Tk_Offset(BarGraphOptions, baseline), 0, NULL, RESET},
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_SYNONYM, "-bm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-bottommargin", 0},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(BarGraphOptions, borderWidth), 
   0, NULL, RESET},
  {TK_OPTION_PIXELS, "-bottommargin", "bottomMargin", "BottomMargin",
   "0", -1, Tk_Offset(BarGraphOptions, bottomMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_CURSOR, "-cursor", "cursor", "Cursor", 
   "crosshair", -1, Tk_Offset(BarGraphOptions, cursor), 
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-foreground", 0},
  {TK_OPTION_FONT, "-font", "font", "Font", 
   STD_FONT_MEDIUM, -1, Tk_Offset(BarGraphOptions, titleTextStyle.font), 
   0, NULL, RESET},
  {TK_OPTION_COLOR, "-foreground", "foreground", "Foreground",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(BarGraphOptions, titleTextStyle.color), 
   0, NULL, CACHE},
  {TK_OPTION_SYNONYM, "-halo", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-searchhalo", 0},
  {TK_OPTION_PIXELS, "-height", "height", "Height", 
   "4i", -1, Tk_Offset(BarGraphOptions, reqHeight), 0, NULL, RESET},
  {TK_OPTION_COLOR, "-highlightbackground", "highlightBackground",
   "HighlightBackground", 
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(BarGraphOptions, highlightBgColor), 
   0, NULL, CACHE},
  {TK_OPTION_COLOR, "-highlightcolor", "highlightColor", "HighlightColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(BarGraphOptions, highlightColor), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-highlightthickness", "highlightThickness",
   "HighlightThickness", 
   "2", -1, Tk_Offset(BarGraphOptions, highlightWidth), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-invertxy", "invertXY", "InvertXY", 
   "no", -1, Tk_Offset(BarGraphOptions, inverted), 0, NULL, RESET},
  {TK_OPTION_JUSTIFY, "-justify", "justify", "Justify", 
   "center", -1, Tk_Offset(BarGraphOptions, titleTextStyle.justify), 
   0, NULL, RESET},
  {TK_OPTION_PIXELS, "-leftmargin", "leftMargin", "Margin", 
   "0", -1, Tk_Offset(BarGraphOptions, leftMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_SYNONYM, "-lm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-leftmargin", 0},
  {TK_OPTION_BORDER, "-plotbackground", "plotbackground", "PlotBackground",
   STD_NORMAL_BACKGROUND, -1, Tk_Offset(BarGraphOptions, plotBg), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-plotborderwidth", "plotBorderWidth", "PlotBorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(BarGraphOptions, plotBW), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotpadx", "plotPadX", "PlotPad", 
   "0", -1, Tk_Offset(BarGraphOptions, xPad), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotpady", "plotPadY", "PlotPad", 
   "0", -1, Tk_Offset(BarGraphOptions, yPad), 0, NULL, RESET},
  {TK_OPTION_RELIEF, "-plotrelief", "plotRelief", "Relief", 
   "flat", -1, Tk_Offset(BarGraphOptions, plotRelief), 0, NULL, RESET},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief", 
   "flat", -1, Tk_Offset(BarGraphOptions, relief), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-rightmargin", "rightMargin", "Margin", 
   "0", -1, Tk_Offset(BarGraphOptions, rightMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_SYNONYM, "-rm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-rightmargin", 0},
  {TK_OPTION_PIXELS, "-searchhalo", "searchhalo", "SearchHalo", 
   "2m", -1, Tk_Offset(BarGraphOptions, search.halo), 0, NULL, 0},
  {TK_OPTION_STRING_TABLE, "-searchmode", "searchMode", "SearchMode",
   "points", -1, Tk_Offset(BarGraphOptions, search.mode), 
   0, &searchModeObjOption, 0}, 
  {TK_OPTION_STRING_TABLE, "-searchalong", "searchAlong", "SearchAlong",
   "both", -1, Tk_Offset(BarGraphOptions, search.along), 
   0, &searchAlongObjOption, 0},
  {TK_OPTION_BOOLEAN, "-stackaxes", "stackAxes", "StackAxes", 
   "no", -1, Tk_Offset(BarGraphOptions, stackAxes), 0, NULL, RESET},
  {TK_OPTION_STRING, "-takefocus", "takeFocus", "TakeFocus",
   NULL, -1, Tk_Offset(BarGraphOptions, takeFocus), 
   TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_STRING, "-title", "title", "Title", 
   NULL, -1, Tk_Offset(BarGraphOptions, title), TK_OPTION_NULL_OK, NULL, RESET},
  {TK_OPTION_SYNONYM, "-tm", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-topmargin", 0},
  {TK_OPTION_PIXELS, "-topmargin", "topMargin", "TopMargin", 
   "0", -1, Tk_Offset(BarGraphOptions, topMargin.reqSize), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-width", "width", "Width", 
   "5i", -1, Tk_Offset(BarGraphOptions, reqWidth), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotwidth", "plotWidth", "PlotWidth", 
   "0", -1, Tk_Offset(BarGraphOptions, reqPlotWidth), 0, NULL, RESET},
  {TK_OPTION_PIXELS, "-plotheight", "plotHeight", "PlotHeight", 
   "0", -1, Tk_Offset(BarGraphOptions, reqPlotHeight), 0, NULL, RESET},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

// Create

BarGraph::BarGraph(ClientData clientData, Tcl_Interp* interp, 
		   int objc, Tcl_Obj* const objv[])
  : Graph(clientData, interp, objc, objv)
{
  // problems so far?
  if (!valid_)
    return;

  ops_ = (BarGraphOptions*)calloc(1, sizeof(BarGraphOptions));
  BarGraphOptions* ops = (BarGraphOptions*)ops_;

  Tk_SetClass(tkwin_, "Barchart");

  barGroups_ =NULL;
  nBarGroups_ =0;
  maxBarSetSize_ =0;
  Tcl_InitHashTable(&setTable_, sizeof(BarSetKey)/sizeof(int));

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

BarGraph::~BarGraph()
{
  destroyBarSets();
}

int BarGraph::configure()	
{
  BarGraphOptions* ops = (BarGraphOptions*)ops_;
  // Don't allow negative bar widths. Reset to an arbitrary value (0.1)
  if (ops->barWidth <= 0.0)
    ops->barWidth = 0.9;

  return Graph::configure();
}

int BarGraph::createPen(const char* penName, int objc, Tcl_Obj* const objv[])
{
  int isNew;
  Tcl_HashEntry *hPtr = 
    Tcl_CreateHashEntry(&penTable_, penName, &isNew);
  if (!isNew) {
    Tcl_AppendResult(interp_, "pen \"", penName, "\" already exists in \"",
		     Tk_PathName(tkwin_), "\"", (char *)NULL);
    return TCL_ERROR;
  }

  Pen* penPtr = new BarPen(this, penName, hPtr);
  if (!penPtr)
    return TCL_ERROR;

  Tcl_SetHashValue(hPtr, penPtr);

  if ((Tk_InitOptions(interp_, (char*)penPtr->ops(), penPtr->optionTable(), tkwin_) != TCL_OK) || (PenObjConfigure(this, penPtr, interp_, objc-4, objv+4) != TCL_OK)) {
    delete penPtr;
    return TCL_ERROR;
  }

  flags |= RESET;
  eventuallyRedraw();

  return TCL_OK;
}

int BarGraph::createElement(int objc, Tcl_Obj* const objv[])
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

  Element* elemPtr = new BarElement(this, name, hPtr);
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

void BarGraph::mapElements()
{
  BarGraphOptions* ops = (BarGraphOptions*)ops_;
  if ((BarMode)ops->barMode != INFRONT)
    resetBarSets();

  Graph::mapElements();
}

void BarGraph::resetAxes()
{
  BarGraphOptions* ops = (BarGraphOptions*)ops_;
  
  /* FIXME: This should be called whenever the display list of
   *	      elements change. Maybe yet another flag INIT_STACKS to
   *	      indicate that the element display list has changed.
   *	      Needs to be done before the axis limits are set.
   */
  initBarSets();
  if (((BarMode)ops->barMode == STACKED) && (nBarGroups_ > 0))
    computeBarStacks();

  Graph::resetAxes();
}

void BarGraph::initBarSets()
{
  BarGraphOptions* ops = (BarGraphOptions*)ops_;
  
  // Free resources associated with a previous frequency table. This includes
  // the array of frequency information and the table itself
  destroyBarSets();
  if ((BarMode)ops->barMode == INFRONT)
    return;

  // Initialize a hash table and fill it with unique abscissas.  Keep track
  // of the frequency of each x-coordinate and how many abscissas have
  // duplicate mappings.
  Tcl_HashTable setTable;
  Tcl_InitHashTable(&setTable, sizeof(BarSetKey)/sizeof(int));
  int nSegs =0;

  for (ChainLink* link = Chain_FirstLink(elements_.displayList);
       link; link = Chain_NextLink(link)) {
    BarElement* bePtr = (BarElement*)Chain_GetValue(link);
    BarElementOptions* ops = (BarElementOptions*)bePtr->ops();
    if (ops->hide)
      continue;

    nSegs++;
    if (ops->coords.x) {
      int nPoints = ops->coords.x->nValues();
      for (double *x=ops->coords.x->values_, *xend=x+nPoints; x<xend; x++) {
	BarSetKey key;
	key.value =*x;
	key.xAxis =ops->xAxis;
	key.yAxis =NULL;

	int isNew;
	Tcl_HashEntry* hhPtr = 
	  Tcl_CreateHashEntry(&setTable, (char*)&key, &isNew);
	Tcl_HashTable* tablePtr;
	if (isNew) {
	  tablePtr = (Tcl_HashTable*)malloc(sizeof(Tcl_HashTable));
	  Tcl_InitHashTable(tablePtr, TCL_STRING_KEYS);
	  Tcl_SetHashValue(hhPtr, tablePtr);
	}
	else
	  tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hhPtr);

	const char* name = ops->groupName ? ops->groupName : ops->yAxis->name_;
	Tcl_HashEntry* hhPtr2 = Tcl_CreateHashEntry(tablePtr, name, &isNew);
	size_t count =1;
	if (!isNew) {
	  count = (size_t)Tcl_GetHashValue(hhPtr2);
	  count++;
	}		
	Tcl_SetHashValue(hhPtr2, count);
      }
    }
  }

  // no bar elements to be displayed
  if (setTable.numEntries == 0)
    return;

  int sum =0;
  int max =0;
  Tcl_HashSearch iter;
  for (Tcl_HashEntry *hhPtr = Tcl_FirstHashEntry(&setTable, &iter); hhPtr;
       hhPtr = Tcl_NextHashEntry(&iter)) {
    BarSetKey* keyPtr = (BarSetKey*)Tcl_GetHashKey(&setTable, hhPtr);
    Tcl_HashTable* tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hhPtr);

    int isNew;
    Tcl_HashEntry* hPtr = 
      Tcl_CreateHashEntry(&setTable_, (char*)keyPtr, &isNew);
    Tcl_SetHashValue(hPtr, tablePtr);

    if (max < tablePtr->numEntries)
      max = tablePtr->numEntries; // # of stacks in group
    sum += tablePtr->numEntries;
  }

  Tcl_DeleteHashTable(&setTable);

  if (sum > 0) {
    barGroups_ = new BarGroup[sum];
    BarGroup* groupPtr = barGroups_;
    Tcl_HashSearch iter;
    for (Tcl_HashEntry* hPtr = Tcl_FirstHashEntry(&setTable_, &iter); 
	 hPtr; hPtr = Tcl_NextHashEntry(&iter)) {
      BarSetKey* keyPtr = (BarSetKey*)Tcl_GetHashKey(&setTable_, hPtr);
      Tcl_HashTable* tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hPtr);

      size_t xcount = 0;
      Tcl_HashSearch iter2;
      for (Tcl_HashEntry *hPtr2 = Tcl_FirstHashEntry(tablePtr, &iter2);
	   hPtr2; hPtr2 = Tcl_NextHashEntry(&iter2)) {
	size_t count = (size_t)Tcl_GetHashValue(hPtr2);
	groupPtr->nSegments = count;
	groupPtr->xAxis = keyPtr->xAxis;
	groupPtr->yAxis = keyPtr->yAxis;
	groupPtr->index = xcount++;
	Tcl_SetHashValue(hPtr2, groupPtr);

	groupPtr++;
      }
    }
  }

  maxBarSetSize_ = max;
  nBarGroups_ = sum;
}

void BarGraph::destroyBarSets()
{
  delete [] barGroups_;
  barGroups_ = NULL;

  nBarGroups_ = 0;
  Tcl_HashSearch iter;
  for (Tcl_HashEntry* hPtr=Tcl_FirstHashEntry(&setTable_, &iter); hPtr; 
       hPtr=Tcl_NextHashEntry(&iter)) {
    Tcl_HashTable* tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hPtr);
    Tcl_DeleteHashTable(tablePtr);
    free(tablePtr);
  }

  Tcl_DeleteHashTable(&setTable_);
  Tcl_InitHashTable(&setTable_, sizeof(BarSetKey)/sizeof(int));
}

void BarGraph::resetBarSets()
{
  for (BarGroup *gp = barGroups_, *gend = gp + nBarGroups_; gp < gend; gp++) {
    gp->lastY = 0.0;
    gp->count = 0;
  }
}

void BarGraph::computeBarStacks()
{
  BarGraphOptions* ops = (BarGraphOptions*)ops_;

  if (((BarMode)ops->barMode != STACKED) || (nBarGroups_ == 0))
    return;

  // Initialize the stack sums to zero
  for (BarGroup *gp = barGroups_, *gend = gp + nBarGroups_; gp < gend; gp++)
    gp->sum = 0.0;

  // Consider each bar x-y coordinate. Add the ordinates of duplicate
  // abscissas

  for (ChainLink* link = Chain_FirstLink(elements_.displayList); link;
       link = Chain_NextLink(link)) {
    BarElement* bePtr = (BarElement*)Chain_GetValue(link);
    BarElementOptions* ops = (BarElementOptions*)bePtr->ops();
    if (ops->hide)
      continue;

    if (ops->coords.x && ops->coords.y) {
      for (double *x=ops->coords.x->values_, *y=ops->coords.y->values_, 
	     *xend=x+ops->coords.x->nValues(); x<xend; x++, y++) {
	BarSetKey key;
	key.value =*x;
	key.xAxis =ops->xAxis;
	key.yAxis =NULL;
	Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&setTable_, (char*)&key);
	if (!hPtr)
	  continue;

	Tcl_HashTable *tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hPtr);
	const char *name = ops->groupName ? ops->groupName : ops->yAxis->name_;
	hPtr = Tcl_FindHashEntry(tablePtr, name);
	if (!hPtr)
	  continue;

	BarGroup *groupPtr = (BarGroup*)Tcl_GetHashValue(hPtr);
	groupPtr->sum += *y;
      }
    }
  }
}

