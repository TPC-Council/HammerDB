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

#ifndef __BltGrLegend_h__
#define __BltGrLegend_h__

#include <tk.h>

#include "tkbltGrMisc.h"
#include "tkbltGrText.h"

namespace Blt {
  class Graph;
  class Pick;
  class Element;

  /*
   *  Selection related flags:
   *	SELECT_PENDING		A "selection" command idle task is pending.
   *	SELECT_CLEAR		Clear selection flag of entry.
   *	SELECT_SET		Set selection flag of entry.
   *	SELECT_TOGGLE		Toggle selection flag of entry.
   *			        Mask of selection set/clear/toggle flags.
   *	SELECT_SORTED		Indicates if the entries in the selection 
   *				should be sorted or displayed in the order 
   *				they were selected.
   */

#define SELECT_CLEAR		(1<<24)
#define SELECT_PENDING		(1<<25)
#define SELECT_SET		(1<<26)
#define SELECT_SORTED		(1<<27)
#define SELECT_TOGGLE		(SELECT_SET | SELECT_CLEAR)

  typedef enum {
    SELECT_MODE_SINGLE, SELECT_MODE_MULTIPLE
  } SelectMode;

  typedef struct {
    Tk_3DBorder activeBg;
    XColor* activeFgColor;
    int activeRelief;
    Tk_3DBorder normalBg;
    XColor* fgColor;
    Tk_Anchor anchor;
    int borderWidth;
    int reqColumns;
    int exportSelection;
    Dashes focusDashes;
    XColor* focusColor;
    TextStyleOptions style;
    int hide;
    int ixPad;
    int iyPad;
    int xPad;
    int yPad;
    int raised;
    int relief;
    int reqRows;
    int entryBW;
    int selBW;
    int xReq;
    int yReq;
    int position;
    const char *selectCmd;
    Tk_3DBorder selOutFocusBg;
    Tk_3DBorder selInFocusBg;
    XColor* selOutFocusFgColor;
    XColor* selInFocusFgColor;
    SelectMode selectMode;
    int selRelief;
    const char *title;
    TextStyleOptions titleStyle;
  } LegendOptions;

  class Legend : public Pick {
  public:
    enum Position {RIGHT, LEFT, TOP, BOTTOM, PLOT, XY};

  protected:
    Tk_OptionTable optionTable_;
    void* ops_;

    GC focusGC_;
    Tcl_HashTable selectTable_;

  public:
    Graph* graphPtr_;
    unsigned int flags;

    int width_;
    int height_;
    int x_;
    int y_;

    int nEntries_;
    int nColumns_;
    int nRows_;
    int entryWidth_;
    int entryHeight_;
    BindTable* bindTable_;
    Element* focusPtr_;
    Element* selAnchorPtr_;
    Element* selMarkPtr_;
    Chain* selected_;
    int titleWidth_;
    int titleHeight_;

  protected:
    void setOrigin();
    Element* getNextRow(Element*);
    Element* getNextColumn(Element*);
    Element* getPreviousRow(Element*);
    Element* getPreviousColumn(Element*);
    Element* getFirstElement();
    Element* getLastElement();

  public:
    Legend(Graph*);
    virtual ~Legend();

    int configure();
    void map(int, int);
    void draw(Drawable drawable);
    void print(PSOutput* ps);
    void eventuallyInvokeSelectCmd();

    void removeElement(Element*);
    int getElementFromObj(Tcl_Obj*, Element**);

    void selectEntry(Element*);
    void selectElement(Element*);
    void deselectElement(Element*);
    int selectRange(Element*, Element*);
    void clearSelection();
    int entryIsSelected(Element*);

    void* ops() {return ops_;}
    Tk_OptionTable optionTable() {return optionTable_;}

    Position position() {return (Position)((LegendOptions*)ops_)->position;}
    int isRaised() {return ((LegendOptions*)ops_)->raised;}
    int isHidden() {return ((LegendOptions*)ops_)->hide;}

    ClientData pickEntry(int, int, ClassId*);
  };
};

#endif
