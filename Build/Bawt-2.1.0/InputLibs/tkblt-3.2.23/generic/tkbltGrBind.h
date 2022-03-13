/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1998-2004 George A Howlett.
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

#ifndef __BltGrBind_h__
#define __BltGrBind_h__

#include <tk.h>

#include "tkbltGrMisc.h"

namespace Blt {
  class Graph;
  class Pick;

  class BindTable {
  protected:
    Tk_BindingTable table_;
    unsigned int grab_;
    ClientData newItem_;
    ClassId newContext_;
    Pick* pickPtr_;

  public:
    Graph* graphPtr_;
    ClientData currentItem_;
    ClassId currentContext_;
    ClientData focusItem_;
    ClassId focusContext_;
    int state_;
    XEvent pickEvent_;

  public:
    BindTable(Graph*, Pick*);
    virtual ~BindTable();
  
    int configure(ClientData, int, Tcl_Obj *const []);
    void deleteBindings(ClientData object);
    void doEvent(XEvent*);
    void pickItem(XEvent*);

    ClientData currentItem() {return currentItem_;}
  };
};


#endif
