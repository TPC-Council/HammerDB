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

#include "tkbltChain.h"

using namespace Blt;

// ChainLink

ChainLink::ChainLink(void* clientData)
{
  prev_ =NULL;
  next_ =NULL;
  manage_ =0;
  clientData_ = clientData;
}

ChainLink::ChainLink(size_t ss)
{
  prev_ =NULL;
  next_ =NULL;
  manage_ =1;
  clientData_ = (void*)calloc(1,ss);
}

ChainLink::~ChainLink()
{
  if (manage_ && clientData_)
    free(clientData_);
}

// Chain

Chain::Chain()
{
  head_ =NULL;
  tail_ =NULL;
  nLinks_ =0;
}

Chain::~Chain()
{
  ChainLink* linkPtr = head_;
  while (linkPtr) {
    ChainLink* oldPtr =linkPtr;
    linkPtr = linkPtr->next_;
    delete oldPtr;
  }
}

void Chain::reset()
{
  ChainLink* linkPtr = head_;
  while (linkPtr) {
    ChainLink* oldPtr = linkPtr;
    linkPtr = linkPtr->next_;
    delete oldPtr;
  }
  head_ =NULL;
  tail_ =NULL;
  nLinks_ =0;
}

void Chain::linkAfter(ChainLink* linkPtr, ChainLink* afterPtr)
{
  if (!head_) {
    head_ = linkPtr;
    tail_ = linkPtr;
  }
  else {
    if (!afterPtr) {
      linkPtr->next_ = NULL;
      linkPtr->prev_ = tail_;
      tail_->next_ = linkPtr;
      tail_ = linkPtr;
    } 
    else {
      linkPtr->next_ = afterPtr->next_;
      linkPtr->prev_ = afterPtr;
      if (afterPtr == tail_)
	tail_ = linkPtr;
      else
	afterPtr->next_->prev_ = linkPtr;
      afterPtr->next_ = linkPtr;
    }
  }

  nLinks_++;
}

void Chain::linkBefore(ChainLink* linkPtr, ChainLink* beforePtr)
{
  if (!head_) {
    head_ = linkPtr;
    tail_ = linkPtr;
  }
  else {
    if (beforePtr == NULL) {
      linkPtr->next_ = head_;
      linkPtr->prev_ = NULL;
      head_->prev_ = linkPtr;
      head_ = linkPtr;
    }
    else {
      linkPtr->prev_ = beforePtr->prev_;
      linkPtr->next_ = beforePtr;
      if (beforePtr == head_)
	head_ = linkPtr;
      else
	beforePtr->prev_->next_ = linkPtr;
      beforePtr->prev_ = linkPtr;
    }
  }

  nLinks_++;
}

void Chain::unlinkLink(ChainLink* linkPtr)
{
  // Indicates if the link is actually remove from the chain
  int unlinked;

  unlinked = 0;
  if (head_ == linkPtr) {
    head_ = linkPtr->next_;
    unlinked = 1;
  }
  if (tail_ == linkPtr) {
    tail_ = linkPtr->prev_;
    unlinked = 1;
  }
  if (linkPtr->next_) {
    linkPtr->next_->prev_ = linkPtr->prev_;
    unlinked = 1;
  }
  if (linkPtr->prev_) {
    linkPtr->prev_->next_ = linkPtr->next_;
    unlinked = 1;
  }
  if (unlinked)
    nLinks_--;

  linkPtr->prev_ =NULL;
  linkPtr->next_ =NULL;
}

void Chain::deleteLink(ChainLink* link)
{
  unlinkLink(link);
  delete link;
  link = NULL;
}

ChainLink* Chain::append(void* clientData)
{
  ChainLink* link = new ChainLink(clientData);
  linkAfter(link, NULL);
  return link;
}

ChainLink* Chain::prepend(void* clientData)
{
  ChainLink* link = new ChainLink(clientData);
  linkBefore(link, NULL);
  return link;
}
