proc check_ap_threads {} {
global tc_threadID
set thlist [ thread::names ]
set thlen [ llength $thlist ] 
if { $thlen > 1 } {
return 1
       } else {
return 0
       }
}

proc start_autopilot {} {
global apduration apsequence maxvuser aptime
if { [ check_ap_threads ] } { 
tk_messageBox -icon error -message "Cannot Enable Autopilot with Virtual Users or Transaction Counter still active" 
return 1
	}
if {  [ info exists apmode ] } { ; } else { set apmode "disabled" }
if {  [ info exists apduration ] } { ; } else { set apduration 10 }
if {  [ info exists apsequence ] } { ; } else { set apsequence "2 3 5 9 13 17 21 25" }
foreach btn {menuframe.tpcc buttons.boxes buttons.pencil buttons.lvuser} {
set Name .ed_mainFrame.$btn
$Name configure -state disabled
}
set Name .ed_mainFrame.treeframe.treeview  
$Name state disabled
ed_stop_autopilot
set aptime 00:00:00
.ed_mainFrame.notebook tab .ed_mainFrame.ap  -state normal
.ed_mainFrame.notebook select .ed_mainFrame.ap
pack [ canvas .ed_mainFrame.ap.canv -highlightthickness 0 -background white ] -fill both -expand 1
set Name .ed_mainFrame.ap.canv
frame $Name.b -background white
label  $Name.b.time -textvar aptime -width 12 -bg white -fg black -font {Helvetica 12 bold}
pack $Name.b.time -side right -fill y -padx 10
set lenp [ llength $apsequence ]
ttk::progressbar $Name.b.p -orient horizontal -mode determinate -maximum $lenp
pack $Name.b.p -side left -fill x -expand 1 -padx 10
pack $Name.b -side top -fill both -expand 1 -pady 5 -padx 5 -anchor e
frame $Name.a -background white
ttk::scrollbar $Name.a.y -command "$Name.a.t yview"
text $Name.a.t -yscrollc "$Name.a.y set" -wrap word -padx 2 -pady 3 -highlightthickness 0 -borderwidth 0 -takefocus 0 -background white -font {Arial 10}
pack $Name.a.y -side right -fill y
pack $Name.a.t -side top -fill both -expand 1 -pady 5 -padx 15 -anchor e
pack $Name.a -side top -fill both -expand 1

proc wait_for_exit { ap_chk time0 apduration apseqcp } {
global maxvuser
set Name .ed_mainFrame.ap.canv
if { [ check_ap_threads ] } {
incr ap_chk
 if { $ap_chk eq 3 } {
if {[winfo exists $Name]} {
$Name.a.t insert end  "Virtual Users remain active in background, waiting for exit\n" 
.ed_mainFrame.ap.canv.a.t see end
		} else {
	return
		}
	}
 if { ![ expr {$ap_chk % 10} ] } {
if {[winfo exists $Name]} {
$Name.a.t insert end  "Waiting for Virtual Users to exit...\n"
.ed_mainFrame.ap.canv.a.t see end
		} else {
	return
		} 
	}
if { $ap_chk eq 21600 } {
if {[winfo exists $Name]} {
$Name.a.t insert end  "Autopilot Error: Virtual Users failed to exit in a 12 hour period\n"
.ed_mainFrame.ap.canv.a.t see end
		}
return
	}
after 2000 wait_for_exit $ap_chk $time0 $apduration [ list $apseqcp ]
	} else {
if {[winfo exists $Name]} {
$Name.a.t insert end  "$maxvuser Virtual User Test started at [clock format [clock seconds] -format %T_%D]\n"
.ed_mainFrame.ap.canv.a.t see end
		}
set butteninvdis .ed_mainFrame.buttons.lvuser
foreach action {normal invoke disabled} {
switch $action {
normal { $butteninvdis configure -state normal }
invoke { $butteninvdis $action }
disabled { $butteninvdis configure -state disabled }
	}
}
set butteninvdis .ed_mainFrame.buttons.runworld
$butteninvdis configure -state normal
$butteninvdis invoke
.ed_mainFrame.notebook select .ed_mainFrame.ap
.ed_mainFrame.ap.canv.a.t see end
set time0 [clock seconds]
after 1000 every $time0 $apduration [ list $apseqcp ]
return
	}
}
proc every { time0 apduration apseqcp } { 
global aptime maxvuser opmode
if { $aptime eq "autopilot_quit" } {
after cancel every
return
	}
set m [ Time $time0 ]
set Name .ed_mainFrame.ap.canv
if { $m >= [ expr $apduration * 60 ] } { 
if {[winfo exists $Name]} {
$Name.a.t insert end  "$maxvuser Virtual User Test completed at [clock format [clock seconds] -format %T_%D]\n"
.ed_mainFrame.ap.canv.a.t see end
		}
set aptime 00:00:00
$Name.b.p step
set butteninvdis .ed_mainFrame.buttons.lvuser
foreach action {normal invoke disabled} {
switch $action {
normal { $butteninvdis configure -state normal }
invoke { $butteninvdis $action }
disabled { $butteninvdis configure -state disabled }
	}
}
set apseqcp {*}$apseqcp
if { [ llength $apseqcp ] >=1 } { 
set maxvuser [lindex $apseqcp 0] 
remote_command [ concat max_ops $maxvuser ]
set apseqcp [ list [lrange $apseqcp 1 end] ]
.ed_mainFrame.notebook select .ed_mainFrame.ap
.ed_mainFrame.ap.canv.a.t see end
if { [ check_ap_threads ] } { 
set ap_chk 0
set Name .ed_mainFrame.buttons.test
$Name configure -state disabled
set Name .ed_mainFrame.buttons.runworld
$Name configure -state disabled
wait_for_exit $ap_chk $time0 $apduration $apseqcp
return
} else {
if {[winfo exists .ed_mainFrame.ap.canv]} {
$Name.a.t insert end  "$maxvuser Virtual User Test started at [clock format [clock seconds] -format %T_%D]\n"
.ed_mainFrame.ap.canv.a.t see end
		}
set butteninvdis .ed_mainFrame.buttons.lvuser
foreach action {normal invoke disabled} {
switch $action {
normal { $butteninvdis configure -state normal }
invoke { $butteninvdis $action }
disabled { $butteninvdis configure -state disabled }
	}
}
set butteninvdis .ed_mainFrame.buttons.runworld
$butteninvdis invoke
.ed_mainFrame.notebook select .ed_mainFrame.ap
.ed_mainFrame.ap.canv.a.t see end
set time0 [clock seconds]
	}
set m [ Time $time0 ]
after 1000 every $time0 $apduration [ list $apseqcp ] 
		} else {
.ed_mainFrame.notebook select .ed_mainFrame.ap
.ed_mainFrame.ap.canv.a.t see end
set aptime 00:00:00
$Name.b.p state disabled
if {[winfo exists $Name]} {
$Name.a.t insert end  "Autopilot Sequence ended at [clock format [clock seconds] -format %T_%D]\n"
.ed_mainFrame.ap.canv.a.t see end
			}
return
		}
	} else {
after 1000 every $time0 $apduration [ list $apseqcp ]
	}
}

proc Time { time0 } {
global aptime
set m [expr {[clock seconds] - $time0}]
set aptime [format %2.2d:%2.2d:%2.2d \
[expr {$m/3600}] [expr {$m/60}] [expr {($m)%60}]]
return $m;
 }

proc Start { apduration apsequence } {
global maxvuser opmode
set apseqcp $apsequence
set maxvuser [lindex $apseqcp 0] 
remote_command [ concat max_ops $maxvuser ]
set apseqcp [lrange $apseqcp 1 end]
set Name .ed_mainFrame.ap.canv
if {[winfo exists $Name]} {
$Name.a.t insert end  "Autopilot Sequence $apsequence started at [clock format [clock seconds] -format %T_%D]\n"
$Name.a.t insert end  "$maxvuser Virtual User Test started at [clock format [clock seconds] -format %T_%D]\n"
.ed_mainFrame.ap.canv.a.t see end
	}
set butteninvdis .ed_mainFrame.buttons.lvuser
foreach action {normal invoke disabled} {
switch $action {
normal { $butteninvdis configure -state normal }
invoke { $butteninvdis $action }
disabled { $butteninvdis configure -state disabled }
	}
}
set butteninvdis .ed_mainFrame.buttons.runworld
$butteninvdis invoke
.ed_mainFrame.notebook select .ed_mainFrame.ap
.ed_mainFrame.ap.canv.a.t see end
every [clock seconds] $apduration [ list $apseqcp ]
	}
Start $apduration $apsequence
}

proc ed_kill_autopilot {args} {
   global _ED aptime
   tsv::set application abort 1
   ed_status_message -show "... Stopping Autopilot ..."
   ed_autopilot_button
	set aptime "autopilot_quit"
   update
if {[winfo exists .ed_mainFrame.ap]} {
destroy .ed_mainFrame.ap.canv;
	}
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
.ed_mainFrame.notebook tab .ed_mainFrame.ap -state disabled
foreach btn {menuframe.tpcc buttons.boxes buttons.pencil buttons.lvuser} {
set Name .ed_mainFrame.$btn
$Name configure -state normal
}
set Name .ed_mainFrame.treeframe.treeview  
$Name state !disabled
ed_status_message -finish "Autopilot Stopped"
}

proc switch_mode { opmode hostname id masterlist } {
set Name .ed_mainFrame.buttons.distribute
switch $opmode {
"Local" { puts -nonewline "Setting Local Mode : "
set chanlist [ lindex [ ::comm channels ] end ]
switch -- $chanlist {
::Slave {
set slaveid [ Slave self ]
set slavehost [ info hostname ]
if { $masterlist eq "masterclose" } {
unset opmode; upvar 1 opmode opmode
set opmode "Local"
puts "Master has closed down"
} else {
if { [catch {Slave send "$id $hostname" "puts \"Slave $slaveid $slavehost disconnected\""} b ] } {
puts "Slave disconnection failed: $b"
} else {
puts "Slave disconnected"
		}
	}
}
::Master { puts "Closing Master"
foreach f $masterlist {
puts -nonewline "Closing $f ..."
if { [catch {Master send $f switch_mode \"Local\" localhost 0 masterclose} b ] } {
puts "Failed to close $f: $b"
} else {
puts "Closed"
	}
}
unset masterlist; upvar 1 masterlist masterlist
	}
}
puts "Closing $chanlist connection"
if { [catch { $chanlist destroy } b] } {
puts "Error $b"
}
ed_status_message -perm Local
$Name configure -state disabled
update idletasks
}
"Master" {
set chanlist [ lindex [ ::comm channels ] end ]
if { $chanlist eq "::Slave" } {
puts "Closing $chanlist connection"
if { [catch { $chanlist destroy } b] } {
puts "Error $b"
	}
}
if { [catch {::comm new Master -listen 1 -local 0 -port {}} b] } {
puts "Creation Failed : $b" } else {
puts -nonewline "Setting Master Mode at id : "
puts -nonewline "[ Master self ], hostname : "
ed_status_message -perm Master
$Name configure -state active
update idletasks
puts [ info hostname ]
tk_messageBox -title "Master Mode Active" -message "Master Mode active at id : [ Master self ], hostname : [ info hostname ]"
Master hook incoming {
puts "Received a new slave connection from host $addr"
}
Master hook lost {
global masterlist
set todel [ lsearch $masterlist $id ]
if { $todel != -1 } {
puts "Lost connection to : $id because $reason"
set masterlist [ lreplace $masterlist $todel $todel ]
	}
}
Master hook eval {
upvar 1 opmode opmode
global masterlist
if {[regexp {\"([0-9]+)\W([[:alnum:],[:punct:]]+)\"} $buffer all id host]} {
lappend masterlist "$id $host"
puts "New slave joined : $masterlist"
} else {
if {[regexp {\"Slave ([0-9]+)\W([[:alnum:],[:punct:]]+) disconnected\"} $buffer all id host]} {
set todel [ lsearch -exact $masterlist "$id $host" ]
if { $todel != -1 } {
set masterlist [ lreplace $masterlist $todel $todel ]
					}
				}
			}
		}
	}
}
"Slave" {
set chanlist [ lindex [ ::comm channels ] end ]
if { $chanlist eq "::Master" } {
puts "Closing $chanlist connection"
if { [catch { $chanlist destroy } b] } {
puts "Error $b"
	}
}
if { [catch {::comm new Slave -listen 1 -local 0 -port {}} b] } {
puts "Creation Failed : $b" } else {
ed_status_message -perm Slave
$Name configure -state disabled
puts -nonewline "Setting Slave Mode at id : "
update idletasks
Slave hook lost {
global opmode
if { $opmode eq "Slave" } {
if { [ llength [ ::comm interps ]] > 1 } {
if { [catch { Slave destroy } b] } {
;
} else {
puts "slave lost connection : $reason"
set opmode "Local"
ed_status_message -perm Local
$Name configure -state disabled
update idletasks
		}
	  }	
    }
}
set slaveid [ Slave self ]
set slavehost [ info hostname ]
puts "$slaveid, hostname : $slavehost"
puts -nonewline "Slave connecting to $hostname $id : "
if { [catch {::comm connect "$id $hostname"} b] } {
puts "Connection Failed : $b"
switch_mode "Local" $slavehost $slaveid $masterlist
set opmode "Local"
} else {
puts "Connection suceeded"
if { [catch {::comm send "$id $hostname" "catch {Master connect \"$slaveid $slavehost\"} "} b] } {
puts "Master connect back failed: $b\nCanonical hostname [ info hostname ] must be used"
switch_mode "Local" $slavehost $slaveid $masterlist
set opmode "Local"
} else {
puts "Master call back successful"
				}
			}
		}
	}
}
destroy .mode
return $opmode
}

proc distribute { } {
global masterlist
global _ED
ed_edit_commit
set flbuff $_ED(package)
foreach f $masterlist {
puts -nonewline "Distributing to $f ..."
if { [catch {
Master send $f set _ED(package) [ concat [ list $flbuff\n]]
Master send $f update
Master send $f set _ED(temppackage) [ concat [ list $flbuff\n]]
Master send $f ed_edit } b] } {
puts "Failed $b"
} else {
puts "Succeeded"
		}
	}
}

proc remote_command { command } {
upvar 1 opmode opmode
global masterlist
if { $opmode eq "Master" } {
foreach f $masterlist {
if { [catch { Master send -async $f eval $command } b] } {
puts "Failed $b"
} else { ; }
		}
	}
}

proc max_ops {maxvuser_m
} {
global maxvuser
set maxvuser $maxvuser_m
}

proc auto_ops {suppo_m optlog_m
} {
global suppo
global optlog

set suppo $suppo_m
set optlog $optlog_m
}

proc vuser_slave_ops {maxvuser_m delayms_m conpause_m ntimes_m suppo_m optlog_m 
} {
global maxvuser
global delayms
global conpause
global ntimes
global suppo
global optlog

set maxvuser $maxvuser_m
set delayms $delayms_m
set conpause $conpause_m
set ntimes $ntimes_m
set suppo $suppo_m
set optlog $optlog_m
}

proc vuser_bench_ops {rdbms_m bm_m} {
global rdbms
global bm

set rdbms $rdbms_m
set bm $bm_m
}
