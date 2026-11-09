# Persistent copies of the existing database ASH sources, not a sampler.
package require sqlite3
package provide ashstore 1.0
namespace eval ashstore {
    namespace export init begin append append_snapshot finish rows metadata update_metadata delete

    proc init {db} {
        $db transaction {
            $db eval {
                CREATE TABLE IF NOT EXISTS JOBASH (
                    jobid TEXT NOT NULL,
                    source TEXT NOT NULL,
                    sample_key TEXT NOT NULL,
                    sample_time REAL NOT NULL,
                    row_order INTEGER NOT NULL DEFAULT 0,
                    sql_id TEXT,
                    session_id TEXT,
                    event_type TEXT,
                    event_name TEXT,
                    payload TEXT NOT NULL,
                    PRIMARY KEY(jobid, source, sample_key),
                    FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid)
                );
                CREATE INDEX IF NOT EXISTS JOBASH_TIME ON JOBASH(jobid,source,sample_time);
                CREATE INDEX IF NOT EXISTS JOBASH_SQL ON JOBASH(jobid,sql_id,sample_time);
                CREATE INDEX IF NOT EXISTS JOBASH_SOURCE_SQL ON JOBASH(jobid,source,sql_id,sample_time DESC);
                CREATE INDEX IF NOT EXISTS JOBASH_SOURCE_EVENT ON JOBASH(jobid,source,event_name,sample_time);
                CREATE INDEX IF NOT EXISTS JOBASH_SESSION ON JOBASH(jobid,session_id,sample_time);
                CREATE INDEX IF NOT EXISTS JOBASH_SOURCE_SESSION ON JOBASH(jobid,source,session_id,sample_time);
                CREATE TABLE IF NOT EXISTS JOBASHINFO (
                    jobid TEXT PRIMARY KEY,
                    database TEXT NOT NULL,
                    state TEXT NOT NULL,
                    started_at REAL NOT NULL,
                    ended_at REAL,
                    error TEXT NOT NULL DEFAULT '',
                    metadata TEXT NOT NULL,
                    FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid)
                );
            }
            if {![$db onecolumn {SELECT count(*) FROM pragma_table_info('JOBASH') WHERE name='row_order'}]} {
                $db eval {ALTER TABLE JOBASH ADD COLUMN row_order INTEGER NOT NULL DEFAULT 0}
            }
            $db eval {CREATE INDEX IF NOT EXISTS JOBASH_ORDER ON JOBASH(jobid,source,sample_time,row_order)}
            if {[$db onecolumn {SELECT count(*) FROM sqlite_master WHERE type='table' AND name='JOBCI'}]} {
                if {![$db onecolumn {SELECT count(*) FROM pragma_table_info('JOBCI') WHERE name='collect_ash'}]} {
                    $db eval {ALTER TABLE JOBCI ADD COLUMN collect_ash INTEGER NOT NULL DEFAULT 0}
                }
            }
        }
    }

    proc getfirst {record keys {default ""}} {
        foreach key $keys {
            if {[dict exists $record $key]} {return [dict get $record $key]}
        }
        return $default
    }

    proc begin {db jobid database metadata} {
        init $db
        if {![$db onecolumn {SELECT count(*) FROM JOBMAIN WHERE jobid=$jobid}]} {
            error "ASH requires an existing benchmark Job ID"
        }
        if {$database ni {pg mysql maria vsql}} {error "ASH is unavailable for this database"}
        set started [getfirst $metadata {run_start server_now} [expr {[clock milliseconds]/1000.0}]]
        $db eval {INSERT INTO JOBASHINFO(jobid,database,state,started_at,metadata)
                  VALUES($jobid,$database,'running',$started,$metadata)}
    }

    proc append {db jobid source records} {
        if {$source ni {samples sqlstats chart plans}} {error "Unknown ASH storage source"}
        if {![llength $records]} {return 0}
        # Validate the entire batch before writing any part of it. A malformed
        # transfer must not silently turn a partially stored batch into success.
        set batch {}
        set ordinal 0
        foreach record $records {
            if {[catch {dict size $record}]} {error "ASH transfer row must be a native column dictionary"}
            set sample_time [getfirst $record {_epoch _poll_epoch}]
            if {![string is double -strict $sample_time] || [catch {expr {abs($sample_time)<Inf}} finite] || !$finite} {
                error "ASH transfer requires its database timestamp in _epoch"
            }
            set sql_id [getfirst $record {queryid QueryID query_id digest}]
            set session_id [getfirst $record {pid processlist_id thread_id}]
            set event_type [getfirst $record {wait_event_type}]
            set event_name [getfirst $record {wait_event}]
            set row_order [getfirst $record {_native_row_index} $ordinal]
            if {![string is integer -strict $row_order] || $row_order < 0} {
                error "ASH transfer row order must be a nonnegative integer"
            }
            incr ordinal
            if {$source eq "chart"} {dict set record _native_row_index $row_order}
            # Native MySQL ash_id is exact. Other sources retain a canonical
            # full native row identity so overlapping exports are idempotent.
            if {$source eq "samples" && [dict exists $record ash_id]} {
                set key [dict get $record ash_id]
            } else {
                set native {}
                foreach name [lsort [dict keys $record]] {
                    if {$source eq "samples" && [string match _* $name] && $name ne "_nulls"} continue
                    dict set native $name [dict get $record $name]
                }
                set key $native
            }
            lappend batch [list $key $sample_time $row_order $sql_id $session_id $event_type $event_name $record]
        }
        set inserted 0
        $db transaction {
            if {![$db onecolumn {SELECT count(*) FROM JOBASHINFO WHERE jobid=$jobid}]} {
                error "ASH capture has not been initialized for this Job"
            }
            foreach values $batch {
                lassign $values sample_key sample_time row_order sql_id session_id event_type event_name payload
                $db eval {INSERT OR IGNORE INTO JOBASH
                    (jobid,source,sample_key,sample_time,row_order,sql_id,session_id,event_type,event_name,payload)
                    VALUES($jobid,$source,$sample_key,$sample_time,$row_order,$sql_id,$session_id,$event_type,$event_name,$payload)}
                incr inserted [$db changes]
            }
        }
        return $inserted
    }

    proc finish {db jobid {state complete} {error ""}} {
        if {$state ni {complete cancelled error failed}} {error "Invalid ASH capture completion state"}
        set ended [expr {[clock milliseconds]/1000.0}]
        set metadata [$db onecolumn {SELECT metadata FROM JOBASHINFO WHERE jobid=$jobid}]
        if {[dict exists $metadata run_end]} {
            set native_end [dict get $metadata run_end]
            if {![string is double -strict $native_end] ||
                [catch {expr {abs($native_end)<Inf}} finite] || !$finite} {
                error "ASH completion requires a finite native server timestamp"
            }
            set ended $native_end
        }
        $db eval {UPDATE JOBASHINFO SET state=$state,ended_at=$ended,error=$error
                  WHERE jobid=$jobid AND state='running'}
    }

    proc update_metadata {db jobid values} {
        $db transaction {
            set metadata [$db onecolumn {SELECT metadata FROM JOBASHINFO WHERE jobid=$jobid}]
            if {$metadata eq ""} {error "ASH capture has not been initialized for this Job"}
            set metadata [dict merge $metadata $values]
            set started [getfirst $metadata {run_start server_now}]
            $db eval {UPDATE JOBASHINFO SET metadata=$metadata,started_at=$started
                      WHERE jobid=$jobid AND state='running'}
        }
    }

    proc append_snapshot {db jobid source records values} {
        # SQLite's Tcl transaction command supports nested transactions. Keep
        # the completion marker atomic with the batch, even when it is empty.
        set inserted 0
        $db transaction {
            set inserted [append $db $jobid $source $records]
            update_metadata $db $jobid $values
        }
        return $inserted
    }

    proc rows {db jobid source {begin ""} {end ""}} {
        set values {}
        set query {SELECT payload FROM JOBASH WHERE jobid=$jobid AND source=$source}
        if {$begin ne ""} {::append query { AND sample_time >= $begin}}
        if {$end ne ""} {::append query { AND sample_time <= $end}}
        ::append query { ORDER BY sample_time, row_order, sample_key}
        $db eval $query row {lappend values $row(payload)}
        return $values
    }

    # Indexed retrieval for SQL/event/session drill-down. The SQL ID is kept
    # TEXT throughout; converting PostgreSQL 64-bit IDs to JS numbers loses
    # precision and must never happen here.
    proc rows_matching {db jobid begin end column value} {
        if {$column ni {sql_id event_name session_id}} {
            error "Unsupported ASH drill-down selector"
        }
        if {![string is double -strict $begin] || ![string is double -strict $end] || $begin > $end} {
            error "Invalid ASH drill-down window"
        }
        set results {}
        set query "SELECT payload FROM JOBASH WHERE jobid=\$jobid AND source='samples' AND \"$column\"=\$value AND sample_time>=\$begin AND sample_time<=\$end ORDER BY sample_time,row_order,sample_key"
        $db eval $query row {lappend results $row(payload)}
        return $results
    }

    proc metadata {db jobid} {
        set result {}
        $db eval {SELECT * FROM JOBASHINFO WHERE jobid=$jobid} row {
            set result $row(metadata)
            foreach key {jobid database state started_at ended_at error} {
                dict set result $key $row($key)
            }
            dict set result run_start $row(started_at)
            if {![dict exists $result run_end] && $row(ended_at) ne ""} {
                dict set result run_end $row(ended_at)
            }
        }
        return $result
    }

    proc delete {db jobid} {
        $db transaction {
            $db eval {DELETE FROM JOBASH WHERE jobid=$jobid;
                      DELETE FROM JOBASHINFO WHERE jobid=$jobid}
        }
    }
}
