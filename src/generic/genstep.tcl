#Replica reads port file and automatically connects back
proc replica_callback { primport } {
global opmode
switchmode replica $primport
if { $opmode != "Replica" } {
putscli "Error: Failed to switch to Replica mode via callback"
return
} else {
putscli "Switched to Replica mode via callback"
replica_waittocomplete
        }
}

#Write Primary Port for Replicas to read
proc write_port_file {} {
set tmpdir [ findtempdir ]
if { $tmpdir != "notmpdir" } {
set filename [file join $tmpdir hdbcallback.tcl ]
set outfile [open $filename w]
puts $outfile "replica_callback [ Primary self ]" 
close $outfile
return $filename
	} else {
return $tmpdir
	}
}

#XML Connect Data
proc get_step_xml {} {
if [catch {package require xml} ] { error "Failed to load xml package in tpcccom
mon module" }
set stepxml "config/steps.xml"
if { [ file exists $stepxml ] } {
	set steps [ ::XML::To_Dict_Ml $stepxml ]
	return $steps
	} else {
	error "Step workload specified but file $stepxml does not exist"
	}
    }

#Return current Virtual User setting
proc get_vu {} {
global virtual_users
if { [ info exists virtual_users ] } {
return $virtual_users
	} else {
return 1
	}
}

#Delete port file used to start replicas
proc delete_port_file { port_file } {
file delete $port_file
}

#Find and return the rampup value in a database dict
proc get_base_rampup { dbconfig } {
foreach key [dict keys $dbconfig ] { set base_rampup [ lindex [ dict filter [ dict get $dbconfig $key ] key *rampup  ] 1 ]
if { $base_rampup != "" } { return $base_rampup } 
} 
return ""
}

#Find and return the duration value in a database dict
proc get_base_duration { dbconfig } {
foreach key [dict keys $dbconfig ] { set base_duration [ lindex [ dict filter [ dict get $dbconfig $key ] key *duration  ] 1 ]
if { $base_duration != "" } { return $base_duration } 
} 
return ""
}

#Send a single command to a replica
proc sendonecommand { command stepcount } {
global masterlist masterlistcopy
putscli "Sending \"$command\" to [ lindex $masterlistcopy [ expr $stepcount - 1 ]]"
Primary send [ lindex $masterlistcopy [ expr $stepcount - 1 ]] eval $command  
}

#do the equivalent of dbset for all parameters in a dict, ie set the entire dict
proc dbsetall { stepcount dbname dbconfig } {
global masterlist masterlistcopy
putscli "Sending dbset all to [ lindex $masterlistcopy [ expr $stepcount - 1 ]]"
Primary send [ lindex $masterlistcopy [ expr $stepcount - 1 ]] set $dbname [ concat [list $dbconfig ]] 
}

#Start HammerDB Replicas, one replica per step
proc start_replicas {stepnumbers callbackfile} {
global tcl_platform
for {set step 1} {$step <= $stepnumbers} {incr step} {
putscli "Starting $step replica HammerDB instance"
if {$tcl_platform(platform) == "windows"} {
exec ./bin/tclsh86t hammerdbcli auto $callbackfile &
	} else {
exec ./bin/tclsh8.6 hammerdbcli auto $callbackfile &
	}
}
}

#find prefix for a database
proc find_prefix { db } {
upvar #0 dbdict dbdict
dict for {database attributes} $dbdict {
dict with attributes {
lappend dbl $name
lappend prefixl $prefix
        }
}
set ind [ lsearch $dbl $db ]
if { $ind eq -1 } {
return ""
} else {
set prefix [ lindex $prefixl $ind ]
return $prefix
        }
}

#find name of the config dict for a database
proc find_config { db } {
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $db } {
return config$key
	}
    }
}

#Print Step workload actions check duration does not overrun primary
proc check_and_print_steps { base_rampup base_duration steps } {
set steperror "false"
set prim_elapsed [ expr {$base_rampup + $base_duration} ]
set startafter_total $base_rampup
foreach step [ dict keys $steps ] {
set value [dict get $steps $step]
foreach {startafter step_duration vucount} [ split $value ] {}
set startafter_total [ expr {$startafter_total + $startafter} ]
switch $step {
primary {
putscli "$step starts immediately, runs rampup for $base_rampup minutes then runs test for $step_duration minutes with $vucount Active VU"
}
replica1 {
putscli "$step starts $startafter minutes after rampup completes and runs test for $step_duration minutes with $vucount Active VU"
}
default {
putscli "$step starts $startafter minutes after previous replica starts and runs test for $step_duration minutes with $vucount Active VU"
}
}
set check_step [ expr {$startafter_total + $step_duration} ]
if { $check_step > $prim_elapsed } {
putscli "Error: $step is set to complete after $check_step minutes and is longer than the Primary running time of $prim_elapsed minutes"
set steperror "true"
}}
if { $steperror } {
putscli "Error: Step workload primary running time must exceed the running time of all replicas"
return false
}
return true
}

proc replica_waittocomplete {} {
proc rep_wait_to_complete_loop {} {
upvar rcomplete rcomplete
set rcomplete [vucomplete]
if {!$rcomplete} { catch {after 5000 rep_wait_to_complete_loop} } else {
putscli "Replica workload complete and calling exit from primary"
exit
}
}
set rcomplete "false"
rep_wait_to_complete_loop
vwait forever
}

#Keep primary busy waiting for vucomplete
proc primary_waittocomplete { port_file } {
putscli "Primary entering loop waiting for vucomplete"
proc primary_wait_to_complete_loop { port_file } {
global opmode
upvar wcomplete wcomplete
set wcomplete [vucomplete]
if {!$wcomplete} { catch {after 5000 primary_wait_to_complete_loop $port_file} } else {
putscli "Primary complete"
putscli "deleting port_file $port_file"
delete_port_file $port_file
putscli "Step workload complete"
#Call exit for primary
exit
}
}
set wcomplete "false"
primary_wait_to_complete_loop $port_file
}

#Wait for replicas to connect and run the workload
proc wait_to_connect_and_continue { rampup duration prefix dbconfig port_file } {
global connect masterlist masterlistcopy forever opmode
upvar #0 dbconfig_dict dbconfig_dict
upvar #0 steps steps
set stepnumbers [  expr {[ dict size $steps ] - 1} ]
if {[llength $masterlist] eq 0 } {
putscli "Primary waiting for all replicas to connect .... 0 out of $stepnumbers are connected"
	} else {
putscli "Primary waiting for all replicas to connect .... $masterlist out of $stepnumbers are connected"
	}
if {[llength $masterlist] < $stepnumbers} {after 5000 wait_to_connect_and_continue $rampup $duration $prefix $dbconfig $port_file } else { 
putscli "Primary Received all replica connections $masterlist"
#Make a copy in case a replica disconnects during the test
set masterlistcopy $masterlist
#Must be set here as dbset does remote command
lappend startafterlist rampup $rampup
###Base Settings sent to all replicas
dbset db $prefix
set stepcount 1
###Modify individual replicas based on step settings
foreach step [ dict keys $steps ] {
set value [dict get $steps $step]
foreach {startafter duration vucount} [ split $value ] {}
if { $step != "primary" } {
dbsetall $stepcount $dbconfig $dbconfig_dict
lappend startafterlist $step $startafter
putscli "Setting $step to start after $startafter duration $duration VU count $vucount, Replica instance is [ lindex $masterlistcopy [ expr $stepcount - 1 ]]"
#Apply settings, always set rampup to 0 as Primary does the rampup
if { $prefix eq "ora" } {
foreach command [ list "diset tpcc ora_timeprofile false" "diset tpcc rampup 0" "diset tpcc duration $duration" "vuset vu $vucount" ] { sendonecommand $command $stepcount }
} else {
foreach command [ list "diset tpcc $prefix\_timeprofile false" "diset tpcc $prefix\_rampup 0" "diset tpcc $prefix\_duration $duration" "vuset vu $vucount" ] { sendonecommand $command $stepcount }
}
incr stepcount
} else {
#Set primary values
putscli "Setting primary to run $vucount virtual users for $duration duration"
foreach {startafter duration vucount} [ split $value ] {}
if { $prefix eq "ora" } {
diset tpcc duration $duration
} else {
diset tpcc $prefix\_duration $duration
}
vuset vu $vucount
}
}
loadscript
vucreate
putscli "Starting Primary VUs"
run_virtual
putscli "Delaying Start of Replicas to $startafterlist"
set x 0
set stepcount 0
set startafter 0
while  {$x <= [ expr $stepnumbers * 2 ]} {
set startafter [ expr $startafter + [ lindex $startafterlist [ expr {$x + 1} ]]]
if { [ lindex $startafterlist $x ] != "rampup" } {
putscli "Delaying [ lindex $startafterlist $x ] for $startafter minutes."
task -in "$startafter minutes" -command "sendonecommand run_virtual $stepcount"
	}
incr x 2
incr stepcount
}
primary_waittocomplete $port_file
}
vwait forever
}

#Run a step workload
proc steprun {} {
global rdbms bm
upvar #0 dbconfig_dict dbconfig_dict
upvar #0 steps steps
if { $bm != "TPC-C" } {
putscli "Error: Step Workload does not support $bm"
return
}
set prefix [ find_prefix $rdbms ]
set dbconfig [ find_config $rdbms ]
upvar #0 [set dbconfig ] [ set dbconfig ]
set base_rampup [ get_base_rampup [ set $dbconfig ]]
set base_duration [ get_base_duration [ set $dbconfig ]]
set base_vu [ get_vu ]
#Primary steps are always, startafterprevious 0, run for previous set duration and use VU setting
set prim_steps [ dict create primary "0 $base_duration $base_vu" ] 
#Replica steps are extracted from XML in the config directory
set repl_steps ""
set repl_dict [ get_step_xml ]
#Truncate dict into a more usable form
set repl_keys [ dict keys $repl_dict ]
foreach key [split $repl_keys] { 
lappend repl_steps $key	
lappend repl_steps [ dict values [ dict get $repl_dict $key ] ] 
}
set steps [ concat $prim_steps $repl_steps ]
set stepnumbers [  expr {[ dict size $steps ] - 1} ]
if { ![ check_and_print_steps $base_rampup $base_duration $steps ] } { return }
#Start Primary
switchmode Primary
set port_file [ write_port_file ]
if {  $port_file != "notmpdir" } {
#Start Replicas
start_replicas $stepnumbers $port_file
	} else {
putscli "Failed to write Primary port file to temp directory"
	}
#Wait for replicas to connect
putscli "Doing wait to connnect ...."
set dbconfig_dict [ set $dbconfig ]
wait_to_connect_and_continue $base_rampup $base_duration $prefix $dbconfig $port_file
}
