# Run inside HammerDB CLI: hammerdbcli auto tests/oceanbase-generated.tcl
set argv {}
set root [file dirname [file dirname [file normalize [info script]]]]
package require tcltest 2
namespace import ::tcltest::*
# Route every configuration read/write to disposable copies before dbset/diset.
set isolation_channel [file tempfile oceanbase_test_state_dir [file join [temporaryDirectory] ob-generated-]]
close $isolation_channel
file delete $oceanbase_test_state_dir
file mkdir $oceanbase_test_state_dir
try {
    if {$::tcl_platform(platform) ne "windows"} {file attributes $oceanbase_test_state_dir -permissions 0700}
    catch {hdb close}
    foreach name [concat {generic database} [dict keys $dbdict]] {
        set original [CheckSQLiteDB $name]
        if {[file exists $original]} {
            file copy $original [file join $oceanbase_test_state_dir "$name.db"]
        }
    }
    rename ::CheckSQLiteDB ::oceanbase_test_original_CheckSQLiteDB
    proc ::CheckSQLiteDB {name} {
        return [file join $::oceanbase_test_state_dir "$name.db"]
    }
dbset db ob
dbset bm TPROC-C
diset tpcc ob_driver test
diset tpcc ob_no_stored_procs true
loadscript
proc generated_assignment {script {variable password}} {
    set start [string first "\nset $variable " $script]
    if {$start < 0} {error "Missing password header"}
    set command ""
    foreach line [split [string range $script [expr {$start + 1}] end] \n] {
        append command $line \n
        if {[info complete $command]} {return $command}
    }
    error "Incomplete password assignment"
}
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
set mock [interp create]
$mock eval [generated_proc ostat $::_ED(package)]
$mock eval {
    set byname 1
    set queries {}
    proc RandomNumber {lo hi} {if {$hi == 100 && !$::byname} {return 99}; return 1}
    proc NURand {args} {return 1}
    proc randname {args} {return Known}
    proc mysqlexec {args} {}
    proc puts {args} {set ::output [lindex $args end]}
    namespace eval mysql {
        proc commit {args} {}
        proc sel {handle sql mode} {
            lappend ::queries $sql
            if {[string match {SELECT count(c_id)*} $sql]} {return 1}
            if {[string match {SELECT c_balance, c_first, c_middle, c_id*} $sql]} {return {{25 First M 777}}}
            if {[string match {SELECT c_balance, c_first, c_middle, c_last*} $sql]} {
                if {$mode ne "-flatlist"} {error "Customer ID lookup must use a flat row"}
                return {25 First M Known}
            }
            return {}
        }
    }
}
test order-status-byname {Use the chosen customer's ID, including customers with no orders} -body {
    $mock eval {
        set byname 1
        set queries {}
        ostat handle 1 false true
        expr {[lsearch -glob $queries {*o_c_id = 777*}] >= 0 && [string match {777,Known,First,M,25,0,,} $output]}
    }
} -result 1
test order-status-byid {Flat customer rows and empty order dates are handled} -body {
    $mock eval {
        set byname 0
        ostat handle 1 false true
        set output
    }
} -result {1,Known,First,M,25,0,,}
interp delete $mock
test mysql-after-ob {A native MySQL script has no OceanBase runtime dependency} -body {
    dbset db mysql
    diset tpcc mysql_driver test
    loadscript
    expr {[string first {oceanbasecommon} $::_ED(package)] < 0}
} -result 1
# Generate schema scripts without allocating loader threads or connecting to a database.
rename load_virtual original_load_virtual
proc load_virtual {} {}
proc tpch_date_formats {script} {
    list [regexp -all {str_to_date\('[^']*','%Y-%M-%d'\)} $script] \
         [regexp -all {str_to_date\('[^']*','%Y-%b-%d'\)} $script]
}
foreach database {mysql ob mysql} label {mysql-before-ob oceanbase mysql-after-ob} expected {{4 0} {0 4} {4 0}} {
    dbset db $database
    dbset bm TPROC-H
    test date-build-$label {Only OceanBase initial-load SQL uses abbreviated-month parsing} -body {
        if {$database eq "ob"} {build_obtpch} else {build_mysqltpch}
        tpch_date_formats $::_ED(package)
    } -result $expected
    test date-refresh-$label {Only OceanBase refresh SQL uses abbreviated-month parsing} -body {
        loadscript
        tpch_date_formats $::_ED(package)
    } -result $expected
}
rename load_virtual {}
rename original_load_virtual load_virtual

# Reusing the generator must leave native scripts untouched after OB generation.
foreach asynchronous {false true} {
    test runtime-timed-$asynchronous {OB timed counters, labels and session hooks are isolated} -setup {
        set saved_ob $::configoceanbase
    } -body {
        dbset db mysql
        dbset bm TPROC-C
        diset tpcc mysql_async_scale $asynchronous
        loadtimedmysqltpcc
        set native $::_ED(package)
        dbset db ob
        # Exercise the backend with an async fixture; the OB UI does not expose it.
        dict set ::configoceanbase tpcc ob_async_scale $asynchronous
        loadtimedobtpcc
        set ob $::_ED(package)
        dbset db mysql
        loadtimedmysqltpcc
        list [expr {$native eq $::_ED(package)}] [info complete $ob] \
            [regexp -all {oceanbasecommon::transaction_count} $ob] \
            [expr {[string first {testresult $nopm $tpm OceanBase} $ob] >= 0}] \
            [expr {[string first {Com_commit} $ob] < 0}] \
            [expr {[string first {oceanbasecommon} $native] < 0}]
    } -cleanup {
        set ::configoceanbase $saved_ob
    } -result {1 1 2 1 1 1}
}
test runtime-connect {Both synchronous and asynchronous OB connections apply a session timeout} -setup {
    set mock [interp create]
    $mock eval [list source [file join [file dirname [file dirname [info script]]] modules oceanbasecommon-1.0.tm]]
    foreach name {chk_socket ConnectToMySQL ConnectToMySQLAsynch} {
        $mock eval [generated_proc $name $ob]
    }
    $mock eval {
        set calls {}
        proc mysqlconnect {args} {return handle}
        proc mysqluse {args} {}
        proc puts {args} {}
        namespace eval mysql {
            proc autocommit {args} {}
            proc sel {args} {return {}}
            proc exec {handle sql} {lappend ::calls $sql}
        }
        oceanbasecommon::configure 120
    }
} -body {
    $mock eval {
        ConnectToMySQL host 2881 null {} root@tenant password tpcc
        ConnectToMySQLAsynch host 2881 null {} root@tenant password tpcc client false
        set calls
    }
} -cleanup {
    interp delete $mock
} -result {{SET SESSION ob_query_timeout = 120000000} {SET SESSION ob_query_timeout = 120000000}}

test tproch-login-no-password-output {OB H connects without logging credentials; native generation stays unchanged} -setup {
    set saved_ob $::configoceanbase
    set worker [interp create]
    dbset db ob
    dbset bm TPROC-H
    loadscript
    set h_script $::_ED(package)
    foreach name {chk_socket ConnectToMySQL} {
        $worker eval [generated_proc $name $h_script]
    }
    $worker eval {
        set output {}
        proc puts {args} {lappend ::output [lindex $args end]}
        proc mysqlconnect {args} {set ::connection $args; return handle}
        proc mysqluse {args} {}
        namespace eval mysql {
            proc autocommit {args} {}
            proc sel {args} {return {}}
        }
        namespace eval oceanbasecommon {proc configure_session {args} {}}
    }
} -body {
    set password {synthetic'password$with[syntax]}
    set handle [$worker eval [list ConnectToMySQL host 2883 null {} root@tenant $password tpch false {}]]
    set leaked [$worker eval [list string first $password [$worker eval {join $output \n}]]]
    set delivered [$worker eval {dict get $connection -password}]
    dbset db mysql
    dbset bm TPROC-H
    loadscript
    list $handle $leaked [expr {$delivered eq $password}] \
        [expr {[string first {puts "login_command $login_command"} $::_ED(package)] >= 0}]
} -cleanup {
    interp delete $worker
    set ::configoceanbase $saved_ob
} -result {handle -1 1 1}

set h_expected_types {
    {L_PARTKEY INT} {L_PARTKEY BIGINT}
    {L_QUANTITY INT} {L_QUANTITY DECIMAL(15,2)}
    {L_EXTENDEDPRICE DECIMAL(10,2)} {L_EXTENDEDPRICE DECIMAL(15,2)}
    {L_DISCOUNT DECIMAL(10,2)} {L_DISCOUNT DECIMAL(15,2)}
    {L_TAX DECIMAL(10,2)} {L_TAX DECIMAL(15,2)}
    {`O_CUSTKEY` INT} {`O_CUSTKEY` BIGINT}
    {`O_TOTALPRICE` DECIMAL(10,2)} {`O_TOTALPRICE` DECIMAL(15,2)}
    {PS_PARTKEY INT} {PS_PARTKEY BIGINT}
    {PS_SUPPLYCOST INT} {PS_SUPPLYCOST DECIMAL(15,2)}
    {P_PARTKEY INT} {P_PARTKEY BIGINT}
    {P_RETAILPRICE DECIMAL(10,2)} {P_RETAILPRICE DECIMAL(15,2)}
    {C_CUSTKEY INT} {C_CUSTKEY BIGINT}
    {C_ACCTBAL DECIMAL(10,2)} {C_ACCTBAL DECIMAL(15,2)}
    {S_ACCTBAL DECIMAL(10,2)} {S_ACCTBAL DECIMAL(12,2)}
}

test tproch-optimized-build {Real TPROC-H generation extends native DDL only when selected} -setup {
    set saved_ob $::configoceanbase
    set had_dialog [llength [info commands tk_messageBox]]
    if {$had_dialog} {rename tk_messageBox saved_h_dialog}
    proc tk_messageBox {args} {return yes}
    dbset db ob
    dbset bm TPROC-H
    set worker [interp create]
    $worker eval {proc mysqlexec {handle sql} {lappend ::ddl $sql}; set ddl {}}
} -body {
    dict set ::configoceanbase tpch ob_tpch_optimized_schema true
    dict set ::configoceanbase tpch ob_tpch_partition_count 12
    oceanbase::mysql::generate tpch build
    set optimized $::_ED(package)
    set start [string first {proc OceanBaseHTablegroups } $optimized]
    set end [string first {proc CreateTables } $optimized $start]
    $worker eval [string range $optimized $start [expr {$end - 1}]]
    $worker eval {CreateOceanBaseHTables handle InnoDB tpch 12}
    set distributed [$worker eval {set ddl}]
    $worker eval {set ddl {}}
    dict set ::configoceanbase tpch ob_tpch_optimized_schema false
    oceanbase::mysql::generate tpch build
    set plain $::_ED(package)
    set start [string first {proc CreateTables } $plain]
    set end [string first {proc CreateOBTables } $plain $start]
    $worker eval [string range $plain $start [expr {$end - 1}]]
    $worker eval {CreateTables handle InnoDB}
    set native [$worker eval {set ddl}]
    set preserved {}
    foreach before $native after [lrange $distributed 2 9] {
        set before [string map $h_expected_types $before]
        lappend preserved [expr {[string range $after 0 [expr {[string length $before] - 1}]] eq $before}]
    }
    list [info complete $optimized] \
        [expr {[string first {CreateOceanBaseHTables $mysql_handler $mysql_tpch_storage_engine $db 12} $optimized] >= 0}] \
        [expr {[string first {proc CreateOceanBaseHTables} $plain] == -1}] \
        [expr {[llength $native] == 8 && [llength $distributed] == 11 && 0 ni $preserved}] \
        [regexp {^CREATE INDEX HDB_LINEITEM_SHIPDATE_COVER_IDX\s+ON LINEITEM \(L_SHIPDATE,L_PARTKEY,L_SUPPKEY,L_DISCOUNT,L_QUANTITY,L_EXTENDEDPRICE\) LOCAL$} [lindex $distributed end]] \
        [expr {[string first {HDB_LINEITEM_SHIPDATE_COVER_IDX} [join $native \n]] == -1}]
} -cleanup {
    interp delete $worker
    set ::configoceanbase $saved_ob
    rename tk_messageBox {}
    if {$had_dialog} {rename saved_h_dialog tk_messageBox}
} -result {1 1 1 1 1 1}

test tproch-native-after-distributed {Distributed generation leaves native MySQL schema generation unchanged} -setup {
    set saved_ob $::configoceanbase
    set saved_mysql $::configmysql
    set had_dialog [llength [info commands tk_messageBox]]
    if {$had_dialog} {rename tk_messageBox saved_native_h_dialog}
    proc tk_messageBox {args} {return yes}
} -body {
    dbset db mysql
    dbset bm TPROC-H
    build_mysqltpch
    set before $::_ED(package)
    dict set ::configoceanbase tpch ob_tpch_optimized_schema true
    oceanbase::mysql::generate tpch build
    build_mysqltpch
    expr {$before eq $::_ED(package)}
} -cleanup {
    set ::configoceanbase $saved_ob
    set ::configmysql $saved_mysql
    rename tk_messageBox {}
    if {$had_dialog} {rename saved_native_h_dialog tk_messageBox}
} -result 1


test schema-passwords {Generated C/H build/check/delete entries preserve empty and spaced passwords} -setup {
    set saved_ob $::configoceanbase
    set had_dialog [llength [info commands tk_messageBox]]
    if {$had_dialog} {rename tk_messageBox saved_password_dialog}
    proc tk_messageBox {args} {return yes}
} -body {
    set results {}
    foreach workload {tpcc tpch} {
        foreach action {build check delete} {
            foreach password [list {} {two words} {a;[error unsafe]$x} {double"quote}] {
                set key [expr {$workload eq "tpcc" ? "ob_pass" : "ob_tpch_pass"}]
                dict set ::configoceanbase $workload $key [quotemeta $password]
                oceanbase::mysql::generate $workload $action
                set entry [dict get [dict create build do_$workload check check_$workload delete drop_schema] $action]
                set start [string last "\n$entry " $::_ED(package)]
                set call [string range $::_ED(package) [expr {$start + 1}] end]
                set worker [interp create]
                $worker eval [list proc $entry {args} {return $args}]
                set args [$worker eval $call]
                set password_index [expr {$action eq "build" ? 6 : 5}]
                lappend results [expr {[lindex $args $password_index] eq $password}]
                interp delete $worker
            }
        }
    }
    expr {0 ni $results && [llength $results] == 24}
} -cleanup {
    set ::configoceanbase $saved_ob
    rename tk_messageBox {}
    if {$had_dialog} {rename saved_password_dialog tk_messageBox}
} -result 1


test workload-passwords {Real diset and C test/timed/H query drivers preserve password bytes} -setup {
    set saved_ob $::configoceanbase
    set saved_db $::rdbms
} -body {
    set results {}
    dbset db ob
    foreach {workload action} {tpcc test tpcc timed tpch test} {
        foreach password [list {} {two words} {a;[error unsafe]$x} {double"quote} {back\nslash} {true} {false} "two\nlines" "two\n\"lines"] {
            set key [expr {$workload eq "tpcc" ? "ob_pass" : "ob_tpch_pass"}]
            diset $workload $key $password
            oceanbase::mysql::generate $workload $action
            set worker [interp create]
            $worker eval [generated_assignment $::_ED(package)]
            lappend results [expr {[$worker eval {set password}] eq $password}]
            interp delete $worker
        }
    }
    expr {0 ni $results && [llength $results] == 27}
} -cleanup {
    set ::configoceanbase $saved_ob
    set ::rdbms $saved_db
} -result 1

test workload-usernames {Real C/H headers preserve accepted Tcl metacharacters in user/tenant/cluster} -setup {
    set saved_ob $::configoceanbase
} -body {
    set results {}
    dbset db ob
    foreach {workload action} {tpcc test tpcc timed tpch test} {
        set key [expr {$workload eq "tpcc" ? "ob_user" : "ob_tpch_user"}]
        foreach cluster [list {} {cluster$tag}] {
            dict set ::configoceanbase connection ob_tenant {tenant[injected]}
            dict set ::configoceanbase connection ob_cluster $cluster
            foreach user [list {bench$tag} {bench[injected]} {bench"quote} {bench\path} {bench;tag}] {
                diset $workload $key $user
                oceanbase::mysql::generate $workload $action
                set worker [interp create]
                $worker eval {
                    set executed false
                    proc injected {} {set ::executed true; return unwanted}
                }
                $worker eval [generated_assignment $::_ED(package) user]
                set expected [expr {$cluster eq "" ? "$user@tenant\[injected\]" : "$user@tenant\[injected\]#$cluster"}]
                lappend results [expr {[$worker eval {set user}] eq $expected && ![$worker eval {set executed}]}]
                interp delete $worker
            }
        }
    }
    expr {0 ni $results && [llength $results] == 30}
} -cleanup {
    set ::configoceanbase $saved_ob
} -result 1

test counter-diset-passwords {Counter command after real diset contains decoded C and H credentials} -setup {
    set saved_ob $::configoceanbase
    set worker [interp create]
    $worker eval {
        namespace eval thread {
            proc create {script} {return counter-worker}
            proc send {args} {
                set command [lindex $args end]
                if {[lindex $command 0] eq "read_more"} {set ::counter_command $command}
            }
        }
        set dbdict {mysql {library mysqltcl}}
        set mysql_ssl_options {}
        set quote_passwords true
    }
    foreach file {src/generic/gentccmn.tcl src/oceanbase/mysql/runtime.tcl src/oceanbase/mysql/counter.tcl} {
        $worker eval [list source [file join $root $file]]
    }
} -body {
    set results {}
    dbset db ob
    foreach password [list {} {two words} {a$b} {a;[error unsafe]$x} {double"quote} {back\nslash}] {
        diset tpcc ob_pass $password
        diset tpch ob_tpch_pass $password
        $worker eval [list set configmysql [oceanbase::mysql::config $::configoceanbase]]
        $worker eval {tcount_oceanbase_mysql TPC-C 10 main 120}
        set command [$worker eval {set counter_command}]
        lappend results [expr {[lindex $command 8] eq $password && [lindex $command 10] eq $password}]
    }
    set results
} -cleanup {
    interp delete $worker
    set ::configoceanbase $saved_ob
} -result {1 1 1 1 1 1}

set failed $::tcltest::numTests(Failed)
cleanupTests
} finally {
    catch {hdb close}
    if {[llength [info commands ::oceanbase_test_original_CheckSQLiteDB]]} {
        rename ::CheckSQLiteDB {}
        rename ::oceanbase_test_original_CheckSQLiteDB ::CheckSQLiteDB
    }
    file delete -force $oceanbase_test_state_dir
}
exit [expr {$failed > 0}]
