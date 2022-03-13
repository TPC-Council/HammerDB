/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright (c) 1993 George A Howlett.
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

#include "tkbltGraph.h"
#include "tkbltGrElemLine.h"
#include "tkbltGrElemOption.h"
#include "tkbltGrAxis.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"
#include "tkbltInt.h"

using namespace Blt;

#define SEARCH_X	0
#define SEARCH_Y	1
#define SEARCH_BOTH	2

#define SEARCH_POINTS	0	// closest data point.
#define SEARCH_TRACES	1	// closest point on trace.
#define SEARCH_AUTO	2	// traces if linewidth is > 0 and more than one

#define MIN3(a,b,c)	(((a)<(b))?(((a)<(c))?(a):(c)):(((b)<(c))?(b):(c)))
#define PointInRegion(e,x,y) (((x) <= (e)->right) && ((x) >= (e)->left) && ((y) <= (e)->bottom) && ((y) >= (e)->top))

#define BROKEN_TRACE(dir,last,next) (((dir == INCREASING)&&(next < last)) || ((dir == DECREASING)&&(next > last)))
#define DRAW_SYMBOL() (symbolInterval_==0||(symbolCounter_%symbolInterval_)==0)

static const char* symbolMacros[] =
  {"Li", "Sq", "Ci", "Di", "Pl", "Cr", "Sp", "Sc", "Tr", "Ar", "Bm", NULL};

// OptionSpecs

static const char* smoothObjOption[] = 
  {"linear", "step", "cubic", "quadratic", "catrom", NULL};

static const char* penDirObjOption[] = 
  {"increasing", "decreasing", "both", NULL};

static Tk_ObjCustomOption styleObjOption =
  {
    "styles", StyleSetProc, StyleGetProc, StyleRestoreProc, StyleFreeProc, 
    (ClientData)sizeof(LineStyle)
  };

extern Tk_ObjCustomOption penObjOption;
extern Tk_ObjCustomOption pairsObjOption;
extern Tk_ObjCustomOption valuesObjOption;
extern Tk_ObjCustomOption xAxisObjOption;
extern Tk_ObjCustomOption yAxisObjOption;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_CUSTOM, "-activepen", "activePen", "ActivePen",
   "active", -1, Tk_Offset(LineElementOptions, activePenPtr), 
   TK_OPTION_NULL_OK, &penObjOption, LAYOUT},
  {TK_OPTION_BORDER, "-areabackground", "areaBackground", "AreaBackground",
   NULL, -1, Tk_Offset(LineElementOptions, fillBg), 
   TK_OPTION_NULL_OK, NULL, LAYOUT},
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags", 
   "all", -1, Tk_Offset(LineElementOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_COLOR, "-color", "color", "Color", 
   STD_NORMAL_FOREGROUND, -1, 
   Tk_Offset(LineElementOptions, builtinPen.traceColor), 0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-dashes", "dashes", "Dashes", 
   NULL, -1, Tk_Offset(LineElementOptions, builtinPen.traceDashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, CACHE},
  {TK_OPTION_CUSTOM, "-data", "data", "Data", 
   NULL, -1, Tk_Offset(LineElementOptions, coords),
   TK_OPTION_NULL_OK, &pairsObjOption, RESET},
  {TK_OPTION_COLOR, "-errorbarcolor", "errorBarColor", "ErrorBarColor",
   NULL, -1, Tk_Offset(LineElementOptions, builtinPen.errorBarColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS,"-errorbarwidth", "errorBarWidth", "ErrorBarWidth",
   "1", -1, Tk_Offset(LineElementOptions, builtinPen.errorBarLineWidth),
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarcap", "errorBarCap", "ErrorBarCap", 
   "0", -1, Tk_Offset(LineElementOptions, builtinPen.errorBarCapWidth),
   0, NULL, LAYOUT},
  {TK_OPTION_COLOR, "-fill", "fill", "Fill", 
   NULL, -1, Tk_Offset(LineElementOptions, builtinPen.symbol.fillColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(LineElementOptions, hide), 0, NULL, LAYOUT},
  {TK_OPTION_STRING, "-label", "label", "Label", 
   NULL, -1, Tk_Offset(LineElementOptions, label), 
   TK_OPTION_NULL_OK | TK_OPTION_DONT_SET_DEFAULT, NULL, LAYOUT},
  {TK_OPTION_RELIEF, "-legendrelief", "legendRelief", "LegendRelief",
   "flat", -1, Tk_Offset(LineElementOptions, legendRelief), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "LineWidth",
   "1", -1, Tk_Offset(LineElementOptions, builtinPen.traceWidth),
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-mapx", "mapX", "MapX",
   "x", -1, Tk_Offset(LineElementOptions, xAxis), 0, &xAxisObjOption, RESET},
  {TK_OPTION_CUSTOM, "-mapy", "mapY", "MapY",
   "y", -1, Tk_Offset(LineElementOptions, yAxis), 0, &yAxisObjOption, RESET},
  {TK_OPTION_INT, "-maxsymbols", "maxSymbols", "MaxSymbols",
   "0", -1, Tk_Offset(LineElementOptions, reqMaxSymbols), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-offdash", "offDash", "OffDash", 
   NULL, -1, Tk_Offset(LineElementOptions, builtinPen.traceOffColor),
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline", 
   NULL, -1, Tk_Offset(LineElementOptions, builtinPen.symbol.outlineColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-outlinewidth", "outlineWidth", "OutlineWidth",
   "1", -1, Tk_Offset(LineElementOptions, builtinPen.symbol.outlineWidth),
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-pen", "pen", "Pen",
   NULL, -1, Tk_Offset(LineElementOptions, normalPenPtr), 
   TK_OPTION_NULL_OK, &penObjOption, LAYOUT},
  {TK_OPTION_PIXELS, "-pixels", "pixels", "Pixels", 
   "0.1i", -1, Tk_Offset(LineElementOptions, builtinPen.symbol.size), 
   0, NULL, LAYOUT},
  {TK_OPTION_DOUBLE, "-reduce", "reduce", "Reduce",
   "0", -1, Tk_Offset(LineElementOptions, rTolerance), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-scalesymbols", "scaleSymbols", "ScaleSymbols",
   "yes", -1, Tk_Offset(LineElementOptions, scaleSymbols), 0, NULL, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showerrorbars", "showErrorBars", "ShowErrorBars",
   "both", -1, Tk_Offset(LineElementOptions, builtinPen.errorBarShow), 
   0, &fillObjOption, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showvalues", "showValues", "ShowValues",
   "none", -1, Tk_Offset(LineElementOptions, builtinPen.valueShow), 
   0, &fillObjOption, CACHE},
  {TK_OPTION_STRING_TABLE, "-smooth", "smooth", "Smooth", 
   "linear", -1, Tk_Offset(LineElementOptions, reqSmooth), 
   0, &smoothObjOption, LAYOUT},
  {TK_OPTION_CUSTOM, "-styles", "styles", "Styles",
   "", -1, Tk_Offset(LineElementOptions, stylePalette), 
   0, &styleObjOption, RESET},
  {TK_OPTION_STRING_TABLE, "-symbol", "symbol", "Symbol",
   "none", -1, Tk_Offset(LineElementOptions, builtinPen.symbol), 
   0, &symbolObjOption, CACHE},
  {TK_OPTION_STRING_TABLE, "-trace", "trace", "Trace",
   "both", -1, Tk_Offset(LineElementOptions, penDir), 
   0, &penDirObjOption, RESET},
  {TK_OPTION_ANCHOR, "-valueanchor", "valueAnchor", "ValueAnchor",
   "s", -1, Tk_Offset(LineElementOptions, builtinPen.valueStyle.anchor),
   0, NULL, CACHE},
  {TK_OPTION_COLOR, "-valuecolor", "valueColor", "ValueColor",
   STD_NORMAL_FOREGROUND,-1,
   Tk_Offset(LineElementOptions, builtinPen.valueStyle.color),
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-valuefont", "valueFont", "ValueFont",
   STD_FONT_SMALL, -1, 
   Tk_Offset(LineElementOptions, builtinPen.valueStyle.font),
   0, NULL, CACHE},
  {TK_OPTION_STRING, "-valueformat", "valueFormat", "ValueFormat",
   "%g", -1, Tk_Offset(LineElementOptions, builtinPen.valueFormat), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-valuerotate", "valueRotate", "ValueRotate",
   "0", -1, Tk_Offset(LineElementOptions, builtinPen.valueStyle.angle),
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-weights", "weights", "Weights",
   NULL, -1, Tk_Offset(LineElementOptions, w), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_SYNONYM, "-x", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-xdata", 0},
  {TK_OPTION_CUSTOM, "-xdata", "xData", "XData", 
   NULL, -1, Tk_Offset(LineElementOptions, coords.x), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xerror", "xError", "XError", 
   NULL, -1, Tk_Offset(LineElementOptions, xError), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xhigh", "xHigh", "XHigh", 
   NULL, -1, Tk_Offset(LineElementOptions, xHigh), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-xlow", "xLow", "XLow", 
   NULL, -1, Tk_Offset(LineElementOptions, xLow), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_SYNONYM, "-y", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-ydata", 0},
  {TK_OPTION_CUSTOM, "-ydata", "yData", "YData", 
   NULL, -1, Tk_Offset(LineElementOptions, coords.y), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-yerror", "yError", "YError", 
   NULL, -1, Tk_Offset(LineElementOptions, yError), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-yhigh", "yHigh", "YHigh",
   NULL, -1, Tk_Offset(LineElementOptions, yHigh), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_CUSTOM, "-ylow", "yLow", "YLow", 
   NULL, -1, Tk_Offset(LineElementOptions, yLow), 
   TK_OPTION_NULL_OK, &valuesObjOption, RESET},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

LineElement::LineElement(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
  : Element(graphPtr, name, hPtr)
{
  smooth_ = LINEAR;
  fillPts_ =NULL;
  nFillPts_ = 0;

  symbolPts_.points =NULL;
  symbolPts_.length =0;
  symbolPts_.map =NULL;
  activePts_.points =NULL;
  activePts_.length =0;
  activePts_.map =NULL;

  xeb_.segments =NULL;
  xeb_.map =NULL;
  xeb_.length =0;
  yeb_.segments =NULL;
  yeb_.map =NULL;
  yeb_.length =0;

  symbolInterval_ =0;
  symbolCounter_ =0;
  traces_ =NULL;

  ops_ = (LineElementOptions*)calloc(1, sizeof(LineElementOptions));
  LineElementOptions* ops = (LineElementOptions*)ops_;
  ops->elemPtr = (Element*)this;

  builtinPenPtr = new LinePen(graphPtr, "builtin", &ops->builtinPen);
  ops->builtinPenPtr = builtinPenPtr;

  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);

  ops->stylePalette = new Chain();
  // this is an option and will be freed via Tk_FreeConfigOptions
  // By default an element's name and label are the same
  ops->label = Tcl_Alloc(strlen(name)+1);
  if (name)
    strcpy((char*)ops->label,(char*)name);

  Tk_InitOptions(graphPtr->interp_, (char*)&(ops->builtinPen),
		 builtinPenPtr->optionTable(), graphPtr->tkwin_);
}

LineElement::~LineElement()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  delete builtinPenPtr;

  reset();

  if (ops->stylePalette) {
    freeStylePalette(ops->stylePalette);
    delete ops->stylePalette;
  }

  delete [] fillPts_;
}

int LineElement::configure()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  if (builtinPenPtr->configure() != TCL_OK)
    return TCL_ERROR;

  // Point to the static normal/active pens if no external pens have been
  // selected.
  ChainLink* link = Chain_FirstLink(ops->stylePalette);
  if (!link) {
    link = new ChainLink(sizeof(LineStyle));
    ops->stylePalette->linkAfter(link, NULL);
  } 
  LineStyle* stylePtr = (LineStyle*)Chain_GetValue(link);
  stylePtr->penPtr = NORMALPEN(ops);

  return TCL_OK;
}

void LineElement::map()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
    
  if (!link)
    return;

  reset();
  if (!ops->coords.x || !ops->coords.y ||
      !ops->coords.x->nValues() || !ops->coords.y->nValues())
    return;

  MapInfo mi;
  getScreenPoints(&mi);
  mapSymbols(&mi);

  if (nActiveIndices_ > 0)
    mapActiveSymbols();

  // Map connecting line segments if they are to be displayed.
  smooth_ = (Smoothing)ops->reqSmooth;
  if ((mi.nScreenPts > 1) && (ops->builtinPen.traceWidth > 0)) {
    // Do smoothing if necessary.  This can extend the coordinate array,
    // so both mi.points and mi.nPoints may change.
    switch (smooth_) {
    case STEP:
      generateSteps(&mi);
      break;

    case CUBIC:
    case QUADRATIC:
      // Can't interpolate with less than three points
      if (mi.nScreenPts < 3)
	smooth_ = LINEAR;
      else
	generateSpline(&mi);
      break;

    case CATROM:
      // Can't interpolate with less than three points
      if (mi.nScreenPts < 3)
	smooth_ = LINEAR;
      else
	generateParametricSpline(&mi);
      break;

    default:
      break;
    }
    if (ops->rTolerance > 0.0)
      reducePoints(&mi, ops->rTolerance);

    if (ops->fillBg)
      mapFillArea(&mi);

    mapTraces(&mi);
  }
  delete [] mi.screenPts;
  delete [] mi.map;

  // Set the symbol size of all the pen styles
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    LineStyle* stylePtr = (LineStyle*)Chain_GetValue(link);
    LinePen* penPtr = (LinePen *)stylePtr->penPtr;
    LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();
    int size = scaleSymbol(penOps->symbol.size);
    stylePtr->symbolSize = size;
    stylePtr->errorBarCapWidth = penOps->errorBarCapWidth;
  }

  LineStyle** styleMap = (LineStyle**)StyleMap();
  if (((ops->yHigh && ops->yHigh->nValues() > 0) &&
       (ops->yLow && ops->yLow->nValues() > 0)) ||
      ((ops->xHigh && ops->xHigh->nValues() > 0) &&
       (ops->xLow && ops->xLow->nValues() > 0)) ||
      (ops->xError && ops->xError->nValues() > 0) ||
      (ops->yError && ops->yError->nValues() > 0)) {
    mapErrorBars(styleMap);
  }

  mergePens(styleMap);
  delete [] styleMap;
}

void LineElement::extents(Region2d *extsPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  extsPtr->top = extsPtr->left = DBL_MAX;
  extsPtr->bottom = extsPtr->right = -DBL_MAX;

  if (!ops->coords.x || !ops->coords.y ||
      !ops->coords.x->nValues() || !ops->coords.y->nValues())
    return;
  int np = NUMBEROFPOINTS(ops);

  extsPtr->right = ops->coords.x->max();
  AxisOptions* axisxops = (AxisOptions*)ops->xAxis->ops();
  if ((ops->coords.x->min() <= 0.0) && (axisxops->logScale))
    extsPtr->left = FindElemValuesMinimum(ops->coords.x, DBL_MIN);
  else
    extsPtr->left = ops->coords.x->min();

  extsPtr->bottom = ops->coords.y->max();
  AxisOptions* axisyops = (AxisOptions*)ops->yAxis->ops();
  if ((ops->coords.y->min() <= 0.0) && (axisyops->logScale))
    extsPtr->top = FindElemValuesMinimum(ops->coords.y, DBL_MIN);
  else
    extsPtr->top = ops->coords.y->min();

  // Correct the data limits for error bars
  if (ops->xError && ops->xError->nValues() > 0) {
    np = MIN(ops->xError->nValues(), np);
    for (int ii=0; ii<np; ii++) {
      double x = ops->coords.x->values_[ii] + ops->xError->values_[ii];
      if (x > extsPtr->right)
	extsPtr->right = x;

      x = ops->coords.x->values_[ii] - ops->xError->values_[ii];
      AxisOptions* axisxops = (AxisOptions*)ops->xAxis->ops();
      if (axisxops->logScale) {
	// Mirror negative values, instead of ignoring them
	if (x < 0.0)
	  x = -x;
	if ((x > DBL_MIN) && (x < extsPtr->left))
	  extsPtr->left = x;
      } 
      else if (x < extsPtr->left)
	extsPtr->left = x;
    }		     
  }
  else {
    if (ops->xHigh && 
	(ops->xHigh->nValues() > 0) && 
	(ops->xHigh->max() > extsPtr->right)) {
      extsPtr->right = ops->xHigh->max();
    }
    if (ops->xLow && ops->xLow->nValues() > 0) {
      double left;
      if ((ops->xLow->min() <= 0.0) && (axisxops->logScale))
	left = FindElemValuesMinimum(ops->xLow, DBL_MIN);
      else
	left = ops->xLow->min();

      if (left < extsPtr->left)
	extsPtr->left = left;
    }
  }
    
  if (ops->yError && ops->yError->nValues() > 0) {
    np = MIN(ops->yError->nValues(), np);
    for (int ii=0; ii<np; ii++) {
      double y = ops->coords.y->values_[ii] + ops->yError->values_[ii];
      if (y > extsPtr->bottom)
	extsPtr->bottom = y;

      y = ops->coords.y->values_[ii] - ops->yError->values_[ii];
      AxisOptions* axisyops = (AxisOptions*)ops->yAxis->ops();
      if (axisyops->logScale) {
	// Mirror negative values, instead of ignoring them
	if (y < 0.0)
	  y = -y;
	if ((y > DBL_MIN) && (y < extsPtr->left))
	  extsPtr->top = y;
      }
      else if (y < extsPtr->top)
	extsPtr->top = y;
    }
  }
  else {
    if (ops->yHigh && (ops->yHigh->nValues() > 0) && 
	(ops->yHigh->max() > extsPtr->bottom))
      extsPtr->bottom = ops->yHigh->max();

    if (ops->yLow && ops->yLow->nValues() > 0) {
      double top;
      if ((ops->yLow->min() <= 0.0) && (axisyops->logScale))
	top = FindElemValuesMinimum(ops->yLow, DBL_MIN);
      else
	top = ops->yLow->min();

      if (top < extsPtr->top)
	extsPtr->top = top;
    }
  }
}

void LineElement::closest()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  ClosestSearch* searchPtr = &gops->search;
  int mode = searchPtr->mode;
  if (mode == SEARCH_AUTO) {
    LinePen* penPtr = NORMALPEN(ops);
    LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();
    mode = SEARCH_POINTS;
    if ((NUMBEROFPOINTS(ops) > 1) && (penOps->traceWidth > 0))
      mode = SEARCH_TRACES;
  }
  if (mode == SEARCH_POINTS)
    closestPoint(searchPtr);
  else {
    int found = closestTrace();
    if ((!found) && (searchPtr->along != SEARCH_BOTH))
      closestPoint(searchPtr);
  }
}

void LineElement::draw(Drawable drawable)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePen* penPtr = NORMALPEN(ops);
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (ops->hide)
    return;

  // Fill area under the curve
  if (ops->fillBg && fillPts_) {
    XPoint*points = new XPoint[nFillPts_];

    unsigned int count =0;
    for (Point2d *pp = fillPts_, *endp = pp + nFillPts_; pp < endp; pp++) {
      points[count].x = (short)pp->x;
      points[count].y = (short)pp->y;
      count++;
    }
    Tk_Fill3DPolygon(graphPtr_->tkwin_, drawable, ops->fillBg, points, 
		     nFillPts_, 0, TK_RELIEF_FLAT);
    delete [] points;
  }

  // Error bars
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    LineStyle* stylePtr = (LineStyle*)Chain_GetValue(link);
    LinePen* penPtr = (LinePen *)stylePtr->penPtr;
    LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

    if ((stylePtr->xeb.length > 0) && (penOps->errorBarShow & SHOW_X))
      graphPtr_->drawSegments(drawable, penPtr->errorBarGC_, 
			      stylePtr->xeb.segments, stylePtr->xeb.length);

    if ((stylePtr->yeb.length > 0) && (penOps->errorBarShow & SHOW_Y))
      graphPtr_->drawSegments(drawable, penPtr->errorBarGC_, 
			      stylePtr->yeb.segments, stylePtr->yeb.length);
  }

  // traces
  if ((Chain_GetLength(traces_) > 0) && (penOps->traceWidth > 0))
    drawTraces(drawable, penPtr);

  // Symbols, values
  if (ops->reqMaxSymbols > 0) {
    int total = 0;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
      total += stylePtr->symbolPts.length;
    }
    symbolInterval_ = total / ops->reqMaxSymbols;
    symbolCounter_ = 0;
  }

  unsigned int count =0;
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    LineStyle* stylePtr = (LineStyle*)Chain_GetValue(link);
    LinePen* penPtr = (LinePen *)stylePtr->penPtr;
    LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

    if ((stylePtr->symbolPts.length > 0) && 
	(penOps->symbol.type != SYMBOL_NONE))
      drawSymbols(drawable, penPtr, stylePtr->symbolSize,
		  stylePtr->symbolPts.length, stylePtr->symbolPts.points);

    if (penOps->valueShow != SHOW_NONE)
      drawValues(drawable, penPtr, stylePtr->symbolPts.length, 
		 stylePtr->symbolPts.points, symbolPts_.map + count);

    count += stylePtr->symbolPts.length;
  }

  symbolInterval_ = 0;
  symbolCounter_ = 0;
}

void LineElement::drawActive(Drawable drawable)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePen* penPtr = (LinePen*)ops->activePenPtr;
  if (!penPtr)
    return;
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (ops->hide || !active_)
    return;

  int symbolSize = scaleSymbol(penOps->symbol.size);

  if (nActiveIndices_ > 0) {
    mapActiveSymbols();

    if (penOps->symbol.type != SYMBOL_NONE)
      drawSymbols(drawable, penPtr, symbolSize, activePts_.length,
		  activePts_.points);
    if (penOps->valueShow != SHOW_NONE)
      drawValues(drawable, penPtr, activePts_.length, activePts_.points, 
		 activePts_.map);
  }
  else if (nActiveIndices_ < 0) { 
    if ((Chain_GetLength(traces_) > 0) && (penOps->traceWidth > 0))
      drawTraces(drawable, penPtr);

    if (penOps->symbol.type != SYMBOL_NONE)
      drawSymbols(drawable, penPtr, symbolSize, symbolPts_.length,
		  symbolPts_.points);

    if (penOps->valueShow != SHOW_NONE) {
      drawValues(drawable, penPtr, symbolPts_.length, symbolPts_.points, 
		 symbolPts_.map);
    }
  }
}

void LineElement::drawSymbol(Drawable drawable, int x, int y, int size)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  LinePen* penPtr = NORMALPEN(ops);
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (penOps->traceWidth > 0) {
    // Draw an extra line offset by one pixel from the previous to give a
    // thicker appearance.  This is only for the legend entry.  This routine
    // is never called for drawing the actual line segments.
    XDrawLine(graphPtr_->display_, drawable, penPtr->traceGC_, x - size, y, 
	      x + size, y);
    XDrawLine(graphPtr_->display_, drawable, penPtr->traceGC_, x - size, y + 1,
	      x + size, y + 1);
  }
  if (penOps->symbol.type != SYMBOL_NONE) {
    Point2d point;
    point.x = x;
    point.y = y;
    drawSymbols(drawable, penPtr, size, 1, &point);
  }
}

void LineElement::print(PSOutput* psPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePen* penPtr = NORMALPEN(ops);
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (ops->hide)
    return;

  psPtr->format("\n%% Element \"%s\"\n\n", name_);

  // Draw fill area
  if (ops->fillBg && fillPts_) {
    psPtr->append("% start fill area\n");
    psPtr->setBackground(ops->fillBg);
    psPtr->printPolyline(fillPts_, nFillPts_);
    psPtr->append("gsave fill grestore\n");
    psPtr->append("% end fill area\n");
  }

  // traces
  if ((Chain_GetLength(traces_) > 0) && (penOps->traceWidth > 0))
    printTraces(psPtr, penPtr);

  // Symbols, error bars, values
  if (ops->reqMaxSymbols > 0) {
    int total = 0;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
      total += stylePtr->symbolPts.length;
    }
    symbolInterval_ = total / ops->reqMaxSymbols;
    symbolCounter_ = 0;
  }

  unsigned int count =0;
  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
    LinePen* penPtr = (LinePen *)stylePtr->penPtr;
    LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();
    XColor* colorPtr = penOps->errorBarColor;
    if (!colorPtr)
      colorPtr = penOps->traceColor;

    if ((stylePtr->xeb.length > 0) && (penOps->errorBarShow & SHOW_X)) {
      psPtr->setLineAttributes(colorPtr, penOps->errorBarLineWidth, 
			       NULL, CapButt, JoinMiter);
      psPtr->printSegments(stylePtr->xeb.segments, stylePtr->xeb.length);
    }

    if ((stylePtr->yeb.length > 0) && (penOps->errorBarShow & SHOW_Y)) {
      psPtr->setLineAttributes(colorPtr, penOps->errorBarLineWidth, 
			       NULL, CapButt, JoinMiter);
      psPtr->printSegments(stylePtr->yeb.segments, stylePtr->yeb.length);
    }

    if ((stylePtr->symbolPts.length > 0) && 
	(penOps->symbol.type != SYMBOL_NONE))
      printSymbols(psPtr, penPtr, stylePtr->symbolSize, 
		   stylePtr->symbolPts.length, stylePtr->symbolPts.points);

    if (penOps->valueShow != SHOW_NONE)
      printValues(psPtr, penPtr, stylePtr->symbolPts.length, 
		  stylePtr->symbolPts.points, symbolPts_.map + count);

    count += stylePtr->symbolPts.length;
  }

  symbolInterval_ = 0;
  symbolCounter_ = 0;
}

void LineElement::printActive(PSOutput* psPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePen* penPtr = (LinePen *)ops->activePenPtr;
  if (!penPtr)
    return;
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (ops->hide || !active_)
    return;

  psPtr->format("\n%% Active Element \"%s\"\n\n", name_);

  int symbolSize = scaleSymbol(penOps->symbol.size);
  if (nActiveIndices_ > 0) {
    mapActiveSymbols();

    if (penOps->symbol.type != SYMBOL_NONE)
      printSymbols(psPtr, penPtr, symbolSize, activePts_.length,
			  activePts_.points);

    if (penOps->valueShow != SHOW_NONE)
      printValues(psPtr, penPtr, activePts_.length, activePts_.points,
		  activePts_.map);
  }
  else if (nActiveIndices_ < 0) {
    if ((Chain_GetLength(traces_) > 0) && (penOps->traceWidth > 0))
      printTraces(psPtr, (LinePen*)penPtr);

    if (penOps->symbol.type != SYMBOL_NONE)
      printSymbols(psPtr, penPtr, symbolSize, symbolPts_.length, 
		   symbolPts_.points);
    if (penOps->valueShow != SHOW_NONE) {
      printValues(psPtr, penPtr, symbolPts_.length, symbolPts_.points,
		  symbolPts_.map);
    }
  }
}

void LineElement::printSymbol(PSOutput* psPtr, double x, double y, int size)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  LinePen* penPtr = NORMALPEN(ops);
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (penOps->traceWidth > 0) {
    // Draw an extra line offset by one pixel from the previous to give a
    // thicker appearance.  This is only for the legend entry.  This routine
    // is never called for drawing the actual line segments.
    psPtr->setLineAttributes(penOps->traceColor, penOps->traceWidth, 
			      &penOps->traceDashes, CapButt, JoinMiter);
    psPtr->format("%g %g %d Li\n", x, y, size + size);
  }

  if (penOps->symbol.type != SYMBOL_NONE) {
    Point2d point;
    point.x = x;
    point.y = y;
    printSymbols(psPtr, penPtr, size, 1, &point);
  }
}

// Support

double LineElement::distanceToLine(int x, int y, Point2d *p, Point2d *q,
				   Point2d *t)
{
  double right, left, top, bottom;

  *t = getProjection(x, y, p, q);
  if (p->x > q->x)
    right = p->x, left = q->x;
  else
    left = p->x, right = q->x;

  if (p->y > q->y)
    bottom = p->y, top = q->y;
  else
    top = p->y, bottom = q->y;

  if (t->x > right)
    t->x = right;
  else if (t->x < left)
    t->x = left;

  if (t->y > bottom)
    t->y = bottom;
  else if (t->y < top)
    t->y = top;

  return hypot((t->x - x), (t->y - y));
}

double LineElement::distanceToX(int x, int y, Point2d *p, Point2d *q, 
				Point2d *t)
{
  double dx, dy;
  double d;

  if (p->x > q->x) {
    if ((x > p->x) || (x < q->x)) {
      return DBL_MAX;		/* X-coordinate outside line segment. */
    }
  } else {
    if ((x > q->x) || (x < p->x)) {
      return DBL_MAX;		/* X-coordinate outside line segment. */
    }
  }
  dx = p->x - q->x;
  dy = p->y - q->y;
  t->x = (double)x;
  if (fabs(dx) < DBL_EPSILON) {
    double d1, d2;
    /* 
     * Same X-coordinate indicates a vertical line.  Pick the closest end
     * point.
     */
    d1 = p->y - y;
    d2 = q->y - y;
    if (fabs(d1) < fabs(d2)) {
      t->y = p->y, d = d1;
    } else {
      t->y = q->y, d = d2;
    }
  }
  else if (fabs(dy) < DBL_EPSILON) {
    /* Horizontal line. */
    t->y = p->y, d = p->y - y;
  }
  else {
    double m = dy / dx;
    double b = p->y - (m * p->x);
    t->y = (x * m) + b;
    d = y - t->y;
  }

  return fabs(d);
}

double LineElement::distanceToY(int x, int y, Point2d *p, Point2d *q,
				Point2d *t)
{
  double dx, dy;
  double d;

  if (p->y > q->y) {
    if ((y > p->y) || (y < q->y)) {
      return DBL_MAX;
    }
  }
  else {
    if ((y > q->y) || (y < p->y)) {
      return DBL_MAX;
    }
  }
  dx = p->x - q->x;
  dy = p->y - q->y;
  t->y = y;
  if (fabs(dy) < DBL_EPSILON) {
    double d1, d2;

    /* Save Y-coordinate indicates an horizontal line. Pick the closest end
     * point. */
    d1 = p->x - x;
    d2 = q->x - x;
    if (fabs(d1) < fabs(d2)) {
      t->x = p->x, d = d1;
    }
    else {
      t->x = q->x, d = d2;
    }
  }
  else if (fabs(dx) < DBL_EPSILON) {
    /* Vertical line. */
    t->x = p->x, d = p->x - x;
  } 
  else {
    double m = dy / dx;
    double b = p->y - (m * p->x);
    t->x = (y - b) / m;
    d = x - t->x;
  }

  return fabs(d);
}

int LineElement::scaleSymbol(int normalSize)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  double scale = 1.0;
  if (ops->scaleSymbols) {
    double xRange = (ops->xAxis->max_ - ops->xAxis->min_);
    double yRange = (ops->yAxis->max_ - ops->yAxis->min_);
    // Save the ranges as a baseline for future scaling
    if (!xRange_ || !yRange_) {
      xRange_ = xRange;
      yRange_ = yRange;
    }
    else {
      // Scale the symbol by the smallest change in the X or Y axes
      double xScale = xRange_ / xRange;
      double yScale = yRange_ / yRange;
      scale = MIN(xScale, yScale);
    }
  }
  int newSize = (int)(normalSize * scale);

  int maxSize = MIN(graphPtr_->hRange_, graphPtr_->vRange_);
  if (newSize > maxSize)
    newSize = maxSize;

  // Make the symbol size odd so that its center is a single pixel.
  newSize |= 0x01;

  return newSize;
}

void LineElement::getScreenPoints(MapInfo* mapPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if (!ops->coords.x || !ops->coords.y) {
    mapPtr->screenPts = NULL;
    mapPtr->nScreenPts = 0;
    mapPtr->map = NULL;
  }

  int np = NUMBEROFPOINTS(ops);
  double* x = ops->coords.x->values_;
  double* y = ops->coords.y->values_;
  Point2d* points = new Point2d[np];
  int* map = new int[np];

  int count = 0;
  if (gops->inverted) {
    for (int ii=0; ii<np; ii++) {
      if ((isfinite(x[ii])) && (isfinite(y[ii]))) {
	points[count].x = ops->yAxis->hMap(y[ii]);
	points[count].y = ops->xAxis->vMap(x[ii]);
	map[count] = ii;
	count++;
      }
    }
  }
  else {
    for (int ii=0; ii< np; ii++) {
      if ((isfinite(x[ii])) && (isfinite(y[ii]))) {
	points[count].x = ops->xAxis->hMap(x[ii]);
	points[count].y = ops->yAxis->vMap(y[ii]);
	map[count] = ii;
	count++;
      }
    }
  }
  mapPtr->screenPts = points;
  mapPtr->nScreenPts = count;
  mapPtr->map = map;
}

void LineElement::reducePoints(MapInfo *mapPtr, double tolerance)
{
  int* simple = new int[mapPtr->nScreenPts];
  int* map = new int[mapPtr->nScreenPts];
  Point2d* screenPts = new Point2d[mapPtr->nScreenPts];
  int np = simplify(mapPtr->screenPts, 0, mapPtr->nScreenPts - 1, 
		    tolerance, simple);
  for (int ii=0; ii<np; ii++) {
    int kk = simple[ii];
    screenPts[ii] = mapPtr->screenPts[kk];
    map[ii] = mapPtr->map[kk];
  }
  delete [] simple;

  delete [] mapPtr->screenPts;
  mapPtr->screenPts = screenPts;
  delete [] mapPtr->map;
  mapPtr->map = map;
  mapPtr->nScreenPts = np;
}

// Douglas-Peucker line simplification algorithm
int LineElement::simplify(Point2d *inputPts, int low, int high, 
			  double tolerance, int *indices)
{
#define StackPush(a)	s++, stack[s] = (a)
#define StackPop(a)	(a) = stack[s], s--
#define StackEmpty()	(s < 0)
#define StackTop()	stack[s]
    int split = -1; 
    double dist2, tolerance2;
    int s = -1;			/* Points to top stack item. */

    int* stack = new int[high - low + 1];
    StackPush(high);
    int count = 0;
    indices[count++] = 0;
    tolerance2 = tolerance * tolerance;
    while (!StackEmpty()) {
	dist2 = findSplit(inputPts, low, StackTop(), &split);
	if (dist2 > tolerance2)
	    StackPush(split);
	else {
	    indices[count++] = StackTop();
	    StackPop(low);
	}
    } 
    delete [] stack;
    return count;
}

double LineElement::findSplit(Point2d *points, int i, int j, int *split)	
{    
    double maxDist2 = -1.0;
    if ((i + 1) < j) {
	double a = points[i].y - points[j].y;
	double b = points[j].x - points[i].x;
	double c = (points[i].x * points[j].y) - (points[i].y * points[j].x);
	for (int kk = (i + 1); kk < j; kk++) {
	    double dist2 = (points[kk].x * a) + (points[kk].y * b) + c;
	    if (dist2 < 0.0)
		dist2 = -dist2;	

	    // Track the maximum.
	    if (dist2 > maxDist2) {
		maxDist2 = dist2;
		*split = kk;
	    }
	}
	// Correction for segment length---should be redone if can == 0
	maxDist2 *= maxDist2 / (a * a + b * b);
    } 
    return maxDist2;
}

void LineElement::generateSteps(MapInfo *mapPtr)
{
  int newSize = ((mapPtr->nScreenPts - 1) * 2) + 1;
  Point2d* screenPts = new Point2d[newSize];
  int* map = new int[newSize];
  screenPts[0] = mapPtr->screenPts[0];
  map[0] = 0;

  int count = 1;
  for (int i = 1; i < mapPtr->nScreenPts; i++) {
    screenPts[count + 1] = mapPtr->screenPts[i];

    // Hold last y-coordinate, use new x-coordinate
    screenPts[count].x = screenPts[count + 1].x;
    screenPts[count].y = screenPts[count - 1].y;

    // Use the same style for both the hold and the step points
    map[count] = map[count + 1] = mapPtr->map[i];
    count += 2;
  }
  delete [] mapPtr->map;
  mapPtr->map = map;
  delete [] mapPtr->screenPts;
  mapPtr->screenPts = screenPts;
  mapPtr->nScreenPts = newSize;
}

void LineElement::generateSpline(MapInfo *mapPtr)
{
  int nOrigPts = mapPtr->nScreenPts;
  Point2d* origPts = mapPtr->screenPts;

  // check points are not monotonically increasing
  for (int ii=0, jj=1; jj<nOrigPts; ii++, jj++) {
    if (origPts[jj].x <= origPts[ii].x)
      return;
  }
  if (((origPts[0].x > (double)graphPtr_->right_)) ||
      ((origPts[mapPtr->nScreenPts - 1].x < (double)graphPtr_->left_)))
    return;

  // The spline is computed in screen coordinates instead of data points so
  // that we can select the abscissas of the interpolated points from each
  // pixel horizontally across the plotting area.
  int extra = (graphPtr_->right_ - graphPtr_->left_) + 1;
  if (extra < 1)
    return;

  int niPts = nOrigPts + extra + 1;
  Point2d* iPts = new Point2d[niPts];
  int* map = new int[niPts];

  // Populate the x2 array with both the original X-coordinates and extra
  // X-coordinates for each horizontal pixel that the line segment contains
  int count = 0;
  for (int ii=0, jj=1; jj<nOrigPts; ii++, jj++) {
    // Add the original x-coordinate
    iPts[count].x = origPts[ii].x;

    // Include the starting offset of the point in the offset array
    map[count] = mapPtr->map[ii];
    count++;

    // Is any part of the interval (line segment) in the plotting area? 
    if ((origPts[jj].x >= (double)graphPtr_->left_) || 
	(origPts[ii].x <= (double)graphPtr_->right_)) {
      double x = origPts[ii].x + 1.0;

      /*
       * Since the line segment may be partially clipped on the left or
       * right side, the points to interpolate are always interior to
       * the plotting area.
       *
       *           left			    right
       *      x1----|---------------------------|---x2
       *
       * Pick the max of the starting X-coordinate and the left edge and
       * the min of the last X-coordinate and the right edge.
       */
      x = MAX(x, (double)graphPtr_->left_);
      double last = MIN(origPts[jj].x, (double)graphPtr_->right_);

      // Add the extra x-coordinates to the interval
      while (x < last) {
	map[count] = mapPtr->map[ii];
	iPts[count++].x = x;
	x++;
      }
    }
  }
  niPts = count;
  int result = 0;
  if (smooth_ == CUBIC)
    result = naturalSpline(origPts, nOrigPts, iPts, niPts);
  else if (smooth_ == QUADRATIC)
    result = quadraticSpline(origPts, nOrigPts, iPts, niPts);

  // The spline interpolation failed.  We will fall back to the current
  // coordinates and do no smoothing (standard line segments)
  if (!result) {
    smooth_ = LINEAR;
    delete [] iPts;
    delete [] map;
  }
  else {
    delete [] mapPtr->map;
    mapPtr->map = map;
    delete [] mapPtr->screenPts;
    mapPtr->screenPts = iPts;
    mapPtr->nScreenPts = niPts;
  }
}

void LineElement::generateParametricSpline(MapInfo *mapPtr)
{
  int nOrigPts = mapPtr->nScreenPts;
  Point2d *origPts = mapPtr->screenPts;

  Region2d exts;
  graphPtr_->extents(&exts);

  /* 
   * Populate the x2 array with both the original X-coordinates and extra
   * X-coordinates for each horizontal pixel that the line segment contains.
   */
  int count = 1;
  for (int i = 0, j = 1; j < nOrigPts; i++, j++) {
    Point2d p = origPts[i];
    Point2d q = origPts[j];
    count++;
    if (lineRectClip(&exts, &p, &q))
      count += (int)(hypot(q.x - p.x, q.y - p.y) * 0.5);
  }
  int niPts = count;
  Point2d *iPts = new Point2d[niPts];
  int* map = new int[niPts];

  /* 
   * FIXME: This is just plain wrong.  The spline should be computed
   *        and evaluated in separate steps.  This will mean breaking
   *	      up this routine since the catrom coefficients can be
   *	      independently computed for original data point.  This 
   *	      also handles the problem of allocating enough points 
   *	      since evaluation is independent of the number of points 
   *		to be evalualted.  The interpolated 
   *	      line segments should be clipped, not the original segments.
   */
  count = 0;
  int i,j;
  for (i = 0, j = 1; j < nOrigPts; i++, j++) {
    Point2d p = origPts[i];
    Point2d q = origPts[j];

    double d = hypot(q.x - p.x, q.y - p.y);
    /* Add the original x-coordinate */
    iPts[count].x = (double)i;
    iPts[count].y = 0.0;

    /* Include the starting offset of the point in the offset array */
    map[count] = mapPtr->map[i];
    count++;

    /* Is any part of the interval (line segment) in the plotting
     * area?  */

    if (lineRectClip(&exts, &p, &q)) {
      double dp, dq;

      /* Distance of original point to p. */
      dp = hypot(p.x - origPts[i].x, p.y - origPts[i].y);
      /* Distance of original point to q. */
      dq = hypot(q.x - origPts[i].x, q.y - origPts[i].y);
      dp += 2.0;
      while(dp <= dq) {
	/* Point is indicated by its interval and parameter t. */
	iPts[count].x = (double)i;
	iPts[count].y =  dp / d;
	map[count] = mapPtr->map[i];
	count++;
	dp += 2.0;
      }
    }
  }
  iPts[count].x = (double)i;
  iPts[count].y = 0.0;
  map[count] = mapPtr->map[i];
  count++;
  niPts = count;
  int result = 0;
  if (smooth_ == CUBIC)
    result = naturalParametricSpline(origPts, nOrigPts, &exts, 0, iPts, niPts);
  else if (smooth_ == CATROM)
    result = catromParametricSpline(origPts, nOrigPts, iPts, niPts);

  // The spline interpolation failed.  We will fall back to the current
  // coordinates and do no smoothing (standard line segments)
  if (!result) {
    smooth_ = LINEAR;
    delete [] iPts;
    delete [] map;
  }
  else {
    delete [] mapPtr->map;
    mapPtr->map = map;
    delete [] mapPtr->screenPts;
    mapPtr->screenPts = iPts;
    mapPtr->nScreenPts = niPts;
  }
}

void LineElement::mapSymbols(MapInfo *mapPtr)
{
  Point2d* points = new Point2d[mapPtr->nScreenPts];
  int *map = new int[mapPtr->nScreenPts];

  Region2d exts;
  graphPtr_->extents(&exts);

  Point2d *pp;
  int count = 0;
  int i;
  for (pp=mapPtr->screenPts, i=0; i<mapPtr->nScreenPts; i++, pp++) {
    if (PointInRegion(&exts, pp->x, pp->y)) {
      points[count].x = pp->x;
      points[count].y = pp->y;
      map[count] = mapPtr->map[i];
      count++;
    }
  }
  symbolPts_.points = points;
  symbolPts_.length = count;
  symbolPts_.map = map;
}

void LineElement::mapActiveSymbols()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  delete [] activePts_.points;
  activePts_.points = NULL;
  delete [] activePts_.map;
  activePts_.map = NULL;

  Region2d exts;
  graphPtr_->extents(&exts);

  Point2d *points = new Point2d[nActiveIndices_];
  int* map = new int[nActiveIndices_];
  int np = NUMBEROFPOINTS(ops);
  int count = 0;
  if (ops->coords.x && ops->coords.y) {
    for (int ii=0; ii<nActiveIndices_; ii++) {
      int iPoint = activeIndices_[ii];
      if (iPoint >= np)
	continue;

      double x = ops->coords.x->values_[iPoint];
      double y = ops->coords.y->values_[iPoint];
      points[count] = graphPtr_->map2D(x, y, ops->xAxis, ops->yAxis);
      map[count] = iPoint;
      if (PointInRegion(&exts, points[count].x, points[count].y)) {
	count++;
      }
    }
  }

  if (count > 0) {
    activePts_.points = points;
    activePts_.map = map;
  }
  else {
    delete [] points;
    delete [] map;	
  }
  activePts_.length = count;
}

void LineElement::mergePens(LineStyle **styleMap)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  if (Chain_GetLength(ops->stylePalette) < 2) {
    ChainLink* link = Chain_FirstLink(ops->stylePalette);
    LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
    stylePtr->symbolPts.length = symbolPts_.length;
    stylePtr->symbolPts.points = symbolPts_.points;
    stylePtr->xeb.length = xeb_.length;
    stylePtr->xeb.segments = xeb_.segments;
    stylePtr->yeb.length = yeb_.length;
    stylePtr->yeb.segments = yeb_.segments;
    return;
  }

  if (symbolPts_.length > 0) {
    Point2d* points = new Point2d[symbolPts_.length];
    int* map = new int[symbolPts_.length];
    Point2d *pp = points;
    int* ip = map;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
      stylePtr->symbolPts.points = pp;
      for (int ii=0; ii<symbolPts_.length; ii++) {
	int iData = symbolPts_.map[ii];
	if (styleMap[iData] == stylePtr) {
	  *pp++ = symbolPts_.points[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->symbolPts.length = pp - stylePtr->symbolPts.points;
    }
    delete [] symbolPts_.points;
    symbolPts_.points = points;
    delete [] symbolPts_.map;
    symbolPts_.map = map;
  }

  if (xeb_.length > 0) {
    Segment2d* segments = new Segment2d[xeb_.length];
    Segment2d *sp = segments;
    int* map = new int[xeb_.length];
    int* ip = map;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
      stylePtr->xeb.segments = sp;
      for (int ii=0; ii<xeb_.length; ii++) {
	int iData = xeb_.map[ii];
	if (styleMap[iData] == stylePtr) {
	  *sp++ = xeb_.segments[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->xeb.length = sp - stylePtr->xeb.segments;
    }
    delete [] xeb_.segments;
    xeb_.segments = segments;
    delete [] xeb_.map;
    xeb_.map = map;
  }

  if (yeb_.length > 0) {
    Segment2d* segments = new Segment2d[yeb_.length];
    Segment2d* sp = segments;
    int* map = new int [yeb_.length];
    int* ip = map;
    for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
	 link = Chain_NextLink(link)) {
      LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
      stylePtr->yeb.segments = sp;
      for (int ii=0; ii<yeb_.length; ii++) {
	int iData = yeb_.map[ii];
	if (styleMap[iData] == stylePtr) {
	  *sp++ = yeb_.segments[ii];
	  *ip++ = iData;
	}
      }
      stylePtr->yeb.length = sp - stylePtr->yeb.segments;
    }
    delete [] yeb_.segments;
    yeb_.segments = segments;
    delete [] yeb_.map;
    yeb_.map = map;
  }
}

#define CLIP_TOP	(1<<0)
#define CLIP_BOTTOM	(1<<1)
#define CLIP_RIGHT	(1<<2)
#define CLIP_LEFT	(1<<3)

int LineElement::outCode(Region2d *extsPtr, Point2d *p)
{
  int code =0;
  if (p->x > extsPtr->right)
    code |= CLIP_RIGHT;
  else if (p->x < extsPtr->left)
    code |= CLIP_LEFT;

  if (p->y > extsPtr->bottom)
    code |= CLIP_BOTTOM;
  else if (p->y < extsPtr->top)
    code |= CLIP_TOP;

  return code;
}

int LineElement::clipSegment(Region2d *extsPtr, int code1, int code2,
			     Point2d *p, Point2d *q)
{
  int inside = ((code1 | code2) == 0);
  int outside = ((code1 & code2) != 0);

  /*
   * In the worst case, we'll clip the line segment against each of the four
   * sides of the bounding rectangle.
   */
  while ((!outside) && (!inside)) {
    if (code1 == 0) {
      Point2d *tmp;
      int code;

      /* Swap pointers and out codes */
      tmp = p, p = q, q = tmp;
      code = code1, code1 = code2, code2 = code;
    }
    if (code1 & CLIP_LEFT) {
      p->y += (q->y - p->y) *
	(extsPtr->left - p->x) / (q->x - p->x);
      p->x = extsPtr->left;
    } else if (code1 & CLIP_RIGHT) {
      p->y += (q->y - p->y) *
	(extsPtr->right - p->x) / (q->x - p->x);
      p->x = extsPtr->right;
    } else if (code1 & CLIP_BOTTOM) {
      p->x += (q->x - p->x) *
	(extsPtr->bottom - p->y) / (q->y - p->y);
      p->y = extsPtr->bottom;
    } else if (code1 & CLIP_TOP) {
      p->x += (q->x - p->x) *
	(extsPtr->top - p->y) / (q->y - p->y);
      p->y = extsPtr->top;
    }
    code1 = outCode(extsPtr, p);

    inside = ((code1 | code2) == 0);
    outside = ((code1 & code2) != 0);
  }
  return (!inside);
}

void LineElement::saveTrace(int start, int length, MapInfo* mapPtr)
{
  bltTrace* tracePtr  = new bltTrace;
  Point2d* screenPts = new Point2d[length];
  int* map = new int[length];

  // Copy the screen coordinates of the trace into the point array
  if (mapPtr->map) {
    for (int ii=0, jj=start; ii<length; ii++, jj++) {
      screenPts[ii].x = mapPtr->screenPts[jj].x;
      screenPts[ii].y = mapPtr->screenPts[jj].y;
      map[ii] = mapPtr->map[jj];
    }
  } 
  else {
    for (int ii=0, jj=start; ii<length; ii++, jj++) {
      screenPts[ii].x = mapPtr->screenPts[jj].x;
      screenPts[ii].y = mapPtr->screenPts[jj].y;
      map[ii] = jj;
    }
  }
  tracePtr->screenPts.length = length;
  tracePtr->screenPts.points = screenPts;
  tracePtr->screenPts.map = map;
  tracePtr->start = start;
  if (traces_ == NULL)
    traces_ = new Chain();

  traces_->append(tracePtr);
}

void LineElement::freeTraces()
{
  for (ChainLink* link = Chain_FirstLink(traces_); link;
       link = Chain_NextLink(link)) {
    bltTrace* tracePtr = (bltTrace*)Chain_GetValue(link);
    delete [] tracePtr->screenPts.map;
    delete [] tracePtr->screenPts.points;
    delete tracePtr;
  }
  delete traces_;
  traces_ = NULL;
}

void LineElement::mapTraces(MapInfo *mapPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  Region2d exts;
  graphPtr_->extents(&exts);

  int count = 1;
  int code1 = outCode(&exts, mapPtr->screenPts);
  Point2d* p = mapPtr->screenPts;
  Point2d* q = p + 1;

  int start;
  int ii;
  for (ii=1; ii<mapPtr->nScreenPts; ii++, p++, q++) {
    Point2d s;
    s.x = 0;
    s.y = 0;
    int code2 = outCode(&exts, q);
    // Save the coordinates of the last point, before clipping
    if (code2 != 0)
      s = *q;

    int broken = BROKEN_TRACE(ops->penDir, p->x, q->x);
    int offscreen = clipSegment(&exts, code1, code2, p, q);
    if (broken || offscreen) {
      // The last line segment is either totally clipped by the plotting
      // area or the x-direction is wrong, breaking the trace.  Either
      // way, save information about the last trace (if one exists),
      // discarding the current line segment
      if (count > 1) {
	start = ii - count;
	saveTrace(start, count, mapPtr);
	count = 1;
      }
    }
    else {
      // Add the point to the trace
      count++;

      // If the last point is clipped, this means that the trace is
      // broken after this point.  Restore the original coordinate
      // (before clipping) after saving the trace.
      if (code2 != 0) {
	start = ii - (count - 1);
	saveTrace(start, count, mapPtr);
	mapPtr->screenPts[ii] = s;
	count = 1;
      }
    }
    code1 = code2;
  }
  if (count > 1) {
    start = ii - count;
    saveTrace(start, count, mapPtr);
  }
}

void LineElement::mapFillArea(MapInfo *mapPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if (fillPts_) {
    delete [] fillPts_;
    fillPts_ = NULL;
    nFillPts_ = 0;
  }
  if (mapPtr->nScreenPts < 3)
    return;

  int np = mapPtr->nScreenPts + 3;
  Region2d exts;
  graphPtr_->extents(&exts);

  Point2d* origPts = new Point2d[np];
  if (gops->inverted) {
    int i;
    double minX = (double)ops->yAxis->screenMin_;
    for (i = 0; i < mapPtr->nScreenPts; i++) {
      origPts[i].x = mapPtr->screenPts[i].x + 1;
      origPts[i].y = mapPtr->screenPts[i].y;
      if (origPts[i].x < minX) {
	minX = origPts[i].x;
      }
    }	
    // Add edges to make the polygon fill to the bottom of plotting window
    origPts[i].x = minX;
    origPts[i].y = origPts[i - 1].y;
    i++;
    origPts[i].x = minX;
    origPts[i].y = origPts[0].y; 
    i++;
    origPts[i] = origPts[0];
  }
  else {
    int i;
    double maxY = (double)ops->yAxis->bottom_;
    for (i = 0; i < mapPtr->nScreenPts; i++) {
      origPts[i].x = mapPtr->screenPts[i].x + 1;
      origPts[i].y = mapPtr->screenPts[i].y;
      if (origPts[i].y > maxY) {
	maxY = origPts[i].y;
      }
    }	
    // Add edges to extend the fill polygon to the bottom of plotting window
    origPts[i].x = origPts[i - 1].x;
    origPts[i].y = maxY;
    i++;
    origPts[i].x = origPts[0].x; 
    origPts[i].y = maxY;
    i++;
    origPts[i] = origPts[0];
  }

  Point2d *clipPts = new Point2d[np * 3];
  np = polyRectClip(&exts, origPts, np - 1, clipPts);

  delete [] origPts;
  if (np < 3)
    delete [] clipPts;
  else {
    fillPts_ = clipPts;
    nFillPts_ = np;
  }
}

void LineElement::reset()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  freeTraces();

  for (ChainLink* link = Chain_FirstLink(ops->stylePalette); link;
       link = Chain_NextLink(link)) {
    LineStyle *stylePtr = (LineStyle*)Chain_GetValue(link);
    stylePtr->symbolPts.length = 0;
    stylePtr->xeb.length = 0;
    stylePtr->yeb.length = 0;
  }

  delete [] symbolPts_.points;
  symbolPts_.points = NULL;

  delete [] symbolPts_.map;
  symbolPts_.map = NULL;
  symbolPts_.length = 0;

  delete [] activePts_.points;
  activePts_.points = NULL;
  activePts_.length = 0;

  delete [] activePts_.map;
  activePts_.map = NULL;

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
}

void LineElement::mapErrorBars(LineStyle **styleMap)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  Region2d exts;
  graphPtr_->extents(&exts);

  int nn =0;
  int np = NUMBEROFPOINTS(ops);
  if (ops->coords.x && ops->coords.y) {
    if (ops->xError && (ops->xError->nValues() > 0))
      nn = MIN(ops->xError->nValues(), np);
    else
      if (ops->xHigh && ops->xLow)
	nn = MIN3(ops->xHigh->nValues(), ops->xLow->nValues(), np);
  }

  if (nn) {
    Segment2d* errorBars = new Segment2d[nn * 3];
    Segment2d* segPtr = errorBars;
    int* errorToData = new int[nn * 3];
    int* indexPtr = errorToData;

    for (int ii=0; ii<nn; ii++) {
      double x = ops->coords.x->values_[ii];
      double y = ops->coords.y->values_[ii];
      LineStyle* stylePtr = styleMap[ii];

      if ((isfinite(x)) && (isfinite(y))) {
	double high;
	double low;
	if (ops->xError && ops->xError->nValues() > 0) {
	  high = x + ops->xError->values_[ii];
	  low = x - ops->xError->values_[ii];
	} 
	else {
	  high = ops->xHigh ? ops->xHigh->values_[ii] : 0;
	  low  = ops->xLow ? ops->xLow->values_[ii] : 0;
	}

	if ((isfinite(high)) && (isfinite(low)))  {
	  Point2d p = graphPtr_->map2D(high, y, ops->xAxis, ops->yAxis);
	  Point2d q = graphPtr_->map2D(low, y, ops->xAxis, ops->yAxis);
	  segPtr->p = p;
	  segPtr->q = q;
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Left cap
	  segPtr->p.x = p.x;
	  segPtr->q.x = p.x;
	  segPtr->p.y = p.y - stylePtr->errorBarCapWidth;
	  segPtr->q.y = p.y + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Right cap
	  segPtr->p.x = q.x;
	  segPtr->q.x = q.x;
	  segPtr->p.y = q.y - stylePtr->errorBarCapWidth;
	  segPtr->q.y = q.y + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	}
      }
    }
    xeb_.segments = errorBars;
    xeb_.length = segPtr - errorBars;
    xeb_.map = errorToData;
  }

  nn =0;
  if (ops->coords.x && ops->coords.y) {
    if (ops->yError && (ops->yError->nValues() > 0))
      nn = MIN(ops->yError->nValues(), np);
    else
      if (ops->yHigh && ops->yLow)
	nn = MIN3(ops->yHigh->nValues(), ops->yLow->nValues(), np);
  }

  if (nn) {
    Segment2d* errorBars = new Segment2d[nn * 3];
    Segment2d* segPtr = errorBars;
    int* errorToData = new int[nn * 3];
    int* indexPtr = errorToData;

    for (int ii=0; ii<nn; ii++) {
      double x = ops->coords.x->values_[ii];
      double y = ops->coords.y->values_[ii];
      LineStyle* stylePtr = styleMap[ii];

      if ((isfinite(x)) && (isfinite(y))) {
	double high;
	double low;
	if (ops->yError && ops->yError->nValues() > 0) {
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
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Top cap
	  segPtr->p.y = p.y;
	  segPtr->q.y = p.y;
	  segPtr->p.x = p.x - stylePtr->errorBarCapWidth;
	  segPtr->q.x = p.x + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	  // Bottom cap
	  segPtr->p.y = q.y;
	  segPtr->q.y = q.y;
	  segPtr->p.x = q.x - stylePtr->errorBarCapWidth;
	  segPtr->q.x = q.x + stylePtr->errorBarCapWidth;
	  if (lineRectClip(&exts, &segPtr->p, &segPtr->q)) {
	    segPtr++;
	    *indexPtr++ = ii;
	  }
	}
      }
    }
    yeb_.segments = errorBars;
    yeb_.length = segPtr - errorBars;
    yeb_.map = errorToData;
  }
}

int LineElement::closestTrace()
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;
  ClosestSearch* searchPtr = &gops->search;

  Point2d closest;

  int iClose = -1;
  double dMin = searchPtr->dist;
  closest.x = closest.y = 0;
  for (ChainLink *link=Chain_FirstLink(traces_); link; 
       link = Chain_NextLink(link)) {
    bltTrace *tracePtr = (bltTrace*)Chain_GetValue(link);
    for (Point2d *p=tracePtr->screenPts.points, 
	   *pend=p + (tracePtr->screenPts.length - 1); p<pend; p++) {
      Point2d b;
      double d;
      if (searchPtr->along == SEARCH_X)
	d = distanceToX(searchPtr->x, searchPtr->y, p, p + 1, &b);
      else if (searchPtr->along == SEARCH_Y)
	d = distanceToY(searchPtr->x, searchPtr->y, p, p + 1, &b);
      else
	d = distanceToLine(searchPtr->x, searchPtr->y, p, p + 1, &b);

      if (d < dMin) {
	closest = b;
	iClose = tracePtr->screenPts.map[p-tracePtr->screenPts.points];
	dMin = d;
      }
    }
  }
  if (dMin < searchPtr->dist) {
    searchPtr->dist = dMin;
    searchPtr->elemPtr = (Element*)this;
    searchPtr->index = iClose;
    searchPtr->point = graphPtr_->invMap2D(closest.x, closest.y, 
					   ops->xAxis, ops->yAxis);
    return 1;
  }

  return 0;
}

void LineElement::closestPoint(ClosestSearch *searchPtr)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;

  double dMin = searchPtr->dist;
  int iClose = 0;

  // Instead of testing each data point in graph coordinates, look at the
  // array of mapped screen coordinates. The advantages are
  //  1) only examine points that are visible (unclipped), and
  //  2) the computed distance is already in screen coordinates.
  int count =0;
  for (Point2d *pp = symbolPts_.points; count < symbolPts_.length;
       count++, pp++) {
    double dx = (double)abs(searchPtr->x - pp->x);
    double dy = (double)abs(searchPtr->y - pp->y);
    double d;
    if (searchPtr->along == SEARCH_BOTH)
      d = hypot(dx, dy);
    else if (searchPtr->along == SEARCH_X)
      d = dx;
    else if (searchPtr->along == SEARCH_Y)
      d = dy;
    else
      continue;

    if (d < dMin) {
      iClose = symbolPts_.map[count];
      dMin = d;
    }
  }
  if (dMin < searchPtr->dist) {
    searchPtr->elemPtr = (Element*)this;
    searchPtr->dist = dMin;
    searchPtr->index = iClose;
    searchPtr->point.x = ops->coords.x->values_[iClose];
    searchPtr->point.y = ops->coords.y->values_[iClose];
  }
}

void LineElement::drawCircle(Display *display, Drawable drawable, 
			     LinePen* penPtr, 
			     int nSymbolPts, Point2d *symbolPts, int radius)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  int count = 0;
  int s = radius + radius;
  XArc* arcs = new XArc[nSymbolPts];
  XArc *ap = arcs;
  for (Point2d *pp=symbolPts, *pend=pp+nSymbolPts; pp<pend; pp++) {
    if (DRAW_SYMBOL()) {
      ap->x = (short)(pp->x - radius);
      ap->y = (short)(pp->y - radius);
      ap->width = (short)s;
      ap->height = (short)s;
      ap->angle1 = 0;
      ap->angle2 = 23040;
      ap++;
      count++;
    }
    symbolCounter_++;
  }

  for (XArc *ap=arcs, *aend=ap+count; ap<aend; ap++) {
    if (penOps->symbol.fillGC)
      XFillArc(display, drawable, penOps->symbol.fillGC, 
	       ap->x, ap->y, ap->width, ap->height, ap->angle1, ap->angle2);

    if (penOps->symbol.outlineWidth > 0)
      XDrawArc(display, drawable, penOps->symbol.outlineGC,
	       ap->x, ap->y, ap->width, ap->height, ap->angle1, ap->angle2);
  }

  delete [] arcs;
}

void LineElement::drawSquare(Display *display, Drawable drawable, 
			     LinePen* penPtr, 
			     int nSymbolPts, Point2d *symbolPts, int r)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  int s = r + r;
  int count =0;
  Rectangle* rectangles = new Rectangle[nSymbolPts];
  Rectangle* rp=rectangles;
  for (Point2d *pp=symbolPts, *pend=pp+nSymbolPts; pp<pend; pp++) {
    if (DRAW_SYMBOL()) {
      rp->x = (int)pp->x - r;
      rp->y = (int)pp->y - r;
      rp->width = s;
      rp->height = s;
      rp++;
      count++;
    }
    symbolCounter_++;
  }

  for (Rectangle *rp=rectangles, *rend=rp+count; rp<rend; rp ++) {
    if (penOps->symbol.fillGC)
      XFillRectangle(display, drawable, penOps->symbol.fillGC,
		     rp->x, rp->y, rp->width, rp->height);

    if (penOps->symbol.outlineWidth > 0)
      XDrawRectangle(display, drawable, penOps->symbol.outlineGC,
		     rp->x, rp->y, rp->width, rp->height);
  }

  delete [] rectangles;
}

void LineElement::drawSCross(Display* display, Drawable drawable, 
			     LinePen* penPtr, 
			     int nSymbolPts, Point2d* symbolPts, int r2)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  Point pattern[4];
  if (penOps->symbol.type == SYMBOL_SCROSS) {
    r2 = (int)(r2 * M_SQRT1_2);
    pattern[3].y = pattern[2].x = pattern[0].x = pattern[0].y = -r2;
    pattern[3].x = pattern[2].y = pattern[1].y = pattern[1].x = r2;
  }
  else {
    pattern[0].y = pattern[1].y = pattern[2].x = pattern[3].x = 0;
    pattern[0].x = pattern[2].y = -r2;
    pattern[1].x = pattern[3].y = r2;
  }

  for (Point2d *pp=symbolPts, *endp=pp+nSymbolPts; pp<endp; pp++) {
    if (DRAW_SYMBOL()) {
      int rndx = (int)pp->x;
      int rndy = (int)pp->y;
      XDrawLine(graphPtr_->display_, drawable, penOps->symbol.outlineGC,
		pattern[0].x + rndx, pattern[0].y + rndy,
		pattern[1].x + rndx, pattern[1].y + rndy);
      XDrawLine(graphPtr_->display_, drawable, penOps->symbol.outlineGC,
		pattern[2].x + rndx, pattern[2].y + rndy,
		pattern[3].x + rndx, pattern[3].y + rndy);
    }
  }
}

void LineElement::drawCross(Display *display, Drawable drawable, 
			    LinePen* penPtr, 
			    int nSymbolPts, Point2d *symbolPts, int r2)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  /*
   *          2   3       The plus/cross symbol is a closed polygon
   *                      of 12 points. The diagram to the left
   *    0,12  1   4    5  represents the positions of the points
   *           x,y        which are computed below. The extra
   *     11  10   7    6  (thirteenth) point connects the first and
   *                      last points.
   *          9   8
   */
  int d = (r2 / 3);
  Point pattern[13];
  pattern[0].x = pattern[11].x = pattern[12].x = -r2;
  pattern[2].x = pattern[1].x = pattern[10].x = pattern[9].x = -d;
  pattern[3].x = pattern[4].x = pattern[7].x = pattern[8].x = d;
  pattern[5].x = pattern[6].x = r2;
  pattern[2].y = pattern[3].y = -r2;
  pattern[0].y = pattern[1].y = pattern[4].y = pattern[5].y =
  pattern[12].y = -d;
  pattern[11].y = pattern[10].y = pattern[7].y = pattern[6].y = d;
  pattern[9].y = pattern[8].y = r2;

  if (penOps->symbol.type == SYMBOL_CROSS) {
    // For the cross symbol, rotate the points by 45 degrees
    for (int ii=0; ii<12; ii++) {
      double dx = (double)pattern[ii].x * M_SQRT1_2;
      double dy = (double)pattern[ii].y * M_SQRT1_2;
      pattern[ii].x = (int)(dx - dy);
      pattern[ii].y = (int)(dx + dy);
    }
    pattern[12] = pattern[0];
  }

  int count = 0;
  XPoint* polygon = new XPoint[nSymbolPts*13];
  XPoint* xpp = polygon;
  for (Point2d *pp = symbolPts, *endp = pp + nSymbolPts; pp < endp; pp++) {
    if (DRAW_SYMBOL()) {
      int rndx = (int)pp->x;
      int rndy = (int)pp->y;
      for (int ii=0; ii<13; ii++) {
	xpp->x = (short)(pattern[ii].x + rndx);
	xpp->y = (short)(pattern[ii].y + rndy);
	xpp++;
      }
      count++;
    }
    symbolCounter_++;
  }

  if (penOps->symbol.fillGC) {
    XPoint* xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 13)
      XFillPolygon(graphPtr_->display_, drawable, 
		   penOps->symbol.fillGC, xpp, 13, Complex, 
		   CoordModeOrigin);
  }

  if (penOps->symbol.outlineWidth > 0) {
    XPoint*xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 13)
      XDrawLines(graphPtr_->display_, drawable, 
		 penOps->symbol.outlineGC, xpp, 13, CoordModeOrigin);
  }

  delete [] polygon;
}

void LineElement::drawDiamond(Display *display, Drawable drawable, 
			      LinePen* penPtr, 
			      int nSymbolPts, Point2d *symbolPts, int r1)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  /*
   *                      The plus symbol is a closed polygon
   *            1         of 4 points. The diagram to the left
   *                      represents the positions of the points
   *       0,4 x,y  2     which are computed below. The extra
   *                      (fifth) point connects the first and
   *            3         last points.
   */
  Point pattern[5];
  pattern[1].y = pattern[0].x = -r1;
  pattern[2].y = pattern[3].x = pattern[0].y = pattern[1].x = 0;
  pattern[3].y = pattern[2].x = r1;
  pattern[4] = pattern[0];

  int count = 0;
  XPoint* polygon = new XPoint[nSymbolPts*5];
  XPoint* xpp = polygon;
  for (Point2d *pp = symbolPts, *endp = pp + nSymbolPts; pp < endp; pp++) {
    if (DRAW_SYMBOL()) {
      int rndx = (int)pp->x;
      int rndy = (int)pp->y;
      for (int ii=0; ii<5; ii++) {
	xpp->x = (short)(pattern[ii].x + rndx);
	xpp->y = (short)(pattern[ii].y + rndy);
	xpp++;
      }
      count++;
    }
    symbolCounter_++;
  }

  if (penOps->symbol.fillGC) {
    XPoint* xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 5)
      XFillPolygon(graphPtr_->display_, drawable, 
		   penOps->symbol.fillGC, xpp, 5, Convex, CoordModeOrigin);
  }

  if (penOps->symbol.outlineWidth > 0) {
    XPoint* xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 5)
      XDrawLines(graphPtr_->display_, drawable, 
		 penOps->symbol.outlineGC, xpp, 5, CoordModeOrigin);
  }

  delete [] polygon;
}

#define B_RATIO		1.3467736870885982
#define TAN30		0.57735026918962573
#define COS30		0.86602540378443871
void LineElement::drawArrow(Display *display, Drawable drawable, 
			    LinePen* penPtr, 
			    int nSymbolPts, Point2d *symbolPts, int size)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  double b = size * B_RATIO * 0.7 * 0.5;
  short b2 = (short)b;
  short h2 = (short)(TAN30 * b);
  short h1 = (short)(b / COS30);
  /*
   *                      The triangle symbol is a closed polygon
   *           0,3         of 3 points. The diagram to the left
   *                      represents the positions of the points
   *           x,y        which are computed below. The extra
   *                      (fourth) point connects the first and
   *      2           1   last points.
   */

  Point pattern[4];
  if (penOps->symbol.type == SYMBOL_ARROW) {
    pattern[3].x = pattern[0].x = 0;
    pattern[3].y = pattern[0].y = h1;
    pattern[1].x = b2;
    pattern[2].y = pattern[1].y = -h2;
    pattern[2].x = -b2;
  } else {
    pattern[3].x = pattern[0].x = 0;
    pattern[3].y = pattern[0].y = -h1;
    pattern[1].x = b2;
    pattern[2].y = pattern[1].y = h2;
    pattern[2].x = -b2;
  }

  int count = 0;
  XPoint* polygon = new XPoint[nSymbolPts*4];
  XPoint* xpp = polygon;
  for (Point2d *pp = symbolPts, *endp = pp + nSymbolPts; pp < endp; pp++) {
    if (DRAW_SYMBOL()) {
      int rndx = (int)pp->x;
      int rndy = (int)pp->y;
      for (int ii=0; ii<4; ii++) {
	xpp->x = (short)(pattern[ii].x + rndx);
	xpp->y = (short)(pattern[ii].y + rndy);
	xpp++;
      }
      count++;
    }
    symbolCounter_++;
  }

  if (penOps->symbol.fillGC) {
    XPoint* xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 4)
      XFillPolygon(graphPtr_->display_, drawable, 
		   penOps->symbol.fillGC, xpp, 4, Convex, CoordModeOrigin);
  }

  if (penOps->symbol.outlineWidth > 0) {
    XPoint* xpp = polygon;
    for (int ii=0; ii<count; ii++, xpp += 4)
      XDrawLines(graphPtr_->display_, drawable, 
		 penOps->symbol.outlineGC, xpp, 4, CoordModeOrigin);
  }

  delete [] polygon;
}

#define S_RATIO		0.886226925452758
void LineElement::drawSymbols(Drawable drawable, LinePen* penPtr, int size,
			      int nSymbolPts, Point2d* symbolPts)
{
  LinePenOptions* penOps = (LinePenOptions*)penPtr->ops();

  if (size < 3) {
    if (penOps->symbol.fillGC) {
      for (Point2d *pp = symbolPts, *endp = pp + nSymbolPts; pp < endp; pp++)
	XDrawLine(graphPtr_->display_, drawable, penOps->symbol.fillGC, 
		  (int)pp->x, (int)pp->y, (int)pp->x+1, (int)pp->y+1);
    }
    return;
  }

  int r1 = (int)ceil(size * 0.5);
  int r2 = (int)ceil(size * S_RATIO * 0.5);

  switch (penOps->symbol.type) {
  case SYMBOL_NONE:
    break;
  case SYMBOL_SQUARE:
    drawSquare(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,r2);
    break;
  case SYMBOL_CIRCLE:
    drawCircle(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,r1);
    break;
  case SYMBOL_SPLUS:
  case SYMBOL_SCROSS:
    drawSCross(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,r2);
    break;
  case SYMBOL_PLUS:
  case SYMBOL_CROSS:
    drawCross(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,r2);
    break;
  case SYMBOL_DIAMOND:
    drawDiamond(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,r1);
    break;
  case SYMBOL_TRIANGLE:
  case SYMBOL_ARROW:
    drawArrow(graphPtr_->display_, drawable, penPtr, nSymbolPts,symbolPts,size);
    break;
  }
}

void LineElement::drawTraces(Drawable drawable, LinePen* penPtr)
{
  for (ChainLink* link = Chain_FirstLink(traces_); link;
       link = Chain_NextLink(link)) {
    bltTrace* tracePtr = (bltTrace*)Chain_GetValue(link);

    int count = tracePtr->screenPts.length; 
    XPoint* points = new XPoint[count];
    XPoint*xpp = points;
    for (int ii=0; ii<count; ii++, xpp++) {
      xpp->x = (short)tracePtr->screenPts.points[ii].x;
      xpp->y = (short)tracePtr->screenPts.points[ii].y;
    }
    XDrawLines(graphPtr_->display_, drawable, penPtr->traceGC_, points, 
	       count, CoordModeOrigin);
    delete [] points;
  }
}

void LineElement::drawValues(Drawable drawable, LinePen* penPtr, 
			     int length, Point2d *points, int *map)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePenOptions* pops = (LinePenOptions*)penPtr->ops();

  char string[TCL_DOUBLE_SPACE * 2 + 2];
  const char* fmt = pops->valueFormat;
  if (fmt == NULL)
    fmt = "%g";
  TextStyle ts(graphPtr_, &pops->valueStyle);

  double* xval = ops->coords.x->values_;
  double* yval = ops->coords.y->values_;
  int count = 0;

  for (Point2d *pp = points, *endp = points + length; pp < endp; pp++) {
    double x = xval[map[count]];
    double y = yval[map[count]];
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

    ts.drawText(drawable, string, pp->x, pp->y);
  } 
}

void LineElement::printSymbols(PSOutput* psPtr, LinePen* penPtr, int size,
			       int nSymbolPts, Point2d *symbolPts)
{
  LinePenOptions* pops = (LinePenOptions*)penPtr->ops();

  double symbolSize;

  // Set line and foreground attributes
  XColor* fillColor = pops->symbol.fillColor;
  if (!fillColor)
    fillColor = pops->traceColor;

  XColor* outlineColor = pops->symbol.outlineColor;
  if (!outlineColor)
    outlineColor = pops->traceColor;

  if (pops->symbol.type == SYMBOL_NONE)
    psPtr->setLineAttributes(pops->traceColor, pops->traceWidth + 2,
			     &pops->traceDashes, CapButt, JoinMiter);
  else {
    psPtr->setLineWidth(pops->symbol.outlineWidth);
    psPtr->setDashes(NULL);
  }

  // build DrawSymbolProc
  psPtr->append("\n/DrawSymbolProc {\n");
  switch (pops->symbol.type) {
  case SYMBOL_NONE:
    break;
  default:
    psPtr->append("  ");
    psPtr->setBackground(fillColor);
    psPtr->append("  gsave fill grestore\n");

    if (pops->symbol.outlineWidth > 0) {
      psPtr->append("  ");
      psPtr->setForeground(outlineColor);
      psPtr->append("  stroke\n");
    }
    break;
  }
  psPtr->append("} def\n\n");

  // set size
  symbolSize = (double)size;
  switch (pops->symbol.type) {
  case SYMBOL_SQUARE:
  case SYMBOL_CROSS:
  case SYMBOL_PLUS:
  case SYMBOL_SCROSS:
  case SYMBOL_SPLUS:
    symbolSize = (double)size * S_RATIO;
    break;
  case SYMBOL_TRIANGLE:
  case SYMBOL_ARROW:
    symbolSize = (double)size * 0.7;
    break;
  case SYMBOL_DIAMOND:
    symbolSize = (double)size * M_SQRT1_2;
    break;

  default:
    break;
  }

  int count =0;
  for (Point2d *pp=symbolPts, *endp=symbolPts + nSymbolPts; pp < endp; pp++) {
    if (DRAW_SYMBOL()) {
      psPtr->format("%g %g %g %s\n", pp->x, pp->y, symbolSize, 
		    symbolMacros[pops->symbol.type]);
      count++;
    }
    symbolCounter_++;
  }
}

void LineElement::setLineAttributes(PSOutput* psPtr, LinePen* penPtr)
{
  LinePenOptions* pops = (LinePenOptions*)penPtr->ops();

  psPtr->setLineAttributes(pops->traceColor, pops->traceWidth, 
			   &pops->traceDashes, CapButt, JoinMiter);

  if ((LineIsDashed(pops->traceDashes)) && 
      (pops->traceOffColor)) {
    psPtr->append("/DashesProc {\n  gsave\n    ");
    psPtr->setBackground(pops->traceOffColor);
    psPtr->append("    ");
    psPtr->setDashes(NULL);
    psPtr->append("stroke\n  grestore\n} def\n");
  } else {
    psPtr->append("/DashesProc {} def\n");
  }
}

void LineElement::printTraces(PSOutput* psPtr, LinePen* penPtr)
{
  setLineAttributes(psPtr, penPtr);
  for (ChainLink* link = Chain_FirstLink(traces_); link; 
       link = Chain_NextLink(link)) {
    bltTrace *tracePtr = (bltTrace*)Chain_GetValue(link);
    if (tracePtr->screenPts.length > 0) {
      psPtr->append("% start trace\n");
      psPtr->printMaxPolyline(tracePtr->screenPts.points, 
			     tracePtr->screenPts.length);
      psPtr->append("% end trace\n");
    }
  }
}

void LineElement::printValues(PSOutput* psPtr, LinePen* penPtr, 
			      int nSymbolPts, Point2d *symbolPts, 
			      int *pointToData)
{
  LineElementOptions* ops = (LineElementOptions*)ops_;
  LinePenOptions* pops = (LinePenOptions*)penPtr->ops();

  const char* fmt = pops->valueFormat;
  if (fmt == NULL)
    fmt = "%g";
  TextStyle ts(graphPtr_, &pops->valueStyle);

  int count = 0;
  for (Point2d *pp=symbolPts, *endp=symbolPts + nSymbolPts; pp < endp; pp++) {
    double x = ops->coords.x->values_[pointToData[count]];
    double y = ops->coords.y->values_[pointToData[count]];
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

    ts.printText(psPtr, string, pp->x, pp->y);
  } 
}


