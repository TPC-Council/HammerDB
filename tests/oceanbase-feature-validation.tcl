set argv {}
package require tcltest 2
namespace import ::tcltest::*
set root [file dirname [file dirname [file normalize [info script]]]]
source [file join $root modules oceanbasecommon-1.0.tm]
source [file join $root modules oceanbaseconfig-1.0.tm]
source [file join $root modules xml-1.1.tm]
source [file join $root src oceanbase obopt.tcl]
if {![llength [info commands find_config_dir]]} {proc find_config_dir {} {return [file join $::root config]}}
set baseline [::XML::To_Dict [file join $root config oceanbase.xml]]
test ssl-file-list-safety {TLS certificate paths containing spaces remain a single driver argument} -body {
    set path [makeDirectory {certificate folder}]
    set f [open [file join $path {ca test.pem}] w]; close $f
    set c $baseline
    dict set c connection ob_ssl true
    dict set c connection ob_ssl_linux_capath $path
    dict set c connection ob_ssl_ca {ca test.pem}
    set opts [oceanbasecommon::ssl_options $c]
    expr {[dict get $opts -sslca] eq [file join $path {ca test.pem}]}
} -cleanup {removeDirectory {certificate folder}} -result 1
test ssl-missing-cert {Requested TLS never falls back to an unencrypted connection} -body {
    set c $baseline
    dict set c connection ob_ssl true
    dict set c connection ob_ssl_linux_capath /nonexistent-hdb-cert
    oceanbasecommon::ssl_options $c
} -returnCodes error -match glob -result {*not readable*}
test new-field-migration {Existing OB settings retain values while acquiring feature defaults} -body {
    set c [oceanbaseconfig::normalize {connection {ob_compatibility_mode mysql} tpcc {ob_async_client 3} tpch {}}]
    list [dict get $c tpcc ob_async_client] [dict get $c tpcc ob_connect_pool] [dict get $c tpch ob_cloud_query]
} -result {3 false false}
test pool-requires-procedures {Contradictory pool/client-SQL settings fail before opening connections} -body {
    set c $baseline
    dict set c tpcc ob_connect_pool true
    dict set c tpcc ob_no_stored_procs true
    oceanbase::mysql::config $c
} -returnCodes error -result {Cluster Connect Pool requires stored procedures}
test async-count-validation {Reject invalid client counts before generating an invalid script} -body {
    set c $baseline
    dict set c tpcc ob_async_client 0
    oceanbase::mysql::config $c
} -returnCodes error -match glob -result {*ob_async_client*}
test test-driver-warehouse-validation {Unsupported Test Driver option fails before native generation} -body {
    set configoceanbase $baseline
    dict set configoceanbase tpcc ob_allwarehouse true
    oceanbase::mysql::generate tpcc test
} -cleanup {set configoceanbase $baseline} -returnCodes error -result {Use All Warehouses requires the Timed Driver Script}
test test-driver-async-validation {Async cannot silently become a synchronous Test Driver} -body {
    set configoceanbase $baseline
    dict set configoceanbase tpcc ob_async_scale true
    oceanbase::mysql::generate tpcc test
} -cleanup {set configoceanbase $baseline} -returnCodes error -result {Asynchronous Scaling requires the Timed Driver Script}

test counter-single-burst-after-idle {Both counters report a single burst after an idle sample} -setup {
    set worker [interp create]
    foreach source {modules/oceanbasecommon-1.0.tm modules/tcountcommon-1.0.tm src/generic/gentccmn.tcl src/oceanbase/mysql/runtime.tcl src/oceanbase/mysql/counter.tcl} {
        $worker eval [list source [file join $root $source]]
    }
    $worker eval {
        package provide mockmysql 1.0
        namespace eval thread {
            proc create {script} {uplevel #0 $script; return worker}
            proc wait {} {}
            proc release {} {}
            proc send {args} {
                set command [lindex $args end]
                if {[lindex $command 0] in {read_more ::showLCD tce post_kill_transcount_cleanup}} {uplevel #0 $command}
            }
        }
        namespace eval tsv {
            proc get {application key} {expr {$key eq "timeout" ? $::samples>=4 : 0}}
        }
        namespace eval mysql {
            proc exec {args} {}
            proc sel {handle sql format} {
                set index $::samples
                incr ::samples
                if {$::testing_bm eq "TPC-H"} {return [list [list Queries [lindex {100 101 122 123} $index]]]}
                return [list [list {trans commit count} [lindex {100 100 120 120} $index]] [list {trans rollback count} 0]]
            }
        }
        proc mysqlconnect {args} {return mockhandle}
        proc showLCD {value} {lappend ::readings $value}
        proc tce {args} {}
        proc after {args} {}
        proc post_kill_transcount_cleanup {} {}
        set dbdict {mysql {library mockmysql}}
        set mysql_ssl_options {-ssl false}
        set quote_passwords false
    }
} -body {
    set results {}
    foreach benchmark {TPC-C TPC-H} {
        $worker eval [list set configmysql [oceanbase::mysql::config $baseline]]
        $worker eval [list set testing_bm $benchmark]
        $worker eval {set samples 0; set readings {}}
        $worker eval [list tcount_oceanbase_mysql $benchmark 1 master 120]
        lappend results [$worker eval {::tcl::mathfunc::max {*}$readings}]
    }
    set results
} -cleanup {interp delete $worker} -result {1200 72000}
set failed $::tcltest::numTests(Failed)
cleanupTests
exit [expr {$failed > 0}]
