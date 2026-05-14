# pipelines-1.0.tm
package provide pipelines 1.0

namespace eval pipelines {
    namespace export wapp-page-pipelines

    proc __is_sha1 {s} {
        expr {[regexp {^[0-9a-fA-F]{7,40}$} [string trim $s]]}
    }

    proc __norm_pre {s} {
        regsub -all {\r\n} $s "\n" s
        regsub -all {\r}   $s "\n" s
        return $s
    }

    proc __db_label {dbprefix} {
        set dbprefix [string tolower [string trim $dbprefix]]
        switch -exact -- $dbprefix {
            maria  { return "MariaDB" }
            pg     { return "PostgreSQL" }
            mysql  { return "MySQL" }
            ora    { return "Oracle" }
            mssqls { return "SQL Server" }
            db2    { return "Db2" }
            default { return $dbprefix }
        }
    }

    proc __dbprefix_to_cidict_key {dbprefix} {
        set dbprefix [string tolower [string trim $dbprefix]]
        switch -exact -- $dbprefix {
            maria { return "MariaDB" }
            pg    { return "PostgreSQL" }
            mysql { return "MySQL" }
            default { return "" }
        }
    }

    proc ci_pipeline_label {p} {
        set p [string tolower [string trim $p]]
        switch -exact -- $p {
            single_c { return "Single" }
            single_h { return "Single" }
            profile  { return "Profile" }
            compare  { return "Compare" }
            default  { return $p }
        }
    }

    proc __auto_refresh_js {{ms 120000}} {
        # auto-refresh
        # cache-buster
        set ms [string trim $ms]
        if {![string is integer -strict $ms] || $ms < 2000} { set ms 15000 }

        wapp-subst "<script>\n"
        wapp-subst "(function(){\n"
        wapp-subst "  var REFRESH_MS = $ms;\n"
        wapp-subst "  setInterval(function(){\n"
        wapp-subst "    var base = window.location.pathname + window.location.search;\n"
        wapp-subst {    base = base.replace(/([?&])_r=\\d+/, '$1').replace(/(\\?|&)$/, '');\n}
        wapp-subst {    var sep = (base.indexOf('?') >= 0) ? '&' : '?';\n}
        wapp-subst {    var url = base + sep + '_r=' + Date.now() + window.location.hash;\n}
        wapp-subst "    window.location.replace(url);\n"
        wapp-subst "  }, REFRESH_MS);\n"
        wapp-subst "})();\n"
        wapp-subst "</script>\n"
     }

    proc __page_head {B title} {
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        wapp-subst {<p><img src='%html($B)/logo.png' width='55' height='60'></p>}

        # button from title
        set btn_label ""
        set btn_url ""

        if {$title eq "HammerDB Jobs"} {
            set btn_label "Pipelines"
            set btn_url "$B/pipelines"
        } elseif {$title eq "HammerDB Pipelines"} {
            set btn_label "Jobs"
            set btn_url "$B/jobs"
        }

        # header
        if {$btn_label ne ""} {
            wapp-subst {
<div style="margin:0 16px 18px 16px; padding-bottom:8px; border-bottom:1px solid #ddd;">
    <div style="display:flex; justify-content:flex-start; align-items:center; gap:12px;">
        <h3 class="title" style="margin:0;">%html($title)</h3>
        <a href="%html($btn_url)"
           style="margin-top:2px;
                  padding:6px 14px;
                  border:1px solid #bbb;
                  border-radius:4px;
                  text-decoration:none;
                  font-weight:500;">
            %html($btn_label)
        </a>
    </div>
</div>
}
        } else {
            wapp-subst "<h3 class='title'>%html($title)</h3>\n"
        }

        # page styles
        wapp-subst {
<style>
.aut-wrap{max-width:980px;}
.aut-form{max-width:720px;}
.aut-ctl{width:100%; box-sizing:border-box; min-width:0;}
.aut-row{margin-top:8px;}
.aut-actions{margin-top:14px;}
.aut-btn{padding:6px 14px;}
.aut-banner{border:1px solid #ddd; padding:10px 12px; border-radius:6px; margin:10px 0 14px 0;}
.aut-ok{background:#e7f6ea; border-color:#7ac189; color:#155724;}
.aut-fail{background:#fdeaea; border-color:#e18b8b; color:#721c24;}
.aut-mini{opacity:0.75; font-size:0.95em;}
.aut-details{margin-top:8px;}
.aut-details summary{cursor:pointer; font-weight:600;}
.aut-kv{margin:0; padding:0;}
.aut-kv b{display:inline-block; min-width:90px;}
</style>
}
        wapp-subst "\n"
    }

    proc __page_tail {} {
        # layout closed by app
    }

proc __get_ci_build_config {dbprefix} {
        upvar #0 cidict cidict
        if {![info exists cidict]} {
            set cidict [SQLite2Dict "ci"]
        }
        set key [__dbprefix_to_cidict_key $dbprefix]

        set repo_url ""
        set ref_regexp ""
        set listen_port ""

        if {$key ne ""} {
            if {[dict exists $cidict $key build repo_url]} {
                set repo_url [dict get $cidict $key build repo_url]
            } 
            if {[dict exists $cidict $key build ref_regexp]} {
                set ref_regexp [dict get $cidict $key build ref_regexp]
            }
        }

        if {[dict exists $cidict common listen_port]} {
            set listen_port [dict get $cidict common listen_port]
        }

        if {$listen_port eq ""} { set listen_port 5000 }
        set cilisten_url "http://127.0.0.1:$listen_port"

        return [dict create repo_url $repo_url ref_regexp $ref_regexp cilisten_url $cilisten_url]
    }

    variable __tag_cache_ts
    variable __tag_cache_list

    proc __repo_to_owner_repo {repo_url} {
        set u [string trim $repo_url]
        regsub {\.git$} $u "" u
        if {[regexp {github\.com/([^/]+)/([^/]+)$} $u -> owner repo]} {
            return "$owner/$repo"
        }
        return ""
    }

    proc __http_get {url} {
        if {[catch {package require http}]} {
            return [dict create ok 0 code 0 body "" err "http package missing"]
        }
        set headers [list User-Agent HammerDB-Pipelines]
        set code 0
        set body ""
        set err ""
        if {[catch {
            set tok [http::geturl $url -method GET -headers $headers -timeout 8000]
            set code [http::ncode $tok]
            set body [http::data $tok]
            http::cleanup $tok
        } e]} {
            set err $e
        }
        set ok 0
        if {$err eq "" && $code >= 200 && $code < 300} { set ok 1 }
        return [dict create ok $ok code $code body $body err $err]
    }

proc __github_tags {repo_url} {
        variable __tag_cache_ts
        variable __tag_cache_list

        if {![info exists __tag_cache_ts]} { set __tag_cache_ts [dict create] }
        if {![info exists __tag_cache_list]} { set __tag_cache_list [dict create] }

        set repo_url [string trim $repo_url]
        if {$repo_url eq ""} { return {} }

        # cache by repo_url
        set key $repo_url

        set now [clock seconds]
        if {[dict exists $__tag_cache_ts $key]} {
            set ts [dict get $__tag_cache_ts $key]
            if {$ts > 0 && ($now - $ts) < 300 && [dict exists $__tag_cache_list $key]} {
                return [dict get $__tag_cache_list $key]
            }
        }

        # fetch tags via git
        set out ""
        if {[catch { set out [exec git ls-remote --tags --refs $repo_url] } err]} {
            return {}
        }

        set tags {}
        foreach line [split $out "\n"] {
            # <sha>\trefs/tags/<tagname>
            if {[regexp {\trefs/tags/(.+)$} $line -> t]} {
                lappend tags $t
            }
        }

        # filter rules
        # MariaDB: mariadb-12.* mariadb-11.*
        # PostgreSQL: REL_*
        # MySQL: mysql-*
        set filtered {}
        if {[string match "*github.com/MariaDB/server*" $repo_url]} {
            foreach t $tags {
                if {[regexp {^mariadb-(1[012])\..+} $t]} {
                    lappend filtered $t
                }
            }
        } elseif {[string match "*github.com/postgres/postgres*" $repo_url]} {
            foreach t $tags {
                if {[string match "REL_*" $t]} {
                    lappend filtered $t
                }
            }
        } elseif {[string match "*github.com/mysql/mysql-server*" $repo_url]} {
            foreach t $tags {
                if {[string match "mysql-*" $t]} {
                    lappend filtered $t
                }
            }
        } else {
            # unknown repo: no filter
            set filtered $tags
        }

        # dedupe preserve order
        array set seen {}
        set uniq {}
        foreach t $filtered {
            if {![info exists seen($t)]} {
                set seen($t) 1
                lappend uniq $t
            }
        }

        # sort newest first
        set sorted $uniq

        if {[string match "*github.com/MariaDB/server*" $repo_url]} {
            # mariadb-12.2.1 => {12 2 1}
            proc ::pipelines::__ver_mariadb {t} {
                if {![regexp {^mariadb-([0-9]+)\.([0-9]+)\.([0-9]+)} $t -> a b c]} { return {0 0 0} }
                return [list $a $b $c]
            }
            set sorted [lsort -command {apply {{x y} {
                set vx [::pipelines::__ver_mariadb $x]
                set vy [::pipelines::__ver_mariadb $y]
                # descending
                if {[lindex $vx 0] != [lindex $vy 0]} { return [expr {[lindex $vy 0] - [lindex $vx 0]}] }
                if {[lindex $vx 1] != [lindex $vy 1]} { return [expr {[lindex $vy 1] - [lindex $vx 1]}] }
                return [expr {[lindex $vy 2] - [lindex $vx 2]}]
            }} } $sorted]
        } elseif {[string match "*github.com/postgres/postgres*" $repo_url]} {
            # REL_16_2 => {16 2}
            proc ::pipelines::__ver_pg {t} {
                if {![regexp {^REL_([0-9]+)_([0-9]+)$} $t -> a b]} { return {0 0} }
                return [list $a $b]
            }
            set sorted [lsort -command {apply {{x y} {
                set vx [::pipelines::__ver_pg $x]
                set vy [::pipelines::__ver_pg $y]
                if {[lindex $vx 0] != [lindex $vy 0]} { return [expr {[lindex $vy 0] - [lindex $vx 0]}] }
                return [expr {[lindex $vy 1] - [lindex $vx 1]}]
            }} } $sorted]
        } elseif {[string match "*github.com/mysql/mysql-server*" $repo_url]} {
            # mysql-8.0.36 => {8 0 36}
            proc ::pipelines::__ver_mysql {t} {
                if {![regexp {^mysql-([0-9]+)\.([0-9]+)\.([0-9]+)} $t -> a b c]} { return {0 0 0} }
                return [list $a $b $c]
            }
            set sorted [lsort -command {apply {{x y} {
                set vx [::pipelines::__ver_mysql $x]
                set vy [::pipelines::__ver_mysql $y]
                if {[lindex $vx 0] != [lindex $vy 0]} { return [expr {[lindex $vy 0] - [lindex $vx 0]}] }
                if {[lindex $vx 1] != [lindex $vy 1]} { return [expr {[lindex $vy 1] - [lindex $vx 1]}] }
                return [expr {[lindex $vy 2] - [lindex $vx 2]}]
            }} } $sorted]
        }

        # cap list size
        if {[llength $sorted] > 60} {
            set sorted [lrange $sorted 0 59]
        }

        dict set __tag_cache_ts $key $now
        dict set __tag_cache_list $key $sorted
        return $sorted
}
    variable __last_ok 0
    variable __last_code 0
    variable __last_msg ""
    variable __last_payload ""
    variable __last_body ""
    variable __last_err ""

    proc __store_last {ok code msg payload body err} {
        variable __last_ok
        variable __last_code
        variable __last_msg
        variable __last_payload
        variable __last_body
        variable __last_err

        set __last_ok $ok
        set __last_code $code
        set __last_msg $msg
        set __last_payload $payload
        set __last_body $body
        set __last_err $err
    }

proc __render_last_if_any {} {
        variable __last_ok
        variable __last_code 
        variable __last_msg
        variable __last_payload
        variable __last_body
        variable __last_err

        if {$__last_msg eq ""} { return }
    
        set cls "aut-banner"
        if {$__last_ok} { append cls " aut-ok" } else { append cls " aut-fail" }

        # safe <pre>
        proc __pre_safe {s} {
            set s [__norm_pre $s]
            regsub -all {&} $s {\&amp;} s
            regsub -all {<} $s {\&lt;}  s
            regsub -all {>} $s {\&gt;}  s
            return "<pre>$s</pre>"
        }

        wapp-subst "<div class='%html($cls)' id='runresult'>"
        wapp-subst "<b>%html($__last_msg)</b>"
if {!$__last_ok && [string match "*connection refused*" $__last_err]} {
    wapp-subst "<div class='aut-mini' style='margin-top:6px;'>Start the listener: <code>hammerdbcli</code> → <code>cilisten maria</code></div>"
} elseif {!$__last_ok && [string match "*connect failed*" $__last_err]} {
    wapp-subst "<div class='aut-mini' style='margin-top:6px;'>Start the listener: <code>hammerdbcli</code> → <code>cilisten maria</code></div>"
} elseif {!$__last_ok && ([string match "*pipeline already*" [string tolower $__last_msg]] || [string match "*pipeline is already*" [string tolower $__last_err]])} {
    set reset_url "[wapp-param BASE_URL]/jobs?cireset=1"
    wapp-subst "<div class='aut-mini' style='margin-top:8px;'><a href='%html($reset_url)'>Clear blocked CI pipeline</a></div>"
}
        if {$__last_code ne 0} {
            wapp-subst " <span class='aut-mini'>(HTTP %html($__last_code))</span>"
        }

        if {$__last_err ne "" || $__last_payload ne "" || $__last_body ne ""} {
    wapp-subst {<details class="aut-details">}
    wapp-subst {<summary>Webhook details</summary>}
    if {$__last_payload ne ""} {
        wapp-subst {<div class="aut-mini" style="margin-top:6px;"><b>Request</b></div>}
        wapp-unsafe [__pre_safe $__last_payload]
    }
    if {$__last_body ne ""} {
        wapp-subst {<div class="aut-mini" style="margin-top:6px;"><b>Response</b></div>}
        wapp-unsafe [__pre_safe $__last_body]
    }
    if {$__last_err ne ""} {
        wapp-subst {<div class="aut-mini" style="margin-top:6px;"><b>Error</b></div>}
        wapp-unsafe [__pre_safe $__last_err]
    }
    wapp-subst {</details>}
}

        wapp-subst {</div>}
    }

    proc __post_json {url json_body} {
        if {[catch {package require http}]} {
            return [dict create ok 0 code 0 body "" err "http package missing"]
        }
        set headers [list Content-Type application/json Accept application/json User-Agent HammerDB-Pipelines]
        set code 0
        set body ""
        set err ""
        if {[catch {
            set tok [http::geturl $url -method POST -headers $headers -query $json_body -timeout 20000]
            set code [http::ncode $tok]
            set body [http::data $tok]
            http::cleanup $tok
        } e]} {
            set err $e
        }
        set ok 0
        if {$err eq "" && $code >= 200 && $code < 300} { set ok 1 }
        return [dict create ok $ok code $code body $body err $err]
    }

    proc __url_encode {s} {
        # URL encode
        set out ""
        set bytes [encoding convertto utf-8 $s]
        binary scan $bytes c* codes
        foreach c $codes {
            set c [expr {($c+256)%256}]
            if {($c>=0x30 && $c<=0x39) || ($c>=0x41 && $c<=0x5A) || ($c>=0x61 && $c<=0x7A) || $c==0x2D || $c==0x2E || $c==0x5F || $c==0x7E} {
                append out [format %c $c]
            } else {
                append out %[format %02X $c]
            }
        }
        return $out
    }
proc __url_encode {s} {
        # URL encode
        set out ""
        set bytes [encoding convertto utf-8 $s]
        binary scan $bytes c* codes
        foreach c $codes {
            set c [expr {($c+256)%256}]
            if {($c>=0x30 && $c<=0x39) || ($c>=0x41 && $c<=0x5A) || ($c>=0x61 && $c<=0x7A) || $c==0x2D || $c==0x2E || $c==0x5F || $c==0x7E} {
                append out [format %c $c]
            } else {
                append out %[format %02X $c]
            }
        }
        return $out
    }

    proc __url_decode {s} {
        # URL decode
        set s [string map {+ " "} $s]
        set out ""
        set i 0
        set n [string length $s]
        while {$i < $n} {
            set ch [string index $s $i]
            if {$ch eq "%" && $i+2 < $n} {
                set hx [string range $s [expr {$i+1}] [expr {$i+2}]]
                if {[regexp {^[0-9A-Fa-f]{2}$} $hx]} {
                    append out [binary format H2 $hx]
                    incr i 3
                    continue
                }
            }
            append out $ch
            incr i
        }
        # UTF-8 decode
        return [encoding convertfrom utf-8 $out]
    }

    proc __json_escape {s} {
        set s [string map {\\ \\\\ \" \\\" \n \\n \r \\r \t \\t} $s]
        return $s
    }

    proc __make_payload_json {ref dbprefix pipeline_ui workload_ui io_intensive} {
    set pl ""
    if {$pipeline_ui eq "single"} {
        if {$workload_ui eq "H"} {
            set pl "single_h"
        } else {
            set pl "single_c"
        }
    } elseif {$pipeline_ui eq "profile"} {
        set pl "profile"
    } else {
        set pl "compare"
    }

    # Normalize ref to match CI rules: refs/tags/... or refs/heads/... or SHA
    set ref [string trim $ref]
    if {$ref ne "" && ![regexp {^refs/(tags|heads)/} $ref]} {

        # Leave commit SHAs as-is (short or full)
        if {![regexp {^[0-9a-fA-F]{7,40}$} $ref]} {

            # Default to tag ref
            set ref "refs/tags/$ref"
        }
    }

    set io_flag [expr {$io_intensive eq "1" ? 1 : 0}]

    set j_ref [__json_escape [string trim $ref]]
    set j_db  [__json_escape [string tolower [string trim $dbprefix]]]
    set j_pl  [__json_escape $pl]
    set j_wl  [__json_escape [string toupper [string trim $workload_ui]]]

    return "{\"ref\":\"$j_ref\",\"database\":\"$j_db\",\"pipeline\":\"$j_pl\",\"workload\":\"$j_wl\",\"io_intensive\":$io_flag}"
    }

    proc _tail_ci_log_file {filename {maxbytes 65536}} {
        if {$filename eq "" || $filename eq "nologfile" || ![file exists $filename] || ![file readable $filename]} {
            return "No active pipeline log"
        }

        set fsize [file size $filename]
        if {$fsize < 0} {
            return "No active pipeline log"
        }

        set fh [open $filename r]
        fconfigure $fh -translation binary -encoding iso8859-1

        if {$fsize > $maxbytes} {
            seek $fh [expr {$fsize - $maxbytes}] start
        }

        set data [read $fh]
        close $fh

        return [encoding convertfrom utf-8 $data]
    }

    proc wapp-page-pipelines {} {
        set B [wapp-param BASE_URL]
        set xfproto [wapp-param HTTP_X_FORWARDED_PROTO]
        set xfhost  [wapp-param HTTP_X_FORWARDED_HOST]
        set host  [wapp-param HTTP_HOST]
        if {$xfproto ne ""} {
        if {$xfhost ne ""} {
           set B "$xfproto://$xfhost"
           } elseif {$host ne ""} {
          set B "$xfproto://$host"
          }
        }
	set windows_host [expr {$::tcl_platform(platform) eq "windows"}]

        # parse query
        set __qs [wapp-param QUERY_STRING]
        set __qsdict [dict create]
        if {$__qs ne ""} {
            foreach part [split $__qs &] {
                if {$part eq ""} continue
                set eq [string first "=" $part]
                if {$eq < 0} {
                    set k $part
                    set v ""
                } else {
                    set k [string range $part 0 [expr {$eq-1}]]
                    set v [string range $part [expr {$eq+1}] end]
                }
                # decode
                set k [__url_decode $k]
                set v [__url_decode $v]
                dict set __qsdict $k $v
            }
        }

        proc __qget {d k {def ""}} {
            if {[dict exists $d $k]} { return [dict get $d $k] }
            return $def
        }

        if {[dict exists $__qsdict tailci] && [dict get $__qsdict tailci] eq "1"} {

            set tmpdir [findtempdir]
            set logfile [file join $tmpdir hammerdbci.log]

            if {![file exists $logfile]} {
                set logtxt "No active pipeline log"
            } else {
                set logtxt [_tail_ci_log_file $logfile 65536]
            }

            wapp-mimetype "text/plain; charset=utf-8"
            wapp-unsafe $logtxt
            return
        }

        # params
        set action [string tolower [string trim [__qget $__qsdict action ""]]]

        set dbprefix [string tolower [string trim [__qget $__qsdict db ""]]]
        if {$dbprefix eq ""} { set dbprefix "maria" }
        if {$dbprefix ni {"maria" "pg" "mysql"}} { set dbprefix "maria" }
        set pipeline_ui [string tolower [string trim [__qget $__qsdict pipeline ""]]]
        if {$pipeline_ui eq ""} { set pipeline_ui "single" }
        if {$pipeline_ui ni {"single" "profile" "compare"}} { set pipeline_ui "single" }

        set workload_ui [string toupper [string trim [__qget $__qsdict workload ""]]]
        if {$workload_ui eq ""} { set workload_ui "C" }
        if {$workload_ui ni {"C" "H"}} { set workload_ui "C" }

        set io_intensive [string trim [__qget $__qsdict io_intensive ""]]
        if {$io_intensive ne "1"} { set io_intensive "" }
        set io_intensive_checked [expr {$io_intensive eq "1" ? " checked" : ""}]

        # tag selection
        set tag_sel [string trim [__qget $__qsdict tag_sel ""]]
        set ref_custom [string trim [__qget $__qsdict ref_custom ""]]
        if {$ref_custom eq ""} { set ref_custom [string trim [__qget $__qsdict ref_cust ""]] }

        # typed tag => Custom
        if {[string trim $ref_custom] ne ""} {
            set tag_sel "__custom__"
        }

# Block databases that cannot be built/run by HammerDB pipelines yet.
if {$dbprefix in {ora mssqls db2}} {
    if {$action eq "run"} {
        __store_last 0 0 "[__db_label $dbprefix] pipelines are not yet enabled." "" "" "Support for already-running Oracle, SQL Server, and Db2 instances is planned for a future release."
        set q "db=$dbprefix"
if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
wapp-redirect "$B/pipelines?$q#runresult"
        return
    }
}
        set cfg [__get_ci_build_config $dbprefix]
        set repo_url     [dict get $cfg repo_url]
        set ref_regexp   [dict get $cfg ref_regexp]
        set cilisten_url [dict get $cfg cilisten_url]

        set tags [__github_tags $repo_url]

        if {$tag_sel eq ""} {
            if {[llength $tags] > 0} {
                set tag_sel [lindex $tags 0]
            } else {
                set tag_sel "__custom__"
            }
        }

        set ref $tag_sel
        if {$tag_sel eq "__custom__"} {
            set ref $ref_custom
        }

        # run
        if {$action eq "run"} {
            if {$windows_host} {
                __store_last 0 0 "CI pipelines are not available on Windows in this release." "" "" "Use HammerDB on Linux to run pipelines."
                set q "db=$dbprefix"
                if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
                if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
                if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
                if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
                if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
                wapp-redirect "$B/pipelines?$q#runresult"
                return
            }
            set ref_trim [string trim $ref]
            if {$ref_trim eq ""} {
                __store_last 0 0 "Ref is required." "" "" "Ref is required."
                set q "db=$dbprefix"
if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
wapp-redirect "$B/pipelines?$q#runresult"
                return
            }

            if {$pipeline_ui eq "single" && $workload_ui ni {"C" "H"}} {
                __store_last 0 0 "Workload must be C or H." "" "" "Bad workload."
                set q "db=$dbprefix"
if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
wapp-redirect "$B/pipelines?$q#runresult"
                return
            }

            if {$tag_sel eq "__custom__" && $ref_regexp ne ""} {
                if {![regexp -- $ref_regexp $ref_trim] && ![__is_sha1 $ref_trim]} {
                    __store_last 0 0 "Invalid ref format." "" "" "Ref did not match rules."
                    set q "db=$dbprefix"
if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
wapp-redirect "$B/pipelines?$q#runresult"
                    return
                }
            }

            
# Do not allow a second pipeline to be submitted while one is active
set active_ci_count [join [hdbjobs eval {
    SELECT COUNT(*)
    FROM JOBCI
    WHERE status IN ('PENDING','INIT','BUILDING','RUNNING')
}]]

if {$active_ci_count > 0} {
    __store_last 0 0 "Pipeline state is active." "" "" "Use Clear blocked CI pipeline if the previous run has stopped but left stale state."

    set q "db=$dbprefix"
    if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
    if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
    if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
    if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
    if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }

    wapp-redirect "$B/pipelines?$q#runresult"
    return
}

# request payload
set payload_json [__make_payload_json $ref_trim $dbprefix $pipeline_ui $workload_ui $io_intensive]

# banner text
set bench "TPROC-$workload_ui"
set ptxt  [string totitle $pipeline_ui]
set ref_short $ref_trim
if {[regexp {^refs/tags/(.+)$} $ref_trim -> r]} { set ref_short $r }

set summary "$bench · $ptxt · $ref_short"

# request text
#set payload_pretty "Request\n-------\nref:      $ref_trim\ndatabase: $dbprefix\npipeline: $pipeline_ui\nworkload: $workload_ui\nio:       $io_intensive\nqs:       $__qs\n\n(JSON)\n------\n$payload_json"
#without query string
set payload_pretty "Request\n-------\nref:      $ref_trim\ndatabase: $dbprefix\npipeline: $pipeline_ui\nworkload: $workload_ui\nio:       $io_intensive\n       \n(JSON)\n------\n$payload_json"

# try POST
set resp [__post_json $cilisten_url $payload_json]
set ok   [dict get $resp ok]
set code [dict get $resp code]
set body [dict get $resp body]
set err  [dict get $resp err]

if {!$ok} {
    set msg "CI listener not reachable at $cilisten_url. ($err) — $summary"
    __store_last 0 $code $msg $payload_pretty $body $err
} else {
    set msg "Pipeline queued — $summary"
    __store_last 1 $code $msg $payload_pretty $body ""
}

set q "db=$dbprefix"
if {$tag_sel ne ""} { append q "&tag_sel=[__url_encode $tag_sel]" }
if {$ref_custom ne ""} { append q "&ref_custom=[__url_encode $ref_custom]" }
if {$pipeline_ui ne ""} { append q "&pipeline=[__url_encode $pipeline_ui]" }
if {$workload_ui ne ""} { append q "&workload=[__url_encode $workload_ui]" }
if {$io_intensive ne ""} { append q "&io_intensive=[__url_encode $io_intensive]" }
wapp-redirect "$B/pipelines?$q#runresult"
return
        }

        # render page
        __page_head $B "HammerDB Pipelines"
        __auto_refresh_js 120000
        wapp-subst "<!-- pipelines-module:1.5 -->"
        wapp-subst {<div class="aut-wrap">}

        __render_last_if_any

	   if {$windows_host} {
            wapp-subst {
<div class="aut-banner aut-fail">
    <b>CI pipelines are not available on Windows in this release.</b><br>
    Use HammerDB on Linux to run pipelines.
</div>
}
        }

        # recent runs
        wapp-subst {<table>}
        wapp-subst {<tr><th>Pipeid</th><th>DB</th><th>Ref</th><th>Pipeline</th><th>Date</th><th>Status</th></tr>}

        set cicount [join [hdbjobs eval {SELECT COUNT(*) FROM JOBCI}]]
        if {$cicount eq 0} {
            wapp-subst {<tr><td colspan="6">No Automated CI runs found.</td></tr>}
        } else {
            set has_dbprefix 0
            if {![catch {hdbjobs eval {SELECT dbprefix FROM JOBCI LIMIT 1}}]} { set has_dbprefix 1 }
    # cleanup stale CI rows
    set now [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$has_dbprefix} {
        catch {
            hdbjobs eval "
                UPDATE JOBCI
                   SET status='FAILED',
                       end_timestamp='$now'
                 WHERE (end_timestamp IS NULL OR end_timestamp='')
                   AND status IN ('INIT','BUILDING','RUNNING')
                   AND EXISTS (
                       SELECT 1
                         FROM JOBCI j2
                        WHERE j2.refname  = JOBCI.refname
                          AND j2.dbprefix = JOBCI.dbprefix
                          AND j2.ci_id    > JOBCI.ci_id
                          AND (
                                -- newer row is queued/active
                                (
                                  (j2.end_timestamp IS NULL OR j2.end_timestamp='')
                                  AND j2.status IN ('PENDING','INIT','BUILDING','RUNNING')
                                )
                                OR
                                -- newer row has ended (COMPLETE/FAILED/etc)
                                (j2.end_timestamp IS NOT NULL AND j2.end_timestamp != '')
                              )
                   )
            "
        }
    } else {
        catch {
            hdbjobs eval "
                UPDATE JOBCI
                   SET status='FAILED',
                       end_timestamp='$now'
                 WHERE (end_timestamp IS NULL OR end_timestamp='')
                   AND status IN ('INIT','BUILDING','RUNNING')
                   AND EXISTS (
                       SELECT 1
                         FROM JOBCI j2
                        WHERE j2.refname = JOBCI.refname
                          AND j2.ci_id   > JOBCI.ci_id
                          AND (
                                (
                                  (j2.end_timestamp IS NULL OR j2.end_timestamp='')
                                  AND j2.status IN ('PENDING','INIT','BUILDING','RUNNING')
                                )
                                OR
                                (j2.end_timestamp IS NOT NULL AND j2.end_timestamp != '')
                              )
                   )
            "
        }
    }
            if {$has_dbprefix} {
                # alias columns
                hdbjobs eval {SELECT ci_id,
                                     refname,
                                     dbprefix AS row_dbprefix,
                                     pipeline AS row_pipeline,
                                     timestamp AS row_timestamp,
                                     status AS row_status
                              FROM JOBCI
                              ORDER BY ci_id DESC
                              LIMIT 25} {
                    set url "$B/ci?ci_id=$ci_id"
                    set plabel [ci_pipeline_label $row_pipeline]
                    wapp-subst "<tr><td><a href=\"%html($url)\">%html($ci_id)</a></td><td>%html([__db_label $row_dbprefix])</td><td>%html($refname)</td><td>%html($plabel)</td><td>%html($row_timestamp)</td><td>%html($row_status)</td></tr>"
                }
            } else {
                hdbjobs eval {SELECT ci_id,
                                     refname,
                                     pipeline AS row_pipeline,
                                     timestamp AS row_timestamp,
                                     status AS row_status
                              FROM JOBCI
                              ORDER BY ci_id DESC
                              LIMIT 25} {
                    set url "$B/ci?ci_id=$ci_id"
                    set plabel [ci_pipeline_label $row_pipeline]
                    wapp-subst "<tr><td><a href=\"%html($url)\">%html($ci_id)</a></td><td>-</td><td>%html($refname)</td><td>%html($plabel)</td><td>%html($row_timestamp)</td><td>%html($row_status)</td></tr>"
                }
            }
        }
        wapp-subst {</table>}

        wapp-subst {<div class="aut-form">}

        # database chooser
        wapp-subst {<p><b>Database</b></p>}
        wapp-subst "<select class='aut-ctl' name='db' onchange=\"window.location='%html($B)/pipelines?db=' + encodeURIComponent(this.value)\">"
        foreach {pfx label} [ list ora Oracle mssqls "SQL Server" db2 Db2 mysql MySQL pg PostgreSQL maria MariaDB ] {
            # Hide DBs until support is enabled
            if {$pfx in {ora mssqls db2}} continue
            set sel ""
            if {$dbprefix eq $pfx} { set sel " selected" }
            wapp-subst "<option value='%html($pfx)'$sel>%html($label)</option>"
        }
        wapp-subst {</select>}

        # DB header
        wapp-subst "<h4 style='margin:14px 0 8px 0;'>%html([__db_label $dbprefix])</h4>"

        # info line
        wapp-subst "<p class='aut-mini' style='margin-top:10px;'>"
        wapp-subst "<b>Endpoint:</b> %html($cilisten_url) &nbsp;·&nbsp; <b>Valid ref:</b> tag, branch, or commit SHA"
        wapp-subst "</p>"

        # run form
            if {$dbprefix in {ora mssqls db2}} {
            wapp-subst "<div class='aut-banner aut-fail' style='margin-top:10px;'>"
            wapp-subst "<b>%html([__db_label $dbprefix]) pipelines are not yet enabled.</b><br>"
            wapp-subst "Support for already-running Oracle, SQL Server, and Db2 instances is planned for a future release."
            wapp-subst "</div>"
        } elseif {$windows_host} {
            wapp-subst {
<div class="aut-banner aut-fail" style="margin-top:10px;">
    <b>CI pipelines are not available on Windows in this release.</b><br>
</div>
}
        } else {
wapp-subst "<form method='GET' action='%html($B)/pipelines' id='runform'>"
        wapp-subst {<input type='hidden' name='action' value='run'>}
        wapp-subst "<input type='hidden' name='db' value='%html($dbprefix)'>"

        wapp-subst {<p style='margin-top:12px;'><b>Ref</b></p>}
        wapp-subst {<select class="aut-ctl" name="tag_sel" form="runform">}
        if {[llength $tags] == 0} {
            wapp-subst "<option value='' disabled selected>(no tags found — use Custom...)</option>"
        }
        foreach t $tags {
            set sel ""
            if {$tag_sel eq $t} { set sel " selected" }
            wapp-subst "<option value='%html($t)'$sel>%html($t)</option>"
        }
        set sel ""
        if {$tag_sel eq "__custom__"} { set sel " selected" }
        wapp-subst "<option value='__custom__'$sel>Custom...</option>"
        wapp-subst {</select>}

        wapp-subst {<div class="aut-row">}
        wapp-subst {Custom ref (tag, branch, or commit SHA):}
        if {$ref_custom eq ""} {
            wapp-subst "<input class='aut-ctl' type='text' name='ref_custom' form='runform' placeholder='refs/tags/... or refs/heads/... or a1b2c3d4e5f6...'>"
        } else {
            wapp-subst "<input class='aut-ctl' type='text' name='ref_custom' form='runform' value='%html($ref_custom)' placeholder='refs/tags/... or refs/heads/... or 144dead8826f...'>"
        }
        wapp-subst {</div>}

# benchmark selector

# selected bench
set bench_c_single ""
set bench_c_profile ""
set bench_c_compare ""
set bench_h_single ""
set io_intensive ""

if {$workload_ui eq "H"} {
    set bench_h_single " checked"
} else {
    if {$pipeline_ui eq "profile"} {
        set bench_c_profile " checked"
    } elseif {$pipeline_ui eq "compare"} {
        set bench_c_compare " checked"
    } else {
        set bench_c_single " checked"
    }
}

wapp-subst "<input type='hidden' name='workload' id='workload_hidden' form='runform' value='%html($workload_ui)'>"
wapp-subst "<input type='hidden' name='pipeline'  id='pipeline_hidden'  form='runform' value='%html($pipeline_ui)'>"

wapp-subst {<div style='margin-top:18px;'>}
wapp-subst {<div style='font-weight:600; margin-bottom:6px;'>Benchmark</div>}

# TPROC-C
wapp-subst {<div style='display:flex; gap:18px; align-items:center; margin-top:6px;'>}
wapp-subst {<div style='min-width:82px; font-weight:600;'>TPROC-C</div>}
wapp-subst "<label style='cursor:pointer;'><input type='radio' name='bench' value='c_single'$bench_c_single onchange=\"document.getElementById('workload_hidden').value='C';document.getElementById('pipeline_hidden').value='single';\"> Single</label>"
wapp-subst "<label style='cursor:pointer;'><input type='radio' name='bench' value='c_profile'$bench_c_profile onchange=\"document.getElementById('workload_hidden').value='C';document.getElementById('pipeline_hidden').value='profile';\"> Profile</label>"
wapp-subst "<label style='cursor:pointer;'><input type='radio' name='bench' value='c_compare'$bench_c_compare onchange=\"document.getElementById('workload_hidden').value='C';document.getElementById('pipeline_hidden').value='compare';\"> Compare</label>"
wapp-subst "<label style='cursor:pointer; margin-left:14px;'><input type='checkbox' name='io_intensive' value='1'$io_intensive> Full Durability + I/O intensive</label>"
wapp-subst {</div>}

# TPROC-H
wapp-subst {<div style='display:flex; gap:18px; align-items:center; margin-top:8px;'>}
wapp-subst {<div style='min-width:82px; font-weight:600;'>TPROC-H</div>}
wapp-subst "<label style='cursor:pointer;'><input type='radio' name='bench' value='h_single'$bench_h_single onchange=\"document.getElementById('workload_hidden').value='H';document.getElementById('pipeline_hidden').value='single';\"> Single</label>"
wapp-subst {</div>}
wapp-subst {</div>}

wapp-subst {
<div style="margin:18px 0 20px 0; max-width:800px; border-radius:6px; background:#eef6ff; border:1px solid #d0d7de;">
  <details id="ci-log-panel">
    <summary style="cursor:pointer; padding:10px 14px; font-weight:600; color:#0a3d62; border-left:4px solid #0969da;">
      Pipeline Activity
    </summary>

    <div style="padding:12px;">
      <pre id="ci-log-box"
           style="margin:0;
                  padding:12px;
                  height:320px;
                  overflow:auto;
                  background:#eef6ff;
                  color:#0a3d62;
                  border:1px solid #d0d7de;
                  border-radius:6px;
                  font-family:monospace;
                  font-size:13px;
                  line-height:1.35;
                  white-space:pre-wrap;"></pre>
    </div>
  </details>
</div>
}

wapp-subst "<script>
(function () {
  const panel = document.getElementById('ci-log-panel');
  const box = document.getElementById('ci-log-box');
  let timer = null;

  async function refreshCILog() {
    try {
      const res = await fetch('/pipelines?tailci=1', {cache:'no-store'});
      const txt = await res.text();
      box.textContent = txt;
      box.scrollTop = box.scrollHeight;
    } catch(e) {
      box.textContent = 'Unable to load Pipeline log';
    }
  }

  panel.addEventListener('toggle', function () {
    if (panel.open) {
      refreshCILog();
      timer = setInterval(refreshCILog, 3000);
    } else {
      if (timer) {
        clearInterval(timer);
        timer = null;
      }
    }
  });
})();
</script>"

        wapp-subst {<div class="aut-actions">}
        wapp-subst {<button class="aut-btn" type="submit" form="runform">Run Benchmark</button>}
        wapp-subst {</div>}
        wapp-subst {</form>}
        }

        wapp-subst {</div>}
        wapp-subst {</div>}
        __page_tail
    }
}

namespace import pipelines::*
