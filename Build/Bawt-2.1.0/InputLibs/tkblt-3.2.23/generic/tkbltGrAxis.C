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

#include "tkbltGraph.h"
#include "tkbltGrBind.h"
#include "tkbltGrAxis.h"
#include "tkbltGrAxisOption.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"
#include "tkbltInt.h"

using namespace Blt;

#define AXIS_PAD_TITLE 2
#define EXP10(x) (pow(10.0,(x)))

AxisName Blt::axisNames[] = { 
  { "x",  CID_AXIS_X },
  { "y",  CID_AXIS_Y },
  { "x2", CID_AXIS_X },
  { "y2", CID_AXIS_Y }
} ;

// Defs

extern double AdjustViewport(double offset, double windowSize);

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_COLOR, "-activeforeground", "activeForeground", "ActiveForeground",
   STD_ACTIVE_FOREGROUND, -1, Tk_Offset(AxisOptions, activeFgColor), 
   0, NULL, CACHE}, 
  {TK_OPTION_RELIEF, "-activerelief", "activeRelief", "Relief",
   "flat", -1, Tk_Offset(AxisOptions, activeRelief), 0, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-autorange", "autoRange", "AutoRange",
   "0", -1, Tk_Offset(AxisOptions, windowSize), 0, NULL, RESET},
  {TK_OPTION_BORDER, "-background", "background", "Background",
   NULL, -1, Tk_Offset(AxisOptions, normalBg), TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_CUSTOM, "-bindtags", "bindTags", "BindTags",
   "all", -1, Tk_Offset(AxisOptions, tags), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(AxisOptions, borderWidth), 0, NULL, LAYOUT},
  {TK_OPTION_BOOLEAN, "-checklimits", "checkLimits", "CheckLimits", 
   "no", -1, Tk_Offset(AxisOptions, checkLimits), 0, NULL, RESET},
  {TK_OPTION_COLOR, "-color", "color", "Color",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(AxisOptions, tickColor), 
   0, NULL, CACHE},
  {TK_OPTION_SYNONYM, "-command", NULL, NULL,
   NULL, 0, -1, 0, (ClientData)"-tickformatcommand", 0},
  {TK_OPTION_BOOLEAN, "-descending", "descending", "Descending",
   "no", -1, Tk_Offset(AxisOptions, descending), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-exterior", "exterior", "exterior",
   "yes", -1, Tk_Offset(AxisOptions, exterior), 0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_SYNONYM, "-foreground", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_BOOLEAN, "-grid", "grid", "Grid",
   "yes", -1, Tk_Offset(AxisOptions, showGrid), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-gridcolor", "gridColor", "GridColor", 
   "gray64", -1, Tk_Offset(AxisOptions, major.color), 0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-griddashes", "gridDashes", "GridDashes", 
   "dot", -1, Tk_Offset(AxisOptions, major.dashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, CACHE},
  {TK_OPTION_PIXELS, "-gridlinewidth", "gridLineWidth", "GridLineWidth",
   "1", -1, Tk_Offset(AxisOptions, major.lineWidth), 0, NULL, CACHE},
  {TK_OPTION_BOOLEAN, "-gridminor", "gridMinor", "GridMinor", 
   "yes", -1, Tk_Offset(AxisOptions, showGridMinor), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-gridminorcolor", "gridMinorColor", "GridMinorColor", 
   "gray64", -1, Tk_Offset(AxisOptions, minor.color), 0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-gridminordashes", "gridMinorDashes", "GridMinorDashes", 
   "dot", -1, Tk_Offset(AxisOptions, minor.dashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, CACHE},
  {TK_OPTION_PIXELS, "-gridminorlinewidth", "gridMinorLineWidth", 
   "GridMinorLineWidth",
   "1", -1, Tk_Offset(AxisOptions, minor.lineWidth), 0, NULL, CACHE},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide",
   "no", -1, Tk_Offset(AxisOptions, hide), 0, NULL, LAYOUT},
  {TK_OPTION_JUSTIFY, "-justify", "justify", "Justify",
   "c", -1, Tk_Offset(AxisOptions, titleJustify), 0, NULL, LAYOUT},
  {TK_OPTION_BOOLEAN, "-labeloffset", "labelOffset", "LabelOffset",
   "no", -1, Tk_Offset(AxisOptions, labelOffset), 0, NULL, LAYOUT},
  {TK_OPTION_COLOR, "-limitscolor", "limitsColor", "LimitsColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(AxisOptions, limitsTextStyle.color), 
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-limitsfont", "limitsFont", "LimitsFont",
   STD_FONT_SMALL, -1, Tk_Offset(AxisOptions, limitsTextStyle.font), 
   0, NULL, LAYOUT},
  {TK_OPTION_STRING, "-limitsformat", "limitsFormat", "LimitsFormat",
   NULL, -1, Tk_Offset(AxisOptions, limitsFormat), 
   TK_OPTION_NULL_OK, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "LineWidth",
   "1", -1, Tk_Offset(AxisOptions, lineWidth), 0, NULL, LAYOUT},
  {TK_OPTION_BOOLEAN, "-logscale", "logScale", "LogScale",
   "no", -1, Tk_Offset(AxisOptions, logScale), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-loosemin", "looseMin", "LooseMin", 
   "no", -1, Tk_Offset(AxisOptions, looseMin), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-loosemax", "looseMax", "LooseMax", 
   "no", -1, Tk_Offset(AxisOptions, looseMax), 0, NULL, RESET},
  {TK_OPTION_CUSTOM, "-majorticks", "majorTicks", "MajorTicks",
   NULL, -1, Tk_Offset(AxisOptions, t1UPtr), 
   TK_OPTION_NULL_OK, &ticksObjOption, RESET},
  {TK_OPTION_CUSTOM, "-max", "max", "Max", 
   NULL, -1, Tk_Offset(AxisOptions, reqMax), 
   TK_OPTION_NULL_OK, &limitObjOption, RESET},
  {TK_OPTION_CUSTOM, "-min", "min", "Min", 
   NULL, -1, Tk_Offset(AxisOptions, reqMin), 
   TK_OPTION_NULL_OK, &limitObjOption, RESET},
  {TK_OPTION_CUSTOM, "-minorticks", "minorTicks", "MinorTicks",
   NULL, -1, Tk_Offset(AxisOptions, t2UPtr), 
   TK_OPTION_NULL_OK, &ticksObjOption, RESET},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief",
   "flat", -1, Tk_Offset(AxisOptions, relief), 0, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-rotate", "rotate", "Rotate", 
   "0", -1, Tk_Offset(AxisOptions, tickAngle), 0, NULL, LAYOUT},
  {TK_OPTION_CUSTOM, "-scrollcommand", "scrollCommand", "ScrollCommand",
   NULL, -1, Tk_Offset(AxisOptions, scrollCmdObjPtr), 
   TK_OPTION_NULL_OK, &objectObjOption, 0},
  {TK_OPTION_PIXELS, "-scrollincrement", "scrollIncrement", "ScrollIncrement",
   "10", -1, Tk_Offset(AxisOptions, scrollUnits), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-scrollmax", "scrollMax", "ScrollMax", 
   NULL, -1, Tk_Offset(AxisOptions, reqScrollMax),  
   TK_OPTION_NULL_OK, &limitObjOption, 0},
  {TK_OPTION_CUSTOM, "-scrollmin", "scrollMin", "ScrollMin", 
   NULL, -1, Tk_Offset(AxisOptions, reqScrollMin), 
   TK_OPTION_NULL_OK, &limitObjOption, 0},
  {TK_OPTION_DOUBLE, "-shiftby", "shiftBy", "ShiftBy",
   "0", -1, Tk_Offset(AxisOptions, shiftBy), 0, NULL, RESET},
  {TK_OPTION_BOOLEAN, "-showticks", "showTicks", "ShowTicks",
   "yes", -1, Tk_Offset(AxisOptions, showTicks), 0, NULL, LAYOUT},
  {TK_OPTION_DOUBLE, "-stepsize", "stepSize", "StepSize",
   "0", -1, Tk_Offset(AxisOptions, reqStep), 0, NULL, RESET},
  {TK_OPTION_INT, "-subdivisions", "subdivisions", "Subdivisions",
   "2", -1, Tk_Offset(AxisOptions, reqNumMinorTicks), 0, NULL, RESET},
  {TK_OPTION_ANCHOR, "-tickanchor", "tickAnchor", "Anchor",
   "c", -1, Tk_Offset(AxisOptions, reqTickAnchor), 0, NULL, LAYOUT},
  {TK_OPTION_FONT, "-tickfont", "tickFont", "Font",
   STD_FONT_SMALL, -1, Tk_Offset(AxisOptions, tickFont), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-ticklength", "tickLength", "TickLength",
   "8", -1, Tk_Offset(AxisOptions, tickLength), 0, NULL, LAYOUT},
  {TK_OPTION_INT, "-tickdefault", "tickDefault", "TickDefault",
   "4", -1, Tk_Offset(AxisOptions, reqNumMajorTicks), 0, NULL, RESET},
  {TK_OPTION_STRING, "-tickformat", "tickFormat", "TickFormat",
   NULL, -1, Tk_Offset(AxisOptions, tickFormat), TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_STRING, "-tickformatcommand", "tickformatcommand", "TickFormatCommand",
   NULL, -1, Tk_Offset(AxisOptions, tickFormatCmd), TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_STRING, "-title", "title", "Title",
   NULL, -1, Tk_Offset(AxisOptions, title), TK_OPTION_NULL_OK, NULL, LAYOUT},
  {TK_OPTION_BOOLEAN, "-titlealternate", "titleAlternate", "TitleAlternate",
   "no", -1, Tk_Offset(AxisOptions, titleAlternate), 0, NULL, LAYOUT},
  {TK_OPTION_COLOR, "-titlecolor", "titleColor", "TitleColor", 
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(AxisOptions, titleColor), 
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-titlefont", "titleFont", "TitleFont",
   STD_FONT_NORMAL, -1, Tk_Offset(AxisOptions, titleFont), 0, NULL, LAYOUT},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

TickLabel::TickLabel(char* str)
{
  anchorPos.x = DBL_MAX;
  anchorPos.y = DBL_MAX;
  width =0;
  height =0;
  string = dupstr(str);
}

TickLabel::~TickLabel()
{
  delete [] string;
}

Ticks::Ticks(int cnt)
{
  nTicks =cnt;
  values = new double[cnt];
}

Ticks::~Ticks()
{
  delete [] values;
}

Axis::Axis(Graph* graphPtr, const char* name, int margin, Tcl_HashEntry* hPtr)
{
  ops_ = (AxisOptions*)calloc(1, sizeof(AxisOptions));
  AxisOptions* ops = (AxisOptions*)ops_;

  graphPtr_ = graphPtr;
  classId_ = CID_NONE;
  name_ = dupstr(name);
  className_ = dupstr("none");

  hashPtr_ = hPtr;
  refCount_ =0;
  use_ =0;
  active_ =0;		

  link =NULL;
  chain =NULL;

  titlePos_.x =0;
  titlePos_.y =0;
  titleWidth_ =0;
  titleHeight_ =0;	
  min_ =0;
  max_ =0;
  scrollMin_ =0;
  scrollMax_ =0;
  valueRange_.min =0;
  valueRange_.max =0;
  valueRange_.range =0;
  valueRange_.scale =0;
  axisRange_.min =0;
  axisRange_.max =0;
  axisRange_.range =0;
  axisRange_.scale =0;
  prevMin_ =0;
  prevMax_ =0;
  t1Ptr_ =NULL;
  t2Ptr_ =NULL;
  minorSweep_.initial =0;
  minorSweep_.step =0;
  minorSweep_.nSteps =0;
  majorSweep_.initial =0;
  majorSweep_.step =0;
  majorSweep_.nSteps =0;

  margin_ = margin;
  segments_ =NULL;
  nSegments_ =0;
  tickLabels_ = new Chain();
  left_ =0;
  right_ =0;
  top_ =0;
  bottom_ =0;
  width_ =0;
  height_ =0;
  maxTickWidth_ =0;
  maxTickHeight_ =0; 
  tickAnchor_ = TK_ANCHOR_N;
  tickGC_ =NULL;
  activeTickGC_ =NULL;
  titleAngle_ =0;	
  titleAnchor_ = TK_ANCHOR_N;
  screenScale_ =0;
  screenMin_ =0;
  screenRange_ =0;

  ops->reqMin =NAN;
  ops->reqMax =NAN;
  ops->reqScrollMin =NAN;
  ops->reqScrollMax =NAN;

  ops->limitsTextStyle.anchor =TK_ANCHOR_NW;
  ops->limitsTextStyle.color =NULL;
  ops->limitsTextStyle.font =NULL;
  ops->limitsTextStyle.angle =0;
  ops->limitsTextStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(graphPtr_->interp_, optionSpecs);
}

Axis::~Axis()
{
  AxisOptions* ops = (AxisOptions*)ops_;

  graphPtr_->bindTable_->deleteBindings(this);

  if (link)
    chain->deleteLink(link);

  if (hashPtr_)
    Tcl_DeleteHashEntry(hashPtr_);

  delete [] name_;
  delete [] className_;

  if (tickGC_)
    Tk_FreeGC(graphPtr_->display_, tickGC_);

  if (activeTickGC_)
    Tk_FreeGC(graphPtr_->display_, activeTickGC_);

  delete [] ops->major.segments;
  if (ops->major.gc)
    graphPtr_->freePrivateGC(ops->major.gc);

  delete [] ops->minor.segments;
  if (ops->minor.gc)
    graphPtr_->freePrivateGC(ops->minor.gc);

  delete t1Ptr_;
  delete t2Ptr_;

  freeTickLabels();

  delete tickLabels_;

  delete [] segments_;

  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

int Axis::configure()
{
  AxisOptions* ops = (AxisOptions*)ops_;

  // Check the requested axis limits. Can't allow -min to be greater than
  // -max.  Do this regardless of -checklimits option. We want to always 
  // detect when the user has zoomed in beyond the precision of the data

  if (((!isnan(ops->reqMin)) && (!isnan(ops->reqMax))) &&
      (ops->reqMin >= ops->reqMax)) {
      ostringstream str;
      str << "impossible axis limits (-min " << ops->reqMin 
	  << " >= -max " << ops->reqMax << ") for \"" 
	  << name_ << "\"" << ends;
      Tcl_AppendResult(graphPtr_->interp_, str.str().c_str(), NULL);
      return TCL_ERROR;
  }

  scrollMin_ = ops->reqScrollMin;
  scrollMax_ = ops->reqScrollMax;
  if (ops->logScale) {
    if (ops->checkLimits) {
      // Check that the logscale limits are positive.
      if ((!isnan(ops->reqMin)) && (ops->reqMin <= 0.0)) {
	ostringstream str;
	str << "bad logscale -min limit \"" << ops->reqMin 
	    << "\" for axis \"" << name_ << "\"" << ends;
	Tcl_AppendResult(graphPtr_->interp_, str.str().c_str(), NULL);
	return TCL_ERROR;
      }
    }
    if ((!isnan(scrollMin_)) && (scrollMin_ <= 0.0))
      scrollMin_ = NAN;

    if ((!isnan(scrollMax_)) && (scrollMax_ <= 0.0))
      scrollMax_ = NAN;
  }

  double angle = fmod(ops->tickAngle, 360.0);
  if (angle < 0.0)
    angle += 360.0;

  ops->tickAngle = angle;
  resetTextStyles();

  titleWidth_ = titleHeight_ = 0;
  if (ops->title) {
    int w, h;
    graphPtr_->getTextExtents(ops->titleFont, ops->title, -1, &w, &h);
    titleWidth_ = (unsigned int)w;
    titleHeight_ = (unsigned int)h;
  }

  return TCL_OK;
}

void Axis::map(int offset, int margin)
{
  if (isHorizontal()) {
    screenMin_ = graphPtr_->hOffset_;
    width_ = graphPtr_->right_ - graphPtr_->left_;
    screenRange_ = graphPtr_->hRange_;
  }
  else {
    screenMin_ = graphPtr_->vOffset_;
    height_ = graphPtr_->bottom_ - graphPtr_->top_;
    screenRange_ = graphPtr_->vRange_;
  }
  screenScale_ = 1.0 / screenRange_;

  AxisInfo info;
  offsets(margin, offset, &info);
  makeSegments(&info);
}

void Axis::mapStacked(int count, int margin)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if (Chain_GetLength(gops->margins[margin_].axes) > 1 
      || ops->reqNumMajorTicks <= 0)
    ops->reqNumMajorTicks = 4;

  unsigned int slice;
  if (isHorizontal()) {
    slice = graphPtr_->hRange_ / Chain_GetLength(gops->margins[margin].axes);
    screenMin_ = graphPtr_->hOffset_;
    width_ = slice;
  }
  else {
    slice = graphPtr_->vRange_ / Chain_GetLength(gops->margins[margin].axes);
    screenMin_ = graphPtr_->vOffset_;
    height_ = slice;
  }

  int w, h;
  graphPtr_->getTextExtents(ops->tickFont, "0", 1, &w, &h);
  screenMin_ += (slice * count) + 2 + h / 2;
  screenRange_ = slice - 2 * 2 - h;
  screenScale_ = 1.0 / screenRange_;

  AxisInfo info;
  offsets(margin, 0, &info);
  makeSegments(&info);
}

void Axis::mapGridlines()
{
  AxisOptions* ops = (AxisOptions*)ops_;

  Ticks* t1Ptr = t1Ptr_;
  if (!t1Ptr)
    t1Ptr = generateTicks(&majorSweep_);
 
  Ticks* t2Ptr = t2Ptr_;
  if (!t2Ptr)
    t2Ptr = generateTicks(&minorSweep_);

  int needed = t1Ptr->nTicks;
  if (ops->showGridMinor)
    needed += (t1Ptr->nTicks * t2Ptr->nTicks);

  if (needed == 0) {
    if (t1Ptr != t1Ptr_)
      delete t1Ptr;
    if (t2Ptr != t2Ptr_)
      delete t2Ptr;

    return;			
  }

  needed = t1Ptr->nTicks;
  if (needed != ops->major.nAllocated) {
    delete [] ops->major.segments;
    ops->major.segments = new Segment2d[needed];
    ops->major.nAllocated = needed;
  }
  needed = (t1Ptr->nTicks * t2Ptr->nTicks);
  if (needed != ops->minor.nAllocated) {
    delete [] ops->minor.segments;
    ops->minor.segments = new Segment2d[needed];
    ops->minor.nAllocated = needed;
  }

  Segment2d* s1 = ops->major.segments;
  Segment2d* s2 = ops->minor.segments;
  for (int ii=0; ii<t1Ptr->nTicks; ii++) {
    double value = t1Ptr->values[ii];
    if (ops->showGridMinor) {
      for (int jj=0; jj<t2Ptr->nTicks; jj++) {
	double subValue = value + (majorSweep_.step * t2Ptr->values[jj]);
	if (inRange(subValue, &axisRange_)) {
	  makeGridLine(subValue, s2);
	  s2++;
	}
      }
    }
    if (inRange(value, &axisRange_)) {
      makeGridLine(value, s1);
      s1++;
    }
  }

  if (t1Ptr != t1Ptr_)
    delete t1Ptr;
  if (t2Ptr != t2Ptr_)
    delete t2Ptr;

  ops->major.nUsed = s1 - ops->major.segments;
  ops->minor.nUsed = s2 - ops->minor.segments;
}

void Axis::draw(Drawable drawable)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  if (ops->hide || !use_)
    return;

  if (ops->normalBg) {
    int relief = active_ ? ops->activeRelief : ops->relief;
    Tk_Fill3DRectangle(graphPtr_->tkwin_, drawable, ops->normalBg, 
		       left_, top_, right_ - left_, bottom_ - top_,
		       ops->borderWidth, relief);
  }

  if (ops->title) {
    TextStyle ts(graphPtr_);
    TextStyleOptions* tops = (TextStyleOptions*)ts.ops();

    tops->angle = titleAngle_;
    tops->font = ops->titleFont;
    tops->anchor = titleAnchor_;
    tops->color = active_ ? ops->activeFgColor : ops->titleColor;
    tops->justify = ops->titleJustify;

    ts.xPad_ = 1;
    ts.yPad_ = 0;
    ts.drawText(drawable, ops->title, titlePos_.x, titlePos_.y);
  }

  if (ops->scrollCmdObjPtr) {
    double worldMin = valueRange_.min;
    double worldMax = valueRange_.max;
    if (!isnan(scrollMin_))
      worldMin = scrollMin_;
    if (!isnan(scrollMax_))
      worldMax = scrollMax_;

    double viewMin = min_;
    double viewMax = max_;
    if (viewMin < worldMin)
      viewMin = worldMin;
    if (viewMax > worldMax)
      viewMax = worldMax;

    if (ops->logScale) {
      worldMin = log10(worldMin);
      worldMax = log10(worldMax);
      viewMin = log10(viewMin);
      viewMax = log10(viewMax);
    }

    double worldWidth = worldMax - worldMin;	
    double viewWidth = viewMax - viewMin;
    int isHoriz = isHorizontal();

    double fract;
    if (isHoriz != ops->descending)
      fract = (viewMin - worldMin) / worldWidth;
    else
      fract = (worldMax - viewMax) / worldWidth;

    fract = AdjustViewport(fract, viewWidth / worldWidth);

    if (isHoriz != ops->descending) {
      viewMin = (fract * worldWidth);
      min_ = viewMin + worldMin;
      max_ = min_ + viewWidth;
      viewMax = viewMin + viewWidth;
      if (ops->logScale) {
	min_ = EXP10(min_);
	max_ = EXP10(max_);
      }
      updateScrollbar(graphPtr_->interp_, ops->scrollCmdObjPtr,
		      (int)viewMin, (int)viewMax, (int)worldWidth);
    }
    else {
      viewMax = (fract * worldWidth);
      max_ = worldMax - viewMax;
      min_ = max_ - viewWidth;
      viewMin = viewMax + viewWidth;
      if (ops->logScale) {
	min_ = EXP10(min_);
	max_ = EXP10(max_);
      }
      updateScrollbar(graphPtr_->interp_, ops->scrollCmdObjPtr,
		      (int)viewMax, (int)viewMin, (int)worldWidth);
    }
  }

  if (ops->showTicks) {
    TextStyle ts(graphPtr_);
    TextStyleOptions* tops = (TextStyleOptions*)ts.ops();

    tops->angle = ops->tickAngle;
    tops->font = ops->tickFont;
    tops->anchor = tickAnchor_;
    tops->color = active_ ? ops->activeFgColor : ops->tickColor;

    ts.xPad_ = 2;
    ts.yPad_ = 0;

    for (ChainLink* link = Chain_FirstLink(tickLabels_); link;
	 link = Chain_NextLink(link)) {	
      TickLabel* labelPtr = (TickLabel*)Chain_GetValue(link);
      ts.drawText(drawable, labelPtr->string, labelPtr->anchorPos.x, 
		  labelPtr->anchorPos.y);
    }
  }

  if ((nSegments_ > 0) && (ops->lineWidth > 0)) {	
    GC gc = active_ ? activeTickGC_ : tickGC_;
    graphPtr_->drawSegments(drawable, gc, segments_, nSegments_);
  }
}

void Axis::drawGrids(Drawable drawable) 
{
  AxisOptions* ops = (AxisOptions*)ops_;

  if (ops->hide || !ops->showGrid || !use_)
    return;

  graphPtr_->drawSegments(drawable, ops->major.gc,
			  ops->major.segments, ops->major.nUsed);

  if (ops->showGridMinor)
    graphPtr_->drawSegments(drawable, ops->minor.gc,
			    ops->minor.segments, ops->minor.nUsed);
}

void Axis::drawLimits(Drawable drawable)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if (!ops->limitsFormat)
    return;

  int vMin = graphPtr_->left_ + gops->xPad + 2;
  int vMax = vMin;
  int hMin = graphPtr_->bottom_ - gops->yPad - 2;
  int hMax = hMin;

  const int spacing =8;
  int isHoriz = isHorizontal();
  char* minPtr =NULL;
  char* maxPtr =NULL;
  char minString[200];
  char maxString[200];
  const char* fmt = ops->limitsFormat;
  if (fmt && *fmt) {
    minPtr = minString;
    snprintf(minString, 200, fmt, axisRange_.min);

    maxPtr = maxString;
    snprintf(maxString, 200, fmt, axisRange_.max);
  }
  if (ops->descending) {
    char *tmp = minPtr;
    minPtr = maxPtr;
    maxPtr = tmp;
  }

  TextStyle ts(graphPtr_, &ops->limitsTextStyle);
  if (maxPtr) {
    if (isHoriz) {
      ops->limitsTextStyle.angle = 90.0;
      ops->limitsTextStyle.anchor = TK_ANCHOR_SE;

      int ww, hh;
      ts.drawTextBBox(drawable, maxPtr, graphPtr_->right_, hMax, &ww, &hh);
      hMax -= (hh + spacing);
    } 
    else {
      ops->limitsTextStyle.angle = 0.0;
      ops->limitsTextStyle.anchor = TK_ANCHOR_NW;

      int ww, hh;
      ts.drawTextBBox(drawable, maxPtr, vMax, graphPtr_->top_, &ww, &hh);
      vMax += (ww + spacing);
    }
  }
  if (minPtr) {
    ops->limitsTextStyle.anchor = TK_ANCHOR_SW;

    if (isHoriz) {
      ops->limitsTextStyle.angle = 90.0;

      int ww, hh;
      ts.drawTextBBox(drawable, minPtr, graphPtr_->left_, hMin, &ww, &hh);
      hMin -= (hh + spacing);
    } 
    else {
      ops->limitsTextStyle.angle = 0.0;

      int ww, hh;
      ts.drawTextBBox(drawable, minPtr, vMin, graphPtr_->bottom_, &ww, &hh);
      vMin += (ww + spacing);
    }
  }
}

void Axis::setClass(ClassId classId)
{
  delete [] className_;

  classId_ = classId;
  switch (classId) {
  case CID_NONE:
    className_ = dupstr("none");
    break;
  case CID_AXIS_X:
    className_ = dupstr("XAxis");
    break;
  case CID_AXIS_Y:
    className_ = dupstr("YAxis");
    break;
  default:
    className_ = NULL;
    break;
  }
}

void Axis::logScale(double min, double max)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  double range;
  double tickMin, tickMax;
  double majorStep, minorStep;
  int nMajor, nMinor;

  nMajor = nMinor = 0;
  majorStep = minorStep = 0.0;
  tickMin = tickMax = NAN;
  if (min < max) {
    min = (min != 0.0) ? log10(fabs(min)) : 0.0;
    max = (max != 0.0) ? log10(fabs(max)) : 1.0;

    tickMin = floor(min);
    tickMax = ceil(max);
    range = tickMax - tickMin;
	
    if (range > 10) {
      // There are too many decades to display a major tick at every
      // decade.  Instead, treat the axis as a linear scale
      range = niceNum(range, 0);
      majorStep = niceNum(range / ops->reqNumMajorTicks, 1);
      tickMin = floor(tickMin/majorStep)*majorStep;
      tickMax = ceil(tickMax/majorStep)*majorStep;
      nMajor = (int)((tickMax - tickMin) / majorStep) + 1;
      minorStep = EXP10(floor(log10(majorStep)));
      if (minorStep == majorStep) {
	nMinor = 4;
	minorStep = 0.2;
      }
      else
	nMinor = (int)(majorStep/minorStep) - 1;
    }
    else {
      if (tickMin == tickMax)
	tickMax++;
      majorStep = 1.0;
      nMajor = (int)(tickMax - tickMin + 1); /* FIXME: Check this. */
	    
      minorStep = 0.0;		/* This is a special hack to pass
				 * information to the GenerateTicks
				 * routine. An interval of 0.0 tells 1)
				 * this is a minor sweep and 2) the axis
				 * is log scale. */
      nMinor = 10;
    }
    if (!ops->looseMin || (ops->looseMin && !isnan(ops->reqMin))) {
      tickMin = min;
      nMajor++;
    }
    if (!ops->looseMax || (ops->looseMax && !isnan(ops->reqMax))) {
      tickMax = max;
    }
  }
  majorSweep_.step = majorStep;
  majorSweep_.initial = floor(tickMin);
  majorSweep_.nSteps = nMajor;
  minorSweep_.initial = minorSweep_.step = minorStep;
  minorSweep_.nSteps = nMinor;

  setRange(&axisRange_, tickMin, tickMax);
}

void Axis::linearScale(double min, double max)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  unsigned int nTicks = 0;
  double step = 1.0;
  double axisMin =NAN;
  double axisMax =NAN;
  double tickMin =NAN;
  double tickMax =NAN;

  if (min < max) {
    double range = max - min;
    if (ops->reqStep > 0.0) {
      step = ops->reqStep;
      while ((2 * step) >= range && step >= (2 * DBL_EPSILON)) {
	step *= 0.5;
      }
    }
    else {
      range = niceNum(range, 0);
      step = niceNum(range / ops->reqNumMajorTicks, 1);
    }
    if (step >= DBL_EPSILON) {
	axisMin = tickMin = floor(min / step) * step + 0.0;
	axisMax = tickMax = ceil(max / step) * step + 0.0;
	nTicks = (int)((tickMax-tickMin) / step) + 1;
    } else {
	/*
	 * A zero step can result from having a too small range, such that
	 * the floating point can no longer represent fractions of it (think
	 * subnormals).  In such a case, let's just have two steps: the
	 * minimum and the maximum.
	 */
	axisMin = tickMin = min;
	axisMax = tickMax = min + DBL_EPSILON;
	step = DBL_EPSILON;
	nTicks = 2;
    }
  } 
  majorSweep_.step = step;
  majorSweep_.initial = tickMin;
  majorSweep_.nSteps = nTicks;

  /*
   * The limits of the axis are either the range of the data ("tight") or at
   * the next outer tick interval ("loose").  The looseness or tightness has
   * to do with how the axis fits the range of data values.  This option is
   * overridden when the user sets an axis limit (by either -min or -max
   * option).  The axis limit is always at the selected limit (otherwise we
   * assume that user would have picked a different number).
   */
  if (!ops->looseMin || (ops->looseMin && !isnan(ops->reqMin)))
    axisMin = min;

  if (!ops->looseMax || (ops->looseMax && !isnan(ops->reqMax)))
    axisMax = max;

  setRange(&axisRange_, axisMin, axisMax);

  if (ops->reqNumMinorTicks > 0) {
    nTicks = ops->reqNumMinorTicks - 1;
    step = 1.0 / (nTicks + 1);
  } 
  else {
    nTicks = 0;
    step = 0.5;
  }
  minorSweep_.initial = minorSweep_.step = step;
  minorSweep_.nSteps = nTicks;
}

void Axis::setRange(AxisRange *rangePtr, double min, double max)
{
  rangePtr->min = min;
  rangePtr->max = max;
  rangePtr->range = max - min;
  if (fabs(rangePtr->range) < DBL_EPSILON) {
    rangePtr->range = DBL_EPSILON;
  }
  rangePtr->scale = 1.0 / rangePtr->range;
}

void Axis::fixRange()
{
  AxisOptions* ops = (AxisOptions*)ops_;

  // When auto-scaling, the axis limits are the bounds of the element data.
  // If no data exists, set arbitrary limits (wrt to log/linear scale).
  double min = valueRange_.min;
  double max = valueRange_.max;

  // Check the requested axis limits. Can't allow -min to be greater
  // than -max, or have undefined log scale limits.  */
  if (((!isnan(ops->reqMin)) && (!isnan(ops->reqMax))) &&
      (ops->reqMin >= ops->reqMax)) {
    ops->reqMin = ops->reqMax = NAN;
  }
  if (ops->reqMin < -DBL_MAX) {
    ops->reqMin = -DBL_MAX;
  }
  if (ops->reqMax > DBL_MAX) {
    ops->reqMax = DBL_MAX;
  }
  if (ops->logScale) {
    if ((!isnan(ops->reqMin)) && (ops->reqMin <= 0.0))
      ops->reqMin = NAN;

    if ((!isnan(ops->reqMax)) && (ops->reqMax <= 0.0))
      ops->reqMax = NAN;
  }

  if (min == DBL_MAX) {
    if (!isnan(ops->reqMin))
      min = ops->reqMin;
    else
      min = (ops->logScale) ? 0.001 : 0.0;
  }
  if (max == -DBL_MAX) {
    if (!isnan(ops->reqMax))
      max = ops->reqMax;
    else
      max = 1.0;
  }
  if (min >= max) {

    // There is no range of data (i.e. min is not less than max), so
    // manufacture one.
    if (min == 0.0)
      min = 0.0, max = 1.0;
    else
      max = min + (fabs(min) * 0.1);
  }
  setRange(&valueRange_, min, max);

  // The axis limits are either the current data range or overridden by the
  // values selected by the user with the -min or -max options.
  min_ = min;
  max_ = max;
  if (!isnan(ops->reqMin))
    min_ = ops->reqMin;

  if (!isnan(ops->reqMax))
    max_ = ops->reqMax;

  if (max_ < min_) {
    // If the limits still don't make sense, it's because one limit
    // configuration option (-min or -max) was set and the other default
    // (based upon the data) is too small or large.  Remedy this by making
    // up a new min or max from the user-defined limit.
    if (isnan(ops->reqMin))
      min_ = max_ - (fabs(max_) * 0.1);

    if (isnan(ops->reqMax))
      max_ = min_ + (fabs(max_) * 0.1);
  }

  // If a window size is defined, handle auto ranging by shifting the axis
  // limits.
  if ((ops->windowSize > 0.0) && 
      (isnan(ops->reqMin)) && (isnan(ops->reqMax))) {
    if (ops->shiftBy < 0.0)
      ops->shiftBy = 0.0;

    max = min_ + ops->windowSize;
    if (max_ >= max) {
      if (ops->shiftBy > 0.0)
	max = ceil(max_/ops->shiftBy)*ops->shiftBy;
      min_ = max - ops->windowSize;
    }
    max_ = max;
  }
  if ((max_ != prevMax_) || 
      (min_ != prevMin_)) {
    /* and save the previous minimum and maximum values */
    prevMin_ = min_;
    prevMax_ = max_;
  }
}

// Reference: Paul Heckbert, "Nice Numbers for Graph Labels",
// Graphics Gems, pp 61-63.  
double Axis::niceNum(double x, int round)
{
  double expt;			/* Exponent of x */
  double frac;			/* Fractional part of x */
  double nice;			/* Nice, rounded fraction */

  expt = floor(log10(x));
  frac = x / EXP10(expt);		/* between 1 and 10 */
  if (round) {
    if (frac < 1.5) {
      nice = 1.0;
    } else if (frac < 3.0) {
      nice = 2.0;
    } else if (frac < 7.0) {
      nice = 5.0;
    } else {
      nice = 10.0;
    }
  } else {
    if (frac <= 1.0) {
      nice = 1.0;
    } else if (frac <= 2.0) {
      nice = 2.0;
    } else if (frac <= 5.0) {
      nice = 5.0;
    } else {
      nice = 10.0;
    }
  }
  return nice * EXP10(expt);
}

int Axis::inRange(double x, AxisRange *rangePtr)
{
  if (rangePtr->range < DBL_EPSILON)
    return (fabs(rangePtr->max - x) >= DBL_EPSILON);
  else {
    double norm;

    norm = (x - rangePtr->min) * rangePtr->scale;
    return ((norm >= -DBL_EPSILON) && ((norm - 1.0) < DBL_EPSILON));
  }
}

int Axis::isHorizontal()
{
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;
  return ((classId_ == CID_AXIS_Y) == gops->inverted);
}

void Axis::freeTickLabels()
{
  Chain* chain = tickLabels_;
  for (ChainLink* link = Chain_FirstLink(chain); link;
       link = Chain_NextLink(link)) {
    TickLabel* labelPtr = (TickLabel*)Chain_GetValue(link);
    delete labelPtr;
  }
  chain->reset();
}

TickLabel* Axis::makeLabel(double value)
{
#define TICK_LABEL_SIZE		200

  AxisOptions* ops = (AxisOptions*)ops_;

  char string[TICK_LABEL_SIZE + 1];

  // zero out any extremely small numbers
  if (value<DBL_EPSILON && value>-DBL_EPSILON)
    value =0;

  if (ops->tickFormat && *ops->tickFormat) {
    snprintf(string, TICK_LABEL_SIZE, ops->tickFormat, value);
  } else if (ops->logScale) {
    snprintf(string, TICK_LABEL_SIZE, "1E%d", int(value));
  } else {
    snprintf(string, TICK_LABEL_SIZE, "%.15G", value);
  }

  if (ops->tickFormatCmd) {
    Tcl_Interp* interp = graphPtr_->interp_;
    Tk_Window tkwin = graphPtr_->tkwin_;

    // A TCL proc was designated to format tick labels. Append the path
    // name of the widget and the default tick label as arguments when
    // invoking it. Copy and save the new label from interp->result.
    Tcl_ResetResult(interp);
    if (Tcl_VarEval(interp, ops->tickFormatCmd, " ", Tk_PathName(tkwin),
		    " ", string, NULL) != TCL_OK) {
      Tcl_BackgroundError(interp);
    }
    else {
      // The proc could return a string of any length, so arbitrarily
      // limit it to what will fit in the return string.
      strncpy(string, Tcl_GetStringResult(interp), TICK_LABEL_SIZE);
      string[TICK_LABEL_SIZE] = '\0';
	    
      Tcl_ResetResult(interp); /* Clear the interpreter's result. */
    }
  }

  TickLabel* labelPtr = new TickLabel(string);

  return labelPtr;
}

double Axis::invHMap(double x)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  double value;

  x = (double)(x - screenMin_) * screenScale_;
  if (ops->descending) {
    x = 1.0 - x;
  }
  value = (x * axisRange_.range) + axisRange_.min;
  if (ops->logScale) {
    value = EXP10(value);
  }
  return value;
}

double Axis::invVMap(double y)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  double value;

  y = (double)(y - screenMin_) * screenScale_;
  if (ops->descending) {
    y = 1.0 - y;
  }
  value = ((1.0 - y) * axisRange_.range) + axisRange_.min;
  if (ops->logScale) {
    value = EXP10(value);
  }
  return value;
}

double Axis::hMap(double x)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  if ((ops->logScale) && (x != 0.0)) {
    x = log10(fabs(x));
  }
  /* Map graph coordinate to normalized coordinates [0..1] */
  x = (x - axisRange_.min) * axisRange_.scale;
  if (ops->descending) {
    x = 1.0 - x;
  }
  return (x * screenRange_ + screenMin_);
}

double Axis::vMap(double y)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  if ((ops->logScale) && (y != 0.0)) {
    y = log10(fabs(y));
  }
  /* Map graph coordinate to normalized coordinates [0..1] */
  y = (y - axisRange_.min) * axisRange_.scale;
  if (ops->descending) {
    y = 1.0 - y;
  }
  return ((1.0 - y) * screenRange_ + screenMin_);
}

void Axis::getDataLimits(double min, double max)
{
  if (valueRange_.min > min)
    valueRange_.min = min;

  if (valueRange_.max < max)
    valueRange_.max = max;
}

void Axis::resetTextStyles()
{
  AxisOptions* ops = (AxisOptions*)ops_;

  XGCValues gcValues;
  unsigned long gcMask;
  gcMask = (GCForeground | GCLineWidth | GCCapStyle);
  gcValues.foreground = ops->tickColor->pixel;
  gcValues.font = Tk_FontId(ops->tickFont);
  gcValues.line_width = ops->lineWidth;
  gcValues.cap_style = CapProjecting;

  GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
  if (tickGC_)
    Tk_FreeGC(graphPtr_->display_, tickGC_);
  tickGC_ = newGC;

  // Assuming settings from above GC
  gcValues.foreground = ops->activeFgColor->pixel;
  newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
  if (activeTickGC_)
    Tk_FreeGC(graphPtr_->display_, activeTickGC_);
  activeTickGC_ = newGC;

  gcValues.background = gcValues.foreground = ops->major.color->pixel;
  gcValues.line_width = ops->major.lineWidth;
  gcMask = (GCForeground | GCBackground | GCLineWidth);
  if (LineIsDashed(ops->major.dashes)) {
    gcValues.line_style = LineOnOffDash;
    gcMask |= GCLineStyle;
  }
  newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (LineIsDashed(ops->major.dashes))
    graphPtr_->setDashes(newGC, &ops->major.dashes);

  if (ops->major.gc)
    graphPtr_->freePrivateGC(ops->major.gc);

  ops->major.gc = newGC;

  gcValues.background = gcValues.foreground = ops->minor.color->pixel;
  gcValues.line_width = ops->minor.lineWidth;
  gcMask = (GCForeground | GCBackground | GCLineWidth);
  if (LineIsDashed(ops->minor.dashes)) {
    gcValues.line_style = LineOnOffDash;
    gcMask |= GCLineStyle;
  }
  newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (LineIsDashed(ops->minor.dashes))
    graphPtr_->setDashes(newGC, &ops->minor.dashes);

  if (ops->minor.gc)
    graphPtr_->freePrivateGC(ops->minor.gc);

  ops->minor.gc = newGC;
}

void Axis::makeLine(int line, Segment2d *sp)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  double min = axisRange_.min;
  double max = axisRange_.max;
  if (ops->logScale) {
    min = EXP10(min);
    max = EXP10(max);
  }
  if (isHorizontal()) {
    sp->p.x = hMap(min);
    sp->q.x = hMap(max);
    sp->p.y = sp->q.y = line;
  }
  else {
    sp->q.x = sp->p.x = line;
    sp->p.y = vMap(min);
    sp->q.y = vMap(max);
  }
}

void Axis::offsets(int margin, int offset, AxisInfo *infoPtr)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  int axisLine =0;
  int t1 =0;
  int t2 =0;
  int labelOffset =AXIS_PAD_TITLE;
  int tickLabel =0;

  float titleAngle[4] = {0.0, 90.0, 0.0, 270.0};
  titleAngle_ = titleAngle[margin];
  Margin *marginPtr = gops->margins + margin;

  if (ops->lineWidth > 0) {
    if (ops->showTicks) {
      t1 = ops->tickLength;
      t2 = (t1 * 10) / 15;
    }
    labelOffset = t1 + AXIS_PAD_TITLE;
    if (ops->exterior)
      labelOffset += ops->lineWidth;
  }

  int axisPad =0;

  // Adjust offset for the interior border width and the line width */
  // fixme
  int pad = 0;
  //  int pad = 1;
  //  if (graphPtr_->plotBW > 0)
  //    pad += graphPtr_->plotBW + 1;

  // Pre-calculate the x-coordinate positions of the axis, tick labels, and
  // the individual major and minor ticks.
  int inset = pad + ops->lineWidth / 2;

  switch (margin) {
  case MARGIN_TOP:
    {
      int mark = graphPtr_->top_ - offset - pad;
      tickAnchor_ = TK_ANCHOR_S;
      left_ = screenMin_ - inset - 2;
      right_ = screenMin_ + screenRange_ + inset - 1;
      if (gops->stackAxes)
	top_ = mark - marginPtr->axesOffset;
      else
	top_ = mark - height_;
      bottom_ = mark;

      axisLine = bottom_;
      if (ops->exterior) {
	axisLine -= gops->plotBW + axisPad + ops->lineWidth / 2;
	tickLabel = axisLine - 2;
	if (ops->lineWidth > 0)
	  tickLabel -= ops->tickLength;
      } 
      else {
	if (gops->plotRelief == TK_RELIEF_SOLID)
	  axisLine--;

	axisLine -= axisPad + ops->lineWidth / 2;
	tickLabel = graphPtr_->top_ -  gops->plotBW - 2;
      }

      int x, y;
      if (ops->titleAlternate) {
	x = graphPtr_->right_ + AXIS_PAD_TITLE;
	y = mark - (height_  / 2);
	titleAnchor_ = TK_ANCHOR_W;
      }
      else {
	x = (right_ + left_) / 2;
	if (gops->stackAxes)
	  y = mark - marginPtr->axesOffset + AXIS_PAD_TITLE;
	else
	  y = mark - height_ + AXIS_PAD_TITLE;

	titleAnchor_ = TK_ANCHOR_N;
      }
      titlePos_.x = x;
      titlePos_.y = y;
    }
    break;

  case MARGIN_BOTTOM:
    {
      /*
       *  ----------- bottom + plot borderwidth
       *      mark --------------------------------------------
       *          ===================== axisLine (linewidth)
       *                   tick
       *		    title
       *
       *          ===================== axisLine (linewidth)
       *  ----------- bottom + plot borderwidth
       *      mark --------------------------------------------
       *                   tick
       *		    title
       */
      int mark = graphPtr_->bottom_ + offset;
      double fangle = fmod(ops->tickAngle, 90.0);
      if (fangle == 0.0)
	tickAnchor_ = TK_ANCHOR_N;
      else {
	int quadrant = (int)(ops->tickAngle / 90.0);
	if ((quadrant == 0) || (quadrant == 2))
	  tickAnchor_ = TK_ANCHOR_NE;
	else
	  tickAnchor_ = TK_ANCHOR_NW;
      }

      left_ = screenMin_ - inset - 2;
      right_ = screenMin_ + screenRange_ + inset - 1;
      top_ = mark + labelOffset - t1;
      if (gops->stackAxes)
	bottom_ = mark + marginPtr->axesOffset - 1;
      else
	bottom_ = mark + height_ - 1;

      axisLine = top_;
      if (gops->plotRelief == TK_RELIEF_SOLID)
	axisLine++;

      if (ops->exterior) {
	axisLine += gops->plotBW + axisPad + ops->lineWidth / 2;
	tickLabel = axisLine + 2;
	if (ops->lineWidth > 0)
	  tickLabel += ops->tickLength;
      }
      else {
	axisLine -= axisPad + ops->lineWidth / 2;
	tickLabel = graphPtr_->bottom_ +  gops->plotBW + 2;
      }

      int x, y;
      if (ops->titleAlternate) {
	x = graphPtr_->right_ + AXIS_PAD_TITLE;
	y = mark + (height_ / 2);
	titleAnchor_ = TK_ANCHOR_W; 
      }
      else {
	x = (right_ + left_) / 2;
	if (gops->stackAxes)
	  y = mark + marginPtr->axesOffset - AXIS_PAD_TITLE;
	else
	  y = mark + height_ - AXIS_PAD_TITLE;
	titleAnchor_ = TK_ANCHOR_S; 
      }
      titlePos_.x = x;
      titlePos_.y = y;
    }
    break;

  case MARGIN_LEFT:
    {
      /*
       *                    mark
       *                  |  : 
       *                  |  :      
       *                  |  : 
       *                  |  :
       *                  |  : 
       *     axisLine
       */
      /* 
       * Exterior axis 
       *     + plotarea right
       *     |A|B|C|D|E|F|G|H
       *           |right
       * A = plot pad 
       * B = plot border width
       * C = axis pad
       * D = axis line
       * E = tick length
       * F = tick label 
       * G = graph border width
       * H = highlight thickness
       */
      /* 
       * Interior axis 
       *     + plotarea right
       *     |A|B|C|D|E|F|G|H
       *           |right
       * A = plot pad 
       * B = tick length
       * C = axis line width
       * D = axis pad
       * E = plot border width
       * F = tick label 
       * G = graph border width
       * H = highlight thickness
       */
      int mark = graphPtr_->left_ - offset;
      tickAnchor_ = TK_ANCHOR_E;
      if (gops->stackAxes)
	left_ = mark - marginPtr->axesOffset;
      else
	left_ = mark - width_;
      right_ = mark - 3;
      top_ = screenMin_ - inset - 2;
      bottom_ = screenMin_ + screenRange_ + inset - 1;

      axisLine = right_;
      if (ops->exterior) {
	axisLine -= gops->plotBW + axisPad + ops->lineWidth / 2;
	tickLabel = axisLine - 2;
	if (ops->lineWidth > 0)
	  tickLabel -= ops->tickLength;
      }
      else {
	if (gops->plotRelief == TK_RELIEF_SOLID)
	  axisLine--;
	axisLine += axisPad + ops->lineWidth / 2;
	tickLabel = graphPtr_->left_ - gops->plotBW - 2;
      }

      int x, y;
      if (ops->titleAlternate) {
	x = mark - (width_ / 2);
	y = graphPtr_->top_ - AXIS_PAD_TITLE;
	titleAnchor_ = TK_ANCHOR_SW; 
      }
      else {
	if (gops->stackAxes)
	  x = mark - marginPtr->axesOffset;
	else
	  x = mark - width_ + AXIS_PAD_TITLE;
	y = (bottom_ + top_) / 2;
	titleAnchor_ = TK_ANCHOR_W; 
      } 
      titlePos_.x = x;
      titlePos_.y = y;
    }
    break;

  case MARGIN_RIGHT:
    {
      int mark = graphPtr_->right_ + offset + pad;
      tickAnchor_ = TK_ANCHOR_W;
      left_ = mark;
      if (gops->stackAxes)
	right_ = mark + marginPtr->axesOffset - 1;
      else
	right_ = mark + width_ - 1;

      top_ = screenMin_ - inset - 2;
      bottom_ = screenMin_ + screenRange_ + inset -1;

      axisLine = left_;
      if (gops->plotRelief == TK_RELIEF_SOLID)
	axisLine++;

      if (ops->exterior) {
	axisLine += gops->plotBW + axisPad + ops->lineWidth / 2;
	tickLabel = axisLine + 2;
	if (ops->lineWidth > 0)
	  tickLabel += ops->tickLength;
      }
      else {
	axisLine -= axisPad + ops->lineWidth / 2;
	tickLabel = graphPtr_->right_ + gops->plotBW + 2;
      }

      int x, y;
      if (ops->titleAlternate) {
	x = mark + (width_ / 2);
	y = graphPtr_->top_ - AXIS_PAD_TITLE;
	titleAnchor_ = TK_ANCHOR_SE; 
      }
      else {
	if (gops->stackAxes)
	  x = mark + marginPtr->axesOffset - AXIS_PAD_TITLE;
	else
	  x = mark + width_ - AXIS_PAD_TITLE;

	y = (bottom_ + top_) / 2;
	titleAnchor_ = TK_ANCHOR_E;
      }
      titlePos_.x = x;
      titlePos_.y = y;
    }
    break;

  case MARGIN_NONE:
    axisLine = 0;
    break;
  }

  if ((margin == MARGIN_LEFT) || (margin == MARGIN_TOP)) {
    t1 = -t1;
    t2 = -t2;
    labelOffset = -labelOffset;
  }

  infoPtr->axis = axisLine;
  infoPtr->t1 = axisLine + t1;
  infoPtr->t2 = axisLine + t2;
  if (tickLabel > 0)
    infoPtr->label = tickLabel;
  else
    infoPtr->label = axisLine + labelOffset;

  if (!ops->exterior) {
    infoPtr->t1 = axisLine - t1;
    infoPtr->t2 = axisLine - t2;
  } 
}

void Axis::makeTick(double value, int tick, int line, Segment2d *sp)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  if (ops->logScale)
    value = EXP10(value);

  if (isHorizontal()) {
    sp->p.x = hMap(value);
    sp->p.y = line;
    sp->q.x = sp->p.x;
    sp->q.y = tick;
  }
  else {
    sp->p.x = line;
    sp->p.y = vMap(value);
    sp->q.x = tick;
    sp->q.y = sp->p.y;
  }
}

void Axis::makeSegments(AxisInfo *infoPtr)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  delete [] segments_;
  segments_ = NULL;

  Ticks* t1Ptr = ops->t1UPtr ? ops->t1UPtr : t1Ptr_;
  Ticks* t2Ptr = ops->t2UPtr ? ops->t2UPtr : t2Ptr_;

  int nMajorTicks= t1Ptr ? t1Ptr->nTicks : 0;
  int nMinorTicks= t2Ptr ? t2Ptr->nTicks : 0;

  int arraySize = 1 + (nMajorTicks * (nMinorTicks + 1));
  Segment2d* segments = new Segment2d[arraySize];
  Segment2d* sp = segments;
  if (ops->lineWidth > 0) {
    makeLine(infoPtr->axis, sp);
    sp++;
  }

  if (ops->showTicks) {
    int isHoriz = isHorizontal();
    for (int ii=0; ii<nMajorTicks; ii++) {
      double t1 = t1Ptr->values[ii];
      /* Minor ticks */
      for (int jj=0; jj<nMinorTicks; jj++) {
	double t2 = t1 + (majorSweep_.step*t2Ptr->values[jj]);
	if (inRange(t2, &axisRange_)) {
	  makeTick(t2, infoPtr->t2, infoPtr->axis, sp);
	  sp++;
	}
      }
      if (!inRange(t1, &axisRange_))
	continue;

      /* Major tick */
      makeTick(t1, infoPtr->t1, infoPtr->axis, sp);
      sp++;
    }

    ChainLink* link = Chain_FirstLink(tickLabels_);
    double labelPos = (double)infoPtr->label;

    for (int ii=0; ii< nMajorTicks; ii++) {
      double t1 = t1Ptr->values[ii];
      if (ops->labelOffset)
	t1 += majorSweep_.step * 0.5;

      if (!inRange(t1, &axisRange_))
	continue;

      TickLabel* labelPtr = (TickLabel*)Chain_GetValue(link);
      link = Chain_NextLink(link);
      Segment2d seg;
      makeTick(t1, infoPtr->t1, infoPtr->axis, &seg);
      // Save tick label X-Y position
      if (isHoriz) {
	labelPtr->anchorPos.x = seg.p.x;
	labelPtr->anchorPos.y = labelPos;
      }
      else {
	labelPtr->anchorPos.x = labelPos;
	labelPtr->anchorPos.y = seg.p.y;
      }
    }
  }
  segments_ = segments;
  nSegments_ = sp - segments;
}

Ticks* Axis::generateTicks(TickSweep *sweepPtr)
{
  Ticks* ticksPtr = new Ticks(sweepPtr->nSteps);

  if (sweepPtr->step == 0.0) { 
    // Hack: A zero step indicates to use log values
    // Precomputed log10 values [1..10]
    static double logTable[] = {
      0.0, 
      0.301029995663981, 
      0.477121254719662, 
      0.602059991327962, 
      0.698970004336019, 
      0.778151250383644, 
      0.845098040014257,
      0.903089986991944, 
      0.954242509439325, 
      1.0
    };
    for (int ii=0; ii<sweepPtr->nSteps; ii++)
      ticksPtr->values[ii] = logTable[ii];
  }
  else {
    double value = sweepPtr->initial;
    for (int ii=0; ii<sweepPtr->nSteps; ii++) {
      value = (value/sweepPtr->step)*sweepPtr->step;
      ticksPtr->values[ii] = value;
      value += sweepPtr->step;
    }
  }

  return ticksPtr;
}

void Axis::makeGridLine(double value, Segment2d *sp)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  if (ops->logScale)
    value = EXP10(value);

  if (isHorizontal()) {
    sp->p.x = hMap(value);
    sp->p.y = graphPtr_->top_;
    sp->q.x = sp->p.x;
    sp->q.y = graphPtr_->bottom_;
  }
  else {
    sp->p.x = graphPtr_->left_;
    sp->p.y = vMap(value);
    sp->q.x = graphPtr_->right_;
    sp->q.y = sp->p.y;
  }
}

void Axis::print(PSOutput* psPtr)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  PostscriptOptions* pops = (PostscriptOptions*)graphPtr_->postscript_->ops_;

  if (ops->hide || !use_)
    return;

  psPtr->format("%% Axis \"%s\"\n", name_);
  if (pops->decorations) {
    if (ops->normalBg) {
      int relief = active_ ? ops->activeRelief : ops->relief;
      psPtr->fill3DRectangle(ops->normalBg, left_, top_, 
			     right_-left_, bottom_-top_, 
			     ops->borderWidth, relief);
    }
  }
  else {
    psPtr->setClearBackground();
    psPtr->fillRectangle(left_, top_, right_-left_, bottom_-top_);
  }

  if (ops->title) {
    TextStyle ts(graphPtr_);
    TextStyleOptions* tops = (TextStyleOptions*)ts.ops();

    tops->angle = titleAngle_;
    tops->font = ops->titleFont;
    tops->anchor = titleAnchor_;
    tops->color = active_ ? ops->activeFgColor : ops->titleColor;
    tops->justify = ops->titleJustify;

    ts.xPad_ = 1;
    ts.yPad_ = 0;
    ts.printText(psPtr, ops->title, titlePos_.x, titlePos_.y);
  }

  if (ops->showTicks) {
    TextStyle ts(graphPtr_);
    TextStyleOptions* tops = (TextStyleOptions*)ts.ops();

    tops->angle = ops->tickAngle;
    tops->font = ops->tickFont;
    tops->anchor = tickAnchor_;
    tops->color = active_ ? ops->activeFgColor : ops->tickColor;

    ts.xPad_ = 2;
    ts.yPad_ = 0;

    for (ChainLink* link = Chain_FirstLink(tickLabels_); link; 
	 link = Chain_NextLink(link)) {
      TickLabel *labelPtr = (TickLabel*)Chain_GetValue(link);
      ts.printText(psPtr, labelPtr->string, labelPtr->anchorPos.x, 
		   labelPtr->anchorPos.y);
    }
  }

  if ((nSegments_ > 0) && (ops->lineWidth > 0)) {
    psPtr->setLineAttributes(active_ ? ops->activeFgColor : ops->tickColor,
			     ops->lineWidth, (Dashes*)NULL, CapButt, JoinMiter);
    psPtr->printSegments(segments_, nSegments_);
  }
}

void Axis::printGrids(PSOutput* psPtr)
{
  AxisOptions* ops = (AxisOptions*)ops_;

  if (ops->hide || !ops->showGrid || !use_)
    return;

  psPtr->format("%% Axis %s: grid line attributes\n", name_);
  psPtr->setLineAttributes(ops->major.color, ops->major.lineWidth, 
			    &ops->major.dashes, CapButt, JoinMiter);
  psPtr->format("%% Axis %s: major grid line segments\n", name_);
  psPtr->printSegments(ops->major.segments, ops->major.nUsed);

  if (ops->showGridMinor) {
    psPtr->setLineAttributes(ops->minor.color, ops->minor.lineWidth, 
			     &ops->minor.dashes, CapButt, JoinMiter);
    psPtr->format("%% Axis %s: minor grid line segments\n", name_);
    psPtr->printSegments(ops->minor.segments, ops->minor.nUsed);
  }
}

void Axis::printLimits(PSOutput* psPtr)
{
  AxisOptions* ops = (AxisOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if (!ops->limitsFormat)
    return;

  double vMin = graphPtr_->left_ + gops->xPad + 2;
  double vMax = vMin;
  double hMin = graphPtr_->bottom_ - gops->yPad - 2;
  double hMax = hMin;

  const int spacing =8;
  int isHoriz = isHorizontal();
  char* minPtr =NULL;
  char* maxPtr =NULL;
  char minString[200];
  char maxString[200];
  const char* fmt = ops->limitsFormat;
  if (fmt && *fmt) {
    minPtr = minString;
    snprintf(minString, 200, fmt, axisRange_.min);

    maxPtr = maxString;
    snprintf(maxString, 200, fmt, axisRange_.max);
  }
  if (ops->descending) {
    char *tmp = minPtr;
    minPtr = maxPtr;
    maxPtr = tmp;
  }

  int textWidth, textHeight;
  TextStyle ts(graphPtr_, &ops->limitsTextStyle);
  if (maxPtr) {
    graphPtr_->getTextExtents(ops->tickFont, maxPtr, -1, 
			      &textWidth, &textHeight);
    if ((textWidth > 0) && (textHeight > 0)) {
      if (isHoriz) {
	ops->limitsTextStyle.angle = 90.0;
	ops->limitsTextStyle.anchor = TK_ANCHOR_SE;

	ts.printText(psPtr, maxPtr, graphPtr_->right_, (int)hMax);
	hMax -= (textWidth + spacing);
      } 
      else {
	ops->limitsTextStyle.angle = 0.0;
	ops->limitsTextStyle.anchor = TK_ANCHOR_NW;

	ts.printText(psPtr, maxPtr, (int)vMax, graphPtr_->top_);
	vMax += (textWidth + spacing);
      }
    }
  }

  if (minPtr) {
    graphPtr_->getTextExtents(ops->tickFont, minPtr, -1, 
			      &textWidth, &textHeight);
    if ((textWidth > 0) && (textHeight > 0)) {
      ops->limitsTextStyle.anchor = TK_ANCHOR_SW;

      if (isHoriz) {
	ops->limitsTextStyle.angle = 90.0;

	ts.printText(psPtr, minPtr, graphPtr_->left_, (int)hMin);
	hMin -= (textWidth + spacing);
      }
      else {
	ops->limitsTextStyle.angle = 0.0;

	ts.printText(psPtr, minPtr, (int)vMin, graphPtr_->bottom_);
	vMin += (textWidth + spacing);
      }
    }
  }
}

void Axis::updateScrollbar(Tcl_Interp* interp, Tcl_Obj *scrollCmdObjPtr,
			   int first, int last, int width)
{
  double firstFract =0.0;
  double lastFract = 1.0;
  if (width > 0) {
    firstFract = (double)first / (double)width;
    lastFract = (double)last / (double)width;
  }
  Tcl_Obj *cmdObjPtr = Tcl_DuplicateObj(scrollCmdObjPtr);
  Tcl_ListObjAppendElement(interp, cmdObjPtr, Tcl_NewDoubleObj(firstFract));
  Tcl_ListObjAppendElement(interp, cmdObjPtr, Tcl_NewDoubleObj(lastFract));
  Tcl_IncrRefCount(cmdObjPtr);
  if (Tcl_EvalObjEx(interp, cmdObjPtr, TCL_EVAL_GLOBAL) != TCL_OK) {
    Tcl_BackgroundError(interp);
  }
  Tcl_DecrRefCount(cmdObjPtr);
}

void Axis::getGeometry()
{
  AxisOptions* ops = (AxisOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  freeTickLabels();

  // Leave room for axis baseline and padding
  unsigned int y =0;
  if (ops->exterior && (gops->plotRelief != TK_RELIEF_SOLID))
    y += ops->lineWidth + 2;

  maxTickHeight_ = maxTickWidth_ = 0;

  if (t1Ptr_)
    delete t1Ptr_;
  t1Ptr_ = generateTicks(&majorSweep_);

  if (t2Ptr_)
    delete t2Ptr_;
  t2Ptr_ = generateTicks(&minorSweep_);

  if (ops->showTicks) {
    Ticks* t1Ptr = ops->t1UPtr ? ops->t1UPtr : t1Ptr_;
	
    int nTicks =0;
    if (t1Ptr)
      nTicks = t1Ptr->nTicks;
	
    unsigned int nLabels =0;
    for (int ii=0; ii<nTicks; ii++) {
      double x = t1Ptr->values[ii];
      double x2 = t1Ptr->values[ii];
      if (ops->labelOffset)
	x2 += majorSweep_.step * 0.5;

      if (!inRange(x2, &axisRange_))
	continue;

      TickLabel* labelPtr = makeLabel(x);
      tickLabels_->append(labelPtr);
      nLabels++;

      // Get the dimensions of each tick label.  Remember tick labels
      // can be multi-lined and/or rotated.
      int lw, lh;
      graphPtr_->getTextExtents(ops->tickFont, labelPtr->string, -1, &lw, &lh);
      labelPtr->width  = lw;
      labelPtr->height = lh;

      if (ops->tickAngle != 0.0) {
	// Rotated label width and height
	double rlw, rlh;
	graphPtr_->getBoundingBox(lw, lh, ops->tickAngle, &rlw, &rlh, NULL);
	lw = (int)rlw;
	lh = (int)rlh;
      }
      if (maxTickWidth_ < int(lw))
	maxTickWidth_ = lw;

      if (maxTickHeight_ < int(lh))
	maxTickHeight_ = lh;
    }
	
    unsigned int pad =0;
    if (ops->exterior) {
      // Because the axis cap style is "CapProjecting", we need to
      // account for an extra 1.5 linewidth at the end of each line
      pad = ((ops->lineWidth * 12) / 8);
    }
    if (isHorizontal())
      y += maxTickHeight_ + pad;
    else {
      y += maxTickWidth_ + pad;
      if (maxTickWidth_ > 0)
	// Pad either size of label.
	y += 5;
    }
    y += 2 * AXIS_PAD_TITLE;
    if ((ops->lineWidth > 0) && ops->exterior)
      // Distance from axis line to tick label.
      y += ops->tickLength;

  } // showTicks

  if (ops->title) {
    if (ops->titleAlternate) {
      if (y < titleHeight_)
	y = titleHeight_;
    } 
    else
      y += titleHeight_ + AXIS_PAD_TITLE;
  }

  // Correct for orientation of the axis
  if (isHorizontal())
    height_ = y;
  else
    width_ = y;
}

