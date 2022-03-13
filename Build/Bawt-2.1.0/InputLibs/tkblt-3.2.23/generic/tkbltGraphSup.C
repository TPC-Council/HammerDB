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

#include <cmath>

#include "tkbltGraph.h"
#include "tkbltGrAxis.h"
#include "tkbltGrElem.h"
#include "tkbltGrLegd.h"
#include "tkbltGrMisc.h"

using namespace Blt;

#define AXIS_PAD_TITLE 2
#define ROTATE_0	0
#define ROTATE_90	1
#define ROTATE_180	2
#define ROTATE_270	3

/*
 *---------------------------------------------------------------------------
 *
 * layoutGraph --
 *
 *	Calculate the layout of the graph.  Based upon the data, axis limits,
 *	X and Y titles, and title height, determine the cavity left which is
 *	the plotting surface.  The first step get the data and axis limits for
 *	calculating the space needed for the top, bottom, left, and right
 *	margins.
 *
 * 	1) The LEFT margin is the area from the left border to the Y axis 
 *	   (not including ticks). It composes the border width, the width an 
 *	   optional Y axis label and its padding, and the tick numeric labels. 
 *	   The Y axis label is rotated 90 degrees so that the width is the 
 *	   font height.
 *
 * 	2) The RIGHT margin is the area from the end of the graph
 *	   to the right window border. It composes the border width,
 *	   some padding, the font height (this may be dubious. It
 *	   appears to provide a more even border), the max of the
 *	   legend width and 1/2 max X tick number. This last part is
 *	   so that the last tick label is not clipped.
 *
 *           Window Width
 *      ___________________________________________________________
 *      |          |                               |               |
 *      |          |   TOP  height of title        |               |
 *      |          |                               |               |
 *      |          |           x2 title            |               |
 *      |          |                               |               |
 *      |          |        height of x2-axis      |               |
 *      |__________|_______________________________|_______________|  W
 *      |          | -plotpady                     |               |  i
 *      |__________|_______________________________|_______________|  n
 *      |          | top                   right   |               |  d
 *      |          |                               |               |  o
 *      |   LEFT   |                               |     RIGHT     |  w
 *      |          |                               |               |
 *      | y        |     Free area = 104%          |      y2       |  H
 *      |          |     Plotting surface = 100%   |               |  e
 *      | t        |     Tick length = 2 + 2%      |      t        |  i
 *      | i        |                               |      i        |  g
 *      | t        |                               |      t  legend|  h
 *      | l        |                               |      l   width|  t
 *      | e        |                               |      e        |
 *      |    height|                               |height         |
 *      |       of |                               | of            |
 *      |    y-axis|                               |y2-axis        |
 *      |          |                               |               |
 *      |          |origin 0,0                     |               |
 *      |__________|_left_________________bottom___|_______________|
 *      |          |-plotpady                      |               |
 *      |__________|_______________________________|_______________|
 *      |          | (xoffset, yoffset)            |               |
 *      |          |                               |               |
 *      |          |       height of x-axis        |               |
 *      |          |                               |               |
 *      |          |   BOTTOM   x title            |               |
 *      |__________|_______________________________|_______________|
 *
 * 3) The TOP margin is the area from the top window border to the top
 *    of the graph. It composes the border width, twice the height of
 *    the title font (if one is given) and some padding between the
 *    title.
 *
 * 4) The BOTTOM margin is area from the bottom window border to the
 *    X axis (not including ticks). It composes the border width, the height
 *    an optional X axis label and its padding, the height of the font
 *    of the tick labels.
 *
 * The plotting area is between the margins which includes the X and Y axes
 * including the ticks but not the tick numeric labels. The length of the
 * ticks and its padding is 5% of the entire plotting area.  Hence the entire
 * plotting area is scaled as 105% of the width and height of the area.
 *
 * The axis labels, ticks labels, title, and legend may or may not be
 * displayed which must be taken into account.
 *
 * if reqWidth > 0 : set outer size
 * if reqPlotWidth > 0 : set plot size
 *---------------------------------------------------------------------------
 */

void Graph::layoutGraph()
{
  GraphOptions* ops = (GraphOptions*)ops_;

  int width = width_;
  int height = height_;

  // Step 1
  // Compute the amount of space needed to display the axes
  // associated with each margin.  They can be overridden by 
  // -leftmargin, -rightmargin, -bottommargin, and -topmargin 
  // graph options, respectively.
  int left   = getMarginGeometry(&ops->leftMargin);
  int right  = getMarginGeometry(&ops->rightMargin);
  int top    = getMarginGeometry(&ops->topMargin);
  int bottom = getMarginGeometry(&ops->bottomMargin);

  int pad = ops->bottomMargin.maxTickWidth;
  if (pad < ops->topMargin.maxTickWidth)
    pad = ops->topMargin.maxTickWidth;

  pad = pad / 2 + 3;
  if (right < pad)
    right = pad;

  if (left < pad)
    left = pad;

  pad = ops->leftMargin.maxTickHeight;
  if (pad < ops->rightMargin.maxTickHeight)
    pad = ops->rightMargin.maxTickHeight;

  pad = pad / 2;
  if (top < pad)
    top = pad;

  if (bottom < pad)
    bottom = pad;

  if (ops->leftMargin.reqSize > 0)
    left = ops->leftMargin.reqSize;

  if (ops->rightMargin.reqSize > 0)
    right = ops->rightMargin.reqSize;

  if (ops->topMargin.reqSize > 0)
    top = ops->topMargin.reqSize;

  if (ops->bottomMargin.reqSize > 0)
    bottom = ops->bottomMargin.reqSize;

  // Step 2
  // Add the graph title height to the top margin. 
  if (ops->title)
    top += titleHeight_ + 6;

  int inset = (inset_ + ops->plotBW);
  int inset2 = 2 * inset;

  // Step 3
  // Estimate the size of the plot area from the remaining
  // space.  This may be overridden by the -plotwidth and
  // -plotheight graph options.  We use this to compute the
  // size of the legend. 
  if (width == 0)
    width = 400;

  if (height == 0)
    height = 400;

  int plotWidth  = (ops->reqPlotWidth > 0) ? ops->reqPlotWidth :
    width - (inset2 + left + right);
  int plotHeight = (ops->reqPlotHeight > 0) ? ops->reqPlotHeight : 
    height - (inset2 + top + bottom);
  legend_->map(plotWidth, plotHeight);

  // Step 4
  // Add the legend to the appropiate margin. 
  if (!legend_->isHidden()) {
    switch (legend_->position()) {
    case Legend::RIGHT:
      if (!ops->rightMargin.reqSize)
	right += legend_->width_ + 2;
      break;
    case Legend::LEFT:
      if (!ops->leftMargin.reqSize)
	left += legend_->width_ + 2;
      break;
    case Legend::TOP:
      if (!ops->topMargin.reqSize)
	top += legend_->height_ + 2;
      break;
    case Legend::BOTTOM:
      if (!ops->bottomMargin.reqSize)
	bottom += legend_->height_ + 2;
      break;
    case Legend::XY:
    case Legend::PLOT:
      break;
    }
  }

  // Recompute the plotarea or graph size, now accounting for the legend. 
  if (ops->reqPlotWidth == 0) {
    plotWidth = width  - (inset2 + left + right);
    if (plotWidth < 1)
      plotWidth = 1;
  }
  if (ops->reqPlotHeight == 0) {
    plotHeight = height - (inset2 + top + bottom);
    if (plotHeight < 1)
      plotHeight = 1;
  }

  // Step 5
  // If necessary, correct for the requested plot area aspect ratio.
  if ((ops->reqPlotWidth == 0) && (ops->reqPlotHeight == 0) && 
      (ops->aspect > 0.0)) {
    double ratio;

    // Shrink one dimension of the plotarea to fit the requested
    // width/height aspect ratio.
    ratio = plotWidth / plotHeight;
    if (ratio > ops->aspect) {
      // Shrink the width
      int scaledWidth = (int)(plotHeight * ops->aspect);
      if (scaledWidth < 1)
	scaledWidth = 1;

      // Add the difference to the right margin.
      // CHECK THIS: w = scaledWidth
      right += (plotWidth - scaledWidth);
    }
    else {
      // Shrink the height
      int scaledHeight = (int)(plotWidth / ops->aspect);
      if (scaledHeight < 1)
	scaledHeight = 1;

      // Add the difference to the top margin
      // CHECK THIS: h = scaledHeight;
      top += (plotHeight - scaledHeight); 
    }
  }

  // Step 6
  // If there's multiple axes in a margin, the axis titles will be
  // displayed in the adjoining margins.  Make sure there's room 
  // for the longest axis titles.
  if (top < ops->leftMargin.axesTitleLength)
    top = ops->leftMargin.axesTitleLength;

  if (right < ops->bottomMargin.axesTitleLength)
    right = ops->bottomMargin.axesTitleLength;

  if (top < ops->rightMargin.axesTitleLength)
    top = ops->rightMargin.axesTitleLength;

  if (right < ops->topMargin.axesTitleLength)
    right = ops->topMargin.axesTitleLength;

  // Step 7
  // Override calculated values with requested margin sizes.
  if (ops->leftMargin.reqSize > 0)
    left = ops->leftMargin.reqSize;

  if (ops->rightMargin.reqSize > 0)
    right = ops->rightMargin.reqSize;

  if (ops->topMargin.reqSize > 0)
    top = ops->topMargin.reqSize;

  if (ops->bottomMargin.reqSize > 0)
    bottom = ops->bottomMargin.reqSize;

  if (ops->reqPlotWidth > 0) {	
    // Width of plotarea is constained.  If there's extra space, add it to
    // the left and/or right margins.  If there's too little, grow the
    // graph width to accomodate it.
    int w = plotWidth + inset2 + left + right;

    // Extra space in window
    if (width > w) {
      int extra = (width - w) / 2;
      if (ops->leftMargin.reqSize == 0) { 
	left += extra;
	if (ops->rightMargin.reqSize == 0)
	  right += extra;
	else
	  left += extra;
      }
      else if (ops->rightMargin.reqSize == 0)
	right += extra + extra;
    }
    else if (width < w)
      width = w;
  } 

  // Constrain the plotarea height
  if (ops->reqPlotHeight > 0) {

    // Height of plotarea is constained.  If there's extra space, 
    // add it to th top and/or bottom margins.  If there's too little,
    // grow the graph height to accomodate it.
    int h = plotHeight + inset2 + top + bottom;

    // Extra space in window
    if (height > h) {
      int extra = (height - h) / 2;
      if (ops->topMargin.reqSize == 0) { 
	top += extra;
	if (ops->bottomMargin.reqSize == 0)
	  bottom += extra;
	else
	  top += extra;
      }
      else if (ops->bottomMargin.reqSize == 0)
	bottom += extra + extra;
    }
    else if (height < h)
      height = h;
  }	

  width_  = width;
  height_ = height;
  left_   = left + inset;
  top_    = top + inset;
  right_  = width - right - inset;
  bottom_ = height - bottom - inset;

  ops->leftMargin.width    = left   + inset_;
  ops->rightMargin.width   = right  + inset_;
  ops->topMargin.height    = top    + inset_;
  ops->bottomMargin.height = bottom + inset_;
	    
  vOffset_ = top_ + ops->yPad;
  vRange_  = plotHeight - 2*ops->yPad;
  hOffset_ = left_ + ops->xPad;
  hRange_  = plotWidth  - 2*ops->xPad;

  if (vRange_ < 1)
    vRange_ = 1;

  if (hRange_ < 1)
    hRange_ = 1;

  hScale_ = 1.0 / hRange_;
  vScale_ = 1.0 / vRange_;

  // Calculate the placement of the graph title so it is centered within the
  // space provided for it in the top margin
  titleY_ = 3 + inset_;
  titleX_ = (right_ + left_) / 2;
}

int Graph::getMarginGeometry(Margin *marginPtr)
{
  GraphOptions* ops = (GraphOptions*)ops_;
  int isHoriz = !(marginPtr->site & 0x1); /* Even sites are horizontal */

  // Count the visible axes.
  unsigned int nVisible = 0;
  unsigned int l =0;
  int w =0;
  int h =0;

  marginPtr->maxTickWidth =0;
  marginPtr->maxTickHeight =0;

  if (ops->stackAxes) {
    for (ChainLink* link = Chain_FirstLink(marginPtr->axes); link;
	 link = Chain_NextLink(link)) {
      Axis* axisPtr = (Axis*)Chain_GetValue(link);
      AxisOptions* ops = (AxisOptions*)axisPtr->ops();
      if (!ops->hide && axisPtr->use_) {
	nVisible++;
	axisPtr->getGeometry();

	if (isHoriz) {
	  if (h < axisPtr->height_)
	    h = axisPtr->height_;
	}
	else {
	  if (w < axisPtr->width_)
	    w = axisPtr->width_;
	}
	if (axisPtr->maxTickWidth_ > marginPtr->maxTickWidth)
	  marginPtr->maxTickWidth = axisPtr->maxTickWidth_;

	if (axisPtr->maxTickHeight_ > marginPtr->maxTickHeight)
	  marginPtr->maxTickHeight = axisPtr->maxTickHeight_;
      }
    }
  }
  else {
    for (ChainLink* link = Chain_FirstLink(marginPtr->axes); link;
	 link = Chain_NextLink(link)) {
      Axis* axisPtr = (Axis*)Chain_GetValue(link);
      AxisOptions* ops = (AxisOptions*)axisPtr->ops();
      if (!ops->hide && axisPtr->use_) {
	nVisible++;
	axisPtr->getGeometry();

	if ((ops->titleAlternate) && (l < axisPtr->titleWidth_))
	  l = axisPtr->titleWidth_;

	if (isHoriz)
	  h += axisPtr->height_;
	else
	  w += axisPtr->width_;

	if (axisPtr->maxTickWidth_ > marginPtr->maxTickWidth)
	  marginPtr->maxTickWidth = axisPtr->maxTickWidth_;

	if (axisPtr->maxTickHeight_ > marginPtr->maxTickHeight)
	  marginPtr->maxTickHeight = axisPtr->maxTickHeight_;
      }
    }
  }
  // Enforce a minimum size for margins.
  if (w < 3)
    w = 3;

  if (h < 3)
    h = 3;

  marginPtr->nAxes = nVisible;
  marginPtr->axesTitleLength = l;
  marginPtr->width = w;
  marginPtr->height = h;
  marginPtr->axesOffset = (isHoriz) ? h : w;
  return marginPtr->axesOffset;
}

void Graph::getTextExtents(Tk_Font font, const char *text, int textLen,
			   int* ww, int* hh)
{
  if (!text) {
    *ww =0;
    *hh =0;
    return;
  }

  Tk_FontMetrics fm;
  Tk_GetFontMetrics(font, &fm);
  int lineHeight = fm.linespace;

  if (textLen < 0)
    textLen = strlen(text);

  int maxWidth =0;
  int maxHeight =0;
  int lineLen =0;
  const char *line =NULL;
  const char *p, *pend;
  for (p =line=text, pend=text+textLen; p<pend; p++) {
    if (*p == '\n') {
      if (lineLen > 0) {
	int lineWidth = Tk_TextWidth(font, line, lineLen);
	if (lineWidth > maxWidth)
	  maxWidth = lineWidth;
      }
      maxHeight += lineHeight;
      line = p + 1;	/* Point to the start of the next line. */
      lineLen = 0;	/* Reset counter to indicate the start of a
			 * new line. */
      continue;
    }
    lineLen++;
  }

  if ((lineLen > 0) && (*(p - 1) != '\n')) {
    maxHeight += lineHeight;
    int lineWidth = Tk_TextWidth(font, line, lineLen);
    if (lineWidth > maxWidth)
      maxWidth = lineWidth;
  }

  *ww = maxWidth;
  *hh = maxHeight;
}

/*
 *---------------------------------------------------------------------------
 *
 *	Computes the dimensions of the bounding box surrounding a rectangle
 *	rotated about its center.  If pointArr isn't NULL, the coordinates of
 *	the rotated rectangle are also returned.
 *
 *	The dimensions are determined by rotating the rectangle, and doubling
 *	the maximum x-coordinate and y-coordinate.
 *
 *		w = 2 * maxX,  h = 2 * maxY
 *
 *	Since the rectangle is centered at 0,0, the coordinates of the
 *	bounding box are (-w/2,-h/2 w/2,-h/2, w/2,h/2 -w/2,h/2).
 *
 *  		0 ------- 1
 *  		|         |
 *  		|    x    |
 *  		|         |
 *  		3 ------- 2
 *
 * Results:
 *	The width and height of the bounding box containing the rotated
 *	rectangle are returned.
 *
 *---------------------------------------------------------------------------
 */
void Graph::getBoundingBox(int width, int height, double angle,
			   double *rotWidthPtr, double *rotHeightPtr,
			   Point2d *bbox)
{
  angle = fmod(angle, 360.0);
  if (fmod(angle, 90.0) == 0.0) {
    int ll, ur, ul, lr;
    double rotWidth, rotHeight;

    // Handle right-angle rotations specially
    int quadrant = (int)(angle / 90.0);
    switch (quadrant) {
    case ROTATE_270:
      ul = 3, ur = 0, lr = 1, ll = 2;
      rotWidth = (double)height;
      rotHeight = (double)width;
      break;
    case ROTATE_90:
      ul = 1, ur = 2, lr = 3, ll = 0;
      rotWidth = (double)height;
      rotHeight = (double)width;
      break;
    case ROTATE_180:
      ul = 2, ur = 3, lr = 0, ll = 1;
      rotWidth = (double)width;
      rotHeight = (double)height;
      break;
    default:
    case ROTATE_0:
      ul = 0, ur = 1, lr = 2, ll = 3;
      rotWidth = (double)width;
      rotHeight = (double)height;
      break;
    }
    if (bbox) {
      double x = rotWidth * 0.5;
      double y = rotHeight * 0.5;
      bbox[ll].x = bbox[ul].x = -x;
      bbox[ur].y = bbox[ul].y = -y;
      bbox[lr].x = bbox[ur].x = x;
      bbox[ll].y = bbox[lr].y = y;
    }
    *rotWidthPtr = rotWidth;
    *rotHeightPtr = rotHeight;
    return;
  }

  // Set the four corners of the rectangle whose center is the origin
  Point2d corner[4];
  corner[1].x = corner[2].x = (double)width * 0.5;
  corner[0].x = corner[3].x = -corner[1].x;
  corner[2].y = corner[3].y = (double)height * 0.5;
  corner[0].y = corner[1].y = -corner[2].y;

  double radians = (-angle / 180.0) * M_PI;
  double sinTheta = sin(radians);
  double cosTheta = cos(radians);
  double xMax =0;
  double yMax =0;

  // Rotate the four corners and find the maximum X and Y coordinates
  for (int ii=0; ii<4; ii++) {
    double x = (corner[ii].x * cosTheta) - (corner[ii].y * sinTheta);
    double y = (corner[ii].x * sinTheta) + (corner[ii].y * cosTheta);
    if (x > xMax)
      xMax = x;

    if (y > yMax)
      yMax = y;

    if (bbox) {
      bbox[ii].x = x;
      bbox[ii].y = y;
    }
  }

  // By symmetry, the width and height of the bounding box are twice the
  // maximum x and y coordinates.
  *rotWidthPtr = xMax + xMax;
  *rotHeightPtr = yMax + yMax;
}

/*
 *---------------------------------------------------------------------------
 *
 * Blt_AnchorPoint --
 *
 * 	Translates a position, using both the dimensions of the bounding box,
 * 	and the anchor direction, returning the coordinates of the upper-left
 * 	corner of the box. The anchor indicates where the given x-y position
 * 	is in relation to the bounding box.
 *
 *  		7 nw --- 0 n --- 1 ne
 *  		 |                |
 *  		6 w    8 center  2 e
 *  		 |                |
 *  		5 sw --- 4 s --- 3 se
 *
 * 	The coordinates returned are translated to the origin of the bounding
 * 	box (suitable for giving to XCopyArea, XCopyPlane, etc.)
 *
 * Results:
 *	The translated coordinates of the bounding box are returned.
 *
 *---------------------------------------------------------------------------
 */
Point2d Graph::anchorPoint(double x, double y, double w, double h,	
			   Tk_Anchor anchor)
{
  Point2d t;

  switch (anchor) {
  case TK_ANCHOR_NW:		/* 7 Upper left corner */
    break;
  case TK_ANCHOR_W:		/* 6 Left center */
    y -= (h * 0.5);
    break;
  case TK_ANCHOR_SW:		/* 5 Lower left corner */
    y -= h;
    break;
  case TK_ANCHOR_N:		/* 0 Top center */
    x -= (w * 0.5);
    break;
  case TK_ANCHOR_CENTER:	/* 8 Center */
    x -= (w * 0.5);
    y -= (h * 0.5);
    break;
  case TK_ANCHOR_S:		/* 4 Bottom center */
    x -= (w * 0.5);
    y -= h;
    break;
  case TK_ANCHOR_NE:		/* 1 Upper right corner */
    x -= w;
    break;
  case TK_ANCHOR_E:		/* 2 Right center */
    x -= w;
    y -= (h * 0.5);
    break;
  case TK_ANCHOR_SE:		/* 3 Lower right corner */
    x -= w;
    y -= h;
    break;
  }

  t.x = x;
  t.y = y;
  return t;
}

