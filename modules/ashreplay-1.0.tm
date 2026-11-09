# Historical execution of the desktop ASH SQL over archived native rows.
# This is a SQL dialect adapter, not an ASH sampler or a second analytics engine.
package require sqlite3

namespace eval ::ashreplay {
    variable root [file dirname [file dirname [info script]]]
    variable providers {}
    variable serial 0
    variable contexts {}
    namespace export report query original_sql window selection percent
}

proc ::ashreplay::_provider {database} {
    variable root
    variable providers
    if {$database ni {pg mysql maria vsql}} {error "Unsupported ASH database"}
    set family [expr {$database eq "vsql" ? "mysql" : $database}]
    if {![dict exists $providers $family]} {
        lassign [dict get {pg {postgresql pgmet set_pgcursors} mysql {mysql mysqlmet set_mysqlcursors} maria {mariadb mariamet set_mariacursors}} $family] dir ns setup
        set child [interp create]
        try {
            interp eval $child [list source [file join $root src $dir ${ns}.tcl]]
            interp eval $child [list ${ns}::$setup]
            if {$family eq "pg"} {
                interp eval $child {pgmet::set_pg_waits; pgmet::set_pg_events}
            } else {
                interp eval $child [list ${ns}::set_${family}_waits]
                interp eval $child [list ${ns}::set_${family}_events]
            }
            dict set providers $family [dict create interp $child namespace $ns]
        } on error {message options} {
            interp delete $child
            return -options $options $message
        }
    }
    return [dict get $providers $family]
}

proc ::ashreplay::original_sql {database cursor} {
    if {$cursor ni {ash ashtime ashempty days secs ash_sqldetails ash_sqlsessions ash_sqlevents ash_sqltxt ash_sqlstats ash_eventsqls sqlovertimeload sqlio}} {
        error "ASH replay does not execute this desktop cursor"
    }
    set provider [_provider $database]
    return [interp eval [dict get $provider interp] [list set public(sql,$cursor)]]
}

proc ::ashreplay::_finite {value name} {
    if {![string is double -strict $value] || [catch {expr {abs(double($value)) < Inf}} finite] || !$finite} {
        error "ASH $name must be a finite number"
    }
    return $value
}

proc ::ashreplay::_get {dictionary key default} {
    if {[dict exists $dictionary $key]} {return [dict get $dictionary $key]}
    return $default
}

proc ::ashreplay::_epoch {value timezone} {
    if {$value eq ""} {return ""}
    if {[string is double -strict $value]} {return [_finite $value timestamp]}
    if {![regexp {^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})(\.\d+)?(Z|[+-]\d{2}(?::?\d{2})?)?$} $value -> day time fraction offset]} {
        error "Native ASH timestamp requires a recorded epoch"
    }
    if {$offset eq "Z"} {set offset +0000}
    if {[regexp {^[+-]\d{2}$} $offset]} {append offset 00}
    set offset [string map {: ""} $offset]
    if {$offset ne ""} {
        set seconds [clock scan "$day $time $offset" -format {%Y-%m-%d %H:%M:%S %z}]
    } else {
        set seconds [clock scan "$day $time" -format {%Y-%m-%d %H:%M:%S} -timezone $timezone]
    }
    if {$fraction ne ""} {set seconds [expr {$seconds + double($fraction)}]}
    return $seconds
}

proc ::ashreplay::_parts {id epoch} {
    variable contexts
    set context [dict get $contexts $id]
    if {$epoch eq ""} {return {"" ""}}
    set key [format %.6f $epoch]
    if {[dict exists $context parts $key]} {return [dict get $context parts $key]}
    set zone [dict get $context timezone]
    set integer [expr {wide(floor($epoch))}]
    set date [clock format $integer -timezone $zone -format {%Y-%m-%d}]
    set midnight [clock scan $date -format {%Y-%m-%d} -timezone UTC]
    set day [expr {$midnight / 86400 + 2440588}]
    lassign [clock format $integer -timezone $zone -format {%H %M %S}] h m s
    scan $h %d h; scan $m %d m; scan $s %d s
    set seconds [expr {$h*3600+$m*60+$s+($epoch-floor($epoch))}]
    return [list $day $seconds]
}

proc ::ashreplay::_to_char {id epoch format} {
    if {$epoch eq ""} {return ""}
    lassign [_parts $id $epoch] day seconds
    switch -- $format {
        J {return $day}
        SSSS {return [expr {wide(floor($seconds))}]}
        default {error "Unsupported desktop ASH timestamp format"}
    }
}

proc ::ashreplay::_to_days {id epoch} {
    if {$epoch eq ""} {return ""}
    return [expr {[lindex [_parts $id $epoch] 0] - 1721060}]
}

proc ::ashreplay::_seconds {id epoch} {
    if {$epoch eq ""} {return ""}
    return [lindex [_parts $id $epoch] 1]
}

proc ::ashreplay::_identity {value} {return $value}
proc ::ashreplay::_now {id} {variable contexts; return [dict get $contexts $id now]}
proc ::ashreplay::_ceil {value} {return [expr {ceil($value)}]}
proc ::ashreplay::_floor {value} {return [expr {floor($value)}]}
proc ::ashreplay::_trunc {value} {return [expr {double(wide($value))}]}
proc ::ashreplay::_greatest {left right} {return [expr {max($left,$right)}]}

proc ::ashreplay::_chart_bound {database day seconds timezone anchor {recorded_offset ""}} {
    _finite $day chart_day; _finite $seconds chart_seconds; _finite $anchor chart_anchor
    set origin [expr {$database eq "pg" ? 2440588 : 719528}]
    # Desktop coordinates are native day*86400+seconds, including midnight
    # rollover. Use the recorded point's zone offset to express those same
    # coordinates as UNIX seconds; do not rebucket or recalculate its AAS.
    if {$recorded_offset ne ""} {
        set zone_seconds [_finite $recorded_offset chart_utc_offset]
    } else {
        set offset [clock format [expr {wide(floor($anchor))}] -timezone $timezone -format %z]
        if {![regexp {^([+-])([0-9]{2})([0-9]{2})$} $offset -> sign hours minutes]} {
            error "ASH chart timezone offset is unavailable"
        }
        scan $hours %d hours; scan $minutes %d minutes
        set zone_seconds [expr {($hours*3600+$minutes*60)*($sign eq "+" ? 1 : -1)}]
    }
    return [expr {($day-$origin)*86400+$seconds-$zone_seconds}]
}

proc ::ashreplay::_pg_bound {day seconds timezone} {
    # The desktop sends J/SSSS strings to PostgreSQL to_timestamp. Tcl selects
    # the first occurrence during a repeated hour; PostgreSQL selects the one
    # after the transition. Enumerate the zone offsets adjacent to the date to
    # reproduce that parser choice, without using the sampled epoch as a hint.
    set wall [expr {($day-2440588)*86400+$seconds}]
    set text [clock format [expr {wide($wall)}] -timezone UTC -format {%Y-%m-%d %H:%M:%S}]
    set scanned [clock scan $text -timezone $timezone -format {%Y-%m-%d %H:%M:%S}]
    set candidates {}; set possible {}
    foreach delta {-172800 0 172800} {
        set offset [clock format [expr {$scanned+$delta}] -timezone $timezone -format %z]
        regexp {^([+-])([0-9]{2})([0-9]{2})$} $offset -> sign hours minutes
        scan $hours %d hours; scan $minutes %d minutes
        set candidate [expr {$wall-($hours*3600+$minutes*60)*($sign eq "+" ? 1 : -1)}]
        lappend possible $candidate
        if {[clock format [expr {wide($candidate)}] -timezone $timezone -format {%Y-%m-%d %H:%M:%S}] eq $text} {
            lappend candidates $candidate
        }
    }
    if {[llength $candidates]} {return [lindex [lsort -real $candidates] end]}
    # For a skipped local time PostgreSQL uses the pre-transition offset,
    # normalizing forwards. Tcl's negative-DST zones can normalize backwards.
    return [lindex [lsort -real $possible] end]
}

proc ::ashreplay::window {database begid endid begday begsec endday endsec timezone} {
    if {$database ni {pg mysql maria vsql}} {error "Unsupported ASH database"}
    foreach {name value} [list begin_sample_id $begid end_sample_id $endid begin_day $begday begin_seconds $begsec end_day $endday end_seconds $endsec] {_finite $value $name}
    # Extracted verbatim from the three desktop ash_details callbacks. The
    # unusual concatenated day/seconds counters are kept as desktop values.
    set native_begin [expr {$database eq "pg" ? [format "%06.0f %05.0f" $begday $begsec] : $begid-1}]
    set native_end [expr {$database eq "pg" ? [format "%06.0f %05.0f" $endday $endsec] : $endid}]
    set begcnt [format "%06.0f%05.0f" $begday $begsec]
    set endcnt [format "%06.0f%05.0f" $endday $endsec]
    set result [dict create native_begin $native_begin native_end $native_end begcnt $begcnt endcnt $endcnt \
        sesdelta [expr {$endcnt-$begcnt}] begin_sample_id $begid end_sample_id $endid delta [expr {$endid-$begid}]]
    if {$database ne "pg"} {
        dict set result begin $native_begin; dict set result end $native_end
    } elseif {$timezone ne ""} {
        lassign $native_begin day seconds
        scan $day %d day; scan $seconds %d seconds
        dict set result begin [_pg_bound $day $seconds $timezone]
        lassign $native_end day seconds
        scan $day %d day; scan $seconds %d seconds
        dict set result end [_pg_bound $day $seconds $timezone]
    }
    return $result
}

proc ::ashreplay::selection {database chart_rows timezone begin end} {
    _finite $begin pointer_begin; _finite $end pointer_end
    set points {}; set native_bounds {}
    foreach raw [lsort -command ::ashreplay::_chart_compare $chart_rows] {
        set row [_normal_row $raw]
        foreach column {first_day last_day beg_secs end_secs sample_id} {
            if {![dict exists $row $column]} {error "ASH chart selection requires captured native bucket coordinates"}
        }
        set begday [dict get $row first_day]; set begsec [dict get $row beg_secs]
        set endday [dict get $row last_day]; set endsec [dict get $row end_secs]
        # Same midnight normalization as ash_fetch, before its four points.
        if {$endsec > 86399} {set endsec [expr {$endsec-86400}]; incr endday}
        set id [dict get $row sample_id]
        set offset [_get $row _sample_utc_offset_seconds [_get $row _utc_offset_seconds ""]]
        set first [_chart_bound $database $begday $begsec $timezone $id $offset]
        set last [_chart_bound $database $endday $endsec $timezone $id $offset]
        set key [list $begday $begsec $endday $endsec]
        if {$key in $native_bounds} {continue}
        lappend native_bounds $key
        # ash_fetch inserts start-zero/start-value/end-value/end-zero. Equal
        # distance chooses the earliest stored point; duplicate points in a
        # bucket carry identical native coordinates and sample IDs.
        foreach tuple [list [list $first $id $begday $begsec] [list $first $id $begday $begsec] \
                [list $last $id $endday $endsec] [list $last $id $endday $endsec]] {lappend points $tuple}
    }
    if {![llength $points]} {error "ASH has no captured chart points to select"}
    set chosen {}
    foreach pointer [list $begin $end] {
        set distance Inf; set best 0; set index 0
        foreach point $points {
            set difference [expr {abs([lindex $point 0]-$pointer)}]
            if {$difference < $distance} {set distance $difference; set best $index}
            incr index
        }
        lappend chosen $best
    }
    lassign [lsort -integer $chosen] first last
    lassign [lindex $points $first] x begid begday begsec
    lassign [lindex $points $last] x endid endday endsec
    return [window $database $begid $endid $begday $begsec $endday $endsec $timezone]
}

proc ::ashreplay::_chart_compare {left right} {
    set left [_normal_row $left]; set right [_normal_row $right]
    foreach key {_poll_epoch} {
        set a [_get $left $key 0]; set b [_get $right $key 0]
        if {$a < $b} {return -1}; if {$a > $b} {return 1}
    }
    set a [_get $left _row_index [_get $left _native_row_index ""]]
    set b [_get $right _row_index [_get $right _native_row_index ""]]
    if {$a eq "" || $b eq ""} {set a [_get $left sample_id 0]; set b [_get $right sample_id 0]}
    if {$a < $b} {return -1}; if {$a > $b} {return 1}
    return 0
}

proc ::ashreplay::_dialect {database cursor sql} {
    # Only temporal syntax and numeric affinity are adapted. CASE, grouping,
    # window functions, native score expressions and predicates stay upstream.
    set map [list \
        {to_timestamp('$public(ash,beg)','J SSSS')} {$ash_begin} \
        {to_timestamp('$public(ash,end)','J SSSS')} {$ash_end} \
        {to_timestamp('$public(ash,starttime)','J SSSS')} {$ash_start} \
        {interval '$public(ash,bucket_secs) seconds'} {$ash_bucket} \
        {interval '$public(ash,loadhours) hours'} {($ash_loadhours*3600)} \
        {$public(ash,beg)} {$ash_begin} {$public(ash,end)} {$ash_end} \
        {$public(ash,starttime)} {$ash_start} {$public(ash,bucket_secs)} {$ash_bucket} \
        {$public(ashsql,bucket_secs)} {$ash_bucket} {$public(ash,loadhours)} {$ash_loadhours} \
        {$public(ash,where)} {ash_time >= $ash_begin AND ash_time <= $ash_end} \
        {$public(ash,eventid)} {wait_event = $ash_event_id}]
    if {$database eq "pg"} {
        lappend map {$public(ash,sqlid)} {queryid = $ash_sql_id} \
            {$public(ashsql,sqlovertimeid)} {queryid = $ash_sql_id} \
            {extract(epoch from max(ash_time)over()-min(ash_time)over())} {(max(ash_time)over()-min(ash_time)over())} \
            {extract(epoch from ash_time)} {ash_time} \
            {extract(epoch from sample_time)} {sample_time}
        set sql [string map $map $sql]
        # SQLite requires the projection name PostgreSQL derives from this CASE.
        set sql [string map [list {end), wait_event,} {end) as wait_event_type, wait_event,} {::numeric} {*1.0}] $sql]
        regsub -all -nocase {current_timestamp} $sql {ash_now()} sql
        regsub -all -nocase {to_char\(} $sql {ash_to_char(} sql
        regsub -all -nocase {ceil\(} $sql {ash_ceil(} sql
        regsub -all -nocase {trunc\(} $sql {ash_trunc(} sql
        # PostgreSQL DESC places SQL NULL before non-NULL; SQLite reverses it.
        regsub -all -nocase {ORDER BY (xact_start|calls) DESC LIMIT} $sql {ORDER BY \1 DESC NULLS FIRST LIMIT} sql
    } else {
        lappend map {$public(ash,sqlid)} {digest = $ash_sql_id} \
            {$public(ashsql,sqlovertimeid)} {digest = $ash_sql_id}
        set sql [string map $map $sql]
        regsub -all -nocase {DATE_SUB\(NOW\(\), INTERVAL \$ash_bucket SECOND\)} $sql {(ash_now()-$ash_bucket)} sql
        regsub -all -nocase {DATE_SUB\(NOW\(\), INTERVAL \$ash_loadhours HOUR\)} $sql {(ash_now()-$ash_loadhours*3600)} sql
        regsub -all -nocase {DATE_SUB\(sample_time, INTERVAL \$ash_loadhours HOUR\)} $sql {(sample_time-$ash_loadhours*3600)} sql
        regsub -all -nocase {UNIX_TIMESTAMP\(} $sql {ash_identity(} sql
        regsub -all -nocase {FROM_UNIXTIME\(} $sql {ash_identity(} sql
        regsub -all -nocase {TIME_TO_SEC\(} $sql {ash_seconds(} sql
        regsub -all -nocase {\mTIME\(} $sql {ash_identity(} sql
        regsub -all -nocase {TO_DAYS\(} $sql {ash_to_days(} sql
        regsub -all -nocase {\mNOW\(\)} $sql {ash_now()} sql
        regsub -all -nocase {CEILING\(} $sql {ash_ceil(} sql
        regsub -all -nocase {FLOOR\(} $sql {ash_floor(} sql
        regsub -all -nocase {COUNT\(\*\)/GREATEST} $sql {(COUNT(*)*1.0)/GREATEST} sql
        regsub -all -nocase {SUM_TIMER_WAIT/1000000000} $sql {(SUM_TIMER_WAIT*1.0)/1000000000} sql
    }
    if {[string first {$public(} $sql] >= 0} {error "Desktop ASH cursor has an unsupported substitution"}
    return $sql
}

proc ::ashreplay::_normal_row {row} {
    set result {}
    dict for {key value} $row {dict set result [string tolower $key] $value}
    return $result
}

proc ::ashreplay::_collation {id name left right} {
    variable contexts
    if {$left eq $right} {return 0}
    set keys [dict get $contexts $id weights $name]
    foreach value [list $left $right] {
        if {![dict exists $keys $value]} {
            # TclSQLite ignores exceptions raised by collation callbacks. Mark
            # the entire query invalid and discard its rows after execution.
            dict set contexts $id collation_error "ASH native collation '$name' has no recorded comparison key for a selected value"
            return 0
        }
    }
    return [string compare [dict get $keys $left] [dict get $keys $right]]
}

proc ::ashreplay::_like {id pattern value} {
    variable contexts
    if {$value eq ""} {return 0}
    if {![dict exists $contexts $id likes $pattern $value]} {
        error "ASH native LIKE predicate was not recorded for this source value"
    }
    return [dict get $contexts $id likes $pattern $value]
}

proc ::ashreplay::_collations {handle id samples stats metadata} {
    variable contexts
    set database [dict get $contexts $id database]
    set source [_get $metadata source_collation ""]
    if {$database eq "pg"} {
        # PostgreSQL deterministic collations distinguish different byte strings
        # for equality. Its count-only ORDER BY leaves equal-count ties unspecified.
        if {$source ni {binary deterministic}} {
            error "ASH PostgreSQL replay requires captured deterministic source collations; nondeterministic or unknown collations cannot be replayed faithfully"
        }
        return
    }
    if {$source eq "binary"} {
        # SQLite's default LIKE is ASCII-insensitive even on BINARY columns.
        $handle eval {PRAGMA case_sensitive_like=ON}
        return
    }
    set columns {sql_text wait_event command user host digest digest_text wait_event_type}
    set weights {}; set names {}; set likes {}
    foreach raw [concat $samples $stats] {
        set row [_normal_row $raw]
        foreach column $columns {
            if {![dict exists $row $column] || $column in [_get $row _nulls {}]} {continue}
            set value [dict get $row $column]
            if {![dict exists $row _collation_$column] || ![dict exists $row _weight_$column]} {
                error "ASH native collation and weight for '$column' were not captured; faithful replay is unavailable"
            }
            set name [dict get $row _collation_$column]
            if {$name eq ""} {error "ASH native collation for '$column' is unavailable"}
            set weight [string toupper [dict get $row _weight_$column]]
            if {![regexp {^(?:[0-9A-F]{2})*$} $weight]} {error "ASH native collation weight is invalid"}
            # WEIGHT_STRING alone retains trailing-space keys for PAD SPACE.
            # Capture records whether it used native RTRIM weights after a
            # native equality probe; never infer this from a collation name.
            if {![dict exists $row _pad_$column]} {
                error "ASH native padding semantics for '$column' were not captured"
            }
            if {[dict exists $weights $name $value] && [dict get $weights $name $value] ne $weight} {
                error "ASH native collation keys disagree across recorded snapshots"
            }
            dict set weights $name $value $weight
            dict set names $column $name 1
            if {$column eq "wait_event_type" && [dict exists $row _weight_cpu]} {
                dict set weights $name CPU [string toupper [dict get $row _weight_cpu]]
            }
        }
        dict for {key truth} $row {
            if {[regexp {^_like_([0-9a-f]+)$} $key -> hex]} {
                if {![dict exists $row wait_event_type] || "wait_event_type" in [_get $row _nulls {}]} {continue}
                if {$truth ni {0 1}} {error "ASH native LIKE result is invalid"}
                if {[catch {encoding convertfrom utf-8 [binary decode hex $hex]} pattern]} {error "ASH native LIKE pattern is invalid"}
                set value [dict get $row wait_event_type]
                if {[dict exists $likes $pattern $value] && [dict get $likes $pattern $value] ne $truth} {
                    error "ASH native LIKE results disagree across recorded snapshots"
                }
                dict set likes $pattern $value $truth
            }
        }
        dict for {column name} [_get $metadata comparison_collations {}] {
            if {$column ni {digest digest_text}} {error "Invalid ASH native comparison column"}
            if {![dict exists $row $column] || $column in [_get $row _nulls {}]} {continue}
            if {![dict exists $row _compare_weight_$column] || ![dict exists $row _compare_pad_$column]} {
                error "ASH native cross-collation comparison key for '$column' was not captured"
            }
            set weight [string toupper [dict get $row _compare_weight_$column]]
            if {![regexp {^(?:[0-9A-F]{2})*$} $weight]} {error "Invalid ASH native comparison weight"}
            set value [dict get $row $column]
            if {[dict exists $weights $name $value] && [dict get $weights $name $value] ne $weight} {
                error "ASH native comparison weights disagree"
            }
            dict set weights $name $value $weight
        }
    }
    dict set contexts $id weights $weights
    dict set contexts $id likes $likes
    set collations {}; set index 0
    dict for {name keys} $weights {
        set sqlname ash_native_[incr index]
        $handle collate $sqlname [list ::ashreplay::_collation $id $name]
        dict set collations $name $sqlname
    }
    dict set contexts $id collations $collations
    $handle function like [list ::ashreplay::_like $id]
}

proc ::ashreplay::_insert {handle table rows required id} {
    variable contexts
    set columns $required
    set normalized {}
    set database [dict get $contexts $id database]
    set timezone [dict get $contexts $id timezone]
    foreach row $rows {
        set row [_normal_row $row]
        dict for {key value} $row {
            if {[string index $key 0] ne "_" && $key ni $columns} {
                if {![regexp {^[a-z][a-z0-9_]*$} $key]} {error "Invalid archived ASH column"}
                lappend columns $key
            }
        }
        if {[dict exists $row ash_time]} {
            if {[dict exists $row _epoch]} {
                set epoch [_finite [dict get $row _epoch] sample_epoch]
            } else {
                set epoch [_epoch [dict get $row ash_time] $timezone]
            }
            dict set row ash_time $epoch
            if {[dict exists $row _day] && [dict exists $row _seconds]} {
                set day [_finite [dict get $row _day] sample_day]
                if {$database ne "pg"} {set day [expr {$day + 1721060}]}
                dict set contexts $id parts [format %.6f $epoch] [list $day [_finite [dict get $row _seconds] sample_seconds]]
            }
        }
        if {[dict exists $row xact_start] && [dict get $row xact_start] ne ""} {
            dict set row xact_start [_epoch [dict get $row xact_start] $timezone]
        }
        lappend normalized $row
    }
    set declarations {}
    set numeric {ash_time xact_start pid processlist_id calls total_exec_time rows shared_blks_hit shared_blks_read shared_blks_dirtied shared_blks_written local_blks_hit local_blks_read local_blks_dirtied local_blks_written temp_blks_read temp_blks_written blk_read_time blk_write_time plans total_plan_time wal_records wal_fpi wal_bytes count_star sum_timer_wait sum_rows_affected sum_rows_sent sum_rows_examined sum_created_tmp_tables sum_created_tmp_disk_tables sum_select_scan sum_select_full_join sum_sort_rows sum_no_index_used}
    foreach column $columns {
        set declaration "\"$column\" [expr {$column in $numeric ? "NUMERIC" : "TEXT"}]"
        set native {}
        foreach row $normalized {
            if {[dict exists $row _collation_$column] && [dict get $row _collation_$column] ni $native} {
                lappend native [dict get $row _collation_$column]
            }
        }
        if {[llength $native]} {
            if {[llength $native] != 1} {
                error "ASH source column '$column' changed collation; faithful historical replay is unavailable"
            }
            append declaration " COLLATE [dict get $contexts $id collations [lindex $native 0]]"
        }
        lappend declarations $declaration
    }
    $handle eval "CREATE TABLE $table ([join $declarations ,])"
    $handle transaction {
        foreach row $normalized {
            set names {}; set values {}; set index 0
            set nulls [_get $row _nulls {}]
            foreach column $columns {
                lappend names "\"$column\""
                if {![dict exists $row $column] || $column in $nulls} {
                    lappend values NULL
                } else {
                    set values_$index [dict get $row $column]
                    lappend values \$values_$index
                }
                incr index
            }
            $handle eval "INSERT INTO $table ([join $names ,]) VALUES ([join $values ,])"
        }
    }
}

proc ::ashreplay::_open {database samples stats metadata options} {
    variable serial
    variable contexts
    _provider $database
    set timezone [_get $metadata server_timezone ""]
    if {$timezone eq "" || $timezone eq "SYSTEM"} {error "ASH replay requires the captured server timezone"}
    # Validate timezone before reading potentially ambiguous native timestamps.
    if {[catch {clock format 0 -timezone $timezone}]} {error "ASH server timezone is unavailable for historical replay"}
    set begin [_get $options begin [_get $metadata run_start ""]]
    set end [_get $options end [_get $metadata run_end [_get $metadata server_now ""]]]
    _finite $begin begin; _finite $end end
    if {$begin > $end} {error "ASH selected window is reversed"}
    set now [_get $metadata server_now $end]
    _finite $now server_now
    set bucket [_get $metadata bucket_secs 15]
    if {![string is integer -strict $bucket] || $bucket < 1} {error "ASH bucket must be a positive integer"}
    foreach key {sql_id event_id session_id} {
        if {[dict exists $options $key] && [string length [dict get $options $key]] > 1024} {error "ASH selection identifier is too long"}
    }
    set id [incr serial]
    set handle ::ashreplay::db$id
    dict set contexts $id [dict create database $database timezone $timezone now $now parts {} begin $begin end $end bucket $bucket]
    sqlite3 $handle :memory:
    try {
        _collations $handle $id $samples $stats $metadata
        $handle function ash_now [list ::ashreplay::_now $id]
        $handle function ash_to_char [list ::ashreplay::_to_char $id]
        $handle function ash_to_days [list ::ashreplay::_to_days $id]
        $handle function ash_seconds [list ::ashreplay::_seconds $id]
        foreach {name command} {ash_identity _identity ash_ceil _ceil ash_floor _floor ash_trunc _trunc greatest _greatest} {
            $handle function $name [list ::ashreplay::$command]
        }
        set common {ash_time wait_event_type wait_event}
        if {$database eq "pg"} {
            _insert $handle pg_active_session_history $samples [concat $common {queryid query cmdtype backend_type pid usename application_name xact_start}] $id
            _insert $handle pg_stat_statements_history $stats {ash_time queryid calls total_exec_time rows shared_blks_hit shared_blks_read shared_blks_dirtied shared_blks_written local_blks_hit local_blks_read local_blks_dirtied local_blks_written temp_blks_read temp_blks_written blk_read_time blk_write_time plans total_plan_time wal_records wal_fpi wal_bytes} $id
        } else {
            $handle eval {ATTACH ':memory:' AS hammerdb_ash; ATTACH ':memory:' AS performance_schema}
            _insert $handle hammerdb_ash.active_session_history $samples [concat $common {digest digest_text sql_text command processlist_id user host}] $id
            # Desktop reads the entire current Performance Schema table. Use
            # the last complete captured snapshot, including an empty reset;
            # merging each digest's last appearance would resurrect evictions.
            set latest [_get $metadata stats_poll_epoch ""]
            if {$latest eq ""} {
                foreach raw $stats {
                    set row [_normal_row $raw]
                    set epoch [_get $row _poll_epoch [_get $row _epoch ""]]
                    if {$epoch ne ""} {_finite $epoch stats_epoch}
                    if {$epoch ne "" && ($latest eq "" || $epoch > $latest)} {set latest $epoch}
                }
            } else {_finite $latest stats_poll_epoch}
            if {$latest ne ""} {
                set snapshot {}
                foreach raw $stats {
                    set row [_normal_row $raw]
                    if {[_get $row _poll_epoch [_get $row _epoch ""]] eq $latest ||
                        ([_get $row _poll_epoch [_get $row _epoch ""]] ne "" && [_get $row _poll_epoch [_get $row _epoch ""]] == $latest)} {lappend snapshot $raw}
                }
                set stats $snapshot
            }
            _insert $handle performance_schema.events_statements_summary_by_digest $stats {digest digest_text count_star sum_timer_wait sum_rows_affected sum_rows_sent sum_rows_examined sum_created_tmp_tables sum_created_tmp_disk_tables sum_select_scan sum_select_full_join sum_sort_rows sum_no_index_used} $id
        }
    } on error {message error_options} {
        catch {$handle close}
        dict unset contexts $id
        return -options $error_options $message
    }
    return [list $id $handle]
}

proc ::ashreplay::_query {id handle database cursor metadata options} {
    variable contexts
    set context [dict get $contexts $id]
    set ash_begin [dict get $context begin]
    set ash_end [dict get $context end]
    set ash_bucket [dict get $context bucket]
    set ash_start [_get $metadata run_start $ash_begin]
    set ash_loadhours [expr {max(0.0,([dict get $context now]-$ash_start)/3600.0)}]
    set ash_sql_id [_get $options sql_id ""]
    set ash_event_id [_get $options event_id ""]
    set sql [_dialect $database $cursor [original_sql $database $cursor]]
    if {$database ne "pg" && $cursor eq "ash_sqlstats"} {
        dict for {column name} [_get $metadata comparison_collations {}] {
            if {![dict exists $contexts $id collations $name]} {continue}
            set collation [dict get $contexts $id collations $name]
            set upper [string toupper $column]
            set sql [string map [list "$upper IN (" "$upper COLLATE $collation IN ("] $sql]
        }
    }
    if {$ash_sql_id eq ""} {
        set column [expr {$database eq "pg" ? "queryid" : "digest"}]
        set sql [string map [list "$column = \$ash_sql_id" "$column IS NULL"] $sql]
    }
    set rows {}
    dict set contexts $id collation_error ""
    $handle eval $sql row {
        set result {}
        foreach column $row(*) {dict set result [string tolower $column] $row($column)}
        lappend rows $result
    }
    if {[dict get $contexts $id collation_error] ne ""} {error [dict get $contexts $id collation_error]}
    return $rows
}

proc ::ashreplay::query {database cursor samples stats metadata options} {
    variable contexts
    lassign [_open $database $samples $stats $metadata $options] id handle
    try {return [_query $id $handle $database $cursor $metadata $options]} finally {
        $handle close
        dict unset contexts $id
    }
}

proc ::ashreplay::percent {mode total denominator} {
    if {$denominator <= 0} {return ""}
    switch -- $mode {
        session {return [format {%3.0f} [expr {ceil(100 * $total / ($denominator))}]]}
        sql {return [format {%0.0f} [expr {100 * ($total+0.0)/$denominator}]]}
        event {return [format {%3.1f} [expr {$total * 100.0 / $denominator}]]}
        default {error "Unknown desktop ASH percentage calculation"}
    }
}

proc ::ashreplay::delta {begid endid bucket} {
    set delta [expr {$endid-$begid}]
    if {$delta == 0} {set delta $bucket}
    return $delta
}

proc ::ashreplay::event_group {database wait_event_type} {
    if {$database eq "pg"} {return $wait_event_type}
    # Exact case-sensitive display classification from ash_sqlevents_fetch.
    # This differs deliberately from the database SQL's native LIKE semantics.
    if { [string match "wait/synch/mutex*" $wait_event_type] } {
        return "Mutex"
    } elseif { [string match "wait/synch/rwlock*" $wait_event_type] } {
        return "RWLock"
    } elseif { [string match "wait/synch/cond*" $wait_event_type] } {
        return "Cond"
    } elseif { [string match "wait/synch/sxlock*" $wait_event_type] } {
        return "SXLock"
    } elseif { [string match "wait/io/file*" $wait_event_type] } {
        return "File_IO"
    } elseif { [string match "wait/io/table*" $wait_event_type] } {
        return "Table_IO"
    } elseif { [string match "wait/io/socket*" $wait_event_type] } {
        return "Network"
    } elseif { [string match "wait/lock*" $wait_event_type] } {
        return "Lock"
    } elseif { [string match "idle*" $wait_event_type] } {
        return "Idle"
    } elseif { $wait_event_type eq "CPU" } {
        return "CPU"
    } else {return "Other"}
}

proc ::ashreplay::stat_values {database row} {
    set row [_normal_row $row]
    if {$database eq "pg"} {
        set metrics {total_exec_time calls rows shared_blks_hit shared_blks_read shared_blks_dirtied shared_blks_written local_blks_hit local_blks_read local_blks_dirtied local_blks_written temp_blks_read temp_blks_written wal_records wal_fpi wal_bytes plans total_plan_time blk_read_time blk_write_time}
        set times {blk_write_time blk_read_time total_plan_time total_exec_time}
        set denominator rows
    } else {
        set metrics {total_exec_time calls rows_affected rows_sent rows_examined tmp_tables tmp_disk_tables select_scan select_full_join sort_rows no_index_used}
        set times {total_exec_time}
        set denominator rows_affected
    }
    foreach metric $times {dict set row $metric [format "%0.2f" [dict get $row $metric]]}
    set result {}
    foreach metric $metrics {
        set value [dict get $row $metric]
        if {[dict get $row calls] == 0} {set per_exec 0} else {
            set per_exec [format "%0.2f" [expr {$value/[dict get $row calls]}]]
        }
        if {[dict get $row $denominator] == 0} {set per_row 0} else {
            set per_row [format "%0.2f" [expr {$value/[dict get $row $denominator]}]]
        }
        lappend result [dict create statistic $metric total $value per_exec $per_exec per_row $per_row]
    }
    return $result
}

proc ::ashreplay::overtime_delta {id maxid bucket delta} {
    if {$id > $maxid} {
        if {$maxid == 0} {set delta $bucket} else {
            set newdelta [expr {$id-$maxid}]
            if {$newdelta != 0} {set delta $newdelta}
        }
        set maxid $id
    }
    return [list $maxid $delta]
}

proc ::ashreplay::overtime_aas {cnt delta {sample_seconds 1}} {
    # Weight native sample counts without changing the archived raw data.
    return [format "%6.3f" [expr {($cnt*double($sample_seconds))/max($delta,$sample_seconds)}]]
}
proc ::ashreplay::accumulate {aas curval} {return [expr {$aas+$curval}]}

proc ::ashreplay::_shares {rows denominator mode} {
    set result {}
    foreach row $rows {
        set total [_get $row total 0]
        dict set row percent [percent $mode $total $denominator]
        lappend result $row
    }
    return $result
}

proc ::ashreplay::report {database samples stats metadata options} {
    variable contexts
    lassign [_open $database $samples $stats $metadata $options] id handle
    try {
        set sql [_query $id $handle $database ash_sqldetails $metadata $options]
        set sessions [_query $id $handle $database ash_sqlsessions $metadata $options]
        set events [_query $id $handle $database ash_sqlevents $metadata $options]
        set display_events {}
        foreach row $events {
            dict set row group [event_group $database [dict get $row wait_event_type]]
            lappend display_events $row
        }
        set events $display_events
        set sql_total 0; foreach row $sql {incr sql_total [dict get $row total]}
        set event_total 0; foreach row $events {incr event_total [dict get $row total]}
        set begin [dict get $contexts $id begin]; set end [dict get $contexts $id end]
        if {[dict exists $options begin_sample_id] && [dict exists $options end_sample_id]} {
            set first [_finite [dict get $options begin_sample_id] begin_sample_id]
            set last [_finite [dict get $options end_sample_id] end_sample_id]
            set delta [delta $first $last [dict get $contexts $id bucket]]
        } else {set delta [delta [expr {ceil($begin)}] [expr {ceil($end)}] [dict get $contexts $id bucket]]}
        set chart [_get $metadata chart_rows {}]
        set limitations {}
        if {![dict exists $metadata chart_rows]} {
            # This is one recorded refresh only, never an invented historical grid.
            set chart [_query $id $handle $database ash $metadata $options]
            lappend limitations {Historical chart refresh rows were not captured; chart contains only the canonical query at recorded server_now.}
        }
        set selected_chart {}
        # The chart must never show sample intervals from a previous workload
        # that remained in the database server's shared ASH sampler. Historical
        # Jobs are isolated by jobid, and their displayed chart is also
        # bounded to THIS benchmark's recorded start/end timestamps.
        set job_start [_get $metadata run_start $begin]
        set job_end [_get $metadata run_end [_get $metadata server_now $end]]
        foreach row $chart {
            set row [_normal_row $row]
            if {[dict exists $row first_day] && [dict exists $row last_day] &&
                [dict exists $row beg_secs] && [dict exists $row end_secs]} {
                set anchor [_get $row sample_id [_get $row _poll_epoch $end]]
                set offset [_get $row _sample_utc_offset_seconds [_get $row _utc_offset_seconds ""]]
                dict set row begin [_chart_bound $database [dict get $row first_day] [dict get $row beg_secs] [dict get $contexts $id timezone] $anchor $offset]
                dict set row end [_chart_bound $database [dict get $row last_day] [dict get $row end_secs] [dict get $contexts $id timezone] $anchor $offset]
            }
            if {[dict exists $row begin] && [dict exists $row end]} {
                if {[dict get $row end] < $job_start || [dict get $row begin] > $job_end} continue
                dict set row begin [expr {max([dict get $row begin],$job_start)}]
                dict set row end [expr {min([dict get $row end],$job_end)}]
            }
            if {[dict exists $row wait_event_type]} {dict set row category [dict get $row wait_event_type]}
            lappend selected_chart $row
        }
        set io {}
        # The original Desktop SQL I/O cursor replays against the saved
        # native samples; do not generate a separate wait-class algorithm.
        if {[catch {set io [_query $id $handle $database sqlio $metadata $options]}]} {
            lappend limitations {Desktop SQL I/O query could not be replayed for this window.}
        }
        set result [dict create database $database begin $begin end $end bucket_secs [dict get $contexts $id bucket] \
            chart $selected_chart sql [_shares $sql $sql_total sql] sessions [_shares $sessions $delta session] \
            events [_shares $events $event_total event] sql_io $io \
            sql_text {} sql_stats {} sql_statistics {} event_sqls {} sql_overtime {} limitations $limitations]
        if {[dict exists $options sql_id]} {
            # Use the already reconstructed, selected Job-window SQLite handle
            # for all three original Desktop queries. Previously each SQL click
            # read every occurrence of the SQL ID from disk and rebuilt a
            # SECOND SQLite database, causing multi-second drilldown latency.
            set text_rows [_query $id $handle $database ash_sqltxt $metadata $options]
            dict set result sql_stats [_query $id $handle $database ash_sqlstats $metadata $options]
            dict set result sql_overtime [_query $id $handle $database sqlovertimeload $metadata $options]
            set text_column [expr {$database eq "pg" ? "query" : "sql_text"}]
            if {[llength $text_rows]} {dict set result sql_text [_get [lindex $text_rows 0] $text_column ""]} else {dict set result sql_text ""}
            if {[llength [dict get $result sql_stats]]} {dict set result sql_statistics [stat_values $database [lindex [dict get $result sql_stats] 0]]}
            set overtime {}; set maxid 0; set delta [dict get $contexts $id bucket]
            set sample_seconds [expr {$database eq "pg" ? 1 : 5}]
            foreach row [dict get $result sql_overtime] {
                lassign [overtime_delta [dict get $row last_id] $maxid [dict get $contexts $id bucket] $delta] maxid delta
                dict set row aas [overtime_aas [dict get $row cnt] $delta $sample_seconds]
                dict set row category [dict get $row wait_event_type]
                lappend overtime $row
            }
            dict set result sql_overtime $overtime
        }
        if {[dict exists $options event_id]} {dict set result event_sqls [_query $id $handle $database ash_eventsqls $metadata $options]}
        if {[dict exists $options session_id]} {
            set details {}
            foreach row $sessions {if {[dict get $row pid] eq [dict get $options session_id]} {lappend details $row}}
            dict set result session_details $details
            # A session may execute many SQL IDs. Keep their identities and
            # sampled counts distinct instead of pretending the session has
            # one SQL text or one SQL-statistics snapshot. The Jobs layer has
            # already restricted 'samples' to this session when detail_only.
            set sqlkey [expr {$database eq "pg" ? "queryid" : "digest"}]
            set statement_texts {}
            set statement_times {}
            foreach raw $samples {
                set sample [_normal_row $raw]
                set sqlid [_get $sample $sqlkey ""]
                set textcol [expr {$database eq "pg" ? "query" : "sql_text"}]
                set statement [_get $sample $textcol ""]
                set source $textcol
                if {$statement eq "" && $database ne "pg"} {
                    set statement [_get $sample digest_text ""]
                    set source digest_text
                }
                if {$statement eq ""} continue
                set epoch [_get $sample _epoch 0]
                if {![dict exists $statement_times $sqlid] || $epoch >= [dict get $statement_times $sqlid]} {
                    dict set statement_texts $sqlid [list $statement $source]
                    dict set statement_times $sqlid $epoch
                }
            }
            set statement_rows {}
            set statement_stats {}
            set display_limit 12
            set displayed 0
            foreach statement_row $sql {
                if {$displayed >= $display_limit} break
                set sqlid [_get $statement_row queryid ""]
                set entry [dict create queryid $sqlid total [_get $statement_row total 0] cmdtype [_get $statement_row cmdtype ""]]
                if {[dict exists $statement_texts $sqlid]} {
                    lassign [dict get $statement_texts $sqlid] statement source
                    dict set entry sql_text $statement
                    dict set entry text_source $source
                }
                lappend statement_rows $entry
                # Reuse native Desktop SQL-statistics cursor on the selected
                # archive's existing replay handle, not an estimated count.
                # Its snapshot is by SQL ID, never specific to one session.
                if {$sqlid ne ""} {
                    set sql_options [dict replace $options sql_id $sqlid]
                    # Missing/native-statistics failures must not prevent
                    # a session's saved activity and SQL text from opening.
                    catch {
                        set stat_rows [_query $id $handle $database ash_sqlstats $metadata $sql_options]
                        if {[llength $stat_rows]} {
                            foreach metric [stat_values $database [lindex $stat_rows 0]] {
                                dict set metric queryid $sqlid
                                lappend statement_stats $metric
                            }
                        }
                    }
                }
                incr displayed
            }
            dict set result session_sql $statement_rows
            dict set result session_sql_stats $statement_stats
            dict set result session_sql_count [llength $sql]
        }
        set originals {}
        foreach cursor {ash ash_sqldetails ash_sqlsessions ash_sqlevents ash_sqltxt ash_sqlstats ash_eventsqls sqlovertimeload} {
            dict set originals $cursor [original_sql $database $cursor]
        }
        dict set result original_sql $originals
        dict set result driver_cpucount [_get $metadata driver_cpucount ""]
        return $result
    } finally {
        $handle close
        dict unset contexts $id
    }
}

package provide ashreplay 1.0
