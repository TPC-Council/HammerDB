# Native, read-only OceanBase ASH provider for the shared metrics presentation.
# This module also loads in the collector thread, where no Tk commands run.
namespace eval oceanbaseash {
    variable module_file [file normalize [info script]]
    variable last_provider {}
    variable profile {}
    variable event_groups {}

    proc groups {} {
        return {Other Application Concurrency Configuration Commit Network User_IO System_IO Scheduler Cluster CPU}
    }

    proc group {state waitclass} {
        if {$state eq "ON CPU"} {return CPU}
        set key [string toupper [string map {{ } _} $waitclass]]
        set known {APPLICATION Application CONCURRENCY Concurrency CONFIGURATION Configuration COMMIT Commit NETWORK Network USER_IO User_IO SYSTEM_IO System_IO SCHEDULER Scheduler CLUSTER Cluster}
        if {[dict exists $known $key]} {return [dict get $known $key]}
        return Other
    }

    proc event_group {event} {
        variable event_groups
        if {[dict exists $event_groups $event]} {return [dict get $event_groups $event]}
        if {$event eq "ON CPU"} {return CPU}
        return Other
    }

    proc integer {value {minimum 0}} {
        if {![string is wideinteger -strict $value] || $value < $minimum} {
            error "Invalid OceanBase ASH numeric bound"
        }
        return $value
    }

    proc sql_id {value} {
        if {$value eq "" || $value eq "{}"} {return {}}
        if {![regexp {^[[:xdigit:]]{32}$} $value]} {error "Invalid OceanBase SQL ID"}
        return $value
    }

    # Hex literals are independent of NO_BACKSLASH_ESCAPES and Tcl quoting.
    proc literal {value} {
        binary scan [encoding convertto utf-8 $value] H* encoded
        return "CONVERT(X'$encoded' USING utf8mb4)"
    }

    proc connection {configuration workload} {
        package require oceanbasecommon
        set c [dict get $configuration connection]
        if {[dict get $c ob_compatibility_mode] ne "mysql"} {error "OceanBase ASH currently supports MySQL tenants"}
        if {[string equal -nocase [dict get $c ob_tenant] sys]} {error "OceanBase ASH requires a business tenant, not sys"}
        set port [integer [dict get $c ob_port] 1]
        if {$port > 65535} {error "Invalid OceanBase ASH port"}
        set prefix [expr {$workload eq "TPC-C" ? "ob_" : "ob_tpch_"}]
        set section [expr {$workload eq "TPC-C" ? "tpcc" : "tpch"}]
        set user [::oceanbase::mysql::username [dict get $configuration $section ${prefix}user] [dict get $c ob_tenant] [dict get $c ob_cluster]]
        set options [list -host [dict get $c ob_host] -port $port -user $user -password [dict get $configuration $section ${prefix}pass]]
        lappend options {*}[::oceanbasecommon::ssl_options $configuration]
        return [dict create options $options timeout [integer [dict get $c ob_query_timeout] 1]]
    }

    proc prepare_provider {} {
        variable last_provider
        global rdbms public
        set current [expr {$rdbms eq "OceanBase" ? "OceanBase" : "MySQL"}]
        if {$last_provider ne "" && ($last_provider ne $current || $current eq "OceanBase")} {
            catch {destroy .ed_mainFrame.me.m}
            foreach pattern {x_w_ash x_ashsql y_w_* y_ashsql_* ash_day ash_sec sample_id y_ash_maxcpu x_ash_maxcpu} {
                foreach vector [::blt::vector names $pattern] {catch {::blt::vector destroy $vector}}
            }
            array unset public
            set ::mysqlmet::firstconnect true
        }
        set last_provider $current
    }

    proc connect {} {
        variable module_file
        global configoceanbase bm public dbmon_threadID masterthread
        if {[catch {set config [connection $configoceanbase $bm]} message]} {
            puts "OceanBase ASH: $message"
            catch {.ed_mainFrame.buttons.dashboard configure -state normal}
            return
        }
        set public(connected) 0
        set public(metrics_provider) OceanBase
        set public(thread_actv) 0
        set public(parent) $masterthread
        set dbmon_threadID [thread::create {thread::wait}]
        tsv::set application themonitor $dbmon_threadID
        # Lists preserve credentials and paths; the worker never evals data.
        thread::send $dbmon_threadID [list set auto_path $::auto_path]
        thread::send $dbmon_threadID [list ::tcl::tm::path add {*}[::tcl::tm::path list]]
        thread::send $dbmon_threadID [list source $module_file]
        thread::send -async $dbmon_threadID [list ::oceanbaseash::worker_connect $masterthread $config]
    }

    proc columns {handle view} {
        mysql::sel $handle "SELECT * FROM $view WHERE 1=0"
        return [string toupper [mysql::col $handle -current name]]
    }

    proc worker_connect {parent config} {
        variable profile
        set handle {}
        if {[catch {
            package require mysqltcl
            set handle [mysqlconnect {*}[dict get $config options]]
            mysql::exec $handle "SET SESSION ob_query_timeout = [expr {[dict get $config timeout] * 1000000}]"
            mysql::exec $handle {SET SESSION time_zone = '+00:00'}
            set tenant [lindex [mysql::sel $handle {SELECT effective_tenant_id()} -flatlist] 0]
            integer $tenant 2
            set fields [columns $handle {oceanbase.GV$OB_ACTIVE_SESSION_HISTORY}]
            foreach required {SAMPLE_TIME CON_ID SESSION_TYPE SESSION_STATE SESSION_ID SVR_IP SVR_PORT USER_ID SQL_ID WAIT_CLASS EVENT} {
                if {$required ni $fields} {error "OceanBase ASH view lacks $required"}
            }
            set profile [dict create tenant $tenant weight [expr {"WEIGHT" in $fields ? "COALESCE(WEIGHT,1)" : "1"}]]
            foreach {name view} {plans {oceanbase.GV$OB_PLAN_CACHE_PLAN_STAT} explain {oceanbase.GV$OB_PLAN_CACHE_PLAN_EXPLAIN}} {
                if {[catch {set cols [columns $handle $view]}]} {set cols {}}
                dict set profile $name $cols
            }
        } message]} {
            if {$handle ne ""} {catch {mysqlclose $handle}}
            thread::send -async $parent [list ::oceanbaseash::connection_failed [thread::id] $message]
            thread::release
            return
        }
        thread::send -async $parent [list ::oceanbaseash::connected [thread::id] $handle $profile]
    }

    proc connection_failed {worker message} {
        global public dbmon_threadID
        if {![info exists dbmon_threadID] || $dbmon_threadID ne $worker} {return}
        set public(connected) err
        set public(run) 0
        unset -nocomplain dbmon_threadID
        tsv::set application themonitor READY
        puts "OceanBase ASH unavailable: $message. Check the business tenant and permission to read oceanbase.GV\$OB_ACTIVE_SESSION_HISTORY."
        catch {.ed_mainFrame.buttons.dashboard configure -state normal}
    }

    proc connected {worker handle capabilities} {
        variable profile
        global public dbmon_threadID
        if {![info exists dbmon_threadID] || $dbmon_threadID ne $worker} {
            catch {thread::send -async $worker [list ::oceanbaseash::worker_close $handle]}
            return
        }
        set profile $capabilities
        ::mysqlmet::colors
        ::mysqlmet::init_publics
        set public(connected) 1
        set public(handle) $handle
        set public(thread_actv) 0
        set public(cpucount) 0
        set public(ash,selected_sql) {}
        set public(ash,last_end) 0
        set public(ash,event_name) {}
        set public(version) 8.0
        ::mysqlmet::create_metrics_screen
        start_monitor
        catch {.ed_mainFrame.buttons.dashboard configure -state normal}
    }

    proc start_monitor {} {
        global public
        set public(run) 1
        set public(visible) {}
        # An empty ASH view is valid: the monitor remains open for future work.
        ::mysqlmet::ash_init 1
        set public(cursor,ash) fast
        set public(slow_cur) 0
        set public(sql,sqlio) {OceanBase native ASH I/O samples}
        catch {$public(ash,graph) axis configure y -title "Average active sessions"}
        set buttons $public(ash,details_buttons).sql
        $buttons.stats configure -command {::oceanbaseash::show_detail ash_sqlstats}
        $buttons.sqlio configure -command {::oceanbaseash::show_detail sqlio}
        ttk::button $buttons.plan -text "cached plan" -command {::oceanbaseash::show_detail ash_sqlplan}
        pack $buttons.plan -side left
        ::mysqlmet::mon_loop
        puts "OceanBase ASH: current tenant foreground sessions across OBServers; completed time buckets, native sampling weights."
    }

    proc stop {} {
        global public dbmon_threadID
        set public(run) 0
        set public(thread_actv) 0
        after cancel mon_loop
        after cancel ::mysqlmet::mon_loop
        if {[info exists dbmon_threadID]} {
            if {[thread::exists $dbmon_threadID]} {
                if {[info exists public(handle)]} {
                    catch {thread::send -async $dbmon_threadID [list ::oceanbaseash::worker_close $public(handle)]}
                } else {catch {thread::release $dbmon_threadID}}
            }
            unset -nocomplain dbmon_threadID
        }
        tsv::set application themonitor READY
        catch {.ed_mainFrame.buttons.dashboard configure -state normal}
    }

    proc worker_close {handle} {
        catch {mysqlclose $handle}
        thread::release
    }

    proc sample_source {capabilities begin end {selected {}}} {
        set tenant [integer [dict get $capabilities tenant] 2]
        set begin [integer $begin]
        set end [integer $end]
        set weight [dict get $capabilities weight]
        if {$weight ni {1 {COALESCE(WEIGHT,1)}}} {error "Invalid ASH sampling weight"}
        set predicate {}
        set selected [sql_id $selected]
        if {$selected ne ""} {set predicate " AND SQL_ID='[string toupper $selected]'"}
        return "SELECT SAMPLE_TIME, SVR_IP, SVR_PORT, SESSION_ID, USER_ID, SQL_ID,
            SESSION_STATE, WAIT_CLASS, CASE WHEN SESSION_STATE='ON CPU' THEN 'ON CPU' ELSE EVENT END AS EVENT,
            $weight AS SAMPLE_WEIGHT
            FROM oceanbase.GV\$OB_ACTIVE_SESSION_HISTORY
            WHERE CON_ID=$tenant AND SESSION_TYPE='FOREGROUND'
            AND (SESSION_STATE='ON CPU' OR UPPER(WAIT_CLASS)<>'IDLE')
            AND SAMPLE_TIME>=FROM_UNIXTIME($begin) AND SAMPLE_TIME<FROM_UNIXTIME($end)$predicate"
    }

    # Request arguments are validated numbers, an SQL ID, or encoded SQL data.
    proc query {cursor request capabilities} {
        set begin [dict get $request begin]
        set end [dict get $request end]
        set selected [dict get $request selected]
        if {$cursor in {ash ash_sqldetails ash_eventsqls}} {set selected {}}
        set source [sample_source $capabilities $begin $end $selected]
        switch -- $cursor {
            ash - sqlovertime {
                set bucket [integer [dict get $request bucket] 1]
                return "SELECT FLOOR(UNIX_TIMESTAMP(SAMPLE_TIME)/$bucket)*$bucket AS BUCKET_START,
                    SESSION_STATE, WAIT_CLASS, SUM(SAMPLE_WEIGHT) AS SAMPLES FROM ($source) ash
                    GROUP BY BUCKET_START, SESSION_STATE, WAIT_CLASS ORDER BY BUCKET_START"
            }
            ash_sqldetails {
                return "SELECT SQL_ID, SESSION_STATE, WAIT_CLASS, SUM(SAMPLE_WEIGHT) FROM ($source) ash
                    GROUP BY SQL_ID, SESSION_STATE, WAIT_CLASS"
            }
            ash_sqlsessions {
                return "SELECT SVR_IP, SVR_PORT, SESSION_ID, USER_ID, SESSION_STATE, WAIT_CLASS,
                    SUM(SAMPLE_WEIGHT) FROM ($source) ash
                    GROUP BY SVR_IP, SVR_PORT, SESSION_ID, USER_ID, SESSION_STATE, WAIT_CLASS"
            }
            ash_sqlevents - sqlio {
                set where [expr {$cursor eq "sqlio" ? "WHERE UPPER(WAIT_CLASS) IN ('USER_IO','SYSTEM_IO','USER IO','SYSTEM IO')" : ""}]
                return "SELECT EVENT, SESSION_STATE, WAIT_CLASS, SUM(SAMPLE_WEIGHT) FROM ($source) ash $where
                    GROUP BY EVENT, SESSION_STATE, WAIT_CLASS ORDER BY SUM(SAMPLE_WEIGHT) DESC"
            }
            ash_eventsqls {
                return "SELECT SQL_ID, SUM(SAMPLE_WEIGHT) FROM ($source) ash
                    WHERE EVENT=[literal [dict get $request event]] GROUP BY SQL_ID ORDER BY SUM(SAMPLE_WEIGHT) DESC LIMIT 20"
            }
            default {error "Unsupported OceanBase ASH query $cursor"}
        }
    }

    proc execute {cursor} {
        global public dbmon_threadID
        if {![info exists public(run)] || !$public(run) || ![info exists dbmon_threadID]} {return}
        if {$cursor in {days version ashempty secs cpucount ashrpt}} {return}
        if {$cursor eq "ashtime"} {set cursor ash}
        if {$public(thread_actv)} {return}
        set selected $public(ash,selected_sql)
        if {$cursor eq "sqlovertime" && [info exists public(ashsql,sqlovertimeid)]} {
            set selected {}
            regexp {digest = '([[:xdigit:]]{32})'} $public(ashsql,sqlovertimeid) -> selected
        }
        set begin [expr {[info exists public(ash,beg)] ? wide($public(ash,beg)) : 0}]
        set end [expr {[info exists public(ash,end)] ? wide($public(ash,end)) : 0}]
        set request [dict create begin $begin end $end selected $selected bucket 15 event $public(ash,event_name)]
        if {$cursor eq "ash"} {dict set request begin $public(ash,last_end)}
        if {$cursor eq "sqlovertime"} {dict set request begin $public(ash,starttime)}
        set public(thread_actv) 1
        if {[catch {
            thread::send -async $dbmon_threadID [list ::oceanbaseash::worker_fetch [thread::id] $public(handle) $cursor $request]
        } message]} {
            set public(thread_actv) 0
            puts "OceanBase ASH: $message"
            return
        }
        vwait public(thread_actv)
    }

    proc worker_fetch {parent handle cursor request} {
        variable profile
        set rows {}
        set names {}
        set message {}
        if {[catch {
            if {$cursor in {ash sqlovertime sqlio}} {
                set now [lindex [mysql::sel $handle {SELECT FLOOR(UNIX_TIMESTAMP(NOW()))} -flatlist] 0]
                set end [expr {wide($now) / 15 * 15}]
                if {$cursor eq "sqlio" || [dict get $request begin] == 0} {
                    set earliest [expr {$end-7200}]
                    if {$cursor eq "ash"} {
                        # Do not paint evicted history as idle. Start with the
                        # oldest retained sample, or one empty bucket on an idle tenant.
                        set tenant [integer [dict get $profile tenant] 2]
                        set retained [lindex [mysql::sel $handle "SELECT FLOOR(UNIX_TIMESTAMP(MIN(SAMPLE_TIME))) FROM oceanbase.GV\$OB_ACTIVE_SESSION_HISTORY WHERE CON_ID=$tenant AND SAMPLE_TIME>=FROM_UNIXTIME($earliest)" -flatlist] 0]
                        if {[string is wideinteger -strict $retained]} {
                            set earliest [expr {max($earliest,wide($retained)/15*15)}]
                        } else {set earliest [expr {$end-15}]}
                    }
                    dict set request begin $earliest
                }
                dict set request end $end
            }
            if {$cursor in {ash_sqltxt ash_sqlstats ash_sqlplan}} {
                lassign [cached_detail $handle $cursor [dict get $request selected] $profile] names rows
            } else {
                set sql [query $cursor $request $profile]
                set rows [mysql::sel $handle $sql -list]
            }
        } message]} {
            set rows {}
        } else {set message {}}
        thread::send -async $parent [list ::oceanbaseash::fetched [thread::id] $cursor $request $names $rows $message]
    }

    proc cached_detail {handle cursor selected capabilities} {
        set selected [sql_id $selected]
        if {$selected eq ""} {return [list {} {}]}
        set fields [dict get $capabilities plans]
        if {"SQL_ID" ni $fields} {error "Plan cache details are unavailable (view or permission)"}
        set tenant [integer [dict get $capabilities tenant] 2]
        set where "SQL_ID='$selected'"
        if {"TENANT_ID" in $fields} {append where " AND TENANT_ID=$tenant"}
        if {$cursor eq "ash_sqltxt"} {
            if {"STATEMENT" ni $fields} {error "SQL text is unavailable in the plan cache"}
            set text STATEMENT
            if {"QUERY_SQL" in $fields} {set text {COALESCE(NULLIF(QUERY_SQL,''),STATEMENT)}}
            return [list {STATEMENT} [mysql::sel $handle "SELECT $text FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 1" -list]]
        }
        if {$cursor eq "ash_sqlstats"} {
            set names {}
            foreach name {SVR_IP SVR_PORT PLAN_ID EXECUTIONS ELAPSED_TIME CPU_TIME ROWS_PROCESSED LAST_ACTIVE_TIME} {
                if {$name in $fields} {lappend names $name}
            }
            if {"EXECUTIONS" ni $names} {error "Execution statistics are unavailable in the plan cache"}
            return [list $names [mysql::sel $handle "SELECT `[join $names {`,`}]` FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 20" -list]]
        }
        set explain [dict get $capabilities explain]
        foreach name {SVR_IP SVR_PORT PLAN_ID} {
            if {$name ni $fields || $name ni $explain} {error "Cached plan details are unavailable (view or permission)"}
        }
        set keys [mysql::sel $handle "SELECT SVR_IP,SVR_PORT,PLAN_ID FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 1" -list]
        if {![llength $keys]} {return [list {} {}]}
        lassign [lindex $keys 0] ip port plan
        set names {}
        foreach name {SVR_IP SVR_PORT PLAN_ID PLAN_LINE_ID OPERATOR NAME ROWS COST PROPERTY} {
            if {$name in $explain} {lappend names $name}
        }
        set filter "SVR_IP=[literal $ip] AND SVR_PORT=[integer $port 1] AND PLAN_ID=[integer $plan]"
        if {"TENANT_ID" in $explain} {append filter " AND TENANT_ID=$tenant"}
        set order [expr {"PLAN_LINE_ID" in $explain ? "ORDER BY PLAN_LINE_ID" : ""}]
        return [list $names [mysql::sel $handle "SELECT `[join $names {`,`}]` FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_EXPLAIN WHERE $filter $order" -list]]
    }

    proc graph_rows {rows begin end bucket} {
        set counts {}
        foreach row $rows {
            lassign $row start state waitclass weight
            set start [expr {wide($start)}]
            set category [group $state $waitclass]
            dict set counts $start $category [expr {[dict exists $counts $start $category] ? [dict get $counts $start $category]+$weight : $weight}]
        }
        set result {}
        for {set start $begin} {$start < $end} {incr start $bucket} {
            set finish [expr {$start+$bucket}]
            set categories [expr {[dict exists $counts $start] ? [dict get $counts $start] : [dict create CPU 0]}]
            dict for {category count} $categories {
                # Positional contract of the existing graph callback.
                lappend result [list [expr {$finish%86400}] [expr {$start/86400+719528}] [expr {$finish/86400+719528}] \
                    [expr {double($count)/$bucket}] $finish [expr {$finish%86400}] [expr {$start%86400}] $category]
            }
        }
        return $result
    }

    proc overtime_rows {rows begin end bucket} {
        set result {}
        # The shared SQL-over-time renderer divides by consecutive point
        # distances. Include every bucket so an idle gap never dilutes the next
        # active bucket's AAS. Preserve categories sharing the same timestamp.
        foreach row [graph_rows $rows $begin $end $bucket] {
            lappend result [list [lindex $row 4] [lindex $row 2] \
                [expr {[lindex $row 3]*$bucket}] [lindex $row 0] [lindex $row 7]]
        }
        return $result
    }

    proc fetched {worker cursor request names rows message} {
        global public dbmon_threadID
        if {![info exists dbmon_threadID] || $dbmon_threadID ne $worker} {return}
        set public(thread_actv) 0
        if {![info exists public(run)] || !$public(run)} {return}
        if {$message ne ""} {
            if {$cursor in {ash_sqltxt ash_sqlstats ash_sqlplan}} {
                display_text "Unavailable: $message"
            } else {puts "OceanBase ASH $cursor unavailable: $message"}
            return
        }
        switch -- $cursor {
            ash {
                set begin [dict get $request begin]
                set end [dict get $request end]
                if {$begin >= $end} {return}
                set public(ash,last_end) $end
                set public(ash,starttime) [expr {$end-7200}]
                set public(today) [expr {$end/86400+719528}]
                set public(secs) [expr {$end%86400}]
                ::mysqlmet::ash_fetch 1 [graph_rows $rows $begin $end 15]
            }
            ash_sqldetails {render_activity sql $rows}
            ash_sqlsessions {render_activity session $rows}
            ash_sqlevents {render_events $rows}
            sqlovertime {
                ::mysqlmet::sqlovertime_fetch 1 [overtime_rows $rows [dict get $request begin] [dict get $request end] 15]
            }
            ash_sqltxt - ash_sqlstats - ash_sqlplan {
                if {![llength $rows]} {display_text "Unavailable: this SQL is no longer present in the tenant plan cache."; return}
                set text {}
                if {$cursor eq "ash_sqlstats"} {append text "Plan-cache lifetime totals, not totals for the selected ASH interval. Time columns are microseconds.\n\n"}
                foreach row $rows {
                    foreach name $names value $row {append text "$name: $value\n"}
                    append text "\n"
                }
                display_text $text
            }
            sqlio {
                set text "I/O ASH sample weights in the last two hours:\n"
                foreach row $rows {lassign $row event state waitclass samples; append text "$event ($waitclass): $samples\n"}
                display_text $text
            }
            ash_eventsqls {
                set text "SQL IDs sampled for $public(ash,event_name):\n"
                foreach row $rows {lassign $row id samples; append text "$id: $samples sample weight\n"}
                display_text $text
            }
        }
    }

    proc activity_rows {kind rows} {
        set aggregate {}
        foreach row $rows {
            if {$kind eq "sql"} {
                lassign $row id state waitclass samples
                set label $id
                set detail SQL
            } else {
                lassign $row ip port session user state waitclass samples
                set id "$ip:$port/$session"
                set label "user $user @ $ip:$port"
                set detail $id
            }
            if {$kind eq "sql" && ![regexp {^[[:xdigit:]]{32}$} $id]} {continue}
            set category [group $state $waitclass]
            if {![dict exists $aggregate $id]} {
                dict set aggregate $id [dict create label $label detail $detail total 0 counts {}]
            }
            dict set aggregate $id total [expr {[dict get $aggregate $id total]+$samples}]
            set old [expr {[dict exists $aggregate $id counts $category] ? [dict get $aggregate $id counts $category] : 0}]
            dict set aggregate $id counts $category [expr {$old+$samples}]
        }
        set result {}
        dict for {id values} $aggregate {
            set total [dict get $values total]
            set row [list [dict get $values label] $total $total [dict get $values detail]]
            foreach category [groups] {
                lappend row [expr {[dict exists $values counts $category] ? [dict get $values counts $category] : 0}]
            }
            lappend result $row
        }
        return [lsort -real -decreasing -index 2 $result]
    }

    proc render_activity {kind rows} {
        global public
        set key [expr {$kind eq "sql" ? "sqltbl" : "sestbl"}]
        set table $public(ash,$key)
        $table delete 0 end
        set rendered [activity_rows $kind $rows]
        set total 0
        foreach row $rendered {set total [expr {$total+[lindex $row 2]}]}
        if {$kind eq "sql"} {set public(sqltbl,maxActivity) [expr {max($total,1)}]}
        set public(ashtbl,delta) [expr {max($public(ash,end)-$public(ash,beg),1)}]
        foreach row $rendered {
            set index [$table insert end $row]
        }
        for {set index 0} {$index < [$table size]} {incr index} {
            $table cellconfigure $index,1 -window [expr {$kind eq "sql" ? "createSqlFrame" : "createSesFrame"}]
        }
        if {$kind eq "sql"} {
            set id [expr {[llength $rendered] ? [lindex $rendered 0 0] : ""}]
            select_sql $id
        }
    }

    proc render_events {rows} {
        variable event_groups
        global public
        $public(ash,evttbl) delete 0 end
        set total 0
        foreach row $rows {
            lassign $row event state waitclass samples
            set category [group $state $waitclass]
            dict set event_groups $event $category
            $public(ash,evttbl) insert end [list $event $samples $samples $category]
            set total [expr {$total+$samples}]
        }
        set public(ashevt,total) [expr {max($total,1)}]
        for {set i 0} {$i < [$public(ash,evttbl) size]} {incr i} {
            $public(ash,evttbl) cellconfigure $i,1 -window createevtFrame
        }
    }

    proc select_sql {selected} {
        global public
        set public(ash,selected_sql) [sql_id $selected]
        set public(ash,realsqlid) $public(ash,selected_sql)
        execute ash_sqltxt
        execute ash_sqlevents
        execute ash_sqlsessions
    }

    proc details {begin end} {
        global public x_w_ash
        set left [expr {wide($x_w_ash($begin))}]
        set right [expr {wide($x_w_ash($end))}]
        if {$left > $right} {lassign [list $right $left] left right}
        if {$left == $right} {incr right 15}
        set public(ash,beg) $left
        set public(ash,end) $right
        set public(ash,begid) $left
        set public(ash,endid) $right
        execute ash_sqldetails
    }

    proc display_text {text} {
        global public
        $public(ash,output) delete 0.0 end
        $public(ash,output) insert end $text
    }

    proc show_detail {cursor} {
        global public
        catch {pack forget $public(ash,output_frame).stats}
        pack $public(ash,output_frame).txt -side left -anchor nw
        execute $cursor
    }

    proc session_table {table} {
        $table columnconfigure sid -sortmode dictionary
        bind [$table bodytag] <Button-1> {::oceanbaseash::session_click %W %x %y}
    }

    proc session_click {widget x y} {
        global public
        foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields $widget $x $y] {}
        set table $public(ash,sestbl)
        set row [$table containing $tablelist::y]
        if {$row < 0} {return}
        set text "Session [$table cellcget $row,sid -text]\nASH sample weights in selected interval:\n"
        foreach category [groups] {append text "$category: [$table cellcget $row,$category -text]\n"}
        display_text $text
    }
}
package provide oceanbaseash 1.0
