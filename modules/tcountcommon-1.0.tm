package provide tcountcommon 1.0
namespace eval tcountcommon {
namespace export downshift zeroes isdiff
proc downshift { list } {
set temp "null"
set n [ expr [llength $list] - 1 ]
while {$n > 0} {
set temp1 [lindex $list $n]
set list [ lreplace $list $n $n $temp ]
set temp $temp1
incr n -2
        }
set list [ lreplace $list  [ expr [llength $list] - 2 ] end ]
return $list
}

proc zeroes { list } {
set total 0
set n [ expr [llength $list] - 1 ]
while {$n > 0} {
set interim [lindex $list $n]
set total [ expr $total + $interim ]
incr n -2
}
if { $total eq 0 } {
        return 0
} else {
        return 1
                }
        }

proc isdiff { list } {
set diff 0
set n [ expr [llength $list] - 1 ]
set firstval [lindex $list $n]
while {$n > 0} {
set interim [lindex $list $n]
if { $interim != $firstval } { set diff 1 }
incr n -2
}
if { $diff eq 0 } {
        return 0
} else {
        return 1
                }
        }
}
