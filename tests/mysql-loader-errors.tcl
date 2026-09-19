# Run: tclsh tests/mysql-loader-errors.tcl (Tcl 8.6+), or hammerdbcli auto this file.
# No database or Thread package is needed. Shared state and SQL calls are deterministic fixtures.
set argv {}
if {[package vcompare [info patchlevel] 8.6] < 0} {error "This test requires Tcl 8.6 or later"}
package require tcltest 2
namespace import ::tcltest::*
set root [file dirname [file dirname [file normalize [info script]]]]
if {[info exists ::env(HAMMERDB_SOURCE_ROOT)]} {set root $::env(HAMMERDB_SOURCE_ROOT)}
source [file join $root src mysql mysqloltp.tcl]
source [file join $root src mysql mysqlolap.tcl]
proc loader_proc {generator name} {
    set source [info body $generator]
    set start [string first "proc $name \{" $source]
    if {$start < 0} {error "Missing generated loader $name"}
    set command ""
    foreach line [split [string range $source $start end] \n] {
        append command $line \n
        if {[info complete $command]} {return $command}
    }
    error "Incomplete generated loader $name"
}
proc fixture {definition} {
    set i [interp create]
    $i eval $definition
    $i eval {
        set position 2
        set fail_connect 0
        set finish_workers 0
        set sleeps 0
        array set dists {}
        array set shared {application,abort 0 application,load READY common,thrdlst {unused monitor idle idle}}
        namespace eval tsv {
            proc set {table key value} {::set ::shared($table,$key) $value}
            proc get {table key} {return $::shared($table,$key)}
            proc exists {table key} {info exists ::shared($table,$key)}
            proc lappend {table key value} {::lappend ::shared($table,$key) $value}
            proc lindex {table key index} {::lindex $::shared($table,$key) $index}
            proc lreplace {table key first last value} {
                ::set ::shared($table,$key) [::lreplace $::shared($table,$key) $first $last $value]
            }
        }
        proc puts {args} {}
        proc after {args} {
            if {[incr ::sleeps] > 3} {return -code error -errorcode {TEST POLL_LIMIT} "monitor kept waiting"}
        }
        proc chk_thread {} {return TRUE}
        proc findvuposition {} {list $::position 3}
        proc findvuhposition {} {list $::position 3}
        proc set_dists {} {}
        proc set_dist_list {args} {}
        proc findchunk {args} {return {1 1 1}}
        proc start_end {args} {return 1:1}
        proc ConnectToMySQL {args} {
            if {$::fail_connect} {return -code error -errorcode {TEST CONNECT} "injected connection failure"}
            return handle
        }
        proc CreateDatabase {args} {return 1}
        foreach name {CreateTables CreateOBTables LoadWare LoadCust LoadOrd mk_supp mk_cust mk_part mk_order mk_region CreateStoredProcs GatherStatistics mysqluse mysqlclose mysqlexec} {
            proc $name {args} {}
        }
        foreach name {LoadItems mk_nation} {
            proc $name {args} {
                if {$::finish_workers} {set ::shared(common,thrdlst) {unused monitor done done}}
            }
        }
        namespace eval mysql {
            proc autocommit {args} {}
            proc commit {args} {}
        }
    }
    return $i
}
foreach workload {tpcc tpch} generator {build_mysqltpcc build_mysqltpch} arguments {
    {host 3306 null {} 2 user password db innodb false false 2}
    {host 3306 null {} 1 user password db innodb 2 false 1 tenant}
} {
    set definition [loader_proc $generator do_$workload]
    set call [list do_$workload {*}$arguments]
    test $workload-worker-error {Worker connection error sets abort and preserves the error code} -setup {
        set i [fixture $definition]
        $i eval {set fail_connect 1}
    } -body {
        set code [catch {$i eval $call} message options]
        list $code $message [dict get $options -errorcode] [$i eval {tsv::get application abort}]
    } -cleanup {interp delete $i} -result {1 {injected connection failure} {TEST CONNECT} 1}
    test $workload-monitor-error {Monitor setup error sets abort so waiting workers can exit} -setup {
        set i [fixture $definition]
        $i eval {set position 1; set fail_connect 1}
    } -body {
        catch {$i eval $call} message options
        list $message [dict get $options -errorcode] [$i eval {tsv::get application abort}]
    } -cleanup {interp delete $i} -result {{injected connection failure} {TEST CONNECT} 1}
    test $workload-monitor-abort {Monitor stops when a worker has failed instead of polling forever} -setup {
        set i [fixture $definition]
        $i eval {set position 1; tsv::set application abort 1}
    } -body {
        $i eval $call
    } -cleanup {interp delete $i} -returnCodes error -result {Schema build aborted after a loader failure}
    test $workload-worker-success {Successful workers still report done without aborting} -setup {
        set i [fixture $definition]
    } -body {
        $i eval $call
        $i eval {list [tsv::get application abort] [tsv::lindex common thrdlst 2]}
    } -cleanup {interp delete $i} -result {0 done}
    test $workload-monitor-success {Monitor completes normally when every worker reports done} -setup {
        set i [fixture $definition]
        $i eval {set position 1; set finish_workers 1}
    } -body {
        $i eval $call
        $i eval {tsv::get application abort}
    } -cleanup {interp delete $i} -result 0
}
set failed $::tcltest::numTests(Failed)
cleanupTests
exit [expr {$failed > 0}]
