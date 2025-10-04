proc metset {args} {
    global agent_hostname agent_id 
    upvar #0 genericdict genericdict
    if {[ llength $args ] != 2} {
        putscli {Usage: metset [agent_hostname|agent_id] value}
    } else {
        set option [ lindex [ split  $args ]  0 ]
        set ind [ lsearch {agent_hostname agent_id} $option ]
        if { $ind eq -1 } {
            putscli "Error: invalid option"
            putscli {Usage: metset [agent_hostname|agent_id]  value}
            return
        }
        set val [ lindex [ split  $args ]  1 ]
    		if { [ interp exists metrics_interp ] } {
                tk_messageBox -icon warning -message "Stop Metrics before setting configuration"
                return
        } 
        switch  $option {
            agent_id { 
                set agent_id $val
                if { ![string is integer -strict $agent_id] } {
                    tk_messageBox -message "agent_id be an integer"
                    putscli -nonewline "setting to value: "
                    set agent_id 10000
                } else {
                if { [catch {dict set genericdict metrics agent_id $agent_id}] } {
                    putscli "Failed to set Metrics agent id"
                } else {
                    putscli "Metrics agent id set to $agent_id"
		    SQLiteUpdateKeyValue "generic" metrics agent_id $agent_id
                }
                }
            }
            agent_hostname { 
                set agent_hostname $val
                if { [catch {dict set genericdict metrics agent_hostname $agent_hostname}] } {
                    putscli "Failed to set Metrics agent hostname"
                } else {
                    putscli "Metrics agent hostname set to $agent_hostname"
		    SQLiteUpdateKeyValue "generic" metrics agent_hostname $agent_hostname
                }
            }
            default {
                putscli "Unknown metset option"
                putscli {Usage: metset [agent_hostname|agent_id] value}
            }
}}}

proc metstart {} {
		global agent_hostname agent_id 
    		if { [ interp exists metrics_interp ] } {
                putscli "CPU metrics are already running on [ info hostname ], call metstop to stop"
		return
		} else {
                upvar #0 genericdict genericdict
                if {[dict exists $genericdict metrics ]} {
			set agent_hostname [ dict get $genericdict metrics agent_hostname ]
			set agent_id [ dict get $genericdict metrics agent_id ]
		} else {
			set agent_hostname "localhost"
			set agent_id "10000"
		}
                global tcl_platform
                set dirname [ find_exec_dir ]
                if { $dirname eq "FNF" } {
                puts "Error: Cannot find a Valid Executable Directory"
                return
                }
                set UserDefaultDir $dirname
                ::tcl::tm::path add [zipfs root]app/modules "$UserDefaultDir/modules"
                package require comm
                namespace import comm::*
                package require socktest
                namespace import socktest::*
	        if { $agent_hostname eq "localhost" || $agent_hostname eq [ info hostname ] } { 
                set result [ sockmesg [ socktest localhost $agent_id 5000 ]]
                if { $result eq "OK" } {
                } else {
                putscli "Starting Local Metrics Agent on [ info hostname ]"
                if {$tcl_platform(platform)=="windows"} {
                    if {[file exists "$dirname/agent/agent.bat"]} {
                        set agentfile "agent.bat"
                        } else {
                        set agentfile "agent"
                    }
                if {[catch {exec cmd /c "cd /d $dirname/agent && $agentfile $agent_id" &} message ]} {
	        putscli "Error starting metrics agent: $message"
    	        }
                } else {
		  if {[catch {exec sh -c "cd $dirname/agent && ./agent $agent_id >/dev/null 2>/dev/null" &} message ]} {
                  putscli $message
                }
                }}
    		} else {
                set result [ sockmesg [ socktest $agent_hostname $agent_id 1000 ]]
                if { $result eq "OK" } { 
		#there is a remote agent running we can connect to; 
		} else {
                putscli "Remote Metrics Agent is not running on $agent_hostname, $agent_id" 
                return
		}
    		}
                after 500 {climetrics}
}}

proc metstatus {} {
global tcl_platform agent_hostname agent_id
set UserDefaultDir [ file dirname [ info script ] ]
::tcl::tm::path add [zipfs root]app/modules "../$UserDefaultDir/modules"
package require comm
namespace import comm::*
package require socktest
namespace import socktest::*
 if { ![ interp exists metrics_interp ] } {
putscli "CPU Metrics are not running on [ info hostname ]"
 } else {
putscli "CPU Metrics are running on [ info hostname ]"
set result [ sockmesg [ socktest $agent_hostname $agent_id 1000 ]] 
if { $result eq "OK" } {
putscli "Metrics Agent running on $agent_hostname:$agent_id"
} 
}
}

proc metstop {} {
global tcl_platform agent_hostname agent_id 
set UserDefaultDir [ file dirname [ info script ] ]
::tcl::tm::path add [zipfs root]app/modules "../$UserDefaultDir/modules"
package require comm
namespace import comm::*
package require socktest
namespace import socktest::*
set result [ sockmesg [ socktest $agent_hostname $agent_id 1000 ]]
if { $result eq "OK" } {
	  if { [ interp exists metrics_interp ] } {
	#A display is already connected so stopping display will close or reinitialize agent
  	putscli "Stopping Metrics Agent and Display on $agent_hostname:$agent_id"
	#Delay to make sure agent has finished sending
         after 10000 {
		 catch {DisplayMetrics destroy}
		 catch {interp delete metrics_interp}
	 }
  	} else {
	#A display is not already connected so #set up port to send stop message to agent
    if { [catch {::comm new STOPMetrics -listen 1 -local 0 -silent "TRUE" -port {}} b] } {
    tk_messageBox -message "Stopping Metrics Agent and Display on $agent_hostname:$agent_id failed to create port"
    } else {
        set displayid [ STOPMetrics self ]
        set displayhost [ info hostname ]
        #puts "Metric close port open @ $displayid on $displayhost"
	if { [catch {::comm send -async "$agent_id $agent_hostname" "catch {Agent STOP \"$displayid $displayhost\"} "} b] } {
     putscli "Stopping Metrics Agent and Display on $agent_hostname:$agent_id failed to send message $b"
            } else {
     putscli "Stopping Metrics Agent on $agent_hostname:$agent_id"
	    }
	}
     catch { STOPMetrics destroy }
	}
} else {
  putscli "No Metrics Agent detected on id: $agent_hostname:$agent_id"
}
return
}

proc climetrics {} {
    global agent_hostname agent_id
    if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
    if {  [ info exists id ] } { ; } else { set id 0 }
    putscli "Connecting to Agent to Display CPU Metrics"
    if { [ interp exists metrics_interp ] } {
        interp delete metrics_interp
    }
    interp create metrics_interp
    after 0 {interp eval {metrics_interp} [ConfigureNetworkDisplayCLI $agent_id $agent_hostname]}
    #Agent runs the Display from here so additional threads not required
    return
}


proc ConfigureNetworkDisplayCLI {agentid agenthostname} {
    #set up port
    if { [catch {::comm new DisplayMetrics -listen 1 -local 0 -silent "TRUE" -port {}} b] } {
        putscli "Creation of Port Failed : $b" 
    } else {
        set displayid [ DisplayMetrics self ]
        set displayhost [ info hostname ]
        putscli "Metric receive port open @ $displayid on $displayhost"
        DisplayMetrics hook lost {
            if { [catch { DisplayMetrics destroy } b] } {
                putscli "Agent Connection lost but Failed to close network port : $b" 
            } else {
                #ed_kill_cpu_metrics
                putscli "Metrics Connection closed"
            }
        }
        #Test Agent Port
        namespace import socktest::*
        putscli "Connecting to HammerDB Agent @ $agenthostname:$agentid"
        puts -nonewline "Testing Agent Connectivity..."
        set result [ sockmesg [ socktest $agenthostname $agentid 1000 ]]
        #Test is OK so call agent to call back
        if { $result eq "OK" } {
            putscli $result
            putscli "Metrics Connected"
            if { [catch {::comm send -async "$agentid $agenthostname" "catch {Agent connect \"$displayid $displayhost\"} "} b] } {
                putscli "Connection to agent lost: $b"
                catch { DisplayMetrics destroy }
            }
        } else {
            putscli $result
            putscli "Connection failed verify agent hostname and id @ $agenthostname:$agentid"
                if {$::tcl_platform(platform)!="windows"} {
                putscli "Check sysstat package is installed and mpstat command is available to agent"
                }
            DoDisplay 1 "AGENT CONNECTION FAILED" local
            return
        } 
    }
}

proc DoDisplay {maxcpu cpu_model caller} {
global agent_hostname jobid
	putscli "Started CPU Metrics for $cpu_model:($maxcpu CPUs)"
	if { [ info exists cpu_model ] && ![ string match "AGENT CONNECTION FAILED" $cpu_model ] } {
	if { [ info exists jobid] && $jobid != "" && $jobid != 0 } {
        #If we have done set jobid [ vurun ] in script set jobid back
        if { [ string match Benchmark* $jobid ] } { 
        set jobid [ regsub {Benchmark.*=} $jobid ""]
	}		
        hdbjobs eval {INSERT INTO JOBSYSTEM(jobid,hostname,cpumodel,cpucount) VALUES($jobid,$agent_hostname,$cpu_model,$maxcpu) ON CONFLICT(jobid) DO UPDATE SET jobid=excluded.jobid,hostname=excluded.hostname,cpumodel=excluded.cpumodel,cpucount=excluded.cpucount}
    	} else {
	#Started CPU metrics before a job is running, insert a placeholder making sure only one placeholder is current
        hdbjobs eval {INSERT INTO JOBSYSTEM(jobid,hostname,cpumodel,cpucount) VALUES('@@@',$agent_hostname,$cpu_model,$maxcpu) ON CONFLICT(jobid) DO UPDATE SET hostname=excluded.hostname,cpumodel=excluded.cpumodel,cpucount=excluded.cpucount}
	}
	} else { 
putscli "AGENT CONNECTION FAILED"
	}
}

proc addstats { usr sys irq idle } {
	global usrlist syslist irqlist idlelist
foreach x { usrlist syslist irqlist idlelist } y { usr sys irq idle } {
	lappend $x [ set $y ]
	}
}

proc StatsOneLine {line} {
global jobid usrlist syslist irqlist idlelist agent_hostname
proc gmean L {
    expr pow([join $L *],1./[llength $L])
}
    #Called by agent remotely
    #Different formats some include AMPM some don't
    if { [ llength $line ] eq 12 } {
        lassign $line when ampm cpu usr nice sys iowait irq soft steal guest idle
    } else {
        if { [ llength $line ] eq 11 } {
            lassign $line when cpu usr nice sys iowait irq soft steal guest idle
        } else {
            putscli "CPU Metrics error: expecting 11 or 12 columns in mpstat data but got [ llength $line ]"
            set cpu 0
        }
    }
    #For the all CPU line add a list and insert the average over 10 seconds into the JOBMETRIC table
    if {[string match "all" $cpu]} {
            addstats $usr $sys $irq $idle
	}
	if { [ info exists usrlist ] && [ llength $usrlist ] eq 5 } {
	foreach x { usrlist syslist irqlist idlelist } y { usrgmean sysgmean irqgmean idlegmean } {
	set $y [format "%3.2f" [ gmean [ set $x ]]]
	}
    	if { [ interp exists metrics_interp ] } {
	putscli "CPU all usr%-$usrgmean sys%-$sysgmean irq%-$irqgmean idle%-$idlegmean"
	 if { [ info exists jobid] && $jobid != "" && $jobid != 0 } {
         if { [ string match Benchmark* $jobid ] } {
         set jobid [ regsub {Benchmark.*=} $jobid ""]
	 }
        hdbjobs eval {INSERT INTO JOBMETRIC(jobid,usr,sys,irq,idle) VALUES($jobid,$usrgmean,$sysgmean,$irqgmean,$idlegmean)}
        #Metrics started before job was running, if placeholder in jobsystem update with correct jobid
        set jobhost [ hdbjobs eval {select hostname from JOBSYSTEM where JOBID=$jobid} ]
        if {$jobhost eq ""} {
        set placehold [ hdbjobs eval {select hostname from JOBSYSTEM where JOBID="@@@"} ]
        if {$placehold eq ""} {
        #The jobid is not present in the jobsystem table and there is no placeholder
        #Likely metrics are continual running for multiple jobs so find system data from previous job
        hdbjobs eval {select hostname,cpumodel,cpucount from JOBSYSTEM where hostname=$agent_hostname LIMIT 1} {
        hdbjobs eval {INSERT INTO JOBSYSTEM(jobid,hostname,cpumodel,cpucount) VALUES($jobid,$agent_hostname,$cpumodel,$cpucount)}}
        } else {
        hdbjobs eval {select hostname,cpumodel,cpucount from JOBSYSTEM where JOBID="@@@"} {
        hdbjobs eval {update JOBSYSTEM set jobid = $jobid where JOBID="@@@"}
                }
                }
    	} else {
	#The jobid is present in the jobsystem table
			;
        }
	}
	}
	foreach x { usrlist syslist irqlist idlelist } {
	set $x [list]
	}
	}
}
