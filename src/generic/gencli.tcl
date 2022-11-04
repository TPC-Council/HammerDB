set opmode "Local"
set table "notable"
set suppo 1
set _ED(package) ""
set _ED(packagekeyname) ""
namespace eval ttk {
    variable currentTheme "black"
    proc scrollbar { args } { ; }
}
proc putscli { output } {
    puts $output
    TclReadLine::print "\r"
}
# Pure Tcl implementation of [string insert] command.
proc ::tcl::string::insert {string index insertString} {
    # Convert end-relative and TIP 176 indexes to simple integers.
    if {[regexp -expanded {
            ^(end(?![\t\n\v\f\r ])      # "end" is never followed by whitespace
            |[\t\n\v\f\r ]*[+-]?\d+)    # m, with optional leading whitespace
            (?:([+-])                   # op, omitted when index is "end"
            ([+-]?\d+))?                # n, omitted when index is "end"
            [\t\n\v\f\r ]*$             # optional whitespace (unless "end")
        } $index _ m op n]} {
        # Convert first index to an integer.
        switch $m {
            end     {set index [string length $string]}
            default {scan $m %d index}
        }
        # Add or subtract second index, if provided.
        switch $op {
            + {set index [expr {$index + $n}]}
            - {set index [expr {$index - $n}]}
        }
    } elseif {![string is integer -strict $index]} {
        # Reject invalid indexes.
        return -code error "bad index \"$index\": must be\
                integer?\[+-\]integer? or end?\[+-\]integer?"
    }
    # Concatenate the pre-insert, insertion, and post-insert strings.
    string cat [string range $string 0 [expr {$index - 1}]] $insertString\
               [string range $string $index end]
}
# Bind [string insert] to [::tcl::string::insert].
namespace ensemble configure string -map [dict replace\
        [namespace ensemble configure string -map]\
        insert ::tcl::string::insert]
proc {} { args } { ; }
proc canvas { args } { ; } 
proc pack { args } { ; }
proc .ed_mainFrame { args } { ; }
proc .ed_mainFrame.notebook { args } { ; }
proc ed_stop_vuser {} { ; }
proc ed_edit_commit {} { ; }
proc disable_enable_options_menu { disenable } { ; }
proc notable { delete 0 end } { ; }
proc .ed_mainFrame.buttons.datagen { args } { ; }
proc .ed_mainFrame.buttons.boxes { args } { ; }
proc .ed_mainFrame.buttons.test { args } { ; }
proc .ed_mainFrame.buttons.runworld { args } { ; }
proc .ed_mainFrame.buttons.delete { args } { ; }
proc ed_lvuser_button { args } { ; }
proc .ed_mainFrame.editbuttons.test { args } { ; }
proc .ed_mainFrame.editbuttons.distribute { args } { ; }
proc destroy { args } { ; }
proc ed_edit { args } { ; }
proc applyctexthighlight { args } { ; }
proc winfo { args } { return "false" }
proc even x {expr {($x % 2) == 0}}
proc odd  x {expr {($x % 2) != 0}}

proc bgerror {{message ""}} {
    global errorInfo
    if {[string match {*threadscreated*} $errorInfo]} {
        #puts stderr "Background Error ignored - Threads Killed"
    } else {
        puts stderr "Unmatched Background Error - $errorInfo"
    }
}

proc configtable {} { 
    global vustatus threadscreated virtual_users maxvuser table ntimes thvnum totrun AVUC
    set AVUC "idle"
    if { ![info exists vustatus] } { set vustatus {} }
    for {set vuser 0} {$vuser < $maxvuser} {incr vuser} {
        set thvnum($threadscreated($vuser)) $vuser
        if {![dict exists $vustatus [ expr $vuser + 1]]} {
            dict set vustatus [ expr $vuser + 1 ] "CREATING"
        } else {
            dict set vustatus [ expr $vuser + 1 ] "ACTIVE"
        }
        if { [ dict get $vustatus [ expr $vuser + 1 ] ] eq "CREATING" } {
            if { $virtual_users != $maxvuser && $vuser eq 0} {
                puts -nonewline "Vuser [ expr $vuser + 1 ] created MONITOR"
            } else {
                puts -nonewline "Vuser [ expr $vuser + 1 ] created"
            }
            putscli " - WAIT IDLE"
            dict set vustatus [ expr $vuser + 1 ] "WAIT IDLE"
    }}
    set totrun [ expr $maxvuser * $ntimes ]
}

proc find_current_dict {} {
    global rdbms bm
    upvar #0 dbdict dbdict
    foreach { key } [ dict keys $dbdict ] {
        set dictname config$key
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            upvar #0 config$key config$key
            set posswkl  [ split  [ dict get $dbdict $key workloads ]]
            set ind [lsearch $posswkl $bm]
            if { $ind != -1 } { set wkltoremove [lreplace $posswkl $ind $ind ]
                if { [ llength $wkltoremove ] > 1 } { 
                    putscli "Error printing dict format more than 2 workloads" 
                    return
                } else {
                    set bmdct [ string tolower [ join [ split $wkltoremove - ] "" ]]
                    set tmpdictforpt [ dict remove [ subst \$config$key ] $bmdct ]
                }
            }
            return $tmpdictforpt
        }
    }
}

proc jobmain { jobid } {
    global rdbms bm
    set query [ hdbcli eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid} ]
    if { $query eq 0 } {
        set tmpdictforpt [ find_current_dict ]
        hdbcli eval {INSERT INTO JOBMAIN(jobid,db,bm,jobdict) VALUES($jobid,$rdbms,$bm,$tmpdictforpt)}
        return 0
    } else {
        return 1
    }
}

proc runninguser { threadid } { 
    global table threadscreated thvnum inrun AVUC vustatus jobid
    set AVUC "run"
    set message [ join " Vuser\  [ expr $thvnum($threadid) + 1]:RUNNING" ]
    catch { putscli $message } 
    hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
    dict set vustatus [ expr $thvnum($threadid) + 1 ] "RUNNING"
}

proc printresult { result threadid } { 
    global vustatus table threadscreated thvnum succ fail totrun totcount inrun AVUC jobid
    incr totcount
    if { $result == 0 } {
        set message [ join " Vuser\  [expr $thvnum($threadid) + 1]:FINISHED SUCCESS" ]
        catch {putscli $message } 
        hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
        dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH SUCCESS"
    } else {
        set message [ join " Vuser\ [expr $thvnum($threadid) + 1]:FINISHED FAILED" ]
        catch {putscli $message } 
        hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
        dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH FAILED"
    }
    if { $totrun == $totcount } {
        set AVUC "complete"
        if { [ info exists inrun ] } { unset inrun }
        catch { putscli "ALL VIRTUAL USERS COMPLETE" }
        hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, "ALL VIRTUAL USERS COMPLETE")}
        refreshscript
        TclReadLine::prompt
    }
}

proc tk_messageBox { args } { 
    global jobid
    set messind [ lsearch $args -message ]
    if { $messind eq -1 } { 
        set message "tk_messageBox with unknown message"
    } else {
        set message [ lindex $args [expr $messind + 1] ]
    }
    hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
    putscli $message
    set typeind [ lsearch $args yesno ]
    if { $typeind eq -1 } { set yesno "false" 
    } else {
        set yesno "true"
    }
    if { $yesno eq "true" } {
        putscli "Enter yes or no: replied yes"
        return "yes"
        #putscli "Enter yes or no: "
        #Delete 2 lines above for interactive response
        gets stdin reply
        set yntoup [ string toupper $reply ]
        if { [ string match NO $yntoup ] } { 
            putscli "replied no"
        return "no" } else { 
            putscli "replied yes"
        return "yes" }
    }
    return
}

rename myerrorproc _myerrorproc
proc myerrorproc { id info } {
    global threadsbytid jobid
    if { ![ info exists jobid ] } { set jobid 0 }
    if { ![string match {*index*} $info] } {
        if { [ string length $info ] == 0 } {
            set message "Warning: a running Virtual User was terminated, any pending output has been discarded"
            putscli $message
            hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
        } else {
            if { [ info exists threadsbytid($id) ] } {
                set vuser [expr $threadsbytid($id) + 1]
                set info "Error in Virtual User [$vuser]: $info"
                putscli $info
                hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, $vuser, $info)}
            }  else {
                if {[string match {*.tc*} $info]} {
                    putscli "Warning: Transaction Counter stopped, connection message not displayed"
                    hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $info)}
                } else {
                    ;
                    #Background Error from Virtual User suppressed
                }
            }
        }
    }
}

rename Log _Log
proc Log {id msg lastline} {
    global tids threadsbytid jobid
    catch {putscli [ join " Vuser\ [expr $threadsbytid($id) + 1]:$lastline" ]} 
    set vuser [expr $threadsbytid($id) + 1]
    set lastline [ string trimright $lastline ]
    hdbcli eval {INSERT INTO JOBOUTPUT VALUES($jobid, $vuser, $lastline)}
}

proc ed_edit_clear {} {
    global _ED lprefix
    if {[ lindex [ split [ join [ stacktrace ] ] ] end ] eq "ed_edit_clear" } {
        set lprefix "load"
    }
    set _ED(package) ""
    set _ED(packagekeyname) ""
}

proc .ed_mainFrame.mainwin.textFrame.left.text { args } {
    #this proc reproduces the functionality built into ctext used in the GUI so CLI can do search and replace in scripts
    global _ED
    set offset 0
    set possibleactions {fastinsert fastdelete search} 
    set action [ lindex $args 0 ]
    if { [ lsearch $possibleactions $action ] eq -1 } {
        puts "Error: argument to text command should be one of [ join $possibleactions ]"
        return
    } else {
        switch $action {
            fastinsert {
                if {[string is integer -strict [ lindex $args 1 ]]} { 
                    #Insert at the index given
                    set insertind [ lindex $args 1 ] 
                    set offset 0
                    set substring [ lindex $args 2 ]
                    set _ED(package) [ string insert $_ED(package) $insertind $substring ]
                    #puts "success matched $insertind to insert $substring with offset $offset"
                } elseif { [ string match *\+1l [ lindex $args 1 ]] } {
                    #Insert at the next line after the index
                    #Remove +1l from 2nd arg
                    set insertind [ string range [ lindex $args 1 ] 0 end-3 ]
                    set offset +1l
                    set substring [ lindex $args 2 ]
                    set stringtofind "\n"
                    #find next new line"
                    set nnl [ string first $stringtofind $_ED(package) $insertind ]
#if not able to find new line set last index as end of script
                    if { $nnl eq -1 } { set nnl [ string length $_ED(package) ] }
#puts "insert at $nnl this will be the string inserted $substring"
                    set _ED(package) [ string insert $_ED(package) $nnl "\n$substring" ]
#puts "success matched $insertind to insert $substring with offset $offset"
                } elseif { [ string match end [ lindex $args 1 ]] } {
#Insert at the end
                    set insertind [ string length $_ED(package) ]
                    set offset end
                    set substring [ lindex $args 2 ]
                    append _ED(package) $substring
#puts "success matched $insertind to append $substring with offset $offset"
                } elseif { [ string match end-2l [ lindex $args 1 ]] } {
#insert 2 lines up from the end, used only for the timeproifle 
                    set insertind [ string length $_ED(package) ]
                    set offset end-2l
                    set substring [ lindex $args 2 ]
#For timeprofile we insert inside the last 2 curly braces
                    set stringtofind "\}"
        #set stringtofind2 "\n"
                    set ind [ string last $stringtofind $_ED(package) ]
                    set ind2 [ string last $stringtofind $_ED(package) [ expr $ind - 1 ] ]
                    set ind3 [ string last $stringtofind $_ED(package) [ expr $ind2 - 1 ] ]
                    set _ED(package) [ string insert $_ED(package) [ expr $ind3 + 2 ] $substring ]
#puts "success matched $insertind to insert $substring with offset $offset"
                } else {
                    puts "Error: failed to match arguments for text insert into script : [ lindex $args 0 ] [ lindex $args 1 ]"
                    return
                }
            }
            fastdelete {
#Request to delete characters
#puts "Request to delete :args 0 [ lindex $args 0 ]:args 1 [ lindex $args 1 ]:args 2 [ lindex $args 2 ]"
                if { [ string match *\+1l [ lindex $args 2 ] ] } {
#Requested to delete multiple lines
                    set start [ lindex $args 1 ]
#Remove +1l from 2nd arg
                    set end [ string range [ lindex $args 2 ] 0 end-3 ]
#puts "delete from $start to $end this will be the string deleted \"[ string range $_ED(package) $start $end ]\""
                    set stringtofind "\n"
#find next new line"
                    set endnnl [ string first $stringtofind $_ED(package) $end ]
                    #if not able to find new line set last index as end of script
                    if { $endnnl eq -1 } { set endnnl [ string length $_ED(package) ] }
                    #puts "delete from $start to $endnnl this will be the string deleted \"[ string range $_ED(package) $start $endnnl ]\""
                    set _ED(package) [ string replace $_ED(package) $start $endnnl ]
                } elseif { [ string match "*lineend + 1 char" [ lindex $args 2 ] ] } {
                    #Requested to delete from an index to the end of the line including newline character
                    #puts "Request to delete from [ lindex $args 1 ] to [ lindex $args 1 ] lineend incl newline"
                    set searchtonnl [ lindex [ split [ lindex $args 1 ] ] ]
                    set stringtofind "\n"
                    #Searching for next newline so do not need + 1 char
                    set nnl [ string first $stringtofind $_ED(package) $searchtonnl ]
                    #puts "delete from $searchtonnl to $nnl this will be the string deleted \"[ string range $_ED(package) $searchtonnl $nnl ]\""
                    set _ED(package) [ string replace $_ED(package) $searchtonnl $nnl ]
                } else {
                    puts "Error: failed to match arguments for text delete in script : [ lindex $args 0 ] [ lindex $args 1 ]"
                    return
                }
            }
            search {
                set srchdirection [ lindex $args 1 ] 
                if { $srchdirection eq "-backwards" } {
                    set stringtofind [lindex $args 2]
                    set ind [ string last $stringtofind $_ED(package) ]
                    return $ind
                } elseif { $srchdirection eq "-forwards" } {
                    set stringtofind [lindex $args 2]
                    set ind [ string first $stringtofind $_ED(package) ]
                    return $ind
                } else {
                    puts "Error: failed to match arguments for text search in script : [ lindex $args 0 ] [ lindex $args 1 ]"
                    return
                }
            }	
        }
    }
}

proc pdict {args} {
    set cmd pdict
    set usage "usage: $cmd ?maxlevel? dictionaryValue ?globPattern?..."
    if {[string is integer [lindex $args 0]]} {
        set maxlvl [lindex $args 0]
        set args [lrange $args 1 end]
    } else {
        set maxlvl [llength $args]
    }
    foreach {dvar pat} $args break
    if {$dvar == ""} {error $usage}
    if {$pat  == ""} {set pat "*"}
    set args [lrange $args 2 end]
    upvar __pdict__level __pdict__level
    incr __pdict__level +1
    set sp [string repeat " " [expr $__pdict__level-1]]
    if {[catch {dict keys $dvar $pat} keys]} {
        error "$cmd error: 'dictionaryValue' is no 'dict'\n → $usage\n  → $keys"
    } elseif {[llength $keys]} {
        set size [::tcl::mathfunc::max {*}[lmap k $keys {string length $k}]]
        foreach key $keys {
            set dsubvar [dict get $dvar $key]
            puts -nonewline [format {%s%-*s} $sp $size $key]
            if {$__pdict__level < $maxlvl} {
                set isVal   [catch {dict keys $dsubvar} keys]
                if {[llength $keys] == 0} {
                    puts " = \{\}"
                } elseif {$isVal} {
                    puts " = $dsubvar"
                } else {
                    puts " \{"
                    pdict $maxlvl $dsubvar {*}$args
                    puts "$sp\}"
                }
            } else {
                puts " = $dsubvar"
            }
        }
    } else {
    }
    if {$__pdict__level == 1} {
        unset -nocomplain __pdict__level
    } else {
        incr __pdict__level -1
    }
}

proc numberOfCPUs {} {
  # Windows puts it in an environment variable
  global tcl_platform env
  if {$tcl_platform(platform) eq "windows"} {
    return $env(NUMBER_OF_PROCESSORS)
  }

  # Assume Linux, which has /proc/cpuinfo, but be careful
  if {![catch {open "/proc/cpuinfo"} f]} {
    set cores [regexp -all -line {^processor\s} [read $f]]
    close $f
    if {$cores > 0} {
      return $cores
    }
  }
  return 1
}

proc vuset { args } {
    global virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps opmode
    if {[ llength $args ] != 2} {
        puts {Usage: vuset [vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps] value}
    } else {
        set option [ lindex [ split  $args ]  0 ]
        set ind [ lsearch {vu delay repeat iterations showoutput logtotemp unique nobuff timestamps} $option ]
        if { $ind eq -1 } {
            puts "Error: invalid option"
            puts {Usage: vuset [vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps] value}
            return
        }
        set val [ lindex [ split  $args ]  1 ]
        if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] > 0} {
            puts "Error: Virtual Users exist, destroy with vudestroy before changing settings"
            return
        }
        switch  $option {
            vu {	
                set virtual_users $val
		if { $virtual_users eq "vcpu" } { 
		    set virtual_users [ numberOfCPUs ]
			}
                if { ![string is integer -strict $virtual_users] } {
                    tk_messageBox -message "The number of virtual users must be an integer"
                    puts -nonewline "setting to value: "
                    set virtual_users 1
                    return
                } else {
                    if { $virtual_users < 1 } { tk_messageBox -message "The number of virtual users must be 1 or greater"
                        puts -nonewline "setting to value: "
                        set virtual_users 1
                        return
                    }
                }
                remote_command [ concat vuset vu $val ]
            }
            delay {
                set conpause $val
                if { ![string is integer -strict $conpause] } {
                    tk_messageBox -message "User Delay(ms) must be an integer"
                    puts -nonewline "setting to value: "
                    set conpause 500
                } else {
                    if { $conpause < 1 } { tk_messageBox -message "User Delay(ms) must be 1 or greater"
                        puts -nonewline "setting to value: "
                        set conpause 500
                    }
                }
                remote_command [ concat vuset delay $val ]
            }
            repeat {
                set delayms $val
                if { ![string is integer -strict $delayms] } {
                    tk_messageBox -message "Repeat Delay(ms) must be an integer"
                    puts -nonewline "setting to value: "
                    set delayms 500
                } else {
                    if { $delayms < 1 } { tk_messageBox -message "Repeat Delay(ms) must be 1 or greater"
                        puts -nonewline "setting to value: "
                        set delayms 500
                    }
                }
                remote_command [ concat vuset repeat $val ]
            }
            iterations {
                set ntimes $val
                if { ![string is integer -strict $ntimes] } {
                    tk_messageBox -message "Iterations must be an integer"
                    puts -nonewline "setting to value: "
                    set ntimes 1
                } else {
                    if { $ntimes < 1 } { tk_messageBox -message "Iterations must be 1 or greater"
                        puts -nonewline "setting to value: "
                        set ntimes 1
                    }
                }
                remote_command [ concat vuset iterations $val ]
            }
            showoutput { 
                set suppo $val
                if { ![string is integer -strict $suppo] } {
                    tk_messageBox -message "Show Output must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set suppo 1
                } else {
                    if { $suppo > 1 } { tk_messageBox -message "Show Output must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set suppo 1
                    }
                }
                remote_command [ concat vuset showoutput $val ]
            }
            logtotemp { 
                set optlog $val
                if { ![string is integer -strict $optlog] } {
                    tk_messageBox -message "Log Output must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set optlog 0
                } else {
                    if { $optlog > 1 } { tk_messageBox -message "Log Output must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set optlog 0
                    }
                }
                remote_command [ concat vuset logtotemp $val ]
            }
            unique { 
                set unique_log_name $val
                if { ![string is integer -strict $unique_log_name] } {
                    tk_messageBox -message "Unique Log Name must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set unique_log_name 0
                } else {
                    if { $unique_log_name > 1 } { tk_messageBox -message "Unique Log Name must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set unique_log_name 0
                    }
                }
                remote_command [ concat vuset unique $val ]
            }
            nobuff { 
                set no_log_buffer $val
                if { ![string is integer -strict $no_log_buffer] } {
                    tk_messageBox -message "No Log Buffer must be 0 or 1"
                    puts -nonewline "setting to value:0"
                    set no_log_buffer 0
                } else {
                    if { $no_log_buffer > 1 } { tk_messageBox -message "No Log Buffer must be 0 or 1"
                        puts -nonewline "setting to value:0"
                        set no_log_buffer 0
                    }
                }
                remote_command [ concat vuset nobuff $val ]
            }
            timestamps { 
                set log_timestamps $val
                if { ![string is integer -strict $log_timestamps] } {
                    tk_messageBox -message "Log timestamps must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set log_timestamps 0
                } else {
                    if { $log_timestamps > 1 } { tk_messageBox -message "Log timestamps must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set log_timestamps 0
                    }
                }
                remote_command [ concat vuset timestamps $val ]
            }
            default {
                puts "Unknown vuset option"
                puts {Usage: vuset [vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps] value}
            }
}}}

proc findakey { key2find dictname } {
        upvar #0 $dictname $dictname
        foreach key [dict keys [ set $dictname]] {
                dict for {k v} [dict get [ set $dictname ] $key] {
                if { $k eq $key2find } {
                return $key
                }
                }
        }
return {}
}

proc diset { args } {
    global rdbms opmode
    if {[ llength $args ] != 3} {
        putscli "Error: Invalid number of arguments\nUsage: diset dict key value"
        putscli "Type \"print dict\" for valid dictionaries and keys for $rdbms" 
    } else {
        set dct [ lindex $args 0 ]
        set key2 [ lindex $args 1 ]
        set val [ lindex $args 2 ]
        upvar #0 dbdict dbdict
        foreach { key } [ dict keys $dbdict ] {
            set dictname config$key
            if { [ dict get $dbdict $key name ] eq $rdbms } {
                set dictname config$key
                upvar #0 $dictname $dictname
                if {[dict exists [ set $dictname ] $dct ]} {
                    if {[dict exists [ set $dictname ] $dct $key2 ]} {
                        set previous [ dict get [ set $dictname ] $dct $key2 ]
                        if { $previous eq [ concat $val ] } {
                            putscli "Value $val for $dct:$key2 is the same as existing value $previous, no change made"
                        } else {
                            if { [ string match *driver $key2 ] && ![ string match *odbc_driver $key2 ] } {
                                putscli "Clearing Script, reload script to activate new setting"
                                clearscript
                                if { $val != "test" && $val != "timed"  } {	
                                    putscli "Error: Driver script must be either \"test\" or \"timed\""
                                    return
                                }	
                            }
                            if { [catch {dict set $dictname $dct $key2 [ concat $val ] } message]} {
                                putscli "Failed to set Dictionary value: $message"
                            } else {
                                putscli "Changed $dct:$key2 from $previous to [ concat $val ] for $rdbms"
                              	#Save new value to SQLite
                              	SQLiteUpdateKeyValue $key $dct $key2 $val
                                remote_command [ concat diset $dct $key2 [ list \{$val\} ]]
                        }}
                    		} else {
		       		set key2find [ findakey $key2 $dictname ]
                       		if { [ string length $key2find ] > 0 } {
                        	putscli "Dictionary \"$dct\" for $rdbms exists but key \"$key2\" doesn't, key \"$key2\" is in the \"$key2find\" dictionary"
                        	} else {
                        	putscli "Dictionary \"$dct\" for $rdbms exists but key \"$key2\" doesn't, key \"$key2\" cannot be found in any $rdbms dictionary"
                        	}
                        	putscli "Type \"print dict\" for valid dictionaries and keys for $rdbms"
                    	}
                } else {
                    putscli {Usage: diset dict key value}
                    putscli "Dictionary \"$dct\" for $rdbms does not exist"
                    putscli "Type \"print dict\" for valid dictionaries and keys for $rdbms"
                }
}}}}

proc librarycheck {} {
    upvar #0 dbdict dbdict
    dict for {database attributes} $dbdict {
        dict with attributes {
            lappend dbl $name
            lappend prefixl $prefix
            lappend libl $library
        }
    }
    foreach db $dbl library $libl {
        puts "Checking database library for $db"
        if { [ llength $library ] > 1 } { 
            set version [ lindex $library 1 ]
            set library [ lindex $library 0 ]
            set cmd "package require $library $version"
        } else {
            set cmd "package require $library"
        }
        if [catch {eval $cmd} message] { 
            puts "Error: failed to load $library - $message" 
            if {[string match windows $::tcl_platform(platform)]} {
                puts "Ensure that $db client libraries are installed and the location in the PATH environment variable"
            } else {
                puts "Ensure that $db client libraries are installed and the location in the LD_LIBRARY_PATH environment variable"
            }
        } else {
            puts "Success ... loaded library $library for $db" 
        }
    }
}

proc dbset { args } {
    global rdbms bm opmode
    if {[ llength $args ] != 2} {
        putscli {Usage: dbset [db|bm] value}
    } else {
        set option [ lindex [ split  $args ]  0 ]
        set ind [ lsearch {db bm} $option ]
        if { $ind eq -1 } {
            putscli "Error: invalid option"
            putscli {Usage: dbset [db|bm] value}
            return
        }
        set val [ lindex [ split  $args ]  1 ]
        switch  $option {
            db {
                upvar #0 dbdict dbdict
                dict for {database attributes} $dbdict {
                    dict with attributes {
                        lappend dbl $name
                        lappend prefixl $prefix
                    }
                }
                set ind [ lsearch $prefixl $val ]
                if { $ind eq -1 } {
                    putscli "Unknown prefix $val, choose one from $prefixl"
                } else {
                    set rdbms [ lindex $dbl $ind ]
                    remote_command [ concat dbset db $val ]
                    putscli "Database set to $rdbms"
                    SQLiteUpdateKeyValue "generic" "benchmark" "rdbms" $rdbms
                }
            }	
            bm {
                set toup [ string toupper $val ]
                if { [ string match ???-? $toup ] || [ string match ?????-? $toup ] } { set dashformat "true" } else { set dashformat "false" }
                upvar #0 dbdict dbdict
                foreach { key } [ dict keys $dbdict ] {
                    set dictname config$key
                    if { [ dict get $dbdict $key name ] eq $rdbms } {
                        set posswkl  [ split  [ dict get $dbdict $key workloads ]]
                        set posswkl2 [ regsub -all {(TP)(C)(-[CH])} $posswkl {\1RO\2\3} ]
                        if { $dashformat } {
                            set ind [ lsearch [ concat $posswkl $posswkl2 ] $toup ]
                            if { $ind eq -1 } {
                                putscli "Unknown benchmark $toup, choose one from $posswkl2 (or compatible names $posswkl)"
                            } else {
                                set dicttoup [ regsub -all {(TP)(RO)(C-[CH])} $toup {\1\3} ]
                                set bm $dicttoup
                                remote_command [ concat dbset bm $dicttoup ]
                                putscli "Benchmark set to $toup for $rdbms"
                                SQLiteUpdateKeyValue "generic" "benchmark" "bm" $bm
                            }
                        } else {
                            putscli "Unknown benchmark $toup, choose one from $posswkl2 (or compatible names $posswkl)"
                        }
                    }
            }}
            default {
                putscli "Unknown dbset option"
                putscli {Usage: dbset [db|bm|config] value}
            }
        }
    }
}

proc print { args } {
    global _ED rdbms bm virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps gen_count_ware gen_scale_fact gen_directory gen_num_vu
    if {[ llength $args ] != 1} {
        puts {Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|vucomplete|datagen|tcconf]}
    } else {
        set ind [ lsearch {db bm dict script vuconf vucreated vustatus vucomplete datagen tcconf} $args ]
        if { $ind eq -1 } {
            puts "Error: invalid option"
            puts {Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|vucomplete|datagen|tcconf]}
            return
        }
        switch $args {
            db {
                upvar #0 dbdict dbdict
                dict for {database attributes} $dbdict {
                    dict with attributes {
                        lappend dbl $name
                        lappend prefixl $prefix
                    }
                }
                puts "Database $rdbms set.\nTo change do: dbset db prefix, one of:"
                foreach a $dbl b $prefixl { puts -nonewline "$a = $b " }
            }
            bm {
                puts "Benchmark set to $bm"
            }
            script {
                if { [ string length $_ED(package) ] eq 0  } {
                    puts "\nNo Script loaded: Load with loadscript\n"
                } else {
                    puts $_ED(package)
                }
            }
            dict {
                #only print the part of dict for the current workload
                upvar #0 dbdict dbdict
                foreach { key } [ dict keys $dbdict ] {
                    set dictname config$key
                    if { [ dict get $dbdict $key name ] eq $rdbms } {
                        upvar #0 config$key config$key
                        set posswkl  [ split  [ dict get $dbdict $key workloads ]]
                        set ind [lsearch $posswkl $bm]
                        if { $ind != -1 } { set wkltoremove [lreplace $posswkl $ind $ind ] 
                            if { [ llength $wkltoremove ] > 1 } { puts "Error printing dict format more than 2 workloads" } else {
                                set bmdct [ string tolower [ join [ split $wkltoremove - ] "" ]]
                                set tmpdictforpt [ dict remove [ subst \$config$key ] $bmdct ]
                            }
                        }
                        puts "Dictionary Settings for $rdbms"
                        pdict 2 $tmpdictforpt
                }}
            }
            vuconf {
                foreach i { "Virtual Users" "User Delay(ms)" "Repeat Delay(ms)" "Iterations" "Show Output" "Log Output" "Unique Log Name" "No Log Buffer" "Log Timestamps" } j { virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps } {
                    puts "$i = [ set $j ]"
                }
            }
            vucreated {
                puts "[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] Virtual Users created"
            }
            vustatus {
                vustatus
            }
            vucomplete {
                vucomplete
            }
            datagen {
                if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
                if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
                if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
                if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
                if {  ![ info exists bm ] } { set bm "TPC-C" }
                if { $bm eq "TPC-C" } {
                    puts "Data Generation set to build a $bm schema for $rdbms with $gen_count_ware warehouses with $gen_num_vu virtual users in $gen_directory" 
                } else {
                    puts "Data Generation set to build a $bm schema for $rdbms with $gen_scale_fact scale factor with $gen_num_vu virtual users in $gen_directory" 
                }
            }
            tcconf {
                upvar #0 genericdict genericdict
                dict with genericdict { pdict 2 $transaction_counter }
            }
            default {
                puts "unknown print option"
            }
        }
    }
}

proc ed_status_message { flag message } {
    #Suppress GUI status messages in CLI
    #puts $message
}

proc vucreate {} {
    global _ED lprefix vustatus opmode
    if { [ string length $_ED(package) ] eq 0  } {
    #Try loadscript and recheck before asking the user to load the script if it is empty
       catch {loadscript}
       if { [ string length $_ED(package) ] eq 0  } {
       putscli "No Script loaded: Load script before creating Virtual Users"
       } else {
        #Call vucreate recursively, first call loaded script, 2nd to create VUs
        vucreate
       }
    } else {
        if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] > 0} {
            putscli "Error: Virtual Users exist, destroy with vudestroy before creating"
            return
        }
        unset -nocomplain vustatus
        set vustatus {}
        remote_command [ concat vucreate ]
        if { [catch {load_virtual} message]} {
            putscli "Failed to create virtual users: $message"
        } else {
            if { $lprefix eq "loadtimed" } {
                putscli "[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] Virtual Users Created with Monitor VU"
            } else {
                putscli "[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] Virtual Users Created"
            }
        }
    }
}

proc vudestroy {} {
    global threadscreated threadsbytid vustatus AVUC opmode
    if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] > 0} {
        tsv::set application abort 1
        if { [catch {ed_kill_vusers} message]} {
            putscli "Virtual Users remain running in background or shutting down, retry"
        } else {
            remote_command [ concat vudestroy ]
            set x 0
            set checkstop 0
            while {!$checkstop} {
                incr x
                after 1000
                update
                if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] eq 0} {
                    set checkstop 1
                    putscli "vudestroy success"
                    unset -nocomplain AVUC
                    unset -nocomplain vustatus
                } 
                if { $x eq 20 } { 
                    set checkstop 1 
                    putscli "Virtual Users remain running in background or shutting down, retry"
                }
            }
        }	
    } else {
        if { $opmode eq "Replica" } {
            #In Primary Replica Mode ed_kill_vusers may have already been called from Primary so thread::names is 1
            unset -nocomplain AVUC
            unset -nocomplain vustatus
            putscli "vudestroy from Primary, Replica status clean up"
        } else {
            putscli "No Virtual Users found to destroy"
        }
    }
}

proc vustatus {} {
    global vustatus
    if { ![info exists vustatus] } {
        puts "No Virtual Users found"
    } else { 
        if { [ catch {[ set vuoput [ pdict 1 $vustatus ] ]}] } {
            puts "Error in finding VU status"
        } else {
            puts $vuoput
        }
    }
}

proc vucomplete {} {
    global AVUC
    if { ![info exists AVUC] } {
        return false
    } else {
        if { $AVUC eq "complete" } { 
            return true 
        } else {
            return false
        }
}}

proc loadscript {} {
    global bm _ED opmode
    if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
    if { [ string length $_ED(package) ] > 0 } { 
        putscli "Script loaded, Type \"print script\" to view"
    } else {
        putscli "Error:script failed to load"
    }
    remote_command [ concat loadscript ]
    #Save dict(all config) to SQLite, if need group saving, uncomment
    #upvar #0 dbdict dbdict
    #foreach { key } [ dict keys $dbdict ] {
    #  if { [ dict get $dbdict $key name ] eq $rdbms } {
    #    set dbname $key
    #    set dictname config$key
    #    upvar #0 $dictname $dictname
    #    break
    #  }
    #}
    #Dict2SQLite $dbname [ dict get [ set $dictname ] ]
}

proc clearscript {} {
    global bm _ED opmode
    set _ED(package) ""
    if { [ string length $_ED(package) ] eq 0 } { 
        putscli "Script cleared"
    } else {
        putscli "Error:script failed to clear"
    }
    remote_command [ concat clearscript ]
}

proc refreshscript {} {
    global bm _ED
    set _ED(package) ""
    if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
    remote_command [ concat refreshscript ]
}

proc customscript { customscript } {
    global _ED
    if { [ file exists $customscript ] && [ file isfile $customscript ] && [ file extension $customscript ] eq ".tcl" } {
        set _ED(file) $customscript
    } else {
        puts "Usage: customscript scriptname.tcl"
        return
    }
    if {$_ED(file) == ""} {return}
    if {![file readable $_ED(file)]} {
        ed_error "File \[$_ED(file)\] is not readable."
        return
    }
    if {[catch "open \"$_ED(file)\" r" fd]} {
        ed_error "Error while opening $_ED(file): \[$fd\]"
    } else {
        set _ED(package) "[read $fd]"
        close $fd
        puts "Loaded $customscript"
    }
}

proc distributescript {} {
    global opmode masterlist
    if { $opmode != "Primary" } { 
        puts "Error: Cannot distribute script if not in Primary mode"
    } else {
        if { [ llength $masterlist ] eq 0 } {
            puts "Error: Primary has no Replicas to distribute to"
        } else {
            distribute
        }
    }
}

proc build_schema {} {
    global _ED
    #This runs the schema creation
    upvar #0 dbdict dbdict
    global _ED bm rdbms
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set prefix [ dict get $dbdict $key prefix ]
            if { $bm == "TPC-C" }  {
                set command [ concat [subst {build_$prefix}]tpcc ]
            } else {
                set command [ concat [subst {build_$prefix}]tpch ]
            }
            eval $command
            break
        }
    }
    if { [ string length $_ED(package) ] > 0 } { 
        #yes was pressed
        run_virtual
    } else {
        #no was pressed
        puts "Schema creation cancelled"
    }
}

proc buildschema {} {
    global virtual_users maxvuser rdbms bm threadscreated jobid
    if { [ info exists threadscreated ] } {
        puts "Error: Cannot build schema with Virtual Users active, destroy Virtual Users first"
        return
    }
    set jobid [guid]
    if { [jobmain $jobid] eq 1 } {
        dict set jsondict error message "Jobid already exists or error in creating jobid in JOBMAIN table"
        #return
    }
    upvar #0 dbdict dbdict
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set dictname config$key
            #set dbname $key
            upvar #0 $dictname $dictname
            break
        }
    }
    if { $bm eq "TPC-C" } {
        set cwkey [ lsearch [ join [ set $dictname ]] *count_ware ]
        set buildcw [ lindex [ join [ set $dictname ]] [ expr $cwkey + 1]]
        set vukey [ lsearch [ join [ set $dictname ]] *num_vu ]
        set vuname [ lsearch -inline [ join [ set $dictname ]] *num_vu ]
        set buildvu [ lindex [ join [ set $dictname ]] [ expr $vukey + 1]]
        if { ![string is integer -strict $buildvu ] || $buildvu < 1 || $buildvu > 1024 } {
            puts "Error: Number of virtual users to build schema must be an integer less than 1024"
            return
        }
        if { $buildvu > $buildcw } {
            puts "Error:Build virtual users must be less than or equal to number of warehouses"
            puts "You have $buildvu virtual users building $buildcw warehouses"
            return
        } else {
            if { $buildvu eq 1 } {
                set maxvuser 1
                set virtual_users 1
                clearscript
                puts "Building $buildcw Warehouses(s) with 1 Virtual User"
                if { [ catch {build_schema} message ] } {
                    puts "Error: $message"
                    unset -nocomplain jobid
                }
            } else {
                set maxvuser [ expr $buildvu + 1 ]
                set virtual_users $maxvuser
                clearscript
                puts "Building $buildcw Warehouses with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu)"
                if { [ catch {build_schema} message ] } {
                    puts "Error: $message"
                    unset -nocomplain jobid
                }
            }
        }
    } else {
        set sfkey [ lsearch [ join [ set $dictname ]] *scale_fact ]
        set buildsf [ lindex [ join [ set $dictname ]] [ expr $sfkey + 1]]
        set vukey [ lsearch [ join [ set $dictname ]] *num_tpch_threads ]
        set vuname [ lsearch -inline [ join [ set $dictname ]] *num_tpch_threads ]
        set buildvu [ lindex [ join [ set $dictname ]] [ expr $vukey + 1]]
        if { ![string is integer -strict $buildvu ] || $buildvu < 1 || $buildvu > 1024 } {
            puts "Error: Number of virtual users to build schema must be an integer less than 1024"
            return
        }
        set validvalues {1 10 30 100 300 1000 3000 10000 30000 100000}
        set ind [ lsearch $validvalues $buildsf ]
        if { $ind eq -1 } {
            puts "Error: Scale Factor must be a value in $validvalues"
            return
        }
        if { $buildvu eq 1 } { set maxvuser 1 } else {
            set maxvuser [ expr $buildvu + 1 ]
        }
        set virtual_users $maxvuser
        clearscript
        puts "Building Scale Factor $buildsf with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu)"
        if { [ catch {build_schema} message ] } {
            puts "Error: $message"
        }
    }
    #Save dict(all config) to SQLite, if need group saving, uncomment
    #Dict2SQLite $dbname [ dict get [ set $dictname ] ]
    #Add automated waittocomplete to buildschema
    _waittocomplete
}

proc init_job_tables { } {
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict sqlitedb sqlitedb_dir]} {
        set sqlite_db [ dict get $genericdict sqlitedb sqlitedb_dir ]
        if { [string toupper $sqlite_db] eq "TMP" || [string toupper $sqlite_db] eq "TEMP" } {
            set tmpdir [ findtempdir ]
            if { $tmpdir != "notmpdir" } {
                set sqlite_db [ file join $tmpdir hammer.DB ]
            } else {
                puts "Error Database Directory set to TMP but couldn't find temp directory"
            }
        }
    } else {
        set sqlite_db ":memory:"
    }
    if [catch {sqlite3 hdbcli $sqlite_db} message ] {
        puts "Error initializing SQLite database : $message"
        return
    } else {
        catch {hdbcli timeout 30000}
        #hdbcli eval {PRAGMA foreign_keys=ON}
        if { $sqlite_db eq ":memory:" } {
            catch {hdbcli eval {DROP TABLE JOBMAIN}}
            catch {hdbcli eval {DROP TABLE JOBTIMING}}
            catch {hdbcli eval {DROP TABLE JOBTCOUNT}}
            catch {hdbcli eval {DROP TABLE JOBOUTPUT}}
            if [catch {hdbcli eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
                puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
                return
            } elseif [ catch {hdbcli eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
            } elseif [ catch {hdbcli eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
                return
            } elseif [ catch {hdbcli eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBOUTPUT table in SQLite in-memory database : $message"
                return
            } else {
                catch {hdbcli eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
                catch {hdbcli eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
                catch {hdbcli eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
                catch {hdbcli eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
                puts "Initialized new SQLite in-memory database"
            }
        } else {
            if [catch {set tblname [ hdbcli eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
                puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
                return
            } else {
                if { $tblname eq "" } {
                    if [catch {hdbcli eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
                        puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
                        return
                    } elseif [ catch {hdbcli eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                        puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
                        return
                    } elseif [ catch {hdbcli eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                        puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
                        return
                    } elseif [catch {hdbcli eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
                        puts "Error creating JOBOUTPUT table in SQLite on-disk database : $message"
                        return
                    } else {
                        catch {hdbcli eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
                        catch {hdbcli eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
                        catch {hdbcli eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
                        catch {hdbcli eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
                        puts "Initialized new SQLite on-disk database $sqlite_db"
                    }
                } else {
                    puts "Initialized SQLite on-disk database $sqlite_db using existing tables"
                }
            }
        }
    }
}

proc jobs { args } {
    #global ws_port
    switch [ llength $args ] {
        0 {
            #Query all jobs
            set res [ getjob "" ]
            return $res
        }
        1 {
            set param [ lindex [ split  $args ]  0 ]
            #List results for all jobs
            if [ string equal $param "result" ] {
                #set alljobs [ rest::format_json [ jobs ]]
                set alljobs [ jobs ]
                foreach jobres $alljobs {
                    set res [ getjob "jobid=$jobres&result" ]
                    putscli $res
                }
            } elseif [ string equal $param "timestamp" ] {
                #set alljobs [ rest::format_json [ jobs ]]
                set alljobs [ jobs ]
                foreach jobres $alljobs {
                    set res [getjob "jobid=$jobres&timestamp" ]
                    putscli $res
                }	
            } else {
                #Query one jobid
                set jobid $param
                set res [getjob "jobid=$jobid" ]
                putscli $res
            }
        }
        2 {
            #Query status, result, vu number or delete job data for one jobid
            #jobid=TEXT&status param is status
            #jobid=TEXT&result param is result
            #jobid=TEXT&delete param is delete
            #jobid=TEXT&timestamp param is timestamp
            #jobid=TEXT&dict param is dict
            #jobid=TEXT&timing param is timing
            #jobid=TEXT&db param is db
            #jobid=TEXT&bm param is bm
            #jobid=TEXT&tcount param is tcount
            #jobid=TEXT&vu=INTEGER param is an INTEGER identifying the vu number
            set jobid [ lindex [ split  $args ]  0 ]
            set cmd [ lindex [ split  $args ]  1 ]
            if [ string is entier $cmd ] { set cmd "vu=$cmd" }
            set res [getjob "jobid=$jobid&$cmd" ]
            putscli $res
        }
        3 {
            #jobs?jobid=TEXT&timing&vu param is timing
            set jobid [ lindex [ split  $args ]  0 ]
            set cmd [ lindex [ split  $args ]  1 ]
            set vusel [ lindex [ split  $args ]  2 ]
            if { $cmd != "timing" } {
                #set body { "type": "error", "key": "message", "value": "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID" } 
                #set res [rest::post http://localhost:$ws_port/echo $body ]
                putscli "Error: Jobs Three Parameter Usage: jobs jobid=JOBID&timing&vu=VUID"
            } else {
                #Three arguments 2nd parameter is timing
                if [ string is entier $vusel ] { set vusel "vu=$vusel" }
                set res [getjob "jobid=$jobid&$cmd&$vusel" ]
                putscli $res
            }
        }
        default {
            #set body { "type": "error", "key": "message", "value": "Usage: jobs query=parameter" } 
            #set res [rest::post http://localhost:$ws_port/echo $body ]
            putscli "Error: Usage: jobs query=parameter"
        }
    }
}

interp alias {} job {} jobs

proc getjob { query } {
    global bm
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline jobsoutput]} {
        set outputformat [ dict get $genericdict commandline jobsoutput ]
    } else {
        set outputformat "text"
    }
    
    #set query [ wapp-param QUERY_STRING ]
    set params [ split $query & ]
    set paramlen [ llength $params ]
    #No parameters list jobids
    if { $paramlen eq 0 } {
        set joboutput [ hdbcli eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
        #wapp-mimetype application/json
        #wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        set huddleobj [ huddle compile {list} $joboutput ]
        if { $outputformat eq "JSON" } {
            putscli [ huddle jsondump $huddleobj ]
        } else {
            putscli [ join $joboutput "\n" ]
        }
        return
    } else {
        if { $paramlen >= 1 && $paramlen <= 3 } {
            foreach a $params {
                lassign [split $a =] key value
                dict append paramdict $key $value
            }
        } else {
            #dict set jsondict error message "Usage: jobs?query=parameter"
            #wapp-2-json 2 $jsondict
            putscli "Error: Usage: jobs query=parameter"
            return
        }
        if { $paramlen eq 3 } {
            if { [ dict keys $paramdict ] != "jobid timing vu" } {
                #dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
                #wapp-2-json 2 $jsondict
                putscli "Error: Jobs Three Parameter Usage: jobs jobid=JOBID&timing&vu=VUID"
                return
            } else {
                #3 parameter case of 1-jobid 2-timing 3-vu
                set jobid [ dict get $paramdict jobid ]
                set vuid [ dict get $paramdict vu ]
                if [ string is entier $vuid ] {
                    unset -nocomplain jobtiming
                    set jobtiming [ dict create ]
                    hdbcli eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and VU=$vuid and SUMMARY=0 ORDER BY RATIO_PCT DESC}  {
                        set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
                        dict append jobtiming $procname $timing
                    }
                    if { ![ dict size $jobtiming ] eq 0 } {
                        #wapp-2-json 2 $jobtiming
                        return
                    } else {
                        #dict set jsondict error message "No Timing Data for VU $vuid for JOB $jobid: jobs?jobid=JOBID&timing&vu=VUID"
                        #wapp-2-json 2 $jsondict
                        putscli "No Timing Data for VU $vuid for JOB $jobid: jobs jobid=JOBID&timing&vu=VUID"
                        return
                    }
                } else {
                    #dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
                    #wapp-2-json 2 $jsondict
                    putscli "Jobs Three Parameter Usage: jobs jobid=JOBID&timing&vu=VUID"
                    return
                }
            }
        }
    }
    #1 parameter
    if { $paramlen eq 1 } {
        if { [ dict keys $paramdict ] eq "jobid" } {
            set jobid [ dict get $paramdict jobid ]
            set query [ hdbcli eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid} ]
            if { $query eq 0 } {
                #dict set jsondict error message "Jobid $jobid does not exist"
                #wapp-2-json 2 $jsondict
                putscli "Jobid $jobid does not exist"
                return
            } else {
                set joboutput [ hdbcli eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
                set huddleobj [ huddle compile {list} $joboutput ]
                if { $outputformat eq "JSON" } {
                    putscli [ huddle jsondump $huddleobj ]
                } else {
                    set res ""
                    set num 0
                    foreach row $joboutput {
                        if { $num == 0 } {
                            set res "Virtual User $row:"
                            incr num
                        } else {
                            set res "$res $row"
                            putscli $res
                            set num 0
                        }
                    }
                    #putscli [ join $joboutput "\n" ]
                }
                #wapp-mimetype application/json
                #wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
            }
        } else {
            #dict set jsondict error message "Jobs One Parameter Usage: jobs?jobid=TEXT"
            #wapp-2-json 2 $jsondict
            putscli "Jobs One Parameter Usage: jobs jobid=TEXT"
            return
        }
        #2 or more parameters
    } else {
        if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid delete" || [ dict keys $paramdict ] eq "jobid timestamp" || [ dict keys $paramdict ] eq "jobid dict" || [ dict keys $paramdict ] eq "jobid timing" || [ dict keys $paramdict ] eq "jobid db" ||  [ dict keys $paramdict ] eq "jobid bm" || [ dict keys $paramdict ] eq "jobid tcount" } {
            set jobid [ dict get $paramdict jobid ]
            if { [ dict keys $paramdict ] eq "jobid vu" } {
                set vuid [ dict get $paramdict vu ]
            } else {
                if { [ dict keys $paramdict ] eq "jobid result" } {
                    set vuid 1
                } else {
                    set vuid 0
                }
            }
            set query [ hdbcli eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
            if { $query eq 0 } {
                #dict set jsondict error message "Jobid $jobid for virtual user $vuid does not exist"
                #wapp-2-json 2 $jsondict
                putscli "Jobid $jobid for virtual user $vuid does not exist"
                return
            } else {
                if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" } {
                    set joboutput [ hdbcli eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
                    set huddleobj [ huddle compile {list} $joboutput ]
                    if { $outputformat eq "JSON" } {
                        putscli [ huddle jsondump $huddleobj ]
                    } else {
                        set res ""
                        set num 0
                        foreach row $joboutput {
                            if { $num == 0 } {
                                set res "Virtual User $row:"
                                incr num
                            } else {
                                set res "$res $row"
                                putscli $res
                                set num 0
                            }
                        }
                        #putscli [ join $joboutput "\n" ]
                    }
                    #wapp-mimetype application/json
                    #wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
                    #putscli $joboutput
                    return
                }
                if { [ dict keys $paramdict ] eq "jobid delete" } {
                    set joboutput [ hdbcli eval {DELETE FROM JOBMAIN WHERE JOBID=$jobid} ]
                    set joboutput [ hdbcli eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid} ]
                    set joboutput [ hdbcli eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid} ]
                    set joboutput [ hdbcli eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid} ]
                    #dict set jsondict success message "Deleted Jobid $jobid"
                    #wapp-2-json 2 $jsondict
                    putscli "Deleted Jobid $jobid"
                } else {
                    if { [ dict keys $paramdict ] eq "jobid result" } {
                        if { $bm eq "TPC-C" } { 
                            set tstamp ""
                            set tstamp [ join [ hdbcli eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
                            set joboutput [ hdbcli eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
                            set activevu [ lsearch -glob -inline $joboutput "*Active Virtual Users*" ]
                            set result [ lsearch -glob -inline $joboutput "TEST RESULT*" ]
                        } else {
                            set joboutput [ hdbcli eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
                            set result [ lsearch -all -glob -inline $joboutput "Completed*" ]
                        }
                        if { $result eq {} } {
                            set joboutput [ list $jobid "Jobid has no test result" ]
                        } else {
                            if { $activevu eq {} } {
                                set joboutput [ list $jobid $tstamp $result ]
                            } else {
                                set joboutput [ list $jobid $tstamp $activevu $result ]
                            }
                        }
                    } else {
                        if { [ dict keys $paramdict ] eq "jobid timing" } {
                            unset -nocomplain jobtiming
                            set jobtiming [ dict create ]
                            hdbcli eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and SUMMARY=1 ORDER BY RATIO_PCT DESC}  {
                                set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
                                dict append jobtiming $procname $timing
                            }
                            if { ![ dict size $jobtiming ] eq 0 } {
                                #wapp-2-json 2 $jobtiming
                                putscli $jobtiming
                                return
                            } else {
                                #dict set jsondict error message "No Timing Data for JOB $jobid: jobs?jobid=JOBID&timing"
                                #wapp-2-json 2 $jsondict
                                putscli "No Timing Data for JOB $jobid: jobs jobid=JOBID&timing"
                                return
                            }
                        } else {
                            if { [ dict keys $paramdict ] eq "jobid timestamp" } {
                                set joboutput [ hdbcli eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]
                                #wapp-2-json 2 $joboutput
                                putscli $joboutput
                                return
                            } else {
                                if { [ dict keys $paramdict ] eq "jobid dict" } {
                                    set joboutput [ join [ hdbcli eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid} ]]
                                    #wapp-2-json 2 $joboutput
                                    putscli $joboutput
                                    return
                                } else {
                                    if { [ dict keys $paramdict ] eq "jobid tcount" } {
                                        set jobheader [ hdbcli eval {select distinct(db), metric from JOBTCOUNT, JOBMAIN WHERE JOBTCOUNT.JOBID=$jobid AND JOBMAIN.JOBID=$jobid} ]
                                        set joboutput [ hdbcli eval {select counter, JOBTCOUNT.timestamp from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
                                        #dict append jsondict $jobheader $joboutput 
                                        #wapp-2-json 2 $jsondict
                                        putscli $jobheader
                                        putscli $joboutput
                                        return
                                    } else {
                                        if { [ dict keys $paramdict ] eq "jobid db" } {
                                            set joboutput [ join [ hdbcli eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
                                        } else {
                                            if { [ dict keys $paramdict ] eq "jobid bm" } {
                                                set joboutput [ join [ hdbcli eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
                                            } else {
                                                set joboutput [ list $jobid "Cannot find Jobid output" ]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    set huddleobj [ huddle compile {list} $joboutput ]
                    #wapp-mimetype application/json
                    #wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
                    if { $outputformat eq "JSON" } {
                        putscli [ huddle jsondump $huddleobj ]
                    } else {
                        putscli [ join $joboutput "\n" ]
                    }
                }
            }
        } else {
            #dict set jsondict error message "Jobs Two Parameter Usage: jobs?jobid=TEXT&status or jobs?jobid=TEXT&db or jobs?jobid=TEXT&bm or jobs?jobid=TEXT&timestamp or jobs?jobid=TEXT&dict or jobs?jobid=TEXT&vu=INTEGER or jobs?jobid=TEXT&result or jobs?jobid=TEXT&timing or jobs?jobid=TEXT&delete" 
            #wapp-2-json 2 $jsondict
            putscli "Jobs Two Parameter Usage: jobs jobid=TEXT&status or jobs jobid=TEXT&db or jobs jobid=TEXT&bm or jobs jobid=TEXT&timestamp or jobs jobid=TEXT&dict or jobs jobid=TEXT&vu=INTEGER or jobs jobid=TEXT&result or jobs jobid=TEXT&timing or jobs jobid=TEXT&delete"
            return
        }
    }
}

proc keepalive {} {
  #Routine to keep the main thread alive during vurun
  global rdbms bm
  set ka_valid 1
  if {$bm eq "TPC-C"} {
    #For TPC-C we have a rampup and duration time, find these, check they are valid and call _runtimer automatically with these values
    upvar #0 dbdict dbdict
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline keepalive_margin]} {
      set ka_margin [ dict get $genericdict commandline keepalive_margin]
      if {![string is entier $ka_margin]} { 
        set ka_margin 10 
      }
    } else {
      set ka_margin 10
    }
    foreach { key } [ dict keys $dbdict ] {
      if { [ dict get $dbdict $key name ] eq $rdbms } {
        set dictname config$key
        upvar #0 $dictname $dictname
      }
    }
    set rampup_secs [expr {[ get_base_rampup [ set $dictname ]]*60}]
    set duration_secs [expr {[ get_base_duration [ set $dictname ]] *60}]
    foreach { val } [ list $rampup_secs $duration_secs ] {
      if { ![string is entier $val ] || ($val < 60 && $val != 0) } {
        set ka_valid 0
      }
    }
    if { $ka_valid } {
      _runtimer [expr {$rampup_secs + $duration_secs + $ka_margin}]
    } else {
      tk_messageBox -icon warning -message "Cannot detect rampup and duration times, keepalive for main thread not active"
    }
  } else {
    #Workload is TPROC-H, call _waittocomplete to wait until vucomplete message after an indeterminate amount of time
    _waittocomplete
    return
  }
}

proc delete_schema {} {
    global _ED
    #This runs the schema deletion
    upvar #0 dbdict dbdict
    global _ED bm rdbms
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set prefix [ dict get $dbdict $key prefix ]
            if { $bm == "TPC-C" }  {
                set command [ concat [subst {delete_$prefix}]tpcc ]
            } else {
                set command [ concat [subst {delete_$prefix}]tpch ]
            }
            eval $command
            break
        }
    }
    if { [ string length $_ED(package) ] > 0 } { 
        #yes was pressed
        run_virtual
    } else {
        #no was pressed
        puts "Schema deletion cancelled"
    }
}

proc deleteschema {} {
    global virtual_users maxvuser rdbms bm threadscreated
    if { [ info exists threadscreated ] } {
        puts "Error: Cannot delete schema with Virtual Users active, destroy Virtual Users first"
        return
    }
    upvar #0 dbdict dbdict
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set dictname config$key
            #set dbname $key
            upvar #0 $dictname $dictname
            break
        }
    }
    set maxvuser 1
    set virtual_users 1
    clearscript
    puts "Deleting schema with 1 Virtual User"
    if { [ catch {delete_schema} message ] } {
        puts "Error: $message"
    }
}

proc vurun {} {
    global _ED opmode jobid

    set jobid [guid]
    if { [jobmain $jobid] eq 1 } {
        dict set jsondict error message "Jobid already exists or error in creating jobid in JOBMAIN table"
        #return
    }
    
    #If calling vurun and virtual users not created, create them now
    if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] eq 0} {
        vucreate
    }
    #In turn if script is not already loaded vucreate should call loadscript meaning following should not return no workload to run
    if { [ string length $_ED(package) ] > 0 } { 
        remote_command [ concat vurun ]
        if { [ catch {run_virtual} message ] } {
            putscli "Error: $message"
            unset -nocomplain jobid
        } else {
            #Deprecated runtimer replaced with automated keepalive
            keepalive
        }
    } else {
        putscli "Error: There is no workload to run because the Script is empty"
        unset -nocomplain jobid
    }
     if { [ info exists jobid ] } {
        return "jobid=$jobid"
    } else {
        return
    }
}

proc run_datagen {} {
    global _ED bm rdbms threadscreated
    #Clear the Script Editor first to make sure a genuine schema build is run
    ed_edit_clear
    if { [ info exists threadscreated ] } {
        tk_messageBox -icon error -message "Cannot generate data with Virtual Users active, destroy Virtual Users first"
        #clear script editor so cannot be re-run with incorrect v user count
        return 1
    }
    if { $bm == "TPC-C" } {
        gendata_tpcc
    } else {
        gendata_tpch
}}

proc datagenrun {} {
    global _ED
    if { [ catch {run_datagen} message ] } {
        puts "Error: $message"
    }
    if { [ string length $_ED(package) ] > 0 } { 
        #yes was pressed
        run_virtual
    } else {
        #no was pressed
        puts "Data Generation cancelled"
    }
}

proc dgset { args } {
    global rdbms bm gen_count_ware gen_scale_fact gen_directory gen_num_vu maxvuser virtual_users lprefix
    if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
    if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
    if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
    if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
    if {  ![ info exists bm ] } { set bm "TPC-C" }
    if {[ llength $args ] != 2} {
        puts {dgset - Usage: dgset [vu|scale_fact|warehouse|directory]}
    } else {
        set option [ lindex [ split  $args ] 0 ]
        set ind [ lsearch [ list vu scale_fact warehouse directory ] $option ]
        if { $ind eq -1 } {
            puts "Error: invalid option"
            puts {Usage: dgset [vu|scale_fact|warehouse|directory]}
            return
        }
        set val [ lindex [ split  $args ]  1 ]
        switch  $option {
            vu {
                set gen_num_vu $val
                if { $bm eq "TPC-C" } {
                    if { ![string is integer -strict $gen_count_ware] || $gen_count_ware < 1 || $gen_count_ware > 100000 } { 
                        tk_messageBox -message "The number of warehouses must be a positive integer less than or equal to 100000" 
                        #puts -nonewline "setting to value: "
                        set gen_num_vu 1
                        set virtual_users 1
                        return
                    } 
                    if { $gen_num_vu > $gen_count_ware } {
                        puts "Error:Build virtual users must be less than or equal to number of warehouses"
                        puts "You have $gen_num_vu virtual users building $gen_count_ware warehouses"
                        #puts -nonewline "setting to value: "
                        set gen_num_vu $gen_count_ware
                        return
                }}
                if { ![string is integer -strict $gen_num_vu] || $gen_num_vu < 1 || $gen_num_vu > 1024 } { 
                    tk_messageBox -message "The number of virtual users must be a positive integer less than 1024" 
                    #puts -nonewline "setting to value: "
                    set gen_num_vu 1
                    set virtual_users 1
                    return
                } else {
                    set maxvuser [ expr $gen_num_vu + 1 ]
                    set virtual_users $maxvuser 
                    puts "Set virtual users to $gen_num_vu for data generation" 
                }
            }
            scale_fact {
                set gen_scale_fact $val
                set validvalues {1 10 30 100 300 1000 3000 10000 30000 100000}
                set ind [ lsearch $validvalues $gen_scale_fact ]
                if { $ind eq -1 } {
                    puts "Error: Scale Factor must be a value in $validvalues"
                    set gen_scale_fact 1
                    return
                }
            }
            warehouse {
                set gen_count_ware $val
                if { ![string is integer -strict $gen_count_ware] } {
                    tk_messageBox -message "The number of virtual users must be an integer"
                    puts -nonewline "setting to value: "
                    set gen_num_vu 1
                    set virtual_users 1
                    return
                } else {
                    if { $virtual_users < 1 } { tk_messageBox -message "The number of virtual users must be 1 or greater"
                        puts -nonewline "setting to value: "
                        set gen_num_vu 1
                        set virtual_users 1
                        return
                    }
                    if { $gen_num_vu > $gen_count_ware } {
                        puts "Error:Build virtual users must be less than or equal to number of warehouses"
                        puts "You have $gen_num_vu virtual users building $gen_count_ware warehouses"
                        set gen_num_vu $gen_count_ware
                        return
                    }
            }}
            directory {
                set tmp $gen_directory
                set gen_directory $val
                if {![file writable $gen_directory]} {
                    tk_messageBox -message "Files cannot be written to chosen directory you must create $gen_directory before generating data" 
                    puts -nonewline "Setting back to "
                    set gen_directory $tmp
                }
            }
        }
    }
}

proc loadtpcc {} {
    upvar #0 dbdict dbdict
    global _ED rdbms lprefix
    set _ED(packagekeyname) "TPROC-C"
    ed_status_message -show "TPROC-C Driver Script"
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set dictname config$key
            upvar #0 $dictname $dictname
            set prefix [ dict get $dbdict $key prefix ]
            set drivername [ concat [subst {$prefix}]_driver ]
            set drivertype [ dict get [ set $dictname ] tpcc $drivername ]
            if { $drivertype eq "test" } { set lprefix "load" } else { set lprefix "loadtimed" }
            set command [ concat [subst {$lprefix$prefix}]tpcc ]
            eval $command
            set allw [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *allwarehouse ]
            if { $allw != "" } {
                set db_allwarehouse [ dict get [ set $dictname ] tpcc $allw ]
                set asyscl [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *async_scale ]
                if { $asyscl != "" } {
                    set db_async_scale [ dict get [ set $dictname ] tpcc $asyscl ]
                } else {
                    set db_async_scale "false"
                }
                if { $db_allwarehouse } { shared_tpcc_functions "allwarehouse" $db_async_scale }
            }
            upvar #0 genericdict genericdict
            if {[dict exists $genericdict timeprofile profiler]} {
                set profiler [ dict get $genericdict timeprofile profiler]
            }
            if { $profiler eq "xtprof" } { set profile_func "xttimeprofile" }  else { set profile_func "ettimeprofile" }
            set timep [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *timeprofile ]
            if { $timep != "" } {
                set db_timeprofile [ dict get [ set $dictname ] tpcc $timep ]
                if { $db_timeprofile } { shared_tpcc_functions $profile_func "false" }
            }
            break
        }
    }
}

proc loadtpch {} {
    upvar #0 dbdict dbdict
    global _ED rdbms lprefix
    if {  [ info exists lprefix ] } { ; } else { set lprefix "load" }
    global cloud_query mysql_cloud_query pg_cloud_query
    set _ED(packagekeyname) "TPROC-H"
    puts "TPROC-H Driver Script"
    foreach { key } [ dict keys $dbdict ] {
        if { [ dict get $dbdict $key name ] eq $rdbms } {
            set dictname config$key
            upvar #0 $dictname $dictname
            set prefix [ dict get $dbdict $key prefix ]
            set command [ concat [subst {load$prefix}]tpch ]
            set cloudq [ lsearch -inline [ dict get [ set $dictname ] tpch ] *cloud_query ]
            if { $cloudq != "" } {
                set db_cloud_query [ dict get [ set $dictname ] tpch $cloudq ]
                if { $db_cloud_query } { set command [ concat [subst {load$prefix}]cloud ] }
            }
            eval $command
            set lprefix "load"
            break
        }
    }
}

proc switchmode {{assignmode "current"} {assignid 0} {assignhost "localhost"} args} {
    global opmode hostname id masterlist mode
    upvar 1 oldmode oldmode
    if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
    if {  [ info exists id ] } { ; } else { set id 0 }
    if {  [ info exists masterlist ] } { ; } else { set masterlist "" }
    set oldmode $opmode
    set modestring [ string tolower $assignmode ] 
    switch $modestring {
        "current" {
            puts "Mode currently set to $opmode"
            return
        }
        "local" {
            set opmode "Local"
        }
        "primary" {
            set opmode "Primary"
        }
        "replica" {
            set opmode "Replica"
            set id $assignid
            set hostname $assignhost
        }
        default {
            puts "Error:Mode to switch to must be one of Local, Primary or Replica"
            return
        }
    }	
    if { $oldmode eq $opmode } { tk_messageBox -title "Confirm Mode" -message "Already in $opmode mode" } else { 
    if {[ tk_messageBox -icon question -title "Confirm Mode" -message "Switch from $oldmode\nto $opmode mode?" -type yesno ] == yes} { set opmode [ switch_mode $opmode $hostname $id $masterlist ] }  else { set opmode $oldmode } }
    return
}

proc quit {} {
    puts "Shutting down HammerDB CLI"
    exit
}

proc waittocomplete { args } {
global hdb_version
tk_messageBox -icon warning -message "waittocomplete command has been deprecated and is not required for version $hdb_version"
}

proc _waittocomplete {} {
#waittocomplete returns after vucomplete is detected, in v4.5 and earlier it would call exit
    upvar timevar timevar
    proc wait_to_complete_loop {} {
    upvar timevar timevar
        upvar wcomplete wcomplete
        set wcomplete [vucomplete]
        if {!$wcomplete} { catch {after 5000 wait_to_complete_loop} } else { 
	set timevar 1
        }
    }
    set wcomplete "false"
    wait_to_complete_loop
    vwait timevar
    return
}

proc runtimer { args } {
global hdb_version
tk_messageBox -icon warning -message "runtimer command has been deprecated and is not required for version $hdb_version"
}

proc _runtimer { seconds } {
    upvar elapsed elapsed
    upvar timevar timevar
    proc runtimer_loop { seconds } {
        upvar elapsed elapsed
        incr elapsed
        upvar timevar timevar
        set rcomplete [vucomplete]
        if { ![ expr {$elapsed % 60} ] } {
            set y [ expr $elapsed / 60 ]
            #putscli "Timer: $y minutes elapsed"
        }
        if {!$rcomplete && $elapsed < $seconds } {
            ;#Neither vucomplete or time reached, reschedule loop
        catch {after 1000 runtimer_loop $seconds }} else {
            #putscli "keepalive returned after $elapsed seconds"
            set elapsed 0
            set timevar 1
        }
    }
    set elapsed 0
    set timevar 0
    runtimer_loop $seconds
    vwait timevar
    return
}

proc tcstart {} {
    global tc_threadID
    set tclist [ thread::names ]
    if { [ info exists tc_threadID ] } {
        set idx [ lsearch $tclist $tc_threadID ]
        if { $idx != -1 } {
            tk_messageBox -icon warning -message "Transaction Counter thread already running with threadid:$tc_threadID"
            return 
        } else {
            tk_messageBox -icon warning -message "Transaction Counter thread already running"
            return
        }
    } else {
        #Start transaction counter
        transcount
    }
}

proc tcstatus {} {
    global tc_threadID
    set tclist [ thread::names ]
    if { [ info exists tc_threadID ] } {
        set idx [ lsearch $tclist $tc_threadID ]
        if { $idx != -1 } {
            tk_messageBox -icon warning -message "Transaction Counter thread running with threadid:$tc_threadID"
            return 
        } else {
            tk_messageBox -icon warning -message "Transaction Counter thread running"
            return
        }
    } else {
        putscli "Transaction Counter is not running"
    }
}

proc tcstop {} {
    global tc_threadID
    set tclist [ thread::names ]
    if { [ info exists tc_threadID ] } {
        set idx [ lsearch $tclist $tc_threadID ]
        if { $idx != -1 } {
            tk_messageBox -icon warning -message "Transaction Counter thread running with threadid:$tc_threadID"
            ed_kill_transcount 
        } else {
            tk_messageBox -icon warning -message "Transaction Counter thread running"
            ed_kill_transcount 
        }
    } else {
        putscli "Transaction Counter is not running"
    }
}

proc tcset {args} {
    upvar #0 genericdict genericdict
    if {[ llength $args ] != 2} {
        puts {Usage: tcset [refreshrate|logtotemp|unique|timestamps] value}
    } else {
        set option [ lindex [ split  $args ]  0 ]
        set ind [ lsearch {refreshrate logtotemp unique timestamps} $option ]
        if { $ind eq -1 } {
            puts "Error: invalid option"
            puts {Usage: vuset [refreshrate|logtotemp|unique|timestamps] value}
            return
        }
        set val [ lindex [ split  $args ]  1 ]
        if { [ info exists tc_threadID ] } {
            set idx [ lsearch $tclist $tc_threadID ]
            if { $idx != -1 } {
                tk_messageBox -icon warning -message "Stop Transaction Counter before setting configuration"
                return
        }} 
        switch  $option {
            refreshrate { 
                set refreshrate $val
                if { ![string is integer -strict $refreshrate] } {
                    tk_messageBox -message "Refresh rate must be an integer more than 0 secs and less than 60 secs"
                    puts -nonewline "setting to value: "
                    set refreshrate 10
                } else {
                    if { ($refreshrate >= 60) || ($refreshrate <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs"
                        set refreshrate 10 
                    }
                }
                if { [catch {dict set genericdict transaction_counter tc_refresh_rate $refreshrate}] } {
                    putscli "Failed to set Transaction Counter refresh rate"
                } else {
                    putscli "Transaction Counter refresh rate set to $refreshrate"
                }
            }
            logtotemp { 
                set logtotemp $val
                if { ![string is integer -strict $logtotemp ] } {
                    tk_messageBox -message "Log Output must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set logtotemp  0
                } else {
                    if { $logtotemp  > 1 } { tk_messageBox -message "Log Output must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set logtotemp  0
                    }
                }
                if { [catch {dict set genericdict transaction_counter tc_log_to_temp $logtotemp}] } {
                    putscli "Failed to set Transaction Counter log to temp"
                } else {
                    putscli "Transaction Counter log to temp set to $logtotemp"
                }
            }
            unique { 
                set unique_log_name $val
                if { ![string is integer -strict $unique_log_name] } {
                    tk_messageBox -message "Unique Log Name must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set unique_log_name 0
                } else {
                    if { $unique_log_name > 1 } { tk_messageBox -message "Unique Log Name must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set unique_log_name 0
                    }
                }
                if { [catch {dict set genericdict transaction_counter tc_unique_log_name $unique_log_name}] } {
                    putscli "Failed to set Transaction Counter unique log name"
                } else {
                    putscli "Transaction Counter unique log name set to $unique_log_name"
                }
            }
            timestamps { 
                set log_timestamps $val
                if { ![string is integer -strict $log_timestamps] } {
                    tk_messageBox -message "Log timestamps must be 0 or 1"
                    puts -nonewline "setting to value: "
                    set log_timestamps 0
                } else {
                    if { $log_timestamps > 1 } { tk_messageBox -message "Log timestamps must be 0 or 1"
                        puts -nonewline "setting to value: "
                        set log_timestamps 0
                    }
                }
                if { [catch {dict set genericdict transaction_counter tc_log_timestamps $log_timestamps}] } {
                    putscli "Failed to set Transaction Counter log timestamps"
                } else {
                    putscli "Transaction Counter timestamps set to $log_timestamps"
                }
            }
            default {
                puts "Unknown tcset option"
                puts {Usage: tcset [refreshrate|logtotemp|unique|timestamps] value}
            }
}}}
