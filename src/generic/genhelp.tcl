proc help { args } {
#Modified help procedure for both CLI and Web Service.
global hdb_version
if [ llength [ info commands wapp-default ]] { set wsmode 1 } else { set wsmode 0 }
if $wsmode { set helpbanner "HammerDB $hdb_version WS Help Index\n
Type \"help command\" for more details on specific commands below\n"
set helpcmds [ list buildschema clearscript customscript datagenrun dbset dgset diset jobs librarycheck loadscript print quit runtimer tcset tcstart tcstatus tcstop vucomplete vucreate vudestroy vurun vuset vustatus waittocomplete ]
	} else {
set helpbanner "HammerDB $hdb_version CLI Help Index\n
Type \"help command\" for more details on specific commands below\n"
set helpcmds [ list buildschema clearscript customscript datagenrun dbset dgset diset distributescript librarycheck loadscript print quit runtimer steprun switchmode tcset tcstart tcstatus tcstop vucomplete vucreate vudestroy vurun vuset vustatus waittocomplete ]
	}
if {[ llength $args ] != 1} {
puts $helpbanner
foreach helpcmd $helpcmds { puts "\t$helpcmd" } 
} else {
set option [ lindex [ split  $args ]  0 ]
set ind [ lsearch $helpcmds $option ]
if { $ind eq -1 } {
putscli "Error: invalid option"
set helpusage "Usage: help \[[ join $helpcmds "|" ]\]"
putscli $helpusage
return
} else {
switch  $option {
jobs {
putscli "jobs - Usage: jobs"
putscli "list all jobs.\n"
putscli {jobs - Usage: jobs [jobid|result|timestamp]}
putscli "jobid: list VU output for jobid."
putscli "result: list result for all jobs."
putscli "timestamp: list starting timestamp for all jobs.\n"
putscli {jobs jobid - Usage: jobs jobid [bm|db|delete|dict|result|status|tcount|timestamp|timing|vuid]}
putscli "bm: list benchmark for jobid."
putscli "db: list database for jobid."
putscli "delete: delete jobid."
putscli "dict: list dict for jobid."
putscli "result: list result for jobid."
putscli "status: list status for jobid."
putscli "tcount: list count for jobid."
putscli "timestamp: list starting timestamp for jobid."
putscli "timing: list xtprof summary timings for jobid."
putscli "vuid: list VU output for VU with vuid for jobid.\n"
putscli {jobs jobid timing - Usage: jobs jobid timing vuid}
putscli "timing vuid: list xtprof timings for vuid for jobid.\n"
}
print {
putscli {print - Usage: print [db|bm|dict|script|vuconf|vucreated|vustatus|datagen|tcconf]}
putscli "prints the current configuration: 
db: database 
bm: benchmark
dict: the dictionary for the current database ie all active variables
script: the loaded script
vuconf: the virtual user configuration
vucreated: the number of virtual users created
vustatus: the status of the virtual users
datagen: the datagen configuration
tcconf: the transaction counter configuration"
}
quit {
putscli "quit - Usage: quit"
if $wsmode {
putscli "Shuts down the HammerDB Web Service."
	} else {
putscli "Shuts down the HammerDB CLI."
	}
}
librarycheck {
putscli "librarycheck - Usage: librarycheck"
putscli "Attempts to load the vendor provided 3rd party library for all databases and reports whether the attempt was successful."
}
dbset {
putscli "dbset - Usage: dbset \[db|bm\] value"
putscli "Sets the database (db) or benchmark (bm). Equivalent to the Benchmark Menu in the graphical interface. Database value is set by the database prefix in the XML configuration." 
}
diset {
putscli "diset - Usage: diset dict key value"
putscli "Set the dictionary variables for the current database. Equivalent to the Schema Build and Driver Options windows in the graphical interface. Use \"print dict\" to see what these variables are and diset to change:
Example:
hammerdb>diset tpcc count_ware 10
Changed tpcc:count_ware from 1 to 10 for Oracle"
}
distributescript {
putscli "distributescript - Usage: distributescript"
putscli "In Primary mode distributes the script loaded by Primary to the connected Replicas." 
}
steprun {
putscli "steprun - Usage: steprun"
putscli "Automatically switches into Primary mode, creates and connects the multiple Replicas defined in config/steps.xml and starts the Primary and Replica Virtual Users at the defined intervals creating a step workload. Both Primary and Replicas will exit on completion."
}
switchmode {
putscli "switchmode - Usage: switchmode \[mode\] ?PrimaryID? ?PrimaryHostname?"
putscli "Equivalent to the Mode option in the graphical interface. Mode to switch to must be one of Local, Primary or Replica. If Mode is Replica then the ID and Hostname of the Primary to connect to must be given."
}
buildschema {
putscli "buildschema - Usage: buildschema"
putscli "Runs the schema build for the database and benchmark selected with dbset and variables selected with diset. Equivalent to the Build command in the graphical interface." 
}
vuset {
putscli "vuset - Usage: vuset \[vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps\]"
putscli "Configure the virtual user options. Equivalent to the Virtual User Options window in the graphical interface." 
}
vucreate {
putscli "vucreate - Usage: vucreate"
putscli "Create the virtual users. Equivalent to the Virtual User Create option in the graphical interface. Use \"print vucreated\" to see the number created, vustatus to see the status and vucomplete to see whether all active virtual users have finished the workload. A script must be loaded before virtual users can be created." 
}
vurun {
putscli "vurun - Usage: vurun"
putscli "Send the loaded script to the created virtual users for execution. Equivalent to the Run command in the graphical interface."
}
vudestroy {
putscli "vudestroy - Usage: vudestroy"
putscli "Destroy the virtual users. Equivalent to the Destroy Virtual Users button in the graphical interface that replaces the Create Virtual Users button after virtual user creation."
}
vustatus {
putscli "vustatus - Usage: vustatus"
putscli "Show the status of virtual users. Status will be \"WAIT IDLE\" for virtual users that are created but not running a workload,\"RUNNING\" for virtual users that are running a workload, \"FINISH SUCCESS\" for virtual users that completed successfully or \"FINISH FAILED\" for virtual users that encountered an error." 
}
vucomplete {
putscli "vucomplete - Usage: vucomplete"
putscli "Returns \"true\" or \"false\" depending on whether all virtual users that started a workload have completed regardless of whether the status was \"FINISH SUCCESS\" or \"FINISH FAILED\"."
}
loadscript {
putscli "loadscript - Usage: loadscript"
putscli "Load the script for the database and benchmark set with dbset and the dictionary variables set with diset. Use \"print script\" to see the script that is loaded. Equivalent to loading a Driver Script in the Script Editor window in the graphical interface."
}
clearscript {
putscli "clearscript - Usage: clearscript"
putscli "Clears the script. Equivalent to the \"Clear the Screen\" button in the graphical interface." 
}
customscript {
putscli "customscript - Usage: customscript scriptname.tcl"
putscli "Load an external script. Equivalent to the \"Open Existing File\" button in the graphical interface."  
}
dgset {
putscli "dgset - Usage: dgset \[vu|ware|directory\]" 
putscli "Set the Datagen options. Equivalent to the Datagen Options dialog in the graphical interface."
}
datagenrun {
putscli "datagenrun - Usage: datagenrun"
putscli "Run Data Generation. Equivalent to the Generate option in the graphical interface."
}
runtimer {
putscli "runtimer - Usage: runtimer seconds"
putscli "Helper routine to run a timer in the main hammerdbcli thread to keep it busy for a period of time whilst the virtual users run a workload. The timer will return when vucomplete returns true or the timer reaches the seconds value. Usually followed by vudestroy."

}
waittocomplete {
putscli "waittocomplete - Usage: waittocomplete"
putscli "Helper routine to enable the main hammerdbcli thread to keep it busy until vucomplete is detected. When vucomplete is detected exit is called causing all virtual users and the main hammerdblci thread to terminate. Often used when calling hammerdb from external scripting commands."
}
tcset {
if $wsmode {
putscli "tcset - Usage: tcset refreshrate seconds"
	} else {
putscli "tcset - Usage: tcset \[refreshrate|logtotemp|unique|timestamps\]"
	}
putscli "Configure the transaction counter options. Equivalent to the Transaction Counter Options window in the graphical interface." 
}
tcstart {
putscli "tcstart - Usage: tcstart"
putscli "Starts the Transaction Counter."
}
tcstatus {
putscli "status - Usage: tcstatus"
putscli "Checks the status of the Transaction Counter."
}
tcstop {
putscli "tcstop - Usage: tcstop"
putscli "Stops the Transaction Counter."
}
}
}
}
}

proc helpws {} {
global ws_port
set res [rest::get http://localhost:$ws_port/help "" ]
putscli [ strip_html $res ]
}

proc wapp-page-help {} {
  set B [wapp-param BASE_URL]
  wapp-trim {
<html>
  <head>
    <meta content=\"text/html;charset=ISO-8859-1\" http-equiv=\"Content-Type\">
    <title>HammerDB Web Service</title>
    <h1>HammerDB Web Service</h1>
  </head>
  <body>
    <h2>HammerDB API</h2>
    <pre><b>GET db</b>: Show the configured database.
get http://localhost:8080/print?db / get http://localhost:8080/db
    <br>
<b>GET bm</b>: Show the configured benchmark.
get http://localhost:8080/print?bm / get http://localhost:8080/bm
{\"benchmark\": \"TPC-C\"}
    <br>
<b>GET dict</b>: Show the dictionary for the current database ie all active variables.
get http://localhost:8080/print?dict /  http://localhost:8080/dict
<br> 
<b>GET script</b>: Show the loaded script.
get http://localhost:8080/print?script / http://localhost:8080/script
<br> 
<b>GET vuconf</b>: Show the virtual user configuration.
get http://localhost:8080/print?vuconf / http://localhost:8080/vuconf
<br> 
<b>GET vucreate</b>: Create the virtual users. Equivalent to the Virtual User Create option in the graphical interface. Use vucreated to see the number created, vustatus to see the status and vucomplete to see whether all active virtual users have finished the workload. A script must be loaded before virtual users can be created.
get http://localhost:8080/vucreate
<br> 
<b>GET vucreated</b>: Show the number of virtual users created.
get http://localhost:8080/print?vucreated / get http://localhost:8080/vucreated
<br> 
<b>GET vustatus</b>: Show the status of virtual users, status will be \"WAIT IDLE\" for virtual users that are created but not running a workload,\"RUNNING\" for virtual users that are running a workload, \"FINISH SUCCESS\" for virtual users that completed successfully or \"FINISH FAILED\" for virtual users that encountered an error.
get http://localhost:8080/print?vustatus / get http://localhost:8080/vustatus
<br> 
<b>GET datagen</b>: Show the datagen configuration
get http://localhost:8080/print?datagen /  get http://localhost:8080/datagen
<br> 
<b>GET vucomplete</b>: Show if virtual users have completed. returns \"true\" or \"false\" depending on whether all virtual users that started a workload have completed regardless of whether the status was \"FINISH SUCCESS\" or \"FINISH FAILED\".
get http://localhost:8080/vucomplete
<br> 
<b>GET vudestroy</b>: Destroy the virtual users. Equivalent to the Destroy Virtual Users button in the graphical interface that replaces the Create Virtual Users button after virtual user creation.
get http://localhost:8080/vudestroy
<br> 
<b>GET loadscript</b>: Load the script for the database and benchmark set with dbset and the dictionary variables set with diset. Use print?script to see the script that is loaded. Equivalent to loading a Driver Script in the Script Editor window in the graphical interface. Driver script must be set to timed for the script to be loaded. Test scripts should be run in the GUI environment.  
get http://localhost:8080/loadscript
<br> 
<b>GET clearscript</b>: Clears the script. Equivalent to the \"Clear the Screen\" button in the graphical interface.
get http://localhost:8080/clearscript
<br> 
<b>GET vurun</b>: Send the loaded script to the created virtual users for execution. Equivalent to the Run command in the graphical interface. Creates a job id associated with all output. 
get http://localhost:8080/vurun
<br>
<b>GET buildschema</b>: Runs the schema build for the database and benchmark selected with dbset and variables selected with diset. Equivalent to the Build command in the graphical interface. Creates a job id associated with all output. 
get http://localhost:8080/buildschema
<br>
<b>GET jobs</b>: Show the job ids, configuration, output, status, results and timings of jobs created by buildschema and vurun. Job output is equivalent to the output viewed in the graphical interface or command line.
get http://localhost:8080/jobs
get http://localhost:8080/jobs?jobid=TEXT
get http://localhost:8080/jobs?jobid=TEXT&bm
get http://localhost:8080/jobs?jobid=TEXT&db
get http://localhost:8080/jobs?jobid=TEXT&delete
get http://localhost:8080/jobs?jobid=TEXT&dict
get http://localhost:8080/jobs?jobid=TEXT&result
get http://localhost:8080/jobs?jobid=TEXT&status
get http://localhost:8080/jobs?jobid=TEXT&tcount
get http://localhost:8080/jobs?jobid=TEXT&amp;timestamp
get http://localhost:8080/jobs?jobid=TEXT&timing
get http://localhost:8080/jobs?jobid=TEXT&timing&vuid=INTEGER
get http://localhost:8080/jobs?jobid=TEXT&vu=INTEGER
<br>
<b>GET librarycheck</b>: Attempts to load the vendor provided 3rd party library for all databases and reports whether the attempt was successful.
get http://localhost:8080/librarycheck
<br>
<b>GET tcstart</b>: Starts the Transaction Counter. 
get http://localhost:8080/tcstart
<br>
<b>GET tcstop</b>: Stops the Transaction Counter. 
get http://localhost:8080/tcstop
<br>
<b>GET tcstatus</b>: Checks the status of the Transaction Counter. 
get http://localhost:8080/tcstatus
<br>
<b>GET quit</b>: Terminates the webservice and reports message to the console.
get http://localhost:8080/quit
<br>
<b>POST dbset</b>: Usage: dbset \[db|bm\] value. Sets the database (db) or benchmark (bm). Equivalent to the Benchmark Menu in the graphical interface. Database value is set by the database prefix in the XML configuration.
post http://localhost:8080/dbset { \"db\": \"ora\" }
<br>
<b>POST diset</b>: Usage: diset dict key value. Set the dictionary variables for the current database. Equivalent to the Schema Build and Driver Options windows in the graphical interface. Use print?dict to see what these variables are and diset to change.
post http://localhost:8080/diset { \"dict\": \"tpcc\", \"key\": \"duration\", \"value\": \"1\" }
<br>
<b>POST vuset</b>: Usage: vuset \[vu|delay|repeat|iterations|showoutput|logtotemp|unique|nobuff|timestamps\]. Configure the virtual user options. Equivalent to the Virtual User Options window in the graphical interface.
post http://localhost:8080/vuset { \"vu\": \"4\" }
<br>
<b>POST tcset</b>: Usage: tcset \[refreshrate\] 
post http://localhost:8080/tcset { \"refreshrate\": \"20\" }
<br>
<b>POST dgset</b>: Usage: dgset \[vu|ware|directory\]. Set the Datagen options. Equivalent to the Datagen Options dialog in the graphical interface.
post http://localhost:8080/dgset { \"directory\": \"/home/oracle\" }
<br>
<b>POST customscript</b>: Load an external script. Equivalent to the \"Open Existing File\" button in the graphical interface. Script must be converted to JSON format before post.
post http://localhost:8080/customscript { \"script\": \"customscript\"}
  </body>
</html>
}}
