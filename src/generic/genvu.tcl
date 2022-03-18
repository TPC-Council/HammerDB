set masterthread [thread::names]
tsv::set application themaster $masterthread
proc myerrorproc { id info } {
global threadsbytid
if { ![string match {*index*} $info] } {
if { [ string length $info ] == 0 } {
puts "Warning: a running Virtual User was terminated, any pending output has been discarded"
} else {
if { [ info exists threadsbytid($id) ] } {
puts "Error in Virtual User [expr $threadsbytid($id) + 1]: $info"
	}  else {
    if {[string match {*.tc*} $info]} {
puts "Warning: Transaction Counter stopped, connection message not displayed"
	} else {
#metrics thread
    if {[string match {*canceled*} $info]} {
#message was eval canceled
					} else {
puts "Metrics Thread Error: $info"
					}
				}
			}
		}
     	}
}
thread::errorproc myerrorproc

proc findtempdir {} {
global env
        set result "."       ;
        if {[string match windows $::tcl_platform(platform)]} {
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            } 
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[file isdirectory C:/TEMP] && [file writable C:/TEMP]} {
                return C:/TEMP
            }
            if {[file isdirectory C:/] && [file writable C:/]} {
                return C:/
            }
        } else { ;
            if {[info exists env(TMP)] && [file isdirectory $env(TMP)] \
                    && [file writable $env(TMP)]} {
                return $env(TMP)
            } 
            if {[info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] \
                    && [file writable $env(TMPDIR)]} {
                return $env(TMPDIR)
            }
            if {[info exists env(TEMP)] && [file isdirectory $env(TEMP)] \
                    && [file writable $env(TEMP)]} {
                return $env(TEMP)
            }
            if {[file isdirectory /tmp] && [file writable /tmp]} {
                return /tmp
            }
        }
        if {[file writable .]} {
            return .
        }
	return notmpdir
    }

proc guid_init { } {
    if {![info exists ::GuiD__SeEd__VaR]} {
       set ::GuiD__SeEd__VaR 0
    }

    if {![info exists ::GuiD__MaChInFo__VaR]} {
       set ::GuiD__MaChInFo__VaR $::tcl_platform(user)[info hostname]$::tcl_platform(machine)$::tcl_platform(os)
    }
 }

 proc guid { } {
    set MachInfo [expr {rand()}]$::GuiD__SeEd__VaR$::GuiD__MaChInFo__VaR
    binary scan $MachInfo h* MachInfo_Hex
    set guid [format %2.2x [clock seconds]]
    append guid [string range [format %2.2x [clock clicks]] 0 3] \
                [string range $MachInfo_Hex 0 11]
    incr ::GuiD__SeEd__VaR
    return [string toupper $guid]
 }

proc Log {id msg lastline} {
global tids threadsbytid
set Name .ed_mainFrame.ap.canv
catch {.ed_mainFrame.tw.cv itemconfigure $tids($id) -text [ join $msg ]}
	if {[winfo exists $Name.a.t]} {
if { [ info exists threadsbytid($id) ] } {
	if { [ expr $threadsbytid($id) + 1 ] eq 1 } {
	$Name.a.t insert end "$lastline" 
	$Name.a.t see end
			}
		}
 	}
}

proc logtofile { id msg } {
global flog threadsbytid log_timestamps
if { [ info exists threadsbytid($id) ] } {
if { $log_timestamps } {
catch {puts $flog [ join "Timestamp\ [expr $threadsbytid($id) + 1]\ @\ [clock format [clock seconds]]" ]}
	}
catch {puts $flog [ join "Vuser\ [expr $threadsbytid($id) + 1]:$msg" ] }
    }
}

proc stacktrace {} {
    set stack "Stack trace:\n"
    for {set i 1} {$i < [info level]} {incr i} {
        set lvl [info level -$i]
        set pname [lindex $lvl 0]
        append stack [string repeat " " $i]$pname
        foreach value [lrange $lvl 1 end] arg [info args $pname] {
            if {$value eq ""} {
                info default $pname $arg value
            }
            append stack " $arg='$value'"
        }
        append stack \n
    }
    return $stack
}

proc load_virtual {}  {
global _ED ed_loadsave argv argv0 argc embed_args threadscreated threadsbytid masterthread maxvuser virtual_users lprefix winterps suppo optlog table Parent ntimes tids tc_threadID dbmon_threadID opmode vuser_create_ok rdbms bm
set vuser_create_ok true
set thlist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $thlist $tc_threadID ]
if { $idx != -1 } {
set thlist [ lreplace $thlist $idx $idx ]
	}
}
#Additional thread for Database Metrics initially Oracle only
#Additional thread for Database Metrics PostgreSQL added
if { $rdbms eq "Oracle" || $rdbms eq "PostgreSQL" } {
if { [ info exists dbmon_threadID ] } {
if { [ thread::exists $dbmon_threadID ] || [ tsv::get application themonitor ] eq "NOWVUSER" } {
set idx [ lsearch $thlist $dbmon_threadID ]
if { $idx != -1 } {
set thlist [ lreplace $thlist $idx $idx ]
	}
     }
  }
}
set thlen [ llength $thlist ] 
if { $opmode != "Replica" } {
if { $thlen > 1 } {
set thlen [ expr { $thlen - 1 } ]
set thlist [ join [lreplace $thlist $thlen $thlen ] ]
set vuser_create_ok "false"
set answer [tk_messageBox -type yesno -icon question -message "Virtual Users still active in background\nWait for Virtual Users to finish?" -detail "Yes to remain active, No to terminate"] 
switch $answer {
yes { ; }
no { 
foreach ij $thlist {
catch {thread::cancel $ij}
      }
   }
}
return 1
} else { ;#Only the Master thread is running }
} else {
#Running in replica mode so attempt to terminate virtual users and continue
if { $thlen > 1 } {
set thlen [ expr { $thlen - 1 } ]
set thlist [ join [lreplace $thlist $thlen $thlen ] ]
set termcheck "fail"
for { set termincnt 1 } {$termincnt < 4 } {incr termincnt } {
puts "Virtual Users still active in background in replica mode - attempting to terminate and continue - attempt $termincnt"
foreach ij $thlist {
catch {thread::cancel $ij}
	}
after 1000
set thlist [ thread::names ]
set thlen [ llength $thlist ] 
if { $thlen <= 1 } { 
puts "Success Virtual Users terminated"
set termcheck "success"
break 
		}
after 1000
	}
if { $termcheck eq "fail" } { 
puts "Failed to terminate running Virtual Users"
return 1 
	} else {
#running in replica mode virtual users terminated so continue
puts "Continuing"
	} 
    }
}
ed_stop_vuser 
tsv::set application abort 0
if {  [ info exists virtual_users ] } { ; } else { set virtual_users 1 }
if {  [ info exists maxvuser ] } { ; } else { set maxvuser $virtual_users }
if {  [ info exists lprefix ] } { ; } else { set lprefix "load" }
if { [ info exists suppo ] } { ; } else { set suppo 0 }
if { [ info exists optlog ] } { ; } else { set optlog 0 }
if { [ info exists ntimes ] && $ntimes > 1 } { ; } else { set ntimes 1 }
#For web version build_schema is not at the end of the stacktrace, modified to find build anywhere in trace
set result [ lsearch [ lindex [ split [ join [ stacktrace ] ] ] ] "build_schema" ]
if { $result != -1 }  {
set virtual_users $maxvuser
	} else {
#Find if workload test or timed set when script is loaded as lprefix
set maxvuser $virtual_users
      if { $lprefix eq "loadtimed" } {
        set maxvuser [expr {$virtual_users + 1}]
        set suppo 1
        } else { ; }        
   } 
#Moved to running of virtual users
#disable_enable_options_menu disable
set Name .ed_mainFrame.buttons.datagen 
$Name configure -state disabled
set Name .ed_mainFrame.buttons.boxes 
$Name configure -state disabled
set Name .ed_mainFrame.editbuttons.test 
$Name configure -state disabled
for { set vuser 0 } {$vuser < $maxvuser } {incr vuser} {
set threadID [thread::create {
proc runVuser { MASTER ID NTIMES DELAYMS OTSQL } {
for { set cnta 0} {$cnta < $NTIMES} {incr cnta } {
eval [subst {thread::send -async $MASTER {::runninguser $ID}}]
   if {[set op [catch "eval $OTSQL" result]]} {
eval [subst {thread::send -async $MASTER {::myerrorproc [list $ID $result]}}]
   }
eval [subst {thread::send -async $MASTER {::printresult [list $op $ID]}}]
set dms 0
after $DELAYMS { set dms 1 }
vwait dms
	}
}

proc winsetup { MASTER OPTLOG } { 
global masterthread
global optlog
set masterthread $MASTER
set optlog $OPTLOG
rename puts _puts
proc puts args {
global masterthread
global optlog
global Stack
set id [ thread::id ]
          set la [llength $args]
          if {$la<1 || $la>3} {
             error "usage: puts ?-nonewline? ?channel? string"
          }
          set nl \n
          if {[lindex $args 0]=="-nonewline"} {
             set nl ""
             set args [lrange $args 1 end]
          }
          if {[llength $args]==1} {
             set args [list stdout [join $args]]
          }
          foreach {channel s} $args break
 if {$channel=="stdout" || $channel=="stderr"} {
if { $masterthread eq -1 } { ; } else {
lappend Stack $s$nl
if { [ llength $Stack ]  > 5 } { set Stack [lreplace $Stack 0 0 ] }
eval [subst {thread::send $masterthread {::Log [ list $id $Stack $s$nl ]}}]
if { $optlog eq 1 } { 
eval [subst {thread::send -async $masterthread {::logtofile [ list $id $s$nl ]}}] 			}
} } else {
		 set cmd _puts
             if {$nl==""} {lappend cmd -nonewline}
             lappend cmd $channel $s
             eval $cmd
				}
	}
}

thread::wait }]
set threadscreated($vuser) $threadID
if { $suppo == 1 } { eval [ subst {thread::send $threadscreated($vuser) { winsetup $masterthread $optlog }}] 
} else { eval [ subst {thread::send $threadscreated($vuser) { winsetup {-1} $optlog }}] }  }
foreach {vuser threadID} [array get threadscreated] {
set threadsbytid($threadID) $vuser
#vusers thread has grabbed previous tc or monitor thread so remove variable
##this thread is now a vuser
if { [ info exists tc_threadID ] } { 
if { $threadID eq $tc_threadID } { unset -nocomplain tc_threadID }
		}
if { ($rdbms eq "Oracle" || $rdbms eq "PostgreSQL") && [ info exists dbmon_threadID ] } { 
if { $threadID eq $dbmon_threadID } { 
tsv::set application themonitor "NOWVUSER"
unset -nocomplain dbmon_threadID
			 }
		}
        }
if { $suppo == 1 } {
set trdwin ".ed_mainFrame.tw"
.ed_mainFrame.notebook tab $trdwin -state normal
.ed_mainFrame.notebook select $trdwin
upvar #0 icons icons
if { [ info exists icons ] } {
#running in GUI get values from icons
set textColor black
set fillColor white
set outlineColor [ dict get $icons defaultBackground ] 
	} else {
#running in CLI set placeholder values to avoid variable does not exist
set textColor black
set fillColor white
set outlineColor white 
	}
set usercount $maxvuser
set countuser 0
if { $usercount <= 9 } {
set x 3
set y 3
} else {
set uscsq [ expr {sqrt($usercount)} ]
set uscsqrnd [ expr {round($uscsq)} ]
if { $uscsq == $uscsqrnd } {
set x $uscsqrnd
set y $uscsqrnd
} else {
if { $uscsq > $uscsqrnd } {
set x $uscsqrnd
set y  [ expr {round(ceil($uscsq))} ]
        } else {
set x [ expr {round(ceil($uscsq))} ]
set y [ expr {round(ceil($uscsq))} ]
        	}
	}
}
global win_scale_fact
if { [ info exists win_scale_fact ] } {
;#running in GUI
	} else {
#running in CLI, set placeholder variable to avoid variable does not exist
set win_scale_fact 1.333333
	}
set rect_sz_fact [ expr {round((100/1.333333)*$win_scale_fact)} ]
set dbl_sz_fact [ expr {$rect_sz_fact*2} ]
set xval [ expr {($x * $rect_sz_fact)*2}]
set yval [ expr {($y * $rect_sz_fact)*2}]
set scrxarea [ expr {$xval + $rect_sz_fact}]
set scryarea [ expr {$yval + $rect_sz_fact}]
set hdb_buff [ expr {$rect_sz_fact/10} ]
set txt_buff [ expr {$rect_sz_fact/5} ]
set cnv [ canvas $trdwin.cv -background white -highlightthickness 0 -scrollregion \
        "$rect_sz_fact $rect_sz_fact $scrxarea $scryarea" -yscrollcommand \
        "$trdwin.cv.cv2.scrollY set" -xscrollcommand "$trdwin.cv.scrollX set" \
        -xscrollincrement 50 -yscrollincrement 25 ]
pack $cnv -fill both -expand 1
 if { $ttk::currentTheme eq "black" } {
set cnv2 [ canvas $trdwin.cv.cv2 -width 11 -highlightthickness 0 -background #424242 ]
	} else {
set cnv2 [ canvas $trdwin.cv.cv2 -width 11 -highlightthickness 0 -background #dcdad5 ]
	}
pack $cnv2 -expand 0 -fill y -ipadx 0 -ipady 0 -padx 0 -pady 0 -side right
set scr1 [ ttk::scrollbar $trdwin.cv.cv2.scrollY -orient vertical -command "$cnv yview" ]
set scr2 [ ttk::scrollbar $trdwin.cv.scrollX -orient horizontal -command "$cnv xview" ]
pack $scr1 -expand 1 -fill y -ipadx 0 -ipady 0 -padx 0 -pady "0 15" -side right
pack $scr2 -anchor s -expand 0 -fill x -ipadx 0 -ipady 0 -padx 0 -pady 0 -side bottom
for {set y $rect_sz_fact} {$y <= $yval} {incr y $dbl_sz_fact} {
    set bottom [expr $y + $dbl_sz_fact]
    for {set x $rect_sz_fact} {$x <= $xval} {incr x $dbl_sz_fact} {
        set right [expr $x+$dbl_sz_fact]
$cnv create rectangle  $x $y $right $bottom \
                -fill $fillColor -outline $outlineColor
if { $countuser < $usercount } {
	set vuid $threadscreated($countuser)
	if { $virtual_users eq [ expr $maxvuser - 1 ]  && $countuser eq 0} { set MON "-MONITOR" } else { set MON "" }
	if { $ttk::currentTheme in {clearlooks arc breeze awlight}} {
        $cnv create text [expr $x+$rect_sz_fact] [expr $y+$hdb_buff] \
        -text "Virtual User [expr $countuser + 1]$MON" -font \
         [ list basic [ expr [ font actual basic -size ] - 1 ] ] -fill $textColor
        set tids($vuid) [ $cnv create text [expr $x+$rect_sz_fact] [expr $y+$txt_buff] \
	-width $dbl_sz_fact -text "" -font \
                [ list basic [ expr [ font actual basic -size ] - 2 ] ] -fill $textColor -anchor n -justify left ] 
		incr countuser
	} else {
        $cnv create text [expr $x+100] [expr $y+10] \
        -text "Virtual User [expr $countuser + 1]$MON" -font \
        [list TkDefaultFont 9] -fill $textColor
        set tids($vuid) [ $cnv create text [expr $x+100] [expr $y+20] \
	-width $rect_sz_fact -text "" -font \
                [list TkDefaultFont 7 ] -fill $textColor -anchor n -justify left ] 
		incr countuser
				}
			}
    		}
	}
}
configtable 
if { $optlog == 1 } {
global flog opmode apmode unique_log_name no_log_buffer log_timestamps
if { [ info exists opmode ] } { ; } else { set opmode "Local" }
if { [ info exists apmode ] } { ; } else { set apmode "disabled" }
if { [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
if {  [ info exists log_timestamps ] } { ; } else { set logtimestamps 0 }
set tmpdir [ findtempdir ]
if { $tmpdir != "notmpdir" } { 
	if { $unique_log_name eq 1 } {
	set guidid [ guid ]
set filename [file join $tmpdir hammerdb_$guidid.log ]
	} else {
set filename [file join $tmpdir hammerdb.log ]
	}
 if {[catch {set flog [open $filename a ]}]} {
     error "Could not open tempfile $filename"
 		} else {
 if {[catch {fconfigure $flog -buffering none}]} {
     error "Could not disable buffering on $filename"
 		}
	puts $flog "Hammerdb Log @ [clock format [clock seconds]]"
	puts $flog "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
			}
if { $opmode != "Replica" } {
if { $apmode eq "disabled" } {
tk_messageBox -title "Logging Active" -message "Logging activated\nto $filename"
		} else {
puts "Logging activated to $filename"
			}
		}
	} else {
if { $opmode != "Replica" } {
if { $apmode eq "disabled" } {
tk_messageBox -icon error -message "Could not create Logfile"
		} else {
puts "Could not create Logfile"
				}
			}
		}
	}
}

proc run_virtual {} {
global _ED ed_loadsave argv argv0 argc embed_args threadscreated threadsbytid maxvuser delayms conpause ntimes masterthread totcount table vuser_create_ok
set Name .ed_mainFrame.buttons.runworld
$Name configure -state disabled
disable_enable_options_menu disable
set vuser_create_ok false
tsv::set application abort 0
ed_edit_commit
set totcount 0
#Trying to run so check if any script in editor to run
if { [ string length $_ED(package)] eq 1 } {
tk_messageBox -icon error -message "There is no workload to run because the Script Editor window is empty" 
$Name configure -state normal
disable_enable_options_menu enable
return
} else {
#Script Editor Loaded with workload, Check if virtual users already created
if { ![ info exists threadscreated ] } { 
#Trying to Run Virtual Users before Creation, try to create then run
set vuser_create_ok "false"
if { [catch {load_virtual} message]} {
puts "Failed to create and run virtual users: $message"
tk_messageBox -icon error -message "Failed to create and run Virtual Users" 
$Name configure -state normal
return
        } else {
#virtual users created dynamically
set vuser_create_ok "true"
	} 
       } else {
#Virtual Users already created before pressing run button
set vuser_create_ok "true"
	} 
if { $vuser_create_ok eq "true" } {
#Virtual Users exist, run the workload
$table delete 0 end 
configtable
if { [ info exists maxvuser ] } { ; } else { set maxvuser 1 }
if { [ info exists delayms ] } { ; } else { set delayms 500 }
if { [ info exists conpause ] } { ; } else { set conpause 500 }
if { [ info exists ntimes ] } { ; } else { set ntimes 1 }
if { [ info exists suppo ] } { ; } else { set suppo 0 }
    ed_status_message -run "RUNNING - $_ED(packagekeyname)"
    update idletasks
 if {[catch {set script_to_send [list $_ED(package)]} message]} {
puts "Failed to capture Editor Script: $message"
tk_messageBox -icon error -message "Failed to capture Editor Script" 
$Name configure -state normal
return
	}
for { set vuser 0} {$vuser < $maxvuser} {incr vuser} {
eval [ subst {thread::send -async $threadscreated($vuser) {runVuser $masterthread $threadscreated($vuser) $ntimes $delayms $script_to_send}}]
set cp 0
after $conpause { set cp 1 }
vwait cp
	}
.ed_mainFrame configure -cursor {}
	} else {
$Name configure -state normal
	}
   }
}
proc ed_kill_vusers {args} {
    global _ED ed_mainf maxvuser threadscreated threadsbytid table suppo inrun flog
    ed_status_message -show "Destroying Virtual Users"
    tsv::set application abort 1
    update
   ed_lvuser_button
   update
if {[winfo exists .ed_mainFrame.tw.cv ]} { destroy .ed_mainFrame.tw.cv }
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
.ed_mainFrame.notebook tab .ed_mainFrame.tw -state disabled
catch { close $flog }
for { set vuser 0} {$vuser < $maxvuser} {incr vuser} {
eval [ subst {thread::send -async $threadscreated($vuser) {thread::release} }] }
unset threadscreated
unset threadsbytid
$table delete 0 end
set Name .ed_mainFrame.buttons.runworld
$Name configure -state normal
disable_enable_options_menu enable
set Name .ed_mainFrame.buttons.datagen 
$Name configure -state normal
set Name .ed_mainFrame.buttons.boxes 
$Name configure -state normal
set Name .ed_mainFrame.editbuttons.test 
$Name configure -state normal
if { [ info exists inrun ] } {
    unset inrun
	} 
ed_status_message -show "Virtual Users Destroyed"
}
