/*
 *	Copyright 2017 Patzschke+Rasp Software GmbH
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

#ifndef __TKBLT_INT_H__

#if defined(_MSC_VER)

#include <limits>

#if !defined(NAN)
#define NAN (std::numeric_limits<double>::quiet_NaN())
#endif

#if !defined(isnan)
#define isnan(x) _isnan(x)
#endif

#if !defined(isfinite)
#define isfinite(x) _finite(x)
#endif

#if !defined(isinf)
#define isinf(x) !_finite(x)
#endif

#if !defined(numeric_limits)
#define numeric_limits(x) _numeric_limits(x)
#endif

#if _MSC_VER < 1900
#define snprintf _snprintf
#else
#include <stdio.h> //sprintf
#endif

#endif	/* _MSC_VER */

#endif	/* __TKBLT_INT_H__ */
