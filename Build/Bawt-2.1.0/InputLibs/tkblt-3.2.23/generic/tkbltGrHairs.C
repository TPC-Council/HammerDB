/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1993-2004 George A Howlett.
 *
 *	Permission is hereby granted, free of charge, to any person
 *	obtaining a copy of this software and associated documentation
 *	files (the "Software"), to deal in the Software without
 *	restriction, including without limitation the rights to use,
 *	copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the
 *	Software is furnished to do so, subject to the following
 *	conditions:
 *
 *	The above copyright notice and this permission notice shall be
 *	included in all copies or substantial portions of the
 *	Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 *	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 *	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 *	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 *	OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 *	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 *	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdlib.h>

#include "tkbltGraph.h"
#include "tkbltGrHairs.h"
#include "tkbltConfig.h"

using namespace Blt;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_COLOR, "-color", "color", "Color", 
   "green", -1, Tk_Offset(CrosshairsOptions, colorPtr), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-dashes", "dashes", "Dashes", 
   NULL, -1, Tk_Offset(CrosshairsOptions, dashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, 0},
  {TK_OPTION_PIXELS, "-linewidth", "lineWidth", "Linewidth",
   "1", -1, Tk_Offset(CrosshairsOptions, lineWidth), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-x", "x", "X",
   "0", -1, Tk_Offset(CrosshairsOptions, x), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-y", "y", "Y",
   "0", -1, Tk_Offset(CrosshairsOptions, y), 0, NULL, 0},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

Crosshairs::Crosshairs(Graph* graphPtr)
{
  ops_ = (CrosshairsOptions*)calloc(1, sizeof(CrosshairsOptions));

  graphPtr_ = graphPtr;
  visible_ =0;
  gc_ =NULL;

  optionTable_ = Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);
  Tk_InitOptions(graphPtr->interp_, (char*)ops_, optionTable_, 
		 graphPtr->tkwin_);
}

Crosshairs::~Crosshairs()
{
  if (gc_)
    graphPtr_->freePrivateGC(gc_);

  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

// Configure

int Crosshairs::configure()
{
  CrosshairsOptions* ops = (CrosshairsOptions*)ops_;

  XGCValues gcValues;
  gcValues.foreground = ops->colorPtr->pixel;
  gcValues.line_width = ops->lineWidth;
  unsigned long gcMask = (GCForeground | GCLineWidth);
  if (LineIsDashed(ops->dashes)) {
    gcValues.line_style = LineOnOffDash;
    gcMask |= GCLineStyle;
  }
  GC newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (LineIsDashed(ops->dashes))
    graphPtr_->setDashes(newGC, &ops->dashes);

  if (gc_)
    graphPtr_->freePrivateGC(gc_);
  gc_ = newGC;

  // Are the new coordinates on the graph?
  map();

  return TCL_OK;
}

void Crosshairs::map()
{
  CrosshairsOptions* ops = (CrosshairsOptions*)ops_;

  segArr_[0].x = ops->x;
  segArr_[1].x = ops->x;
  segArr_[0].y = graphPtr_->bottom_;
  segArr_[1].y = graphPtr_->top_;
  segArr_[2].y = ops->y;
  segArr_[3].y = ops->y;
  segArr_[2].x = graphPtr_->left_;
  segArr_[3].x = graphPtr_->right_;
}

void Crosshairs::on()
{
  visible_ =1;
}

void Crosshairs::off()
{
  visible_ =0;
}

void Crosshairs::draw(Drawable drawable)
{
  CrosshairsOptions* ops = (CrosshairsOptions*)ops_;

  if (visible_ && Tk_IsMapped(graphPtr_->tkwin_)) {
    if (ops->x <= graphPtr_->right_ &&
	ops->x >= graphPtr_->left_ &&
	ops->y <= graphPtr_->bottom_ &&
	ops->y >= graphPtr_->top_) {
      XDrawLine(graphPtr_->display_, drawable, gc_, 
		segArr_[0].x, segArr_[0].y, segArr_[1].x, segArr_[1].y);
      XDrawLine(graphPtr_->display_, drawable, gc_, 
		segArr_[2].x, segArr_[2].y, segArr_[3].x, segArr_[3].y);
    }
  }
}
