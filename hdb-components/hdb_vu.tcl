proc findtempdir {} {
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
global flog threadsbytid
if { [ info exists threadsbytid($id) ] } {
catch {puts $flog [ join "Vuser\ [expr $threadsbytid($id) + 1]:$msg" ] }
    }
}

proc load_virtual {}  {
global _ED ed_loadsave argv argv0 argc embed_args threadscreated threadsbytid masterthread maxvuser winterps suppo optlog table Parent ntimes tids tc_threadID opmode
set thlist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $thlist $tc_threadID ]
if { $idx != -1 } {
set thlist [ lreplace $thlist $idx $idx ]
	}
}
set thlen [ llength $thlist ] 
if { $opmode != "Slave" } {
if { $thlen > 1 } {
set thlen [ expr { $thlen - 1 } ]
set thlist [ join [lreplace $thlist $thlen $thlen ] ]
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
#Running in slave mode so attempt to terminate virtual users and continue
if { $thlen > 1 } {
set thlen [ expr { $thlen - 1 } ]
set thlist [ join [lreplace $thlist $thlen $thlen ] ]
set termcheck "fail"
for { set termincnt 1 } {$termincnt < 4 } {incr termincnt } {
puts "Virtual Users still active in background in slave mode - attempting to terminate and continue - attempt $termincnt"
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
#running in slave mode virtual users terminated so continue
puts "Continuing"
	} 
    }
}
ed_stop_vuser 
tsv::set application abort 0
if { [ info exists maxvuser ] } { ; } else { set maxvuser 1 }
if { [ info exists suppo ] } { ; } else { set suppo 0 }
if { [ info exists optlog ] } { ; } else { set optlog 0 }
if { [ info exists ntimes ] && $ntimes > 1 } { ; } else { set ntimes 1 }
disable_enable_options_menu disable
set Name .ed_mainFrame.buttons.test 
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
        }
if { $suppo == 1 } {
set trdwin ".ed_mainFrame.tw"
.ed_mainFrame.notebook tab $trdwin -state normal
.ed_mainFrame.notebook select $trdwin
set textColor black
set fillColor white
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
set xval [ expr {($x * 100)*2}]
set yval [ expr {($y * 100)*2}]
set scrxarea [ expr {$xval + 100}]
set scryarea [ expr {$yval + 100}]
set cnv [ canvas $trdwin.cv -background white -scrollregion \
        "100 100 $scrxarea $scryarea" -yscrollcommand \
        "$trdwin.cv.cv2.scrollY set" -xscrollcommand "$trdwin.cv.scrollX set" \
        -xscrollincrement 50 -yscrollincrement 25 ]
pack $cnv -fill both -expand 1
set cnv2 [ canvas $trdwin.cv.cv2 -width 11 -background #dcdad5 ]
pack $cnv2 -expand 0 -fill y -ipadx 0 -ipady 0 -padx 0 -pady 0 -side right
set scr1 [ ttk::scrollbar $trdwin.cv.cv2.scrollY -orient vertical -command "$cnv yview" ]
set scr2 [ ttk::scrollbar $trdwin.cv.scrollX -orient horizontal -command "$cnv xview" ]
pack $scr1 -expand 1 -fill y -ipadx 0 -ipady 0 -padx 0 -pady "0 15" -side right
pack $scr2 -anchor s -expand 0 -fill x -ipadx 0 -ipady 0 -padx 0 -pady 0 -side bottom

for {set y 100} {$y <= $yval} {incr y 200} {
    set bottom [expr $y + 200]
    for {set x 100} {$x <= $xval} {incr x 200} {
        set right [expr $x+200]
        $cnv create rectangle  $x $y $right $bottom \
                -fill $fillColor -outline white
if { $countuser < $usercount } {
	set vuid $threadscreated($countuser)
        $cnv create text [expr $x+100] [expr $y+10] \
        -text "Virtual User [expr $countuser + 1]" -font \
        [list helvetica 10] -fill $textColor
        set tids($vuid) [ $cnv create text [expr $x+100] [expr $y+20] \
	-width 180 -text "" -font \
                [list helvetica 8 ] -fill $textColor -anchor n -justify left ] 
		incr countuser
			}
    		}
	}
}
configtable 
if { $optlog == 1 } {
global flog opmode apmode unique_log_name no_log_buffer
if { [ info exists opmode ] } { ; } else { set opmode "Local" }
if { [ info exists apmode ] } { ; } else { set apmode "disabled" }
if { [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
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
if { $opmode != "Slave" } {
if { $apmode eq "disabled" } {
tk_messageBox -title "Logging Active" -message "Logging activated\nto $filename"
		} else {
puts "Logging activated to $filename"
			}
		}
	} else {
if { $opmode != "Slave" } {
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
global _ED ed_loadsave argv argv0 argc embed_args threadscreated threadsbytid maxvuser delayms conpause ntimes masterthread totcount table
set Name .ed_mainFrame.buttons.runworld
$Name configure -state disabled
tsv::set application abort 0
ed_edit_commit
set totcount 0
if { [ info exists threadscreated ] } { 
if { [ string length $_ED(package)] eq 1 } {
tk_messageBox -icon error -message "There is no workload to run because the Script Editor window is empty" 
set Name .ed_mainFrame.buttons.runworld
$Name configure -state normal
} else {
$table delete 0 end 
configtable
if { [ info exists maxvuser ] } { ; } else { set maxvuser 1 }
if { [ info exists delayms ] } { ; } else { set delayms 500 }
if { [ info exists conpause ] } { ; } else { set conpause 500 }
if { [ info exists ntimes ] } { ; } else { set ntimes 1 }
if { [ info exists suppo ] } { ; } else { set suppo 0 }
    ed_status_message -run "RUNNING - $_ED(packagekeyname)"
    update
for { set vuser 0} {$vuser < $maxvuser} {incr vuser} {
eval [ subst {thread::send -async $threadscreated($vuser) {runVuser $masterthread $threadscreated($vuser) $ntimes $delayms [list $_ED(package)]}}]
update 
set cp 0
after $conpause { set cp 1 }
vwait cp
	}
.ed_mainFrame configure -cursor {}
	}
} else {
tk_messageBox -icon error -message "You must configure and create the Virtual Users before trying to run them" 
set Name .ed_mainFrame.buttons.runworld
$Name configure -state normal
	}
}

proc ed_kill_vusers {args} {
    global _ED ed_mainf maxvuser threadscreated threadsbytid table suppo inrun flog
    ed_status_message -show "... closing down active Vusers ..."
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
set Name .ed_mainFrame.buttons.test 
$Name configure -state normal
if { [ info exists inrun ] } {
    unset inrun
	} 
ed_status_message -finish "Virtual Users Destroyed"
}
