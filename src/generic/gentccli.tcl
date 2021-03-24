#Generic CLI Transaction Counter
proc .ed_mainFrame.tc.g {args} {;}
proc tce {} {;}

proc showLCD {number} {
global bm rdbms
if { $bm eq "TPC-C" } { set metric "tpm" } else { set metric "qph" }
putscli "$number $rdbms $metric"
write_to_transcount_log $number $rdbms $metric
return
}

proc transcount { } {
global tcl_platform masterthread tc_threadID bm rdbms afval tc_flog
upvar #0 genericdict genericdict
tsv::set application tc_errmsg ""
dict with genericdict { dict with transaction_counter {
set interval $tc_refresh_rate
set tclog $tc_log_to_temp
set uniquelog $tc_unique_log_name
}}
if { $tclog } { 
set tc_logfile [ open_transcount_log cli $uniquelog ] 
if { $tc_logfile != "notclog" } {
set tc_flog $tc_logfile
} else {
set tc_flog "notclog"
}
}
set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
tk_messageBox -icon warning -message "Transaction Counter Stopping"
return 1
	}
unset -nocomplain tc_threadID
}
tsv::set application timeout 0
if {  ![ info exists bm ] } { set bm "TPC-C" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}

set old 0
set tcdata {}
set timedata {}

#Call Database specific transaction counter
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } { 
set prefix [ dict get $dbdict $key prefix ]
set command [ concat [subst {tcount_$prefix $bm $interval $masterthread}]]
eval $command 
break
	}
    }
if { [ info exists tc_threadID ] } {
tsv::set application thecount $tc_threadID
putscli "Transaction Counter Started"
	} else {
putscli "Transaction Counter Failed to Start"
	}
}

proc ed_kill_transcount {args} {
   global _ED
   tsv::set application timeout 1
   putscli "Stopping Transaction Counter"
   close_transcount_log cli
}

proc show_tc_errmsg {} {
set tc_errmsg [ tsv::get application tc_errmsg ]
if { $tc_errmsg != "" } {
if [catch {set joinedmsg [ join $tc_errmsg ]} message ] {
#error in join show unjoined message
putscli "Transaction Counter Error: $tc_errmsg"
} else {
#show joined message
putscli "Transaction Counter Error: $joinedmsg"
	}
	} else {
#message is empty
putscli "Transaction Counter Error"
	}
#error message is always followed by thread release before loop enter
#so remove tc_threadID to prevent false positive on startup
post_kill_transcount_cleanup
}

proc threadnames_without_tcthread {} {
global tc_threadID
set thlist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $thlist $tc_threadID ]
if { $idx != -1 } {
set thlist [ lreplace $thlist $idx $idx ]
return $thlist
        }
}
return $thlist
}
