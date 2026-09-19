# Run with HammerDB CLI: hammerdbcli auto tests/mysql-generated-regressions.tcl
# No database connection is needed; execute generated procedures with deterministic rows.
set argv {}
package require tcltest 2
namespace import ::tcltest::*
dbset db mysql
dbset bm TPROC-C
proc generated_proc {name script} {
    set start [string first "proc $name \{" $script]
    if {$start < 0} {error "Missing generated procedure $name"}
    set command ""
    foreach line [split [string range $script $start end] \n] {
        append command $line \n
        if {[info complete $command]} {return $command}
    }
    error "Incomplete generated procedure $name"
}
foreach driver {test timed} {
    foreach no_sp {false true} {
        test syntax-$driver-$no_sp {Generated driver has balanced procedure boundaries} -body {
            diset tpcc mysql_driver $driver
            diset tpcc mysql_no_stored_procs $no_sp
            diset tpcc mysql_async_scale false
            loadscript
            set parser [interp create]
            try {
                $parser eval "proc syntax_check {} {\n$::_ED(package)\n}"
                foreach name {neword payment ostat delivery slev prep_statement} {
                    $parser eval [generated_proc $name $::_ED(package)]
                }
            } finally {interp delete $parser}
        } -result {}
    }
}
diset tpcc mysql_driver test
diset tpcc mysql_no_stored_procs true
loadscript
set mock [interp create]
$mock eval [generated_proc ostat $::_ED(package)]
$mock eval [generated_proc payment $::_ED(package)]
$mock eval {
    set byname 1
    set namecount 1
    proc RandomNumber {lo hi} {if {$hi == 100 && !$::byname} {return 99}; return 1}
    proc NURand {args} {return 1}
    proc randname {args} {return Known}
    proc gettimestamp {} {return 20260914000000}
    proc mysqlexec {args} {}
    proc puts {args} {set ::output [lindex $args end]}
    namespace eval mysql {
        proc commit {args} {}
        proc sel {handle sql mode} {
            lappend ::queries $sql
            if {[string match {SELECT count(c_id)*} $sql]} {return $::namecount}
            if {[string match {SELECT c_first, c_middle, c_id*} $sql]} {
                set rows {}
                for {set i 1} {$i <= $::namecount} {incr i} {
                    lappend rows [list First M [expr {100+$i}] Street1 Street2 City State Zip Phone GC 50000 0 25 Date]
                }
                return $rows
            }
            if {[string match {SELECT w_street*} $sql] || [string match {SELECT d_street*} $sql]} {
                return {Street1 Street2 City State Zip Name}
            }
            if {[string match {SELECT c_balance, c_first, c_middle, c_id*} $sql]} {return {{25 First M 777}}}
            if {[string match {SELECT c_balance, c_first, c_middle, c_last*} $sql]} {
                if {$mode eq "-flatlist"} {return {25 First M Known}}
                return {{25 First M Known}}
            }
            return {}
        }
    }
}
foreach count {1 2 3 4} expected {101 101 102 102} {
    test payment-median-$count {Payment selects the lower middle matching customer} -body {
        $mock eval [list set namecount $count]
        $mock eval {
            set byname 1
            set queries {}
            payment handle 1 1 false true
            lindex [split $output ,] 0
        }
    } -result $expected
}
test order-status-byname {Use the selected ID and handle a customer with no orders} -body {
    $mock eval {
        set byname 1
        set namecount 1
        set queries {}
        ostat handle 1 false true
        list [expr {[lsearch -glob $queries {*o_c_id = 777*}] >= 0}] $output
    }
} -result {1 777,Known,First,M,25,0,,}
test order-status-byid {Read the flat customer row and initialize empty order fields} -body {
    $mock eval {
        set byname 0
        ostat handle 1 false true
        set output
    }
} -result {1,Known,First,M,25,0,,}
interp delete $mock

# Exercise the actual schema-check procedure embedded in the MySQL generator.
set schema_mock [interp create]
$schema_mock eval [generated_proc check_tpch [info body check_mysqltpch]]
$schema_mock eval {
    set actual_sf 1
    proc ConnectToMySQL {args} {return handle}
    proc mysqluse {args} {}
    proc mysqlclose {args} {}
    proc puts {args} {}
    namespace eval mysql {
        proc sel {handle sql mode} {
            if {[string match {select schema_name*} $sql]} {return tpch}
            if {$sql eq "show tables"} {return {SUPPLIER CUSTOMER LINEITEM NATION ORDERS PART PARTSUPP REGION}}
            if {$sql eq "select count(*) from supplier"} {error "Table supplier does not exist (case-sensitive server)"}
            if {$sql eq "select count(*) from SUPPLIER"} {return [expr {$::actual_sf * 10000}]}
            if {[string match {show index*} $sql]} {return PRIMARY}
            if {[string match {select count(*)*} $sql]} {return 10000000}
            return {}
        }
    }
}
test tpch-scale-match {Accept matching scale using the schema's uppercase table name} -body {
    $schema_mock eval {check_tpch host 3306 null {} user password tpch 1 false tenant}
} -result {}
test tpch-scale-mismatch {Reject larger schemas instead of skipping the scale check} -body {
    $schema_mock eval {
        set actual_sf 2
        check_tpch host 3306 null {} user password tpch 1 false tenant
    }
} -returnCodes error -match glob -result {*scale factor 2 does not equal dict scale factor*}
interp delete $schema_mock

set failed $::tcltest::numTests(Failed)
cleanupTests
exit [expr {$failed > 0}]
