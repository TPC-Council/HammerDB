#
# Tcl package index file
#
package ifneeded tkblt 3.2 \
    [list load [file join $dir libtkblt3.2.so] tkblt]\n[list source [file join $dir graph.tcl]]
