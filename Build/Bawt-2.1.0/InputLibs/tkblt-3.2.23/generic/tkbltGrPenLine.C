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

#include <stdlib.h>
#include <string.h>

#include "tkbltGrPenLine.h"
#include "tkbltGraph.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"

using namespace Blt;

const char* symbolObjOption[] = 
  {"none", "square", "circle", "diamond", "plus", "cross", "splus", "scross", "triangle", "arrow", NULL};

// Defs

static Tk_OptionSpec linePenOptionSpecs[] = {
  {TK_OPTION_COLOR, "-color", "color", "Color", 
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LinePenOptions, traceColor), 
   0, NULL, CACHE},
  {TK_OPTION_CUSTOM, "-dashes", "dashes", "Dashes", 
   NULL, -1, Tk_Offset(LinePenOptions, traceDashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, CACHE},
  {TK_OPTION_COLOR, "-errorbarcolor", "errorBarColor", "ErrorBarColor",
   NULL, -1, Tk_Offset(LinePenOptions, errorBarColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarwidth", "errorBarWidth", "ErrorBarWidth",
   "1", -1, Tk_Offset(LinePenOptions, errorBarLineWidth), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarcap", "errorBarCap", "ErrorBarCap", 
   "0", -1, Tk_Offset(LinePenOptions, errorBarCapWidth), 0, NULL, LAYOUT},
  {TK_OPTION_COLOR, "-fill", "fill", "Fill", 
   NULL, -1, Tk_Offset(LinePenOptions, symbol.fillColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "LineWidth",
   "1", -1, Tk_Offset(LinePenOptions, traceWidth), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-offdash", "offDash", "OffDash", 
   NULL, -1, Tk_Offset(LinePenOptions, traceOffColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline", 
   NULL, -1, Tk_Offset(LinePenOptions, symbol.outlineColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-outlinewidth", "outlineWidth", "OutlineWidth",
   "1", -1, Tk_Offset(LinePenOptions, symbol.outlineWidth), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-pixels", "pixels", "Pixels", 
   "0.1i", -1, Tk_Offset(LinePenOptions, symbol.size), 0, NULL, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showerrorbars", "showErrorBars", "ShowErrorBars",
   "both", -1, Tk_Offset(LinePenOptions, errorBarShow), 
   0, &fillObjOption, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showvalues", "showValues", "ShowValues",
   "none", -1, Tk_Offset(LinePenOptions, valueShow), 0, &fillObjOption, CACHE},
  {TK_OPTION_STRING_TABLE, "-symbol", "symbol", "Symbol",
   "none", -1, Tk_Offset(LinePenOptions, symbol), 0, &symbolObjOption, CACHE},
  {TK_OPTION_ANCHOR, "-valueanchor", "valueAnchor", "ValueAnchor",
   "s", -1, Tk_Offset(LinePenOptions, valueStyle.anchor), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-valuecolor", "valueColor", "ValueColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LinePenOptions, valueStyle.color), 
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-valuefont", "valueFont", "ValueFont",
   STD_FONT_SMALL, -1, Tk_Offset(LinePenOptions, valueStyle.font), 
   0, NULL, CACHE},
  {TK_OPTION_STRING, "-valueformat", "valueFormat", "ValueFormat",
   "%g", -1, Tk_Offset(LinePenOptions, valueFormat), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-valuerotate", "valueRotate", "ValueRotate",
   "0", -1, Tk_Offset(LinePenOptions, valueStyle.angle), 0, NULL, CACHE},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

LinePen::LinePen(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
  : Pen(graphPtr, name, hPtr)
{
  ops_ = calloc(1, sizeof(LinePenOptions));
  LinePenOptions* ops = (LinePenOptions*)ops_;
  manageOptions_ =1;

  traceGC_ =NULL;
  errorBarGC_ =NULL;

  ops->symbol.type = SYMBOL_NONE;

  ops->valueStyle.anchor =TK_ANCHOR_NW;
  ops->valueStyle.color =NULL;
  ops->valueStyle.font =NULL;
  ops->valueStyle.angle =0;
  ops->valueStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(graphPtr_->interp_, linePenOptionSpecs);
}

LinePen::LinePen(Graph* graphPtr, const char* name, void* options)
  : Pen(graphPtr, name, NULL)
{
  ops_ = options;
  LinePenOptions* ops = (LinePenOptions*)ops_;
  manageOptions_ =0;

  traceGC_ =NULL;
  errorBarGC_ =NULL;

  ops->symbol.type = SYMBOL_NONE;

  ops->valueStyle.anchor =TK_ANCHOR_NW;
  ops->valueStyle.color =NULL;
  ops->valueStyle.font =NULL;
  ops->valueStyle.angle =0;
  ops->valueStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(graphPtr_->interp_, linePenOptionSpecs);
}

LinePen::~LinePen()
{
  LinePenOptions* ops = (LinePenOptions*)ops_;
  
  if (errorBarGC_)
    Tk_FreeGC(graphPtr_->display_, errorBarGC_);

  if (traceGC_)
    graphPtr_->freePrivateGC(traceGC_);

  if (ops->symbol.outlineGC)
    Tk_FreeGC(graphPtr_->display_, ops->symbol.outlineGC);

  if (ops->symbol.fillGC)
    Tk_FreeGC(graphPtr_->display_, ops->symbol.fillGC);
}

int LinePen::configure()
{
  LinePenOptions* ops = (LinePenOptions*)ops_;

  // symbol outline
  {
    unsigned long gcMask = (GCLineWidth | GCForeground);
    XColor* colorPtr = ops->symbol.outlineColor;
    if (!colorPtr)
      colorPtr = ops->traceColor;
    XGCValues gcValues;
    gcValues.foreground = colorPtr->pixel;
    gcValues.line_width = ops->symbol.outlineWidth;
    GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
    if (ops->symbol.outlineGC)
      Tk_FreeGC(graphPtr_->display_, ops->symbol.outlineGC);
    ops->symbol.outlineGC = newGC;
  }

  // symbol fill
  {
    unsigned long gcMask = (GCLineWidth | GCForeground);
    XColor* colorPtr = ops->symbol.fillColor;
    if (!colorPtr)
      colorPtr = ops->traceColor;
    GC newGC = NULL;
    XGCValues gcValues;
    if (colorPtr) {
      gcValues.foreground = colorPtr->pixel;
      newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
    }
    if (ops->symbol.fillGC)
      Tk_FreeGC(graphPtr_->display_, ops->symbol.fillGC);
    ops->symbol.fillGC = newGC;
  }

  // trace
  {
    unsigned long gcMask = 
      (GCLineWidth | GCForeground | GCLineStyle | GCCapStyle | GCJoinStyle);
    XGCValues gcValues;
    gcValues.cap_style = CapButt;
    gcValues.join_style = JoinRound;
    gcValues.line_style = LineSolid;
    gcValues.line_width = ops->traceWidth;

    gcValues.foreground = ops->traceColor->pixel;
    XColor* colorPtr = ops->traceOffColor;
    if (colorPtr) {
      gcMask |= GCBackground;
      gcValues.background = colorPtr->pixel;
    }
    if (LineIsDashed(ops->traceDashes)) {
      gcValues.line_width = ops->traceWidth;
      gcValues.line_style = !colorPtr ? LineOnOffDash : LineDoubleDash;
    }
    GC newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
    if (traceGC_)
      graphPtr_->freePrivateGC(traceGC_);

    if (LineIsDashed(ops->traceDashes)) {
      ops->traceDashes.offset = ops->traceDashes.values[0] / 2;
      graphPtr_->setDashes(newGC, &ops->traceDashes);
    }
    traceGC_ = newGC;
  }

  // errorbar
  {
    unsigned long gcMask = (GCLineWidth | GCForeground);
    XColor* colorPtr = ops->errorBarColor;
    if (!colorPtr)
      colorPtr = ops->traceColor;
    XGCValues gcValues;
    gcValues.line_width = ops->errorBarLineWidth;
    gcValues.foreground = colorPtr->pixel;
    GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
    if (errorBarGC_) {
      Tk_FreeGC(graphPtr_->display_, errorBarGC_);
    }
    errorBarGC_ = newGC;
  }

  return TCL_OK;
}


