proc putscli { output } {
    puts $output
    TclReadLine::print "\r"
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
    #escape backslashes in output to prevent JSON parse errors
    set dict2json [ regsub -all {\\} $dict2json {\\\\} ]
    if { $dfields == 2 } {
        set huddleobj [ huddle compile {dict * dict} $dict2json ]
    } else {
        set huddleobj [ huddle compile {dict} $dict2json ]
    }
    wapp-mimetype application/json
    wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
}

proc wapp-default {} {
wapp-page-jobs
}

proc strip_html { htmlText } {
    regsub -all {<[^>]+>} $htmlText "" newText
    return $newText
}

proc env {} {
    global ws_port
    if [ catch {set tok [http::geturl http://localhost:$ws_port/env]} message ] {
        putscli $message
    } else {
        putscli [ strip_html [ http::data $tok ] ]
    }
    if { [ info exists tok ] } { http::cleanup $tok }
}

proc wapp-page-env {} {
    wapp-allow-xorigin-params
    wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
    wapp-trim {
        <h1>Service Environment</h1>\n<pre>
        <pre>%html([wapp-debug-env])</pre>
    }
}


proc wapp-page-style.css {} {
    wapp-mimetype text/css
    wapp-allow-xorigin-params
    wapp-subst {
  body {
  margin: 0;
  padding: 0;
  padding-left: 20px;
  background-color: #f9f9f9;
  font-family: 'Roboto', sans-serif;
  font-size: 14px;
  color: #333;
  line-height: 1.6;
}

h1, h2, h3 {
  margin: 0 0 0.1em 0;
  font-family: 'Roboto', sans-serif;
  font-weight: 500;
  color: #222;
}

h1 {
  font-size: 2.5em;
}

h2 {
  font-size: 2em;
}

h3 {
  font-size: 1.5em;
}

p, ul, ol {
  margin: 0 0 1em 0;
}

ul, ol {
  padding-left: 1.5em;
  column-count: 1 !important;
  column-width: auto !important;
}

table {
  font-family: 'Roboto', sans-serif;
  font-size: 14px;
  color: #333;
  border-collapse: collapse;
  width: 100%;
  max-width: 800px;
  margin: 1em 0;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
}

td, th {
  border: 1px solid #ccc;
  text-align: left;
  padding: 10px;
}

th {
  background-color: #f0f0f0;
  font-weight: 600;
}

tr:nth-child(even) {
  background-color: #f9f9f9;
}
}
}

proc wapp-page-_dumpdb {} {
    set jmdump [ concat [ hdbjobs eval {SELECT * FROM JOBMAIN} ] ]]
    set jtdump [ concat [ hdbjobs eval {SELECT * FROM JOBTIMING} ]]
    set jcdump [ concat [ hdbjobs eval {SELECT * FROM JOBTCOUNT} ]]
    set jodump [ concat [ hdbjobs eval {SELECT * FROM JOBOUTPUT} ]]
    set jcdump [ concat [ hdbjobs eval {SELECT * FROM JOBCHART} ]]
    set joboutput [ list $jmdump $jtdump $jcdump $jodump $jcdump ]
    set huddleobj [ huddle compile {list} $joboutput ]
    wapp-mimetype application/json
    wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
}

proc get_ws_port {} {
 upvar #0 genericdict genericdict
    if {[dict exists $genericdict webservice ws_port ]} {
        set ws_port [ dict get $genericdict webservice ws_port ]
        if { ![string is integer -strict $ws_port ] } {
            putscli "Warning port not set to integer in config setting to default"
            set ws_port 8080
        }
    } else {
        putscli "Warning port not found in config setting to default"
        set ws_port 8080
    }
return $ws_port
}

proc quit {} {
    global ws_port
    if { ![info exists ws_port ] } {
        set ws_port [ get_ws_port ]
	}
    if [ catch {set tok [http::geturl http://localhost:$ws_port/quit]} message ] {
        putscli $message
    } else {
        putscli [ strip_html [ http::data $tok ] ]
    }
    if { [ info exists tok ] } { http::cleanup $tok }
}

proc wapp-page-quit {} {
    exit
}

rename jobs {}
interp alias {} jobs {} jobs_ws

proc start_webservice { args } {
    global ws_port
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict webservice ws_port ]} {
        set ws_port [ dict get $genericdict webservice ws_port ]
        if { ![string is integer -strict $ws_port ] } {
		if {$args != "gui" } {
            putscli "Warning port not set to integer in config setting to default"
    		}
            set ws_port 8080  
        }
    } else { 
		if {$args != "gui" } {
        putscli "Warning port not found in config setting to default"
		}
        set ws_port 8080  
    }
	init_job_tables_ws
		if {$args != "gui" } {
        putscli "Starting HammerDB Web Service on port $ws_port"
		}
switch $args {
"gui" {
        if [catch {wapp-start [ list --server $ws_port ]} message ] { }
}
"scgi" {
        if [catch {wapp-start [ list --scgi $ws_port ]} message ] { }
}
"wait" {
        if [catch {wapp-start [ list --server $ws_port ]} message ] {
            putscli "Error starting HammerDB webservice on port $ws_port in wait mode : $message"
        }
}
"nowait" {
        if [catch {wapp-start [ list --server $ws_port --nowait ]} message ] {
            putscli "Error starting HammerDB webservice on port $ws_port in nowait mode : $message"
}
}
}}
