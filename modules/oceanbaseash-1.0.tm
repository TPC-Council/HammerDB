# Read-only OceanBase ASH data and worker lifecycle.
# Each worker owns its OceanBase Connector/C session and reports data by callback.
namespace eval oceanbaseash {
    variable module_file [file normalize [info script]]
    variable worker {}
    variable retiring {}
    variable generation 0
    variable ready 0
    variable callback {}
    variable next_request 0
    variable handle {}
    variable profile {}

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
        set password [::oceanbase::mysql::decode_password [dict get $configuration $section ${prefix}pass]]
        set options [list -host [dict get $c ob_host] -port $port -user $user -password $password]
        lappend options {*}[::oceanbasecommon::ssl_options $configuration]
        return [dict create options $options timeout [integer [dict get $c ob_query_timeout] 1]]
    }

    proc start {configuration workload callbackPrefix} {
        variable module_file
        variable worker
        variable generation
        variable callback
        if {![llength $callbackPrefix]} {error "OceanBase ASH requires a callback"}
        stop
        set session [incr generation]
        set callback $callbackPrefix
        if {[catch {
            package require Thread
            set config [connection $configuration $workload]
            set parent [thread::id]
            set bootstrap [list apply {{module paths tm_paths parent session config} {
                if {[catch {
                    set ::auto_path $paths
                    ::tcl::tm::path add {*}$tm_paths
                    source $module
                } message]} {
                    catch {thread::send -async $parent [list ::oceanbaseash::connection_failed [thread::id] $session $message]}
                    tsv::unset oceanbaseash_workers [thread::id]
                    thread::release
                    return
                }
                ::oceanbaseash::worker_connect $parent $session $config
            }} $module_file $::auto_path [::tcl::tm::path list] $parent $session $config]
            set worker [thread::create {thread::wait}]
            # Benchmark interpreters can see the worker through Thread's registry.
            tsv::set oceanbaseash_workers $worker 1
            thread::send -async $worker $bootstrap
        } message]} {
            if {$worker ne {}} {
                catch {tsv::unset oceanbaseash_workers $worker}
                catch {thread::release $worker}
            }
            after 0 [list ::oceanbaseash::connection_failed $worker $session $message]
        }
        return
    }

    proc threads {} {
        variable worker
        variable retiring
        set live {}
        foreach thread $retiring {
            if {[thread::exists $thread]} {lappend live $thread}
        }
        set retiring $live
        if {$worker ne {} && [thread::exists $worker]} {lappend live $worker}
        return $live
    }

    proc stop {} {
        variable worker
        variable retiring
        variable ready
        variable callback
        threads
        set ready 0
        set callback {}
        if {$worker eq {}} {return}
        set closing $worker
        set worker {}
        if {![thread::exists $closing]} {return}
        lappend retiring $closing
        # Queue closure ahead of obsolete work. If bootstrap has not run,
        # there is no client session to close.
        if {[catch {thread::send -async -head $closing {
            if {[llength [info commands ::oceanbaseash::worker_close]]} {
                ::oceanbaseash::worker_close
            } else {
                tsv::unset oceanbaseash_workers [thread::id]
                thread::release
            }
        }}]} {catch {thread::release $closing}}
    }

    proc columns {handle view} {
        ::obmysql::sel $handle "SELECT * FROM $view WHERE 1=0"
        return [string toupper [::obmysql::col $handle -current name]]
    }

    proc worker_connect {parent session config} {
        variable handle
        variable profile
        if {[catch {
            package require oceanbasecommon
            oceanbasecommon::load_client
            set handle [::obmysql::connect {*}[dict get $config options]]
            ::obmysql::exec $handle "SET SESSION ob_query_timeout = [expr {[dict get $config timeout] * 1000000}]"
            ::obmysql::exec $handle {SET SESSION time_zone = '+00:00'}
            set tenant [lindex [::obmysql::sel $handle {SELECT effective_tenant_id()} -flatlist] 0]
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
            catch {thread::send -async $parent [list ::oceanbaseash::connection_failed [thread::id] $session $message]}
            worker_close
            return
        }
        if {[catch {thread::send -async $parent [list ::oceanbaseash::connected [thread::id] $session]}]} {worker_close}
    }

    proc connection_failed {thread session message} {
        variable worker
        variable retiring
        variable generation
        variable ready
        variable callback
        if {$session != $generation || $thread ne $worker || $callback eq {}} {return}
        if {$worker ne {} && [thread::exists $worker]} {lappend retiring $worker}
        set worker {}
        set ready 0
        set failed_callback $callback
        set callback {}
        {*}$failed_callback error connect {} $message
    }

    proc connected {thread session} {
        variable worker
        variable generation
        variable ready
        variable callback
        if {$session != $generation || $thread ne $worker || $callback eq {}} {return}
        set ready 1
        {*}$callback connected
    }

    proc worker_close {} {
        variable handle
        if {$handle ne {}} {catch {::obmysql::close $handle}}
        set handle {}
        tsv::unset oceanbaseash_workers [thread::id]
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

    proc request {cursor params} {
        variable worker
        variable ready
        variable generation
        variable next_request
        if {!$ready || ![thread::exists $worker]} {return {}}
        if {$cursor ni {ash sqlovertime ash_sqldetails ash_sqlsessions ash_sqlevents
                sqlio ash_eventsqls ash_sqltxt ash_sqlstats ash_sqlplan}} {
            error "Unsupported OceanBase ASH request $cursor"
        }
        set id [incr next_request]
        set request [dict merge {begin 0 end 0 selected {} event {}} $params [list id $id bucket 15]]
        if {[catch {thread::send -async $worker                 [list ::oceanbaseash::worker_fetch [thread::id] $generation $cursor $request]}]} {
            return {}
        }
        return $id
    }

    proc worker_window {cursor request} {
        variable handle
        variable profile
        set bucket [dict get $request bucket]
        set begin [integer [dict get $request begin]]
        set end [integer [dict get $request end]]
        if {$end == 0} {
            set now [integer [lindex [::obmysql::sel $handle {SELECT FLOOR(UNIX_TIMESTAMP(NOW()))} -flatlist] 0]]
            set end [expr {$now / $bucket * $bucket}]
            # A backward server-clock change invalidates the incremental
            # cursor. Reload from retained history using the new endpoint.
            if {$cursor eq "ash" && $begin > $end} {set begin 0}
        }
        if {$begin > $end} {error "Invalid OceanBase ASH time range"}
        set initial [expr {$begin == 0}]
        if {$cursor in {ash sqlovertime}} {
            set begin [expr {$begin / $bucket * $bucket}]
            set end [expr {$end / $bucket * $bucket}]
        }
        set earliest [expr {max($end - 7200, 0)}]
        if {$cursor eq "ash" && $initial} {
            # Initial history starts at the oldest retained sample, not at
            # an assumed idle point. An idle tenant gets one empty bucket.
            set tenant [dict get $profile tenant]
            set retained [lindex [::obmysql::sel $handle "SELECT FLOOR(UNIX_TIMESTAMP(MIN(SAMPLE_TIME)))
                FROM oceanbase.GV\$OB_ACTIVE_SESSION_HISTORY WHERE CON_ID=$tenant
                AND SAMPLE_TIME>=FROM_UNIXTIME($earliest) AND SAMPLE_TIME<FROM_UNIXTIME($end)" -flatlist] 0]
            if {[string is wideinteger -strict $retained]} {
                set begin [expr {min($end, $retained / $bucket * $bucket)}]
            } else {
                set begin [expr {$end - $bucket}]
            }
        }
        dict set request begin [expr {max($begin, $earliest)}]
        dict set request end $end
        return $request
    }

    proc worker_fetch {parent session cursor request} {
        variable handle
        variable profile
        set rows {}
        set names {}
        set message {}
        if {[catch {
            if {$cursor in {ash_sqltxt ash_sqlstats ash_sqlplan}} {
                lassign [cached_detail $handle $cursor [dict get $request selected] $profile] names rows
            } else {
                set request [worker_window $cursor $request]
                if {[dict get $request begin] < [dict get $request end]} {
                    set rows [::obmysql::sel $handle [query $cursor $request $profile] -list]
                }
            }
        } message]} {
            set result [list error $cursor $request $message]
        } else {
            set result [list result $cursor $request $names $rows]
        }
        if {[catch {thread::send -async $parent                 [list ::oceanbaseash::received [thread::id] $session {*}$result]}]} {
            worker_close
        }
    }

    proc received {thread session args} {
        variable worker
        variable generation
        variable ready
        variable callback
        if {!$ready || $session != $generation || $thread ne $worker || $callback eq {}} {return}
        {*}$callback {*}$args
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
            return [list {STATEMENT} [::obmysql::sel $handle "SELECT $text FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 1" -list]]
        }
        if {$cursor eq "ash_sqlstats"} {
            set names {}
            foreach name {SVR_IP SVR_PORT PLAN_ID EXECUTIONS ELAPSED_TIME CPU_TIME ROWS_PROCESSED LAST_ACTIVE_TIME} {
                if {$name in $fields} {lappend names $name}
            }
            if {"EXECUTIONS" ni $names} {error "Execution statistics are unavailable in the plan cache"}
            return [list $names [::obmysql::sel $handle "SELECT `[join $names {`,`}]` FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 20" -list]]
        }
        set explain [dict get $capabilities explain]
        foreach name {SVR_IP SVR_PORT PLAN_ID} {
            if {$name ni $fields || $name ni $explain} {error "Cached plan details are unavailable (view or permission)"}
        }
        set keys [::obmysql::sel $handle "SELECT SVR_IP,SVR_PORT,PLAN_ID FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_STAT WHERE $where LIMIT 1" -list]
        if {![llength $keys]} {return [list {} {}]}
        lassign [lindex $keys 0] ip port plan
        set names {}
        foreach name {SVR_IP SVR_PORT PLAN_ID PLAN_LINE_ID OPERATOR NAME ROWS COST PROPERTY} {
            if {$name in $explain} {lappend names $name}
        }
        set filter "SVR_IP=[literal $ip] AND SVR_PORT=[integer $port 1] AND PLAN_ID=[integer $plan]"
        if {"TENANT_ID" in $explain} {append filter " AND TENANT_ID=$tenant"}
        set order [expr {"PLAN_LINE_ID" in $explain ? "ORDER BY PLAN_LINE_ID" : ""}]
        return [list $names [::obmysql::sel $handle "SELECT `[join $names {`,`}]` FROM oceanbase.GV\$OB_PLAN_CACHE_PLAN_EXPLAIN WHERE $filter $order" -list]]
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

}
package provide oceanbaseash 1.0
