tksvg
======

This package adds support to read the SVG image format from Tk.
The actual code to parse and raster the SVG comes from nanosvg.

Example usage:

	package require tksvg
	set img [image create photo -file orb.svg]
	pack [label .l -image $img]
 
