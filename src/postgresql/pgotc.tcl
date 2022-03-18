proc tcount_pg {bm interval masterthread} {
global tc_threadID
upvar #0 dbdict dbdict
if {[dict exists $dbdict postgresql library ]} {
        set library [ dict get $dbdict postgresql library ]
} else { set library "Pgtcl" }
#Setup Transaction Counter Thread
set tc_threadID [thread::create {
proc ConnectToPostgres { host port sslmode user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]} message]} {
set lda "connection failed:$message"
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}
proc read_more { MASTER library pg_host pg_port pg_sslmode pg_superuser pg_superuserpass pg_defaultdbase pg_tpch_superuser pg_tpch_superuserpass pg_tpch_defaultdbase interval old tce bm } {
set timeout 0
set iconflag 0
if { $interval <= 0 } { set interval 10 } 
set gcol "blue"
if { ![ info exists tcdata ] } { set tcdata {} }
if { ![ info exists timedata ] } { set timedata {} }
if { $bm eq "TPC-C" } { 
set tmp_pg_su $pg_superuser
set tmp_pg_supass $pg_superuserpass	
set tmp_pg_defdb $pg_defaultdbase	
	set tval 60 
	} else { 
set tmp_pg_su $pg_tpch_superuser	
set tmp_pg_supass $pg_tpch_superuserpass	
set tmp_pg_defdb $pg_tpch_defaultdbase	
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
set tc_lda [ ConnectToPostgres $pg_host $pg_port $pg_sslmode $tmp_pg_su $tmp_pg_supass $tmp_pg_defdb ]
if { [string match {*connection*} $tc_lda] } {
tsv::set application tc_errmsg $tc_lda
eval [subst {thread::send $MASTER show_tc_errmsg}]
thread::release
return
        } 
#Enter loop until stop button pressed
while { $timeout eq 0 } {
set timeout [ tsv::get application timeout ]
if { $timeout != 0 } { break }
if {[catch {pg_select $tc_lda "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr { set pgcnt $tx_arr(sum) }} message]} {
tsv::set application tc_errmsg "sql failed $message"
eval [subst {thread::send $MASTER show_tc_errmsg}]
catch { pg_disconnect $tc_lda }
break
} else {
if { [ string is entier -strict $pgcnt ] } {
set outc $pgcnt
        } else {
set outc 0
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
upvar #0 configpostgresql configpostgresql
setlocaltcountvars $configpostgresql 1
set old 0
#Call Transaction Counter to start read_more loop
eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $library $pg_host $pg_port $pg_sslmode $pg_superuser $pg_superuserpass $pg_defaultdbase $pg_tpch_superuser $pg_tpch_superuserpass $pg_tpch_defaultdbase $interval $old tce $bm }}] 
} 
