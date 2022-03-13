/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 1995-2004 George A Howlett.
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

#include <cmath>

#include <float.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include <cmath>

#include "tkbltInt.h"
#include "tkbltVecInt.h"
#include "tkbltNsUtil.h"
#include "tkbltParse.h"

using namespace std;
using namespace Blt;

/*
 * Three types of math functions:
 *
 *	ComponentProc		Function is applied in multiple calls to
 *				each component of the vector.
 *	VectorProc		Entire vector is passed, each component is
 *				modified.
 *	ScalarProc		Entire vector is passed, single scalar value
 *				is returned.
 */

typedef double (ComponentProc)(double value);
typedef int (VectorProc)(Vector *vPtr);
typedef double (ScalarProc)(Vector *vPtr);

/*
 * Built-in math functions:
 */
typedef int (GenericMathProc) (void*, Tcl_Interp*, Vector*);

/*
 * MathFunction --
 *
 *	Contains information about math functions that can be called
 *	for vectors.  The table of math functions is global within the
 *	application.  So you can't define two different "sqrt"
 *	functions.
 */
typedef struct {
  const char *name;		/* Name of built-in math function.  If
				 * NULL, indicates that the function
				 * was user-defined and dynamically
				 * allocated.  Function names are
				 * global across all interpreters. */

  void *proc;			/* Procedure that implements this math
				 * function. */

  ClientData clientData;	/* Argument to pass when invoking the
				 * function. */

} MathFunction;

/* The data structure below is used to describe an expression value,
 * which can be either a double-precision floating-point value, or a
 * string.  A given number has only one value at a time.  */

#define STATIC_STRING_SPACE 150

/*
 * Tokens --
 *
 *	The token types are defined below.  In addition, there is a
 *	table associating a precedence with each operator.  The order
 *	of types is important.  Consult the code before changing it.
 */
enum Tokens {
  VALUE, OPEN_PAREN, CLOSE_PAREN, COMMA, END, UNKNOWN,
  MULT = 8, DIVIDE, MOD, PLUS, MINUS,
  LEFT_SHIFT, RIGHT_SHIFT,
  LESS, GREATER, LEQ, GEQ, EQUAL, NEQ,
  OLD_BIT_AND, EXPONENT, OLD_BIT_OR, OLD_QUESTY, OLD_COLON,
  AND, OR, UNARY_MINUS, OLD_UNARY_PLUS, NOT, OLD_BIT_NOT
};

typedef struct {
  Vector *vPtr;
  char staticSpace[STATIC_STRING_SPACE];
  ParseValue pv;		/* Used to hold a string value, if any. */
} Value;

/*
 * ParseInfo --
 *
 *	The data structure below describes the state of parsing an
 *	expression.  It's passed among the routines in this module.
 */
typedef struct {
  const char *expr;		/* The entire right-hand side of the
				 * expression, as originally passed to
				 * Blt_ExprVector. */

  const char *nextPtr;	/* Position of the next character to
			 * be scanned from the expression
			 * string. */

  enum Tokens token;		/* Type of the last token to be parsed
				 * from nextPtr.  See below for
				 * definitions.  Corresponds to the
				 * characters just before nextPtr. */

} ParseInfo;

/*
 * Precedence table.  The values for non-operator token types are ignored.
 */
static int precTable[] =
  {
    0, 0, 0, 0, 0, 0, 0, 0,
    12, 12, 12,			/* MULT, DIVIDE, MOD */
    11, 11,			/* PLUS, MINUS */
    10, 10,			/* LEFT_SHIFT, RIGHT_SHIFT */
    9, 9, 9, 9,			/* LESS, GREATER, LEQ, GEQ */
    8, 8,			/* EQUAL, NEQ */
    7,				/* OLD_BIT_AND */
    13,				/* EXPONENTIATION */
    5,				/* OLD_BIT_OR */
    4,				/* AND */
    3,				/* OR */
    2,				/* OLD_QUESTY */
    1,				/* OLD_COLON */
    14, 14, 14, 14		/* UNARY_MINUS, OLD_UNARY_PLUS, NOT,
				 * OLD_BIT_NOT */
  };


/*
 * Forward declarations.
 */

static int NextValue(Tcl_Interp* interp, ParseInfo *piPtr, int prec, 
		     Value *valuePtr);

static int Sort(Vector *vPtr)
{
  size_t* map = Vec_SortMap(&vPtr, 1);
  double* values = (double*)malloc(sizeof(double) * vPtr->length);
  for(int ii = vPtr->first; ii <= vPtr->last; ii++)
    values[ii] = vPtr->valueArr[map[ii]];

  free(map);
  for (int ii = vPtr->first; ii <= vPtr->last; ii++)
    vPtr->valueArr[ii] = values[ii];

  free(values);
  return TCL_OK;
}

static double Length(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  return (double)(vPtr->last - vPtr->first + 1);
}

double Blt_VecMax(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  return Vec_Max(vPtr);
}

double Blt_VecMin(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  return Vec_Min(vPtr);
}

int Blt_ExprVector(Tcl_Interp* interp, char *string, Blt_Vector *vector)
{
  return ExprVector(interp,string,vector);
}

static double Product(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double prod;
  double *vp, *vend;

  prod = 1.0;
  for(vp = vPtr->valueArr + vPtr->first,
	vend = vPtr->valueArr + vPtr->last; vp <= vend; vp++) {
    prod *= *vp;
  }
  return prod;
}

static double Sum(Blt_Vector *vectorPtr)
{
  // Kahan summation algorithm

  Vector *vPtr = (Vector *)vectorPtr;
  double* vp = vPtr->valueArr + vPtr->first;
  double sum = *vp++;
  double c = 0.0;			/* A running compensation for lost
				 * low-order bits.*/
  for (double* vend = vPtr->valueArr + vPtr->last; vp <= vend; vp++) {
    double y = *vp - c;		/* So far, so good: c is zero.*/
    double t = sum + y;		/* Alas, sum is big, y small, so
				 * low-order digits of y are lost.*/
    c = (t - sum) - y;	/* (t - sum) recovers the high-order
			 * part of y; subtracting y recovers
			 * -(low part of y) */
    sum = t;
  }

  return sum;
}

static double Mean(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double sum = Sum(vectorPtr);
  int n = vPtr->last - vPtr->first + 1;

  return sum / (double)n;
}

// var = 1/N Sum( (x[i] - mean)^2 )
static double Variance(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double mean = Mean(vectorPtr);
  double var = 0.0;
  int count = 0;
  for(double *vp=vPtr->valueArr+vPtr->first, *vend=vPtr->valueArr+vPtr->last;
      vp <= vend; vp++) {
    double dx = *vp - mean;
    var += dx * dx;
    count++;
  }

  if (count < 2)
    return 0.0;

  var /= (double)(count - 1);
  return var;
}

// skew = Sum( (x[i] - mean)^3 ) / (var^3/2)
static double Skew(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double mean = Mean(vectorPtr);
  double var = 0;
  double skew = 0;
  int count = 0;
  for(double *vp=vPtr->valueArr+vPtr->first, *vend=vPtr->valueArr+vPtr->last;
      vp <= vend; vp++) {
    double diff = *vp - mean;
    diff = fabs(diff);
    double diffsq = diff * diff;
    var += diffsq;
    skew += diffsq * diff;
    count++;
  }

  if (count < 2)
    return 0.0;

  var /= (double)(count - 1);
  skew /= count * var * sqrt(var);
  return skew;
}

static double StdDeviation(Blt_Vector *vectorPtr)
{
  double var;

  var = Variance(vectorPtr);
  if (var > 0.0) {
    return sqrt(var);
  }
  return 0.0;
}

static double AvgDeviation(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double mean = Mean(vectorPtr);
  double avg = 0.0;
  int count = 0;
  for(double *vp=vPtr->valueArr+vPtr->first, *vend=vPtr->valueArr+vPtr->last;
      vp <= vend; vp++) {
    double diff = *vp - mean;
    avg += fabs(diff);
    count++;
  }

  if (count < 2)
    return 0.0;

  avg /= (double)count;
  return avg;
}

static double Kurtosis(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double mean = Mean(vectorPtr);
  double var = 0;
  double kurt = 0;
  int count = 0;
  for(double *vp=vPtr->valueArr+vPtr->first, *vend=vPtr->valueArr+vPtr->last;
      vp <= vend; vp++) {
    double diff = *vp - mean;
    double diffsq = diff * diff;
    var += diffsq;
    kurt += diffsq * diffsq;
    count++;
  }

  if (count < 2)
    return 0.0;

  var /= (double)(count - 1);

  if (var == 0.0)
    return 0.0;

  kurt /= (count * var * var);
  return kurt - 3.0;		/* Fisher Kurtosis */
}

static double Median(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  size_t *map;
  double q2;
  int mid;

  if (vPtr->length == 0) {
    return -DBL_MAX;
  }
  map = Vec_SortMap(&vPtr, 1);
  mid = (vPtr->length - 1) / 2;

  /*  
   * Determine Q2 by checking if the number of elements [0..n-1] is
   * odd or even.  If even, we must take the average of the two
   * middle values.  
   */
  if (vPtr->length & 1) { /* Odd */
    q2 = vPtr->valueArr[map[mid]];
  } else {			/* Even */
    q2 = (vPtr->valueArr[map[mid]] + 
	  vPtr->valueArr[map[mid + 1]]) * 0.5;
  }
  free(map);
  return q2;
}

static double Q1(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double q1;
  size_t *map;

  if (vPtr->length == 0) {
    return -DBL_MAX;
  } 
  map = Vec_SortMap(&vPtr, 1);

  if (vPtr->length < 4) {
    q1 = vPtr->valueArr[map[0]];
  } else {
    int mid, q;

    mid = (vPtr->length - 1) / 2;
    q = mid / 2;

    /* 
     * Determine Q1 by checking if the number of elements in the
     * bottom half [0..mid) is odd or even.   If even, we must
     * take the average of the two middle values.
     */
    if (mid & 1) {		/* Odd */
      q1 = vPtr->valueArr[map[q]]; 
    } else {		/* Even */
      q1 = (vPtr->valueArr[map[q]] + 
	    vPtr->valueArr[map[q + 1]]) * 0.5; 
    }
  }
  free(map);
  return q1;
}

static double Q3(Blt_Vector *vectorPtr)
{
  Vector *vPtr = (Vector *)vectorPtr;
  double q3;
  size_t *map;

  if (vPtr->length == 0) {
    return -DBL_MAX;
  } 

  map = Vec_SortMap(&vPtr, 1);

  if (vPtr->length < 4) {
    q3 = vPtr->valueArr[map[vPtr->length - 1]];
  } else {
    int mid, q;

    mid = (vPtr->length - 1) / 2;
    q = (vPtr->length + mid) / 2;

    /* 
     * Determine Q3 by checking if the number of elements in the
     * upper half (mid..n-1] is odd or even.   If even, we must
     * take the average of the two middle values.
     */
    if (mid & 1) {		/* Odd */
      q3 = vPtr->valueArr[map[q]];
    } else {		/* Even */
      q3 = (vPtr->valueArr[map[q]] + 
	    vPtr->valueArr[map[q + 1]]) * 0.5; 
    }
  }
  free(map);
  return q3;
}

static int Norm(Blt_Vector *vector)
{
  Vector *vPtr = (Vector *)vector;
  double norm, range, min, max;
  int i;

  min = Vec_Min(vPtr);
  max = Vec_Max(vPtr);
  range = max - min;
  for (i = 0; i < vPtr->length; i++) {
    norm = (vPtr->valueArr[i] - min) / range;
    vPtr->valueArr[i] = norm;
  }
  return TCL_OK;
}

static double Nonzeros(Blt_Vector *vector)
{
  Vector *vPtr = (Vector *)vector;
  int count;
  double *vp, *vend;

  count = 0;
  for(vp = vPtr->valueArr + vPtr->first, vend = vPtr->valueArr + vPtr->last; vp <= vend; vp++) {
    if (*vp == 0.0)
      count++;
  }
  return (double) count;
}

static double Fabs(double value)
{
  if (value < 0.0)
    return -value;
  return value;
}

static double Round(double value)
{
  if (value < 0.0)
    return ceil(value - 0.5);
  else
    return floor(value + 0.5);
}

static double Fmod(double x, double y)
{
  if (y == 0.0)
    return 0.0;
  return x - (floor(x / y) * y);
}

/*
 *---------------------------------------------------------------------------
 *
 * MathError --
 *
 *	This procedure is called when an error occurs during a
 *	floating-point operation.  It reads errno and sets
 *	interp->result accordingly.
 *
 * Results:
 *	Interp->result is set to hold an error message.
 *
 * Side effects:
 *	None.
 *
 *---------------------------------------------------------------------------
 */
static void MathError(Tcl_Interp* interp, double value)
{
  if ((errno == EDOM) || (value != value)) {
    Tcl_AppendResult(interp, "domain error: argument not in valid range",
		     (char *)NULL);
    Tcl_SetErrorCode(interp, "ARITH", "DOMAIN", 
		     Tcl_GetStringResult(interp), (char *)NULL);
  }
  else if ((errno == ERANGE) || isinf(value)) {
    if (value == 0.0) {
      Tcl_AppendResult(interp, 
		       "floating-point value too small to represent",
		       (char *)NULL);
      Tcl_SetErrorCode(interp, "ARITH", "UNDERFLOW", 
		       Tcl_GetStringResult(interp), (char *)NULL);
    }
    else {
      Tcl_AppendResult(interp, 
		       "floating-point value too large to represent",
		       (char *)NULL);
      Tcl_SetErrorCode(interp, "ARITH", "OVERFLOW", 
		       Tcl_GetStringResult(interp), (char *)NULL);
    }
  }
  else {
    Tcl_AppendResult(interp, "unknown floating-point error, ",
		     "errno = ", Itoa(errno), (char *)NULL);
    Tcl_SetErrorCode(interp, "ARITH", "UNKNOWN", 
		     Tcl_GetStringResult(interp), (char *)NULL);
  }
}

static int ParseString(Tcl_Interp* interp, const char *string, Value *valuePtr)
{
  const char *endPtr;
  double value;

  errno = 0;

  /*   
   * The string can be either a number or a vector.  First try to
   * convert the string to a number.  If that fails then see if
   * we can find a vector by that name.
   */

  value = strtod(string, (char **)&endPtr);
  if ((endPtr != string) && (*endPtr == '\0')) {
    if (errno != 0) {
      Tcl_ResetResult(interp);
      MathError(interp, value);
      return TCL_ERROR;
    }
    /* Numbers are stored as single element vectors. */
    if (Vec_ChangeLength(interp, valuePtr->vPtr, 1) != TCL_OK) {
      return TCL_ERROR;
    }
    valuePtr->vPtr->valueArr[0] = value;
    return TCL_OK;
  } else {
    Vector *vPtr;

    while (isspace((unsigned char)(*string))) {
      string++;		/* Skip spaces leading the vector name. */    
    }
    vPtr = Vec_ParseElement(interp, valuePtr->vPtr->dataPtr, 
				string, &endPtr, NS_SEARCH_BOTH);
    if (vPtr == NULL) {
      return TCL_ERROR;
    }
    if (*endPtr != '\0') {
      Tcl_AppendResult(interp, "extra characters after vector", 
		       (char *)NULL);
      return TCL_ERROR;
    }
    /* Copy the designated vector to our temporary. */
    Vec_Duplicate(valuePtr->vPtr, vPtr);
  }
  return TCL_OK;
}

static int ParseMathFunction(Tcl_Interp* interp, const char *start,
			     ParseInfo *piPtr, Value *valuePtr)
{
  Tcl_HashEntry *hPtr;
  MathFunction *mathPtr;	/* Info about math function. */
  char *p;
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  GenericMathProc *proc;

  /*
   * Find the end of the math function's name and lookup the
   * record for the function.
   */
  p = (char *)start;
  while (isspace((unsigned char)(*p))) {
    p++;
  }
  piPtr->nextPtr = p;
  while (isalnum((unsigned char)(*p)) || (*p == '_')) {
    p++;
  }
  if (*p != '(') {
    return TCL_RETURN;	/* Must start with open parenthesis */
  }
  dataPtr = valuePtr->vPtr->dataPtr;
  *p = '\0';
  hPtr = Tcl_FindHashEntry(&dataPtr->mathProcTable, piPtr->nextPtr);
  *p = '(';
  if (hPtr == NULL) {
    return TCL_RETURN;	/* Name doesn't match any known function */
  }
  /* Pick up the single value as the argument to the function */
  piPtr->token = OPEN_PAREN;
  piPtr->nextPtr = p + 1;
  valuePtr->pv.next = valuePtr->pv.buffer;
  if (NextValue(interp, piPtr, -1, valuePtr) != TCL_OK) {
    return TCL_ERROR;	/* Parse error */
  }
  if (piPtr->token != CLOSE_PAREN) {
    Tcl_AppendResult(interp, "unmatched parentheses in expression \"",
		     piPtr->expr, "\"", (char *)NULL);
    return TCL_ERROR;	/* Missing right parenthesis */
  }
  mathPtr = (MathFunction*)Tcl_GetHashValue(hPtr);
  proc = (GenericMathProc*)mathPtr->proc;
  if ((*proc) (mathPtr->clientData, interp, valuePtr->vPtr) != TCL_OK) {
    return TCL_ERROR;	/* Function invocation error */
  }
  piPtr->token = VALUE;
  return TCL_OK;
}

static int NextToken(Tcl_Interp* interp, ParseInfo *piPtr, Value *valuePtr)
{
  const char *p;
  const char *endPtr;
  const char *var;
  int result;

  p = piPtr->nextPtr;
  while (isspace((unsigned char)(*p))) {
    p++;
  }
  if (*p == '\0') {
    piPtr->token = END;
    piPtr->nextPtr = p;
    return TCL_OK;
  }
  /*
   * Try to parse the token as a floating-point number. But check
   * that the first character isn't a "-" or "+", which "strtod"
   * will happily accept as an unary operator.  Otherwise, we might
   * accidently treat a binary operator as unary by mistake, which
   * will eventually cause a syntax error.
   */
  if ((*p != '-') && (*p != '+')) {
    double value;

    errno = 0;
    value = strtod(p, (char **)&endPtr);
    if (endPtr != p) {
      if (errno != 0) {
	MathError(interp, value);
	return TCL_ERROR;
      }
      piPtr->token = VALUE;
      piPtr->nextPtr = endPtr;

      /*
       * Save the single floating-point value as an 1-component vector.
       */
      if (Vec_ChangeLength(interp, valuePtr->vPtr, 1) != TCL_OK) {
	return TCL_ERROR;
      }
      valuePtr->vPtr->valueArr[0] = value;
      return TCL_OK;
    }
  }
  piPtr->nextPtr = p + 1;
  switch (*p) {
  case '$':
    piPtr->token = VALUE;
    var = Tcl_ParseVar(interp, p, &endPtr);
    if (var == NULL) {
      return TCL_ERROR;
    }
    piPtr->nextPtr = endPtr;
    Tcl_ResetResult(interp);
    result = ParseString(interp, var, valuePtr);
    return result;

  case '[':
    piPtr->token = VALUE;
    result = ParseNestedCmd(interp, p + 1, 0, &endPtr, &valuePtr->pv);
    if (result != TCL_OK) {
      return result;
    }
    piPtr->nextPtr = endPtr;
    Tcl_ResetResult(interp);
    result = ParseString(interp, valuePtr->pv.buffer, valuePtr);
    return result;

  case '"':
    piPtr->token = VALUE;
    result = ParseQuotes(interp, p + 1, '"', 0, &endPtr, &valuePtr->pv);
    if (result != TCL_OK) {
      return result;
    }
    piPtr->nextPtr = endPtr;
    Tcl_ResetResult(interp);
    result = ParseString(interp, valuePtr->pv.buffer, valuePtr);
    return result;

  case '{':
    piPtr->token = VALUE;
    result = ParseBraces(interp, p + 1, &endPtr, &valuePtr->pv);
    if (result != TCL_OK) {
      return result;
    }
    piPtr->nextPtr = endPtr;
    Tcl_ResetResult(interp);
    result = ParseString(interp, valuePtr->pv.buffer, valuePtr);
    return result;

  case '(':
    piPtr->token = OPEN_PAREN;
    break;

  case ')':
    piPtr->token = CLOSE_PAREN;
    break;

  case ',':
    piPtr->token = COMMA;
    break;

  case '*':
    piPtr->token = MULT;
    break;

  case '/':
    piPtr->token = DIVIDE;
    break;

  case '%':
    piPtr->token = MOD;
    break;

  case '+':
    piPtr->token = PLUS;
    break;

  case '-':
    piPtr->token = MINUS;
    break;

  case '^':
    piPtr->token = EXPONENT;
    break;

  case '<':
    switch (*(p + 1)) {
    case '<':
      piPtr->nextPtr = p + 2;
      piPtr->token = LEFT_SHIFT;
      break;
    case '=':
      piPtr->nextPtr = p + 2;
      piPtr->token = LEQ;
      break;
    default:
      piPtr->token = LESS;
      break;
    }
    break;

  case '>':
    switch (*(p + 1)) {
    case '>':
      piPtr->nextPtr = p + 2;
      piPtr->token = RIGHT_SHIFT;
      break;
    case '=':
      piPtr->nextPtr = p + 2;
      piPtr->token = GEQ;
      break;
    default:
      piPtr->token = GREATER;
      break;
    }
    break;

  case '=':
    if (*(p + 1) == '=') {
      piPtr->nextPtr = p + 2;
      piPtr->token = EQUAL;
    } else {
      piPtr->token = UNKNOWN;
    }
    break;

  case '&':
    if (*(p + 1) == '&') {
      piPtr->nextPtr = p + 2;
      piPtr->token = AND;
    } else {
      piPtr->token = UNKNOWN;
    }
    break;

  case '|':
    if (*(p + 1) == '|') {
      piPtr->nextPtr = p + 2;
      piPtr->token = OR;
    } else {
      piPtr->token = UNKNOWN;
    }
    break;

  case '!':
    if (*(p + 1) == '=') {
      piPtr->nextPtr = p + 2;
      piPtr->token = NEQ;
    } else {
      piPtr->token = NOT;
    }
    break;

  default:
    piPtr->token = VALUE;
    result = ParseMathFunction(interp, p, piPtr, valuePtr);
    if ((result == TCL_OK) || (result == TCL_ERROR)) {
      return result;
    } else {
      Vector *vPtr;

      while (isspace((unsigned char)(*p))) {
	p++;		/* Skip spaces leading the vector name. */    
      }
      vPtr = Vec_ParseElement(interp, valuePtr->vPtr->dataPtr, 
				  p, &endPtr, NS_SEARCH_BOTH);
      if (vPtr == NULL) {
	return TCL_ERROR;
      }
      Vec_Duplicate(valuePtr->vPtr, vPtr);
      piPtr->nextPtr = endPtr;
    }
  }
  return TCL_OK;
}

static int NextValue(Tcl_Interp* interp, ParseInfo *piPtr,
		     int prec, Value *valuePtr)
{
  Value value2;		/* Second operand for current operator.  */
  int oper;		/* Current operator (either unary or binary). */
  int gotOp;			/* Non-zero means already lexed the operator
				 * (while picking up value for unary operator).
				 * Don't lex again. */
  int result;
  Vector *vPtr, *v2Ptr;
  int i;

  /*
   * There are two phases to this procedure.  First, pick off an initial
   * value.  Then, parse (binary operator, value) pairs until done.
   */

  vPtr = valuePtr->vPtr;
  v2Ptr = Vec_New(vPtr->dataPtr);
  gotOp = 0;
  value2.vPtr = v2Ptr;
  value2.pv.buffer = value2.pv.next = value2.staticSpace;
  value2.pv.end = value2.pv.buffer + STATIC_STRING_SPACE - 1;
  value2.pv.expandProc = ExpandParseValue;
  value2.pv.clientData = NULL;

  result = NextToken(interp, piPtr, valuePtr);
  if (result != TCL_OK) {
    goto done;
  }
  if (piPtr->token == OPEN_PAREN) {

    /* Parenthesized sub-expression. */

    result = NextValue(interp, piPtr, -1, valuePtr);
    if (result != TCL_OK) {
      goto done;
    }
    if (piPtr->token != CLOSE_PAREN) {
      Tcl_AppendResult(interp, "unmatched parentheses in expression \"",
		       piPtr->expr, "\"", (char *)NULL);
      result = TCL_ERROR;
      goto done;
    }
  } else {
    if (piPtr->token == MINUS) {
      piPtr->token = UNARY_MINUS;
    }
    if (piPtr->token >= UNARY_MINUS) {
      oper = piPtr->token;
      result = NextValue(interp, piPtr, precTable[oper], valuePtr);
      if (result != TCL_OK) {
	goto done;
      }
      gotOp = 1;
      /* Process unary operators. */
      switch (oper) {
      case UNARY_MINUS:
	for(i = 0; i < vPtr->length; i++) {
	  vPtr->valueArr[i] = -(vPtr->valueArr[i]);
	}
	break;

      case NOT:
	for(i = 0; i < vPtr->length; i++) {
	  vPtr->valueArr[i] = (double)(!vPtr->valueArr[i]);
	}
	break;
      default:
	Tcl_AppendResult(interp, "unknown operator", (char *)NULL);
	goto error;
      }
    } else if (piPtr->token != VALUE) {
      Tcl_AppendResult(interp, "missing operand", (char *)NULL);
      goto error;
    }
  }
  if (!gotOp) {
    result = NextToken(interp, piPtr, &value2);
    if (result != TCL_OK) {
      goto done;
    }
  }
  /*
   * Got the first operand.  Now fetch (operator, operand) pairs.
   */
  for (;;) {
    oper = piPtr->token;

    value2.pv.next = value2.pv.buffer;
    if ((oper < MULT) || (oper >= UNARY_MINUS)) {
      if ((oper == END) || (oper == CLOSE_PAREN) || 
	  (oper == COMMA)) {
	result = TCL_OK;
	goto done;
      } else {
	Tcl_AppendResult(interp, "bad operator", (char *)NULL);
	goto error;
      }
    }
    if (precTable[oper] <= prec) {
      result = TCL_OK;
      goto done;
    }
    result = NextValue(interp, piPtr, precTable[oper], &value2);
    if (result != TCL_OK) {
      goto done;
    }
    if ((piPtr->token < MULT) && (piPtr->token != VALUE) &&
	(piPtr->token != END) && (piPtr->token != CLOSE_PAREN) &&
	(piPtr->token != COMMA)) {
      Tcl_AppendResult(interp, "unexpected token in expression",
		       (char *)NULL);
      goto error;
    }
    /*
     * At this point we have two vectors and an operator.
     */

    if (v2Ptr->length == 1) {
      double *opnd;
      double scalar;

      /*
       * 2nd operand is a scalar.
       */
      scalar = v2Ptr->valueArr[0];
      opnd = vPtr->valueArr;
      switch (oper) {
      case MULT:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] *= scalar;
	}
	break;

      case DIVIDE:
	if (scalar == 0.0) {
	  Tcl_AppendResult(interp, "divide by zero", (char *)NULL);
	  goto error;
	}
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] /= scalar;
	}
	break;

      case PLUS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] += scalar;
	}
	break;

      case MINUS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] -= scalar;
	}
	break;

      case EXPONENT:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = pow(opnd[i], scalar);
	}
	break;

      case MOD:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = Fmod(opnd[i], scalar);
	}
	break;

      case LESS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] < scalar);
	}
	break;

      case GREATER:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] > scalar);
	}
	break;

      case LEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] <= scalar);
	}
	break;

      case GEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] >= scalar);
	}
	break;

      case EQUAL:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] == scalar);
	}
	break;

      case NEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] != scalar);
	}
	break;

      case AND:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] && scalar);
	}
	break;

      case OR:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] || scalar);
	}
	break;

      case LEFT_SHIFT:
	{
	  int offset;

	  offset = (int)scalar % vPtr->length;
	  if (offset > 0) {
	    double *hold;
	    int j;

	    hold = (double*)malloc(sizeof(double) * offset);
	    for (i = 0; i < offset; i++) {
	      hold[i] = opnd[i];
	    }
	    for (i = offset, j = 0; i < vPtr->length; i++, j++) {
	      opnd[j] = opnd[i];
	    }
	    for (i = 0, j = vPtr->length - offset;
		 j < vPtr->length; i++, j++) {
	      opnd[j] = hold[i];
	    }
	    free(hold);
	  }
	}
	break;

      case RIGHT_SHIFT:
	{
	  int offset;

	  offset = (int)scalar % vPtr->length;
	  if (offset > 0) {
	    double *hold;
	    int j;
			
	    hold = (double*)malloc(sizeof(double) * offset);
	    for (i = vPtr->length - offset, j = 0; 
		 i < vPtr->length; i++, j++) {
	      hold[j] = opnd[i];
	    }
	    for (i = vPtr->length - offset - 1, 
		   j = vPtr->length - 1; i >= 0; i--, j--) {
	      opnd[j] = opnd[i];
	    }
	    for (i = 0; i < offset; i++) {
	      opnd[i] = hold[i];
	    }
	    free(hold);
	  }
	}
	break;

      default:
	Tcl_AppendResult(interp, "unknown operator in expression",
			 (char *)NULL);
	goto error;
      }

    } else if (vPtr->length == 1) {
      double *opnd;
      double scalar;

      /*
       * 1st operand is a scalar.
       */
      scalar = vPtr->valueArr[0];
      Vec_Duplicate(vPtr, v2Ptr);
      opnd = vPtr->valueArr;
      switch (oper) {
      case MULT:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] *= scalar;
	}
	break;

      case PLUS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] += scalar;
	}
	break;

      case DIVIDE:
	for(i = 0; i < vPtr->length; i++) {
	  if (opnd[i] == 0.0) {
	    Tcl_AppendResult(interp, "divide by zero",
			     (char *)NULL);
	    goto error;
	  }
	  opnd[i] = (scalar / opnd[i]);
	}
	break;

      case MINUS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = scalar - opnd[i];
	}
	break;

      case EXPONENT:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = pow(scalar, opnd[i]);
	}
	break;

      case MOD:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = Fmod(scalar, opnd[i]);
	}
	break;

      case LESS:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(scalar < opnd[i]);
	}
	break;

      case GREATER:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(scalar > opnd[i]);
	}
	break;

      case LEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(scalar >= opnd[i]);
	}
	break;

      case GEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(scalar <= opnd[i]);
	}
	break;

      case EQUAL:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] == scalar);
	}
	break;

      case NEQ:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] != scalar);
	}
	break;

      case AND:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] && scalar);
	}
	break;

      case OR:
	for(i = 0; i < vPtr->length; i++) {
	  opnd[i] = (double)(opnd[i] || scalar);
	}
	break;

      case LEFT_SHIFT:
      case RIGHT_SHIFT:
	Tcl_AppendResult(interp, "second shift operand must be scalar",
			 (char *)NULL);
	goto error;

      default:
	Tcl_AppendResult(interp, "unknown operator in expression",
			 (char *)NULL);
	goto error;
      }
    } else {
      double *opnd1, *opnd2;
      /*
       * Carry out the function of the specified operator.
       */
      if (vPtr->length != v2Ptr->length) {
	Tcl_AppendResult(interp, "vectors are different lengths",
			 (char *)NULL);
	goto error;
      }
      opnd1 = vPtr->valueArr, opnd2 = v2Ptr->valueArr;
      switch (oper) {
      case MULT:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] *= opnd2[i];
	}
	break;

      case DIVIDE:
	for (i = 0; i < vPtr->length; i++) {
	  if (opnd2[i] == 0.0) {
	    Tcl_AppendResult(interp,
			     "can't divide by 0.0 vector component",
			     (char *)NULL);
	    goto error;
	  }
	  opnd1[i] /= opnd2[i];
	}
	break;

      case PLUS:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] += opnd2[i];
	}
	break;

      case MINUS:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] -= opnd2[i];
	}
	break;

      case MOD:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = Fmod(opnd1[i], opnd2[i]);
	}
	break;

      case EXPONENT:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = pow(opnd1[i], opnd2[i]);
	}
	break;

      case LESS:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] < opnd2[i]);
	}
	break;

      case GREATER:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] > opnd2[i]);
	}
	break;

      case LEQ:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] <= opnd2[i]);
	}
	break;

      case GEQ:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] >= opnd2[i]);
	}
	break;

      case EQUAL:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] == opnd2[i]);
	}
	break;

      case NEQ:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] != opnd2[i]);
	}
	break;

      case AND:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] && opnd2[i]);
	}
	break;

      case OR:
	for (i = 0; i < vPtr->length; i++) {
	  opnd1[i] = (double)(opnd1[i] || opnd2[i]);
	}
	break;

      case LEFT_SHIFT:
      case RIGHT_SHIFT:
	Tcl_AppendResult(interp, "second shift operand must be scalar",
			 (char *)NULL);
	goto error;

      default:
	Tcl_AppendResult(interp, "unknown operator in expression",
			 (char *)NULL);
	goto error;
      }
    }
  }
 done:
  if (value2.pv.buffer != value2.staticSpace) {
    free(value2.pv.buffer);
  }
  Vec_Free(v2Ptr);
  return result;

 error:
  if (value2.pv.buffer != value2.staticSpace) {
    free(value2.pv.buffer);
  }
  Vec_Free(v2Ptr);
  return TCL_ERROR;
}

static int EvaluateExpression(Tcl_Interp* interp, char *string,
			      Value *valuePtr)
{
  ParseInfo info;
  int result;
  Vector *vPtr;
  double *vp, *vend;

  info.expr = info.nextPtr = string;
  valuePtr->pv.buffer = valuePtr->pv.next = valuePtr->staticSpace;
  valuePtr->pv.end = valuePtr->pv.buffer + STATIC_STRING_SPACE - 1;
  valuePtr->pv.expandProc = ExpandParseValue;
  valuePtr->pv.clientData = NULL;

  result = NextValue(interp, &info, -1, valuePtr);
  if (result != TCL_OK) {
    return result;
  }
  if (info.token != END) {
    Tcl_AppendResult(interp, ": syntax error in expression \"",
		     string, "\"", (char *)NULL);
    return TCL_ERROR;
  }
  vPtr = valuePtr->vPtr;

  /* Check for NaN's and overflows. */
  for (vp = vPtr->valueArr, vend = vp + vPtr->length; vp < vend; vp++) {
    if (!isfinite(*vp)) {
      /*
       * IEEE floating-point error.
       */
      MathError(interp, *vp);
      return TCL_ERROR;
    }
  }
  return TCL_OK;
}

static int ComponentFunc(ClientData clientData, Tcl_Interp* interp,
			 Vector *vPtr)
{
  ComponentProc *procPtr = (ComponentProc *) clientData;
  double *vp, *vend;

  errno = 0;
  for(vp = vPtr->valueArr + vPtr->first, 
	vend = vPtr->valueArr + vPtr->last; vp <= vend; vp++) {
    *vp = (*procPtr) (*vp);
    if (errno != 0) {
      MathError(interp, *vp);
      return TCL_ERROR;
    }
    if (!isfinite(*vp)) {
      /*
       * IEEE floating-point error.
       */
      MathError(interp, *vp);
      return TCL_ERROR;
    }
  }
  return TCL_OK;
}

static int ScalarFunc(ClientData clientData, Tcl_Interp* interp, Vector *vPtr)
{
  double value;
  ScalarProc *procPtr = (ScalarProc *) clientData;

  errno = 0;
  value = (*procPtr) (vPtr);
  if (errno != 0) {
    MathError(interp, value);
    return TCL_ERROR;
  }
  if (Vec_ChangeLength(interp, vPtr, 1) != TCL_OK) {
    return TCL_ERROR;
  }
  vPtr->valueArr[0] = value;
  return TCL_OK;
}

static int VectorFunc(ClientData clientData, Tcl_Interp* interp, Vector *vPtr)
{
  VectorProc *procPtr = (VectorProc *) clientData;

  return (*procPtr) (vPtr);
}


static MathFunction mathFunctions[] =
  {
    {"abs",     (void*)ComponentFunc, (ClientData)Fabs},
    {"acos",	(void*)ComponentFunc, (ClientData)(double (*)(double))acos},
    {"asin",	(void*)ComponentFunc, (ClientData)(double (*)(double))asin},
    {"atan",	(void*)ComponentFunc, (ClientData)(double (*)(double))atan},
    {"adev",	(void*)ScalarFunc,    (ClientData)AvgDeviation},
    {"ceil",	(void*)ComponentFunc, (ClientData)(double (*)(double))ceil},
    {"cos",	(void*)ComponentFunc, (ClientData)(double (*)(double))cos},
    {"cosh",	(void*)ComponentFunc, (ClientData)(double (*)(double))cosh},
    {"exp",	(void*)ComponentFunc, (ClientData)(double (*)(double))exp},
    {"floor",	(void*)ComponentFunc, (ClientData)(double (*)(double))floor},
    {"kurtosis",(void*)ScalarFunc,    (ClientData)Kurtosis},
    {"length",	(void*)ScalarFunc,    (ClientData)Length},
    {"log",	(void*)ComponentFunc, (ClientData)(double (*)(double))log},
    {"log10",	(void*)ComponentFunc, (ClientData)(double (*)(double))log10},
    {"max",	(void*)ScalarFunc,    (ClientData)Blt_VecMax},
    {"mean",	(void*)ScalarFunc,    (ClientData)Mean},
    {"median",	(void*)ScalarFunc,    (ClientData)Median},
    {"min",	(void*)ScalarFunc,    (ClientData)Blt_VecMin},
    {"norm",	(void*)VectorFunc,    (ClientData)Norm},
    {"nz",	(void*)ScalarFunc,    (ClientData)Nonzeros},
    {"q1",	(void*)ScalarFunc,    (ClientData)Q1},
    {"q3",	(void*)ScalarFunc,    (ClientData)Q3},
    {"prod",	(void*)ScalarFunc,    (ClientData)Product},
    {"random",	(void*)ComponentFunc, (ClientData)drand48},
    {"round",	(void*)ComponentFunc, (ClientData)Round},
    {"sdev",	(void*)ScalarFunc,    (ClientData)StdDeviation},
    {"sin",	(void*)ComponentFunc, (ClientData)(double (*)(double))sin},
    {"sinh",	(void*)ComponentFunc, (ClientData)(double (*)(double))sinh},
    {"skew",	(void*)ScalarFunc,    (ClientData)Skew},
    {"sort",	(void*)VectorFunc,    (ClientData)Sort},
    {"sqrt",	(void*)ComponentFunc, (ClientData)(double (*)(double))sqrt},
    {"sum",	(void*)ScalarFunc,    (ClientData)Sum},
    {"tan",	(void*)ComponentFunc, (ClientData)(double (*)(double))tan},
    {"tanh",	(void*)ComponentFunc, (ClientData)(double (*)(double))tanh},
    {"var",	(void*)ScalarFunc,    (ClientData)Variance},
    {(char *)NULL,},
  };

void Blt::Vec_InstallMathFunctions(Tcl_HashTable *tablePtr)
{
  MathFunction *mathPtr;

  for (mathPtr = mathFunctions; mathPtr->name != NULL; mathPtr++) {
    Tcl_HashEntry *hPtr;
    int isNew;

    hPtr = Tcl_CreateHashEntry(tablePtr, mathPtr->name, &isNew);
    Tcl_SetHashValue(hPtr, (ClientData)mathPtr);
  }
}

void Blt::Vec_UninstallMathFunctions(Tcl_HashTable *tablePtr)
{
  Tcl_HashEntry *hPtr;
  Tcl_HashSearch cursor;

  for (hPtr = Tcl_FirstHashEntry(tablePtr, &cursor); hPtr != NULL; 
       hPtr = Tcl_NextHashEntry(&cursor)) {
    MathFunction *mathPtr = (MathFunction*)Tcl_GetHashValue(hPtr);
    if (mathPtr->name == NULL)
      free(mathPtr);
  }
}

static void InstallIndexProc(Tcl_HashTable *tablePtr, const char *string,
			     Blt_VectorIndexProc *procPtr)
{
  Tcl_HashEntry *hPtr;
  int dummy;

  hPtr = Tcl_CreateHashEntry(tablePtr, string, &dummy);
  if (procPtr == NULL)
    Tcl_DeleteHashEntry(hPtr);
  else
    Tcl_SetHashValue(hPtr, (ClientData)procPtr);
}

void Blt::Vec_InstallSpecialIndices(Tcl_HashTable *tablePtr)
{
  InstallIndexProc(tablePtr, "min",  Blt_VecMin);
  InstallIndexProc(tablePtr, "max",  Blt_VecMax);
  InstallIndexProc(tablePtr, "mean", Mean);
  InstallIndexProc(tablePtr, "sum",  Sum);
  InstallIndexProc(tablePtr, "prod", Product);
}

int Blt::ExprVector(Tcl_Interp* interp, char *string, Blt_Vector *vector)
{
  VectorInterpData *dataPtr;	/* Interpreter-specific data. */
  Vector *vPtr = (Vector *)vector;
  Value value;

  dataPtr = (vector != NULL) ? vPtr->dataPtr : Vec_GetInterpData(interp);
  value.vPtr = Vec_New(dataPtr);
  if (EvaluateExpression(interp, string, &value) != TCL_OK) {
    Vec_Free(value.vPtr);
    return TCL_ERROR;
  }
  if (vPtr != NULL) {
    Vec_Duplicate(vPtr, value.vPtr);
  } else {
    Tcl_Obj *listObjPtr;
    double *vp, *vend;

    /* No result vector.  Put values in interp->result.  */
    listObjPtr = Tcl_NewListObj(0, (Tcl_Obj **) NULL);
    for (vp = value.vPtr->valueArr, vend = vp + value.vPtr->length; 
	 vp < vend; vp++) {
      Tcl_ListObjAppendElement(interp, listObjPtr, Tcl_NewDoubleObj(*vp));
    }
    Tcl_SetObjResult(interp, listObjPtr);
  }
  Vec_Free(value.vPtr);
  return TCL_OK;
}

#ifdef _WIN32
double drand48(void)
{
  return (double)rand() / (double)RAND_MAX;
}

void srand48(long int seed)
{
  srand(seed);
}
#endif
