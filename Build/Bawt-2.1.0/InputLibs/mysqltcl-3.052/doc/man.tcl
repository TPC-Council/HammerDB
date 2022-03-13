# script for produce html and ngroff from tcl man page
# see doctools from tcllib

package require doctools

::doctools::new dl -file mysqltcl.man -format html
set file [open mysqltcl.html w]
set filein [open mysqltcl.man]
puts $file [dl format [read $filein]]
close $filein
close $file

set file [open man.macros r]
set manmacros [string trim [read $file]]
close $file

::doctools::new dl2 -file mysqltcl.man -format nroff
set file [open mysqltcl.n w]
set filein [open mysqltcl.man]
set data [dl2 format [read $filein]]
set data [string map [list {.so man.macros} $manmacros] $data]
puts $file $data
close $filein
close $file


