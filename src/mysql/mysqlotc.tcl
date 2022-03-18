proc tcount_mysql {bm interval masterthread} {
global tc_threadID
upvar #0 dbdict dbdict
if {[dict exists $dbdict mysql library ]} {
        set library [ dict get $dbdict mysql library ]
} else { set library "mysqltcl" }
#Setup Transaction Counter Thread
set tc_threadID [thread::create {
proc read_more { MASTER library mysql_host mysql_port mysql_socket mysql_user mysql_pass mysql_tpch_user mysql_tpch_pass interval old tce bm } {
set timeout 0
set iconflag 0
if { $interval <= 0 } { set interval 10 } 
set gcol "orange"
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
if { $bm eq "TPC-C" } {
set sqc "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'"
set tmp_mysql_user $mysql_user
set tmp_mysql_pass $mysql_pass
set tval 60
	} else {
set sqc "show global status where Variable_name = 'Queries' or Variable_name = 'Com_show_status'"
set tmp_mysql_user $mysql_tpch_user
set tmp_mysql_pass $mysql_tpch_pass
set tval 3600
	}
set mplier [ expr {$tval / $interval} ]
if {[catch {package require $library} message]} {
tsv::set application tc_errmsg "failed to load library $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
}
if [catch {::tcl::tm::path add modules} message] {
tsv::set application tc_errmsg "failed to find modules $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
}
if [catch {package require tcountcommon} message ] {
tsv::set application tc_errmsg "failed to load common transaction counter functions $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
} else {
namespace import tcountcommon::*
}
if { ![string match windows $::tcl_platform(platform)] && ($mysql_host eq "127.0.0.1" || [ string tolower $mysql_host ] eq "localhost") && [ string tolower $mysql_socket ] != "null" } {
if [catch {mysqlconnect -socket $mysql_socket -user $tmp_mysql_user -password $tmp_mysql_pass} mysql_handler] {
tsv::set application tc_errmsg $mysql_handler
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
	} 
} else {
if [catch {mysqlconnect -host $mysql_host -port $mysql_port -user $tmp_mysql_user -password $tmp_mysql_pass} mysql_handler] {
tsv::set application tc_errmsg $mysql_handler
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
	} 
}
#Enter loop until stop button pressed
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $timeout != 0 } { break }

if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler $sqc -list ] ]} message]} {
tsv::set application tc_errmsg "sql failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { mysqlclose $mysql_handler }
break
} else {
if { $bm eq "TPC-C" } {
regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
set outc [ expr $com_comm + $com_roll ]
        } else {
regexp {\{\{Com_show_status\ ([0-9]+)\}\ \{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
regexp {\{\{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
set outc [ expr $queries - $show_stat ]
        }
}
set new $outc
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
if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }} 
if { $tcsize >= 4 } { 
if { $iconflag eq 0 } {
if { [ catch [ subst {thread::send -async $MASTER { .ed_mainFrame.tc.g delete "all" }} ] ] } { break }
set iconflag 1
        }
if { [ zeroes $tcdata ] eq 0 } {
set tcdata {}
set timedata {}
if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }
} else {
if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break } 
}
}
set old $new
set pauseval $interval
for {set pausecount $pauseval} {$pausecount > 0} {incr pausecount -1} {
if { [ tsv::get application timeout ] } { break } else { after 1000 }
}
}
eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
thread::release
}
thread::wait 
}]
#Setup Transaction Counter Connection Variables
upvar #0 configmysql configmysql
setlocaltcountvars $configmysql 1
set old 0
#Call Transaction Counter to start read_more loop
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $library $mysql_host $mysql_port $mysql_socket $mysql_user $mysql_pass $mysql_tpch_user $mysql_tpch_pass $interval $old tce $bm }}]
} 
