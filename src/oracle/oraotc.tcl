proc tcount_ora {bm interval masterthread} {
global tc_threadID
upvar #0 dbdict dbdict
if {[dict exists $dbdict oracle library ]} {
set library [ dict get $dbdict oracle library ]
} else { set library "Oratcl" }
#Setup Transaction Counter Thread
set tc_threadID [thread::create {
#STANDARD SQL
proc standsql { curn sql } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
error "SQL statement failed: $sql : $message"
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
	}
return $ftch
    }
}

proc read_more { MASTER library connectstr interval old tce rac bm tpcc_tt_compat tpch_tt_compat } {
set timeout 0
set iconflag 0
if { $interval <= 0 } { set interval 10 } 
set gcol "red"
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
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
if {[catch {set ldc [oralogon $connectstr]} message]} {
tsv::set application tc_errmsg "connection failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
	} else {
if {[catch { set curc [ oraopen $ldc ]} message]} {
tsv::set application tc_errmsg "cursor open failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { oralogoff $ldc }
thread::release
return
}
if {[catch {oraparse $curc $sqc} message]} {
tsv::set application tc_errmsg "sql parse failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { oralogoff $ldc }
thread::release
return
		}
	}
#Enter loop until stop button pressed
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $timeout != 0 } { break }
if {[catch {set outc [standsql $curc $sqc]} message]} {
tsv::set application tc_errmsg "sql failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch {oralogoff $ldc}
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
upvar #0 configoracle configoracle
setlocaltcountvars $configoracle 0
variable tpcc_tt_compat tpch_tt_compat
if {[dict exists $configoracle tpcc tpcc_tt_compat ]} {
set tpcc_tt_compat [ dict get $configoracle tpcc tpcc_tt_compat ]
        } else { set tpcc_tt_compat "false" }
if {[dict exists $configoracle tpch tpch_tt_compat ]} {
set tpch_tt_compat [ dict get $configoracle tpch tpch_tt_compat ]
        } else { set tpch_tt_compat "false" }
set connectstr $system_user/$system_password@$instance
set old 0
#Call Transaction Counter to start read_more loop
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $library $connectstr $interval $old tce $rac $bm $tpcc_tt_compat $tpch_tt_compat }}]
} 
