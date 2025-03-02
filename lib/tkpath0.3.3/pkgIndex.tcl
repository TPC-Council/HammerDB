# pkgIndex.tcl.  Generated from pkgIndex.tcl.in by configure.
#
namespace eval ::tkpath {
    proc load_package {dir} {
	load [file join $dir libtkpath0.3.3.so]
	# Allow optional redirect of library components.
	# Only necessary for testing, but could be used elsewhere.
	if {[info exists ::env(TKPATH_LIBRARY)]} {
	    set dir $::env(TKPATH_LIBRARY)
	}
	source $dir/tkpath.tcl
    };# load_package
}

package ifneeded tkpath 0.3.3 [list ::tkpath::load_package $dir]

#*EOF*
