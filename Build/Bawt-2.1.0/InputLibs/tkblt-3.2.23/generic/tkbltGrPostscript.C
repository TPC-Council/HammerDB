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

#include "tkbltGraph.h"
#include "tkbltGrPostscript.h"
#include "tkbltConfig.h"

using namespace Blt;

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_BOOLEAN, "-center", "center", "Center", 
   "yes", -1, Tk_Offset(PostscriptOptions, center), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-comments", "comments", "Comments",
   NULL, -1, Tk_Offset(PostscriptOptions, comments), 
   TK_OPTION_NULL_OK, &listObjOption, 0},
  {TK_OPTION_BOOLEAN, "-decorations", "decorations", "Decorations",
   "yes", -1, Tk_Offset(PostscriptOptions, decorations), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-footer", "footer", "Footer",
   "no", -1, Tk_Offset(PostscriptOptions, footer), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-greyscale", "greyscale", "Greyscale",
   "no", -1, Tk_Offset(PostscriptOptions, greyscale), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-height", "height", "Height", 
   "0", -1, Tk_Offset(PostscriptOptions, reqHeight), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-landscape", "landscape", "Landscape",
   "no", -1, Tk_Offset(PostscriptOptions, landscape), 0, NULL, 0},
  {TK_OPTION_INT, "-level", "level", "Level", 
   "2", -1, Tk_Offset(PostscriptOptions, level), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-padx", "padX", "PadX", 
   "1.0i", -1, Tk_Offset(PostscriptOptions, xPad), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-pady", "padY", "PadY", 
   "1.0i", -1, Tk_Offset(PostscriptOptions, yPad), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-paperheight", "paperHeight", "PaperHeight",
   "11.0i", -1, Tk_Offset(PostscriptOptions, reqPaperHeight), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-paperwidth", "paperWidth", "PaperWidth",
   "8.5i", -1, Tk_Offset(PostscriptOptions, reqPaperWidth), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-width", "width", "Width", 
   "0", -1, Tk_Offset(PostscriptOptions, reqWidth), 0, NULL, 0},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

Postscript::Postscript(Graph* graphPtr)
{
  ops_ = (PostscriptOptions*)calloc(1, sizeof(PostscriptOptions));
  graphPtr_ = graphPtr;

  optionTable_ =Tk_CreateOptionTable(graphPtr_->interp_, optionSpecs);
  Tk_InitOptions(graphPtr_->interp_, (char*)ops_, optionTable_,
		 graphPtr_->tkwin_);
}

Postscript::~Postscript()
{
  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

