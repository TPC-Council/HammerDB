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
proc ed_lvuser_button { args } { ; }
proc .ed_mainFrame.editbuttons.test { args } { ; }
proc .ed_mainFrame.editbuttons.distribute { args } { ; }
proc destroy { args } { ; }
proc ed_edit { args } { ; }
proc applyctexthighlight { args } { ; }
proc winfo { args } { return "false" }
proc even x {expr {($x % 2) == 0}}
proc odd  x {expr {($x % 2) != 0}}

proc strip_html { htmlText } {
    regsub -all {<[^>]+>} $htmlText "" newText
    return $newText
    }

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
 } else {
}
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
set query [ hdb eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid} ]
if { $query eq 0 } {
set tmpdictforpt [ find_current_dict ]
hdb eval {INSERT INTO JOBMAIN(jobid,db,bm,jobdict) VALUES($jobid,$rdbms,$bm,$tmpdictforpt)}
return 0
	} else {
return 1
	}

}

proc runninguser { threadid } { 
global table threadscreated thvnum inrun AVUC vustatus jobid
set AVUC "run"
set message [ join " Vuser\  [ expr $thvnum($threadid) + 1]:RUNNING" ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "RUNNING"
 }

proc printresult { result threadid } { 
global vustatus table threadscreated thvnum succ fail totrun totcount inrun AVUC jobid
incr totcount
if { $result == 0 } {
set message [ join " Vuser\  [expr $thvnum($threadid) + 1]:FINISHED SUCCESS" ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH SUCCESS"
} else {
set message [ join " Vuser\ [expr $thvnum($threadid) + 1]:FINISHED FAILED" ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH FAILED"
}
if { $totrun == $totcount } {
set AVUC "complete"
if { [ info exists inrun ] } { unset inrun }
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, "ALL VIRTUAL USERS COMPLETE")}
refreshscript
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
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
set typeind [ lsearch $args yesno ]
if { $typeind eq -1 } { set yesno "false" 
	} else {
	set yesno "true"
	}
if { $yesno eq "true" } {
return "yes"
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
putscli [ subst {{"warning": {"message": "a running Virtual User was terminated, any pending output has been discarded"}}} ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $message)}
} else {
if { [ info exists threadsbytid($id) ] } {
set vuser [expr $threadsbytid($id) + 1]
set info "Error: $info"
putscli [ subst {{"error": {"message": "$info"}}} ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, $vuser, $info)}
        }  else {
    if {[string match {*.tc*} $info]} {
#set message "Warning: Transaction Counter stopped, connection message not displayed"
putscli [ subst {{"error": {"message": "$info"}}} ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, 0, $info)}
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
set vuser [expr $threadsbytid($id) + 1]
set lastline [ string trimright $lastline ]
hdb eval {INSERT INTO JOBOUTPUT VALUES($jobid, $vuser, $lastline)}
}

rename logtofile _logtofile
proc logtofile { id msg } {
puts "Warning: File Logging disabled in web service mode, use jobs command to reretrieve output"
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

proc ed_status_message { flag message } {
#	puts $message
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

proc clearscript2 {} {
global bm _ED
set _ED(package) ""
if { [ string length $_ED(package) ] eq 0 } { 
return "true"
} else {
return "false"
}}


proc refreshscript {} {
global bm _ED
set _ED(package) ""
if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
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
#puts "Schema creation cancelled"
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
set _ED(packagekeyname) "TPC-H"
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

proc is-dict {value} {
#appx dictionary check
    return [expr {[string is list $value] && ([llength $value]&1) == 0}]
	}

####WAPP PAGES##################################
proc wapp-2-json {dfields dict2json} {
if {[string is integer -strict $dfields]} {
if { $dfields <= 2 && $dfields >= 1 } {
if {[ is-dict $dict2json ]} {
	;
	} else {
set dfields 2
dict set dict2json error message "output procedure wapp-2-json called with invalid dictionary"
	}
		} else {
set dfields 2
dict set dict2json error message "output procedure wapp-2-json called with invalid number of fields"
		}
	}
if { $dfields == 2 } {
	set huddleobj [ huddle compile {dict * dict} $dict2json ]
	} else {
	set huddleobj [ huddle compile {dict} $dict2json ]
	}
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
}

proc wapp-default {} {
  set B [wapp-param BASE_URL]
  wapp-trim {
<html>
  <head>
    <meta content=\"text/html;charset=ISO-8859-1\" http-equiv=\"Content-Type\">
    <title>HammerDB Web Service</title>
    <h1>HammerDB Web Service</h1>
    <p><a href='%html($B)/env'>HammerDB Web Service Environment</a></p>
    <p><a href='%html($B)/help'>HammerDB Web Service API</a></p>
  </head>
  <body>
  </body>
</html>
	}
}

proc env {} {
global ws_port
set res [rest::get http://localhost:$ws_port/env "" ]
putscli [ strip_html $res ]
}

proc wapp-page-env {} {
  wapp-allow-xorigin-params
  wapp-trim {
    <h1>HammerDB Web Service Environment</h1>\n<pre>
    <pre>%html([wapp-debug-env])</pre>
  }
}

proc wapp-page-db {} {
global rdbms
upvar #0 dbdict dbdict
dict append dbl "current" $rdbms
dict for {database attributes} $dbdict {
dict with attributes {
dict append dbl $prefix $name
        }
}
wapp-2-json 1 $dbl
}

proc wapp-page-bm {} {
global bm
set bmdict [dict create benchmark $bm ]
wapp-2-json 1 $bmdict
}

proc wapp-page-dict {} {
global wapp
set tmpdictforpt [ find_current_dict ] 
wapp-2-json 2 $tmpdictforpt
}

proc loadscript {} {
global ws_port
set res [rest::get http://localhost:$ws_port/loadscript "" ]
putscli $res
}

proc wapp-page-loadscript {} {
global bm _ED rdbms
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } {
set dictname config$key
upvar #0 $dictname $dictname
set prefix [ dict get $dbdict $key prefix ]
if { $bm eq "TPC-C" } { 
set drivername [ concat [subst {$prefix}]_driver ]
set drivertype [ dict get [ set $dictname ] tpcc $drivername ]
if { $drivertype eq "test" } {
dict set loadscriptdict error message "Test driver script not supported when running as a webservice, use timed script for webservice and GUI for testing"
wapp-2-json 2 $loadscriptdict
return
		}
	   }
      }
}
if { $bm eq "TPC-H" } { loadtpch } else { loadtpcc }
if { [ string length $_ED(package) ] > 0 } { 
dict set loadscriptdict success message "script loaded"
} else {
dict set loadscriptdict error message "script failed to load"
}
wapp-2-json 2 $loadscriptdict
}

proc wapp-page-script {} {
global bm _ED
if { [ string length $_ED(package) ] eq 0  } {
dict set scriptdict error message "No Script loaded: load with loadscript"
wapp-2-json 2 $scriptdict
} else {
dict set scriptdict script $_ED(package)
wapp-2-json 1 $scriptdict
        }
}

proc print { args } {
global ws_port
set res [rest::get http://localhost:$ws_port/print $args ]
putscli $res
}

proc wapp-page-echo {} {
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 6} {
dict set jsondict error message "Incorrect number of parameters to echo"
wapp-2-json 2 $jsondict
return
}
foreach {type key value} [ huddle keys $huddlecontent ] break
	set type2 [ huddle get_stripped $huddlecontent $type ]
	set key2 [ huddle get_stripped $huddlecontent $key ]
	set val [ huddle get_stripped $huddlecontent $value ]
dict set jsondict $type2 $key2 "$val"
wapp-2-json 2 $jsondict
	}
}


proc wapp-page-print {} {
switch [ wapp-param QUERY_STRING ] {
db { wapp-page-db }
bm { wapp-page-bm }
dict { wapp-page-dict }
script { wapp-page-script }
vuconf { wapp-page-vuconf }
vucreated { wapp-page-vucreated }
vustatus { wapp-page-vustatus }
datagen { wapp-page-datagen }
tcconf { wapp-page-tcconf }
default {
dict set scriptdict usage message "print?option"
wapp-2-json 2 $scriptdict
		}
	}
}

proc wapp-page-vuconf {} {
global virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps
foreach i { "Virtual Users" "User Delay(ms)" "Repeat Delay(ms)" "Iterations" "Show Output" "Log Output" "Unique Log Name" "No Log Buffer" "Log Timestamps" } j { virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps } {
dict append vuconfdict $i [ set $j ]
	}
wapp-2-json 1 $vuconfdict
}

proc wapp-page-vucreated {} {
dict append vucreateddict "Virtual Users created" [expr [ llength [ thread::names ] ] - 1 ]
wapp-2-json 1 $vucreateddict
}

proc vustatus {} {
print vustatus
}

proc wapp-page-vustatus {} {
global vustatus
if { ![info exists vustatus] } {
dict append vustatusdict "Virtual User status" "No Virtual Users found"
        } else {
dict append vustatusdict "Virtual User status" $vustatus
        }
wapp-2-json 1 $vustatusdict
	}

proc wapp-page-vucomplete {} {
dict append vucompletedict "Virtual Users complete" [ vucomplete ]
wapp-2-json 1 $vucompletedict
}

proc wapp-page-tcconf {} {
upvar #0 genericdict genericdict
dict with genericdict { wapp-2-json 1 $transaction_counter }
}

proc wapp-page-datagen {} {
global rdbms gen_count_ware gen_scale_fact gen_directory gen_num_vu bm
if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
if {  ![ info exists bm ] } { set bm "TPC-C" }
if { $bm eq "TPC-C" } {
set vudgendict [ dict create schema $bm database $rdbms warehouses $gen_count_ware vu $gen_num_vu directory $gen_directory" ]
	} else {
set vudgendict [ dict create schema $bm database $rdbms scale_factor $gen_scale_fact vu $gen_num_vu directory $gen_directory" ]
	}
wapp-2-json 1 $vudgendict
}

proc librarycheck {} {
global ws_port
set res [rest::get http://localhost:$ws_port/librarycheck "" ]
putscli $res
}

proc wapp-page-librarycheck {} {
upvar #0 dbdict dbdict
dict for {database attributes} $dbdict {
dict with attributes {
lappend dbl $name
lappend prefixl $prefix
lappend libl $library
        }
}
foreach db $dbl library $libl {
if { [ llength $library ] > 1 } {
        set version [ lindex $library 1 ]
        set library [ lindex $library 0 ]
set cmd "package require $library $version"
                } else {
set cmd "package require $library"
                }
if [catch {eval $cmd} message] {
lappend joboutput "error: failed to load $library for $db - $message"
} else {
lappend joboutput "success ... loaded library $library for $db"
                }
        }
        set huddleobj [ huddle compile {list} $joboutput ]
        wapp-mimetype application/json
        wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
}

proc diset { args } {
global ws_port rdbms opmode
if {[ llength $args ] != 3} {
set body { "type": "error", "key": "message", "value": "Incorrect number of parameters to diset dict key value" } 
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
} else {
        set dct [ lindex $args 0 ]
        set key2 [ lindex $args 1 ]
        set val [ lindex $args 2 ]
set body [ subst { "dict": "$dct", "key": "$key2", "value": "$val" } ]
set res [rest::post http://localhost:$ws_port/diset $body ]
putscli $res
	}
}

proc wapp-page-diset {} {
global wapp rdbms
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 6} {
dict set jsondict error message "Incorrect number of parameters to diset dict key value"
wapp-2-json 2 $jsondict
return
} else {
foreach {dict key value} [ huddle keys $huddlecontent ] break
	set dct [ huddle get_stripped $huddlecontent $dict ]
	set key2 [ huddle get_stripped $huddlecontent $key ]
	set val [ huddle get_stripped $huddlecontent $value ]
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
	dict set jsondict success message "Value $val for $dct:$key2 is the same as existing value $previous, no change made"
	wapp-2-json 2 $jsondict
	} else {
	if { [ string match *driver $key2 ] } {
	if { $val != "test" && $val != "timed" } {	
	dict set jsondict error message "Error: Driver script must be either \"test\" or \"timed\""
	} else {
	if { [ clearscript2 ] } {
	if { [catch {dict set $dictname $dct $key2 $val } message]} {
	dict set jsondict error message "Failed to set Dictionary value: $message"
		} else {
dict set jsondict success message "Set driver script to $val, clearing Script, reload script to activate new setting"
		}
	} else {
 dict set jsondict error message "Set driver script to $val but error in clearing Script"
	}}
	wapp-2-json 2 $jsondict
	return
	}
	if { [catch {dict set $dictname $dct $key2 $val } message]} {
	dict set jsondict error message "Failed to set Dictionary value: $message"
	wapp-2-json 2 $jsondict
	} else {
	dict set jsondict success message "Changed $dct:$key2 from $previous to $val for $rdbms"
	wapp-2-json 2 $jsondict
	}}
	} else {
	dict set jsondict error message "Dictionary \"$dct\" for $rdbms exists but key \"$key2\" doesn't"
	wapp-2-json 2 $jsondict
	}
	} else {
	dict set jsondict error message "Dictionary \"$dct\" for $rdbms does not exist"
	wapp-2-json 2 $jsondict
	}
}}}}}

proc tcset { args } {
global ws_port
if {[ llength $args ] != 2} {
set body { "type": "error", "key": "message", "value": "Incorrect number of parameters to tcset key value" }
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
} else {
set opt [ lindex [ split  $args ]  0 ]
set val [ lindex [ split  $args ]  1 ]
set body [ subst { "$opt": "$val" } ]
set res [rest::post http://localhost:$ws_port/tcset $body ]
putscli $res
        }
}

proc wapp-page-tcset {} {
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
        wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 2} {
dict set jsondict error message "Incorrect number of parameters to tcset key value"
        wapp-2-json 2 $jsondict
return
} else {
set key [ huddle keys $huddlecontent ]
set val [ huddle get_stripped $huddlecontent $key ]
set ind [ lsearch {refreshrate} $key ]
if { $ind eq -1 } {
dict set jsondict error message "Invalid option to tcset key value"
        wapp-2-json 2 $jsondict
return
        }
upvar #0 genericdict genericdict
switch  $key {
refreshrate { 
set refreshrate $val
if { ![string is integer -strict $refreshrate] } {
dict set jsondict error message "Refresh rate must be an integer more than 0 secs and less than 60 secs"
        wapp-2-json 2 $jsondict
        set refreshrate 10
	return
        } else {
	if { ($refreshrate >= 60) || ($refreshrate <= 0)  } { 
dict set jsondict error message "Refresh rate must be more than 0 secs and less than 60 secs"
        wapp-2-json 2 $jsondict
        set refreshrate 10 
	return
	}
   }
if { [catch {dict set genericdict transaction_counter tc_refresh_rate $refreshrate}] } {
dict set jsondict error message "Failed to set Transaction Counter refresh rate"
        wapp-2-json 2 $jsondict
	return
} else {
dict set jsondict success message "Transaction Counter refresh rate set to $refreshrate"
        wapp-2-json 2 $jsondict
	return
}
}
default {
#default option should not be reached as earlier index lsearch only looks for refreshrate
#switch statement retained in case of adding additional parameters in future
dict set jsondict error message "Invalid option to tcset key value"
        wapp-2-json 2 $jsondict
	return
	}
}}}}

proc clearscript {} {
global ws_port
set res [rest::get http://localhost:$ws_port/clearscript "" ]
putscli $res
}

proc wapp-page-clearscript {} {
if { [ clearscript2 ] } { 
dict set jsondict success message "Script cleared"
	} else {
dict set jsondict error message "Error:script failed to clear"
	}
	wapp-2-json 2 $jsondict
}

proc dbset { args } {
global ws_port rdbms bm opmode
if {[ llength $args ] != 2} {
set body { "type": "error", "key": "message", "value": "Usage: dbset [db|bm] value" }
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
return
} else {
set option [ lindex [ split  $args ]  0 ]
set ind [ lsearch {db bm} $option ]
if { $ind eq -1 } {
set body { "type": "error", "key": "message", "value": "Usage: dbset [db|bm] value" }
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
return
        }
set opt [ lindex [ split  $args ]  0 ]
set val [ lindex [ split  $args ]  1 ]
set body [ subst { "$opt": "$val" } ]
set res [rest::post http://localhost:$ws_port/dbset $body ]
putscli $res
        }
}

proc wapp-page-dbset {} {
global rdbms bm
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
	wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 2} {
dict set jsondict error message "Incorrect number of parameters to dbset key value"
	wapp-2-json 2 $jsondict
return
} else {
set key [ huddle keys $huddlecontent ] 
set val [ huddle get_stripped $huddlecontent $key ]
set ind [ lsearch {db bm} $key ]
if { $ind eq -1 } {
dict set jsondict error message "Invalid option to dbset key value"
	wapp-2-json 2 $jsondict
return
	}
switch  $key {
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
dict set jsondict error message "Unknown prefix $val, choose one from $prefixl"
	wapp-2-json 2 $jsondict
} else {
set rdbms [ lindex $dbl $ind ]
dict set jsondict success message "Database set to $rdbms"
	wapp-2-json 2 $jsondict
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
dict set jsondict error message "Unknown benchmark $toup, choose one from $posswkl (or compatible names $posswkl)"
	wapp-2-json 2 $jsondict
} else {
set dicttoup [ regsub -all {(TP)(RO)(C-[CH])} $toup {\1\3} ]
set bm $dicttoup
dict set jsondict success message "Benchmark set to $toup for $rdbms"
	wapp-2-json 2 $jsondict
	}
      } else {
dict set jsondict error message "Unknown benchmark $toup, choose one from $posswkl2 (or compatible names $posswkl)"
	wapp-2-json 2 $jsondict
		}
	}
}}
default {
puts "Unknown dbset option"
puts {Usage: dbset [db|bm|config] value}
	}
      }
}}}

proc vuset { args } {
global ws_port
if {[ llength $args ] != 2} {
set body { "type": "error", "key": "message", "value": "Incorrect number of parameters to vuset key value" } 
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
} else {
set opt [ lindex [ split  $args ]  0 ]
set val [ lindex [ split  $args ]  1 ]
set body [ subst { "$opt": "$val" } ]
set res [rest::post http://localhost:$ws_port/vuset $body ]
putscli $res
	}
}

proc wapp-page-vuset {} {
global virtual_users conpause delayms ntimes suppo optlog unique_log_name no_log_buffer log_timestamps
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
	wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 2} {
dict set jsondict error message "Incorrect number of parameters to vuset key value"
	wapp-2-json 2 $jsondict
return
} else {
set key [ huddle keys $huddlecontent ] 
set val [ huddle get_stripped $huddlecontent $key ]
set ind [ lsearch {vu delay repeat iterations showoutput logtotemp unique nobuff timestamps} $key ]
if { $ind eq -1 } {
dict set jsondict error message "Invalid option to vuset key value"
	wapp-2-json 2 $jsondict
return
	}
if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
dict set jsondict error message "Virtual Users exist, destroy with vudestroy before changing settings"
	wapp-2-json 2 $jsondict
return
}
switch  $key {
vu {	
set virtual_users $val
dict set jsondict success message "Virtual users set to $val"
if { ![string is integer -strict $virtual_users] } {
dict set jsondict error message "The number of virtual users must be an integer"
	wapp-2-json 2 $jsondict
        set virtual_users 1
	return
        } else {
if { $virtual_users < 1 } { 
dict set jsondict error message "The number of virtual users must be 1 or greater"
	wapp-2-json 2 $jsondict
        set virtual_users 1
	return
        }
   }
wapp-2-json 2 $jsondict
}
delay {
set conpause $val
dict set jsondict success message "User Delay(ms) set to $val"
if { ![string is integer -strict $conpause] } {
dict set jsondict error message "User Delay(ms) must be an integer"
	wapp-2-json 2 $jsondict
        set conpause 500
        } else {
if { $conpause < 1 } { 
dict set jsondict error message "User Delay(ms) must be 1 or greater"
	wapp-2-json 2 $jsondict
        set conpause 500
        }
   }
wapp-2-json 2 $jsondict
}
repeat {
set delayms $val
dict set jsondict success message "Repeat Delay(ms) set to $val"
if { ![string is integer -strict $delayms] } {
dict set jsondict error message "Repeat Delay(ms) must be an integer"
	wapp-2-json 2 $jsondict
        set delayms 500
        } else {
if { $delayms < 1 } { 
dict set jsondict error message "Repeat Delay(ms) must be 1 or greater"
	wapp-2-json 2 $jsondict
        set delayms 500
        }
   }
wapp-2-json 2 $jsondict
}
iterations {
set ntimes $val
dict set jsondict success message "iterations set to $val"
if { ![string is integer -strict $ntimes] } {
dict set jsondict error message "Iterations must be an integer"
	wapp-2-json 2 $jsondict
        set ntimes 1
        } else {
if { $ntimes < 1 } { 
dict set jsondict error message "Iterations must be 1 or greater"
	wapp-2-json 2 $jsondict
        set ntimes 1
        }
   }
wapp-2-json 2 $jsondict
}
showoutput { 
set suppo $val
dict set jsondict success message "Show Output set to $val"
if { ![string is integer -strict $suppo] } {
dict set jsondict error message "Show Output must be 0 or 1"
	wapp-2-json 2 $jsondict
        set suppo 1
        } else {
if { $suppo > 1 } { 
dict set jsondict error message "Show Output must be 0 or 1"
	wapp-2-json 2 $jsondict
        set suppo 1
        }
   }
wapp-2-json 2 $jsondict
}
logtotemp { 
#set optlog $val
set optlog 0
dict set jsondict error message "Log Output disabled in webservice mode, setting logtotemp to 0"
wapp-2-json 2 $jsondict
}
unique { 
set unique_log_name $val
dict set jsondict success message "Unique Log Name set to $val"
if { ![string is integer -strict $unique_log_name] } {
dict set jsondict error message "Unique Log Name must be 0 or 1"
	wapp-2-json 2 $jsondict
        set unique_log_name 0
        } else {
if { $unique_log_name > 1 } { 
dict set jsondict error message "Unique Log Name must be 0 or 1"
	wapp-2-json 2 $jsondict
        set unique_log_name 0
        }
   }
wapp-2-json 2 $jsondict
}
nobuff { 
set nobuff $val
dict set jsondict success message "No Log Buffer set to $val"
if { ![string is integer -strict $nobuff] } {
dict set jsondict error message "No Log Buffer must be 0 or 1"
	wapp-2-json 2 $jsondict
        set nobuff 0
        } else {
if { $nobuff > 1 } { 
dict set jsondict error message "No Log Buffer must be 0 or 1"
	wapp-2-json 2 $jsondict
        set nobuff 0
        }
   }
wapp-2-json 2 $jsondict
}
timestamps { 
set log_timestamps $val
dict set jsondict success message "Log timestamps set to $val"
if { ![string is integer -strict $log_timestamps] } {
dict set jsondict error message "Log timestamps must be 0 or 1"
	wapp-2-json 2 $jsondict
        set log_timestamps 0
        } else {
if { $log_timestamps > 1 } { 
dict set jsondict error message "Log timestamps must be 0 or 1"
	wapp-2-json 2 $jsondict
        set log_timestamps 0
        }
   }
wapp-2-json 2 $jsondict
}
default {
dict set jsondict error message "Invalid option to vuset key value"
	wapp-2-json 2 $jsondict
	}
}}}}

proc dgset { args } {
global ws_port
if {[ llength $args ] != 2} {
set body { "type": "error", "key": "message", "value": "Incorrect number of parameters to dgset key value" } 
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
} else {
set opt [ lindex [ split  $args ]  0 ]
set val [ lindex [ split  $args ]  1 ]
set body [ subst { "$opt": "$val" } ]
set res [rest::post http://localhost:$ws_port/dgset $body ]
putscli $res
	}
}

proc wapp-page-dgset {} {
global rdbms bm gen_count_ware gen_scale_fact gen_directory gen_num_vu maxvuser virtual_users lprefix
if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
if {  ![ info exists bm ] } { set bm "TPC-C" }
if [catch {set huddlecontent [ huddle::json2huddle [list [wapp-param CONTENT]]]} message ] {
dict set jsondict error message [ subst {$message} ]
        wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 2} {
dict set jsondict error message "Incorrect number of parameters to dgset key value"
        wapp-2-json 2 $jsondict
return
} else {
set key [ huddle keys $huddlecontent ]
set val [ huddle get_stripped $huddlecontent $key ]
set ind [ lsearch [ list vu scale_fact warehouse directory ] $key ]
if { $ind eq -1 } {
dict set jsondict error message "Invalid option to dgset key value"
        wapp-2-json 2 $jsondict
return
        }
if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
dict set jsondict error message "Virtual Users exist, destroy with vudestroy before changing settings"
        wapp-2-json 2 $jsondict
return
}
switch $key {
vu {
set gen_num_vu $val
if { $bm eq "TPC-C" } {
     if { ![string is integer -strict $gen_count_ware] || $gen_count_ware < 1 || $gen_count_ware > 100000 } {
	dict set jsondict error message "The number of warehouses must be a positive integer less than or equal to 100000"
        wapp-2-json 2 $jsondict
	set gen_num_vu 1
        set virtual_users 1
	return
        } 
if { $gen_num_vu > $gen_count_ware } {
	dict set jsondict error message "Build virtual users $gen_num_vu must be less than or equal to number of warehouses $gen_count_ware"
        wapp-2-json 2 $jsondict
	set gen_num_vu $gen_count_ware
	return
	}}
if { ![string is integer -strict $gen_num_vu] || $gen_num_vu < 1 || $gen_num_vu > 1024 } { 
	dict set jsondict error message "The number of virtual users must be a positive integer less than 1024" 
        wapp-2-json 2 $jsondict
	set gen_num_vu 1
        set virtual_users 1
	return
	} else {
	set maxvuser [ expr $gen_num_vu + 1 ]
	set virtual_users $maxvuser 
	dict set jsondict success message "Set virtual users to $gen_num_vu for data generation"
	wapp-2-json 2 $jsondict
		}
   }
scale_fact {
set gen_scale_fact $val
dict set jsondict success message "Set Scale Factor to $gen_scale_fact for data generation"
set validvalues {1 10 30 100 300 1000 3000 10000 30000 100000}
set ind [ lsearch $validvalues $gen_scale_fact ]
if { $ind eq -1 } {
	dict set jsondict error message "Scale Factor must be a value in $validvalue" 
        wapp-2-json 2 $jsondict
	set gen_scale_fact 1
return
}
wapp-2-json 2 $jsondict
}
warehouse {
set gen_count_ware $val
dict set jsondict success message "Set warehouses to $gen_count_ware for data generation"
if { ![string is integer -strict $gen_count_ware] } {
	dict set jsondict error message "The number of virtual users must be an integer" 
        wapp-2-json 2 $jsondict
	set gen_num_vu 1
        set virtual_users 1
	return
        } else {
if { $virtual_users < 1 } { 
	dict set jsondict error message "The number of virtual users must be 1 or greater" 
        wapp-2-json 2 $jsondict
	set gen_num_vu 1
        set virtual_users 1
	return
        }
if { $gen_num_vu > $gen_count_ware } {
	dict set jsondict error message "Build virtual users $gen_num_vu must be less than or equal to number of warehouses $gen_count_ware" 
        wapp-2-json 2 $jsondict
	set gen_num_vu $gen_count_ware
	return
	}
    }
    wapp-2-json 2 $jsondict
}
directory {
dict set jsondict success message "Set directory to $gen_directory for data generation"
	set tmp $gen_directory
	set gen_directory $val
 if {![file writable $gen_directory]} {
dict set jsondict error message "Files cannot be written to chosen directory you must create $gen_directory before generating data" 
wapp-2-json 2 $jsondict
set gen_directory $tmp
		}
wapp-2-json 2 $jsondict
}}}}}

proc customscript { scriptname } {
global ws_port
set _ED(file) $scriptname
if {$_ED(file) == ""} {return}
    if {![file readable $_ED(file)]} {
set body [ subst { "type": "error", "key": "message", "value": "File $scriptname is not readable." } ]
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
        return
    }
if {[catch "open \"$_ED(file)\" r" fd]} {
set body [subst { "type": "error", "key": "message", "value": "Error while opening $scriptname: $fd" } ]
        } else {
 set _ED(package) "[read $fd]"
    close $fd
	}
set huddleobj [ huddle compile {string} "$_ED(package)" ]
set jsonobj [ huddle jsondump $huddleobj ]
set body [ subst { {"script": $jsonobj}} ]
set res [ rest::post http://localhost:$ws_port/customscript $body ]
puts $res
}

proc wapp-page-customscript {} {
global _ED
if [catch {set huddlecontent [ huddle::json2huddle [wapp-param CONTENT]]} message ] {
dict set jsondict error message [ subst {$message} ]
        wapp-2-json 2 $jsondict
} else {
if {[ huddle llength $huddlecontent ] != 2} {
dict set jsondict error message "Incorrect number of parameters to customscript key value"
        wapp-2-json 2 $jsondict
return
} else {
set key [ huddle keys $huddlecontent ]
set val [ huddle get_stripped $huddlecontent $key ]
dict set jsondict success message "Set custom script"
 set _ED(package) $val
        wapp-2-json 2 $jsondict
}}}

proc vudestroy {} {
global ws_port
set res [rest::get http://localhost:$ws_port/vudestroy "" ]
putscli $res
}

proc wapp-page-vudestroy {} {
        global threadscreated threadsbytid vustatus AVUC opmode
        if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] > 0} {
        tsv::set application abort 1
        if { [catch {ed_kill_vusers} message]} {
	dict set jsondict error message "Virtual Users remain running in background or shutting down, retry"
        wapp-2-json 2 $jsondict
        } else {
        #remote_command [ concat vudestroy ]
        set x 0
        set checkstop 0
        while {!$checkstop} {
        incr x
        after 1000
        update
        if {[expr [ llength [ threadnames_without_tcthread ] ] - 1 ] eq 0} {
        set checkstop 1
	dict set jsondict success message "vudestroy success"
        wapp-2-json 2 $jsondict
        unset -nocomplain AVUC
        unset -nocomplain vustatus
                }
        if { $x eq 20 } {
        set checkstop 1
	dict set jsondict error message "Virtual Users remain running in background or shutting down, retry"
        wapp-2-json 2 $jsondict
                }
            }
        }
    } else {
        if { $opmode eq "Replica" } {
#In Primary Replica Mode ed_kill_vusers may have already been called from Primary so thread::names is 1
        unset -nocomplain AVUC
        unset -nocomplain vustatus
	dict set jsondict error message "vudestroy from Primary, Replica status clean up"
        wapp-2-json 2 $jsondict
           } else {
	dict set jsondict error message "No virtual users found to destroy"
        wapp-2-json 2 $jsondict
        }
    }
}

proc vucreate {} {
global ws_port
set res [rest::get http://localhost:$ws_port/vucreate "" ]
putscli $res
}

proc wapp-page-vucreate {} {
global _ED lprefix vustatus
if { [ string length $_ED(package) ] eq 0  } {
dict set jsondict error message "No Script loaded: Load script before creating Virtual Users"
        wapp-2-json 2 $jsondict
} else {
if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
dict set jsondict error message "Virtual Users exist, destroy with vudestroy before creating"
        wapp-2-json 2 $jsondict
return
}
unset -nocomplain vustatus
set vustatus {}
	if { [catch {load_virtual} message]} {
dict set jsondict error message "Failed to create virtual users: $message"
        wapp-2-json 2 $jsondict
	} else {
if { $lprefix eq "loadtimed" } {
dict set jsondict success message "[expr [ llength [ thread::names ] ] - 1 ] Virtual Users Created with Monitor VU"
        wapp-2-json 2 $jsondict
} else {
dict set jsondict success message "[expr [ llength [ thread::names ] ] - 1 ] Virtual Users Created"
        wapp-2-json 2 $jsondict
	    }
	}
    }
}

proc buildschema {} {
global ws_port
set res [rest::get http://localhost:$ws_port/buildschema "" ]
putscli $res
}

proc wapp-page-buildschema {} {
global virtual_users maxvuser rdbms bm threadscreated jobid 
if { [ info exists threadscreated ] } {
dict set jsondict error message "Cannot build schema with Virtual Users active, destroy Virtual Users first"
        wapp-2-json 2 $jsondict
return
        }
set jobid [guid]
if { [jobmain $jobid] eq 1 } {
dict set jsondict error message "Jobid already exists or error in creating jobid in JOBMAIN table"
        wapp-2-json 2 $jsondict
return
        }
upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } {
	set dictname config$key
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
dict set jsondict error message "Number of virtual users to build schema must be an integer"
        wapp-2-json 2 $jsondict
	return
	}
	if { $buildvu > $buildcw } {
dict set jsondict error message "Build virtual users must be less than or equal to number of warehouses. You have $buildvu virtual users building $buildcw warehouses"
        wapp-2-json 2 $jsondict
	return
		} else {
	if { $buildvu eq 1 } {
	set maxvuser 1
	set virtual_users 1
	clearscript2
	if { [ catch {build_schema} message ] } {
dict set jsondict error message "$message"
        wapp-2-json 2 $jsondict
unset -nocomplain jobid
return
			} else {
dict set jsondict success message "Building $buildcw Warehouses(s) with 1 Virtual User: $jobid"
        wapp-2-json 2 $jsondict
			}
	} else {
	set maxvuser [ expr $buildvu + 1 ]
	set virtual_users $maxvuser
	clearscript2
	if { [ catch {build_schema} message ] } {
	dict set jsondict error message "$message"
        wapp-2-json 2 $jsondict
unset -nocomplain jobid
			} else {
dict set jsondict success message "Building $buildcw Warehouses with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu): JOBID=$jobid"
        wapp-2-json 2 $jsondict
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
	dict set jsondict error message "Error: Number of virtual users to build schema must be an integer less than 1024"
        wapp-2-json 2 $jsondict
	return
	}
set validvalues {1 10 30 100 300 1000 3000 10000 30000 100000}
set ind [ lsearch $validvalues $buildsf ]
if { $ind eq -1 } {
dict set jsondict error message "Scale Factor must be a value in $validvalues"
     wapp-2-json 2 $jsondict
return
}
if { $buildvu eq 1 } { set maxvuser 1 } else {
	set maxvuser [ expr $buildvu + 1 ]
	}
	set virtual_users $maxvuser
	clearscript2
	if { [ catch {build_schema} message ] } {
	dict set jsondict error message "$message"
        wapp-2-json 2 $jsondict
 		     } else {
dict set jsondict success message "Building Scale Factor $buildsf with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu): JOBID=$jobid"
     wapp-2-json 2 $jsondict
			}
            }
}

proc jobs { args } {
global ws_port
switch [ llength $args ] {
0 {
#Query all jobs
set res [rest::get http://localhost:$ws_port/jobs "" ]
return $res
}
1 {
set param [ lindex [ split  $args ]  0 ]
#List results for all jobs
if [ string equal $param "result" ] {
	set alljobs [ rest::format_json [ jobs ]]
	foreach jobres $alljobs {
set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobres&result "" ]
putscli $res
	}
	} elseif [ string equal $param "timestamp" ] {
	set alljobs [ rest::format_json [ jobs ]]
	foreach jobres $alljobs {
set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobres&timestamp "" ]
putscli $res
	}	
} else {
#Query one jobid
set jobid $param
set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid "" ]
putscli $res
	}
}
2 {
#Query status, result, vu number or delete job data for one jobid
#jobs?jobid=TEXT&status param is status
#iobs?jobid=TEXT&result param is result
#jobs?jobid=TEXT&delete param is delete
#jobs?jobid=TEXT&timestamp param is timestamp
#jobs?jobid=TEXT&dict param is dict
#jobs?jobid=TEXT&timing param is timing
#jobs?jobid=TEXT&db param is db
#jobs?jobid=TEXT&bm param is bm
#jobs?jobid=TEXT&tcount param is tcount
#jobs?jobid=TEXT&vu=INTEGER param is an INTEGER identifying the vu number
set jobid [ lindex [ split  $args ]  0 ]
set cmd [ lindex [ split  $args ]  1 ]
if [ string is entier $cmd ] { set cmd "vu=$cmd" }
set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid&$cmd "" ]
putscli $res
}
3 {
#jobs?jobid=TEXT&timing&vu param is timing
set jobid [ lindex [ split  $args ]  0 ]
set cmd [ lindex [ split  $args ]  1 ]
set vusel [ lindex [ split  $args ]  2 ]
if { $cmd != "timing" } {
set body { "type": "error", "key": "message", "value": "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID" } 
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
	} else {
#Three arguments 2nd parameter is timing
if [ string is entier $vusel ] { set vusel "vu=$vusel" }
set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid&$cmd&$vusel "" ]
putscli $res
	}
}
default {
set body { "type": "error", "key": "message", "value": "Usage: jobs?query=parameter" } 
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
	}
    }
}

interp alias {} job {} jobs

proc wapp-page-jobs {} {
global bm
set query [ wapp-param QUERY_STRING ]
set params [ split $query & ]
set paramlen [ llength $params ]
#No parameters list jobids
if { $paramlen eq 0 } {
set joboutput [ hdb eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	return
	} else {
if { $paramlen >= 1 && $paramlen <= 3 } {
foreach a $params {
lassign [split $a =] key value
dict append paramdict $key $value
                }
          } else {
dict set jsondict error message "Usage: jobs?query=parameter"
wapp-2-json 2 $jsondict
return
		}
if { $paramlen eq 3 } {
if { [ dict keys $paramdict ] != "jobid timing vu" } {
dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
wapp-2-json 2 $jsondict
return
		} else {
#3 parameter case of 1-jobid 2-timing 3-vu
set jobid [ dict get $paramdict jobid ]
set vuid [ dict get $paramdict vu ]
if [ string is entier $vuid ] {
unset -nocomplain jobtiming
set jobtiming [ dict create ]
hdb eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and VU=$vuid and SUMMARY=0 ORDER BY RATIO_PCT DESC}  {
set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
dict append jobtiming $procname $timing
}
if { ![ dict size $jobtiming ] eq 0 } {
wapp-2-json 2 $jobtiming
return
} else {
dict set jsondict error message "No Timing Data for VU $vuid for JOB $jobid: jobs?jobid=JOBID&timing&vu=VUID"
wapp-2-json 2 $jsondict
return
}
			} else {
dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
wapp-2-json 2 $jsondict
return
			}
		}
       }
}
#1 parameter
if { $paramlen eq 1 } {
if { [ dict keys $paramdict ] eq "jobid" } {
set jobid [ dict get $paramdict jobid ]
set query [ hdb eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid} ]
if { $query eq 0 } {
dict set jsondict error message "Jobid $jobid does not exist"
wapp-2-json 2 $jsondict
return
          } else {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
        set huddleobj [ huddle compile {list} $joboutput ]
        wapp-mimetype application/json
        wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        }
        } else {
dict set jsondict error message "Jobs One Parameter Usage: jobs?jobid=TEXT"
wapp-2-json 2 $jsondict
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
set query [ hdb eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
if { $query eq 0 } {
dict set jsondict error message "Jobid $jobid for virtual user $vuid does not exist"
wapp-2-json 2 $jsondict
return
	  } else {
if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" } {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	return
	}
if { [ dict keys $paramdict ] eq "jobid delete" } {
set joboutput [ hdb eval {DELETE FROM JOBMAIN WHERE JOBID=$jobid} ]
set joboutput [ hdb eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid} ]
set joboutput [ hdb eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid} ]
set joboutput [ hdb eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid} ]
dict set jsondict success message "Deleted Jobid $jobid"
     wapp-2-json 2 $jsondict
	} else {
if { [ dict keys $paramdict ] eq "jobid result" } {
if { $bm eq "TPC-C" } { 
set tstamp ""
set tstamp [ join [ hdb eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
set activevu [ lsearch -glob -inline $joboutput "*Active Virtual Users*" ]
set result [ lsearch -glob -inline $joboutput "TEST RESULT*" ]
	} else {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
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
hdb eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and SUMMARY=1 ORDER BY RATIO_PCT DESC}  {
set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
dict append jobtiming $procname $timing
}
if { ![ dict size $jobtiming ] eq 0 } {
wapp-2-json 2 $jobtiming
return
} else {
dict set jsondict error message "No Timing Data for JOB $jobid: jobs?jobid=JOBID&timing"
wapp-2-json 2 $jsondict
return
		}
	} else {
if { [ dict keys $paramdict ] eq "jobid timestamp" } {
set joboutput [ hdb eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]
wapp-2-json 2 $joboutput
return
	} else {
if { [ dict keys $paramdict ] eq "jobid dict" } {
set joboutput [ join [ hdb eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid} ]]
wapp-2-json 2 $joboutput
return
	} else {
if { [ dict keys $paramdict ] eq "jobid tcount" } {
set jobheader [ hdb eval {select distinct(db), metric from JOBTCOUNT, JOBMAIN WHERE JOBTCOUNT.JOBID=$jobid AND JOBMAIN.JOBID=$jobid} ]
set joboutput [ hdb eval {select counter, JOBTCOUNT.timestamp from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
dict append jsondict $jobheader $joboutput 
wapp-2-json 2 $jsondict
return
	} else {
if { [ dict keys $paramdict ] eq "jobid db" } {
set joboutput [ join [ hdb eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
	} else {
if { [ dict keys $paramdict ] eq "jobid bm" } {
set joboutput [ join [ hdb eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
	} else {
set joboutput [ list $jobid "Cannot find Jobid output" ]
		}
	}}}}}}
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	}
  }
	} else {
dict set jsondict error message "Jobs Two Parameter Usage: jobs?jobid=TEXT&status or jobs?jobid=TEXT&db or jobs?jobid=TEXT&bm or jobs?jobid=TEXT&timestamp or jobs?jobid=TEXT&dict or jobs?jobid=TEXT&vu=INTEGER or jobs?jobid=TEXT&result or jobs?jobid=TEXT&timing or jobs?jobid=TEXT&delete" 
wapp-2-json 2 $jsondict
return
        }
    }
}

interp alias {} wapp-page-job {} wapp-page-jobs

proc vurun {} {
global ws_port jobid
unset -nocomplain jobid
set res [rest::get http://localhost:$ws_port/vurun "" ]
putscli $res
if { [ info exists jobid ] } {
return $jobid
	} else {
return
	}
}

proc wapp-page-vurun {} {
	global _ED jobid
	set jobid [guid]
if { [jobmain $jobid] eq 1 } {
dict set jsondict error message "Jobid already exists or error in creating jobid in JOBMAIN table"
        wapp-2-json 2 $jsondict
return
        }
if { [ string length $_ED(package) ] > 0 } { 
	if { [ catch {run_virtual} message ] } {
dict set jsondict error message "Error running virtual users: $message"
        wapp-2-json 2 $jsondict
unset -nocomplain jobid
	} else {
dict set jsondict success message "Running Virtual Users: JOBID=$jobid"
        wapp-2-json 2 $jsondict
	}
	} else {
dict set jsondict error message "Error: There is no workload to run because the Script is empty"
        wapp-2-json 2 $jsondict
unset -nocomplain jobid
	}
}

proc datagenrun {} {
global ws_port
set res [rest::get http://localhost:$ws_port/datagenrun "" ]
putscli $res
}

proc wapp-page-datagenrun {} {
dict set jsondict error message "datagenrun is not supported in hammerdbws, run datageneration with hammerdb or hammerdbcli"
        wapp-2-json 2 $jsondict
}

proc switchmode {} {
global ws_port
set res [rest::get http://localhost:$ws_port/switchmode "" ]
putscli $res
}

proc wapp-page-switchmode {} {
dict set jsondict error message "Primary, replica modes not supported in hammerdbws, run remote modes with hammerdb or hammerdbcli"
        wapp-2-json 2 $jsondict
}

proc steprun {} {
global ws_port
set res [rest::get http://localhost:$ws_port/steprun "" ]
putscli $res
}

proc wapp-page-steprun {} {
dict set jsondict error message "Steprun not supported in hammerdbws, run steprun with hammerdbcli"
        wapp-2-json 2 $jsondict
}

proc _dumpdb {} {
global ws_port
set res [rest::get http://localhost:$ws_port/_dumpdb "" ]
putscli $res
}

proc wapp-page-_dumpdb {} {
set jmdump [ concat [ hdb eval {SELECT * FROM JOBMAIN} ] ]]
set jtdump [ concat [ hdb eval {SELECT * FROM JOBTIMING} ]]
set jcdump [ concat [ hdb eval {SELECT * FROM JOBTCOUNT} ]]
set jodump [ concat [ hdb eval {SELECT * FROM JOBOUTPUT} ]]
set joboutput [ list $jmdump $jtdump $jcdump $jodump ]
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	}

proc quit {} {
global ws_port
set res [rest::get http://localhost:$ws_port/quit "" ]
putscli $res
}

proc wapp-page-quit {} {
putscli "Shutting down HammerDB Web Service"
exit
	}

proc runtimer { seconds } {
global ws_port
upvar elapsed elapsed
upvar timevar timevar
proc runtimer_loop { seconds } {
global ws_port
upvar elapsed elapsed
incr elapsed
upvar timevar timevar
set rcomplete [vucomplete]
  if { ![ expr {$elapsed % 60} ] } {
  set y [ expr $elapsed / 60 ]
set body [ subst { "type": "success", "key": "message", "value": "Timer: $y minutes elapsed" } ]
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
  }
if {!$rcomplete && $elapsed < $seconds } {
;#Neither vucomplete or time reached, reschedule loop
catch {after 1000 runtimer_loop $seconds }} else {
set body [ subst { "type": "success", "key": "message", "value": "runtimer returned after $elapsed seconds" } ]
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
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
global ws_port
set res [rest::get http://localhost:$ws_port/tcstart "" ]
putscli $res
}

proc wapp-page-tcstart {} {
global tc_threadID
set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
dict set jsondict error message "Transaction Counter thread already running with threadid:$tc_threadID"
wapp-2-json 2 $jsondict
return
} else {
dict set jsondict error message "Transaction Counter thread already running with threadid"
wapp-2-json 2 $jsondict
return
}
} else {
#Start transaction counter
transcount
return
}
}

proc tcstatus {} {
global ws_port
set res [rest::get http://localhost:$ws_port/tcstatus "" ]
putscli $res
}

proc wapp-page-tcstatus {} {
global ws_port
global tc_threadID
set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
dict set jsondict success message "Transaction Counter thread running with threadid:$tc_threadID"
wapp-2-json 2 $jsondict
return
} else {
dict set jsondict success message "Transaction Counter thread running"
wapp-2-json 2 $jsondict
return
}
} else {
dict set jsondict success message "Transaction Counter is not running"
wapp-2-json 2 $jsondict
return
}
}

proc tcstop {} {
global ws_port
set res [rest::get http://localhost:$ws_port/tcstop "" ]
putscli $res
}

proc wapp-page-tcstop {} {
global tc_threadID ws_port
set tclist [ thread::names ]
if { [ info exists tc_threadID ] } {
set idx [ lsearch $tclist $tc_threadID ]
if { $idx != -1 } {
dict set jsondict success message "Transaction Counter thread running with threadid:$tc_threadID"
wapp-2-json 2 $jsondict
ed_kill_transcount
return
} else {
dict set jsondict success message "Transaction Counter thread running"
wapp-2-json 2 $jsondict
ed_kill_transcount
return
}
} else {
dict set jsondict success message "Transaction Counter is not running"
wapp-2-json 2 $jsondict
return
}
}

proc waittocomplete {} {
global ws_port
proc wait_to_complete_loop {} {
global ws_port
upvar wcomplete wcomplete
set wcomplete [vucomplete]
if {!$wcomplete} { catch {after 5000 wait_to_complete_loop} } else {
set body { "type": "success", "key": "message", "value": "waittocomplete called script exit" }
set res [rest::post http://localhost:$ws_port/echo $body ]
putscli $res
exit
}
}
set wcomplete "false"
wait_to_complete_loop
vwait forever
}

proc start_webservice { args } {
global ws_port
upvar #0 genericdict genericdict
if {[dict exists $genericdict webservice ws_port ]} {
set ws_port [ dict get $genericdict webservice ws_port ]
if { ![string is integer -strict $ws_port ] } {
puts "Warning port not set to integer in config setting to default"
	set ws_port 8080  
		}
	} else { 
puts "Warning port not found in config setting to default"
	set ws_port 8080  
	}
if {[dict exists $genericdict webservice sqlite_db ]} {
set sqlite_db [ dict get $genericdict webservice sqlite_db ]
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
if [catch {sqlite3 hdb $sqlite_db} message ] {
puts "Error initializing SQLite database : $message"
return
        } else {
catch {hdb timeout 30000}
#hdb eval {PRAGMA foreign_keys=ON}
if { $sqlite_db eq ":memory:" } {
catch {hdb eval {DROP TABLE JOBMAIN}}
catch {hdb eval {DROP TABLE JOBTIMING}}
catch {hdb eval {DROP TABLE JOBTCOUNT}}
catch {hdb eval {DROP TABLE JOBOUTPUT}}
if [catch {hdb eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
return
	} elseif [ catch {hdb eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
	} elseif [ catch {hdb eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
return
	} elseif [ catch {hdb eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
puts "Error creating JOBOUTPUT table in SQLite in-memory database : $message"
return
        } else {
catch {hdb eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
catch {hdb eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
catch {hdb eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
catch {hdb eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
puts "Initialized new SQLite in-memory database"
	}
} else {
if [catch {set tblname [ hdb eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
return
        } else {
if { $tblname eq "" } {
     if [catch {hdb eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
return
	} elseif [ catch {hdb eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
return
	} elseif [ catch {hdb eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
return
        } elseif [catch {hdb eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
puts "Error creating JOBOUTPUT table in SQLite on-disk database : $message"
return
        } else {
catch {hdb eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
catch {hdb eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
catch {hdb eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
catch {hdb eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
puts "Initialized new SQLite on-disk database $sqlite_db"
	}
     } else {
puts "Initialized SQLite on-disk database $sqlite_db using existing tables"
	}
    }
}
tsv::set webservice wsport $ws_port
tsv::set webservice sqldb $sqlite_db
puts "Starting HammerDB Web Service on port $ws_port"
if [catch {wapp-start [ list --server $ws_port $args ]} message ] {
puts "Error starting HammerDB webservice on port $ws_port : $message"
		} else {
#Readline::interactws called from main script
		}
        }
}
