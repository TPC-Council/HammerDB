/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1993-2004 George A Howlett.
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

#include <float.h>
#include <stdlib.h>
#include <string.h>

#include <cmath>

#include "tkbltGraphBar.h"
#include "tkbltGrElemBar.h"
#include "tkbltGrElemOption.h"
#include "tkbltGrAxis.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"
#include "tkbltInt.h"

using namespace Blt;

#define CLAMP(x,l,h)	((x) = (((x)<(l))? (l) : ((x)>(h)) ? (h) : (x)))
#define MIN3(a,b,c)	(((a)<(b))?(((a)<(c))?(a):(c)):(((b)<(c))?(b):(c)))

#define PointInRectangle(r,x0,y0)					\
  (((x0) <= (int)((r)->x + (r)->width - 1)) && ((x0) >= (int)(r)->x) && \
   ((y0) <= (int)((r)->y + (r)->height - 1)) && ((y0) >= (int)(r)->y))

// OptionSpecs

static Tk_ObjCustomOption styleObjOption =
  {
    "style", StyleSetProc, StyleGetProc, StyleRestoreProc, StyleFreeProc, 
    (ClientData)sizeof(BarStyle)
  };

extern Tk_ObjCustomOption penObjOption;
extern Tk_ObjCustomOption pairsObjOption;
extern Tk_ObjCustomOption valuesObjOption;
extern Tk_ObjCustomOption xAxisObjOption;
extern Tk_ObjCustomOption yAxisObjOption;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_CUSTOM, "-activepen", "activePen", "ActivePen",
   "active", -1, Tk_Offset(BarElementOptions, activePenPtr), 
   TK_OPTION_NULL_OK, &penObjOption, LAYOUT},
  {TK_OPTION_SYNONYM, "-background", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_DOUBLE, "-barwidth", "barWidth", "BarWidth",
   "0", -1, Tk_Offset(BarElementOptions, barWidth), 0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags",
   "all", -1, Tk_Offset(BarElementOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(BarElementOptions, builtinPen.borderWidth),
   0, NULL, CACHE},
  {TK_OPTION_BORDER, "-color", "color", "color",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(BarElementOptions, builtinPen.fill),
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-data", "data", "Data", 
   NULL, -1, Tk_Offset(BarElementOptions, coords),
   TK_OPTION_NULL_OK, &pairsObjOption, RESET},
  {TK_OPTION_COLOR, "-errorbarcolor", "errorBarColor", "ErrorBarColor",
   NULL, -1, Tk_Offset(BarElementOptions, builtinPen.errorBarColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS,"-errorbarwidth", "errorBarWidth", "ErrorBarWidth",
   "1", -1, Tk_Offset(BarElementOptions, builtinPen.errorBarLineWidth),
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarcap", "errorBarCap", "ErrorBarCap", 
   "0", -1, Tk_Offset(BarElementOptions, builtinPen.errorBarCapWidth),
   0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-outline", 0},
  {TK_OPTION_SYNONYM, "-fill", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_SYNONYM, "-foreground", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-outline", 0},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(BarElementOptions, hide), 0, NULL, LAYOUT},
  {TK_OPTION_STRING, "-label", "label", "Label",
   NULL, -1, Tk_Offset(BarElementOptions, label), 
   TK_OPTION_NULL_OK, NULL, LAYOUT},
  {TK_OPTION_RELIEF, "-legendrelief", "legendRelief", "LegendRelief",
   "flat", -1, Tk_Offset(BarElementOptions, legendRelief), 0, NULL, LAYOUT},
  {TK_OPTION_CUSTOM, "-mapx", "mapX", "MapX", 
   "x", -1, Tk_Offset(BarElementOptions, xAxis), 0, &xAxisObjOption, RESET},
  {TK_OPTION_CUSTOM, "-mapy", "mapY", "MapY",
   "y", -1, Tk_Offset(BarElementOptions, yAxis), 0, &yAxisObjOption, RESET},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline",
   NULL, -1, Tk_Offset(BarElementOptions, builtinPen.outlineColor),
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-pen", "pen", "Pen", 
   NULL, -1, Tk_Offset(BarElementOptions, normalPenPtr), 
   TK_OPTION_NULL_OK, &penObjOption, LAYOUT},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief",
   "raised", -1, Tk_Offset(BarElementOptions, builtinPen.relief), 
   0, NULL, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showerrorbars", "showErrorBars", "ShowErrorBars",
   "both", -1, Tk_Offset(BarElementOptions, builtinPen.errorBarShow), 
   0, &fillObjOption, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showvalues", "showValues", "ShowValues",
   "none", -1, Tk_Offset(BarElementOptions, builtinPen.valueShow), 
   0, &fillObjOption, CACHE},
  {TK_OPTION_STRING, "-stack", "stack", "Stack", 
   NULL, -1, Tk_Offset(BarElementOptions, groupName),
   TK_OPTION_NULL_OK, NULL, RESET},
  {TK_OPTION_CUSTOM, "-styles", "styles", "Styles",
   "", -1, Tk_Offset(BarElementOptions, stylePalette), 
   0, &styleObjOption, RESET},
  {TK_OPTION_ANCHOR, "-valueanchor", "valueAnchor", "ValueAnchor",
   "s", -1, Tk_Offset(BarElementOptions, builtinPen.valueStyle.anchor),
   0, NULL, CACHE},
  {TK_OPTION_COLOR, "-valuecolor", "valueColor", "ValueColor",
   STD_NORMAL_FOREGROUND, -1, 
   Tk_Offset(BarElementOptions,builtinPen.valueStyle.color), 0, NULL, CACHE},
  {TK_OPTION_FONT, "-valuefont", "valueFont", "ValueFont",
   STD_FONT_SMALL, -1, Tk_Offset(BarElementOptions, builtinPen.valueStyle.font),
   0, NULL, CACHE},
  {TK_OPTION_STRING, "-valueformat", "valueFormat", "ValueFormat",
   "%g", -1, Tk_Offset(BarElementOptions, builtinPen.valueFormat),
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-valuerotate", "valueRotate", "ValueRotate",
   "0", -1, Tk_Offset(BarElementOptions, builtinPen.valueStyle.angle),
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-weights", "weights", "Weights",
   NULL, -1, Tk_Offset(BarElementOptions, w), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_SYNONYM, "-x", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-xdata", 0},
  {TK_OPTION_CUSTOM, "-xdata", "xData", "XData", 
   NULL, -1, Tk_Offset(BarElementOptions, coords.x), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xerror", "xError", "XError", 
   NULL, -1, Tk_Offset(BarElementOptions, xError), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xhigh", "xHigh", "XHigh", 
   NULL, -1, Tk_Offset(BarElementOptions, xHigh), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xlow", "xLow", "XLow", 
   NULL, -1, Tk_Offset(BarElementOptions, xLow), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_SYNONYM, "-y", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-ydata", 0},
  {TK_OPTION_CUSTOM, "-ydata", "yData", "YData", 
   NULL, -1, Tk_Offset(BarElementOptions, coords.y), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-yerror", "yError", "YError", 
   NULL, -1, Tk_Offset(BarElementOptions, yError), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-yhigh", "yHigh", "YHigh",
   NULL, -1, Tk_Offset(BarElementOptions, yHigh), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-ylow", "yLow", "YLow", 
   NULL, -1, Tk_Offset(BarElementOptions, yLow), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

BarElement::BarElement(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
  : Element(graphPtr, name, hPtr)
{
  barToData_ =NULL;
  bars_ =NULL;
  activeToData_ =NULL;
  activeRects_ =NULL;
  nBars_ =0;
  nActive_ =0;

  xeb_.segments =NULL;
  xeb_.map =NULL;
  xeb_.length =0;
  yeb_.segments =NULL;
  yeb_.map =NULL;
  yeb_.length =0;

  ops_ = (BarElementOptions*)calloc(1, sizeof(BarElementOptions));
  BarElementOptions* ops = (BarElementOptions*)ops_;
  ops->elemPtr = (Element*)this;

  builtinPenPtr = new BarPen(graphPtr_, "builtin", &ops->builtinPen);
  ops->builtinPenPtr = builtinPenPtr;

  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);

  ops->stylePalette = new Chain();

  // this is an option and will be freed via Tk_FreeConfigOptions
  // By default an element's name and label are the same
  ops->label = Tcl_Alloc(strlen(name)+1);
  if (name)
    strcpy((char*)ops->label,(char*)name);

  Tk_InitOptions(graphPtr_->interp_, (char*)&(ops->builtinPen),
		 builtinPenPtr->optionTable(), graphPtr->tkwin_);
}

BarElement::~BarElement()
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  delete builtinPenPtr;

  reset();

  if (ops->stylePalette) {
    freeStylePalette(ops->stylePalette);
    delete ops->stylePalette;
  }
}

int BarElement::configure()
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  if (builtinPenPtr->configure() != TCL_OK)
    return TCL_ERROR;

  // Point to the static normal pen if no external pens have been selected.
  ChainLink* link = Chain_FirstLink(ops->stylePalette);
  if (!link) {
    link = new ChainLink(sizeof(BarStyle));
    ops->stylePalette->linkAfter(link, NULL);
  }
  BarStyle* stylePtr = (BarStyle*)Chain_GetValue(link);
  stylePtr->penPtr = NORMALPEN(ops);

  return TCL_OK;
}

void BarElement::map()
{
  BarGraph* barGraphPtr_ = (BarGraph*)graphPtr_;
  BarElementOptions* ops = (BarElementOptions*)ops_;
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;

  if (!link)
    return;

  reset();
  if (!ops->coords.x || !ops->coords.y ||
      !ops->coords.x->nValues() || !ops->coords.y->nValues())
    return;
  int nPoints = NUMBEROFPOINTS(ops);

  double barWidth = (ops->barWidth > 0.0) ? ops->barWidth : gops->barWidth;
  AxisOptions* axisyops = (AxisOptions*)ops->yAxis->ops();
  double baseline = (axisyops->logScale) ? 0.0 : gops->baseline;
  double barOffset = barWidth * 0.5;

  // Create an array of bars representing the screen coordinates of all the
  // segments in the bar.
  Rectangle* bars = new Rectangle[nPoints];
  int* barToData = new int[nPoints];

  double* x = ops->coords.x->values_;
  double* y = ops->coords.y->values_;
  int count = 0;

  int ii;
  Rectangle* rp;
  for (rp=bars, ii=0; ii<nPoints; ii++) {
    // Two opposite corners of the rectangle in graph coordinates
    Point2d c1, c2;

    // check Abscissa is out of range of the x-axis
    if (((x[ii] - barWidth) > ops->xAxis->axisRange_.max) ||
	((x[ii] + barWidth) < ops->xAxis->axisRange_.min))
      continue;			

    c1.x = x[ii] - barOffset;
    c1.y = y[ii];
    c2.x = c1.x + barWidth;
    c2.y = baseline;

    // If the mode is "aligned" or "stacked" we need to adjust the x or y
    // coordinates of the two corners.
    if ((barGraphPtr_->nBarGroups_ > 0) && 
	((BarGraph::BarMode)gops->barMode != BarGraph::INFRONT) && 
	(!gops->stackAxes)) {
      
      BarSetKey key;
      key.value =x[ii];
      key.xAxis =ops->xAxis;
      key.yAxis =NULL;
      Tcl_HashEntry* hPtr = 
	Tcl_FindHashEntry(&barGraphPtr_->setTable_, (char*)&key);

      if (hPtr) {
	Tcl_HashTable *tablePtr = (Tcl_HashTable*)Tcl_GetHashValue(hPtr);
	const char *name = (ops->groupName) ? ops->groupName:ops->yAxis->name_;
	Tcl_HashEntry* hPtr2 = Tcl_FindHashEntry(tablePtr, name);
	if (hPtr2) {
	  BarGroup* groupPtr = (BarGroup*)Tcl_GetHashValue(hPtr2);
	  double slice = barWidth / (double)barGraphPtr_->maxBarSetSize_;
	  double offset = (slice * groupPtr->index);
	  if (barGraphPtr_->maxBarSetSize_ > 1) {
	    offset += slice * 0.05;
	    slice *= 0.90;
	  }

	  switch ((BarGraph::BarMode)gops->barMode) {
	  case BarGraph::STACKED:
	    groupPtr->count++;
	    c2.y = groupPtr->lastY;
	    c1.y += c2.y;
	    groupPtr->lastY = c1.y;
	    c1.x += offset;
	    c2.x = c1.x + slice;
	    break;
			
	  case BarGraph::ALIGNED:
	    slice /= groupPtr->nSegments;
	    c1.x += offset + (slice * groupPtr->count);
	    c2.x = c1.x + slice;
	    groupPtr->count++;
	    break;
			
	  case BarGraph::OVERLAP:
	    {
	      slice /= (groupPtr->nSegments + 1);
	      double width = slice + slice;
	      groupPtr->count++;
	      c1.x += offset + 
		(slice * (groupPtr->nSegments - groupPtr->count));
	      c2.x = c1.x + width;
	    }
	    break;
			
	  case BarGraph::INFRONT:
	    break;
	  }
	}
      }
    }

    int invertBar = 0;
    if (c1.y < c2.y) {
      // Handle negative bar values by swapping ordinates
      double temp = c1.y;
      c1.y = c2.y;
      c2.y = temp;
      invertBar = 1;
    }

    // Get the two corners of the bar segment and compute the rectangle
    double ybot = c2.y;
    c1 = graphPtr_->map2D(c1.x, c1.y, ops->xAxis, ops->yAxis);
    c2 = graphPtr_->map2D(c2.x, c2.y, ops->xAxis, ops->yAxis);
    if ((ybot == 0.0) && (axisyops->logScale))
      c2.y = graphPtr_->bottom_;
	    
    if (c2.y < c1.y) {
      double t = c1.y;
      c1.y = c2.y;
      c2.y = t;
    }

    if (c2.x < c1.x) {
      double t = c1.x;
      c1.x = c2.x;
      c2.x = t;
    }

    if ((c1.x > graphPtr_->right_) || (c2.x < graphPtr_->left_) || 
	(c1.y > graphPtr_->bottom_) || (c2.y < graphPtr_->top_))
      continue;

    // Bound the bars horizontally by the width of the graph window 
    // Bound the bars vertically by the position of the axis.
    double right =0;
    double left =0;
    double top =0;
    double bottom =0;
    if (gops->stackAxes) {
      top = ops->yAxis->screenMin_;
      bottom = ops->yAxis->screenMin_ + ops->yAxis->screenRange_;
      left = graphPtr_->left_;
      right = graphPtr_->right_;
    }
    else {
      bottom = right = 10000;
      // Shouldn't really have a call to Tk_Width or Tk_Height in
      // mapping routine.  We only want to clamp the bar segment to the
      // size of the window if we're actually mapped onscreen
      if (Tk_Height(graphPtr_->tkwin_) > 1)
	bottom = Tk_Height(graphPtr_->tkwin_);
      if (Tk_Width(graphPtr_->tkwin_) > 1)
	right = Tk_Width(graphPtr_->tkwin_);
    }

    CLAMP(c1.y, top, bottom);
    CLAMP(c2.y, top, bottom);
    CLAMP(c1.x, left, right);
    CLAMP(c2.x, left, right);
    double dx = fabs(c1.x - c2.x);
    double dy = fabs(c1.y - c2.y);
    if ((dx == 0) || (dy == 0))
      continue;

    int height = (int)dy;
    int width  = (int)dx;
    if (invertBar)
      rp->y = (int)MIN(c1.y, c2.y);
    else
      rp->y = (int)(MAX(c1.y, c2.y)) - height;

    rp->x = (int)MIN(c1.x, c2.x);

    rp->width = width;
    if (rp->width & 0x1)
      rp->width++;
    if (rp->width < 1)
      rp->width = 1;

    rp->height = height + 1;
    if (rp->height < 1)
      rp->height = 1;

    // Save the data index corresponding to the rectangle
    barToData[count] = ii;
    count++;
    rp++;
  }
  nBars_ = count;
  bars_ = bars;
  barToData_ = barToData;
  if (nActiveIndices_ > 0)
    mapActive();
	
  int size = 20;
  if (count > 0)
    size = bars->width;

  // Set the symbol size of all the pen styles
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
    BarPen* penPtr = stylePtr->penPtr;
    BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
    stylePtr->symbolSize = size;
    stylePtr->errorBarCapWidth = pops->errorBarCapWidth;
  }

  BarStyle** dataToStyle = (BarStyle**)StyleMap();
  if (((ops->yHigh && ops->yHigh->nValues() > 0) && 
       (ops->yLow && ops->yLow->nValues() > 0)) ||
      ((ops->xHigh && ops->xHigh->nValues() > 0) &&
       (ops->xLow && ops->xLow->nValues() > 0)) ||
      (ops->xError && ops->xError->nValues() > 0) || 
      (ops->yError && ops->yError->nValues() > 0)) {
    mapErrorBars(dataToStyle);
  }

  mergePens(dataToStyle);
  delete [] dataToStyle;
}

void BarElement::extents(Region2d *regPtr)
{
  BarGraph* barGraphPtr_ = (BarGraph*)graphPtr_;
  BarElementOptions* ops = (BarElementOptions*)ops_;
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;

  regPtr->top = regPtr->left = DBL_MAX;
  regPtr->bottom = regPtr->right = -DBL_MAX;

  if (!ops->coords.x || !ops->coords.y ||
      !ops->coords.x->nValues() || !ops->coords.y->nValues())
    return;

  int nPoints = NUMBEROFPOINTS(ops);

  double barWidth = (ops->barWidth > 0.0) ? ops->barWidth : gops->barWidth;
  double middle = barWidth/2.;
  regPtr->left = ops->coords.x->min() - middle;
  regPtr->right = ops->coords.x->max() + middle;

  regPtr->top = ops->coords.y->min();
  regPtr->bottom = ops->coords.y->max();
  if (regPtr->bottom < gops->baseline)
    regPtr->bottom = gops->baseline;

  // Handle stacked bar elements specially.
  // If element is stacked, the sum of its ordinates may be outside the
  // minimum/maximum limits of the element's data points.
  if (((BarGraph::BarMode)gops->barMode == BarGraph::STACKED) && 
      (barGraphPtr_->nBarGroups_ > 0))
    checkStacks(ops->xAxis, ops->yAxis, &regPtr->top, &regPtr->bottom);

  // Warning: You get what you deserve if the x-axis is logScale
  AxisOptions* axisxops = (AxisOptions*)ops->xAxis->ops();
  AxisOptions* axisyops = (AxisOptions*)ops->yAxis->ops();
  if (axisxops->logScale)
    regPtr->left = FindElemValuesMinimum(ops->coords.x, DBL_MIN) + middle;

  // Fix y-min limits for barchart
  if (axisyops->logScale) {
    if ((regPtr->top <= 0.0) || (regPtr->top > 1.0))
      regPtr->top = 1.0;
  }
  else {
    if (regPtr->top > 0.0)
      regPtr->top = 0.0;
  }

  // Correct the extents for error bars if they exist
  if (ops->xError && (ops->xError->nValues() > 0)) {
    nPoints = MIN(ops->xError->nValues(), nPoints);
    for (int ii=0; ii<nPoints; ii++) {
      double x = ops->coords.x->values_[ii] + ops->xError->values_[ii];
      if (x > regPtr->right)
	regPtr->right = x;

      x = ops->coords.x->values_[ii] - ops->xError->values_[ii];
      if (axisxops->logScale) {
	// Mirror negative values, instead of ignoring them
	if (x < 0.0)
	  x = -x;

	if ((x > DBL_MIN) && (x < regPtr->left))
	  regPtr->left = x;

      } 
      else if (x < regPtr->left)
	regPtr->left = x;
    }		     
  }
  else {
    if ((ops->xHigh) &&
	(ops->xHigh->nValues() > 0) && 
	(ops->xHigh->max() > regPtr->right))
      regPtr->right = ops->xHigh->max();

    if (ops->xLow && (ops->xLow->nValues() > 0)) {
      double left;
      if ((ops->xLow->min() <= 0.0) && (axisxops->logScale))
	left = FindElemValuesMinimum(ops->xLow, DBL_MIN);
      else
	left = ops->xLow->min();

      if (left < regPtr->left)
	regPtr->left = left;
    }
  }

  if (ops->yError && (ops->yError->nValues() > 0)) {
    nPoints = MIN(ops->yError->nValues(), nPoints);

    for (int ii=0; ii<nPoints; ii++) {
      double y = ops->coords.y->values_[ii] + ops->yError->values_[ii];
      if (y > regPtr->bottom)
	regPtr->bottom = y;

      y = ops->coords.y->values_[ii] - ops->yError->values_[ii];
      if (axisyops->logScale) {
	// Mirror negative values, instead of ignoring them
	if (y < 0.0) 
	  y = -y;

	if ((y > DBL_MIN) && (y < regPtr->left))
	  regPtr->top = y;

      }
      else if (y < regPtr->top)
	regPtr->top = y;
    }		     
  }
  else {
    if ((ops->yHigh) &&
	(ops->yHigh->nValues() > 0) && 
	(ops->yHigh->max() > regPtr->bottom))
      regPtr->bottom = ops->yHigh->max();

    if (ops->yLow && ops->yLow->nValues() > 0) {
      double top;
      if ((ops->yLow->min() <= 0.0) && 
	  (axisyops->logScale))
	top = FindElemValuesMinimum(ops->yLow, DBL_MIN);
      else
	top = ops->yLow->min();

      if (top < regPtr->top)
	regPtr->top = top;
    }
  }
}

void BarElement::closest()
{
  BarElementOptions* ops = (BarElementOptions*)ops_;
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;

  ClosestSearch* searchPtr = &gops->search;
  double minDist = searchPtr->dist;
  int imin = 0;
    
  int ii;
  Rectangle* bp;
  for (bp=bars_, ii=0; ii<nBars_; ii++, bp++) {
    if (PointInRectangle(bp, searchPtr->x, searchPtr->y)) {
      imin = barToData_[ii];
      minDist = 0.0;
      break;
    }
    double left = bp->x;
    double top = bp->y;
    double right = (double)(bp->x + bp->width);
    double bottom = (double)(bp->y + bp->height);

    Point2d outline[5];
    outline[4].x = outline[3].x = outline[0].x = left;
    outline[4].y = outline[1].y = outline[0].y = top;
    outline[2].x = outline[1].x = right;
    outline[3].y = outline[2].y = bottom;

    Point2d *pp, *pend;
    for (pp=outline, pend=outline+4; pp<pend; pp++) {
      Point2d t = getProjection(searchPtr->x, searchPtr->y, pp, pp + 1);
      if (t.x > right)
	t.x = right;
      else if (t.x < left)
	t.x = left;

      if (t.y > bottom)
	t.y = bottom;
      else if (t.y < top)
	t.y = top;

      double dist = hypot((t.x - searchPtr->x), (t.y - searchPtr->y));
      if (dist < minDist) {
	minDist = dist;
	imin = barToData_[ii];
      }
    }
  }
  if (minDist < searchPtr->dist) {
    searchPtr->elemPtr = (Element*)this;
    searchPtr->dist = minDist;
    searchPtr->index = imin;
    searchPtr->point.x = 
      ops->coords.x ? (double)ops->coords.x->values_[imin] : 0;
    searchPtr->point.y = 
      ops->coords.y ? (double)ops->coords.y->values_[imin] : 0;
  }
}

void BarElement::draw(Drawable drawable)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  if (ops->hide)
    return;

  int count = 0;
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {

    BarStyle* stylePtr = (BarStyle*)Chain_GetValue(link);
    BarPen* penPtr = (BarPen*)stylePtr->penPtr;
    BarPenOptions* pops = (BarPenOptions*)penPtr->ops();

    if (stylePtr->nBars > 0)
      drawSegments(drawable, penPtr, stylePtr->bars, stylePtr->nBars);

    if ((stylePtr->xeb.length > 0) && (pops->errorBarShow & SHOW_X))
      graphPtr_->drawSegments(drawable, penPtr->errorBarGC_, 
			      stylePtr->xeb.segments, stylePtr->xeb.length);

    if ((stylePtr->yeb.length > 0) && (pops->errorBarShow & SHOW_Y))
      graphPtr_->drawSegments(drawable, penPtr->errorBarGC_, 
			      stylePtr->yeb.segments, stylePtr->yeb.length);

    if (pops->valueShow != SHOW_NONE)
      drawValues(drawable, penPtr, stylePtr->bars, stylePtr->nBars, 
		    barToData_ + count);

    count += stylePtr->nBars;
  }
}

void BarElement::drawActive(Drawable drawable)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  if (ops->hide || !active_)
    return;

  BarPen* penPtr = (BarPen*)ops->activePenPtr;
  if (!penPtr)
    return;
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();

  if (nActiveIndices_ > 0) {
    mapActive();

    drawSegments(drawable, penPtr, activeRects_, nActive_);
    if (pops->valueShow != SHOW_NONE)
      drawValues(drawable, penPtr, activeRects_, nActive_, activeToData_);
  }
  else if (nActiveIndices_ < 0) {
    drawSegments(drawable, penPtr, bars_, nBars_);
    if (pops->valueShow != SHOW_NONE)
      drawValues(drawable, penPtr, bars_, nBars_, barToData_);
  }
}

void BarElement::drawSymbol(Drawable drawable, int x, int y, int size)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  BarPen* penPtr = NORMALPEN(ops);
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();

  int radius = (size / 2);
  size--;

  x -= radius;
  y -= radius;

  Tk_Fill3DRectangle(graphPtr_->tkwin_, drawable, 
		     pops->fill, x, y, size, size, 
		     pops->borderWidth, pops->relief);

  if (pops->outlineColor)
    XDrawRectangle(graphPtr_->display_, drawable, penPtr->outlineGC_,
		   x, y, size, size);
}

void BarElement::print(PSOutput* psPtr)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;
  
  if (ops->hide)
    return;

  psPtr->format("\n%% Element \"%s\"\n\n", name_);

  int count = 0;
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {

    BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
    BarPen* penPtr = (BarPen*)stylePtr->penPtr;
    BarPenOptions* pops = (BarPenOptions*)penPtr->ops();

    if (stylePtr->nBars > 0)
      printSegments(psPtr, penPtr, stylePtr->bars, stylePtr->nBars);

    XColor* colorPtr = pops->errorBarColor;
    if (!colorPtr)
      colorPtr = pops->outlineColor;
    if (!colorPtr)
      colorPtr = Tk_3DBorderColor(pops->fill);

    if ((stylePtr->xeb.length > 0) && (pops->errorBarShow & SHOW_X)) {
      psPtr->setLineAttributes(colorPtr, pops->errorBarLineWidth, 
			       NULL, CapButt, JoinMiter);
      psPtr->printSegments(stylePtr->xeb.segments, stylePtr->xeb.length);
    }

    if ((stylePtr->yeb.length > 0) && (pops->errorBarShow & SHOW_Y)) {
      psPtr->setLineAttributes(colorPtr, pops->errorBarLineWidth, 
			       NULL, CapButt, JoinMiter);
      psPtr->printSegments(stylePtr->yeb.segments, stylePtr->yeb.length);
    }

    if (pops->valueShow != SHOW_NONE)
      printValues(psPtr, penPtr, stylePtr->bars, stylePtr->nBars, 
			    barToData_ + count);

    count += stylePtr->nBars;
  }
}

void BarElement::printActive(PSOutput* psPtr)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  if (ops->hide || !active_)
    return;

  BarPen* penPtr = (BarPen*)ops->activePenPtr;
  if (!penPtr)
    return;
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
	
  psPtr->format("\n%% Active Element \"%s\"\n\n", name_);

  if (nActiveIndices_ > 0) {
    mapActive();

    printSegments(psPtr, penPtr, activeRects_, nActive_);
    if (pops->valueShow != SHOW_NONE)
      printValues(psPtr, penPtr, activeRects_, nActive_,activeToData_);
  }
  else if (nActiveIndices_ < 0) {
    printSegments(psPtr, penPtr, bars_, nBars_);
    if (pops->valueShow != SHOW_NONE)
      printValues(psPtr, penPtr, bars_, nBars_, barToData_);
  }
}

void BarElement::printSymbol(PSOutput* psPtr, double x, double y, int size)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  BarPen* penPtr = NORMALPEN(ops);
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();

  x -= size/2.;
  y -= size/2.;

  psPtr->fill3DRectangle(pops->fill, x, y, size, size,
			 pops->borderWidth, pops->relief);

  if (pops->outlineColor) {
    psPtr->setForeground(pops->outlineColor);
    psPtr->printRectangle(x, y, size, size);
  }
}

// Support

void BarElement::ResetStylePalette(Chain* stylePalette)
{
  for (ChainLink* link = Chain_FirstLink(stylePalette); link; 
       link = Chain_NextLink(link)) {
    BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
    stylePtr->xeb.length = 0;
    stylePtr->yeb.length = 0;
    stylePtr->nBars = 0;
  }
}

void BarElement::checkStacks(Axis* xAxis, Axis* yAxis, 
			     double* minPtr, double* maxPtr)
{
  BarGraph* barGraphPtr_ = (BarGraph*)graphPtr_;
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;
  if (((BarGraph::BarMode)gops->barMode != BarGraph::STACKED) || 
      barGraphPtr_->nBarGroups_ == 0)
    return;

  for (BarGroup *gp = barGraphPtr_->barGroups_, 
	 *gend = gp + barGraphPtr_->nBarGroups_; gp < gend; gp++) {
    if ((gp->xAxis == xAxis) && (gp->yAxis == yAxis)) {

      // Check if any of the y-values (because of stacking) are greater
      // than the current limits of the graph.
      if (gp->sum < 0.0) {
	if (*minPtr > gp->sum)
	  *minPtr = gp->sum;
      }
      else {
	if (*maxPtr < gp->sum)
	  *maxPtr = gp->sum;
      }
    }
  }
}

void BarElement::mergePens(BarStyle** dataToStyle)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  if (Chain_GetLength(ops->stylePalette) < 2) {
    ChainLink* link = Chain_FirstLink(ops->stylePalette);
    BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
    stylePtr->nBars = nBars_;
    stylePtr->bars = bars_;
    stylePtr->symbolSize = bars_->width / 2;
    stylePtr->xeb.length = xeb_.length;
    stylePtr->xeb.segments = xeb_.segments;
    stylePtr->yeb.length = yeb_.length;
    stylePtr->yeb.segments = yeb_.segments;
    return;
  }

  // We have more than one style. Group bar segments of like pen styles together
  if (nBars_ > 0) {
    Rectangle* bars = new Rectangle[nBars_];
    int* barToData = new int[nBars_];
    Rectangle* bp = bars;
    int* ip = barToData;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link; 
	 link = Chain_NextLink(link)) {
      BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
      stylePtr->symbolSize = bp->width / 2;
      stylePtr->bars = bp;
      for (int ii=0; ii<nBars_; ii++) {
	int iData = barToData[ii];
	if (dataToStyle[iData] == stylePtr) {
	  *bp++ = bars[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->nBars = bp - stylePtr->bars;
    }
    delete [] bars_;
    bars_ = bars;
    delete [] barToData_;
    barToData_ = barToData;
  }

  if (xeb_.length > 0) {
    Segment2d* bars = new Segment2d[xeb_.length];
    Segment2d *sp = bars;
    int* map = new int[xeb_.length];
    int* ip = map;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
      stylePtr->xeb.segments = sp;
      for (int ii=0; ii<xeb_.length; ii++) {
	int iData = xeb_.map[ii];
	if (dataToStyle[iData] == stylePtr) {
	  *sp++ = xeb_.segments[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->xeb.length = sp - stylePtr->xeb.segments;
    }
    delete [] xeb_.segments;
    xeb_.segments = bars;
    delete [] xeb_.map;
    xeb_.map = map;
  }

  if (yeb_.length > 0) {
    Segment2d* bars = new Segment2d[yeb_.length];
    Segment2d* sp = bars;
    int* map = new int[yeb_.length];
    int* ip = map;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link; 
	 link = Chain_NextLink(link)) {
      BarStyle *stylePtr = (BarStyle*)Chain_GetValue(link);
      stylePtr->yeb.segments = sp;
      for (int ii=0; ii<yeb_.length; ii++) {
	int iData = yeb_.map[ii];
	if (dataToStyle[iData] == stylePtr) {
	  *sp++ = yeb_.segments[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->yeb.length = sp - stylePtr->yeb.segments;
    }
    delete [] yeb_.segments;
    yeb_.segments = bars;
    delete [] yeb_.map;
    yeb_.map = map;
  }
}

void BarElement::mapActive()
{
  delete [] activeRects_;
  activeRects_ = NULL;

  delete [] activeToData_;
  activeToData_ = NULL;

  nActive_ = 0;

  if (nActiveIndices_ > 0) {
    Rectangle* activeRects = new Rectangle[nActiveIndices_];
    int* activeToData = new int[nActiveIndices_];
    int count = 0;
    for (int ii=0; ii<nBars_; ii++) {
      for (int *ip = activeIndices_, *iend = ip + nActiveIndices_;
	   ip < iend; ip++) {
	if (barToData_[ii] == *ip) {
	  activeRects[count] = bars_[ii];
	  activeToData[count] = ii;
	  count++;
	}
      }
    }
    nActive_ = count;
    activeRects_ = activeRects;
    activeToData_ = activeToData;
  }
}

void BarElement::reset()
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  ResetStylePalette(ops->stylePalette);

  delete [] activeRects_;
  activeRects_ = NULL;
  delete [] activeToData_;
  activeToData_ = NULL;

  delete [] xeb_.segments;
  xeb_.segments = NULL;
  delete [] xeb_.map;
  xeb_.map = NULL;
  xeb_.length = 0;

  delete [] yeb_.segments;
  yeb_.segments = NULL;
  delete [] yeb_.map;
  yeb_.map = NULL;
  yeb_.length = 0;

  delete [] bars_;
  bars_ = NULL;
  delete [] barToData_;
  barToData_ = NULL;

  nActive_ = 0;
  nBars_ = 0;
}

void BarElement::mapErrorBars(BarStyle **dataToStyle)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;

  Region2d reg;
  graphPtr_->extents(&reg);

  int nPoints = NUMBEROFPOINTS(ops);
  int nn =0;
  if (ops->coords.x && ops->coords.y) {
    if (ops->xError && (ops->xError->nValues() > 0))
      nn = MIN(ops->xError->nValues(), nPoints);
    else
      if (ops->xHigh && ops->xLow)
	nn = MIN3(ops->xHigh->nValues(), ops->xLow->nValues(), nPoints);
  }

  if (nn) {
    Segment2d* bars = new Segment2d[nn * 3];
    Segment2d* segPtr = bars;
    int* map = new int[nn * 3];
    int* indexPtr = map;

    for (int ii=0; ii<nn; ii++) {
      double x = ops->coords.x->values_[ii];
      double y = ops->coords.y->values_[ii];
      BarStyle* stylePtr = dataToStyle[ii];

      if ((isfinite(x)) && (isfinite(y))) {
	double high, low;
	if (ops->xError->nValues() > 0) {
	  high = x + ops->xError->values_[ii];
	  low = x - ops->xError->values_[ii];
	}
	else {
	  high = ops->xHigh ? ops->xHigh->values_[ii] : 0;
	  low  = ops->xLow  ? ops->xLow->values_[ii]  : 0;
	}
	if ((isfinite(high)) && (isfinite(low)))  {
	  Point2d p = graphPtr_->map2D(high, y, ops->xAxis, ops->yAxis);
	  Point2d q = graphPtr_->map2D(low, y, ops->xAxis, ops->yAxis);
	  segPtr->p = p;
	  segPtr->q = q;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Left cap
	  segPtr->p.x = p.x;
	  segPtr->q.x = p.x;
	  segPtr->p.y = p.y - stylePtr->errorBarCapWidth;
	  segPtr->q.y = p.y + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Right cap
	  segPtr->p.x = q.x;
	  segPtr->q.x = q.x;
	  segPtr->p.y = q.y - stylePtr->errorBarCapWidth;
	  segPtr->q.y = q.y + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	}
      }
    }
    xeb_.segments = bars;
    xeb_.length = segPtr - bars;
    xeb_.map = map;
  }

  nn =0;
  if (ops->coords.x && ops->coords.y) {
    if (ops->yError && (ops->yError->nValues() > 0))
      nn = MIN(ops->yError->nValues(), nPoints);
    else
      if (ops->yHigh && ops->yLow)
	nn = MIN3(ops->yHigh->nValues(), ops->yLow->nValues(), nPoints);
  }

  if (nn) {
    Segment2d* bars = new Segment2d[nn * 3];
    Segment2d* segPtr = bars;
    int* map = new int[nn * 3];
    int* indexPtr = map;

    for (int ii=0; ii<nn; ii++) {
      double x = ops->coords.x->values_[ii];
      double y = ops->coords.y->values_[ii];
      BarStyle *stylePtr = dataToStyle[ii];

      if ((isfinite(x)) && (isfinite(y))) {
      double high, low;
	if (ops->yError->nValues() > 0) {
	  high = y + ops->yError->values_[ii];
	  low = y - ops->yError->values_[ii];
	}
	else {
	  high = ops->yHigh->values_[ii];
	  low = ops->yLow->values_[ii];
	}
	if ((isfinite(high)) && (isfinite(low)))  {
	  Point2d p = graphPtr_->map2D(x, high, ops->xAxis, ops->yAxis);
	  Point2d q = graphPtr_->map2D(x, low, ops->xAxis, ops->yAxis);
	  segPtr->p = p;
	  segPtr->q = q;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Top cap
	  segPtr->p.y = p.y;
	  segPtr->q.y = p.y;
	  segPtr->p.x = p.x - stylePtr->errorBarCapWidth;
	  segPtr->q.x = p.x + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Bottom cap
	  segPtr->p.y = q.y;
	  segPtr->q.y = q.y;
	  segPtr->p.x = q.x - stylePtr->errorBarCapWidth;
	  segPtr->q.x = q.x + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&reg, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	}
      }
    }
    yeb_.segments = bars;
    yeb_.length = segPtr - bars;
    yeb_.map = map;
  }
}

void BarElement::drawSegments(Drawable drawable, BarPen* penPtr,
				 Rectangle *bars, int nBars)
{
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
  for (Rectangle *rp = bars, *rend = rp + nBars; rp < rend; rp++) {
    if ((rp->width < 1) || (rp->height < 1))
      continue;

    Tk_Fill3DRectangle(graphPtr_->tkwin_, drawable, 
		       pops->fill, rp->x, rp->y, rp->width, rp->height, 
		       pops->borderWidth, pops->relief);

    if (pops->outlineColor)
      XDrawRectangle(graphPtr_->display_, drawable, penPtr->outlineGC_, 
		     rp->x, rp->y, rp->width, rp->height);
  }
}

void BarElement::drawValues(Drawable drawable, BarPen* penPtr, 
			       Rectangle *bars, int nBars, int *barToData)
{
  BarElementOptions* ops = (BarElementOptions*)ops_;
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;

  const char *fmt = pops->valueFormat;
  if (!fmt)
    fmt = "%g";
  TextStyle ts(graphPtr_, &pops->valueStyle);

  int count = 0;
  for (Rectangle *rp = bars, *rend = rp + nBars; rp < rend; rp++) {
    Point2d anchorPos;
    char string[TCL_DOUBLE_SPACE * 2 + 2];

    double x = ops->coords.x->values_[barToData[count]];
    double y = ops->coords.y->values_[barToData[count]];

    count++;
    if (pops->valueShow == SHOW_X)
      snprintf(string, TCL_DOUBLE_SPACE, fmt, x); 
    else if (pops->valueShow == SHOW_Y)
      snprintf(string, TCL_DOUBLE_SPACE, fmt, y); 
    else if (pops->valueShow == SHOW_BOTH) {
      snprintf(string, TCL_DOUBLE_SPACE, fmt, x);
      strcat(string, ",");
      snprintf(string + strlen(string), TCL_DOUBLE_SPACE, fmt, y);
    }

    if (gops->inverted) {
      anchorPos.y = rp->y + rp->height * 0.5;
      anchorPos.x = rp->x + rp->width;
      if (x < gops->baseline)
	anchorPos.x -= rp->width;
    }
    else {
      anchorPos.x = rp->x + rp->width * 0.5;
      anchorPos.y = rp->y;
      if (y < gops->baseline)
	anchorPos.y += rp->height;
    }

    ts.drawText(drawable, string, anchorPos.x, anchorPos.y);
  }
}

void BarElement::printSegments(PSOutput* psPtr, BarPen* penPtr, 
			       Rectangle *bars, int nBars)
{
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
  for (Rectangle *rp = bars, *rend = rp + nBars; rp < rend; rp++) {
    if ((rp->width < 1) || (rp->height < 1))
      continue;

    psPtr->fill3DRectangle(pops->fill, (double)rp->x, (double)rp->y,
			   rp->width, rp->height,
			   pops->borderWidth, pops->relief);

    if (pops->outlineColor) {
      psPtr->setForeground(pops->outlineColor);
      psPtr->printRectangle((double)rp->x, (double)rp->y, rp->width, rp->height);
    }
  }
}

void BarElement::printValues(PSOutput* psPtr, BarPen* penPtr, 
			     Rectangle *bars, int nBars, int *barToData)
{
  BarPenOptions* pops = (BarPenOptions*)penPtr->ops();
  BarElementOptions* ops = (BarElementOptions*)ops_;
  BarGraphOptions* gops = (BarGraphOptions*)graphPtr_->ops_;

  int count = 0;
  const char* fmt = pops->valueFormat;
  if (!fmt)
    fmt = "%g";
  TextStyle ts(graphPtr_, &pops->valueStyle);

  for (Rectangle *rp = bars, *rend = rp + nBars; rp < rend; rp++) {
    double x = ops->coords.x->values_[barToData[count]];
    double y = ops->coords.y->values_[barToData[count]];

    count++;
    char string[TCL_DOUBLE_SPACE * 2 + 2];
    if (pops->valueShow == SHOW_X)
      snprintf(string, TCL_DOUBLE_SPACE, fmt, x); 
    else if (pops->valueShow == SHOW_Y)
      snprintf(string, TCL_DOUBLE_SPACE, fmt, y); 
    else if (pops->valueShow == SHOW_BOTH) {
      snprintf(string, TCL_DOUBLE_SPACE, fmt, x);
      strcat(string, ",");
      snprintf(string + strlen(string), TCL_DOUBLE_SPACE, fmt, y);
    }

    Point2d anchorPos;
    if (gops->inverted) {
      anchorPos.y = rp->y + rp->height * 0.5;
      anchorPos.x = rp->x + rp->width;
      if (x < gops->baseline)
	anchorPos.x -= rp->width;
    }
    else {
      anchorPos.x = rp->x + rp->width * 0.5;
      anchorPos.y = rp->y;
      if (y < gops->baseline)
	anchorPos.y += rp->height;
    }

    ts.printText(psPtr, string, anchorPos.x, anchorPos.y);
  }
}

