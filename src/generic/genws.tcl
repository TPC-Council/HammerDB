proc putscli { output } {
#Suppress output in the Web Service
#Uncomment to debug
#    puts $output
#    TclReadLine::print "\r"
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
  padding-top: 20px;
  background-color: #f9f9f9;
  font-family: 'Roboto', sans-serif;
  font-size: 14px;
  color: #333;
  line-height: 1.6;
}

td.status {
  text-align: center;
  vertical-align: middle;
}
td.status img {
  display: block;
  margin: 0 auto;
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
  max-width: 980px;
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

@media print {
  .no-print {
    display: none !important;
  }

  .print-page-break {
    break-before: page;
    page-break-before: always;
  }

  .print-avoid-break {
    break-inside: avoid;
    page-break-inside: avoid;
  }
}
.aut-wrap {
  max-width: 980px;
}
.aut-wrap table {
  max-width: 100%;
  margin: 1em 0;
}

/* Shared CI/job page layout.  Keep widths tied together so tables and buttons align. */
.hdb-page {
  max-width: 1180px;
  margin: 0 16px 40px 16px;
}

.hdb-section {
  max-width: 980px;
  margin: 0 0 24px 0;
}

.hdb-table-wrap {
  width: 100%;
  max-width: 980px;
  overflow-x: auto;
  margin: 0 0 14px 0;
}

.hdb-table-wrap table,
table.hdb-table {
  width: 100%;
  max-width: none !important;
  min-width: 760px;
  margin: 1em 0;
}

.hdb-form {
  width: 100%;
  max-width: 980px;
  margin: 0 0 18px 0;
}

.hdb-form-narrow {
  width: 100%;
  max-width: 980px;
  margin: 0 0 18px 0;
}

.hdb-actions {
  width: 100%;
  max-width: 980px;
  text-align: right;
  margin: 8px 0 18px 0;
}

.hdb-actions-left {
  width: 100%;
  max-width: 980px;
  text-align: left;
  margin: 14px 0 22px 0;
}

.hdb-activity {
  width: 100%;
  max-width: 980px;
  margin: 18px 0 20px 0;
  border-radius: 6px;
  background: #eef6ff;
  border: 1px solid #d0d7de;
  box-sizing: border-box;
}

.hdb-log-box {
  margin: 0;
  padding: 12px;
  height: 320px;
  overflow: auto;
  background: #eef6ff;
  color: #0a3d62;
  border: 1px solid #d0d7de;
  border-radius: 6px;
  font-family: monospace;
  font-size: 13px;
  line-height: 1.35;
  white-space: pre-wrap;
  box-sizing: border-box;
}

.hdb-jump-inline {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
  margin-left: 4px;
  font-size: 0.82em;
  opacity: 0.82;
}

.hdb-jump-inline a {
  text-decoration: none;
  white-space: nowrap;
}

.hdb-jump-inline a:hover {
  text-decoration: underline;
}

@media (max-width: 760px) {
  .hdb-page {
    margin: 0 8px 32px 8px;
  }
  .hdb-table-wrap table,
  table.hdb-table {
    min-width: 680px;
  }
  .hdb-actions,
  .hdb-actions-left {
    text-align: left;
  }
  .hdb-jump-inline {
    width: 100%;
    margin-left: 0;
    margin-top: 4px;
    line-height: 1.7;
  }
}

.aut-banner {
  width: 100%;
  box-sizing: border-box;
}
}
}

# ----------------------------
# CI WAPP page (HTML-only field display, stable + wrap + correct dict pretty)
# ----------------------------

# Fallback if is-dict not available
if {[info commands is-dict] eq ""} {
    proc is-dict {d} { expr {![catch {dict size $d}]} }
}

proc normalize_pre_text {s} {
    # CRLF/CR -> LF
    regsub -all {\r\n} $s "\n" s
    regsub -all {\r}   $s "\n" s

    # Expand literal escapes if present
    if {![string match "*\n*" $s] && [string match "*\\n*" $s]} {
        regsub -all {\\n} $s "\n" s
        regsub -all {\\t} $s "\t" s
    }

    return $s
}

proc split_cmake_records {s} {
    # 0) If there's no obvious CMake status marker, don't touch it
    #    (prevents wrecking non-cmake output)
    if {![string match "*-- *" $s]} {
        return $s
    }

    # 1) Fix glued percentage tokens: "done[ 2%]" -> "done\n[ 2%]"
    regsub -all {([^\n])(\[[ \t]*[0-9]+%])} $s "\\1\n\\2" s

    # 2) Fix glued cmake status lines:
    #    "...GNU 13.3.0-- The CXX ..." -> "...GNU 13.3.0\n-- The CXX ..."
    #    Only split on "-- " (cmake style), not every "--".
    regsub -all {([^\n])--[ \t]+} $s "\\1\n-- " s

    # 3) Clean up accidental leading newline
    if {[string match "\n-- *" $s]} {
        set s [string range $s 1 end]
    }

    return $s
}

# Heuristic: a "real" nested dict must have dict-size AND "sane" keys.
# Prevents command-lists like {git log -1 --pretty=%B} being mis-read as dicts.
proc is_real_nested_dict {x} {
    if {[catch {dict size $x}]} { return 0 }
    foreach k [dict keys $x] {
        # accept typical dict keys: letters/underscore then letters/digits/underscore
        if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $k]} { return 0 }
    }
    return 1
}

# Quote a scalar value so "anything with spaces" stays together as { ... } on one line.
proc tcl_quote_value {v} {
    # If value contains whitespace or Tcl-special separators, brace it.
    if {[regexp {\s|[{};"\[\]]} $v]} {
        # Avoid double-bracing if it's already a single braced group representation
        return "{${v}}"
    }
    return $v
}

# Pretty print Tcl dicts in Tcl-dict style (preserves "key {value with spaces}" on one line,
# and nests dicts as "key { ... }").
proc pretty_tcl_dict {d {indent 0}} {
    if {![is_real_nested_dict $d]} {
        return $d
    }

    set pad [string repeat "  " $indent]
    set out ""

    dict for {k v} $d {
        if {[is_real_nested_dict $v]} {
            append out "${pad}$k {\n"
            append out [pretty_tcl_dict $v [expr {$indent+1}]]
            append out "${pad}}\n"
        } else {
            append out "${pad}$k [tcl_quote_value $v]\n"
        }
    }
    return $out
}

proc getcirow_id {ci_id} {
    set ci [dict create]
    if {[catch {
        hdbjobs eval {SELECT
            ci_id, refname, pipeline,
            io_intensive, profile_id,
            clone_cmd, clone_output,
            build_cmd, build_output,
            install_cmd, install_output,
            package_cmd, commit_msg,
            config_file, start_cmd,
            status, timestamp, end_timestamp,
            cidict
        FROM JOBCI
        WHERE ci_id=$ci_id} r {
            foreach k [array names r] { dict set ci $k $r($k) }
            break
        }
    } err]} {
        return [list error "Error querying JOBCI: $err"]
    }
    if {[dict size $ci] == 0} {
        return [list error "CI run not found for ci_id $ci_id"]
    }
    return $ci
}

proc getcirow {refname} {
    set ci [dict create]
    if {[catch {
        hdbjobs eval {SELECT
            ci_id, refname, pipeline, io_intensive, 
            profile_id, clone_cmd, clone_output,
            build_cmd, build_output,
            install_cmd, install_output,
            package_cmd, commit_msg,
            config_file, start_cmd,
            status, timestamp, end_timestamp,
            cidict
        FROM JOBCI
        WHERE refname=$refname
        ORDER BY ci_id DESC
        LIMIT 1} r {
            foreach k [array names r] { dict set ci $k $r($k) }
            break
        }
    } err]} {
        return [list error "Error querying JOBCI: $err"]
    }
    if {[dict size $ci] == 0} {
        return [list error "CI refname not found: $refname"]
    }
    return $ci
}

proc wapp-page-ci {} {
    wapp-allow-xorigin-params
    set B [wapp-param BASE_URL]

    # parse query
    set query [wapp-param QUERY_STRING]
    set params [split $query &]
    set paramdict [dict create]
    foreach a $params {
        if {$a eq ""} continue
        lassign [split $a =] k v
        dict set paramdict $k $v
    }
    # need ci_id or refname
    if {![dict exists $paramdict ci_id] && ![dict exists $paramdict refname]} {
        wapp-subst {<p>Usage: ci?ci_id=INTEGER | ci?refname=TEXT</p>}
        return
    }

    # resolve CI row
    if {[dict exists $paramdict ci_id]} {
        set ci_id [dict get $paramdict ci_id]
        set ci [getcirow_id $ci_id]
    } else {
        set refname [dict get $paramdict refname]
        set ci [getcirow $refname]
        if {[is-dict $ci]} { set ci_id [dict get $ci ci_id] }
    }

    if {![is-dict $ci]} {
        wapp-subst {<p>%html([lindex $ci 1])</p>}
        return
    }

    set refname [dict get $ci refname]

    # HTML header
    wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
    wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
    wapp-subst {<p><img src='%html($B)/logo.png' width='55' height='60'></p>}
    wapp-subst {<h3 class="title">CI:%html($refname)</h3>}

    # if no index -> overview page
    if {![dict exists $paramdict index]} {

        # Human-readable labels for CI fields
        set field_labels [dict create \
            summary        "Summary" \
            status         "Status" \
            timestamp      "Start time" \
            end_timestamp  "End time" \
            commit_msg     "Commit message" \
            clone_cmd      "Clone command" \
            clone_output   "Clone output" \
            build_cmd      "Build command" \
            build_output   "Build output" \
            install_cmd    "Install command" \
            install_output "Install output" \
            package_cmd    "Package command" \
            config_file    "Config file" \
            start_cmd      "Start command" \
            cidict         "CI dictionary" \
        ]

        set fields {
            summary
            status
            timestamp
            end_timestamp
            commit_msg
            clone_cmd
            clone_output
            build_cmd
            build_output
            install_cmd
            install_output
            package_cmd
            config_file
            start_cmd
            cidict
        }

        wapp-subst {<ol style="margin:0; padding-left:1.5em;">\n}
        foreach f $fields {
            set url "$B/ci?ci_id=$ci_id&index=$f"
            set label [dict get $field_labels $f]
            wapp-subst {<li style="margin:0; padding:0;"><a href='%html($url)'>%html($label)</a></li>\n}
        }
        wapp-subst {</ol>\n}

        # Performance profile
        set pid ""
        if {[dict exists $ci profile_id]} {
            set pid [string trim [dict get $ci profile_id]]
        }
        if {$pid ne "" && $pid != 0} {
            set purl "$B/jobs?profileid=$pid"
            wapp-subst {<p style="margin:12px 0 0 0;"><b>Performance Profile</b></p>\n}
            wapp-subst {<p style="margin:0;"><a href='%html($purl)'>Profile %html($pid)</a></p>\n}
        }

        # Jobs between CI start/end
        set start_ts [dict get $ci timestamp]
        set end_ts   [dict get $ci end_timestamp]
        if {$end_ts eq ""} { set end_ts $start_ts }

        wapp-subst {<p style="margin:14px 0 0 0;"><b>Jobs between CI start/end</b></p>\n}
        wapp-subst {<p style="margin:0 0 8px 0;">%html($start_ts) → %html($end_ts)</p>\n}

        wapp-subst {<ol style="margin:0; padding-left:1.5em;">\n}
        hdbjobs eval {
            SELECT jobid
            FROM JOBMAIN
            WHERE timestamp >= $start_ts
              AND timestamp <= $end_ts
            ORDER BY timestamp ASC
        } {
            set jurl "$B/jobs?jobid=$jobid&index=output"
            wapp-subst {<li style="margin:0; padding:0;"><a href='%html($jurl)'>%html($jobid)</a></li>\n}
        }
        wapp-subst {</ol>\n}

        wapp-subst {<p style="margin-top:14px;"><a href='%html($B)/'>Job Index</a></p>\n}
        return
    }

    # ----------------------------
    # Field display page
    # ----------------------------
    set field [dict get $paramdict index]

    set allowed {
        summary status timestamp end_timestamp commit_msg
        clone_cmd clone_output
        build_cmd build_output
        install_cmd install_output
        package_cmd config_file
        start_cmd cidict
    }

    if {[lsearch -exact $allowed $field] < 0} {
        wapp-subst {<p>Unknown CI field.</p>}
        return
    }

    set back "$B/ci?ci_id=$ci_id"
    wapp-subst {<p style="margin:0 0 10px 0;"><a href='%html($back)'>Back</a></p>\n}
    wapp-subst {<h4>%html($field)</h4>\n}

    # summary is short
    if {$field eq "summary"} {
        wapp-subst {<pre style="white-space:pre-wrap; overflow-wrap:anywhere;">}
        foreach k {ci_id refname pipeline io_intensive profile_id status timestamp end_timestamp} {
            if {[dict exists $ci $k]} {
                set v [dict get $ci $k]
            } else {
                set v ""
            }
            if {(($k eq "end_timestamp") || ($k eq "profile_id")) && $v eq ""} {
                if {$k eq "profile_id"} {
                    set v "0"
                    wapp-subst "%html($k): %html($v)\n"
                } else {
                    wapp-subst "%html($k):\n"
                }
            } else {
                wapp-subst "%html($k): %html($v)\n"
            }
        }
        wapp-subst {</pre>}
        return
    }

    if {[dict exists $ci $field]} {
        set val [dict get $ci $field]
    } else {
        set val ""
    }

    if {$val eq ""} {
        wapp-subst {<p><i>(empty)</i></p>}
        return
    }

    # Normalise line endings first
    if {$field in {clone_output build_output install_output}} {
        set val [normalize_pre_text $val]
    }

    # Only build_output: split glued CMake records
    if {$field eq "build_output"} {
        set val [split_cmake_records $val]
    }

    # Pretty print cidict (3+ level dict) in Tcl-dict style
    if {$field eq "cidict"} {
        set val [pretty_tcl_dict $val]
    }

    # truncate long outputs
    set max 2000000
    if {[string length $val] > $max} {
        wapp-subst {<p><i>Showing first %html($max) bytes of %html([string length $val]).</i></p>\n}
        set val [string range $val 0 [expr {$max-1}]]
    }

    # IMPORTANT: wrap long lines in <pre>
    wapp-subst {<pre style="white-space:pre-wrap; overflow-wrap:anywhere;">%html($val)</pre>}
    return
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
