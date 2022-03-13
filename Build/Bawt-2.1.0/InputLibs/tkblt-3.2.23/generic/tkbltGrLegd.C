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

#include <tk.h>
#include <tkInt.h>

#include "tkbltGrBind.h"
#include "tkbltGraph.h"
#include "tkbltGrLegd.h"
#include "tkbltGrElem.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrMisc.h"
#include "tkbltGrDef.h"
#include "tkbltConfig.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

static void SelectCmdProc(ClientData);
static Tk_SelectionProc SelectionProc;

// OptionSpecs

static const char* selectmodeObjOption[] = {
  "single", "multiple", NULL
};
static const char*  positionObjOption[] = {
  "rightmargin", "leftmargin", "topmargin", "bottommargin", 
  "plotarea", "xy", NULL
};

static Tk_OptionSpec optionSpecs[] = {
  {TK_OPTION_BORDER, "-activebackground", "activeBackground",
   "ActiveBackground", 
   STD_ACTIVE_BACKGROUND, -1, Tk_Offset(LegendOptions, activeBg), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-activeborderwidth", "activeBorderWidth", 
   "ActiveBorderWidth", 
   STD_BORDERWIDTH, -1, Tk_Offset(LegendOptions, entryBW), 0, NULL, LAYOUT}, 
  {TK_OPTION_COLOR, "-activeforeground", "activeForeground", "ActiveForeground",
   STD_ACTIVE_FOREGROUND, -1, Tk_Offset(LegendOptions, activeFgColor), 
   0, NULL, CACHE},
  {TK_OPTION_RELIEF, "-activerelief", "activeRelief", "ActiveRelief",
   "flat", -1, Tk_Offset(LegendOptions, activeRelief), 0, NULL, LAYOUT},
  {TK_OPTION_ANCHOR, "-anchor", "anchor", "Anchor", 
   "n", -1, Tk_Offset(LegendOptions, anchor), 0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-bg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-background", 0},
  {TK_OPTION_BORDER, "-background", "background", "Background",
   NULL, -1, Tk_Offset(LegendOptions, normalBg), 
   TK_OPTION_NULL_OK, NULL, CACHE},
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   STD_BORDERWIDTH, -1, Tk_Offset(LegendOptions, borderWidth), 
   0, NULL, LAYOUT}, 
  {TK_OPTION_SYNONYM, "-bd", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-borderwidth", 0},
  {TK_OPTION_INT, "-columns", "columns", "columns",
   "0", -1, Tk_Offset(LegendOptions, reqColumns), 0, NULL, LAYOUT},
  {TK_OPTION_BOOLEAN, "-exportselection", "exportSelection", "ExportSelection", 
   "no",  -1, Tk_Offset(LegendOptions, exportSelection), 0, NULL, LAYOUT},
  {TK_OPTION_CUSTOM, "-focusdashes", "focusDashes", "FocusDashes",
   "dot", -1, Tk_Offset(LegendOptions, focusDashes), 
   TK_OPTION_NULL_OK, &dashesObjOption, CACHE},
  {TK_OPTION_COLOR, "-focusforeground", "focusForeground", "FocusForeground",
   STD_ACTIVE_FOREGROUND, -1, Tk_Offset(LegendOptions, focusColor), 
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-font", "font", "Font", 
   STD_FONT_SMALL, -1, Tk_Offset(LegendOptions, style.font), 0, NULL, LAYOUT},
  {TK_OPTION_SYNONYM, "-fg", NULL, NULL, 
   NULL, 0, -1, 0, (ClientData)"-foreground", 0},
  {TK_OPTION_COLOR, "-foreground", "foreground", "Foreground",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LegendOptions, fgColor), 
   0, NULL, CACHE},
  {TK_OPTION_BOOLEAN, "-hide", "hide", "Hide", 
   "no", -1, Tk_Offset(LegendOptions, hide), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-ipadx", "iPadX", "Pad", 
   "1", -1, Tk_Offset(LegendOptions, ixPad), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-ipady", "iPadY", "Pad", 
   "1", -1, Tk_Offset(LegendOptions, iyPad), 0, NULL, LAYOUT},
  {TK_OPTION_BORDER, "-nofocusselectbackground", "noFocusSelectBackground", 
   "NoFocusSelectBackground", 
   STD_ACTIVE_BACKGROUND, -1, Tk_Offset(LegendOptions, selOutFocusBg), 
   0, NULL, CACHE},
  {TK_OPTION_COLOR, "-nofocusselectforeground", "noFocusSelectForeground", 
   "NoFocusSelectForeground", 
   STD_ACTIVE_FOREGROUND, -1, Tk_Offset(LegendOptions, selOutFocusFgColor), 
   0, NULL, CACHE},
  {TK_OPTION_PIXELS, "-padx", "padX", "Pad", 
   "1", -1, Tk_Offset(LegendOptions, xPad), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-pady", "padY", "Pad", 
   "1", -1, Tk_Offset(LegendOptions, yPad), 0, NULL, LAYOUT},
  {TK_OPTION_STRING_TABLE, "-position", "position", "Position", 
   "rightmargin", -1, Tk_Offset(LegendOptions, position),
   0, &positionObjOption, LAYOUT},
  {TK_OPTION_BOOLEAN, "-raised", "raised", "Raised", 
   "no", -1, Tk_Offset(LegendOptions, raised), 0, NULL, LAYOUT},
  {TK_OPTION_RELIEF, "-relief", "relief", "Relief", 
   "flat", -1, Tk_Offset(LegendOptions, relief), 0, NULL, LAYOUT},
  {TK_OPTION_INT, "-rows", "rows", "rows", 
   "0", -1, Tk_Offset(LegendOptions, reqRows), 0, NULL, LAYOUT},
  {TK_OPTION_BORDER, "-selectbackground", "selectBackground", 
   "SelectBackground", 
   STD_ACTIVE_BACKGROUND, -1, Tk_Offset(LegendOptions, selInFocusBg), 
   0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-selectborderwidth", "selectBorderWidth", 
   "SelectBorderWidth", 
   "1", -1, Tk_Offset(LegendOptions, selBW), 0, NULL, LAYOUT},
  {TK_OPTION_STRING, "-selectcommand", "selectCommand", "SelectCommand",
   NULL, -1, Tk_Offset(LegendOptions, selectCmd), TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_COLOR, "-selectforeground", "selectForeground", "SelectForeground",
   STD_ACTIVE_FOREGROUND, -1, Tk_Offset(LegendOptions, selInFocusFgColor), 
   0, NULL, CACHE},
  {TK_OPTION_STRING_TABLE, "-selectmode", "selectMode", "SelectMode",
   "multiple", -1, Tk_Offset(LegendOptions, selectMode), 
   0, &selectmodeObjOption, 0},
  {TK_OPTION_RELIEF, "-selectrelief", "selectRelief", "SelectRelief",
   "flat", -1, Tk_Offset(LegendOptions, selRelief), 0, NULL, LAYOUT},
  {TK_OPTION_STRING, "-title", "title", "Title", 
   NULL, -1, Tk_Offset(LegendOptions, title), TK_OPTION_NULL_OK, NULL, LAYOUT},
  {TK_OPTION_COLOR, "-titlecolor", "titleColor", "TitleColor",
   STD_NORMAL_FOREGROUND, -1, Tk_Offset(LegendOptions, titleStyle.color), 
   0, NULL, CACHE},
  {TK_OPTION_FONT, "-titlefont", "titleFont", "TitleFont",
   STD_FONT_SMALL, -1, Tk_Offset(LegendOptions, titleStyle.font), 
   0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-x", "x", "X", 
   "0", -1, Tk_Offset(LegendOptions, xReq), 0, NULL, LAYOUT},
  {TK_OPTION_PIXELS, "-y", "y", "Y", 
   "0", -1, Tk_Offset(LegendOptions, yReq), 0, NULL, LAYOUT},
  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, -1, 0, 0, 0}
};

Legend::Legend(Graph* graphPtr)
{
  ops_ = (void*)calloc(1, sizeof(LegendOptions));
  LegendOptions* ops = (LegendOptions*)ops_;

  graphPtr_ = graphPtr;
  flags =0;
  nEntries_ =0;
  nColumns_ =0;
  nRows_ =0;
  width_ =0;
  height_ =0;
  entryWidth_ =0;
  entryHeight_ =0;
  x_ =0;
  y_ =0;
  bindTable_ =NULL;
  focusGC_ =NULL;
  focusPtr_ =NULL;
  selAnchorPtr_ =NULL;
  selMarkPtr_ =NULL;
  selected_ = new Chain();
  titleWidth_ =0;
  titleHeight_ =0;

  ops->style.anchor =TK_ANCHOR_NW;
  ops->style.color =NULL;
  ops->style.font =NULL;
  ops->style.angle =0;
  ops->style.justify =TK_JUSTIFY_LEFT;

  ops->titleStyle.anchor =TK_ANCHOR_NW;
  ops->titleStyle.color =NULL;
  ops->titleStyle.font =NULL;
  ops->titleStyle.angle =0;
  ops->titleStyle.justify =TK_JUSTIFY_LEFT;

  bindTable_ = new BindTable(graphPtr, this);

  Tcl_InitHashTable(&selectTable_, TCL_ONE_WORD_KEYS);

  Tk_CreateSelHandler(graphPtr_->tkwin_, XA_PRIMARY, XA_STRING, 
		      SelectionProc, this, XA_STRING);

  optionTable_ =Tk_CreateOptionTable(graphPtr->interp_, optionSpecs);
  Tk_InitOptions(graphPtr->interp_, (char*)ops_, optionTable_, graphPtr->tkwin_);
}

Legend::~Legend()
{
  //  LegendOptions* ops = (LegendOptions*)ops_;

  delete bindTable_;
    
  if (focusGC_)
    graphPtr_->freePrivateGC(focusGC_);

  if (graphPtr_->tkwin_)
    Tk_DeleteSelHandler(graphPtr_->tkwin_, XA_PRIMARY, XA_STRING);

  delete selected_;

  Tk_FreeConfigOptions((char*)ops_, optionTable_, graphPtr_->tkwin_);
  free(ops_);
}

int Legend::configure()
{
  LegendOptions* ops = (LegendOptions*)ops_;

  // GC for active label, Dashed outline
  unsigned long gcMask = GCForeground | GCLineStyle;
  XGCValues gcValues;
  gcValues.foreground = ops->focusColor->pixel;
  gcValues.line_style = (LineIsDashed(ops->focusDashes))
    ? LineOnOffDash : LineSolid;
  GC newGC = graphPtr_->getPrivateGC(gcMask, &gcValues);
  if (LineIsDashed(ops->focusDashes)) {
    ops->focusDashes.offset = 2;
    graphPtr_->setDashes(newGC, &ops->focusDashes);
  }
  if (focusGC_)
    graphPtr_->freePrivateGC(focusGC_);

  focusGC_ = newGC;

  return TCL_OK;
}

void Legend::map(int plotWidth, int plotHeight)
{
  LegendOptions* ops = (LegendOptions*)ops_;
  
  entryWidth_ =0;
  entryHeight_ = 0;
  nRows_ =0;
  nColumns_ =0;
  nEntries_ =0;
  height_ =0;
  width_ = 0;

  TextStyle tts(graphPtr_, &ops->titleStyle);
  tts.getExtents(ops->title, &titleWidth_, &titleHeight_);

  // Count the number of legend entries and determine the widest and tallest
  // label.  The number of entries would normally be the number of elements,
  // but elements can have no legend entry (-label "").
  int nEntries =0;
  int maxWidth =0;
  int maxHeight =0;
  TextStyle ts(graphPtr_, &ops->style);
  for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList); 
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    int w, h;
    ts.getExtents(elemOps->label, &w, &h);
    if (maxWidth < (int)w)
      maxWidth = w;

    if (maxHeight < (int)h)
      maxHeight = h;

    nEntries++;
  }
  if (nEntries == 0)
    return;

  Tk_FontMetrics fontMetrics;
  Tk_GetFontMetrics(ops->style.font, &fontMetrics);
  int symbolWidth = 2 * fontMetrics.ascent;

  maxWidth += 2 * ops->entryBW + 2*ops->ixPad +
    + symbolWidth + 3 * 2;

  maxHeight += 2 * ops->entryBW + 2*ops->iyPad;

  maxWidth |= 0x01;
  maxHeight |= 0x01;

  int lw = plotWidth - 2 * ops->borderWidth - 2*ops->xPad;
  int lh = plotHeight - 2 * ops->borderWidth - 2*ops->yPad;

  /*
   * The number of rows and columns is computed as one of the following:
   *
   *	both options set		User defined. 
   *  -rows				Compute columns from rows.
   *  -columns			Compute rows from columns.
   *	neither set			Compute rows and columns from
   *					size of plot.  
   */
  int nRows =0;
  int nColumns =0;
  if (ops->reqRows > 0) {
    nRows = MIN(ops->reqRows, nEntries); 
    if (ops->reqColumns > 0)
      nColumns = MIN(ops->reqColumns, nEntries);
    else
      nColumns = ((nEntries - 1) / nRows) + 1; /* Only -rows. */
  }
  else if (ops->reqColumns > 0) { /* Only -columns. */
    nColumns = MIN(ops->reqColumns, nEntries);
    nRows = ((nEntries - 1) / nColumns) + 1;
  }
  else {			
    // Compute # of rows and columns from the legend size
    nRows = lh / maxHeight;
    nColumns = lw / maxWidth;
    if (nRows < 1) {
      nRows = nEntries;
    }
    if (nColumns < 1) {
      nColumns = nEntries;
    }
    if (nRows > nEntries) {
      nRows = nEntries;
    } 
    switch ((Position)ops->position) {
    case TOP:
    case BOTTOM:
      nRows = ((nEntries - 1) / nColumns) + 1;
      break;
    case LEFT:
    case RIGHT:
    default:
      nColumns = ((nEntries - 1) / nRows) + 1;
      break;
    }
  }
  if (nColumns < 1)
    nColumns = 1;

  if (nRows < 1)
    nRows = 1;

  lh = (nRows * maxHeight);
  if (titleHeight_ > 0)
    lh += titleHeight_ + ops->yPad;

  lw = nColumns * maxWidth;
  if (lw < (int)(titleWidth_))
    lw = titleWidth_;

  width_ = lw + 2 * ops->borderWidth + 2*ops->xPad;
  height_ = lh + 2 * ops->borderWidth + 2*ops->yPad;
  nRows_ = nRows;
  nColumns_ = nColumns;
  nEntries_ = nEntries;
  entryHeight_ = maxHeight;
  entryWidth_ = maxWidth;

  int row =0;
  int col =0;
  int count =0;
  for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList); 
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    count++;
    elemPtr->row_ = row;
    elemPtr->col_ = col;
    row++;
    if ((count % nRows) == 0) {
      col++;
      row = 0;
    }
  }
}

void Legend::draw(Drawable drawable)
{
  LegendOptions* ops = (LegendOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  if ((ops->hide) || (nEntries_ == 0))
    return;

  setOrigin();
  Tk_Window tkwin = graphPtr_->tkwin_;
  int w = width_;
  int h = height_;

  Pixmap pixmap = Tk_GetPixmap(graphPtr_->display_, Tk_WindowId(tkwin), w, h, 
			       Tk_Depth(tkwin));

  if (ops->normalBg)
    Tk_Fill3DRectangle(tkwin, pixmap, ops->normalBg, 0, 0, 
		       w, h, 0, TK_RELIEF_FLAT);
  else {
    switch ((Position)ops->position) {
    case TOP:
    case BOTTOM:
    case RIGHT:
    case LEFT:
      Tk_Fill3DRectangle(tkwin, pixmap, gops->normalBg, 0, 0, 
			 w, h, 0, TK_RELIEF_FLAT);
      break;
    case PLOT:
    case XY:
      // Legend background is transparent and is positioned over the the
      // plot area.  Either copy the part of the background from the backing
      // store pixmap or (if no backing store exists) just fill it with the
      // background color of the plot.
      if (graphPtr_->cache_ != None)
	XCopyArea(graphPtr_->display_, graphPtr_->cache_, pixmap, 
		  graphPtr_->drawGC_, x_, y_, w, h, 0, 0);
      else 
	Tk_Fill3DRectangle(tkwin, pixmap, gops->plotBg, 0, 0, 
			   w, h, TK_RELIEF_FLAT, 0);
      break;
    };
  }

  Tk_FontMetrics fontMetrics;
  Tk_GetFontMetrics(ops->style.font, &fontMetrics);

  int symbolSize = fontMetrics.ascent;
  int xMid = symbolSize + 1 + ops->entryBW;
  int yMid = (symbolSize / 2) + 1 + ops->entryBW;
  int xLabel = 2 * symbolSize + ops->entryBW +  ops->ixPad + 2 * 2;
  int ySymbol = yMid + ops->iyPad; 
  int xSymbol = xMid + 2;

  int x = ops->xPad + ops->borderWidth;
  int y = ops->yPad + ops->borderWidth;
  
  TextStyle tts(graphPtr_, &ops->titleStyle);
  tts.drawText(pixmap, ops->title, x, y);
  if (titleHeight_ > 0)
    y += titleHeight_ + ops->yPad;

  int count = 0;
  int yStart = y;
  TextStyle ts(graphPtr_, &ops->style);

  for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList);
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();
    if (!elemOps->label)
      continue;

    int isSelected = entryIsSelected(elemPtr);
    if (elemPtr->labelActive_)
      Tk_Fill3DRectangle(tkwin, pixmap, ops->activeBg, 
			 x, y, entryWidth_, entryHeight_, 
			 ops->entryBW, ops->activeRelief);
    else if (isSelected) {
      XColor* fg = (flags & FOCUS) ?
	ops->selInFocusFgColor : ops->selOutFocusFgColor;
      Tk_3DBorder bg = (flags & FOCUS) ?
	ops->selInFocusBg : ops->selOutFocusBg;
      ops->style.color = fg;
      Tk_Fill3DRectangle(tkwin, pixmap, bg, x, y, 
			 entryWidth_, entryHeight_, 
			 ops->selBW, ops->selRelief);
    }
    else {
      ops->style.color = ops->fgColor;
      if (elemOps->legendRelief != TK_RELIEF_FLAT)
	Tk_Fill3DRectangle(tkwin, pixmap, gops->normalBg, 
			   x, y, entryWidth_, 
			   entryHeight_, ops->entryBW, 
			   elemOps->legendRelief);
    }
    elemPtr->drawSymbol(pixmap, x + xSymbol, y + ySymbol, symbolSize);

    ts.drawText(pixmap, elemOps->label, x+xLabel, y+ops->entryBW+ops->iyPad);
    count++;

    if (focusPtr_ == elemPtr) {
      if (isSelected) {
	XColor* color = (flags & FOCUS) ?
	  ops->selInFocusFgColor : ops->selOutFocusFgColor;
	XSetForeground(graphPtr_->display_, focusGC_, color->pixel);
      }
      XDrawRectangle(graphPtr_->display_, pixmap, focusGC_, 
		     x + 1, y + 1, entryWidth_ - 3, 
		     entryHeight_ - 3);
      if (isSelected)
	XSetForeground(graphPtr_->display_, focusGC_, ops->focusColor->pixel);
    }

    // Check when to move to the next column
    if ((count % nRows_) > 0)
      y += entryHeight_;
    else {
      x += entryWidth_;
      y = yStart;
    }
  }

  Tk_3DBorder bg = ops->normalBg;
  if (!bg)
    bg = gops->normalBg;

  Tk_Draw3DRectangle(tkwin, pixmap, bg, 0, 0, w, h, 
		     ops->borderWidth, ops->relief);
  XCopyArea(graphPtr_->display_, pixmap, drawable, graphPtr_->drawGC_, 
	    0, 0, w, h, x_, y_);

  Tk_FreePixmap(graphPtr_->display_, pixmap);
}

void Legend::print(PSOutput* psPtr)
{
  LegendOptions* ops = (LegendOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;
  PostscriptOptions* pops = (PostscriptOptions*)graphPtr_->postscript_->ops_;

  if ((ops->hide) || (nEntries_ == 0))
    return;

  setOrigin();

  double x = x_;
  double y = y_;
  int width = width_ - 2*ops->xPad;
  int height = height_ - 2*ops->yPad;

  psPtr->append("% Legend\n");
  if (pops->decorations) {
    if (ops->normalBg)
      psPtr->fill3DRectangle(ops->normalBg, x, y, width, height, 
			     ops->borderWidth, ops->relief);
    else
      psPtr->print3DRectangle(gops->normalBg, x, y, width, height, 
			     ops->borderWidth, ops->relief);

  }
  else {
    psPtr->setClearBackground();
    psPtr->fillRectangle(x, y, width, height);
  }

  Tk_FontMetrics fontMetrics;
  Tk_GetFontMetrics(ops->style.font, &fontMetrics);
  int symbolSize = fontMetrics.ascent;
  int xMid = symbolSize + 1 + ops->entryBW;
  int yMid = (symbolSize / 2) + 1 + ops->entryBW;
  int xLabel = 2 * symbolSize + ops->entryBW + ops->ixPad + 5;
  int xSymbol = xMid + ops->ixPad;
  int ySymbol = yMid + ops->iyPad;

  x += ops->borderWidth;
  y += ops->borderWidth;
  TextStyle tts(graphPtr_, &ops->titleStyle);
  tts.printText(psPtr, ops->title, x, y);
  if (titleHeight_ > 0)
    y += titleHeight_ + ops->yPad;

  int count = 0;
  double yStart = y;
  TextStyle ts(graphPtr_, &ops->style);

  for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList); 
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    if (elemPtr->labelActive_) {
      ops->style.color = ops->activeFgColor;
      psPtr->fill3DRectangle(ops->activeBg, x, y, entryWidth_, 
			     entryHeight_, ops->entryBW, 
			     ops->activeRelief);
    }
    else {
      ops->style.color = ops->fgColor;
      if (elemOps->legendRelief != TK_RELIEF_FLAT)
	psPtr->print3DRectangle(gops->normalBg, x, y, entryWidth_, entryHeight_,
			       ops->entryBW, elemOps->legendRelief);
    }
    elemPtr->printSymbol(psPtr, x + xSymbol, y + ySymbol, symbolSize);
    ts.printText(psPtr, elemOps->label, x + xLabel, 
		 y + ops->entryBW + ops->iyPad);
    count++;

    if ((count % nRows_) > 0)
      y += entryHeight_;
    else {
      x += entryWidth_;
      y = yStart;
    }
  }
}

void Legend::removeElement(Element* elemPtr)
{
  bindTable_->deleteBindings(elemPtr);
}

void Legend::eventuallyInvokeSelectCmd()
{
  if ((flags & SELECT_PENDING) == 0) {
    flags |= SELECT_PENDING;
    Tcl_DoWhenIdle(SelectCmdProc, this);
  }
}

void Legend::setOrigin()
{
  LegendOptions* ops = (LegendOptions*)ops_;
  GraphOptions* gops = (GraphOptions*)graphPtr_->ops_;

  int x =0;
  int y =0;
  int w =0;
  int h =0;
  switch ((Position)ops->position) {
  case RIGHT:
    w = gops->rightMargin.width - gops->rightMargin.axesOffset;
    h = graphPtr_->bottom_ - graphPtr_->top_;
    x = graphPtr_->right_ + gops->rightMargin.axesOffset;
    y = graphPtr_->top_;
    break;

  case LEFT:
    w = gops->leftMargin.width - gops->leftMargin.axesOffset;
    h = graphPtr_->bottom_ - graphPtr_->top_;
    x = graphPtr_->inset_;
    y = graphPtr_->top_;
    break;

  case TOP:
    w = graphPtr_->right_ - graphPtr_->left_;
    h = gops->topMargin.height - gops->topMargin.axesOffset;
    if (gops->title)
      h -= graphPtr_->titleHeight_;

    x = graphPtr_->left_;
    y = graphPtr_->inset_;
    if (gops->title)
      y += graphPtr_->titleHeight_;
    break;

  case BOTTOM:
    w = graphPtr_->right_ - graphPtr_->left_;
    h = gops->bottomMargin.height - gops->bottomMargin.axesOffset;
    x = graphPtr_->left_;
    y = graphPtr_->bottom_ + gops->bottomMargin.axesOffset;
    break;

  case PLOT:
    w = graphPtr_->right_ - graphPtr_->left_;
    h = graphPtr_->bottom_ - graphPtr_->top_;
    x = graphPtr_->left_;
    y = graphPtr_->top_;
    break;

  case XY:
    w = width_;
    h = height_;
    x = ops->xReq;
    y = ops->yReq;
    if (x < 0)
      x += graphPtr_->width_;

    if (y < 0)
      y += graphPtr_->height_;
    break;
  }

  switch (ops->anchor) {
  case TK_ANCHOR_NW:
    break;
  case TK_ANCHOR_W:
    if (h > height_)
      y += (h - height_) / 2;
    break;
  case TK_ANCHOR_SW:
    if (h > height_)
      y += (h - height_);
    break;
  case TK_ANCHOR_N:
    if (w > width_)
      x += (w - width_) / 2;
    break;
  case TK_ANCHOR_CENTER:
    if (h > height_)
      y += (h - height_) / 2;

    if (w > width_)
      x += (w - width_) / 2;
    break;
  case TK_ANCHOR_S:
    if (w > width_)
      x += (w - width_) / 2;

    if (h > height_)
      y += (h - height_);
    break;
  case TK_ANCHOR_NE:
    if (w > width_)
      x += w - width_;
    break;
  case TK_ANCHOR_E:
    if (w > width_)
      x += w - width_;

    if (h > height_)
      y += (h - height_) / 2;
    break;
  case TK_ANCHOR_SE:
    if (w > width_) {
      x += w - width_;
    }
    if (h > height_) {
      y += (h - height_);
    }
    break;
  }

  x_ = x + ops->xPad;
  y_ = y + ops->yPad;
}

void Legend::selectEntry(Element* elemPtr)
{
  switch (flags & SELECT_TOGGLE) {
  case SELECT_CLEAR:
    deselectElement(elemPtr);
    break;
  case SELECT_SET:
    selectElement(elemPtr);
    break;
  case SELECT_TOGGLE:
    Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&selectTable_, (char*)elemPtr);
    if (hPtr)
      deselectElement(elemPtr);
    else
      selectElement(elemPtr);
    break;
  }
}

void Legend::selectElement(Element* elemPtr)
{
  int isNew;
  Tcl_HashEntry* hPtr = 
    Tcl_CreateHashEntry(&selectTable_, (char*)elemPtr, &isNew);
  if (isNew) {
    ChainLink* link = selected_->append(elemPtr);
    Tcl_SetHashValue(hPtr, link);
  }
}

void Legend::deselectElement(Element* elemPtr)
{
  Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&selectTable_, (char*)elemPtr);
  if (hPtr) {
    ChainLink* link = (ChainLink*)Tcl_GetHashValue(hPtr);
    selected_->deleteLink(link);
    Tcl_DeleteHashEntry(hPtr);
  }
}


int Legend::selectRange(Element *fromPtr, Element *toPtr)
{
  int isBefore=0;
  for (ChainLink* linkPtr = fromPtr->link; linkPtr; linkPtr = linkPtr->next())
    if (linkPtr == toPtr->link)
      isBefore =1;

  if (isBefore) {
    for (ChainLink* link = fromPtr->link; link; link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      selectEntry(elemPtr);
      if (link == toPtr->link)
	break;
    }
  } 
  else {
    for (ChainLink* link = fromPtr->link; link; link = Chain_PrevLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      selectEntry(elemPtr);
      if (link == toPtr->link)
	break;
    }
  }

  return TCL_OK;
}

void Legend::clearSelection()
{
  LegendOptions* ops = (LegendOptions*)ops_;

  Tcl_DeleteHashTable(&selectTable_);
  Tcl_InitHashTable(&selectTable_, TCL_ONE_WORD_KEYS);
  selected_->reset();

  if (ops->selectCmd)
    eventuallyInvokeSelectCmd();
}

int Legend::entryIsSelected(Element* elemPtr)
{
  Tcl_HashEntry* hPtr = Tcl_FindHashEntry(&selectTable_, (char*)elemPtr);
  return (hPtr != NULL);
}

int Legend::getElementFromObj(Tcl_Obj* objPtr, Element** elemPtrPtr)
{
  const char *string = Tcl_GetString(objPtr);
  Element* elemPtr = NULL;

  if (!strcmp(string, "anchor"))
    elemPtr = selAnchorPtr_;
  else if (!strcmp(string, "current"))
    elemPtr = (Element*)bindTable_->currentItem();
  else if (!strcmp(string, "first"))
    elemPtr = getFirstElement();
  else if (!strcmp(string, "focus"))
    elemPtr = focusPtr_;
  else if (!strcmp(string, "last"))
    elemPtr = getLastElement();
  else if (!strcmp(string, "end"))
    elemPtr = getLastElement();
  else if (!strcmp(string, "next.row"))
    elemPtr = getNextRow(focusPtr_);
  else if (!strcmp(string, "next.column"))
    elemPtr = getNextColumn(focusPtr_);
  else if (!strcmp(string, "previous.row"))
    elemPtr = getPreviousRow(focusPtr_);
  else if (!strcmp(string, "previous.column"))
    elemPtr = getPreviousColumn(focusPtr_);
  else if (string[0] == '@') {
    int x, y;
    if (graphPtr_->getXY(string, &x, &y) != TCL_OK)
      return TCL_ERROR;

    ClassId classId;
    elemPtr = (Element*)pickEntry(x, y, &classId);
  }
  else {
    if (graphPtr_->getElement(objPtr, &elemPtr) != TCL_OK)
      return TCL_ERROR;

    if (!elemPtr->link) {
      Tcl_AppendResult(graphPtr_->interp_, "bad legend index \"", string, "\"",
		       (char *)NULL);
      return TCL_ERROR;
    }
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();
    if (!elemOps->label)
      elemPtr = NULL;
  }

  *elemPtrPtr = elemPtr;
  return TCL_OK;
}

Element* Legend::getNextRow(Element* focusPtr)
{
  unsigned col = focusPtr->col_;
  unsigned row = focusPtr->row_ + 1;
  for (ChainLink* link = focusPtr->link; link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    if ((elemPtr->col_ == col) && (elemPtr->row_ == row))
      return elemPtr;	
  }
  return NULL;
}

Element* Legend::getNextColumn(Element* focusPtr)
{
  unsigned col = focusPtr->col_ + 1;
  unsigned row = focusPtr->row_;
  for (ChainLink* link = focusPtr->link; link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    if ((elemPtr->col_ == col) && (elemPtr->row_ == row))
      return elemPtr;
  }
  return NULL;
}

Element* Legend::getPreviousRow(Element* focusPtr)
{
  unsigned col = focusPtr->col_;
  unsigned row = focusPtr->row_ - 1;
  for (ChainLink* link = focusPtr->link; link; link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    if ((elemPtr->col_ == col) && (elemPtr->row_ == row))
      return elemPtr;	
  }
  return NULL;
}

Element* Legend::getPreviousColumn(Element* focusPtr)
{
  unsigned col = focusPtr->col_ - 1;
  unsigned row = focusPtr->row_;
  for (ChainLink* link = focusPtr->link; link; link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();

    if (!elemOps->label)
      continue;

    if ((elemPtr->col_ == col) && (elemPtr->row_ == row))
      return elemPtr;	
  }
  return NULL;
}

Element* Legend::getFirstElement()
{
  for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList);
       link; link = Chain_NextLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();
    if (elemOps->label)
      return elemPtr;
  }
  return NULL;
}

Element* Legend::getLastElement()
{
  for (ChainLink* link = Chain_LastLink(graphPtr_->elements_.displayList); 
       link; link = Chain_PrevLink(link)) {
    Element* elemPtr = (Element*)Chain_GetValue(link);
    ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();
    if (elemOps->label)
      return elemPtr;
  }
  return NULL;
}

ClientData Legend::pickEntry(int xx, int yy, ClassId* classIdPtr)
{
  LegendOptions* ops = (LegendOptions*)ops_;

  int ww = width_;
  int hh = height_;

  if (titleHeight_ > 0)
    yy -= titleHeight_ + ops->yPad;

  xx -= x_ + ops->borderWidth;
  yy -= y_ + ops->borderWidth;
  ww -= 2 * ops->borderWidth + 2*ops->xPad;
  hh -= 2 * ops->borderWidth + 2*ops->yPad;

  // In the bounding box? if so, compute the index
  if (xx >= 0 && xx < ww && yy >= 0 && yy < hh) {
    int row    = yy / entryHeight_;
    int column = xx / entryWidth_;
    int nn = (column * nRows_) + row;

    // Legend entries are stored in bottom-to-top
    if (nn < nEntries_) {
      int count = 0;
      for (ChainLink* link = Chain_FirstLink(graphPtr_->elements_.displayList);
	   link; link = Chain_NextLink(link)) {
	Element* elemPtr = (Element*)Chain_GetValue(link);
	ElementOptions* elemOps = (ElementOptions*)elemPtr->ops();
	if (elemOps->label) {
	  if (count == nn) {
	    *classIdPtr = elemPtr->classId();
	    return elemPtr;
	  }
	  count++;
	}
      }	      
    }
  }

  return NULL;
}

// Support

static int SelectionProc(ClientData clientData, int offset, char *buffer,
			 int maxBytes)
{
  Legend* legendPtr = (Legend*)clientData;
  Graph* graphPtr = legendPtr->graphPtr_;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();

  if ((ops->exportSelection) == 0)
    return -1;

  // Retrieve the names of the selected entries
  Tcl_DString dString;
  Tcl_DStringInit(&dString);
  if (legendPtr->flags & SELECT_SORTED) {
    for (ChainLink* link=Chain_FirstLink(legendPtr->selected_); 
	 link; link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      Tcl_DStringAppend(&dString, elemPtr->name_, -1);
      Tcl_DStringAppend(&dString, "\n", -1);
    }
  }
  else {
    for (ChainLink* link=Chain_FirstLink(graphPtr->elements_.displayList);
	 link; link = Chain_NextLink(link)) {
      Element* elemPtr = (Element*)Chain_GetValue(link);
      if (legendPtr->entryIsSelected(elemPtr)) {
	Tcl_DStringAppend(&dString, elemPtr->name_, -1);
	Tcl_DStringAppend(&dString, "\n", -1);
      }
    }
  }

  int nBytes = Tcl_DStringLength(&dString) - offset;
  strncpy(buffer, Tcl_DStringValue(&dString) + offset, maxBytes);
  Tcl_DStringFree(&dString);
  buffer[maxBytes] = '\0';
  return MIN(nBytes, maxBytes);
}

static void SelectCmdProc(ClientData clientData) 
{
  Legend* legendPtr = (Legend*)clientData;
  LegendOptions* ops = (LegendOptions*)legendPtr->ops();

  Tcl_Preserve(legendPtr);
  legendPtr->flags &= ~SELECT_PENDING;
  if (ops->selectCmd) {
    Tcl_Interp* interp = legendPtr->graphPtr_->interp_;
    if (Tcl_GlobalEval(interp, ops->selectCmd) != TCL_OK)
      Tcl_BackgroundError(interp);
  }
  Tcl_Release(legendPtr);
}



