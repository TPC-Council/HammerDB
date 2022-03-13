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

#include "tkbltGrPenBar.h"
#include "tkbltGraph.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"

using namespace Blt;

static Tk_OptionSpec barPenOptionSpecs[] = {
  {TK_OPTION_SYNONYM, "-background", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(BarPenOptions, borderWidth), 0, NULL, CACHE},
  {TK_OPTION_BORDER, "-color", "color", "Color",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(BarPenOptions, fill), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-errorbarcolor", "errorBarColor", "ErrorBarColor",
   NULL, -1, Tk_Offset(BarPenOptions, errorBarColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarwidth", "errorBarWidth","ErrorBarWidth",
   "1", -1, Tk_Offset(BarPenOptions, errorBarLineWidth), 0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-errorbarcap", "errorBarCap", "ErrorBarCap", 
   "0", -1, Tk_Offset(BarPenOptions, errorBarCapWidth), 0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-outline", 0},
  {TK_OPTION_SYNONYM, "-fill", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-color", 0},
  {TK_OPTION_SYNONYM, "-foreground", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-outline", 0},
  {TK_OPTION_COLOR, "-outline", "outline", "Outline",
   NULL, -1, Tk_Offset(BarPenOptions, outlineColor), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief",
   "raised", -1, Tk_Offset(BarPenOptions, relief), 0, NULL, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showerrorbars", "showErrorBars", "ShowErrorBars",
   "both", -1, Tk_Offset(BarPenOptions, errorBarShow), 
   0, &fillObjOption, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-showvalues", "showValues", "ShowValues",
   "none", -1, Tk_Offset(BarPenOptions, valueShow), 0, &fillObjOption, CACHE},
  {TK_OPTION_ANCHOR, "-valueanchor", "valueAnchor", "ValueAnchor",
   "s", -1, Tk_Offset(BarPenOptions, valueStyle.anchor), 0, NULL, CACHE},
  {TK_OPTION_COLOR, "-valuecolor", "valueColor", "ValueColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(BarPenOptions, valueStyle.color),
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-valuefont", "valueFont", "ValueFont",
   STD_FONT_SMALL, -1, Tk_Offset(BarPenOptions, valueStyle.font), 
   0, NULL, CACHE},
  {TK_OPTION_STRING, "-valueformat", "valueFormat", "ValueFormat",
   "%g", -1, Tk_Offset(BarPenOptions, valueFormat), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_DOUBLE, "-valuerotate", "valueRotate", "ValueRotate",
   "0", -1, Tk_Offset(BarPenOptions, valueStyle.angle), 0, NULL, CACHE},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

BarPen::BarPen(Graph* graphPtr, const char* name, Tcl_HashEntry* hPtr)
  : Pen(graphPtr, name, hPtr)
{
  ops_ = calloc(1, sizeof(BarPenOptions));
  BarPenOptions* ops = (BarPenOptions*)ops_;
  manageOptions_ =1;

  outlineGC_ =NULL;
  errorBarGC_ =NULL;

  ops->valueStyle.anchor =TK_ANCHOR_NW;
  ops->valueStyle.color =NULL;
  ops->valueStyle.font =NULL;
  ops->valueStyle.angle =0;
  ops->valueStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(graphPtr_->interp_, barPenOptionSpecs);
}

BarPen::BarPen(Graph* graphPtr, const char* name, void* options)
  : Pen(graphPtr, name, NULL)
{
  ops_ = options;
  BarPenOptions* ops = (BarPenOptions*)ops_;
  manageOptions_ =0;

  outlineGC_ =NULL;
  errorBarGC_ =NULL;

  ops->valueStyle.anchor =TK_ANCHOR_NW;
  ops->valueStyle.color =NULL;
  ops->valueStyle.font =NULL;
  ops->valueStyle.angle =0;
  ops->valueStyle.justify =TK_JUSTIFY_LEFT;

  optionTable_ = Tk_CreateOptionTable(graphPtr_->interp_, barPenOptionSpecs);
}

BarPen::~BarPen()
{
  if (outlineGC_)
    Tk_FreeGC(graphPtr_->display_, outlineGC_);
  if (errorBarGC_)
    Tk_FreeGC(graphPtr_->display_, errorBarGC_);
}

int BarPen::configure()
{
  BarPenOptions* ops = (BarPenOptions*)ops_;

  // outlineGC
  {
    unsigned long gcMask = GCForeground | GCLineWidth;
    XGCValues gcValues;
    gcValues.line_width = ops->borderWidth;
    if (ops->outlineColor)
      gcValues.foreground = ops->outlineColor->pixel;
    else if (ops->fill)
      gcValues.foreground = Tk_3DBorderColor(ops->fill)->pixel;
    GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
    if (outlineGC_)
      Tk_FreeGC(graphPtr_->display_, outlineGC_);
    outlineGC_ = newGC;
  }

  // errorBarGC
  {
    unsigned long gcMask = GCForeground | GCLineWidth;
    XGCValues gcValues;
    if (ops->errorBarColor)
      gcValues.foreground = ops->errorBarColor->pixel;
    else if (ops->outlineColor)
      gcValues.foreground = ops->outlineColor->pixel;
    else if (ops->fill)
      gcValues.foreground = Tk_3DBorderColor(ops->fill)->pixel;

    gcValues.line_width = ops->errorBarLineWidth;
    GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
    if (errorBarGC_)
      Tk_FreeGC(graphPtr_->display_, errorBarGC_);
    errorBarGC_ = newGC;
  }

  return TCL_OK;
}

