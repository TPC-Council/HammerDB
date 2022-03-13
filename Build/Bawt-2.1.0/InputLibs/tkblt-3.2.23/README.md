[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1041783.svg)](https://doi.org/10.5281/zenodo.1041783)
# tkblt
Introduction to the TkBLT library

TkBLT is a library of extensions to the Tk library. It adds new
commands and variables to the application's interpreter.

TkBLT is a derived version of the BLT Toolkit by George A. Howlett,
for Tcl/Tk 8.5/8.6, is TEA compatible, with full support for MacOSX and
Windows, and is fully compatible with the Tk API. TkBLT is released
under the original BSD license. TkBLT includes only the Graph and
Barchart Tk widgets, and the Tcl Vector command.

The following commands are added to the interpreter from the TkBLT library:

Graph: A 2D plotting widget. Plots two variable data in a window with an optional 
legend and annotations. It has of several components; coordinate axes, 
crosshairs, a legend, and a collection of elements and tags.

Barchart: A barchart widget. Plots two-variable data as rectangular bars in a 
window. The x-coordinate values designate the position of the bar along 
the x-axis, while the y-coordinate values designate the magnitude.
The barchart widget has of several components; coordinate axes, 
crosshairs, a legend, and a collection of elements and tags.

Vector: Creates a vector of floating point values. The vector's components
can be manipulated in three ways: through a Tcl array variable, a Tcl
command, or the C API.
