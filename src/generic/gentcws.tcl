#Generic CLI Transaction Counter
proc .ed_mainFrame.tc.g {args} {;}
proc tce {} {;}

proc showLCD {number} {
global bm rdbms jobid
if { $bm eq "TPC-C" } { set metric "tpm" } else { set metric "qph" }
#TCOUNT may run without a job so only insert TCOUNT DATA into Database if a job is running
#If no job is running no data is inserted, by using global var once job is created data is inserted
#debug output by uncomment next line 
#putscli "$number $rdbms $metric"
if { $jobid != "" } {
hdb eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,$number,$metric)}
	}
}

proc transcount { } {
global tcl_platform masterthread tc_threadID bm rdbms afval tc_flog ws_port
upvar #0 genericdict genericdict
tsv::set application tc_errmsg ""
#Only set interval in web service
dict with genericdict { dict with transaction_counter {
set interval $tc_refresh_rate
}}
set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
dict set jsondict success message "Transaction Counter Stopping"
wapp-2-json 2 $jsondict
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
dict set jsondict success message "Transaction Counter Thread Started"
wapp-2-json 2 $jsondict
return 0
	} else {
dict set jsondict error message "Transaction Counter Failed to Start"
wapp-2-json 2 $jsondict
return 1
	}
}

proc ed_kill_transcount {args} {
global _ED ws_port
tsv::set application timeout 1
dict set jsondict success message "Stopping Transaction Counter"
wapp-2-json 2 $jsondict
return
}

proc show_tc_errmsg {} {
global jobid
if { ![ info exists jobid ] } { set jobid 0 }
set tc_errmsg [ tsv::get application tc_errmsg ]
if { $tc_errmsg != "" } {
if [catch {set joinedmsg [ join $tc_errmsg ]} message ] {
#error in join show unjoined message
putscli [ subst {{"error": {"message": "Transaction Counter Error: $tc_errmsg"}}} ]
hdb eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,0,$tc_errmsg)}
} else {
#show joined message
putscli [ subst {{"error": {"message": "Transaction Counter Error: $joinedmsg"}}} ]
hdb eval {INSERT INTO JOBTCOUNT(jobid,counter,metric) VALUES($jobid,0,$joinedmsg)}
        }
        } else {
#message is empty
putscli {"error": {"message": "Transaction Counter Error"}}
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
