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

#ifndef BLT_NS_UTIL_H
#define BLT_NS_UTIL_H 1

#define NS_SEARCH_NONE		(0)
#define NS_SEARCH_CURRENT	(1<<0)
#define NS_SEARCH_GLOBAL	(1<<1)
#define NS_SEARCH_BOTH		(NS_SEARCH_GLOBAL | NS_SEARCH_CURRENT)

#define BLT_NO_DEFAULT_NS	(1<<0)
#define BLT_NO_ERROR_MSG	(1<<1)

namespace Blt {

  typedef struct {
    const char *name;
    Tcl_Namespace *nsPtr;
  } Blt_ObjectName;

  extern Tcl_Namespace* GetVariableNamespace(Tcl_Interp* interp, 
					     const char *varName);

  extern Tcl_Namespace* GetCommandNamespace(Tcl_Command cmdToken);

  extern int ParseObjectName(Tcl_Interp* interp, const char *name, 
				 Blt_ObjectName *objNamePtr, 
				 unsigned int flags);

  extern char* MakeQualifiedName(Blt_ObjectName *objNamePtr, 
				 Tcl_DString *resultPtr);
};

#endif /* BLT_NS_UTIL_H */
