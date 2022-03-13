/*
 * Smithsonian Astrophysical Observatory, Cambridge, MA, USA
 * This code has been modified under the terms listed below and is made
 * available under the same terms.
 */

/*
 *	Copyright 2009 George A Howlett.
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

#include <float.h>
#include <stdlib.h>
#include <string.h>

#include <cmath>

#include "tkbltGrElemLine.h"

using namespace Blt;

typedef double TriDiagonalMatrix[3];
typedef struct {
  double b, c, d;
} Cubic2D;

typedef struct {
  double b, c, d, e, f;
} Quint2D;

// Quadratic spline parameters
#define E1	param[0]
#define E2	param[1]
#define V1	param[2]
#define V2	param[3]
#define W1	param[4]
#define W2	param[5]
#define Z1	param[6]
#define Z2	param[7]
#define Y1	param[8]
#define Y2	param[9]

/*
 *---------------------------------------------------------------------------
 *
 * Search --
 *
 *	Conducts a binary search for a value.  This routine is called
 *	only if key is between x(0) and x(len - 1).
 *
 * Results:
 *	Returns the index of the largest value in xtab for which
 *	x[i] < key.
 *
 *---------------------------------------------------------------------------
 */
static int Search(Point2d points[], int nPoints, double key, int *foundPtr)
{
  int low = 0;
  int high = nPoints - 1;

  while (high >= low) {
    int mid = (high + low) / 2;
    if (key > points[mid].x)
      low = mid + 1;
    else if (key < points[mid].x)
      high = mid - 1;
    else {
      *foundPtr = 1;
      return mid;
    }
  }
  *foundPtr = 0;
  return low;
}

/*
 *---------------------------------------------------------------------------
 *
 * QuadChoose --
 *
 *	Determines the case needed for the computation of the parame-
 *	ters of the quadratic spline.
 *
 * Results:
 * 	Returns a case number (1-4) which controls how the parameters
 * 	of the quadratic spline are evaluated.
 *
 *---------------------------------------------------------------------------
 */
static int QuadChoose(Point2d* p, Point2d* q, double m1, double m2, 
		      double epsilon)
{
  // Calculate the slope of the line joining P and Q
  double slope = (q->y - p->y) / (q->x - p->x);

  if (slope != 0.0) {
    double prod1 = slope * m1;
    double prod2 = slope * m2;

    // Find the absolute values of the slopes slope, m1, and m2
    double mref = fabs(slope);
    double mref1 = fabs(m1);
    double mref2 = fabs(m2);

    // If the relative deviation of m1 or m2 from slope is less than
    // epsilon, then choose case 2 or case 3.
    double relerr = epsilon * mref;
    if ((fabs(slope - m1) > relerr) && (fabs(slope - m2) > relerr) &&
	(prod1 >= 0.0) && (prod2 >= 0.0)) {
      double prod = (mref - mref1) * (mref - mref2);
      if (prod < 0.0) {
	// l1, the line through (x1,y1) with slope m1, and l2,
	// the line through (x2,y2) with slope m2, intersect
	// at a point whose abscissa is between x1 and x2.
	// The abscissa becomes a knot of the spline.
	return 1;
      }
      if (mref1 > (mref * 2.0)) {
	if (mref2 <= ((2.0 - epsilon) * mref))
	  return 3;
      }
      else if (mref2 <= (mref * 2.0)) {
	// Both l1 and l2 cross the line through
	// (x1+x2)/2.0,y1 and (x1+x2)/2.0,y2, which is the
	// midline of the rectangle formed by P and Q or both
	// m1 and m2 have signs different than the sign of
	// slope, or one of m1 and m2 has opposite sign from
	// slope and l1 and l2 intersect to the left of x1 or
	// to the right of x2.  The point (x1+x2)/2. is a knot
	// of the spline.
	return 2;
      }
      else if (mref1 <= ((2.0 - epsilon) * mref)) {
	// In cases 3 and 4, sign(m1)=sign(m2)=sign(slope).
	// Either l1 or l2 crosses the midline, but not both.
	// Choose case 4 if mref1 is greater than
	// (2.-epsilon)*mref; otherwise, choose case 3.
	return 3;
      }
      // If neither l1 nor l2 crosses the midline, the spline
      // requires two knots between x1 and x2.
      return 4;
    }
    else {
      // The sign of at least one of the slopes m1 or m2 does not
      // agree with the sign of *slope*.
      if ((prod1 < 0.0) && (prod2 < 0.0)) {
	return 2;
      }
      else if (prod1 < 0.0) {
	if (mref2 > ((epsilon + 1.0) * mref))
	  return 1;
	else
	  return 2;
      }
      else if (mref1 > ((epsilon + 1.0) * mref))
	return 1;
      else
	return 2;
    }
  }
  else if ((m1 * m2) >= 0.0)
    return 2;
  else
    return 1;
}

/*
 *---------------------------------------------------------------------------
 *	Computes the knots and other parameters of the spline on the
 *	interval PQ.
 * On input--
 *	P and Q are the coordinates of the points of interpolation.
 *	m1 is the slope at P.
 *	m2 is the slope at Q.
 *	ncase controls the number and location of the knots.
 * On output--
 *
 *	(v1,v2),(w1,w2),(z1,z2), and (e1,e2) are the coordinates of
 *	the knots and other parameters of the spline on P.
 *	(e1,e2) and Q are used only if ncase=4.
 *---------------------------------------------------------------------------
 */
static void QuadCases(Point2d* p, Point2d* q, double m1, double m2, 
		      double param[], int which)
{
  if ((which == 3) || (which == 4)) {
    double c1 = p->x + (q->y - p->y) / m1;
    double d1 = q->x + (p->y - q->y) / m2;
    double h1 = c1 * 2.0 - p->x;
    double j1 = d1 * 2.0 - q->x;
    double mbar1 = (q->y - p->y) / (h1 - p->x);
    double mbar2 = (p->y - q->y) / (j1 - q->x);

    if (which == 4) {
      // Case 4
      Y1 = (p->x + c1) / 2.0;
      V1 = (p->x + Y1) / 2.0;
      V2 = m1 * (V1 - p->x) + p->y;
      Z1 = (d1 + q->x) / 2.0;
      W1 = (q->x + Z1) / 2.0;
      W2 = m2 * (W1 - q->x) + q->y;
      double mbar3 = (W2 - V2) / (W1 - V1);
      Y2 = mbar3 * (Y1 - V1) + V2;
      Z2 = mbar3 * (Z1 - V1) + V2;
      E1 = (Y1 + Z1) / 2.0;
      E2 = mbar3 * (E1 - V1) + V2;
    }
    else {
      // Case 3
      double k1 = (p->y - q->y + q->x * mbar2 - p->x * mbar1) / (mbar2 - mbar1);
      if (fabs(m1) > fabs(m2)) {
	Z1 = (k1 + p->x) / 2.0;
      } else {
	Z1 = (k1 + q->x) / 2.0;
      }
      V1 = (p->x + Z1) / 2.0;
      V2 = p->y + m1 * (V1 - p->x);
      W1 = (q->x + Z1) / 2.0;
      W2 = q->y + m2 * (W1 - q->x);
      Z2 = V2 + (W2 - V2) / (W1 - V1) * (Z1 - V1);
    }
  }
  else if (which == 2) {
    // Case 2
    Z1 = (p->x + q->x) / 2.0;
    V1 = (p->x + Z1) / 2.0;
    V2 = p->y + m1 * (V1 - p->x);
    W1 = (Z1 + q->x) / 2.0;
    W2 = q->y + m2 * (W1 - q->x);
    Z2 = (V2 + W2) / 2.0;
  }
  else {
    // Case 1
    Z1 = (p->y - q->y + m2 * q->x - m1 * p->x) / (m2 - m1);
    double ztwo = p->y + m1 * (Z1 - p->x);
    V1 = (p->x + Z1) / 2.0;
    V2 = (p->y + ztwo) / 2.0;
    W1 = (Z1 + q->x) / 2.0;
    W2 = (ztwo + q->y) / 2.0;
    Z2 = V2 + (W2 - V2) / (W1 - V1) * (Z1 - V1);
  }
}

static int QuadSelect(Point2d* p, Point2d* q, double m1, double m2, 
		      double epsilon, double param[])
{
  int ncase = QuadChoose(p, q, m1, m2, epsilon);
  QuadCases(p, q, m1, m2, param, ncase);
  return ncase;
}

static double QuadGetImage(double p1, double p2, double p3, double x1, 
			   double x2, double x3)
{
  double A = x1 - x2;
  double B = x2 - x3;
  double C = x1 - x3;

  double y = (p1 * (A * A) + p2 * 2.0 * B * A + p3 * (B * B)) / (C * C);
  return y;
}

/*
 *---------------------------------------------------------------------------
 *	Finds the image of a point in x.
 *	On input
 *	x	Contains the value at which the spline is evaluated.
 *	leftX, leftY
 *		Coordinates of the left-hand data point used in the
 *		evaluation of x values.
 *	rightX, rightY
 *		Coordinates of the right-hand data point used in the
 *		evaluation of x values.
 *	Z1, Z2, Y1, Y2, E2, W2, V2
 *		Parameters of the spline.
 *	ncase	Controls the evaluation of the spline by indicating
 *		whether one or two knots were placed in the interval
 *		(xtabs,xtabs1).
 *---------------------------------------------------------------------------
 */
static void QuadSpline(Point2d* intp, Point2d* left, Point2d* right,
		       double param[], int ncase)

{
  double y;

  if (ncase == 4) {
    // Case 4:  More than one knot was placed in the interval.
    // Determine the location of data point relative to the 1st knot.
    if (Y1 > intp->x)
      y = QuadGetImage(left->y, V2, Y2, Y1, intp->x, left->x);
    else if (Y1 < intp->x) {
      // Determine the location of the data point relative to the 2nd knot.
      if (Z1 > intp->x)
	y = QuadGetImage(Y2, E2, Z2, Z1, intp->x, Y1);
      else if (Z1 < intp->x)
	y = QuadGetImage(Z2, W2, right->y, right->x, intp->x, Z1);
      else
	y = Z2;
    }
    else
      y = Y2;
  }
  else {
    // Cases 1, 2, or 3:
    // Determine the location of the data point relative to the knot.
    if (Z1 < intp->x)
      y = QuadGetImage(Z2, W2, right->y, right->x, intp->x, Z1);
    else if (Z1 > intp->x)
      y = QuadGetImage(left->y, V2, Z2, Z1, intp->x, left->x);
    else
      y = Z2;
  }

  intp->y = y;
}

/*
 *---------------------------------------------------------------------------
 * 	Calculates the derivative at each of the data points.  The
 * 	slopes computed will insure that an osculatory quadratic
 * 	spline will have one additional knot between two adjacent
 * 	points of interpolation.  Convexity and monotonicity are
 * 	preserved wherever these conditions are compatible with the
 * 	data.
 *---------------------------------------------------------------------------
 */
static void QuadSlopes(Point2d *points, double *m, int nPoints)
{
  double m1s =0;
  double m2s =0;
  double m1 =0;
  double m2 =0;
  int i, n, l;
  for (l = 0, i = 1, n = 2; i < (nPoints - 1); l++, i++, n++) {
    // Calculate the slopes of the two lines joining three
    // consecutive data points.
    double ydif1 = points[i].y - points[l].y;
    double ydif2 = points[n].y - points[i].y;
    m1 = ydif1 / (points[i].x - points[l].x);
    m2 = ydif2 / (points[n].x - points[i].x);
    if (i == 1) {
      // Save slopes of starting point
      m1s = m1;
      m2s = m2;
    }
    // If one of the preceding slopes is zero or if they have opposite
    // sign, assign the value zero to the derivative at the middle point.
    if ((m1 == 0.0) || (m2 == 0.0) || ((m1 * m2) <= 0.0))
      m[i] = 0.0;
    else if (fabs(m1) > fabs(m2)) {
      // Calculate the slope by extending the line with slope m1.
      double xbar = ydif2 / m1 + points[i].x;
      double xhat = (xbar + points[n].x) / 2.0;
      m[i] = ydif2 / (xhat - points[i].x);
    }
    else {
      // Calculate the slope by extending the line with slope m2.
      double xbar = -ydif1 / m2 + points[i].x;
      double xhat = (points[l].x + xbar) / 2.0;
      m[i] = ydif1 / (points[i].x - xhat);
    }
  }

  // Calculate the slope at the last point, x(n).
  i = nPoints - 2;
  n = nPoints - 1;
  if ((m1 * m2) < 0.0)
    m[n] = m2 * 2.0;
  else {
    double xmid = (points[i].x + points[n].x) / 2.0;
    double yxmid = m[i] * (xmid - points[i].x) + points[i].y;
    m[n] = (points[n].y - yxmid) / (points[n].x - xmid);
    if ((m[n] * m2) < 0.0)
      m[n] = 0.0;
  }

  // Calculate the slope at the first point, x(0).
  if ((m1s * m2s) < 0.0)
    m[0] = m1s * 2.0;
  else {
    double xmid = (points[0].x + points[1].x) / 2.0;
    double yxmid = m[1] * (xmid - points[1].x) + points[1].y;
    m[0] = (yxmid - points[0].y) / (xmid - points[0].x);
    if ((m[0] * m1s) < 0.0)
      m[0] = 0.0;
  }
}

/*
 *---------------------------------------------------------------------------
 *
 * QuadEval --
 *
 * 	QuadEval controls the evaluation of an osculatory quadratic
 * 	spline.  The user may provide his own slopes at the points of
 * 	interpolation or use the subroutine 'QuadSlopes' to calculate
 * 	slopes which are consistent with the shape of the data.
 *
 * ON INPUT--
 *   	intpPts	must be a nondecreasing vector of points at which the
 *		spline will be evaluated.
 *   	origPts	contains the abscissas of the data points to be
 *		interpolated. xtab must be increasing.
 *   	y	contains the ordinates of the data points to be
 *		interpolated.
 *   	m 	contains the slope of the spline at each point of
 *		interpolation.
 *   	nPoints	number of data points (dimension of xtab and y).
 *   	numEval is the number of points of evaluation (dimension of
 *		xval and yval).
 *   	epsilon 	is a relative error tolerance used in subroutine
 *		'QuadChoose' to distinguish the situation m(i) or
 *		m(i+1) is relatively close to the slope or twice
 *		the slope of the linear segment between xtab(i) and
 *		xtab(i+1).  If this situation occurs, roundoff may
 *		cause a change in convexity or monotonicity of the
 *   		resulting spline and a change in the case number
 *		provided by 'QuadChoose'.  If epsilon is not equal to zero,
 *		then epsilon should be greater than or equal to machine
 *		epsilon.
 * ON OUTPUT--
 * 	yval 	contains the images of the points in xval.
 *   	err 	is one of the following error codes:
 *      	0 - QuadEval ran normally.
 *      	1 - xval(i) is less than xtab(1) for at least one
 *		    i or xval(i) is greater than xtab(num) for at
 *		    least one i. QuadEval will extrapolate to provide
 *		    function values for these abscissas.
 *      	2 - xval(i+1) < xval(i) for some i.
 *
 *
 *  QuadEval calls the following subroutines or functions:
 *      Search
 *      QuadCases
 *      QuadChoose
 *      QuadSpline
 *---------------------------------------------------------------------------
 */
static int QuadEval(Point2d origPts[], int nOrigPts, Point2d intpPts[],
		    int nIntpPts, double *m, double epsilon)
{
  double param[10];

  // Initialize indices and set error result
  int error = 0;
  int l = nOrigPts - 1;
  int p = l - 1;
  int ncase = 1;

  // Determine if abscissas of new vector are non-decreasing.
  for (int jj=1; jj<nIntpPts; jj++) {
    if (intpPts[jj].x < intpPts[jj - 1].x)
      return 2;
  }
  // Determine if any of the points in xval are LESS than the
  // abscissa of the first data point.
  int start;
  for (start = 0; start < nIntpPts; start++) {
    if (intpPts[start].x >= origPts[0].x)
      break;
  }
  // Determine if any of the points in xval are GREATER than the
  // abscissa of the l data point.
  int end;
  for (end = nIntpPts - 1; end >= 0; end--) {
    if (intpPts[end].x <= origPts[l].x)
      break;
  }

  if (start > 0) {
    // Set error value to indicate that extrapolation has occurred
    error = 1;

    // Calculate the images of points of evaluation whose abscissas
    // are less than the abscissa of the first data point.
    ncase = QuadSelect(origPts, origPts + 1, m[0], m[1], epsilon, param);
    for (int jj=0; jj<(start - 1); jj++)
      QuadSpline(intpPts + jj, origPts, origPts + 1, param, ncase);
    if (nIntpPts == 1)
      return error;
  }
  int ii;
  int nn;
  if ((nIntpPts == 1) && (end != (nIntpPts - 1)))
    goto noExtrapolation;
    
  // Search locates the interval in which the first in-range
  // point of evaluation lies.
  int found;
  ii = Search(origPts, nOrigPts, intpPts[start].x, &found);
    
  nn = ii + 1;
  if (nn >= nOrigPts) {
    nn = nOrigPts - 1;
    ii = nOrigPts - 2;
  }
  /*
   * If the first in-range point of evaluation is equal to one
   * of the data points, assign the appropriate value from y.
   * Continue until a point of evaluation is found which is not
   * equal to a data point.
   */
  if (found) {
    do {
      intpPts[start].y = origPts[ii].y;
      start++;
      if (start >= nIntpPts) {
	return error;
      }
    } while (intpPts[start - 1].x == intpPts[start].x);
	
    for (;;) {
      if (intpPts[start].x < origPts[nn].x) {
	break;	/* Break out of for-loop */
      }
      if (intpPts[start].x == origPts[nn].x) {
	do {
	  intpPts[start].y = origPts[nn].y;
	  start++;
	  if (start >= nIntpPts) {
	    return error;
	  }
	} while (intpPts[start].x == intpPts[start - 1].x);
      }
      ii++;
      nn++;
    }
  }
  /*
   * Calculate the images of all the points which lie within
   * range of the data.
   */
  if ((ii > 0) || (error != 1))
    ncase = QuadSelect(origPts+ii, origPts+nn, m[ii], m[nn], epsilon, param);

  for (int jj=start; jj<=end; jj++) {
    // If xx(j) - x(n) is negative, do not recalculate
    // the parameters for this section of the spline since
    // they are already known.
    if (intpPts[jj].x == origPts[nn].x) {
      intpPts[jj].y = origPts[nn].y;
      continue;
    }
    else if (intpPts[jj].x > origPts[nn].x) {
      double delta;
	    
      // Determine that the routine is in the correct part of the spline
      do {
	ii++;
	nn++;
	delta = intpPts[jj].x - origPts[nn].x;
      } while (delta > 0.0);
	    
      if (delta < 0.0)
	ncase = QuadSelect(origPts+ii, origPts+nn, m[ii], m[nn], 
			   epsilon, param);
      else if (delta == 0.0) {
	intpPts[jj].y = origPts[nn].y;
	continue;
      }
    }
    QuadSpline(intpPts+jj, origPts+ii, origPts+nn, param, ncase);
  }
    
  if (end == (nIntpPts - 1))
    return error;

  if ((nn == l) && (intpPts[end].x != origPts[l].x))
    goto noExtrapolation;

  // Set error value to indicate that extrapolation has occurred
  error = 1;
  ncase = QuadSelect(origPts + p, origPts + l, m[p], m[l], epsilon, param);

 noExtrapolation:
  // Calculate the images of the points of evaluation whose
  // abscissas are greater than the abscissa of the last data point.
  for (int jj=(end + 1); jj<nIntpPts; jj++)
    QuadSpline(intpPts + jj, origPts + p, origPts + l, param, ncase);

  return error;
}

/*
 *---------------------------------------------------------------------------
 *
 *		  Shape preserving quadratic splines
 *		   by D.F.Mcallister & J.A.Roulier
 *		    Coded by S.L.Dodd & M.Roulier
 *			 N.C.State University
 *
 *---------------------------------------------------------------------------
 */
/*
 * Driver routine for quadratic spline package
 * On input--
 *   X,Y    Contain n-long arrays of data (x is increasing)
 *   XM     Contains m-long array of x values (increasing)
 *   eps    Relative error tolerance
 *   n      Number of input data points
 *   m      Number of output data points
 * On output--
 *   work   Contains the value of the first derivative at each data point
 *   ym     Contains the interpolated spline value at each data point
 */
int LineElement::quadraticSpline(Point2d *origPts, int nOrigPts, 
				 Point2d *intpPts, int nIntpPts)
{
  double* work = new double[nOrigPts];
  double epsilon = 0.0;
  /* allocate space for vectors used in calculation */
  QuadSlopes(origPts, work, nOrigPts);
  int result = QuadEval(origPts, nOrigPts, intpPts, nIntpPts, work, epsilon);
  delete [] work;
  if (result > 1) {
    return 0;
  }
  return 1;
}

/*
 *---------------------------------------------------------------------------
 * Reference:
 *	Numerical Analysis, R. Burden, J. Faires and A. Reynolds.
 *	Prindle, Weber & Schmidt 1981 pp 112
 *---------------------------------------------------------------------------
 */
int LineElement::naturalSpline(Point2d *origPts, int nOrigPts, 
			       Point2d *intpPts, int nIntpPts)
{
  Point2d *ip, *iend;
  double x, dy, alpha;
  int isKnot;
  int i, j, n;

  double* dx = new double[nOrigPts];
  /* Calculate vector of differences */
  for (i = 0, j = 1; j < nOrigPts; i++, j++) {
    dx[i] = origPts[j].x - origPts[i].x;
    if (dx[i] < 0.0) {
      return 0;
    }
  }
  n = nOrigPts - 1;		/* Number of intervals. */
  TriDiagonalMatrix* A = new TriDiagonalMatrix[nOrigPts];
  if (!A) {
    delete [] dx;
    return 0;
  }
  /* Vectors to solve the tridiagonal matrix */
  A[0][0] = A[n][0] = 1.0;
  A[0][1] = A[n][1] = 0.0;
  A[0][2] = A[n][2] = 0.0;

  /* Calculate the intermediate results */
  for (i = 0, j = 1; j < n; j++, i++) {
    alpha = 3.0 * ((origPts[j + 1].y / dx[j]) - (origPts[j].y / dx[i]) - 
		   (origPts[j].y / dx[j]) + (origPts[i].y / dx[i]));
    A[j][0] = 2 * (dx[j] + dx[i]) - dx[i] * A[i][1];
    A[j][1] = dx[j] / A[j][0];
    A[j][2] = (alpha - dx[i] * A[i][2]) / A[j][0];
  }

  Cubic2D* eq = new Cubic2D[nOrigPts];
  if (!eq) {
    delete [] A;
    delete [] dx;
    return 0;
  }
  eq[0].c = eq[n].c = 0.0;
  for (j = n, i = n - 1; i >= 0; i--, j--) {
    eq[i].c = A[i][2] - A[i][1] * eq[j].c;
    dy = origPts[i+1].y - origPts[i].y;
    eq[i].b = (dy) / dx[i] - dx[i] * (eq[j].c + 2.0 * eq[i].c) / 3.0;
    eq[i].d = (eq[j].c - eq[i].c) / (3.0 * dx[i]);
  }
  delete [] A;
  delete [] dx;

  /* Now calculate the new values */
  for (ip = intpPts, iend = ip + nIntpPts; ip < iend; ip++) {
    ip->y = 0.0;
    x = ip->x;

    /* Is it outside the interval? */
    if ((x < origPts[0].x) || (x > origPts[n].x)) {
      continue;
    }
    /* Search for the interval containing x in the point array */
    i = Search(origPts, nOrigPts, x, &isKnot);
    if (isKnot) {
      ip->y = origPts[i].y;
    } else {
      i--;
      x -= origPts[i].x;
      ip->y = origPts[i].y + x * (eq[i].b + x * (eq[i].c + x * eq[i].d));
    }
  }
  delete [] eq;
  return 1;
}

typedef struct {
  double t;			/* Arc length of interval. */
  double x;			/* 2nd derivative of X with respect to T */
  double y;			/* 2nd derivative of Y with respect to T */
} CubicSpline;

/*
 * The following two procedures solve the special linear system which arise
 * in cubic spline interpolation. If x is assumed cyclic ( x[i]=x[n+i] ) the
 * equations can be written as (i=0,1,...,n-1):
 *     m[i][0] * x[i-1] + m[i][1] * x[i] + m[i][2] * x[i+1] = b[i] .
 * In matrix notation one gets A * x = b, where the matrix A is tridiagonal
 * with additional elements in the upper right and lower left position:
 *   A[i][0] = A_{i,i-1}  for i=1,2,...,n-1    and    m[0][0] = A_{0,n-1} ,
 *   A[i][1] = A_{i, i }  for i=0,1,...,n-1
 *   A[i][2] = A_{i,i+1}  for i=0,1,...,n-2    and    m[n-1][2] = A_{n-1,0}.
 * A should be symmetric (A[i+1][0] == A[i][2]) and positive definite.
 * The size of the system is given in n (n>=1).
 *
 * In the first procedure the Cholesky decomposition A = C^T * D * C
 * (C is upper triangle with unit diagonal, D is diagonal) is calculated.
 * Return TRUE if decomposition exist.
 */
static int SolveCubic1(TriDiagonalMatrix A[], int n)
{
  int i;
  double m_ij, m_n, m_nn, d;

  if (n < 1) {
    return 0;		/* Dimension should be at least 1 */
  }
  d = A[0][1];		/* D_{0,0} = A_{0,0} */
  if (d <= 0.0) {
    return 0;		/* A (or D) should be positive definite */
  }
  m_n = A[0][0];		/*  A_{0,n-1}  */
  m_nn = A[n - 1][1];		/* A_{n-1,n-1} */
  for (i = 0; i < n - 2; i++) {
    m_ij = A[i][2];		/*  A_{i,1}  */
    A[i][2] = m_ij / d;	/* C_{i,i+1} */
    A[i][0] = m_n / d;	/* C_{i,n-1} */
    m_nn -= A[i][0] * m_n;	/* to get C_{n-1,n-1} */
    m_n = -A[i][2] * m_n;	/* to get C_{i+1,n-1} */
    d = A[i + 1][1] - A[i][2] * m_ij;	/* D_{i+1,i+1} */
    if (d <= 0.0) {
      return 0;	/* Elements of D should be positive */
    }
    A[i + 1][1] = d;
  }
  if (n >= 2) {		/* Complete last column */
    m_n += A[n - 2][2];	/* add A_{n-2,n-1} */
    A[n - 2][0] = m_n / d;	/* C_{n-2,n-1} */
    A[n - 1][1] = d = m_nn - A[n - 2][0] * m_n;	/* D_{n-1,n-1} */
    if (d <= 0.0) {
      return 0;
    }
  }
  return 1;
}

/*
 * The second procedure solves the linear system, with the Cholesky
 * decomposition calculated above (in m[][]) and the right side b given
 * in x[]. The solution x overwrites the right side in x[].
 */
static void SolveCubic2(TriDiagonalMatrix A[], CubicSpline spline[], 
			int nIntervals)
{
  int n = nIntervals - 2;
  int m = nIntervals - 1;

  // Division by transpose of C : b = C^{-T} * b 
  double x = spline[m].x;
  double y = spline[m].y;
  for (int ii=0; ii<n; ii++) {
    spline[ii + 1].x -= A[ii][2] * spline[ii].x; /* C_{i,i+1} * x(i) */
    spline[ii + 1].y -= A[ii][2] * spline[ii].y; /* C_{i,i+1} * x(i) */
    x -= A[ii][0] * spline[ii].x;	/* C_{i,n-1} * x(i) */
    y -= A[ii][0] * spline[ii].y; /* C_{i,n-1} * x(i) */
  }
  if (n >= 0) {
    // C_{n-2,n-1} * x_{n-1}
    spline[m].x = x - A[n][0] * spline[n].x; 
    spline[m].y = y - A[n][0] * spline[n].y; 
  }
  // Division by D: b = D^{-1} * b 
  for (int ii=0; ii<nIntervals; ii++) {
    spline[ii].x /= A[ii][1];
    spline[ii].y /= A[ii][1];
  }

  // Division by C: b = C^{-1} * b
  x = spline[m].x;
  y = spline[m].y;
  if (n >= 0) {
    // C_{n-2,n-1} * x_{n-1}
    spline[n].x -= A[n][0] * x;	
    spline[n].y -= A[n][0] * y;	
  }
  for (int ii=(n - 1); ii>=0; ii--) {
    // C_{i,i+1} * x_{i+1} + C_{i,n-1} * x_{n-1}
    spline[ii].x -= A[ii][2] * spline[ii + 1].x + A[ii][0] * x;
    spline[ii].y -= A[ii][2] * spline[ii + 1].y + A[ii][0] * y;
  }
}

/*
 * Find second derivatives (x''(t_i),y''(t_i)) of cubic spline interpolation
 * through list of points (x_i,y_i). The parameter t is calculated as the
 * length of the linear stroke. The number of points must be at least 3.
 * Note: For CLOSED_CONTOURs the first and last point must be equal.
 */
static CubicSpline* CubicSlopes(Point2d points[], int nPoints,
				int isClosed, double unitX, double unitY)
{
  CubicSpline *s1, *s2;
  int n, i;
  double norm, dx, dy;
    
  CubicSpline* spline = new CubicSpline[nPoints];
  if (!spline)
    return NULL;

  TriDiagonalMatrix *A = new TriDiagonalMatrix[nPoints];
  if (!A) {
    delete [] spline;
    return NULL;
  }
  /*
   * Calculate first differences in (dxdt2[i], y[i]) and interval lengths
   * in dist[i]:
   */
  s1 = spline;
  for (i = 0; i < nPoints - 1; i++) {
    s1->x = points[i+1].x - points[i].x;
    s1->y = points[i+1].y - points[i].y;

    /*
     * The Norm of a linear stroke is calculated in "normal coordinates"
     * and used as interval length:
     */
    dx = s1->x / unitX;
    dy = s1->y / unitY;
    s1->t = sqrt(dx * dx + dy * dy);

    s1->x /= s1->t;	/* first difference, with unit norm: */
    s1->y /= s1->t;	/*   || (dxdt2[i], y[i]) || = 1      */
    s1++;
  }

  /*
   * Setup linear System:  Ax = b
   */
  n = nPoints - 2;		/* Without first and last point */
  if (isClosed) {
    /* First and last points must be equal for CLOSED_CONTOURs */
    spline[nPoints - 1].t = spline[0].t;
    spline[nPoints - 1].x = spline[0].x;
    spline[nPoints - 1].y = spline[0].y;
    n++;			/* Add last point (= first point) */
  }
  s1 = spline, s2 = s1 + 1;
  for (i = 0; i < n; i++) {
    /* Matrix A, mainly tridiagonal with cyclic second index 
       ("j = j+n mod n") 
    */
    A[i][0] = s1->t;	/* Off-diagonal element A_{i,i-1} */
    A[i][1] = 2.0 * (s1->t + s2->t);	/* A_{i,i} */
    A[i][2] = s2->t;	/* Off-diagonal element A_{i,i+1} */

    /* Right side b_x and b_y */
    s1->x = (s2->x - s1->x) * 6.0;
    s1->y = (s2->y - s1->y) * 6.0;

    /* 
     * If the linear stroke shows a cusp of more than 90 degree,
     * the right side is reduced to avoid oscillations in the
     * spline: 
     */
    /*
     * The Norm of a linear stroke is calculated in "normal coordinates"
     * and used as interval length:
     */
    dx = s1->x / unitX;
    dy = s1->y / unitY;
    norm = sqrt(dx * dx + dy * dy) / 8.5;
    if (norm > 1.0) {
      /* The first derivative will not be continuous */
      s1->x /= norm;
      s1->y /= norm;
    }
    s1++, s2++;
  }

  if (!isClosed) {
    /* Third derivative is set to zero at both ends */
    A[0][1] += A[0][0];	/* A_{0,0}     */
    A[0][0] = 0.0;		/* A_{0,n-1}   */
    A[n-1][1] += A[n-1][2]; /* A_{n-1,n-1} */
    A[n-1][2] = 0.0;	/* A_{n-1,0}   */
  }
  /* Solve linear systems for dxdt2[] and y[] */

  if (SolveCubic1(A, n)) {	/* Cholesky decomposition */
    SolveCubic2(A, spline, n); /* A * dxdt2 = b_x */
  }
  else {			/* Should not happen, but who knows ... */
    delete [] A;
    delete [] spline;
    return NULL;
  }
  /* Shift all second derivatives one place right and update the ends. */
  s2 = spline + n, s1 = s2 - 1;
  for (/* empty */; s2 > spline; s2--, s1--) {
    s2->x = s1->x;
    s2->y = s1->y;
  }
  if (isClosed) {
    spline[0].x = spline[n].x;
    spline[0].y = spline[n].y;
  } else {
    /* Third derivative is 0.0 for the first and last interval. */
    spline[0].x = spline[1].x; 
    spline[0].y = spline[1].y; 
    spline[n + 1].x = spline[n].x;
    spline[n + 1].y = spline[n].y;
  }
  delete [] A;
  return spline;
}

// Calculate interpolated values of the spline function (defined via p_cntr
// and the second derivatives dxdt2[] and dydt2[]). The number of tabulated
// values is n. On an equidistant grid n_intpol values are calculated.
static int CubicEval(Point2d *origPts, int nOrigPts, Point2d *intpPts, 
		     int nIntpPts, CubicSpline *spline)
{
  double t, tSkip;
  Point2d q;
  int count;

  /* Sum the lengths of all the segments (intervals). */
  double tMax = 0.0;
  for (int ii=0; ii<nOrigPts - 1; ii++)
    tMax += spline[ii].t;

  /* Need a better way of doing this... */

  /* The distance between interpolated points */
  tSkip = (1. - 1e-7) * tMax / (nIntpPts - 1);
    
  t = 0.0;			/* Spline parameter value. */
  q = origPts[0];
  count = 0;

  intpPts[count++] = q;	/* First point. */
  t += tSkip;
    
  for (int ii=0, jj=1; jj<nOrigPts; ii++, jj++) {
    // Interval length
    double d = spline[ii].t;
    Point2d p = q;
    q = origPts[ii+1];
    double hx = (q.x - p.x) / d;
    double hy = (q.y - p.y) / d;
    double dx0 = (spline[jj].x + 2 * spline[ii].x) / 6.0;
    double dy0 = (spline[jj].y + 2 * spline[ii].y) / 6.0;
    double dx01 = (spline[jj].x - spline[ii].x) / (6.0 * d);
    double dy01 = (spline[jj].y - spline[ii].y) / (6.0 * d);
    while (t <= spline[ii].t) { /* t in current interval ? */
      p.x += t * (hx + (t - d) * (dx0 + t * dx01));
      p.y += t * (hy + (t - d) * (dy0 + t * dy01));
      intpPts[count++] = p;
      t += tSkip;
    }

    // Parameter t relative to start of next interval 
    t -= spline[ii].t;
  }

  return count;
}

int LineElement::naturalParametricSpline(Point2d *origPts, int nOrigPts, 
					 Region2d *extsPtr, int isClosed,
					 Point2d *intpPts, int nIntpPts)
{
  // Generate a cubic spline curve through the points (x_i,y_i) which are
  // stored in the linked list p_cntr.
  // The spline is defined as a 2d-function s(t) = (x(t),y(t)), where the
  // parameter t is the length of the linear stroke.

  if (nOrigPts < 3)
    return 0;

  if (isClosed) {
    origPts[nOrigPts].x = origPts[0].x;
    origPts[nOrigPts].y = origPts[0].y;
    nOrigPts++;
  }

  // Width and height of the grid is used at unit length (2d-norm)
  double unitX = extsPtr->right - extsPtr->left;
  double unitY = extsPtr->bottom - extsPtr->top;
  if (unitX < FLT_EPSILON)
    unitX = FLT_EPSILON;
  if (unitY < FLT_EPSILON)
    unitY = FLT_EPSILON;

  /* Calculate parameters for cubic spline: 
   *		t     = arc length of interval.
   *		dxdt2 = second derivatives of x with respect to t, 
   *		dydt2 = second derivatives of y with respect to t, 
   */
  CubicSpline* spline = CubicSlopes(origPts, nOrigPts, isClosed, unitX, unitY);
  if (spline == NULL)
    return 0;

  int result= CubicEval(origPts, nOrigPts, intpPts, nIntpPts, spline);

  delete [] spline;
  return result;
}

static void CatromCoeffs(Point2d* p, Point2d* a, Point2d* b, 
			 Point2d* c, Point2d* d)
{
  a->x = -p[0].x + 3.0 * p[1].x - 3.0 * p[2].x + p[3].x;
  b->x = 2.0 * p[0].x - 5.0 * p[1].x + 4.0 * p[2].x - p[3].x;
  c->x = -p[0].x + p[2].x;
  d->x = 2.0 * p[1].x;
  a->y = -p[0].y + 3.0 * p[1].y - 3.0 * p[2].y + p[3].y;
  b->y = 2.0 * p[0].y - 5.0 * p[1].y + 4.0 * p[2].y - p[3].y;
  c->y = -p[0].y + p[2].y;
  d->y = 2.0 * p[1].y;
}

int LineElement::catromParametricSpline(Point2d* points, int nPoints, 
					Point2d* intpPts, int nIntpPts)
{
  // The spline is computed in screen coordinates instead of data points so
  // that we can select the abscissas of the interpolated points from each
  // pixel horizontally across the plotting area.

  Point2d* origPts = new Point2d[nPoints + 4];
  memcpy(origPts + 1, points, sizeof(Point2d) * nPoints);

  origPts[0] = origPts[1];
  origPts[nPoints + 2] = origPts[nPoints + 1] = origPts[nPoints];

  for (int ii=0; ii<nIntpPts; ii++) {
    int interval = (int)intpPts[ii].x;
    double t = intpPts[ii].y;
    Point2d a, b, c, d;
    CatromCoeffs(origPts + interval, &a, &b, &c, &d);
    intpPts[ii].x = (d.x + t * (c.x + t * (b.x + t * a.x))) / 2.0;
    intpPts[ii].y = (d.y + t * (c.y + t * (b.y + t * a.y))) / 2.0;
  }

  delete [] origPts;
  return 1;
}
