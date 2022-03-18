proc tcount_db2 {bm interval masterthread} {
global tc_threadID
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
	        set library [ dict get $dbdict db2 library ]
	} else { set library "db2tcl" }
#Setup Transaction Counter Thread
set tc_threadID [thread::create {
proc read_more { MASTER library db2_user db2_pass db2_dbase db2_tpch_user db2_tpch_pass db2_tpch_dbase interval old tce bm } {
set timeout 0
set iconflag 0
if { $interval <= 0 } { set interval 10 } 
set gcol "green"
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
if { $bm eq "TPC-C" } {
set sqc "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary"
set tmp_db2_user $db2_user
set tmp_db2_pass $db2_pass
set tmp_db2_dbase $db2_dbase
set tval 60
        } else {
set sqc "select act_completed_total from sysibmadm.mon_db_summary"
set tmp_db2_user $db2_tpch_user
set tmp_db2_pass $db2_tpch_pass
set tmp_db2_dbase $db2_tpch_dbase
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
if {[catch {set db_handle [db2_connect $tmp_db2_dbase $tmp_db2_user $tmp_db2_pass]} message]} {
tsv::set application tc_errmsg "connection failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
     } 
#Enter loop until stop button pressed
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $timeout != 0 } { break }
if {[catch { set stmnt_handle1 [ db2_select_direct $db_handle $sqc ]} message]} {
tsv::set application tc_errmsg "sql failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { db2_disconnect $db_handle }
break
} 
if {[catch {set outc [db2_fetchrow $stmnt_handle1 ]} message]} {
tsv::set application tc_errmsg "sql fetch failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { db2_disconnect $db_handle }
break
} 
if {[catch {db2_finish $stmnt_handle1} message]} {
tsv::set application tc_errmsg "handle close failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { db2_disconnect $db_handle }
break
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
upvar #0 configdb2 configdb2
setlocaltcountvars $configdb2 1
set old 0
#Call Transaction Counter to start read_more loop
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $library $db2_user $db2_pass $db2_dbase $db2_tpch_user $db2_tpch_pass $db2_tpch_dbase $interval $old tce $bm }}]
} 
