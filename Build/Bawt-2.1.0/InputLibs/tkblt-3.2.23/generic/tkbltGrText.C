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

#include <cmath>

#include <tk.h>
#include <tkInt.h>

#include "tkbltGrText.h"
#include "tkbltGraph.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

TextStyle::TextStyle(Graph* graphPtr)
{
  ops_ = (TextStyleOptions*)calloc(1, sizeof(TextStyleOptions));
  TextStyleOptions* ops = (TextStyleOptions*)ops_;
  graphPtr_ = graphPtr;
  manageOptions_ = 1;

  ops->anchor =TK_ANCHOR_NW;
  ops->color =NULL;
  ops->font =NULL;
  ops->angle =0;
  ops->justify =TK_JUSTIFY_LEFT;

  xPad_ = 0;
  yPad_ = 0;
  gc_ = NULL;
}

TextStyle::TextStyle(Graph* graphPtr, TextStyleOptions* ops)
{
  ops_ = (TextStyleOptions*)ops;
  graphPtr_ = graphPtr;
  manageOptions_ = 0;

  xPad_ = 0;
  yPad_ = 0;
  gc_ = NULL;
}

TextStyle::~TextStyle()
{
  //  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  if (gc_)
    Tk_FreeGC(graphPtr_->display_, gc_);

  if (manageOptions_)
    free(ops_);
}

void TextStyle::drawText(Drawable drawable, const char *text, double x, double y) {
  drawText(drawable, text, (int)x, (int)y);
}

void TextStyle::drawText(Drawable drawable, const char *text, int x, int y)
{
  drawTextBBox(drawable, text, x, y, NULL, NULL);
}

void TextStyle::drawTextBBox(Drawable drawable, const char *text,
			     int x, int y, int* ww, int* hh)
{
  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  if (!text || !(*text))
    return;

  if (!gc_)
    resetStyle();

  int w1, h1;
  Tk_TextLayout layout = Tk_ComputeTextLayout(ops->font, text, -1, -1, 
					      ops->justify, 0, &w1, &h1);
  Point2d rr = rotateText(x, y, w1, h1);
#if (TCL_MAJOR_VERSION == 8) && (TCL_MINOR_VERSION >= 6)
  TkDrawAngledTextLayout(graphPtr_->display_, drawable, gc_, layout,
			 (int)rr.x, (int)rr.y, ops->angle, 0, -1);
#else
  Tk_DrawTextLayout(graphPtr_->display_, drawable, gc_, layout,
		    (int)rr.x, (int)rr.y, 0, -1);
#endif
  Tk_FreeTextLayout(layout);

  if (ww && hh) {
    double angle = fmod(ops->angle, 360.0);
    if (angle < 0.0)
      angle += 360.0;

    if (angle != 0.0) {
      double rotWidth, rotHeight;
      graphPtr_->getBoundingBox(w1, h1, angle, &rotWidth, &rotHeight, NULL);
      w1 = (int)rotWidth;
      h1 = (int)rotHeight;
    }

    *ww = w1;
    *hh = h1;
  }
}

void TextStyle::printText(PSOutput* psPtr, const char *text, int x, int y)
{
  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  if (!text || !(*text))
    return;

  int w1, h1;
  Tk_TextLayout layout = Tk_ComputeTextLayout(ops->font, text, -1, -1,
					      ops->justify, 0, &w1, &h1);

  int xx =0;
  int yy =0;
  switch (ops->anchor) {
  case TK_ANCHOR_NW:	   xx = 0; yy = 0; break;
  case TK_ANCHOR_N:	   xx = 1; yy = 0; break;
  case TK_ANCHOR_NE:	   xx = 2; yy = 0; break;
  case TK_ANCHOR_E:	   xx = 2; yy = 1; break;
  case TK_ANCHOR_SE:	   xx = 2; yy = 2; break;
  case TK_ANCHOR_S:	   xx = 1; yy = 2; break;
  case TK_ANCHOR_SW:	   xx = 0; yy = 2; break;
  case TK_ANCHOR_W:	   xx = 0; yy = 1; break;
  case TK_ANCHOR_CENTER: xx = 1; yy = 1; break;
  }

  const char* justify =NULL;
  switch (ops->justify) {
  case TK_JUSTIFY_LEFT:   justify = "0";   break;
  case TK_JUSTIFY_CENTER: justify = "0.5"; break;
  case TK_JUSTIFY_RIGHT:  justify = "1";   break;
  }

  psPtr->setFont(ops->font);
  psPtr->setForeground(ops->color);

  psPtr->format("%g %d %d [\n", ops->angle, x, y);
  Tcl_ResetResult(graphPtr_->interp_);
  Tk_TextLayoutToPostscript(graphPtr_->interp_, layout);
  psPtr->append(Tcl_GetStringResult(graphPtr_->interp_));
  Tcl_ResetResult(graphPtr_->interp_);
  psPtr->format("] %g %g %s DrawText\n", xx/-2.0, yy/-2.0, justify);
}

void TextStyle::printText(PSOutput* psPtr, const char *text, double x, double y) {
  return printText(psPtr, text, (int)x, (int)y);
}

void TextStyle::resetStyle()
{
  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  unsigned long gcMask;
  gcMask = GCFont;

  XGCValues gcValues;
  gcValues.font = Tk_FontId(ops->font);
  if (ops->color) {
    gcMask |= GCForeground;
    gcValues.foreground = ops->color->pixel;
  }
  GC newGC = Tk_GetGC(graphPtr_->tkwin_, gcMask, &gcValues);
  if (gc_)
    Tk_FreeGC(graphPtr_->display_, gc_);

  gc_ = newGC;
}

Point2d TextStyle::rotateText(int x, int y, int w1, int h1)
{
  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  //  Matrix t0 = Translate(-x,-y);
  //  Matrix t1 = Translate(-w1/2,-h1/2);
  //  Matrix rr = Rotate(angle);
  //  Matrix t2 = Translate(w2/2,h2/2);
  //  Matrix t3 = Translate(x,y);

  double angle = ops->angle;
  double ccos = cos(M_PI*angle/180.);
  double ssin = sin(M_PI*angle/180.);
  double w2, h2;
  graphPtr_->getBoundingBox(w1, h1, angle, &w2, &h2, NULL);

  double x1 = x+w1/2.;
  double y1 = y+h1/2.;
  double x2 = w2/2.+x;
  double y2 = h2/2.+y;

  double rx =  x*ccos + y*ssin + (-x1*ccos -y1*ssin +x2);
  double ry = -x*ssin + y*ccos + ( x1*ssin -y1*ccos +y2);

  return graphPtr_->anchorPoint(rx, ry, w2, h2, ops->anchor);
}

void TextStyle::getExtents(const char *text, int* ww, int* hh)
{
  TextStyleOptions* ops = (TextStyleOptions*)ops_;

  int w, h;
  graphPtr_->getTextExtents(ops->font, text, -1, &w, &h);
  *ww = w + 2*xPad_;
  *hh = h + 2*yPad_;
}
