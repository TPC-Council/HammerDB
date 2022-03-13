#!/usr/bin/tcl

if {[file exists libload.tcl]} {
    source libload.tcl
} else {
    source [file join [file dirname [info script]] libload.tcl]
}


puts "please observe memory consumption per top (Program break after reach 2000)"

set i 0
while 1 {
    set c$i [mysqlconnect -u root -db uni]
    mysqlsel [set c$i] {select * from Student}
    while {[set row [mysqlnext [set c$i]]]!=""} {}
    if {$i>=500} break
    mysqlclose [set c$i]
    puts "loop $i"
    incr i
}
