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
 *
 */

#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <cmath>

#include "tk.h"

// copied from tk3d.h

typedef struct TkBorder {
    Screen *screen;		/* Screen on which the border will be used. */
    Visual *visual;		/* Visual for all windows and pixmaps using
				 * the border. */
    int depth;			/* Number of bits per pixel of drawables where
				 * the border will be used. */
    Colormap colormap;		/* Colormap out of which pixels are
				 * allocated. */
    int resourceRefCount;	/* Number of active uses of this color (each
				 * active use corresponds to a call to
				 * Tk_Alloc3DBorderFromObj or Tk_Get3DBorder).
				 * If this count is 0, then this structure is
				 * no longer valid and it isn't present in
				 * borderTable: it is being kept around only
				 * because there are objects referring to it.
				 * The structure is freed when objRefCount and
				 * resourceRefCount are both 0. */
    int objRefCount;		/* The number of Tcl objects that reference
				 * this structure. */
    XColor *bgColorPtr;		/* Background color (intensity between
				 * lightColorPtr and darkColorPtr). */
    XColor *darkColorPtr;	/* Color for darker areas (must free when
				 * deleting structure). NULL means shadows
				 * haven't been allocated yet.*/
    XColor *lightColorPtr;	/* Color used for lighter areas of border
				 * (must free this when deleting structure).
				 * NULL means shadows haven't been allocated
				 * yet. */
    Pixmap shadow;		/* Stipple pattern to use for drawing shadows
				 * areas. Used for displays with <= 64 colors
				 * or where colormap has filled up. */
    GC bgGC;			/* Used (if necessary) to draw areas in the
				 * background color. */
    GC darkGC;			/* Used to draw darker parts of the border.
				 * None means the shadow colors haven't been
				 * allocated yet.*/
    GC lightGC;			/* Used to draw lighter parts of the border.
				 * None means the shadow colors haven't been
				 * allocated yet. */
    Tcl_HashEntry *hashPtr;	/* Entry in borderTable (needed in order to
				 * delete structure). */
    struct TkBorder *nextPtr;	/* Points to the next TkBorder structure with
				 * the same color name. Borders with the same
				 * name but different screens or colormaps are
				 * chained together off a single entry in
				 * borderTable. */
} TkBorder;

#include "tkbltGraph.h"
#include "tkbltGrPostscript.h"
#include "tkbltGrPSOutput.h"

using namespace Blt;

PSOutput::PSOutput(Graph* graphPtr)
{
  graphPtr_ = graphPtr;

  Tcl_DStringInit(&dString_);
}

PSOutput::~PSOutput()
{
  Tcl_DStringFree(&dString_);
}

void PSOutput::printPolyline(Point2d* screenPts, int nScreenPts)
{
  Point2d* pp = screenPts;
  append("newpath\n");
  format("  %g %g moveto\n", pp->x, pp->y);

  Point2d* pend;
  for (pp++, pend = screenPts + nScreenPts; pp < pend; pp++)
    format("  %g %g lineto\n", pp->x, pp->y);
}

void PSOutput::printMaxPolyline(Point2d* points, int nPoints)
{
  if (nPoints <= 0)
    return;

  for (int nLeft = nPoints; nLeft > 0; nLeft -= 1500) {
    int length = MIN(1500, nLeft);
    printPolyline(points, length);
    append("DashesProc stroke\n");
    points += length;
  }
}

void PSOutput::printSegments(Segment2d* segments, int nSegments)
{
  append("newpath\n");

  for (Segment2d *sp = segments, *send = sp + nSegments; sp < send; sp++) {
    format("  %g %g moveto %g %g lineto\n", sp->p.x, sp->p.y, sp->q.x, sp->q.y);
    append("DashesProc stroke\n");
  }
}

void PSOutput::computeBBox(int width, int height)
{
  Postscript* setupPtr = graphPtr_->postscript_;
  PostscriptOptions* pops = (PostscriptOptions*)setupPtr->ops_;

  // scale from points to pica
  double pica = 25.4 / 72 *
    WidthOfScreen(Tk_Screen(graphPtr_->tkwin_)) / 
    WidthMMOfScreen(Tk_Screen(graphPtr_->tkwin_));

  double hBorder = 2*pops->xPad/pica;
  double vBorder = 2*pops->yPad/pica;
  int hSize = !pops->landscape ? width : height; 
  int vSize = !pops->landscape ? height : width;

  // If the paper size wasn't specified, set it to the graph size plus the
  // paper border.
  double paperWidth = pops->reqPaperWidth > 0 ? pops->reqPaperWidth/pica :
    hSize + hBorder;
  double paperHeight = pops->reqPaperHeight > 0 ? pops->reqPaperHeight/pica :
    vSize + vBorder;

  // Scale the plot size if it's bigger than the paper
  double hScale = (hSize+hBorder)>paperWidth ? (paperWidth-hBorder)/hSize
    : 1.0;
  double vScale = (vSize+vBorder)>paperHeight ? (paperHeight-vBorder)/vSize
    : 1.0;

  double scale = MIN(hScale, vScale);
  if (scale != 1.0) {
    hSize = (int)(hSize*scale + 0.5);
    vSize = (int)(vSize*scale + 0.5);
  }

  int x = (int)((paperWidth > hSize) && pops->center ?
		(paperWidth - hSize) / 2 : pops->xPad/pica);
  int y = (int)((paperHeight > vSize) && pops->center ?
		(paperHeight - vSize) / 2 : pops->yPad/pica);

  setupPtr->left = x;
  setupPtr->bottom = y;
  setupPtr->right = x + hSize - 1;
  setupPtr->top = y + vSize - 1;
  setupPtr->scale = scale;
  setupPtr->paperHeight = (int)paperHeight;
  setupPtr->paperWidth = (int)paperWidth;
}

const char* PSOutput::getValue(int* lengthPtr)
{
  *lengthPtr = strlen(Tcl_DStringValue(&dString_));
  return Tcl_DStringValue(&dString_);
}

void PSOutput::append(const char* string)
{
  Tcl_DStringAppend(&dString_, string, -1);
}

void PSOutput::format(const char* fmt, ...)
{
  va_list argList;

  va_start(argList, fmt);
  vsnprintf(scratchArr_, POSTSCRIPT_BUFSIZ, fmt, argList);
  va_end(argList);
  Tcl_DStringAppend(&dString_, scratchArr_, -1);
}

void PSOutput::setLineWidth(int lineWidth)
{
  if (lineWidth < 1)
    lineWidth = 1;
  format("%d setlinewidth\n", lineWidth);
}

void PSOutput::printRectangle(double x, double y, int width, int height)
{
  append("newpath\n");
  format("  %g %g moveto\n", x, y);
  format("  %d %d rlineto\n", width, 0);
  format("  %d %d rlineto\n", 0, height);
  format("  %d %d rlineto\n", -width, 0);
  append("closepath\n");
  append("stroke\n");
}

void PSOutput::fillRectangle(double x, double y, int width, int height)
{
  append("newpath\n");
  format("  %g %g moveto\n", x, y);
  format("  %d %d rlineto\n", width, 0);
  format("  %d %d rlineto\n", 0, height);
  format("  %d %d rlineto\n", -width, 0);
  append("closepath\n");
  append("fill\n");
}

void PSOutput::fillRectangles(Rectangle* rectangles, int nRectangles)
{
  for (Rectangle *rp = rectangles, *rend = rp + nRectangles; rp < rend; rp++)
    fillRectangle((double)rp->x, (double)rp->y, (int)rp->width,(int)rp->height);
}

void PSOutput::setBackground(XColor* colorPtr)
{
  PostscriptOptions* pops = (PostscriptOptions*)graphPtr_->postscript_->ops_;
  printXColor(colorPtr);
  append(" setrgbcolor\n");
  if (pops->greyscale)
    append(" currentgray setgray\n");
}

void PSOutput::setForeground(XColor* colorPtr)
{
  PostscriptOptions* pops = (PostscriptOptions*)graphPtr_->postscript_->ops_;
  printXColor(colorPtr);
  append(" setrgbcolor\n");
  if (pops->greyscale)
    append(" currentgray setgray\n");
}

void PSOutput::setBackground(Tk_3DBorder border)
{
  TkBorder* borderPtr = (TkBorder*)border;
  setBackground(borderPtr->bgColorPtr);
}

void PSOutput::setFont(Tk_Font font) 
{
  Tcl_DString psdstr;
  Tcl_DStringInit(&psdstr);
  int psSize = Tk_PostscriptFontName(font, &psdstr);
  format("%d /%s SetFont\n", psSize, Tcl_DStringValue(&psdstr));
  Tcl_DStringFree(&psdstr);
}

void PSOutput::setLineAttributes(XColor* colorPtr,int lineWidth,
				   Dashes* dashesPtr, int capStyle, 
				   int joinStyle)
{
  setJoinStyle(joinStyle);
  setCapStyle(capStyle);
  setForeground(colorPtr);
  setLineWidth(lineWidth);
  setDashes(dashesPtr);
  append("/DashesProc {} def\n");
}

void PSOutput::fill3DRectangle(Tk_3DBorder border, double x, double y,
				 int width, int height, int borderWidth, 
				 int relief)
{
  TkBorder* borderPtr = (TkBorder*)border;

  setBackground(borderPtr->bgColorPtr);
  fillRectangle(x, y, width, height);
  print3DRectangle(border, x, y, width, height, borderWidth, relief);
}

void PSOutput::setClearBackground()
{
  append("1 1 1 setrgbcolor\n");
}

void PSOutput::setDashes(Dashes* dashesPtr)
{

  append("[ ");
  if (dashesPtr) {
    for (unsigned char* vp = dashesPtr->values; *vp != 0; vp++)
      format(" %d", *vp);
  }
  append("] 0 setdash\n");
}

void PSOutput::fillPolygon(Point2d *screenPts, int nScreenPts)
{
  printPolygon(screenPts, nScreenPts);
  append("fill\n");
}

void PSOutput::setJoinStyle(int joinStyle)
{
  // miter = 0, round = 1, bevel = 2
  format("%d setlinejoin\n", joinStyle);
}

void PSOutput::setCapStyle(int capStyle)
{
  // X11:not last = 0, butt = 1, round = 2, projecting = 3
  // PS: butt = 0, round = 1, projecting = 2
  if (capStyle > 0)
    capStyle--;

  format("%d setlinecap\n", capStyle);
}

void PSOutput::printPolygon(Point2d *screenPts, int nScreenPts)
{
  Point2d* pp = screenPts;
  append("newpath\n");
  format("  %g %g moveto\n", pp->x, pp->y);

  Point2d* pend;
  for (pp++, pend = screenPts + nScreenPts; pp < pend; pp++) 
    format("  %g %g lineto\n", pp->x, pp->y);

  format("  %g %g lineto\n", screenPts[0].x, screenPts[0].y);
  append("closepath\n");
}

void PSOutput::print3DRectangle(Tk_3DBorder border, double x, double y,
				 int width, int height, int borderWidth,
				 int relief)
{
  int twiceWidth = (borderWidth * 2);
  if ((width < twiceWidth) || (height < twiceWidth))
    return;

  TkBorder* borderPtr = (TkBorder*)border;

  // Handle grooves and ridges with recursive calls
  if ((relief == TK_RELIEF_GROOVE) || (relief == TK_RELIEF_RIDGE)) {
    int halfWidth = borderWidth / 2;
    int insideOffset = borderWidth - halfWidth;
    print3DRectangle(border, (double)x, (double)y, width, height, halfWidth, 
		    (relief == TK_RELIEF_GROOVE) ? 
		    TK_RELIEF_SUNKEN : TK_RELIEF_RAISED);
    print3DRectangle(border, (double)(x + insideOffset), 
		    (double)(y + insideOffset), width - insideOffset * 2, 
		    height - insideOffset * 2, halfWidth,
		    (relief == TK_RELIEF_GROOVE) ? 
		    TK_RELIEF_RAISED : TK_RELIEF_SUNKEN);
    return;
  }

  XColor* lightPtr = borderPtr->lightColorPtr;
  XColor* darkPtr = borderPtr->darkColorPtr;
  XColor light;
  if (!lightPtr) {
    light.red = 0x00;
    light.blue = 0x00;
    light.green = 0x00;
    lightPtr = &light;
  }
  XColor dark;
  if (!darkPtr) {
    dark.red = 0x00;
    dark.blue = 0x00;
    dark.green = 0x00;
    darkPtr = &dark;
  }

  XColor* topPtr, *bottomPtr;
  if (relief == TK_RELIEF_RAISED) {
    topPtr = lightPtr;
    bottomPtr = darkPtr;
  }
  else if (relief == TK_RELIEF_SUNKEN) {
    topPtr = darkPtr;
    bottomPtr = lightPtr;
  }
  else if (relief == TK_RELIEF_SOLID) {
    topPtr = lightPtr;
    bottomPtr = lightPtr;
  }
  else {
    topPtr = borderPtr->bgColorPtr;
    bottomPtr = borderPtr->bgColorPtr;
  }

  setBackground(bottomPtr);
  fillRectangle(x, y + height - borderWidth, width, borderWidth);
  fillRectangle(x + width - borderWidth, y, borderWidth, height);

  Point2d points[7];
  points[0].x = points[1].x = points[6].x = x;
  points[0].y = points[6].y = y + height;
  points[1].y = points[2].y = y;
  points[2].x = x + width;
  points[3].x = x + width - borderWidth;
  points[3].y = points[4].y = y + borderWidth;
  points[4].x = points[5].x = x + borderWidth;
  points[5].y = y + height - borderWidth;
  if (relief != TK_RELIEF_FLAT)
    setBackground(topPtr);

  fillPolygon(points, 7);
}

void PSOutput::printXColor(XColor* colorPtr)
{
  format("%g %g %g",
	 ((double)(colorPtr->red >> 8) / 255.0),
	 ((double)(colorPtr->green >> 8) / 255.0),
	 ((double)(colorPtr->blue >> 8) / 255.0));
}

int PSOutput::preamble(const char* fileName)
{
  Postscript* setupPtr = graphPtr_->postscript_;
  PostscriptOptions* ops = (PostscriptOptions*)setupPtr->ops_;

  if (!fileName)
    fileName = Tk_PathName(graphPtr_->tkwin_);

  // Comments
  append("%!PS-Adobe-3.0 EPSF-3.0\n");

  // The "BoundingBox" comment is required for EPS files. The box
  // coordinates are integers, so we need round away from the center of the
  // box.
  format("%%%%BoundingBox: %d %d %d %d\n",
	 setupPtr->left, setupPtr->paperHeight - setupPtr->top,
	 setupPtr->right, setupPtr->paperHeight - setupPtr->bottom);
	
  append("%%Pages: 0\n");

  format("%%%%Creator: (%s %s %s)\n", PACKAGE_NAME, PACKAGE_VERSION,
	 Tk_Class(graphPtr_->tkwin_));

  time_t ticks = time((time_t *) NULL);
  char date[200];
  strcpy(date, ctime(&ticks));
  char* newline = date + strlen(date) - 1;
  if (*newline == '\n')
    *newline = '\0';

  format("%%%%CreationDate: (%s)\n", date);
  format("%%%%Title: (%s)\n", fileName);
  append("%%DocumentData: Clean7Bit\n");
  if (ops->landscape)
    append("%%Orientation: Landscape\n");
  else
    append("%%Orientation: Portrait\n");

  append("%%DocumentNeededResources: font Helvetica Courier\n");
  addComments(ops->comments);
  append("%%EndComments\n\n");

  // Prolog
  prolog();

  // Setup
  append("%%BeginSetup\n");
  append("gsave\n");
  append("1 setlinewidth\n");
  append("1 setlinejoin\n");
  append("0 setlinecap\n");
  append("[] 0 setdash\n");
  append("0 0 0 setrgbcolor\n");

  if (ops->footer) {
    const char* who = getenv("LOGNAME");
    if (!who)
      who = "???";

    append("8 /Helvetica SetFont\n");
    append("10 30 moveto\n");
    format("(Date: %s) show\n", date);
    append("10 20 moveto\n");
    format("(File: %s) show\n", fileName);
    append("10 10 moveto\n");
    format("(Created by: %s@%s) show\n", who, Tcl_GetHostName());
    append("0 0 moveto\n");
  }

  // Set the conversion from postscript to X11 coordinates. Scale pica to
  // pixels and flip the y-axis (the origin is the upperleft corner).
  // Papersize is in pixels. Translate the new origin *after* changing the scale
  append("% Transform coordinate system to use X11 coordinates\n");
  append("% 1. Flip y-axis over by reversing the scale,\n");
  append("% 2. Translate the origin to the other side of the page,\n");
  append("%    making the origin the upper left corner\n");
  append("1 -1 scale\n");
  format("0 %d translate\n", -setupPtr->paperHeight);

  // Set Origin
  format("%% Set origin\n%d %d translate\n\n", setupPtr->left,setupPtr->bottom);
  if (ops->landscape)
    format("%% Landscape orientation\n0 %g translate\n-90 rotate\n",
	   ((double)graphPtr_->width_ * setupPtr->scale));

  append("\n%%EndSetup\n\n");

  return TCL_OK;
}

void PSOutput::addComments(const char** comments)
{
  if (!comments)
    return;

  for (const char** pp = comments; *pp; pp+=2) {
    if (*(pp+1) == NULL)
      break;
    format("%% %s: %s\n", *pp, *(pp+1));
  }
}

unsigned char PSOutput::reverseBits(unsigned char byte)
{
  byte = ((byte >> 1) & 0x55) | ((byte << 1) & 0xaa);
  byte = ((byte >> 2) & 0x33) | ((byte << 2) & 0xcc);
  byte = ((byte >> 4) & 0x0f) | ((byte << 4) & 0xf0);
  return byte;
}

void PSOutput::byteToHex(unsigned char byte, char* string)
{
  static char hexDigits[] = "0123456789ABCDEF";

  string[0] = hexDigits[byte >> 4];
  string[1] = hexDigits[byte & 0x0F];
}

void PSOutput::prolog()
{
  append(
"%%BeginProlog\n"
"%\n"
"% PostScript prolog file of the BLT graph widget.\n"
"%\n"
"% Copyright 1989-1992 Regents of the University of California.\n"
"% Permission to use, copy, modify, and distribute this\n"
"% software and its documentation for any purpose and without\n"
"% fee is hereby granted, provided that the above copyright\n"
"% notice appear in all copies.  The University of California\n"
"% makes no representations about the suitability of this\n"
"% software for any purpose.  It is provided 'as is' without\n"
"% express or implied warranty.\n"
"%\n"
"% Copyright 1991-1997 Bell Labs Innovations for Lucent Technologies.\n"
"%\n"
"% Permission to use, copy, modify, and distribute this software and its\n"
"% documentation for any purpose and without fee is hereby granted, provided\n"
"% that the above copyright notice appear in all copies and that both that the\n"
"% copyright notice and warranty disclaimer appear in supporting documentation,\n"
"% and that the names of Lucent Technologies any of their entities not be used\n"
"% in advertising or publicity pertaining to distribution of the software\n"
"% without specific, written prior permission.\n"
"%\n"
"% Lucent Technologies disclaims all warranties with regard to this software,\n"
"% including all implied warranties of merchantability and fitness.  In no event\n"
"% shall Lucent Technologies be liable for any special, indirect or\n"
"% consequential damages or any damages whatsoever resulting from loss of use,\n"
"% data or profits, whether in an action of contract, negligence or other\n"
"% tortuous action, arising out of or in connection with the use or performance\n"
"% of this software.\n"
"%\n"
"\n"
"200 dict begin\n"
"\n"
"/BaseRatio 1.3467736870885982 def	% Ratio triangle base / symbol size\n"
"/DrawSymbolProc 0 def			% Routine to draw symbol outline/fill\n"
"/DashesProc 0 def			% Dashes routine (line segments)\n"
"\n"
"% Define the array ISOLatin1Encoding (which specifies how characters are \n"
"% encoded for ISO-8859-1 fonts), if it isn't already present (Postscript \n"
"% level 2 is supposed to define it, but level 1 doesn't). \n"
"\n"
"systemdict /ISOLatin1Encoding known not { \n"
"  /ISOLatin1Encoding [ \n"
"    /space /space /space /space /space /space /space /space \n"
"    /space /space /space /space /space /space /space /space \n"
"    /space /space /space /space /space /space /space /space \n"
"    /space /space /space /space /space /space /space /space \n"
"    /space /exclam /quotedbl /numbersign /dollar /percent /ampersand \n"
"    /quoteright \n"
"    /parenleft /parenright /asterisk /plus /comma /minus /period /slash \n"
"    /zero /one /two /three /four /five /six /seven \n"
"    /eight /nine /colon /semicolon /less /equal /greater /question \n"
"    /at /A /B /C /D /E /F /G \n"
"    /H /I /J /K /L /M /N /O \n"
"    /P /Q /R /S /T /U /V /W \n"
"    /X /Y /Z /bracketleft /backslash /bracketright /asciicircum /underscore \n"
"    /quoteleft /a /b /c /d /e /f /g \n"
"    /h /i /j /k /l /m /n /o \n"
"    /p /q /r /s /t /u /v /w \n"
"    /x /y /z /braceleft /bar /braceright /asciitilde /space \n"
"    /space /space /space /space /space /space /space /space \n"
"    /space /space /space /space /space /space /space /space \n"
"    /dotlessi /grave /acute /circumflex /tilde /macron /breve /dotaccent \n"
"    /dieresis /space /ring /cedilla /space /hungarumlaut /ogonek /caron \n"
"    /space /exclamdown /cent /sterling /currency /yen /brokenbar /section \n"
"    /dieresis /copyright /ordfeminine /guillemotleft /logicalnot /hyphen \n"
"    /registered /macron \n"
"    /degree /plusminus /twosuperior /threesuperior /acute /mu /paragraph \n"
"    /periodcentered \n"
"    /cedillar /onesuperior /ordmasculine /guillemotright /onequarter \n"
"    /onehalf /threequarters /questiondown \n"
"    /Agrave /Aacute /Acircumflex /Atilde /Adieresis /Aring /AE /Ccedilla \n"
"    /Egrave /Eacute /Ecircumflex /Edieresis /Igrave /Iacute /Icircumflex \n"
"    /Idieresis \n"
"    /Eth /Ntilde /Ograve /Oacute /Ocircumflex /Otilde /Odieresis /multiply \n"
"    /Oslash /Ugrave /Uacute /Ucircumflex /Udieresis /Yacute /Thorn \n"
"    /germandbls \n"
"    /agrave /aacute /acircumflex /atilde /adieresis /aring /ae /ccedilla \n"
"    /egrave /eacute /ecircumflex /edieresis /igrave /iacute /icircumflex \n"
"    /idieresis \n"
"    /eth /ntilde /ograve /oacute /ocircumflex /otilde /odieresis /divide \n"
"    /oslash /ugrave /uacute /ucircumflex /udieresis /yacute /thorn \n"
"    /ydieresis \n"
"  ] def \n"
"} if \n"
"\n"
"% font ISOEncode font \n"
"% This procedure changes the encoding of a font from the default \n"
"% Postscript encoding to ISOLatin1.  It is typically invoked just \n"
"% before invoking 'setfont'.  The body of this procedure comes from \n"
"% Section 5.6.1 of the Postscript book. \n"
"\n"
"/ISOEncode { \n"
"  dup length dict\n"
"  begin \n"
"    {1 index /FID ne {def} {pop pop} ifelse} forall \n"
"    /Encoding ISOLatin1Encoding def \n"
"    currentdict \n"
"  end \n"
"\n"
"  % I'm not sure why it's necessary to use 'definefont' on this new \n"
"  % font, but it seems to be important; just use the name 'Temporary' \n"
"  % for the font. \n"
"\n"
"  /Temporary exch definefont \n"
"} bind def \n"
"\n"
"/Stroke {\n"
"  gsave\n"
"    stroke\n"
"  grestore\n"
"} def\n"
"\n"
"/Fill {\n"
"  gsave\n"
"    fill\n"
"  grestore\n"
"} def\n"
"\n"
"/SetFont { 	\n"
"  % Stack: pointSize fontName\n"
"  findfont exch scalefont ISOEncode setfont\n"
"} def\n"
"\n"
"/Box {\n"
"  % Stack: x y width height\n"
"  newpath\n"
"    exch 4 2 roll moveto\n"
"    dup 0 rlineto\n"
"    exch 0 exch rlineto\n"
"    neg 0 rlineto\n"
"  closepath\n"
"} def\n"
"\n"
"/LS {	% Stack: x1 y1 x2 y2\n"
"  newpath \n"
"    4 2 roll moveto \n"
"    lineto \n"
"  closepath\n"
"  stroke\n"
"} def\n"
"\n"
"/baselineSampler ( TXygqPZ) def\n"
"% Put an extra-tall character in; done this way to avoid encoding trouble\n"
"baselineSampler 0 196 put\n"
"\n"
"/cstringshow {\n"
"  {\n"
"    dup type /stringtype eq\n"
"    { show } { glyphshow }\n"
"    ifelse\n"
"  } forall\n"
"} bind def\n"
"\n"
"/cstringwidth {\n"
"  0 exch 0 exch\n"
"  {\n"
"    dup type /stringtype eq\n"
"    { stringwidth } {\n"
"      currentfont /Encoding get exch 1 exch put (\001)\n"
"      stringwidth\n"
"    }\n"
"    ifelse\n"
"    exch 3 1 roll add 3 1 roll add exch\n"
"  } forall\n"
"} bind def\n" 
"\n"
"/DrawText {\n"
"  gsave\n"
"  /justify exch def\n"
"  /yoffset exch def\n"
"  /xoffset exch def\n"
"  /strings exch def\n"
"  /yy exch def\n"
"  /xx exch def\n"
"  /rr exch def\n"
"  % Compute the baseline offset and the actual font height.\n"
"  0 0 moveto baselineSampler false charpath\n"
"  pathbbox dup /baseline exch def\n"
"  exch pop exch sub /height exch def pop\n"
"  newpath\n"
"  % overall width\n"
"  /ww 0 def\n"
"  strings {\n"
"    cstringwidth pop\n"
"    dup ww gt {/ww exch def} {pop} ifelse\n"
"    newpath\n"
"  } forall\n"
"  % overall height\n"
"  /hh 0 def\n"
"  strings length height mul /hh exch def\n"
"  newpath\n"
"  % Translate to x,y\n"
"  xx yy translate\n"
"  % Translate to offset\n"
"  xoffset rr cos mul     yoffset rr sin mul add /xxo exch def\n"
"  xoffset rr sin mul neg yoffset rr cos mul add /yyo exch def\n"
"  ww xxo mul hh yyo mul translate\n"
"  % rotate\n"
"  ww 2 div hh 2 div translate\n"
"  rr neg rotate\n"
"  ww -2 div hh -2 div translate\n"
"  % Translate to justify and baseline\n"
"  justify ww mul baseline translate\n"
"  % For each line, justify and display\n"
"  strings {\n"
"    dup cstringwidth pop\n"
"    justify neg mul 0 moveto\n"
"    gsave\n"
"    1 -1 scale\n"
"    cstringshow\n"
"    grestore\n"
"    0 height translate\n"
"  } forall\n"
"  grestore\n"
"} bind def \n"
"\n"
"% Symbols:\n"
"\n"
"% Skinny-cross\n"
"/Sc {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate 45 rotate\n"
"    0 0 3 -1 roll Sp\n"
"  grestore\n"
"} def\n"
"\n"
"% Skinny-plus\n"
"/Sp {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate\n"
"    2 div\n"
"    dup 2 copy\n"
"    newpath \n"
"      neg 0 \n"
"      moveto 0 \n"
"      lineto\n"
"    DrawSymbolProc\n"
"    newpath \n"
"      neg 0 \n"
"      exch moveto 0 \n"
"      exch lineto\n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"% Cross\n"
"/Cr {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate 45 rotate\n"
"    0 0 3 -1 roll Pl\n"
"  grestore\n"
"} def\n"
"\n"
"% Plus\n"
"/Pl {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate\n"
"    dup 2 div\n"
"    exch 6 div\n"
"\n"
"    %\n"
"    %          2   3		The plus/cross symbol is a\n"
"    %				closed polygon of 12 points.\n"
"    %      0   1   4    5	The diagram to the left\n"
"    %           x,y		represents the positions of\n"
"    %     11  10   7    6	the points which are computed\n"
"    %				below.\n"
"    %          9   8\n"
"    %\n"
"\n"
"    newpath\n"
"      2 copy exch neg exch neg moveto \n"
"      dup neg dup lineto\n"
"      2 copy neg exch neg lineto\n"
"      2 copy exch neg lineto\n"
"      dup dup neg lineto \n"
"      2 copy neg lineto 2 copy lineto\n"
"      dup dup lineto \n"
"      2 copy exch lineto \n"
"      2 copy neg exch lineto\n"
"      dup dup neg exch lineto \n"
"      exch neg exch lineto\n"
"    closepath\n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"% Circle\n"
"/Ci {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 copy pop moveto \n"
"    newpath\n"
"      2 div 0 360 arc\n"
"    closepath \n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"% Square\n"
"/Sq {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    dup dup 2 div dup\n"
"    6 -1 roll exch sub exch\n"
"    5 -1 roll exch sub 4 -2 roll Box\n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"% Line\n"
"/Li {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 1 roll exch 3 -1 roll 2 div 3 copy\n"
"    newpath\n"
"      sub exch moveto \n"
"      add exch lineto\n"
"    closepath\n"
"    stroke\n"
"  grestore\n"
"} def\n"
"\n"
"% Diamond\n"
"/Di {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 1 roll translate 45 rotate 0 0 3 -1 roll Sq\n"
"  grestore\n"
"} def\n"
"    \n"
"% Triangle\n"
"/Tr {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate\n"
"    BaseRatio mul 0.5 mul		% Calculate 1/2 base\n"
"    dup 0 exch 30 cos mul		% h1 = height above center point\n"
"    neg				% b2 0 -h1\n"
"    newpath \n"
"      moveto				% point 1;  b2\n"
"      dup 30 sin 30 cos div mul	% h2 = height below center point\n"
"      2 copy lineto			% point 2;  b2 h2\n"
"      exch neg exch lineto		% \n"
"    closepath\n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"% Arrow\n"
"/Ar {\n"
"  % Stack: x y symbolSize\n"
"  gsave\n"
"    3 -2 roll translate\n"
"    BaseRatio mul 0.5 mul		% Calculate 1/2 base\n"
"    dup 0 exch 30 cos mul		% h1 = height above center point\n"
"					% b2 0 h1\n"
"    newpath moveto			% point 1;  b2\n"
"    dup 30 sin 30 cos div mul		% h2 = height below center point\n"
"    neg				% -h2 b2\n"
"    2 copy lineto			% point 2;  b2 h2\n"
"    exch neg exch lineto		% \n"
"    closepath\n"
"    DrawSymbolProc\n"
"  grestore\n"
"} def\n"
"\n"
"%%EndProlog\n"
);
}
