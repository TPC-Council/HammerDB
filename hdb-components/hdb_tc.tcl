array set lcdshape {
    a {3.0 5 5.2 3 7.0 5 6.0 15 3.8 17 2.0 15}
    b {6.3 2 8.5 0 18.5 0 20.3 2 18.1 4 8.1 4}
    c {19.0 5 21.2 3 23.0 5 22.0 15 19.8 17 18.0 15}
    d {17.4 21 19.6 19 21.4 21 20.4 31 18.2 33 16.4 31}
    e {3.1 34 5.3 32 15.3 32 17.1 34 14.9 36 4.9 36}
    f {1.4 21 3.6 19 5.4 21 4.4 31 2.2 33 0.4 31}
    g {4.7 18 6.9 16 16.9 16 18.7 18 16.5 20 6.5 20}
}

array set llcd {
    0 {a b c d e f}
    1 {c d}
    2 {b c e f g}
    3 {b c d e g}
    4 {a c d g}
    5 {a b d e g}
    6 {a b d e f g}
    7 {b c d}
    8 {a b c d e f g}
    9 {a b c d e g}
    - {g}
    { } {}
}

array set ulcd {
    0 {g}
    1 {a b e f g}
    2 {a d}
    3 {a f}
    4 {b e f}
    5 {c f}
    6 {c}
    7 {a e f g}
    8 {}
    9 {f}
    - {a b c d e f}
    { } {a b c d e f g}
}

proc showLCD {number {width 24} {colours {black black white white}}} {
    global llcd ulcd lcdshape
    set lcdoffset 0
	catch { .ed_mainFrame.tc.c delete lcd }
    foreach {onRim onFill offRim offFill} $colours {break}
    foreach glyph [split [format %${width}d $number] {}] {
	foreach symbol $llcd($glyph) {
.ed_mainFrame.tc.c move [eval .ed_mainFrame.tc.c create polygon $lcdshape($symbol) -tags lcd \
		    -outline $onRim -fill $onFill] $lcdoffset 0
	}
	foreach symbol $ulcd($glyph) {
.ed_mainFrame.tc.c move [eval .ed_mainFrame.tc.c create polygon $lcdshape($symbol) -tags lcd \
		    -outline $offRim -fill $offFill] $lcdoffset 0
	}
	incr lcdoffset 22
    }
}

proc transcount { } {
global tcl_platform interval ttag tcdata timedata masterthread tc_threadID rac bm rdbms afval autor connectstr tpcc_tt_compat tpch_tt_compat mysql_host mysql_port mysql_user mysql_pass mysql_tpch_user mysql_tpch_pass mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass pg_host pg_port pg_superuser pg_superuserpass pg_defaultdbase redis_host redis_port

set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
tk_messageBox -icon warning -message "Transaction Counter Stopping"
return 1
	}
}
unset -nocomplain tc_threadID
tsv::set application timeout 0
if {  ![ info exists bm ] } { set bm "TPC-C" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}

switch $rdbms {
Oracle {
if { [ info exists connectstr ] } { ; } else { set connectstr "system/manager@oracle" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists tpcc_tt_compat ] } { ; } else { set tpcc_tt_compat "false" }
if { [ info exists tpch_tt_compat ] } { ; } else { set tpch_tt_compat "false" }
if { [ info exists rac ] } { ; } else { set rac 0 }
if { [ info exists autor ] } { ; } else { set autor 1 }
}
MySQL {
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_tpch_user ] } { set mysql_tpch_user "root" }
if {  ![ info exists mysql_tpch_pass ] } { set mysql_tpch_pass "mysql" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists autor ] } { ; } else { set autor 1 }
}
MSSQLServer {
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists autor ] } { ; } else { set autor 1 }
}
PostgreSQL {
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists autor ] } { ; } else { set autor 1 }
}
Redis {
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists autor ] } { ; } else { set autor 1 }
}
default {
if { $rdbms != "Oracle" } { set rdbms "Oracle" }
if { [ info exists connectstr ] } { ; } else { set connectstr "system/manager@oracle" }
if { [ info exists interval ] } { ; } else { set interval 10 }
if { [ info exists tpcc_tt_compat ] } { ; } else { set tpcc_tt_compat "false" }
if { [ info exists tpch_tt_compat ] } { ; } else { set tpch_tt_compat "false" }
if { [ info exists rac ] } { ; } else { set rac 0 }
if { [ info exists autor ] } { ; } else { set autor 1 }
        }
    }

ed_stop_transcount
.ed_mainFrame.notebook tab .ed_mainFrame.tc  -state normal
.ed_mainFrame.notebook select .ed_mainFrame.tc 
set old 0
pack [ canvas .ed_mainFrame.tc.buff -width 500 -height 10 -background white -highlightthickness 0 ] -fill both -expand 1
pack [ canvas .ed_mainFrame.tc.c -width 500 -height 40 -background white -highlightthickness 0 ] -fill both -expand 1 -side top
pack [ canvas .ed_mainFrame.tc.buff2 -width 25 -height 300 -background white -highlightthickness 0 ] -expand 0 -side left
pack [ canvas .ed_mainFrame.tc.g -width 500 -height 300 -background white -highlightthickness 0 ] -fill both -expand 1 -side left
set tcdata {}
set timedata {}
showLCD 0
if { $bm eq "TPC-C" } {
.ed_mainFrame.tc.c create text 565 20 -text "tpm" -fill black -font {Helvetica 25} 
	} else {
.ed_mainFrame.tc.c create text 565 20 -text "qph" -fill black -font {Helvetica 25} 
	}
set ttag [ .ed_mainFrame.tc.g create text 270 100 -text "Waiting for Data ..." -fill black -font {Helvetica 18} ]
emu_graph::emu_graph tce -canvas .ed_mainFrame.tc.g -width 400 -height 150 \
 -axistextoffset 10 -autorange 1 -ticklen 5 -xref 75

switch $rdbms {
Oracle {
set tc_threadID [thread::create {
package require Oratcl

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

proc read_more { MASTER connectstr interval old gcanv tce ttag rac bm tpcc_tt_compat tpch_tt_compat } {
set logged_on 0
set timeout 0
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $rac eq 1 } {
if { $bm eq "TPC-C" } {
set sqc {select sum(value) from gv$sysstat where name = 'user commits' or name = 'user rollbacks'}
set tval 60
	} else {
set sqc {select sum(executions) from gv$sqlarea where command_type = 3 and parsing_user_id in (select user# from sys.user$ where type# = 1 and astatus = 0 and name not in ('SYS','SYSTEM','SYSMAN','DBSNMP'))}
set tval 3600
	}
} else {
if { $bm eq "TPC-C" } {
if { $tpcc_tt_compat eq "true" } {
set sqc {select (xact_commits + xact_rollbacks) from sys.monitor} 
	} else {
set sqc {select sum(value) from v$sysstat where name = 'user commits' or name = 'user rollbacks'} 
	}
set tval 60
	} else {
if { $tpch_tt_compat eq "true" } {
set sqc {select cmd_prepares from sys.monitor} 
	} else {
set sqc {select sum(executions) from v$sqlarea where command_type = 3 and parsing_user_id in (select user# from sys.user$ where type# = 1 and astatus = 0 and name not in ('SYS','SYSTEM','SYSMAN','DBSNMP'))}
	}
set tval 3600
	}
   }
if { $interval <= 0 } { set interval 10 } 
set mplier [ expr {$tval / $interval} ]
if { $logged_on eq 0 } {
if {[catch {set ldc [oralogon $connectstr] }]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Connection Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "LOGON FAILED" -fill black -font {Helvetica 18} }}]
	}
break
	} else {
set logged_on 1
	}
}	
if {[catch { set curc [ oraopen $ldc ]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count Cursor Open Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "CURSOR OPEN FAILED" -fill black -font {Helvetica 18} }}]
}
catch { oralogoff $ldc }
break
}
if {[catch {oraparse $curc $sqc}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Parse Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL PARSE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { oralogoff $ldc }
break
}
if {[catch {orasql $curc $sqc}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Execute Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL EXECUTE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { oralogoff $ldc }
break
}
if {[catch {orafetch $curc -datavariable outc}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Fetch Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL FETCH FAILED" -fill black -font {Helvetica 18} }}]
}
catch { oralogoff $ldc }
break
}
if {[catch {oraclose $curc}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count Cursor Close Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "CURSOR CLOSE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { oralogoff $ldc }
break
}
set new $outc
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
set tcsize [ llength $tcdata ]
if { $tcsize eq 0 } { 
set newtick 1 
lappend tcdata $newtick 0
lappend timedata $newtick $tstamp
if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break } 
	} else { 
if { $tcsize >= 40 } {
set tcdata [ downshift $tcdata ]
set timedata [ downshift $timedata ]
set newtick 20
} else {
set newtick [ expr {$tcsize / 2 + 1} ] 
if { $newtick eq 2 } {
set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
	}
}
lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
lappend timedata $newtick $tstamp
if { ![ isdiff $tcdata ] } {
set tcdata [ lreplace $tcdata 1 1 0 ]
}
set transval [expr {[expr {abs($new - $old)}] * $mplier}]
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
}
if { $tcsize >= 4 } { 
if { $tcsize eq 4 } {
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { $gcanv delete $ttag }} ] ] } { break }} 
}
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }} 
} else {
if { $bm eq "TPC-C" } { set gcol "red" } else { set gcol "red" }
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break }} 
		}
}
set old $new
set pauseval [ expr $interval * 1000 ]
for {set pausecount 0} {$pausecount <= $pauseval} {incr pausecount 1000} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
if { [ tsv::get application timeout ] } { break }
}
#catch [ subst {thread::send -async $MASTER { puts "Oracle Transaction Counter Stopped" }} ]
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
} 
MySQL {
set tc_threadID [thread::create {
package require mysqltcl

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

proc read_more { MASTER mysql_host mysql_port mysql_user mysql_pass mysql_tpch_user mysql_tpch_pass interval old gcanv tce ttag bm } {
set logged_on 0
set timeout 0
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $bm eq "TPC-C" } {
set sqc "show global status where Variable_name = 'Handler_commit' or Variable_name =  'Handler_rollback'" 
set tmp_mysql_user $mysql_user
set tmp_mysql_pass $mysql_pass
set tval 60
	} else {
set sqc "show global status where Variable_name = 'Queries' or Variable_name = 'Com_show_status'" 
set tmp_mysql_user $mysql_tpch_user
set tmp_mysql_pass $mysql_tpch_pass
set tval 3600
	}
if { $interval <= 0 } { set interval 10 } 
set mplier [ expr {$tval / $interval} ]
if { $logged_on eq 0 } {
if {[catch {mysqlconnect -host $mysql_host -port $mysql_port -user $tmp_mysql_user -password $tmp_mysql_pass} mysql_handler]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Connection Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "LOGON FAILED" -fill black -font {Helvetica 18} }}]
}
break
	} else {
set logged_on 1
	}
}	
if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler $sqc -list ] ]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Execute Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL EXECUTE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { mysqlclose $mysql_handler }
break
} else {
if { $bm eq "TPC-C" } {
regexp {\{\{Handler_commit\ ([0-9]+)\}\ \{Handler_rollback\ ([0-9]+)\}\}} $handler_stat all handler_comm handler_roll
set outc [ expr $handler_comm + $handler_roll ]
	} else {
regexp {\{\{Com_show_status\ ([0-9]+)\}\ \{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
regexp {\{\{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
set outc [ expr $queries - $show_stat ]
	}
}
set new $outc
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
set tcsize [ llength $tcdata ]
if { $tcsize eq 0 } { 
set newtick 1 
lappend tcdata $newtick 0
lappend timedata $newtick $tstamp
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break }} 
	} else { 
if { $tcsize >= 40 } {
set tcdata [ downshift $tcdata ]
set timedata [ downshift $timedata ]
set newtick 20
} else {
set newtick [ expr {$tcsize / 2 + 1} ] 
if { $newtick eq 2 } {
set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
	}
}
lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
lappend timedata $newtick $tstamp
if { ![ isdiff $tcdata ] } {
set tcdata [ lreplace $tcdata 1 1 0 ]
}
set transval [expr {[expr {abs($new - $old)}] * $mplier}]
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
}
if { $tcsize >= 4 } { 
if { $tcsize eq 4 } {
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { $gcanv delete $ttag }} ] ] } { break }} 
}
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }} 
} else {
if { $bm eq "TPC-C" } { set gcol "orange" } else { set gcol "orange" }
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break }} 
		}
}
set old $new
set pauseval [ expr $interval * 1000 ]
for {set pausecount 0} {$pausecount <= $pauseval} {incr pausecount 1000} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
if { [ tsv::get application timeout ] } { break }
}
#catch [ subst {thread::send -async $MASTER { puts "MySQL Transaction Counter Stopped" }} ]
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
}
MSSQLServer {
set tc_threadID [thread::create {
package require tclodbc 2.5.1

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

proc read_more { MASTER mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass interval old gcanv tce ttag bm } {
set bm "TPC-C"
set logged_on 0
set timeout 0
proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } {
if {[ string match -nocase {*native*} $odbc_driver ] } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
        }
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
        } else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
        }
}
return $connection
}
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $bm eq "TPC-C" } {
set tval 60
	} else {
set tval 3600
	}
if { $interval <= 0 } { set interval 10 } 
set mplier [ expr {$tval / $interval} ]
if { $logged_on eq 0 } {
set connection [ connect_string $mssqls_server $mssqls_port $mssqls_odbc_driver $mssqls_authentication $mssqls_uid $mssqls_pass ]
if [catch {database connect tc_odbc $connection} message ] {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Connection Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "LOGON FAILED" -fill black -font {Helvetica 18} }}]
}
break
	} else {
set logged_on 1
	}
}	
#Same query used for SQL Server TPC-C and TPC-H
if {[catch {set tc_trans [ tc_odbc "select cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'" ]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Execute Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL EXECUTE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { tc_odbc disconnect }
break
} else {
if { $bm eq "TPC-C" || $bm eq "TPC-H" } {
if { [ string is integer -strict $tc_trans ] } {
set outc $tc_trans
        } else {
#SQL Server returned invalid trnasacount data setting to 0
set outc 0
		}
	}
}
set new $outc
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
set tcsize [ llength $tcdata ]
if { $tcsize eq 0 } { 
set newtick 1 
lappend tcdata $newtick 0
lappend timedata $newtick $tstamp
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break }} 
	} else { 
if { $tcsize >= 40 } {
set tcdata [ downshift $tcdata ]
set timedata [ downshift $timedata ]
set newtick 20
} else {
set newtick [ expr {$tcsize / 2 + 1} ] 
if { $newtick eq 2 } {
set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
	}
}
lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
lappend timedata $newtick $tstamp
if { ![ isdiff $tcdata ] } {
set tcdata [ lreplace $tcdata 1 1 0 ]
}
set transval [expr {[expr {abs($new - $old)}] * $mplier}]
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
}
if { $tcsize >= 4 } { 
if { $tcsize eq 4 } {
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { $gcanv delete $ttag }} ] ] } { break }} 
}
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }} 
} else {
if { $bm eq "TPC-C" } { set gcol "yellow" } else { set gcol "yellow" }
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break }} 
		}
}
set old $new
set pauseval [ expr $interval * 1000 ]
for {set pausecount 0} {$pausecount <= $pauseval} {incr pausecount 1000} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
if { [ tsv::get application timeout ] } { break }
}
#catch [ subst {thread::send -async $MASTER { puts "SQL Server Transaction Counter Stopped" }} ]
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
}
PostgreSQL {
set tc_threadID [thread::create {
package require Pgtcl

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

proc read_more { MASTER pg_host pg_port pg_superuser pg_superuserpass pg_defaultdbase interval old gcanv tce ttag bm } {
global tcl_platform
set logged_on 0
set timeout 0
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $bm eq "TPC-C" } {
set tval 60
	} else {
set tval 3600
	}
if { $interval <= 0 } { set interval 10 } 
set mplier [ expr {$tval / $interval} ]
if { $logged_on eq 0 } {
if {[catch {set tc_lda [pg_connect -conninfo [list host = $pg_host port = $pg_port user = $pg_superuser password = $pg_superuserpass dbname = $pg_defaultdbase ]]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Connection Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "LOGON FAILED" -fill black -font {Helvetica 18} }}]
}
break
	} else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set tc_lda [pg_connect -conninfo [list host = $pg_host port = $pg_port user = $pg_superuser password = $pg_superuserpass dbname = $pg_defaultdbase ]]
set logged_on 1
		}
	}
}	
#xact_commit in postgres also includes queries
if {[catch {pg_select $tc_lda "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr { set pgcnt $tx_arr(sum) }}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Execute Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL EXECUTE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { pg_disconnect $tc_lda }
break
} else {
if { [ string is integer -strict $pgcnt ] } {
set outc $pgcnt
        } else {
set outc 0
	}
}
set new $outc
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
set tcsize [ llength $tcdata ]
if { $tcsize eq 0 } { 
set newtick 1 
lappend tcdata $newtick 0
lappend timedata $newtick $tstamp
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break }} 
	} else { 
if { $tcsize >= 40 } {
set tcdata [ downshift $tcdata ]
set timedata [ downshift $timedata ]
set newtick 20
} else {
set newtick [ expr {$tcsize / 2 + 1} ] 
if { $newtick eq 2 } {
set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
	}
}
lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
lappend timedata $newtick $tstamp
if { ![ isdiff $tcdata ] } {
set tcdata [ lreplace $tcdata 1 1 0 ]
}
set transval [expr {[expr {abs($new - $old)}] * $mplier}]
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
}
if { $tcsize >= 4 } { 
if { $tcsize eq 4 } {
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { $gcanv delete $ttag }} ] ] } { break }} 
}
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }} 
} else {
if { $bm eq "TPC-C" } { set gcol "blue" } else { set gcol "blue" }
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break }} 
		}
}
set old $new
set pauseval [ expr $interval * 1000 ]
for {set pausecount 0} {$pausecount <= $pauseval} {incr pausecount 1000} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
if { [ tsv::get application timeout ] } { break }
}
#catch [ subst {thread::send -async $MASTER { puts "PostgreSQL Transaction Counter Stopped" }} ]
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
}
Redis {
set tc_threadID [thread::create {
package require redis

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

proc read_more { MASTER redis_host redis_port interval old gcanv tce ttag bm } {
set logged_on 0
set timeout 0
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $bm eq "TPC-C" } {
set sqc "info" 
set tval 60
	} else {
#No current TPC-H workload for Redis
set tval 3600
	}
if { $interval <= 0 } { set interval 10 } 
set mplier [ expr {$tval / $interval} ]
if { $logged_on eq 0 } {
if {[catch {set redis [redis $redis_host $redis_port ]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Connection Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "LOGON FAILED" -fill black -font {Helvetica 18} }}]
}
break
	} else {
set logged_on 1
	}
}	
if {[catch {set redisinfo [ $redis $sqc ]}]} {
if { $timeout eq 0 } {
eval [subst {thread::send -async $MASTER {::myerrorproc "Transaction Counter" "Transaction Count SQL Execute Failed" }}]
eval [subst {thread::send -async $MASTER { $gcanv delete $ttag }}]
eval [subst {thread::send -async $MASTER { .ed_mainFrame.tc.g create text 270 100 -text "SQL EXECUTE FAILED" -fill black -font {Helvetica 18} }}]
}
catch { $redis QUIT }
break
} else {
if { $bm eq "TPC-C" } {
regexp {total_commands_processed:([0-9]+)} $redisinfo all outc
	} else {
#No current TPC-H workload for Redis
	}
}
set new $outc
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
set tcsize [ llength $tcdata ]
if { $tcsize eq 0 } { 
set newtick 1 
lappend tcdata $newtick 0
lappend timedata $newtick $tstamp
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break }} 
	} else { 
if { $tcsize >= 40 } {
set tcdata [ downshift $tcdata ]
set timedata [ downshift $timedata ]
set newtick 20
} else {
set newtick [ expr {$tcsize / 2 + 1} ] 
if { $newtick eq 2 } {
set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
	}
}
lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
lappend timedata $newtick $tstamp
if { ![ isdiff $tcdata ] } {
set tcdata [ lreplace $tcdata 1 1 0 ]
}
set transval [expr {[expr {abs($new - $old)}] * $mplier}]
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
}
if { $tcsize >= 4 } { 
if { $tcsize eq 4 } {
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { $gcanv delete $ttag }} ] ] } { break }} 
}
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { $timeout eq 0 } {
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }} 
} else {
if { $bm eq "TPC-C" } { set gcol "red" } else { set gcol "red" }
if { $timeout eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break }} 
		}
}
set old $new
set pauseval [ expr $interval * 1000 ]
for {set pausecount 0} {$pausecount <= $pauseval} {incr pausecount 1000} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
if { [ tsv::get application timeout ] } { break }
}
#catch [ subst {thread::send -async $MASTER { puts "Redis Transaction Counter Stopped" }} ]
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
}
default {
puts "Invalid Database Specified for Transaction Counter"
        }
}
switch $rdbms {
Oracle {
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $connectstr $interval $old .ed_mainFrame.tc.g tce $ttag $rac $bm $tpcc_tt_compat $tpch_tt_compat }}]
}
MySQL {
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $mysql_host $mysql_port $mysql_user $mysql_pass $mysql_tpch_user $mysql_tpch_pass $interval $old .ed_mainFrame.tc.g tce $ttag $bm }}]
}
MSSQLServer {
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread {$mssqls_server} $mssqls_port $mssqls_authentication {$mssqls_odbc_driver} $mssqls_uid $mssqls_pass $interval $old .ed_mainFrame.tc.g tce $ttag $bm }}]
}
PostgreSQL {
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $pg_host $pg_port $pg_superuser $pg_superuserpass $pg_defaultdbase $interval $old .ed_mainFrame.tc.g tce $ttag $bm }}]
}
Redis {
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $redis_host $redis_port $interval $old .ed_mainFrame.tc.g tce $ttag $bm }}]
}
default {
puts "Invalid Database Specified for Transaction Counter"
        }
    }
}

proc ed_kill_transcount {args} {
   global _ED
   tsv::set application timeout 1
   ed_status_message -show "... Stopping Transaction Counter ..."
   update
   ed_transcount_button
   update
if {[winfo exists .ed_mainFrame.tc]} {
destroy .ed_mainFrame.tc.buff ;
destroy .ed_mainFrame.tc.c ;
destroy .ed_mainFrame.tc.buff2 ;
destroy .ed_mainFrame.tc.g ;
	}
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
if ![ string match "*.ed_mainFrame.tc*" [ .ed_mainFrame.notebook tabs ]] {
#transaction counter has been detached so reattach before disabling
Attach .ed_mainFrame.notebook .ed_mainFrame.tc 2
}
.ed_mainFrame.notebook tab .ed_mainFrame.tc -state disabled
ed_status_message -finish "Transaction Counter Stopped"
}

proc post_kill_transcount_cleanup {} {
global tc_threadID
unset -nocomplain tc_threadID
tsv::set application timeout 2
 }

