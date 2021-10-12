#Package to implement extended time profiling
#Based on https://wiki.tcl-lang.org/page/Profiling+Tcl+by+Overloading+Proc
#by George Peter Staplin / Barney Blankenship 
#used under Tcl/Tk license
#modifications and extension by Steve Shaw under HammerDB/GPL3.0 license
package provide xtprof 1.0
namespace eval xtprof {
namespace export xttimeprofiler median percentile xtreport xttimeproflog xttimeprofdump proc _proc
namespace path {::tcl::mathop ::tcl::mathfunc}
global TimeProfilerMode
set TimeProfilerMode 0
#Load XML package to extract database and generic configurations
if [catch {package require xml} ] { error "Failed to load XML functions into Time Profile Package" } 
if { [info exists TimeProfilerMode] } {
puts "Initializing xtprof time profiler"
if {[ tsv::exists allvutimings 2 ]} { 
tsv::unset allvutimings
	}
if {[ tsv::exists allclicktimings 2 ]} { 
tsv::unset allclicktimings
	}
    proc xttimeprofiler {args} {
        global ProfilerArray
        
        # Intialize the elapsed time counters if needed...
        if { ![info exists ProfilerArray(ElapsedClicks)] } {
            set ProfilerArray(ElapsedClicks) [expr double([clock clicks])]
            set ProfilerArray(Elapsedms) [expr double([clock clicks -milliseconds])]
        }
        
        set fun [lindex [lindex $args 0] 0]
        
        if { [lindex $args end] == "enter" } {
            # Initalize the count of functions if needed...
            if { ![info exists ProfilerArray(funcount)] } {
                set ProfilerArray(funcount) 0
            }
            
            # See if this function is here for the first time...
            for { set fi 0 } { $fi < $ProfilerArray(funcount) } { incr fi } {
                if { [string equal $ProfilerArray($fi) $fun] } {
                    break
                }
            }
            if { $fi == $ProfilerArray(funcount) } {
                # Yes, function first time visit, add...
                set ProfilerArray($fi) $fun
                set ProfilerArray(funcount) [expr $fi + 1]
            }
            
            # Intialize the "EnterStack" if needed...
            if { ![info exists ProfilerArray(ES0)] } {
                set esi 1
            } else {
                set esi [expr $ProfilerArray(ES0) + 1]
            }
            # Append a "enter clicks" and "enter function name index" to the EnterStack...
            set ProfilerArray(ES0) $esi
            set ProfilerArray(ES$esi) [clock clicks]
            # Note: the above is last thing done so timing start is closest to
            # function operation start as possible.
        } else {
            # Right away stop timing...
            set deltaclicks [clock clicks]
            
            # Do not bother if TimeProfilerDump wiped the ProfilerArray
            # just prior to this "leave"...
            if { [info exists ProfilerArray(ES0)] } {
                # Pull an "enter clicks" off the EnterStack...
                set esi $ProfilerArray(ES0)
                set deltaclicks [expr $deltaclicks - $ProfilerArray(ES$esi)]
                incr esi -1
                set ProfilerArray(ES0) $esi
                
                # Correct for recursion and nesting...
                if { $esi } {
                    # Add our elapsed clicks to the previous stacked values to compensate...
                    for { set fix $esi } { $fix > 0 } { incr fix -1 } {
                        set ProfilerArray(ES$fix) [expr $ProfilerArray(ES$fix) + $deltaclicks]
                    }
                }
                
                # Intialize the delta clicks array if needed...
                if { ![info exists ProfilerArray($fun,0)] } {
                    set cai 1
                } else {
                    set cai [expr $ProfilerArray($fun,0) + 1]
                }
                
                # Add another "delta clicks" reading...
                set ProfilerArray($fun,0) $cai
                set ProfilerArray($fun,$cai) $deltaclicks
            }
        }
    }

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
    guid_init
    set MachInfo [expr {rand()}]$::GuiD__SeEd__VaR$::GuiD__MaChInFo__VaR
    binary scan $MachInfo h* MachInfo_Hex
    set guid [format %2.2x [clock seconds]]
    append guid [string range [format %2.2x [clock clicks]] 0 3] \
                [string range $MachInfo_Hex 0 11]
    incr ::GuiD__SeEd__VaR
    return [string toupper $guid]
 }

proc average {list} {
    expr {[tcl::mathop::+ {*}$list 0.0] / max(1, [llength $list])}
}

proc median {list {mode -real}} {
    set list [lsort $mode $list]
    set len [llength $list]
    if {$len & 1} {
       # Odd number of elements, unique middle element
       return [lindex $list [expr {$len >> 1}]]
    } else {
       # Even number of elements, average the middle two
       return [average [lrange $list [expr {($len >> 1) - 1}] [expr {$len >> 1}]]]
    }
}

proc SumSum2 {list} {
     set sum  0.0
     set sum2 0.0
     foreach x $list {
         set sum  [expr {$sum  + $x}]
         set sum2 [expr {$sum2 + $x*$x}]
     }
     list $sum $sum2
}

proc sigma {val1 val2 args} {
      set args [concat [list $val1 $val2] $args]
      foreach {sum sum2} [SumSum2 $args] {}
      set N [llength $args]
      set mean [expr {$sum/$N}]
      set sigma2 [expr {($sum2 - $mean*$mean*$N)/($N-1)}]
      return [expr {sqrt($sigma2)}]
}

proc percentile {pvalues percent} {
proc is_whole { float } {
  return [expr abs($float - int($float)) > 0 ? 0 : 1]
}
set k [ expr [ llength $pvalues ] * $percent ]
if { [ is_whole $k ] } {
set kint [ expr int($k) ]
set pctile [ expr ([lindex $pvalues [ expr $kint - 1 ]] + [lindex $pvalues $kint ]) / 2.0 ]
if { [ is_whole $pctile ] } {
set pctile [ expr int($pctile) ]
                }
        } else {
set k [ expr round($k) ]
set pctile [ lindex $pvalues [ expr $k - 1 ]]
        }
return $pctile
}

proc xtreport { myposition } {
global TimeProfilerMode
set TimeProfilerMode 0
 if { [info exists TimeProfilerMode] } {
      xttimeprofdump "$myposition"
 } else { puts "time profile mode doesn't exist" }
}

proc xttimeproflog { totalvirtualusers library } {
puts -nonewline "Gathering timing data from Active Virtual Users..."
#Try and add the database name to the report, match the library name from the config to find the database
set dbtoreport ""
if {[catch {set dbdict [ ::XML::To_Dict config/database.xml ]} message ]} { ; } else {
dict for {key value} $dbdict {
dict for {key2 value2} $value {
if { [ string match *$library* $value2 ] } {
set dbtoreport [ dict get $value name ]
break
      }
    }
  }
}
#Extract xt_unique_log_name and xt_gather_timeout from generic.xml assume log name is not unique if config cannot be read. Assume timeout is 10 mins if config cannot be read.
set xtunique_log_name 0
set xtgather_timeout 10
set 2key 0
if {[catch {set gendict [ ::XML::To_Dict config/generic.xml ]} message ]} { ; } else {
dict for {key value} $gendict {
dict for {key2 value2} $value {
if { $key2 eq "xt_unique_log_name" } {
set xtunique_log_name $value2
incr 2key
if { $2key eq 2 } { break }
      }
if { $key2 eq "xt_gather_timeout" } {
set xtgather_timeout $value2
incr 2key
if { $2key eq 2 } { break }
        }
     }
  }
}
if { [ string is entier $xtgather_timeout ] } { 
set xtto [expr {$xtgather_timeout * 60}]
} else {
set xttto 600
#Set xtgather_timout in case decided to print this value in future
set xtgather_timeout 10
}
#Wait for xtto seconds for all virtual users to have set their timing data in the thread shared keyed list
for {set clnt 1} { $clnt <= $xtto } {incr clnt} {
set alldone true
set vureported {}
for {set f 2} {$f <= $totalvirtualusers} {incr f} {
if {![ tsv::exists allvutimings $f ]} { 
set alldone false 
} else {
lappend vureported $f
	}
}
if $alldone { break } else { after 1000 }
}
if !$alldone { 
if { [ llength $vureported ] eq 0 } {
#tsv array allvutimings doesn't exist
puts  "ERROR:Timing Gather Timed Out before any Virtual User Reported"
return
	} else {
#tsv array exists but is not complete
puts "WARNING:Timing Data Incomplete" 
	}
} else {
puts -nonewline "Calculating timings..."
}
#Convert tsv keyed list to dict in the monitor thread
for {set f 2} {$f <= $totalvirtualusers} {incr f} {
#If Timing Data incomplete continue to next iteration in loop
if {![ tsv::exists allvutimings $f ]} { continue }
foreach func [ tsv::keylkeys allvutimings $f ] { dict set monitortimings $f $func [ join [ tsv::keylget allvutimings $f $func ]] }
dict set clicktimings $f [ tsv::keylget allclicktimings $f msperclick ]
dict set endclicks $f [ tsv::keylget allclicktimings $f endclicks ]
dict set endms $f [ tsv::keylget allclicktimings $f endms ]
	}
if { [ llength [ dict keys $monitortimings ]] != [ expr $totalvirtualusers - 1 ] } {
puts "[ llength [ dict keys $monitortimings ]] out of [ expr $totalvirtualusers - 1 ] Virtual Users reported"
}
#At 2nd level all unique keys should typically be neword payment delivery slev ostat
set lev2uniquekeys [ lsort -unique [concat {*}[lmap k1 [dict keys $monitortimings] {dict keys [dict get $monitortimings $k1]}]]]
if { ![ string equal "delivery neword ostat payment slev" $lev2uniquekeys ]} { 
puts "WARNING:Timing data returned values for functions different than expected delivery neword ostat payment slev: $lev2uniquekeys"
}

if ![ tsv::exists webservice wsport ] {
#Not working in webservice mode so open file for writing timing data
set using_webservice "false"
set tmpdir [ findtempdir ]
if { $tmpdir != "notmpdir" } {
        if { $xtunique_log_name eq 1 } {
        set guidid [ guid ]
set filename [file join $tmpdir hdbxtprofile_$guidid.log ]
        } else {
set filename [file join $tmpdir hdbxtprofile.log ]
        }
 if {[catch {set fd [open $filename a ]} message ]} {
     error "Could not open tempfile $filename for Time Profile $message"
                } else {
 if {[catch {fconfigure $fd -buffering none}]} {
     error "Could not disable buffering on $filename"
                }
puts "Writing timing data to $filename"
puts $fd "$dbtoreport Hammerdb Time Profile Report @ [clock format [clock seconds]]"
          }
} else {
     error "Could not open tempfile for Time Profile Report"
  }
} else {
#set local variable using_webservice
set using_webservice "true"
if [catch {package require sqlite3} message ] {
puts "Error loading SQLite : $message"
return
        }
set sqlite_db [ tsv::get webservice sqldb ]
if [catch {sqlite3 hdb $sqlite_db} message ] {
puts "Error initializing SQLite database for Job Timings : $message"
return
        } else {
catch {hdb timeout 30000}
#hdb eval {PRAGMA foreign_keys=ON}
#Select most recent jobid
unset -nocomplain jobid
set jobid [ hdb eval {select jobid from JOBMAIN order by datetime(timestamp) DESC LIMIT 1} ]
	}
}
set vustoreport [ dict keys $monitortimings ]
for { set vutri 0 } { $vutri < [llength $vustoreport] } { incr vutri } {
	set vutr [ lindex $vustoreport $vutri ]
set sprockeys [dict keys [dict get $monitortimings $vutr]]
unset -nocomplain sprocratio
unset -nocomplain sprocorder
#Report the data for each Virtual User in the ratio order
foreach sproc $sprockeys { 
lappend sprocratio $sproc [dict get $monitortimings $vutr $sproc ratio]
	 }
set sprocorder [ lsort -stride 2 -index 1 -real -decreasing $sprocratio ]
#remove every other element so left with list of stored procs sorted by ratio
for { set so 0 } { $so < [llength $sprocorder] } { incr so } {
set sprocorder [ lreplace $sprocorder [ expr $so + 1 ] [ expr $so + 1 ] ] 
}
if { $using_webservice } {
	foreach sproc $sprocorder {
#DEBUG insert into JOBTIMINGS TABLE
#puts [ subst {INSERT INTO JOBTIMING(jobid,vu,procname,calls,min,avg,max,total,p99,p95,p50,sd,ratio,summary,elapsed) VALUES($jobid,$vutr,[format "%s" [ string toupper $sproc]],[format "%d" [dict get $monitortimings $vutr $sproc calls]],[format "%.3f" [dict get $monitortimings $vutr $sproc min]],[format "%.3f" [dict get $monitortimings $vutr $sproc avgms]],[format "%.3f" [dict get $monitortimings $vutr $sproc max]],[format "%.3f" [dict get $monitortimings $vutr $sproc totalms]],[format "%.3f" [dict get $monitortimings $vutr $sproc p99]],[format "%.3f" [dict get $monitortimings $vutr $sproc p95]],[format "%.3f" [dict get $monitortimings $vutr $sproc p50]],[format "%.3f" [dict get $monitortimings $vutr $sproc sd]],[format "%.3f" [dict get $monitortimings $vutr $sproc ratio] 37],0,[dict get $monitortimings $vutr [lindex $sprocorder 1] elapsed])} ]
#Insert XTprof timing data into JobTiming table for each Virtual User
hdb eval [ subst {INSERT INTO JOBTIMING(jobid,vu,procname,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct,summary,elapsed_ms) VALUES('$jobid',$vutr,'[format "%s" [ string toupper $sproc]]',[format "%d" [dict get $monitortimings $vutr $sproc calls]],[format "%.3f" [dict get $monitortimings $vutr $sproc min]],[format "%.3f" [dict get $monitortimings $vutr $sproc avgms]],[format "%.3f" [dict get $monitortimings $vutr $sproc max]],[format "%.3f" [dict get $monitortimings $vutr $sproc totalms]],[format "%.3f" [dict get $monitortimings $vutr $sproc p99]],[format "%.3f" [dict get $monitortimings $vutr $sproc p95]],[format "%.3f" [dict get $monitortimings $vutr $sproc p50]],[format "%.3f" [dict get $monitortimings $vutr $sproc sd]],[format "%.3f" [dict get $monitortimings $vutr $sproc ratio] 37],0,[dict get $monitortimings $vutr [lindex $sprocorder 1] elapsed])} ]
#Add the timings to a list of timings for the same stored proc for all virtual users
#At this point [dict get $monitortimings $vutr $sproc clickslist] will return all unsorted data points for vuser $vutr for stored proc $sproc
#To record all individual data points for a virtual user write the output of this command to a file
#Preceed with {*} to expand the list into individual space separated values
#The msperclick per user is in [ dict get $clicktimings $vutr ] clicks need to be multiplied by this value for timings
 	    lappend $sproc-clickslist {*}[dict get $monitortimings $vutr $sproc clickslist]
		}
	} else {
            puts $fd "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
            puts $fd [format ">>>>> VIRTUAL USER %s : ELAPSED TIME : %.0fms" $vutr [dict get $monitortimings $vutr [lindex $sprocorder 1] elapsed]]
	foreach sproc $sprocorder {
            puts $fd [format ">>>>> PROC: %s" [ string toupper $sproc]]
            puts -nonewline $fd [format "CALLS: %d\t" [dict get $monitortimings $vutr $sproc calls]] 
            puts -nonewline $fd [format "MIN: %.3fms\t" [dict get $monitortimings $vutr $sproc min]]
            puts -nonewline $fd [format "AVG: %.3fms\t" [dict get $monitortimings $vutr $sproc avgms]]
            puts -nonewline $fd [format "MAX: %.3fms\t" [dict get $monitortimings $vutr $sproc max]]
            puts -nonewline $fd [format "TOTAL: %.3fms\n" [dict get $monitortimings $vutr $sproc totalms]]
            puts -nonewline $fd [format "P99: %.3fms\t" [dict get $monitortimings $vutr $sproc p99]]
            puts -nonewline $fd [format "P95: %.3fms\t" [dict get $monitortimings $vutr $sproc p95]]
            puts -nonewline $fd [format "P50: %.3fms\t" [dict get $monitortimings $vutr $sproc p50]]
            puts -nonewline $fd [format "SD: %.3f\t" [dict get $monitortimings $vutr $sproc sd]]
            puts $fd [format "RATIO: %.3f%c" [dict get $monitortimings $vutr $sproc ratio] 37]
#Add the timings to a list of timings for the same stored proc for all virtual users
#At this point [dict get $monitortimings $vutr $sproc clickslist] will return all unsorted data points for vuser $vutr for stored proc $sproc
#To record all individual data points for a virtual user write the output of this command to a file
#Preceed with {*} to expand the list into individual space separated values
#The msperclick per user is in [ dict get $clicktimings $vutr ] clicks need to be multiplied by this value for timings
 	    lappend $sproc-clickslist {*}[dict get $monitortimings $vutr $sproc clickslist]
		}
        }
}
#Calculate Summary for All Virtual Users
#use median values for milliseconds per click, end clicks and end ms
set medianmsperclick [ median [ dict values $clicktimings ]]
set medianendclicks [ median [ dict values $endclicks ]]
set medianendms [ median [ dict values $endms ]]
foreach sproc $lev2uniquekeys {
#$sproc-clickslist is the summary gathered from all virtual users
if { [ llength [ set $sproc-clickslist ]] > 2 } {
	    set sd [ sigma {*}[ set $sproc-clickslist ]]
	} else { set sd 0 }
set sortedclicks [lsort -integer [ set $sproc-clickslist ]]
	   set calls [ llength $sortedclicks ]
	   set min [ lindex $sortedclicks 0 ]
           set max [ lindex $sortedclicks [ expr {$calls -1} ]]
           set ctotal [+ {*}$sortedclicks]
           dict set sumtimings $sproc calls $calls
	   set cavg [expr {$ctotal / $calls}]
           dict set sumtimings $sproc sd $sd
           dict set sumtimings $sproc elapsed $medianendms
           dict set sumtimings $sproc avgms [expr $cavg * $medianmsperclick]
           dict set sumtimings $sproc totalms [expr $ctotal * $medianmsperclick]
           dict set sumtimings $sproc ratio [expr {(double($ctotal / $medianendclicks) * 100.0)/[llength $vustoreport]}]
           dict set sumtimings $sproc max [expr $max * $medianmsperclick]
           dict set sumtimings $sproc min [expr $min * $medianmsperclick]
           dict set sumtimings $sproc p99 [ expr [ percentile $sortedclicks 0.99 ] * $medianmsperclick]
           dict set sumtimings $sproc p95 [ expr [ percentile $sortedclicks 0.95 ] * $medianmsperclick]
           dict set sumtimings $sproc p50 [ expr [ percentile $sortedclicks 0.50 ] * $medianmsperclick]
}
#Recalculate the ratio for all virtual users
unset -nocomplain sprocratio
unset -nocomplain sprocorder
foreach sproc $lev2uniquekeys {
lappend sprocratio $sproc [dict get $sumtimings $sproc ratio]
	 }
set sprocorder [ lsort -stride 2 -index 1 -real -decreasing $sprocratio ]
#remove every other element so left with list of stored procs sorted by ratio
for { set so 0 } { $so < [llength $sprocorder] } { incr so } {
set sprocorder [ lreplace $sprocorder [ expr $so + 1 ] [ expr $so + 1 ] ] 
}
if { $using_webservice } {
foreach sproc $sprocorder {
#Insert summary timings into JOBTIMING table, summary identified by summary column eq 1
hdb eval [ subst {INSERT INTO JOBTIMING(jobid,vu,procname,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct,summary,elapsed_ms) VALUES('$jobid',[llength $vustoreport],'[format "%s" [ string toupper $sproc]]',[format "%d" [dict get $monitortimings $vutr $sproc calls]],[format "%.3f" [dict get $monitortimings $vutr $sproc min]],[format "%.3f" [dict get $monitortimings $vutr $sproc avgms]],[format "%.3f" [dict get $monitortimings $vutr $sproc max]],[format "%.3f" [dict get $monitortimings $vutr $sproc totalms]],[format "%.3f" [dict get $monitortimings $vutr $sproc p99]],[format "%.3f" [dict get $monitortimings $vutr $sproc p95]],[format "%.3f" [dict get $monitortimings $vutr $sproc p50]],[format "%.3f" [dict get $monitortimings $vutr $sproc sd]],[format "%.3f" [dict get $monitortimings $vutr $sproc ratio] 37],1,$medianendms)} ]
		}
	} else {
        puts $fd "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
     puts $fd [format ">>>>> SUMMARY OF [llength $vustoreport] ACTIVE VIRTUAL USERS : MEDIAN ELAPSED TIME : %.0fms" $medianendms]
foreach sproc $sprocorder {
            puts $fd [format ">>>>> PROC: %s" [ string toupper $sproc]]
            puts -nonewline $fd [format "CALLS: %d\t" [dict get $sumtimings $sproc calls]]
            puts -nonewline $fd [format "MIN: %.3fms\t" [dict get $sumtimings $sproc min]]
            puts -nonewline $fd [format "AVG: %.3fms\t" [dict get $sumtimings $sproc avgms]]
            puts -nonewline $fd [format "MAX: %.3fms\t" [dict get $sumtimings $sproc max]]
            puts -nonewline $fd [format "TOTAL: %.3fms\n" [dict get $sumtimings $sproc totalms]]
            puts -nonewline $fd [format "P99: %.3fms\t" [dict get $sumtimings $sproc p99]]
            puts -nonewline $fd [format "P95: %.3fms\t" [dict get $sumtimings $sproc p95]]
            puts -nonewline $fd [format "P50: %.3fms\t" [dict get $sumtimings $sproc p50]]
            puts -nonewline $fd [format "SD: %.3f\t" [dict get $sumtimings $sproc sd]]
            puts $fd [format "RATIO: %.3f%c" [dict get $sumtimings $sproc ratio] 37]
	}
        puts $fd "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
close $fd
	}
}
    
proc xttimeprofdump {myposition} {
        global ProfilerArray
        
        # Stop timing elapsed time and calculate conversion factor for clicks to ms...
        set EndClicks [expr {double([clock clicks]) - $ProfilerArray(ElapsedClicks)}]
        set Endms [expr {double([clock clicks -milliseconds]) - $ProfilerArray(Elapsedms)}]
        set msPerClick [expr $Endms / $EndClicks]
        
        # Visit each function and generate the statistics for it...
        for { set fi 0 ; set PerfList "" } { $fi < $ProfilerArray(funcount) } { incr fi } {
            set fun $ProfilerArray($fi)
            if { ![info exists ProfilerArray($fun,0)] } {
                continue
            }
            for { set max -1.0 ; set min -1.0 ; set ctotal 0.0 ; set cai 1 } { $cai <= $ProfilerArray($fun,0) } { incr cai } {
                set clicks $ProfilerArray($fun,$cai)
                set ctotal [expr {$ctotal + double($clicks)}]
                if { $max < 0 || $max < $clicks } {
                    set max $clicks
                }
                if { $min < 0 || $clicks < $min } {
                    set min $clicks
                }
	    lappend $fun-clickslist $clicks
            }
	    ############################################################
	    #Add unsorted timings to clickslist
	    dict set vutimings $fun clickslist [ set $fun-clickslist ]
            if { [ llength [ set $fun-clickslist ]] > 2 } {
	    dict set vutimings $fun sd [ sigma {*}[dict get $vutimings $fun clickslist] ]
	    } else { 
	    dict set vutimings $fun sd 0
	    }
	    #Sort the clickslist to calculate percentiles
	    set $fun-clickslist [lsort -integer [ set $fun-clickslist ]]
	    dict set vutimings $fun calls [ llength [ set $fun-clickslist ]]
            set cavg [expr {$ctotal / double($ProfilerArray($fun,0))}]
	    dict set vutimings $fun cavg $cavg
	    dict set vutimings $fun elapsed $Endms
	    dict set vutimings $fun avgms [expr $cavg * $msPerClick]
	    dict set vutimings $fun totalms [expr $ctotal * $msPerClick]
	    dict set vutimings $fun ratio [expr {double($ctotal / $EndClicks) * 100.0}]
	    dict set vutimings $fun max [expr $max * $msPerClick]
	    dict set vutimings $fun min [expr $min * $msPerClick]
	    dict set vutimings $fun p99 [ expr [ percentile [ set $fun-clickslist ] 0.99 ] * $msPerClick]
	    dict set vutimings $fun p95 [ expr [ percentile [ set $fun-clickslist ] 0.95 ] * $msPerClick]
	    dict set vutimings $fun p50 [ expr [ percentile [ set $fun-clickslist ] 0.50 ] * $msPerClick]
	    lappend funlist $fun
        }
        # Sort the profile data by Ratio...
	#set the thread shared keyed list allvutimings for the virtual user so the monitor virtual user can report the timings
	foreach func $funlist {tsv::keylset allvutimings $myposition $func [ list [ dict get $vutimings $func ] ]}
	tsv::keylset allclicktimings $myposition msperclick $msPerClick
	tsv::keylset allclicktimings $myposition endclicks $EndClicks 
	tsv::keylset allclicktimings $myposition endms $Endms
        # Reset the world...
        array unset ProfilerArray
	unset -nocomplain vutimings
    }
    
    #=================================================================
    # Overload "proc" so that functions defined after
    # this point have added trace handlers for entry and exit.
    # [George Peter Staplin]
    #=================================================================
    rename proc _proc
    
    _proc proc {name arglist body} {
				    if { $name in {neword payment delivery slev ostat} } {
                                    #===================================        
                                    # Allow multiple namespace use [JMN]
                                    if { ![string match ::* $name] } {
                                        # Not already an 'absolute' namespace path,
                                        # qualify it so that traces can find it...
                                        set name [uplevel 1 namespace current]::[set name]
                                    }
                                    #===================================
                                    
                                    _proc $name $arglist $body
                                    trace add execution $name enter xttimeprofiler
                                    trace add execution $name leave xttimeprofiler
				} else {
                                    #===================================        
                                    # Allow multiple namespace use [JMN]
                                    if { ![string match ::* $name] } {
                                        # Not already an 'absolute' namespace path,
                                        # qualify it so that traces can find it...
                                        set name [uplevel 1 namespace current]::[set name]
                                    }
                                    #===================================
                                    _proc $name $arglist $body
				}}
}
 global TimeProfilerMode
 if { [info exists TimeProfilerMode] } {
      global ProfilerArray
      array unset ProfilerArray
 }
}
