if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded Expect 5.45.4 \
    [list load [file join $dir libexpect5.45.4.so]]
