# all.tcl --
#
# This file contains a top-level script to run all of the Tcl
# tests.  Execute it by invoking "source all" when running tclTest
# in this directory.

package require tcltest
# do this in a way that is backward compatible for Tcl 8.3
namespace import ::tcltest::test ::tcltest::cleanupTests
package require Expect

set ::tcltest::testSingleFile false
set ::tcltest::testsDirectory [file dirname [info script]]

foreach file [lsort [::tcltest::getMatchingFiles]] {
    set tail [file tail $file]
    puts stdout $tail
    if {[catch {source $file} msg]} {
	puts stdout $msg
    }
}

::tcltest::cleanupTests 1 
return
