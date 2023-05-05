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
    set res [rest::get http://localhost:$ws_port/env "" ]
    putscli [ strip_html $res ]
}

proc wapp-page-env {} {
    wapp-allow-xorigin-params
    wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
    wapp-trim {
        <h1>Service Environment</h1>\n<pre>
        <pre>%html([wapp-debug-env])</pre>
    }
}

proc wapp-page-style.css {} {
    wapp-allow-xorigin-params
    wapp-subst {
body {
  margin-top: 0px;
  margin-right: 0px;
  margin-bottom: 0px;
  margin-left: 0px;
  background-color: transparent;
  background-repeat: repeat-x;
  background-attachment: scroll;
  background-position: left top;
  font-family: Roboto, sans-serif;
  font-size: 12px;
  color: #444444;
}
h1, h2, h3 {
  margin-top: 0px;
  margin-right: 0px;
  margin-bottom: 0px;
  margin-left: 0px;
  font-family: Roboto, sans-serif;
  font-weight: normal;
  color: #444444;
}
h1 {
  font-size: 2em;
}
h2 {
  font-size: 2em;
}
h3 {
  font-size: 1.6em;
}
p, ul, ol {
  margin-top: 0px;
  line-height: 125%;
}
table {
  font-family: Roboto, sans-serif;
  font-size: 12px;
  color: #444444;
  border-collapse: collapse;
  width: 50%;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 2px;
}

tr:nth-child(even) {
  background-color: #dddddd;
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

rename jobs {}
interp alias {} jobs {} jobs_ws

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
        tsv::set webservice wsport $ws_port
	init_job_tables
        puts "Starting HammerDB Web Service on port $ws_port"
        if [catch {wapp-start [ list --server $ws_port $args ]} message ] {
            puts "Error starting HammerDB webservice on port $ws_port : $message"
        } else {
            #Readline::interactws called from main script
        }
}
