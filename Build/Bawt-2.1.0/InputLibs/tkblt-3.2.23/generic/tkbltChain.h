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
#ifndef _BLT_CHAIN_H
#define _BLT_CHAIN_H

#define Chain_GetLength(c) (((c) == NULL) ? 0 : (c)->nLinks())
#define Chain_FirstLink(c) (((c) == NULL) ? NULL : (c)->head())
#define Chain_LastLink(c) (((c) == NULL) ? NULL : (c)->tail())

#define Chain_PrevLink(l) ((l)->prev())
#define Chain_NextLink(l) ((l)->next())
#define Chain_GetValue(l) ((l)->clientData())

namespace Blt {

  class Chain;

  class ChainLink {
    friend class Chain;

  protected:
    ChainLink* prev_;
    ChainLink* next_;
    int manage_;
    void* clientData_;

  public:
    ChainLink(void*);
    ChainLink(size_t);
    virtual ~ChainLink();

    ChainLink* prev() {return prev_;}
    ChainLink* next() {return next_;}
    void* clientData() {return clientData_;}
    void setClientData(void* d) {clientData_ =d;}
  };

  class Chain {
  protected:
    ChainLink* head_;
    ChainLink* tail_;
    long nLinks_;

  public:
    Chain();
    virtual ~Chain();

    ChainLink* head() {return head_;}
    ChainLink* tail() {return tail_;}
    long nLinks() {return nLinks_;}

    void reset();
    void linkAfter(ChainLink* link, ChainLink* after);
    void linkBefore(ChainLink* link, ChainLink* before);
    void unlinkLink(ChainLink* linkPtr);
    void deleteLink(ChainLink* link);
    ChainLink* append(void* clientData);
    ChainLink* prepend(void* clientData);
  };
};

#endif
