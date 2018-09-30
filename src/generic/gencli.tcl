set opmode "Local"
set table "notable"
set suppo 1
set optlog 0
set _ED(package) ""
set _ED(packagekeyname) ""
namespace eval ttk {
variable currentTheme "black"
proc scrollbar { args } { ; }
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
proc ed_lvuser_button { args } { ; }
proc .ed_mainFrame.editbuttons.test { args } { ; }
proc winfo { args } { return "false" }
proc even x {expr {($x % 2) == 0}}
proc odd  x {expr {($x % 2) != 0}}

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
puts " - WAIT IDLE"
dict set vustatus [ expr $vuser + 1 ] "WAIT IDLE"
}}
set totrun [ expr $maxvuser * $ntimes ]
}

proc runninguser { threadid } { 
global table threadscreated thvnum inrun AVUC vustatus
set AVUC "run"
TclReadLine::gotocol 0
catch {puts [ join " Vuser\  [ expr $thvnum($threadid) + 1]:RUNNING" ] } 
dict set vustatus [ expr $thvnum($threadid) + 1 ] "RUNNING"
TclReadLine::gotocol 10
 }

proc printresult { result threadid } { 
global vustatus table threadscreated thvnum succ fail totrun totcount inrun AVUC
incr totcount
if { $result == 0 } {
TclReadLine::gotocol 0
catch {puts [ join " Vuser\  [expr $thvnum($threadid) + 1]:FINISHED SUCCESS" ] } 
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH SUCCESS"
TclReadLine::gotocol 10
} else {
TclReadLine::gotocol 0
catch {puts [ join " Vuser\ [expr $thvnum($threadid) + 1]:FINISHED FAILED" ] } 
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH FAILED"
TclReadLine::gotocol 10
}
if { $totrun == $totcount } {
set AVUC "complete"
if { [ info exists inrun ] } { unset inrun }
TclReadLine::gotocol 0
catch { puts "ALL VIRTUAL USERS COMPLETE" }
refreshscript
TclReadLine::prompt ""
    }
}

proc tk_messageBox { args } { 
set messind [ lsearch $args -message ]
if { $messind eq -1 } { 
set message "tk_messageBox with unknown message"
 } else {
set message [ lindex $args [expr $messind + 1] ]
}
puts $message
set typeind [ lsearch $args yesno ]
if { $typeind eq -1 } { set yesno "false" 
	} else {
	set yesno "true"
	}
if { $yesno eq "true" } {
puts "Enter yes or no: replied yes"
return "yes"
#puts "Enter yes or no: "
#Delete 2 lines above for interactive response
gets stdin reply
set yntoup [ string toupper $reply ]
if { [ string match NO $yntoup ] } { 
puts "replied no"
	return "no" } else { 
puts "replied yes"
	return "yes" }
	}
return
}

rename myerrorproc _myerrorproc
proc myerrorproc { id info } {
global threadsbytid
if { ![string match {*index*} $info] } {
if { [ string length $info ] == 0 } {
TclReadLine::gotocol 0
puts "Warning: a running Virtual User was terminated, any pending output has been discarded"
TclReadLine::gotocol 10
} else {
if { [ info exists threadsbytid($id) ] } {
TclReadLine::gotocol 0
puts "Error in Virtual User [expr $threadsbytid($id) + 1]: $info"
TclReadLine::gotocol 10
        }  else {
    if {[string match {*.tc*} $info]} {
TclReadLine::gotocol 0
puts "Warning: Transaction Counter stopped, connection message not displayed"
TclReadLine::gotocol 10
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
global tids threadsbytid
TclReadLine::gotocol 0
catch {puts [ join " Vuser\ [expr $threadsbytid($id) + 1]:$lastline" ]} 
TclReadLine::gotocol 10
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
global _ED
if { [ lindex $args 0 ] eq "fastinsert" && [ lindex $args 1 ] eq "end" } {
set script [ lindex $args 2 ]
append _ED(package) $script
	} else {
if { [ lindex $args 0 ] eq "search" && [ lindex $args 1 ] eq "-backwards" } {
	set stringtofind [lindex $args 2]
	set ind [ string last $stringtofind $_ED(package) ]
	return $ind
	} else {
if { [ lindex $args 0 ] eq "search" && [ lindex $args 1 ] eq "-forwards" } {
	set stringtofind [lindex $args 2]
	set ind [ string first $stringtofind $_ED(package) ]
	return $ind
		} else {
if { [ lindex $args 0 ] eq "fastinsert" && [string is integer -strict [ lindex $args 1 ]] } {
set insertind [ lindex $args 1 ]
set substring [ lindex $args 2 ]
set _ED(package) [ string insert $_ED(package) $insertind $substring ]
		} else {
if { [ lindex $args 0 ] eq "fastinsert" } {
#timeprofile
set insertind [ lindex $args 1 ]
set substring [ lindex $args 2 ]
if { [ string match *1l $insertind ] } {
	set stringtofind "default \{"
	set ind [ string last $stringtofind $_ED(package) ]
set _ED(package) [ string insert $_ED(package) [ expr $ind + 10 ] $substring ]
	} else {
#string should match end-2l
	set stringtofind "\}"
	set stringtofind2 "\n"
	set ind [ string last $stringtofind $_ED(package) ]
	set ind2 [ string last $stringtofind $_ED(package) [ expr $ind - 1 ] ]
	set ind3 [ string last $stringtofind $_ED(package) [ expr $ind2 - 1 ] ]
set _ED(package) [ string insert $_ED(package) [ expr $ind3 + 2 ] $substring ]
			}
		    }
		}	
	    }
	}
}}

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

proc vuset { args } {
global virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps
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
if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
puts "Error: Virtual Users exist, destroy with vudestroy before changing settings"
return
}
switch  $option {
vu {	
set virtual_users $val
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
}
nobuff { 
set nobuff $val
if { ![string is integer -strict $nobuff] } {
        tk_messageBox -message "No Log Buffer must be 0 or 1"
	puts -nonewline "setting to value: "
        set nobuff 0
        } else {
if { $nobuff > 1 } { tk_messageBox -message "No Log Buffer must be 0 or 1"
	puts -nonewline "setting to value: "
        set nobuff 0
        }
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
}
default {
puts "Unknown vuset option"
puts {Usage: vuset [vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps] value}
	}
}}}

proc diset { args } {
global rdbms
if {[ llength $args ] != 3} {
	puts "Error: Invalid number of arguments\nUsage: diset dict key value"
	puts "Type \"print dict\" for valid dictionaries and keys for $rdbms" 
} else {
	set dct [ lindex [ split  $args ]  0 ]
	set key2 [ lindex [ split  $args ]  1 ]
	set val [ lindex [ split  $args ]  2 ]
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
if { [ dict get $dbdict $key name ] eq $rdbms } {
	set dictname config$key
	upvar #0 $dictname $dictname
	if {[dict exists [ set $dictname ] $dct ]} {
	if {[dict exists [ set $dictname ] $dct $key2 ]} {
	set previous [ dict get [ set $dictname ] $dct $key2 ]
	if { $previous eq $val } {
	puts "Value $val for $dct:$key2 is the same as existing value $previous, no change made"
	} else {
	if { [ string match *driver $key2 ] } {
	puts "Clearing Script, reload script to activate new setting"
	clearscript
	if { $val != "test" && $val != "timed"  } {	
	puts "Error: Driver script must be either \"test\" or \"timed\""
	return
		}	
	}
	if { [catch {dict set $dictname $dct $key2 $val } message]} {
	puts "Failed to set Dictionary value: $message"
	} else {
	puts "Changed $dct:$key2 from $previous to $val for $rdbms"
	}}
	} else {
	puts {Usage: diset dict key value}
	puts "Dictionary \"$dct\" for $rdbms exists but key \"$key2\" doesn't"
	puts "Type \"print dict\" for valid dictionaries and keys for $rdbms"
	}
	} else {
	puts {Usage: diset dict key value}
	puts "Dictionary \"$dct\" for $rdbms does not exist"
	puts "Type \"print dict\" for valid dictionaries and keys for $rdbms"
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
#package forget $library
}
	}
}

proc dbset { args } {
global rdbms bm
if {[ llength $args ] != 2} {
puts {Usage: dbset [db|bm] value}
} else {
set option [ lindex [ split  $args ]  0 ]
set ind [ lsearch {db bm} $option ]
if { $ind eq -1 } {
puts "Error: invalid option"
puts {Usage: dbset [db|bm] value}
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
puts "Unknown prefix $val, choose one from $prefixl"
} else {
set rdbms [ lindex $dbl $ind ]
puts "Database set to $rdbms"
	}
}	
bm {
set toup [ string toupper $val ]
if { [ string match ???-? $toup ] } { set dashformat "true" } else { set dashformat "false" }
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
if { [ dict get $dbdict $key name ] eq $rdbms } {
set posswkl  [ split  [ dict get $dbdict $key workloads ]]
if { $dashformat } {
set ind [ lsearch $posswkl $toup ]
if { $ind eq -1 } {
puts "Unknown benchmark $toup, choose one from $posswkl"
} else {
set bm $toup
puts "Benchmark set to $toup for $rdbms"
	}
      } else {
puts "Unknown benchmark $toup, choose one from $posswkl"
		}
	}
}}
default {
puts "Unknown dbset option"
puts {Usage: dbset [db|bm|config] value}
	}
      }
   }
}

proc print { args } {
global _ED rdbms bm virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps gen_count_ware gen_scale_fact gen_directory gen_num_vu
if {[ llength $args ] != 1} {
puts {Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|vucomplete|datagen]}
} else {
set ind [ lsearch {db bm dict script vuconf vucreated vustatus vucomplete datagen} $args ]
if { $ind eq -1 } {
puts "Error: invalid option"
puts {Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|vucomplete|datagen]}
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
puts "[expr [ llength [ thread::names ] ] - 1 ] Virtual Users created"
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
default {
puts "unknown print option"
	}
}
}
}

proc ed_status_message { flag message } {
	puts $message
}

proc vucreate {} {
global _ED lprefix vustatus
if { [ string length $_ED(package) ] eq 0  } {
puts "\nNo Script loaded: Load script before creating Virtual Users\n"
} else {
if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
puts "Error: Virtual Users exist, destroy with vudestroy before creating"
return
}
unset -nocomplain vustatus
set vustatus {}
	if { [catch {load_virtual} message]} {
	puts "Failed to create virtual users: $message"
	} else {
if { $lprefix eq "loadtimed" } {
puts "[expr [ llength [ thread::names ] ] - 1 ] Virtual Users Created with Monitor VU"
} else {
puts "[expr [ llength [ thread::names ] ] - 1 ] Virtual Users Created"
	    }
	}
    }
}

proc vudestroy {} {
	global threadscreated vustatus AVUC
	if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
	tsv::set application abort 1
	if { [catch {ed_kill_vusers} message]} {
	puts "Virtual Users remain running in background or shutting down, retry"
	} else {
	set x 0
	set checkstop 0
	while {!$checkstop} {
	incr x
	after 1000
	update
	if {[expr [ llength [ thread::names ] ] - 1 ] eq 0} {
	set checkstop 1
	puts "vudestroy success"
	unset -nocomplain AVUC
	unset -nocomplain vustatus
		} 
	if { $x eq 20 } { 
	set checkstop 1 
	puts "\nVirtual Users remain running in background or shutting down, retry"
		}
	    }
	}	
    } else {
	puts "No virtual users found to destroy"
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
global bm _ED
if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
if { [ string length $_ED(package) ] > 0 } { 
	puts "Script loaded, Type \"print script\" to view"
} else {
	puts "Error:script failed to load"
}}

proc clearscript {} {
global bm _ED
set _ED(package) ""
if { [ string length $_ED(package) ] eq 0 } { 
	puts "Script cleared"
} else {
	puts "Error:script failed to clear"
}}

proc refreshscript {} {
global bm _ED
set _ED(package) ""
if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
}

proc customscript { customscript } {
global _ED
if { [ file exists $customscript ] && [ file isfile $customscript ] && [ file extension $customscript ] eq ".tcl" } {
set _ED(file) $customscript
	     } else {
puts "Usage: customscript scriptname.tcl"
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
global virtual_users maxvuser rdbms threadscreated
if { [ info exists threadscreated ] } {
puts "Error: Cannot build schema with Virtual Users active, destroy Virtual Users first"
return
        }
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
if { [ dict get $dbdict $key name ] eq $rdbms } {
	set dictname config$key
	upvar #0 $dictname $dictname
	set cwkey [ lsearch [ join [ set $dictname ]] *count_ware ]
	set buildcw [ lindex [ join [ set $dictname ]] [ expr $cwkey + 1]]
	set vukey [ lsearch [ join [ set $dictname ]] *num_vu ]
	set vuname [ lsearch -inline [ join [ set $dictname ]] *num_vu ]
	set buildvu [ lindex [ join [ set $dictname ]] [ expr $vukey + 1]]
if { ![string is integer -strict $buildvu ] || $buildvu < 1 } {
	puts "Error: Number of virtual users to build schema must be an integer"
	return
	}
	if { $buildvu > $buildcw } {
	puts "Error:Build virtual users must be less than or equal to number of warehouses"
	puts "You have $buildvu virtual users building $buildcw warehouses"
	return
		} else {
	if { $buildcw eq 1 } {
	set maxvuser 1
	set virtual_users 1
	clearscript
	puts "Building 1 Warehouse with 1 Virtual User"
	if { [ catch {build_schema} message ] } {
	puts "Error: $message"
			}
	} else {
	set maxvuser [ expr $buildvu + 1 ]
	set virtual_users $maxvuser
	clearscript
	puts "Building $buildcw Warehouses with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu)"
	if { [ catch {build_schema} message ] } {
	puts "Error: $message"
			}
		     }
		  }
	   }
     }
}

proc vurun {} {
	global _ED
if { [ string length $_ED(package) ] > 0 } { 
	if { [ catch {run_virtual} message ] } {
	puts "Error: $message"
	}
	} else {
puts "Error: There is no workload to run because the Script is empty"
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
if { ![string is integer -strict $gen_count_ware] || $gen_count_ware < 1 || $gen_count_ware > 30000 } { 
	tk_messageBox -message "The number of warehouses must be a positive integer less than 30000" 
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
	tk_messageBox -message "The number of virutal users must be a positive integer less than 1024" 
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
        tk_messageBox -message "The umber of virtual users must be an integer"
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
set _ED(packagekeyname) "TPC-C"
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
if { $db_allwarehouse } { shared_tpcc_functions "allwarehouse" }
	}
set timep [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *timeprofile ]
if { $timep != "" } {
set db_timeprofile [ dict get [ set $dictname ] tpcc $timep ]
if { $db_timeprofile } { shared_tpcc_functions "timeprofile" }
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
set _ED(packagekeyname) "TPC-H"
puts "TPC-H Driver Script"
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

proc help { args } {
if {[ llength $args ] != 1} {
  puts "HammerDB v3.1 CLI Help Index\n
Type \"help command\" for more details on specific commands below"
  puts {	
	buildschema
       	clearscript
       	customscript
       	datagenrun
       	dbset
       	dgset
       	diset 
	librarycheck
       	loadscript
       	print 
	vucomplete
       	vucreate
       	vudestroy
       	vurun
       	vuset
       	vustatus 
	}
} else {
set option [ lindex [ split  $args ]  0 ]
set ind [ lsearch {print librarycheck dbset diset buildschema vuset vucreate vurun vudestroy vustatus vucomplete loadscript clearscript customscript dgset datagenrun} $option ]
if { $ind eq -1 } {
puts "Error: invalid option"
puts {Usage: help [print|librarycheck|dbset|diset|buildschema|vuset|vucreate|vurun|vudestroy|vustatus|vucomplete|loadscript|clearscript|customscript|dgset|datagenrun]}
return
} else {
switch  $option {
print {
puts {print - Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|datagen]}
puts "prints the current configuration: 
db: database 
bm: benchmark
dict: the dictionary for the current database ie all active variables
script: the loaded script
vuconf: the virtual user configuration
vucreated: the number of virtual users created
vustatus: the status of the virtual users
datagen: the datagen configuration"
}
librarycheck {
puts "librarycheck - Usage: librarycheck"
puts "Attempts to load the vendor provided 3rd party library for all databases and reports whether the attempt was successful."
}
dbset {
puts "dbset - Usage: dbset \[db|bm\] value"
puts "Sets the database (db) or benchmark (bm). Equivalent to the Benchmark Menu in the graphical interface. Database value is set by the database prefix in the XML configuration." 
}
diset {
puts "diset - Usage: diset dict key value"
puts "Set the dictionary variables for the current database. Equivalent to the Schema Build and Driver Options windows in the graphical interface. Use \"print dict\" to see what these variables area and diset to change:
Example:
hammerdb>diset tpcc count_ware 10
Changed tpcc:count_ware from 1 to 10 for Oracle"
}
buildschema {
puts "buildschema - Usage: buildschema"
puts "Runs the schema build for the database and benchmark selected with dbset and variables selected with diset. Equivalent to the Build command in the graphical interface." 
}
vuset {
puts "vuset - Usage: vuset \[vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps\]"
puts "Configure the virtual user options. Equivalent to the Virtual User Options window in the graphical interface." 
}
vucreate {
puts "vucreate - Usage: vucreate"
puts "Create the virtual users. Equivalent to the Virtual User Create option in the graphical interface. Use \"print vucreated\" to see the number created, vustatus to see the status and vucomplete to see whether all active virtual users have finished the workload. A script must be loaded before virtual users can be created." 
}
vurun {
puts "vurun - Usage: vurun"
puts "Send the loaded script to the created virtual users for execution. Equivalent to the Run command in the graphical interface."
}
vudestroy {
puts "vudestroy - Usage: vudestroy"
puts "Destroy the virtual users. Equivalent to the Destroy Virtual Users button in the graphical interface that replaces the Create Virtual Users button after virtual user creation."
}
vustatus {
puts "vustatus - Usage: vustatus"
puts "Show the status of virtual users. Status will be \"WAIT IDLE\" for virtual users that are created but not running a workload,\"RUNNING\" for virtual users that are running a workload, \"FINISH SUCCESS\" for virtual users that completed successfully or \"FINISH FAILED\" for virtual users that encountered an error." 
}
vucomplete {
puts "vucomplete - Usage: vucomplete"
puts "Returns \"true\" or \"false\" depending on whether all virtual users that started a workload have completed regardless of whether the status was \"FINISH SUCCESS\" or \"FINISH FAILED\"."
}
loadscript {
puts "loadscript - Usage: loadscript"
puts "Load the script for the database and benchmark set with dbset and the dictionary variables set with diset. Use \"print script\" to see the script that is loaded. Equivalent to loading a Driver Script in the Script Editor window in the graphical interface."
}
clearscript {
puts "clearscript - Usage: clearscript"
puts "Clears the script. Equivalent to the \"Clear the Screen\" button in the graphical interface." 
}
customscript {
puts "customscript - Usage: customscript scriptname.tcl"
puts "Load an external script. Equivalent to the \"Open Existing File\" button in the graphical interface."  
}
dgset {
puts "dgset - Usage: dgset \[vu|ware|directory\]" 
puts "Set the Datagen options. Equivalent to the Datagen Options dialog in the graphical interface."
}
datagenrun {
puts "datagenrun - Usage: datagenrun"
puts "Run Data Generation. Equivalent to the Generate option in the graphical interface."
}
}
}
}
}
