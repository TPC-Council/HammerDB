#Transaction counter Functions common to both GUI and CLI
proc post_kill_transcount_cleanup {} {
global tc_threadID
unset -nocomplain tc_threadID
tsv::set application timeout 2
tsv::unset application thecount
 }

proc setlocaltcountvars { configdict allvars } {
#set variables to values in dict
if $allvars {
dict for {descriptor attributes} $configdict  {
if {$descriptor eq "connection" || $descriptor eq "tpcc" || $descriptor eq "tpch" } {
foreach { val } [ dict keys $attributes ] {
uplevel "variable $val"
upvar 1 $val $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
} else {
dict for {descriptor attributes} $configdict  {
if {$descriptor eq "connection" } {
foreach { val } [ dict keys $attributes ] {
uplevel "variable $val"
upvar 1 $val $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
}
}

proc open_transcount_log { iface unique_log_name } {
global opmode apmode
set tc_flog "notclog"
set tmpdir [ findtempdir ]
if { $tmpdir != "notmpdir" } {
        if { $unique_log_name eq 1 } {
        set guidid [ guid ]
set filename [file join $tmpdir hdbtcount_$guidid.log ]
        } else {
set filename [file join $tmpdir hdbtcount.log ]
        }
 if {[catch {set tc_flog [open $filename a ]}]} {
     error "Could not open tempfile $filename"
                } else {
 if {[catch {fconfigure $tc_flog -buffering none}]} {
     error "Could not disable buffering on $filename"
                }
        puts $tc_flog "Hammerdb Transaction Counter Log @ [clock format [clock seconds]]"
        puts $tc_flog "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
                        }
if { $iface eq "cli" } {
putscli "Transaction Counter logging activated to $filename"
	} else {
if { $opmode != "Replica" } {
if { $apmode eq "disabled" } {
tk_messageBox -title "TX Logging Active" -message "TX Counter Logging activated\nto $filename"
                } else {
puts "TX Logging activated to $filename"
                        }
                }
	}
        } else {
set tc_flog "notclog"
               }
return $tc_flog
}

proc close_transcount_log { iface } {
global tc_flog
if { ![info exists tc_flog] } { set tc_flog "notclog"}
if { $tc_flog != "notclog" } {
if { [catch {close $tc_flog} message]} {
if { $iface eq "cli" } {
putscli "Failed to close Transaction Counter Log"
	} else {
puts "Failed to close Transaction Counter Log"
	}
} else {
if { $iface eq "cli" } {
putscli "Closed Transaction Counter Log"
	} else {
puts "Closed Transaction Counter Log"
	}
if { [catch {set tc_flog "notclog"} message]} { ; } 
        }
    }
}

proc write_to_transcount_log { number rdbms metric } {
global tc_flog
if { ![info exists tc_flog] } { set tc_flog "notclog"}
upvar #0 genericdict genericdict
if { $tc_flog != "notclog" } {
dict with genericdict { dict with transaction_counter { set tstamp $tc_log_timestamps }}
if { $tstamp } {
catch {puts $tc_flog "$number $rdbms $metric @ [ clock format [clock seconds]]"}
        } else {
catch {puts $tc_flog "$number $rdbms $metric"}
        }
}
}
