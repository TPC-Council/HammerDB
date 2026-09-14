# Run with Tcl 8.6+: tclsh tests/mysql-tpch-date-format.tcl
package require tcltest 2
namespace import ::tcltest::*

if {[info exists ::env(HAMMERDB_SOURCE_ROOT)]} {
    set source_root [file normalize $::env(HAMMERDB_SOURCE_ROOT)]
} else {
    set source_root [file normalize [file join [file dirname [info script]] ..]]
}
source [file join $source_root modules tpchcommon-1.0.tm]

set mysqlolap_path [file join $source_root src mysql mysqlolap.tcl]
set channel [open $mysqlolap_path r]
set mysqlolap [read $channel]
close $channel

test generated-date-shape {TPROC-H generates abbreviated month names} -body {
    tpchcommon::mk_time 1
} -match regexp -result {^[0-9]{4}-[A-Z]{3}-[0-9]{2}$}

test mysql-date-parser {MySQL parses generated dates with the matching format specifier} -body {
    list \
        [regexp -all {str_to_date\([^\n]*'%Y-%M-%d'\)} $mysqlolap] \
        [regexp -all {str_to_date\([^\n]*'%Y-%b-%d'\)} $mysqlolap]
} -result {0 4}

set failed $::tcltest::numTests(Failed)
cleanupTests
exit [expr {$failed > 0}]
