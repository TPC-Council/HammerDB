#########################################################################
# HammerDB
# Copyright (C) HammerDB Ltd
# Hosted by the TPC-Council
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#########################################################################
#
# quackotc.tcl - transaction-counter thread for the Quack (sqlxtc)
# database.
#
# sqlxtc exposes no server-side commit statistic (there is no
# equivalent of MySQL Com_commit or the PostgreSQL pg_stat_database
# view), so the Quack driver counts committed business transactions
# client-side in the shared tsv variable "application quack_txn".  The
# transaction-counter graph simply reads that counter; this keeps the
# counter accurate without requiring any server support.
#
proc tcount_quack {bm interval masterthread} {
    global tc_threadID
    set tc_threadID [thread::create {
        proc read_more { MASTER interval old bm } {
            set timeout 0
            if { $interval <= 0 } { set interval 10 }
            set gcol "yellow"
            if { ![ info exists tcdata ] } { set tcdata {} }
            if { ![ info exists timedata ] } { set timedata {} }
            if { $bm eq "TPC-C" } { set tval 60 } else { set tval 3600 }
            set mplier [ expr {$tval / $interval} ]
            if [catch {package require tcountcommon} message ] {
                tsv::set application tc_errmsg "failed to load common transaction counter functions $message"
                eval [subst {thread::send $MASTER show_tc_errmsg}]
                thread::release
                return
            } else {
                namespace import tcountcommon::*
            }
            while { $timeout eq 0 } {
                set timeout [ tsv::get application timeout ]
                if { $timeout != 0 } { break }
                if { [ tsv::exists application quack_txn ] } {
                    set outc [ tsv::get application quack_txn ]
                } else {
                    set outc 0
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
                    if { ![ isdiff $tcdata ] } { set tcdata [ lreplace $tcdata 1 1 0 ] }
                    set transval [expr {[expr {abs($new - $old)}] * $mplier}]
                    if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }
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
    set old 0
    catch {eval [ subst {thread::send $tc_threadID {lappend ::auto_path [zipfs root]app/lib}}]}
    catch {eval [ subst {thread::send $tc_threadID {::tcl::tm::path add [zipfs root]app/modules modules}}]}
    eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $interval $old $bm }}]
}
