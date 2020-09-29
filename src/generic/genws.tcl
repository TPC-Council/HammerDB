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
 } else {
}
dict set vustatus [ expr $vuser + 1 ] "WAIT IDLE"
}}
set totrun [ expr $maxvuser * $ntimes ]
}

proc runninguser { threadid } { 
global table threadscreated thvnum inrun AVUC vustatus jobid
set AVUC "run"
set message [ join " Vuser\  [ expr $thvnum($threadid) + 1]:RUNNING" ]
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "RUNNING"
 }

proc printresult { result threadid } { 
global vustatus table threadscreated thvnum succ fail totrun totcount inrun AVUC jobid
incr totcount
if { $result == 0 } {
set message [ join " Vuser\  [expr $thvnum($threadid) + 1]:FINISHED SUCCESS" ]
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH SUCCESS"
} else {
set message [ join " Vuser\ [expr $thvnum($threadid) + 1]:FINISHED FAILED" ]
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
dict set vustatus [ expr $thvnum($threadid) + 1 ] "FINISH FAILED"
}
if { $totrun == $totcount } {
set AVUC "complete"
if { [ info exists inrun ] } { unset inrun }
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, "ALL VIRTUAL USERS COMPLETE")}
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
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
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
if { ![string match {*index*} $info] } {
if { [ string length $info ] == 0 } {
set message "Warning: a running Virtual User was terminated, any pending output has been discarded"
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
} else {
if { [ info exists threadsbytid($id) ] } {
set vuser [expr $threadsbytid($id) + 1]
set info "Error: $info"
hdb eval {INSERT INTO JOBS VALUES($jobid, $vuser, $info)}
        }  else {
    if {[string match {*.tc*} $info]} {
set message "Warning: Transaction Counter stopped, connection message not displayed"
hdb eval {INSERT INTO JOBS VALUES($jobid, 0, $message)}
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
hdb eval {INSERT INTO JOBS VALUES($jobid, $vuser, $lastline)}
}

rename logtofile _logtofile
proc logtofile { id msg } {
puts "Warning: File Logging disabled in web service mode"
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

proc clearscript {} {
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
set timep [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *timeprofile ]
if { $timep != "" } {
set db_timeprofile [ dict get [ set $dictname ] tpcc $timep ]
if { $db_timeprofile } { shared_tpcc_functions "timeprofile" "false" }
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
    <p>See the <a href='%html($B)/env'>HammerDB Web Service Environment</a></p>
  </head>
  <body>
    <h2>HAMMERDB REST/HTTP API</h2>
    <pre><b>GET db</b>: Show the configured database.
get http://localhost:8080/print?db / get http://localhost:8080/db
{
  \"current\": \"Oracle\",
  \"ora\": \"Oracle\",
  \"mssqls\": \"MSSQLServer\",
  \"db2\": \"Db2\",
  \"mysql\": \"MySQL\",
  \"pg\": \"PostgreSQL\",
  \"redis\": \"Redis\"
}
    <br>
<b>GET bm</b>: Show the configured benchmark.
get http://localhost:8080/print?bm / get http://localhost:8080/bm
{\"benchmark\": \"TPC-C\"}
    <br>
<b>GET dict</b>: Show the dictionary for the current database ie all active variables.
get http://localhost:8080/print?dict /  http://localhost:8080/dict
{
  \"connection\": {
    \"system_user\": \"system\",
    \"system_password\": \"manager\",
    \"instance\": \"oracle\",
    \"rac\": \"0\"
  },
  \"tpcc\": {
    \"count_ware\": \"1\",
    \"num_vu\": \"1\",
    \"tpcc_user\": \"tpcc\",
    \"tpcc_pass\": \"tpcc\",
    \"tpcc_def_tab\": \"tpcctab\",
    \"tpcc_ol_tab\": \"tpcctab\",
    \"tpcc_def_temp\": \"temp\",
    \"partition\": \"false\",
    \"hash_clusters\": \"false\",
    \"tpcc_tt_compat\": \"false\",
    \"total_iterations\": \"1000000\",
    \"raiseerror\": \"false\",
    \"keyandthink\": \"false\",
    \"checkpoint\": \"false\",
    \"ora_driver\": \"test\",
    \"rampup\": \"2\",
    \"duration\": \"5\",
    \"allwarehouse\": \"false\",
    \"timeprofile\": \"false\"
  }
}
<br> 
<b>GET script</b>: Show the loaded script.
get http://localhost:8080/print?script / http://localhost:8080/script
{\"script\": \"#!\/usr\/local\/bin\/tclsh8.6\n#EDITABLE OPTIONS##################################################\nset library Oratcl ;# Oracle OCI Library\nset total_iterations 1000000 ;# Number of transactions before logging off\nset RAISEERROR \\"false\\" ;# Exit script on Oracle error (true or false)\nset KEYANDTHINK \\"false\\" ;# Time for user thinking and keying (true or false)\nset CHECKPOINT \\"false\\" ;# Perform Oracle checkpoint when complete (true or false)\nset rampup 2;  # Rampup time in minutes before first snapshot is taken\nset duration 5;  # Duration in minutes before second AWR snapshot is taken\nset mode \\"Local\\" ;# HammerDB operational mode\nset timesten \\"false\\" ;# Database is TimesTen\nset systemconnect system\/manager@oracle ;# Oracle connect string for system user\nset connect tpcc\/new_password@oracle ;# Oracle connect string for tpc-c user\n#EDITABLE OPTIONS##################################################\n#LOAD LIBRARIES AND MODULES &#8230;. \n\"}
<br> 
<b>GET vuconf</b>: Show the virtual user configuration.
get http://localhost:8080/print?vuconf / http://localhost:8080/vuconf
{
  \"Virtual Users\": \"1\",
  \"User Delay(ms)\": \"500\",
  \"Repeat Delay(ms)\": \"500\",
  \"Iterations\": \"1\",
  \"Show Output\": \"1\",
  \"Log Output\": \"0\",
  \"Unique Log Name\": \"0\",
  \"No Log Buffer\": \"0\",
  \"Log Timestamps\": \"0\"
}
<br> 
<b>GET vucreate</b>: Create the virtual users. Equivalent to the Virtual User Create option in the graphical interface. Use vucreated to see the number created, vustatus to see the status and vucomplete to see whether all active virtual users have finished the workload. A script must be loaded before virtual users can be created.
get http://localhost:8080/vucreate
{\"success\": {\"message\": \"4 Virtual Users Created\"}}
<br> 
<b>GET vucreated</b>: Show the number of virtual users created.
get http://localhost:8080/print?vucreated / get http://localhost:8080/vucreated
{\"Virtual Users created\": \"10\"}
<br> 
<b>GET vustatus</b>: Show the status of virtual users, status will be \"WAIT IDLE\" for virtual users that are created but not running a workload,\"RUNNING\" for virtual users that are running a workload, \"FINISH SUCCESS\" for virtual users that completed successfully or \"FINISH FAILED\" for virtual users that encountered an error.
get http://localhost:8080/print?vustatus / get http://localhost:8080/vustatus
{\"Virtual User status\": \"1 {WAIT IDLE} 2 {WAIT IDLE} 3 {WAIT IDLE} 4 {WAIT IDLE} 5 {WAIT IDLE} 6 {WAIT IDLE} 7 {WAIT IDLE} 8 {WAIT IDLE} 9 {WAIT IDLE} 10 {WAIT IDLE}\"}
<br> 
<b>GET datagen</b>: Show the datagen configuration
get http://localhost:8080/print?datagen /  get http://localhost:8080/datagen
{
  \"schema\": \"TPC-C\",
  \"database\": \"Oracle\",
  \"warehouses\": \"1\",
  \"vu\": \"1\",
  \"directory\": \"\/tmp\\"\"
}
<br> 
<b>GET vucomplete</b>: Show if virtual users have completed. returns \"true\" or \"false\" depending on whether all virtual users that started a workload have completed regardless of whether the status was \"FINISH SUCCESS\" or \"FINISH FAILED\".
get http://localhost:8080/vucomplete
{\"Virtual Users complete\": \"true\"}
<br> 
<b>GET vudestroy</b>: Destroy the virtual users. Equivalent to the Destroy Virtual Users button in the graphical interface that replaces the Create Virtual Users button after virtual user creation.
get http://localhost:8080/vudestroy
{\"success\": {\"message\": \"vudestroy success\"}}
<br> 
<b>GET loadscript</b>: Load the script for the database and benchmark set with dbset and the dictionary variables set with diset. Use print?script to see the script that is loaded. Equivalent to loading a Driver Script in the Script Editor window in the graphical interface. Driver script must be set to timed for the script to be loaded. Test scripts should be run in the GUI environment.  
get http://localhost:8080/loadscript
{\"success\": {\"message\": \"script loaded\"}}
<br> 
<b>GET clearscript</b>: Clears the script. Equivalent to the \"Clear the Screen\" button in the graphical interface.
get http://localhost:8080/clearscript
{\"success\": {\"message\": \"Script cleared\"}}
<br> 
<b>GET vurun</b>: Send the loaded script to the created virtual users for execution. Equivalent to the Run command in the graphical interface. Creates a job id associated with all output. 
get http://localhost:8080/vurun
{\"success\": {\"message\": \"Running Virtual Users: JOBID=5CEFBFE658A103E253238363\"}}
<br>
<b>GET datagenrun</b>: Run Data Generation. Equivalent to the Generate option in the graphical interface. Not supported in web service. Generate data using GUI or CLI. 
<br>
<b>GET buildschema</b>: Runs the schema build for the database and benchmark selected with dbset and variables selected with diset. Equivalent to the Build command in the graphical interface. Creates a job id associated with all output. 
get http://localhost:8080/buildschema
{\"success\": {\"message\": \"Building 6 Warehouses with 4 Virtual Users, 3 active + 1 Monitor VU(dict value num_vu is set to 3): JOBID=5CEFA68458A103E273433333\"}}
<br>
<b>GET jobs</b>: Show the job ids, output, status and results of jobs created by buildschema and vurun. Job output is equivalent to the output viewed in the graphical interface or command line.
GET http://localhost:8080/jobs: Show all job ids
get http://localhost:8080/jobs
\[
  \"5CEE889958A003E203838313\",
  \"5CEFA68458A103E273433333\"
\]
GET http://localhost:8080/jobs?jobid=TEXT: Show output for the specified job id.
get http://localhost:8080/jobs?jobid=5CEFA68458A103E273433333
\[
  \"0\",
  \"Ready to create a 6 Warehouse Oracle TPC-C schema\nin database VULPDB1 under user TPCC in tablespace TPCCTAB?\",
  \"0\",
  \"Vuser 1:RUNNING\",
  \"1\",
  \"Monitor Thread\",
  \"1\",
  \"CREATING TPCC SCHEMA\",
...
  \"1\",
  \"TPCC SCHEMA COMPLETE\",
  \"0\",
  \"Vuser 1:FINISHED SUCCESS\",
  \"0\",
  \"ALL VIRTUAL USERS COMPLETE\"
\]
GET http://localhost:8080/jobs?jobid=TEXT&amp;vu=INTEGER: Show output for the specified job id and virtual user.
get http://localhost:8080/jobs?jobid=5CEFA68458A103E273433333&amp;vu=1
\[
  \"1\",
  \"Monitor Thread\",
  \"1\",
  \"CREATING TPCC SCHEMA\",
  \"1\",
  \"CREATING USER tpcc\",
  \"1\",
  \"CREATING TPCC TABLES\",
  \"1\",
  \"Loading Item\",
  \"1\",
  \"Loading Items - 50000\",
  \"1\",
  \"Loading Items - 100000\",
  \"1\",
  \"Item done\",
  \"1\",
  \"Monitoring Workers...\",
  \"1\",
  \"Workers: 3 Active 0 Done\"
\]
GET http://localhost:8080/jobs?jobid=TEXT&amp;status: Show status for the specified job id. Equivalent to virtual user 0.
get http://localhost:8080/jobs?jobid=5CEFA68458A103E273433333&amp;status
\[
  \"0\",
  \"Ready to create a 6 Warehouse Oracle TPC-C schema\nin database VULPDB1 under user TPCC in tablespace TPCCTAB?\",
  \"0\",
  \"Vuser 1:RUNNING\",
  \"0\",
  \"Vuser 2:RUNNING\",
  \"0\",
  \"Vuser 3:RUNNING\",
  \"0\",
  \"Vuser 4:RUNNING\",
  \"0\",
  \"Vuser 4:FINISHED SUCCESS\",
  \"0\",
  \"Vuser 3:FINISHED SUCCESS\",
  \"0\",
  \"Vuser 2:FINISHED SUCCESS\",
  \"0\",
  \"Vuser 1:FINISHED SUCCESS\",
  \"0\",
  \"ALL VIRTUAL USERS COMPLETE\"
\]
GET http://localhost:8080/jobs?jobid=TEXT&amp;result: Show the test result for the specified job id. If job is not a test job such as build job then no result will be reported. 
get http://localhost:8080/jobs?jobid=5CEFA68458A103E273433333&amp;result
\[
  \"5CEFA68458A103E273433333\",
  \"Jobid has no test result\"
\]
GET http://localhost:8080/jobs?jobid=TEXT&amp;delete: Delete all output for the specified jobid.
get http://localhost:8080/jobs?jobid=5CEFA68458A103E273433333&amp;delete
{\"success\": {\"message\": \"Deleted Jobid 5CEFA68458A103E273433333\"}} 
<br>
<b>GET killws</b>: Terminates the webservice and reports message to the console.
get http://localhost:8080/killws
Shutting down HammerDB Web Service
<br>
<b>POST dbset</b>: Usage: dbset \[db|bm\] value. Sets the database (db) or benchmark (bm). Equivalent to the Benchmark Menu in the graphical interface. Database value is set by the database prefix in the XML configuration.
set body { \"db\": \"ora\" }
rest::post http://localhost:8080/dbset $body
<br>
<b>POST diset</b>: Usage: diset dict key value. Set the dictionary variables for the current database. Equivalent to the Schema Build and Driver Options windows in the graphical interface. Use print?dict to see what these variables are and diset to change.
set body { \"dict\": \"tpcc\", \"key\": \"rampup\", \"value\": \"0\" }
rest::post http://localhost:8080/diset $body
set body { \"dict\": \"tpcc\", \"key\": \"duration\", \"value\": \"1\" }
rest::post http://localhost:8080/diset $body
<br>
<b>POST vuset</b>: Usage: vuset \[vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps\]. Configure the virtual user options. Equivalent to the Virtual User Options window in the graphical interface.
set body { \"vu\": \"4\" }
rest::post http://localhost:8080/vuset $body
<br>
<b>POST customscript</b>: Load an external script. Equivalent to the \"Open Existing File\" button in the graphical interface. Script must be converted to JSON format before post as shown in the example:
set customscript \"testscript.tcl\"
set _ED(file) $customscript
if {$_ED(file) == \"\"} {return}
    if {!\[file readable $_ED(file)\]} {
        puts \"File \[$_ED(file)\] is not readable.\"
        return
    }
if {\[catch \"open \\"$_ED(file)\\" r\" fd\]} {
      puts \"Error while opening $_ED(file): \[$fd\]\"
        } else {
 set _ED(package) \"\[read $fd\]\"
 close $fd
	}
set huddleobj \[ huddle compile {string} \"$_ED(package)\" \]
set jsonobj \[ huddle jsondump $huddleobj \]
set body \[ subst { {\"script\": $jsonobj}} \]
set res \[ rest::post http://localhost:8080/customscript $body \] 
<br>
<b>POST dgset</b>: Usage: dgset \[vu|ware|directory\]. Set the Datagen options. Equivalent to the Datagen Options dialog in the graphical interface.
set body { \"directory\": \"/home/oracle\" }
rest::post http://localhost:8080/dgset $body 
<br>
<b>DEBUG</b>
<b>GET dumpdb</b>: Dumps output of the SQLite database to the console.
GET http://localhost:8080/dumpdb
***************DEBUG***************
5CEE889958A003E203838313 0 {Ready to create a 6 Warehouse Oracle TPC-C schema
in database VULPDB1 under user TPCC in tablespace TPCCTAB?} 5CEE889958A003E203838313 0 {Vuser 1:RUNNING} 5CEE889958A003E203838313 1 {Monitor Thread} 5CEE889958A003E203838313 1 {CREATING TPCC SCHEMA} 5CEE889958A003E203838313 0 {Vuser 2:RUNNING} 5CEE889958A003E203838313 2 {Worker Thread} 5CEE889958A003E203838313 2 {Waiting for Monitor Thread...} 5CEE889958A003E203838313 1 {Error: ORA-12541: TNS:no listener} 5CEE889958A003E203838313 0 {Vuser 1:FINISHED FAILED} 5CEE889958A003E203838313 0 {Vuser 3:RUNNING} 5CEE889958A003E203838313 3 {Worker Thread} 5CEE889958A003E203838313 3 {Waiting for Monitor Thread...} 5CEE889958A003E203838313 0 {Vuser 4:RUNNING} 5CEE889958A003E203838313 4 {Worker Thread} 5CEE889958A003E203838313 4 {Waiting for Monitor Thread...} 5CEE889958A003E203838313 2 {Monitor failed to notify ready state} 5CEE889958A003E203838313 0 {Vuser 2:FINISHED SUCCESS} 5CEE889958A003E203838313 3 {Monitor failed to notify ready state} 5CEE889958A003E203838313 0 {Vuser 3:FINISHED SUCCESS} 5CEE889958A003E203838313 4 {Monitor failed to notify ready state} 5CEE889958A003E203838313 0 {Vuser 4:FINISHED SUCCESS} 5CEE889958A003E203838313 0 {ALL VIRTUAL USERS COMPLETE}
***************DEBUG***************</pre>
    <br>
  </body>
</html>

	}
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
global rdbms bm wapp
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
wapp-2-json 2 $tmpdictforpt
    }
  }
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
	if { [ clearscript ] } {
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


proc wapp-page-clearscript {} {
if { [ clearscript ] } { 
dict set jsondict success message "Script cleared"
	} else {
dict set jsondict error message "Error:script failed to clear"
	}
	wapp-2-json 2 $jsondict
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
if { ![string is integer -strict $gen_count_ware] || $gen_count_ware < 1 || $gen_count_ware > 30000 } { 
	dict set jsondict error message "The number of warehouses must be a positive integer less than 30000"
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
	dict set jsondict error message "The number of virutal users must be a positive integer less than 1024" 
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

proc wapp-page-vudestroy {} {
	global threadscreated vustatus AVUC
	if {[expr [ llength [ thread::names ] ] - 1 ] > 0} {
	tsv::set application abort 1
	if { [catch {ed_kill_vusers} message]} {
dict set jsondict error message "Virtual Users remain running in background or shutting down, retry"
        wapp-2-json 2 $jsondict
	} else {
	set x 0
	set checkstop 0
	while {!$checkstop} {
	incr x
	after 1000
	update
	if {[expr [ llength [ thread::names ] ] - 1 ] eq 0} {
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
dict set jsondict error message "No virtual users found to destroy"
        wapp-2-json 2 $jsondict
    }
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

proc wapp-page-buildschema {} {
global virtual_users maxvuser rdbms bm threadscreated jobid 
if { [ info exists threadscreated ] } {
dict set jsondict error message "Cannot build schema with Virtual Users active, destroy Virtual Users first"
        wapp-2-json 2 $jsondict
return
        }
set jobid [guid]
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
	clearscript
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
	clearscript
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
	clearscript
	if { [ catch {build_schema} message ] } {
	dict set jsondict error message "$message"
        wapp-2-json 2 $jsondict
 		     } else {
dict set jsondict success message "Building Scale Factor $buildsf with $maxvuser Virtual Users, $buildvu active + 1 Monitor VU(dict value $vuname is set to $buildvu): JOBID=$jobid"
     wapp-2-json 2 $jsondict
			}
            }
}

proc wapp-page-jobs {} {
global bm
set query [ wapp-param QUERY_STRING ]
set params [ split $query & ]
set paramlen [ llength $params ]
#No parameters list jobids
if { $paramlen eq 0 } {
set joboutput [ hdb eval {SELECT DISTINCT JOBID FROM JOBS} ]
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	return
	} else {
if { $paramlen >= 1 && $paramlen <= 2 } {
foreach a $params {
lassign [split $a =] key value
dict append paramdict $key $value
                }
        } else {
dict set jsondict error message "Usage: jobs?query=parameter"
wapp-2-json 2 $jsondict
return
        }
}
#1 parameter
if { $paramlen eq 1 } {
if { [ dict keys $paramdict ] eq "jobid" } {
set jobid [ dict get $paramdict jobid ]
set query [ hdb eval {SELECT COUNT(*) FROM JOBS WHERE JOBID=$jobid} ]
if { $query eq 0 } {
dict set jsondict error message "Jobid $jobid for jobstatus does not exist"
wapp-2-json 2 $jsondict
return
          } else {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBS WHERE JOBID=$jobid} ]
        set huddleobj [ huddle compile {list} $joboutput ]
        wapp-mimetype application/json
        wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        }
        } else {
dict set jsondict error message "Jobs One Parameter Usage: jobs?jobid=TEXT"
wapp-2-json 2 $jsondict
return
        }
#2 parameters
      } else {
if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid delete" } {
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
set query [ hdb eval {SELECT COUNT(*) FROM JOBS WHERE JOBID=$jobid AND VU=$vuid} ]
if { $query eq 0 } {
dict set jsondict error message "Jobid $jobid for virtual user $vuid does not exist"
wapp-2-json 2 $jsondict
return
	  } else {
if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" } {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBS WHERE JOBID=$jobid AND VU=$vuid} ]
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	return
	}
if { [ dict keys $paramdict ] eq "jobid delete" } {
set joboutput [ hdb eval {DELETE FROM JOBS WHERE JOBID=$jobid} ]
dict set jsondict success message "Deleted Jobid $jobid"
     wapp-2-json 2 $jsondict
	} else {
if { [ dict keys $paramdict ] eq "jobid result" } {
if { $bm eq "TPC-C" } { 
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBS WHERE JOBID=$jobid AND VU=$vuid} ]
set result [ lsearch -glob -inline $joboutput "TEST RESULT*" ]
	} else {
set joboutput [ hdb eval {SELECT VU,OUTPUT FROM JOBS WHERE JOBID=$jobid} ]
set result [ lsearch -all -glob -inline $joboutput "Completed*" ]
	}
if { $result eq {} } {
set joboutput [ list $jobid "Jobid has no test result" ]
		} else {
set joboutput [ list $jobid $result ]
		}
	} else {
set joboutput [ list $jobid "Cannot find Jobid output" ]
	}
	set huddleobj [ huddle compile {list} $joboutput ]
	wapp-mimetype application/json
	wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
	  }
  }
	} else {
dict set jsondict error message "Jobs Two Parameter Usage: jobs?jobid=TEXT&vu=INTEGER or jobs?jobid=TEXT&status or jobs?jobid=TEXT&result or jobs?jobid=TEXT&delete"
wapp-2-json 2 $jsondict
return
        }
    }
}

proc wapp-page-vurun {} {
	global _ED jobid
	set jobid [guid]
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

proc wapp-page-librarycheck {} {
dict set jsondict error message "librarycheck is not supported in hammerdbws, verify libraries with hammerdbcli"
        wapp-2-json 2 $jsondict
}

proc wapp-page-datagenrun {} {
dict set jsondict error message "datagenrun is not supported in hammerdbws, run datageneration with hammerdb or hammerdbcli"
        wapp-2-json 2 $jsondict
}

proc wapp-page-dumpdb {} {
set dbdump [ hdb eval {SELECT * FROM JOBS} ]
puts "***************DEBUG***************"
puts $dbdump
puts "***************DEBUG***************"
	}

proc wapp-page-killws {} {
puts "Shutting down HammerDB Web Service"
exit
	}

proc start_webservice {} {
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
set sqlite_db [ file join $tmpdir hammerdb.DB ]
        } else {
puts "Error Database Directory set to TMP but coundn't find temp directory"
	}
     }
  } else {
set sqlite_db ":memory:"
	}
if [catch {sqlite3 hdb $sqlite_db} message ] {
puts "Error initializing SQLite database : $message"
return
        } else {
if { $sqlite_db eq ":memory:" } {
catch {hdb eval {DROP TABLE JOBS}}
if [catch {hdb eval {CREATE TABLE JOBS(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
puts "Error creating JOBS table in SQLite in-memory database : $message"
return
	} else {
puts "Initialized new SQLite in-memory database"
	} 
} else {
if [catch {set tblname [ hdb eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBS'}]} message ] {
puts "Error querying  JOBS table in SQLite on-disk database : $message"
return
        }  else {
if { $tblname eq "" } {
if [catch {hdb eval {CREATE TABLE JOBS(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
puts "Error creating JOBS table in SQLite on-disk database : $message"
return
        } else {
puts "Initialized new SQLite on-disk database"
	}
     } else {
puts "Initialized SQLite on-disk database using existing JOBS table"
	}
    }
}
puts "Starting HammerDB Web Service on port $ws_port"
if [catch {wapp-start [ list --server $ws_port ]} message ] {
puts "Error starting HammerDB webservice on port $ws_port : $message"
		}
        }
}
