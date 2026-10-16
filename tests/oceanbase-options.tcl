# Run in the built CLI with DISPLAY pointing at a disposable X server.
set argv {}
package require tcltest 2
namespace import ::tcltest::*
set root [file dirname [file dirname [file normalize [info script]]]]
set isolation_channel [file tempfile oceanbase_options_state [file join [temporaryDirectory] ob-options-]]
close $isolation_channel
file delete $oceanbase_options_state
file mkdir $oceanbase_options_state
set failed 1
try {
    if {$::tcl_platform(platform) ne "windows"} {file attributes $oceanbase_options_state -permissions 0700}
    catch {hdb close}
    foreach name [concat {generic database} [dict keys $dbdict]] {
        set original [CheckSQLiteDB $name]
        if {[file exists $original]} {file copy $original [file join $oceanbase_options_state "$name.db"]}
    }
    rename ::CheckSQLiteDB ::oceanbase_options_original_CheckSQLiteDB
    proc ::CheckSQLiteDB {name} {return [file join $::oceanbase_options_state "$name.db"]}
set gui [zipfs mount [file join [pwd] hammerdb] /ob-options-test]
lappend auto_path $gui/lib
set ::env(TK_LIBRARY) $gui/tk_library
package require Tk
set f [open [file join $root src generic gened.tcl]]
set themed_toplevel {}
while {[gets $f line] >= 0} {
    append themed_toplevel $line \n
    if {[info complete $themed_toplevel]} {break}
}
close $f
eval $themed_toplevel
set f [open [file join $root src generic gened.tcl]]
set editor_source [read $f]
close $f
set start [string first {proc get_warehouse_list_for_spinbox } $editor_source]
set definition {}
foreach line [split [string range $editor_source $start end] \n] {
    append definition $line \n
    if {[info complete $definition]} {eval $definition; break}
}
wm withdraw .
ttk::toplevel .ed_mainFrame
wm withdraw .ed_mainFrame
set configoceanbase [oceanbaseconfig::normalize [::XML::To_Dict [file join $root config oceanbase.xml]]]
set baseline $configoceanbase
set mysql_before $configmysql

test options-layout {Independent OB dialog follows native Connection/Settings layout} -body {
    oceanbase::mysql::show_options tpcc all
    list [.oboptions.tabs tab 0 -text] [.oboptions.tabs tab 1 -text] \
        [winfo class $::oceanbase::mysql::option_widgets(ob_pass)] \
        [winfo class $::oceanbase::mysql::option_widgets(ob_count_ware)]
} -cleanup {destroy .oboptions} -result {Connection Settings TEntry TSpinbox}

test options-pool-dependencies {Pool requires prepared stored procedures and disables conflicting choices} -body {
    oceanbase::mysql::show_options tpcc drive
    set ::oceanbase::mysql::options(tpcc,ob_no_stored_procs) true
    $::oceanbase::mysql::option_widgets(ob_connect_pool) invoke
    list $::oceanbase::mysql::options(tpcc,ob_prepared) $::oceanbase::mysql::options(tpcc,ob_no_stored_procs) \
        [$::oceanbase::mysql::option_widgets(ob_prepared) instate disabled] \
        [$::oceanbase::mysql::option_widgets(ob_no_stored_procs) instate disabled]
} -cleanup {destroy .oboptions} -result {true false 1 1}

test options-async-dependencies {Async exposes client controls and enables keying/thinking} -body {
    oceanbase::mysql::show_options tpcc drive
    set before [$::oceanbase::mysql::option_widgets(ob_async_client) instate disabled]
    $::oceanbase::mysql::option_widgets(ob_async_scale) invoke
    list $before $::oceanbase::mysql::options(tpcc,ob_keyandthink) \
        [$::oceanbase::mysql::option_widgets(ob_async_client) instate disabled]
} -cleanup {destroy .oboptions} -result {1 true 0}

test options-test-driver {Test driver disables timed-only options and clears async} -body {
    oceanbase::mysql::show_options tpcc drive
    set ::oceanbase::mysql::options(tpcc,ob_allwarehouse) true
    $::oceanbase::mysql::option_widgets(ob_async_scale) invoke
    set widget $::oceanbase::mysql::option_widgets(ob_driver)
    $widget.test invoke
    list $::oceanbase::mysql::options(tpcc,ob_async_scale) \
        $::oceanbase::mysql::options(tpcc,ob_allwarehouse) \
        [$::oceanbase::mysql::option_widgets(ob_allwarehouse) instate disabled] \
        [$::oceanbase::mysql::option_widgets(ob_duration) instate disabled] \
        [$::oceanbase::mysql::option_widgets(ob_async_scale) instate disabled]
} -cleanup {destroy .oboptions} -result {false false 1 1 1}

test options-tls-controls {TLS CA and mutual-authentication controls follow SSL selection} -body {
    oceanbase::mysql::show_options tpcc build
    $::oceanbase::mysql::option_widgets(ob_ssl) invoke
    set one_way [$::oceanbase::mysql::option_widgets(ob_ssl_cert) instate disabled]
    set widget $::oceanbase::mysql::option_widgets(ob_ssl_two_way)
    $widget.true invoke
    list $one_way [$::oceanbase::mysql::option_widgets(ob_ssl_ca) instate disabled] \
        [$::oceanbase::mysql::option_widgets(ob_ssl_cert) instate disabled]
} -cleanup {destroy .oboptions} -result {1 0 0}

test options-refresh-controls {Refresh function enables update count, delay and verbose controls} -body {
    oceanbase::mysql::show_options tpch drive
    set before [$::oceanbase::mysql::option_widgets(ob_update_sets) instate disabled]
    $::oceanbase::mysql::option_widgets(ob_refresh_on) invoke
    list $before [$::oceanbase::mysql::option_widgets(ob_update_sets) instate disabled]
} -cleanup {destroy .oboptions} -result {1 0}

test options-cancel-isolation {Editing and cancelling does not publish credentials or touch MySQL} -body {
    oceanbase::mysql::show_options tpcc all
    set ::oceanbase::mysql::options(tpcc,ob_user) changed
    .oboptions.buttons.cancel invoke
    list [expr {$baseline eq $configoceanbase}] [expr {$mysql_before eq $configmysql}]
} -result {1 1}

test counter-options-save {Counter settings persist and retain an independent connection} -body {
    countobopts TPC-C
    set ::oceanbase::mysql::options(counter,tc_refresh_rate) 7
    set ::oceanbase::mysql::options(counter,tc_log_to_temp) 1
    set ::oceanbase::mysql::options(counter,tc_unique_log_name) 1
    set ::oceanbase::mysql::options(counter,tc_log_timestamps) 1
    .oboptions.buttons.ok invoke
    sqlite3 settings [CheckSQLiteDB generic]
    set persisted [settings eval {SELECT val FROM transaction_counter WHERE key='tc_refresh_rate'}]
    settings close
    list $persisted [dict get $genericdict transaction_counter tc_log_to_temp] \
        [winfo exists .oboptions] [expr {$mysql_before eq $configmysql}]
} -result {7 1 0 1}

test counter-save-rollback {A failed combined save retains both the connection and counter preferences} -body {
    set updated $configoceanbase
    dict set updated tpcc ob_user should_not_persist
    set failed [catch {oceanbaseconfig::save $updated {tc_refresh_rate 13 invalid_counter_key 1}}]
    sqlite3 settings [CheckSQLiteDB generic]
    set refresh [settings onecolumn {SELECT val FROM transaction_counter WHERE key='tc_refresh_rate'}]
    settings close
    sqlite3 settings [CheckSQLiteDB oceanbase]
    set user [settings onecolumn {SELECT val FROM tpcc WHERE key='ob_user'}]
    settings close
    list $failed $refresh [expr {$user eq [dict get $configoceanbase tpcc ob_user]}]
} -result {1 7 1}

test feature-pool-credentials {Pool qualification and special-character credentials remain data} -body {
    set mapped [oceanbasecommon::pool_connection {ob_host host ob_port 2883 ob_user root ob_pass {a;[not executed]$x} ob_dbase tpcc ob_tenant tenant ob_cluster cluster ob_ssl_options {-ssl false}}]
    list [dict get $mapped mysql_user] [dict get $mapped mysql_pass]
} -result {root@tenant#cluster {a;[not executed]$x}}

test feature-pool-script {OB pools read independent XML, preserving native generator isolation} -body {
    set saved_tk_version $::tk_version
    unset ::tk_version
    dbset db ob
    dbset bm TPROC-C
    dict set configoceanbase tpcc ob_connect_pool true
    dict set configoceanbase tpcc ob_no_stored_procs false
    loadtimedobtpcc
    list [info complete $::_ED(package)] \
        [expr {[string first {get_connect_xml ob} $::_ED(package)] >= 0}] \
        [expr {[string first {oceanbasecommon::pool_connection} $::_ED(package)] >= 0}] \
        [expr {$mysql_before eq $configmysql}]
} -cleanup {set ::tk_version $saved_tk_version; set configoceanbase $baseline} -result {1 1 1 1}

test feature-history-native {OB native HISTORY PK does not use the MySQL VERSION gate} -body {
    set saved_tk_version $::tk_version
    unset ::tk_version
    rename load_virtual real_load_virtual
    proc load_virtual {} {}
    dict set configoceanbase tpcc ob_history_pk true
    build_obtpcc
    list [info complete $::_ED(package)] \
        [expr {[string first {pkmin_version} $::_ED(package)] < 0}] \
        [expr {[string first {AUTO_INCREMENT INVISIBLE} $::_ED(package)] >= 0}]
} -cleanup {set ::tk_version $saved_tk_version; rename load_virtual {}; rename real_load_virtual load_virtual; set configoceanbase $baseline} -result {1 1 1}

test feature-history-distributed {Distributed HISTORY primary key includes its partition key} -body {
    set saved_tk_version $::tk_version
    unset ::tk_version
    rename load_virtual real_load_virtual
    proc load_virtual {} {}
    dict set configoceanbase tpcc ob_distributed_schema true
    dict set configoceanbase tpcc ob_history_pk true
    build_obtpcc
    list [info complete $::_ED(package)] \
        [expr {[string first {PRIMARY KEY (`h_w_id`, `id`)} $::_ED(package)] >= 0}]
} -cleanup {set ::tk_version $saved_tk_version; rename load_virtual {}; rename real_load_virtual load_virtual; set configoceanbase $baseline} -result {1 1}

destroy .ed_mainFrame
set failed $::tcltest::numTests(Failed)
cleanupTests
} finally {
    catch {destroy .oboptions}
    catch {destroy .ed_mainFrame}
    catch {hdb close}
    if {[llength [info commands ::oceanbase_options_original_CheckSQLiteDB]]} {
        rename ::CheckSQLiteDB {}
        rename ::oceanbase_options_original_CheckSQLiteDB ::CheckSQLiteDB
    }
    file delete -force $oceanbase_options_state
}
exit [expr {$failed > 0}]
