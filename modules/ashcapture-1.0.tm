# Existing desktop ASH sampler and monitor lifecycle exposed to Jobs capture.
# No benchmark or replacement sampler is implemented here.
namespace eval ::ashcapture {
    variable module_file [info script]
    variable root [file dirname [file dirname [info script]]]
    variable coordinator ""
    variable statekey ""
    variable native_worker ""
    variable own_event 0
    variable changed_scheduler 0
    variable failed ""
}

proc ::ashcapture::mysql_database_sql {} {
    return {CREATE DATABASE IF NOT EXISTS hammerdb_ash}
}

proc ::ashcapture::mysql_table_sql {} {
    return {CREATE TABLE IF NOT EXISTS hammerdb_ash.active_session_history (
                                ash_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                ash_time DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                thread_id BIGINT,
                                processlist_id BIGINT,
                                user VARCHAR(128),
                                host VARCHAR(261),
                                db VARCHAR(64),
                                command VARCHAR(16),
                                state VARCHAR(64),
                                wait_event_type VARCHAR(64),
                                wait_event VARCHAR(128),
                                sql_text TEXT,
                                digest_text TEXT,
                                digest VARCHAR(64),
                                INDEX idx_ash_time (ash_time),
                                INDEX idx_wait_event_type (wait_event_type),
                                INDEX idx_digest (digest)
                            ) ENGINE=InnoDB}
}

proc ::ashcapture::mysql_event_sql {} {
    return {CREATE EVENT IF NOT EXISTS hammerdb_ash.ash_sampler
                                ON SCHEDULE EVERY 5 SECOND
                                DO
                                INSERT INTO hammerdb_ash.active_session_history
                                (thread_id, processlist_id, user, host, db, command, state,
                                 wait_event_type, wait_event, sql_text, digest_text, digest)
                                SELECT
                                  t.THREAD_ID,
                                  t.PROCESSLIST_ID,
                                  t.PROCESSLIST_USER,
                                  t.PROCESSLIST_HOST,
                                  t.PROCESSLIST_DB,
                                  t.PROCESSLIST_COMMAND,
                                  t.PROCESSLIST_STATE,
                                  COALESCE(w.EVENT_NAME, CASE WHEN t.PROCESSLIST_STATE IS NOT NULL AND t.PROCESSLIST_STATE != '' THEN 'CPU' ELSE 'idle' END),
                                  COALESCE(w.EVENT_NAME, CASE WHEN t.PROCESSLIST_STATE IS NOT NULL AND t.PROCESSLIST_STATE != '' THEN 'CPU' ELSE 'idle/waiting' END),
                                  LEFT(s.SQL_TEXT, 4096),
                                  COALESCE(s.DIGEST_TEXT, LEFT(s.SQL_TEXT, 4096)),
                                  s.DIGEST
                                FROM performance_schema.threads t
                                LEFT JOIN performance_schema.events_waits_current w
                                  ON t.THREAD_ID = w.THREAD_ID AND w.EVENT_NAME != 'idle' AND w.END_EVENT_ID IS NULL
                                LEFT JOIN performance_schema.events_statements_current s
                                  ON t.THREAD_ID = s.THREAD_ID
                                WHERE t.TYPE = 'FOREGROUND'
                                  AND t.PROCESSLIST_COMMAND != 'Sleep'
                                  AND t.PROCESSLIST_COMMAND != 'Daemon'
                                  AND t.PROCESSLIST_ID IS NOT NULL
                                  AND (s.SQL_TEXT IS NULL OR s.SQL_TEXT NOT LIKE '%hammerdb_ash%')}
}

# Shared verbatim MySQL-family desktop setup; strict mode adds validation only.
proc ::ashcapture::mysql_setup_impl {handle driver {strict 0} {reuse 0}} {
    if {$driver ni {mysql maria}} {error "Unsupported ASH connector"}
    set select ${driver}::sel
    set execute ${driver}::exec
    if {[lindex [$select $handle {SELECT @@performance_schema} -flatlist] 0] != 1} {
        error "ASH requires performance_schema=ON and a server restart"
    }
    set event_exists 0
    set scheduler "ON"
    if {$reuse} {
        set event_exists [lindex [$select $handle {SELECT COUNT(*) FROM information_schema.events WHERE EVENT_SCHEMA='hammerdb_ash' AND EVENT_NAME='ash_sampler'} -flatlist] 0]
        set scheduler [lindex [$select $handle {SELECT @@event_scheduler} -flatlist] 0]
    }
    $execute $handle [mysql_database_sql]
    $execute $handle [mysql_table_sql]
    foreach sql {
        {UPDATE performance_schema.setup_consumers SET ENABLED='YES' WHERE NAME IN ('events_waits_current', 'events_statements_current')}
        {UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES' WHERE NAME LIKE 'wait/%'}
        {UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES' WHERE NAME LIKE 'statement/%'}
    } {
        if {$strict} {$execute $handle $sql} else {catch {$execute $handle $sql}}
    }
    if {!$reuse || !$event_exists} {
        catch {$execute $handle {DROP EVENT IF EXISTS hammerdb_ash.ash_sampler}}
        $execute $handle [mysql_event_sql]
    }
    if {$strict} {
        if {![string equal -nocase $scheduler ON]} {
            $execute $handle {SET GLOBAL event_scheduler = ON}
        }
        set consumers [lindex [$select $handle {SELECT COUNT(*) FROM performance_schema.setup_consumers WHERE NAME IN ('events_waits_current','events_statements_current') AND ENABLED='YES'} -flatlist] 0]
        set instruments [lindex [$select $handle {SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE (NAME LIKE 'wait/%' OR NAME LIKE 'statement/%') AND (ENABLED!='YES' OR TIMED!='YES')} -flatlist] 0]
        set waits [lindex [$select $handle {SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'wait/%' AND ENABLED='YES' AND TIMED='YES'} -flatlist] 0]
        set statements [lindex [$select $handle {SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'statement/%' AND ENABLED='YES' AND TIMED='YES'} -flatlist] 0]
        set running [lindex [$select $handle {SELECT @@event_scheduler} -flatlist] 0]
        set event_ready [lindex [$select $handle {SELECT COUNT(*) FROM information_schema.events WHERE EVENT_SCHEMA='hammerdb_ash' AND EVENT_NAME='ash_sampler' AND STATUS='ENABLED' AND INTERVAL_VALUE='5' AND INTERVAL_FIELD='SECOND'} -flatlist] 0]
        if {$consumers != 2 || $instruments != 0 || $waits < 1 || $statements < 1 || ![string equal -nocase $running ON] || $event_ready != 1} {
            error "ASH Performance Schema consumers, instruments or five-second sampler are not operational"
        }
        if {$event_exists} {
            set definition [lindex [$select $handle {SELECT EVENT_DEFINITION FROM information_schema.events WHERE EVENT_SCHEMA='hammerdb_ash' AND EVENT_NAME='ash_sampler'} -flatlist] 0]
            set original [string range [mysql_event_sql] [string first INSERT [mysql_event_sql]] end]
            regsub -all {\s+} [string trimright [string trim $definition] {;}] { } definition
            regsub -all {\s+} [string trimright [string trim $original] {;}] { } original
            if {![string equal $definition $original]} {
                error "Existing ash_sampler differs from the desktop implementation; refusing replacement"
            }
        }
    } else {
        catch {$execute $handle {SET GLOBAL event_scheduler = ON}}
    }
    return [dict create own_event [expr {!$event_exists}] changed_scheduler [expr {$strict && ![string equal -nocase $scheduler ON]}]]
}

proc ::ashcapture::mysql_setup {handle driver {strict 0} {reuse 0}} {
    if {!$strict} {return [mysql_setup_impl $handle $driver 0 $reuse]}
    if {$driver ni {mysql maria}} {error "Unsupported ASH connector"}
    # Server instrumentation is shared, just as in the desktop monitor. A later
    # capture or desktop can reuse it, so stopping this Job never tears it down.
    return [mysql_setup_impl $handle $driver 1 $reuse]
}

# Preserve literal libpq values, including empty and quoted credentials.
proc ::ashcapture::pg_conninfo {host port sslmode user password database} {
    set result {}
    foreach key {host port sslmode user password dbname connect_timeout} value [list $host $port $sslmode $user $password $database 30] {
        set escaped [string map [list \\ \\\\ ' \\'] $value]
        lappend result "$key='$escaped'"
    }
    return [join $result { }]
}
# Activate the sourcebuilt/preloaded desktop extensions in this database.
proc ::ashcapture::pg_setup {handle} {
    foreach sql {{CREATE EXTENSION IF NOT EXISTS pg_stat_statements} {CREATE EXTENSION IF NOT EXISTS pgsentinel}} {
        set result [pg_exec $handle $sql]
        try {
            if {[pg_result $result -status] ne "PGRES_COMMAND_OK"} {
                error "PostgreSQL ASH extension activation failed"
            }
        } finally {pg_result $result -clear}
    }
}
proc ::ashcapture::enabled {} {
    if {![info exists ::env(HAMMERDB_ASH)]} {return 0}
    if {![string is boolean -strict $::env(HAMMERDB_ASH)]} {error "HAMMERDB_ASH must be boolean"}
    return [expr {!!$::env(HAMMERDB_ASH)}]
}
proc ::ashcapture::active {} {
    variable coordinator
    return [expr {$coordinator ne ""}]
}
proc ::ashcapture::threads {} {
    variable coordinator
    variable statekey
    set result {}
    if {$coordinator ne ""} {lappend result $coordinator}
    if {$statekey ne "" && [llength [info commands ::tsv::exists]] && [tsv::exists ashcapture worker,$statekey]} {
        lappend result [tsv::get ashcapture worker,$statekey]
    }
    return $result
}
proc ::ashcapture::database_path {} {
    foreach command {::hdbjobs ::jobs::hdbjobs} {
        if {![llength [info commands $command]]} {continue}
        foreach {sequence name path} [$command eval {PRAGMA database_list}] {
            if {$name eq "main" && $path ne "" && $path ne ":memory:"} {return $path}
        }
    }
    error "ASH requires an on-disk Jobs database for live capture"
}
proc ::ashcapture::configuration {} {
    if {![info exists ::rdbms] || ![info exists ::bm]} {error "ASH benchmark configuration is unavailable"}
    switch -- $::rdbms {
        PostgreSQL {set provider pg; set config configpostgresql}
        MySQL {set provider mysql; set config configmysql}
        MariaDB {set provider maria; set config configmariadb}
        VillageSQL {set provider vsql; set config configvillagesql}
        default {error "ASH is available for PostgreSQL, MySQL, MariaDB and VillageSQL"}
    }
    upvar #0 $config settings
    if {![info exists settings]} {error "ASH database configuration is unavailable"}
    set group [expr {$::bm eq "TPC-C" ? "tpcc" : "tpch"}]
    set connection [dict merge [dict get $settings connection] [dict get $settings $group]]
    set result [dict create provider $provider database $::rdbms]
    foreach name {host port} {dict set result $name [dict get $connection ${provider}_$name]}
    if {$provider eq "pg"} {
        set prefix [expr {$group eq "tpcc" ? "pg_" : "pg_tpch_"}]
        dict set result user [dict get $connection ${prefix}superuser]
        dict set result password [dict get $connection ${prefix}superuserpass]
        dict set result db [dict get $connection ${prefix}defaultdbase]
        dict set result sslmode [dict get $connection pg_sslmode]
    } else {
        set prefix [expr {$group eq "tpcc" ? "${provider}_" : "${provider}_tpch_"}]
        dict set result user [dict get $connection ${prefix}user]
        dict set result password [dict get $connection ${prefix}pass]
        dict set result db [dict get $connection ${prefix}dbase]
        dict set result socket [dict get $connection ${provider}_socket]
        check_${provider}_ssl $settings
        dict set result ssl_options [set ::${provider}_ssl_options]
    }
    return $result
}
proc ::ashcapture::start {jobid {explicit 0}} {
    variable coordinator
    variable statekey
    variable module_file
    variable root
    if {!$explicit && ![enabled]} {return}
    if {[active]} {error "An ASH Job is already active in this interpreter"}
    package require Thread
    package require ashstore 1.0
    set config [configuration]
    set path [database_path]
    set statekey "[pid]-[clock clicks]"
    set coordinator [thread::create {thread::wait}]
    set init [list apply {{module paths tm_paths} {
        set ::auto_path $paths
        ::tcl::tm::path add {*}$tm_paths
        source $module
    }} $module_file $::auto_path [::tcl::tm::path list]]
    # Issue #967: a nested event loop while TclReadLine stdin remains
    # readable allows pressing Return to invoke the CLI recursively. Suspend
    # only the existing stdin handler while checking native ASH readiness.
    # Python mode has no TclReadLine handler, and Tk events still run normally.
    set stdin_handler ""
    set stdin_suspended 0
    if {![catch {set stdin_handler [fileevent stdin readable]}] && $stdin_handler ne ""} {
        fileevent stdin readable {}
        set stdin_suspended 1
    }
    try {
        thread::send $coordinator $init
        thread::send -async $coordinator [list ::ashcapture::bootstrap $path $jobid $config $statekey]
        set deadline [expr {[clock milliseconds]+45000}]
        while {![tsv::exists ashcapture ready,$statekey]} {
            if {[clock milliseconds]>$deadline || ![thread::exists $coordinator]} {
                error "ASH readiness timed out before benchmark execution"
            }
            after 10
            update
        }
        set ready [tsv::get ashcapture ready,$statekey]
        if {$ready ne "ready"} {
            if {[tsv::exists ashcapture error,$statekey]} {error [tsv::get ashcapture error,$statekey]}
            error "ASH instrumentation or capture startup failed before benchmark execution"
        }
        # The workload determines VU positions from thread::names in each
        # interpreter. Publish our coordinator/native IDs to every VU before
        # running any workload script, so findvuposition never counts ASH
        # background threads as virtual users or waits for their timings.
        set ash_threads [threads]
        if {[llength $ash_threads] != 2} {
            error "ASH capture did not publish both background thread IDs"
        }
        tsv::set application ashcapture_threads $ash_threads
    } on error {message options} {
        catch {stop failed}
        return -options $options $message
    } finally {
        if {$stdin_suspended} {
            catch {fileevent stdin readable $stdin_handler}
        }
    }
    return $jobid
}
proc ::ashcapture::stop {{state complete}} {
    variable coordinator
    variable statekey
    if {$coordinator eq ""} {return}
    if {$state ni {complete failed cancelled error}} {error "Invalid ASH terminal state"}
    set worker $coordinator
    set key $statekey
    set coordinator ""
    set statekey ""
    # Do not remove ASH's VU-exclusion marker yet: ashstop may be called
    # while GUI virtual users are still running. Keep their positions stable
    # until BOTH ASH infrastructure threads have been released.
    set failure ""
    if {[thread::exists $worker]} {
        if {[catch {thread::send $worker [list ::ashcapture::shutdown $state]} message]} {
            set failure "ASH final capture or cleanup failed"
        }
        catch {thread::release $worker}
    } else {set failure "ASH coordinator stopped unexpectedly"}
    if {[tsv::exists ashcapture error,$key]} {set failure [tsv::get ashcapture error,$key]}
    if {[tsv::exists ashcapture worker,$key]} {
        set native [tsv::get ashcapture worker,$key]
        if {[thread::exists $native]} {catch {thread::release $native}}
    }
    # Both ASH threads are gone: future virtual-user accounting may now
    # safely return to the original, unmodified thread list.
    catch {tsv::unset application ashcapture_threads}
    foreach name [list worker,$key ready,$key error,$key] {
        if {[tsv::exists ashcapture $name]} {tsv::unset ashcapture $name}
    }
    if {$failure ne ""} {error $failure}
}

# Coordinator thread: one existing native database worker and its existing loop.
proc ::ashcapture::bootstrap {path jobid config key} {
    variable root
    variable native_worker
    variable statekey
    variable failed
    set statekey $key
    set failed ""
    set ::ashcapture::jobid $jobid
    set ::ashcapture::database [dict get $config provider]
    set ::ashcapture::provider [dict get $config provider]
    set ::ashcapture::last_id 0
    set ::ashcapture::last_epoch 0
    set ::ashcapture::batch {}
    set ::ashcapture::poll_times {}
    set ::ashcapture::sample_offsets {}
    set ::ashcapture::pending_chart {}
    set ::ashcapture::offset_changed 0
    set ::ashcapture::end_predicate {}
    set stage {Jobs storage initialization}
    try {
        package require sqlite3
        package require ashstore 1.0
        sqlite3 ::ashcapture::store $path
        ::ashcapture::store timeout 30000
        ashstore::init ::ashcapture::store
        ashstore::begin ::ashcapture::store $jobid [dict get $config provider] [dict create bucket_secs 15 collector desktop existing_sampler 1]
        set provider [dict get $config provider]
        switch -- $provider {
            pg {set ns pgmet; set file postgresql/pgmet.tcl; set factory pg_dbmon_thread_init; set logon pg_logon}
            maria {set ns mariamet; set file mariadb/mariamet.tcl; set factory maria_dbmon_thread_init; set logon maria_logon}
            default {set ns mysqlmet; set file mysql/mysqlmet.tcl; set factory mysql_dbmon_thread_init; set logon mysql_logon}
        }
        set ::ashcapture::ns $ns
        uplevel #0 [list source [file join $root src $file]]
        namespace eval :: [list namespace import ::${ns}::*]
        # Public callbacks are renderer-neutral here; desktop imports remain untouched.
        foreach name {callback_connect callback_err callback_fetch callback_mesg putsm} {
            rename ::$name {}
        }
        proc ::callback_connect {type handle} {set ::public(handle) $handle; set ::public(connected) 1}
        proc ::callback_err {args} {set ::public(connected) err; set ::ashcapture::failed "ASH database operation failed"}
        proc ::callback_fetch {cursor fetch} {::ashcapture::receive $cursor}
        proc ::callback_mesg {args} {}
        proc ::putsm {args} {}
        ${ns}::$factory
        set native_worker $::dbmon_threadID
        tsv::set ashcapture worker,$key $native_worker
        thread::send $native_worker [list set ::auto_path $::auto_path]
        thread::send $native_worker [list ::tcl::tm::path add {*}[::tcl::tm::path list]]
        thread::send $native_worker {set ::tpublic(ashcapture) 1}
        set parent [thread::id]
        set ::public(parent) $parent
        set args [list $parent [dict get $config host] [dict get $config port]]
        if {$provider eq "pg"} {
            lappend args [dict get $config sslmode] [dict get $config user] [dict get $config password] [dict get $config db] default
        } else {
            lappend args [dict get $config socket] [dict get $config ssl_options] [dict get $config user] [dict get $config password] [dict get $config db] capture
        }
        set stage {native driver connection and extension activation}
        thread::send -async $native_worker [list $logon {*}$args]
        after 30000 {if {$::public(connected)==0} {set ::public(connected) err}}
        if {$::public(connected)==0} {vwait ::public(connected)}
        if {$::public(connected) ne "1"} {error "ASH native database connection failed"}
        set ::public(ashcapture) 1
        set ::public(run) 1
        set ::public(sleep,fast) 15
        set ::public(sleep,slow) 60
        set ::public(slow_cur) 0
        set ::public(ash,bucket_secs) 15
        set ::public(ash,loadhours) 2
        set stage {ASH prerequisite validation}
        if {$provider ne "pg"} {
            set driver [expr {$provider eq "maria" ? "maria" : "mysql"}]
            thread::send $native_worker {package require ashcapture 1.0}
            set ownership [thread::send $native_worker [list ::ashcapture::mysql_setup $::public(handle) $driver 1 1]]
            dict with ownership {}
            set ::ashcapture::own_event $own_event
            set ::ashcapture::changed_scheduler $changed_scheduler
            if {$provider eq "maria"} {set_mariacursors} else {set_mysqlcursors}
            set comparison [thread::send $native_worker [list apply {{handle driver} {
                set names [${driver}::sel $handle {SELECT COLLATION(CONCAT((SELECT digest FROM hammerdb_ash.active_session_history LIMIT 1),(SELECT DIGEST FROM performance_schema.events_statements_summary_by_digest LIMIT 1))), CHARSET(CONCAT((SELECT digest FROM hammerdb_ash.active_session_history LIMIT 1),(SELECT DIGEST FROM performance_schema.events_statements_summary_by_digest LIMIT 1))), COLLATION(CONCAT((SELECT digest_text FROM hammerdb_ash.active_session_history LIMIT 1),(SELECT DIGEST_TEXT FROM performance_schema.events_statements_summary_by_digest LIMIT 1))), CHARSET(CONCAT((SELECT digest_text FROM hammerdb_ash.active_session_history LIMIT 1),(SELECT DIGEST_TEXT FROM performance_schema.events_statements_summary_by_digest LIMIT 1)))} -flatlist]
                set result {}
                foreach field {digest digest_text} {collation charset} $names {
                    if {![regexp {^[A-Za-z0-9_]+$} $collation]} {error "Native ASH comparison collation unavailable"}
                    if {![regexp {^[A-Za-z0-9_]+$} $charset]} {error "Native ASH comparison character set unavailable"}
                    dict set result $field [dict create collation $collation charset $charset]
                }
                return $result
            }} $::public(handle) $driver]]
            set ::ashcapture::comparison $comparison
            set names {}
            dict for {field values} $comparison {dict set names $field [dict get $values collation]}
            ashstore::update_metadata ::ashcapture::store $jobid [dict create comparison_collations $names]
        } else {
            thread::send $native_worker [list apply {{handle} {
                set valid 0
                pg_select $handle {SELECT (SELECT count(*)=2 FROM pg_extension WHERE extname IN ('pg_stat_statements','pgsentinel')) AND current_setting('pgsentinel_pgssh.enable',true)::boolean AND current_setting('pgsentinel_ash.sampling_period',true)::numeric > 0 AND EXISTS (SELECT 1 FROM pg_stat_activity WHERE backend_type ILIKE '%pgsentinel%') AS ready} row {set valid $row(ready)}
                if {$valid ne "t" && $valid ne "1"} {error "PostgreSQL ASH extensions, collector or statement history are not operational"}
            }} $::public(handle)]
            set source_collation [thread::send $native_worker [list apply {{handle} {
                set deterministic 0
                pg_select $handle {SELECT NOT EXISTS (SELECT 1 FROM pg_attribute a JOIN pg_collation c ON c.oid=a.attcollation WHERE a.attrelid='pg_active_session_history'::regclass AND NOT c.collisdeterministic) AS deterministic} row {set deterministic $row(deterministic)}
                return [expr {$deterministic in {t 1} ? "deterministic" : "nondeterministic"}]
            }} $::public(handle)]]
            ashstore::update_metadata ::ashcapture::store $jobid [dict create source_collation $source_collation]
            set_pgcursors
        }
        set stage {native metadata and transfer queries}
        setup_queries
        set ::public(cursor,capture_samples) fast
        set ::public(cursor,capture_stats) slow
        set ::public(cursor,ash) fast
        # Initial server clock/watermark is obtained before VUs are released.
        before_poll
        set ::ashcapture::run_start $::ashcapture::poll_epoch
        set ::ashcapture::last_epoch $::ashcapture::run_start
        set ::public(ash,sample_id) [expr {ceil($::ashcapture::run_start)-1}]
        update_predicates
        ${ns}::get_cpucount
        if {![info exists ::public(cpucount)]} {set ::public(cpucount) ""}
        set metadata [dict merge [ashstore::metadata ::ashcapture::store $jobid] $::ashcapture::clock_metadata [dict create run_start $::ashcapture::run_start bucket_secs 15 driver_host_cpucount $::public(cpucount) driver_cpucount $::public(cpucount) collector desktop existing_sampler 1]]
        ashstore::update_metadata ::ashcapture::store $jobid $metadata
        ${ns}::mon_loop
        if {$failed ne ""} {error $failed}
        tsv::set ashcapture ready,$key ready
    } on error {message options} {
        set failed "ASH $::ashcapture::provider capture startup failed during $stage: $message"
        puts stderr $failed
        tsv::set ashcapture error,$key $failed
        catch {shutdown failed}
        tsv::set ashcapture ready,$key failed
    }
}
proc ::ashcapture::setup_queries {} {
    variable provider
    set nullcols {thread_id processlist_id user host db command state wait_event_type wait_event sql_text digest_text digest}
    if {$provider eq "pg"} {
        set ::public(sql,capture_clock) {SELECT EXTRACT(EPOCH FROM clock_timestamp()) AS _epoch, current_setting('TimeZone') AS timezone, EXTRACT(TIMEZONE FROM CURRENT_TIMESTAMP) AS utc_offset_seconds}
        set ::public(sql,capture_samples) {SELECT ash.*, EXTRACT(EPOCH FROM ash.ash_time) AS _epoch, TO_CHAR(ash.ash_time,'J') AS _day, TO_CHAR(ash.ash_time,'SSSS') AS _seconds, (SELECT string_agg(key, ',') FROM json_each(row_to_json(ash)) WHERE value::text='null') AS _nulls_csv FROM pg_active_session_history ash WHERE EXTRACT(EPOCH FROM ash.ash_time) >= $::ashcapture::last_epoch $::ashcapture::end_predicate ORDER BY ash.ash_time}
        set ::public(sql,capture_stats) {SELECT stats.*, EXTRACT(EPOCH FROM clock_timestamp()) AS _epoch, (SELECT string_agg(key, ',') FROM json_each(row_to_json(stats)) WHERE value::text='null') AS _nulls_csv FROM pg_stat_statements_history stats}
    } else {
        set ::public(sql,capture_clock) {SELECT UNIX_TIMESTAMP(NOW(6)) AS _epoch, @@session.time_zone AS timezone, @@system_time_zone AS system_timezone, TIMESTAMPDIFF(SECOND,UTC_TIMESTAMP(),NOW()) AS utc_offset_seconds, @@collation_connection AS collation_connection, @@collation_server AS collation_server}
        set nulls {}
        foreach col $nullcols {lappend nulls "IF(ash.$col IS NULL,'$col',NULL)"}
        set nullsql "CONCAT_WS(',',[join $nulls ,])"
        set weights {}
        foreach col {sql_text wait_event command user host digest digest_text wait_event_type} {
            lappend weights {*}[mysql_text_metadata ash $col]
        }
        lappend weights "HEX(WEIGHT_STRING(CONCAT(COALESCE(LEFT(ash.wait_event_type,0),''),'CPU'))) AS _weight_cpu"
        # Transfer native predicate truth from the authoritative query catalog.
        set patterns {}
        foreach key [array names ::public sql,*] {
            foreach {match pattern} [regexp -all -inline {wait_event_type\s+LIKE\s+'([^']+)'} $::public($key)] {
                if {$pattern ni $patterns} {lappend patterns $pattern}
            }
        }
        foreach pattern $patterns {
            set hex [binary encode hex [encoding convertto utf-8 $pattern]]
            lappend weights "(ash.wait_event_type LIKE '$pattern') AS _like_$hex"
        }
        foreach col {digest digest_text} {lappend weights {*}[mysql_comparison_metadata ash $col]}
        set weightsql [join $weights ,]
        set ::public(sql,capture_samples) "SELECT ash.*, UNIX_TIMESTAMP(ash.ash_time) AS _epoch, TO_DAYS(ash.ash_time) AS _day, TIME_TO_SEC(TIME(ash.ash_time)) AS _seconds, ((TO_DAYS(ash.ash_time)-719528)*86400+TIME_TO_SEC(TIME(ash.ash_time))-UNIX_TIMESTAMP(ash.ash_time)) AS _utc_offset_seconds, $nullsql AS _nulls_csv, $weightsql FROM hammerdb_ash.active_session_history ash WHERE ash.ash_id > \$::ashcapture::last_id AND UNIX_TIMESTAMP(ash.ash_time) >= \$::ashcapture::run_start \$::ashcapture::end_predicate ORDER BY ash.ash_id"
        set statmeta {}
        foreach col {DIGEST DIGEST_TEXT} {lappend statmeta {*}[mysql_text_metadata stats $col] {*}[mysql_comparison_metadata stats $col]}
        set ::public(sql,capture_stats) "SELECT stats.*, UNIX_TIMESTAMP(NOW(6)) AS _epoch, [join $statmeta ,], CONCAT_WS(',',IF(stats.DIGEST IS NULL,'DIGEST',NULL),IF(stats.DIGEST_TEXT IS NULL,'DIGEST_TEXT',NULL),IF(stats.SCHEMA_NAME IS NULL,'SCHEMA_NAME',NULL)) AS _nulls_csv FROM performance_schema.events_statements_summary_by_digest stats"
    }
}
# String weights and padding behavior are evaluated by the source server under
# the actual column collation. Raw strings are retained unchanged.
proc ::ashcapture::mysql_text_metadata {table column} {
    set col "$table.$column"
    set name [string tolower $column]
    set empty "COALESCE(LEFT($col,0),'')"
    set pad "(CONCAT($empty,'x') = CONCAT($empty,'x '))"
    return [list "HEX(WEIGHT_STRING(CASE WHEN $pad THEN RTRIM($col) ELSE $col END)) AS _weight_$name" "COLLATION($col) AS _collation_$name" "$pad AS _pad_$name"]
}
proc ::ashcapture::mysql_comparison_metadata {table column} {
    variable comparison
    set name [string tolower $column]
    set meta [dict get $comparison $name]
    set col "(CONVERT($table.$column USING [dict get $meta charset]) COLLATE [dict get $meta collation])"
    set empty "COALESCE(LEFT($col,0),'')"
    set pad "(CONCAT($empty,'x') = CONCAT($empty,'x '))"
    return [list "HEX(WEIGHT_STRING(CASE WHEN $pad THEN RTRIM($col) ELSE $col END)) AS _compare_weight_$name" "$pad AS _compare_pad_$name"]
}
proc ::ashcapture::before_poll {} {
    variable ns
    variable failed
    if {$failed ne ""} {set ::public(run) 0; return}
    ${ns}::mon_execute capture_clock
}
proc ::ashcapture::update_predicates {} {
    variable provider
    if {$provider eq "pg"} {
        set ::public(ash,where) "ceil(extract(epoch from ash_time)) > $::public(ash,sample_id)"
    } else {
        set ::public(ash,where) "CEILING(UNIX_TIMESTAMP(ash_time)) > $::public(ash,sample_id)"
    }
}
proc ::ashcapture::receive {cursor} {
    variable failed
    variable ns
    variable provider
    variable statekey
    set name [string range $cursor 5 end]
    try {
        if {[tsv::exists fetched error,$cursor]} {
            set native_error [tsv::get fetched error,$cursor]
            tsv::unset fetched error,$cursor
            error $native_error
        }
        set records [tsv::get fetched $cursor]
        if {$name eq "capture_clock"} {
            if {[llength $records]!=1 || ![dict exists [lindex $records 0] _epoch]} {error "ASH server clock is unavailable"}
            set ::ashcapture::poll_epoch [dict get [lindex $records 0] _epoch]
            set clock [lindex $records 0]
            if {$provider ne "pg" && [info exists ::ashcapture::clock_metadata] && [dict get $clock utc_offset_seconds] != [dict get $::ashcapture::clock_metadata utc_offset_seconds]} {
                set ::ashcapture::offset_changed 1
            }
            dict set clock timezone_offset_changed $::ashcapture::offset_changed
            set timezone [dict get $clock timezone]
            if {$provider ne "pg" && $timezone eq "SYSTEM"} {
                set offset [dict get $clock utc_offset_seconds]
                set timezone [format {%s%02d:%02d} [expr {$offset<0 ? "-" : "+"}] [expr {abs($offset)/3600}] [expr {(abs($offset)%3600)/60}]]
            }
            dict set clock server_timezone $timezone
            dict set clock server_now $::ashcapture::poll_epoch
            set ::ashcapture::clock_metadata $clock
            lappend ::ashcapture::poll_times $::ashcapture::poll_epoch
            ashstore::update_metadata ::ashcapture::store $::ashcapture::jobid [dict merge $clock [dict create poll_times $::ashcapture::poll_times]]
        } elseif {$name in {ash capture_samples capture_stats}} {
            set rows {}
            set ordinal 0
            foreach row $records {
                if {$name eq "ash"} {dict set row _row_index $ordinal; incr ordinal}
                if {[dict exists $row _nulls_csv]} {
                    set csv [dict get $row _nulls_csv]
                    dict unset row _nulls_csv
                    dict set row _nulls [expr {$csv eq "" ? {} : [split $csv ,]}]
                }
                dict set row _poll_epoch $::ashcapture::poll_epoch
                if {![dict exists $row _utc_offset_seconds]} {
                    dict set row _utc_offset_seconds [dict get $::ashcapture::clock_metadata utc_offset_seconds]
                }
                if {![dict exists $row _epoch]} {dict set row _epoch $::ashcapture::poll_epoch}
                if {$name eq "ash" && [dict exists $row sample_id] && [dict get $row sample_id]>$::public(ash,sample_id)} {
                    set ::public(ash,sample_id) [dict get $row sample_id]
                }
                if {$name eq "capture_samples"} {
                    if {$provider ne "pg"} {
                        if {[dict get $row ash_id]>$::ashcapture::last_id} {set ::ashcapture::last_id [dict get $row ash_id]}
                        if {[dict exists $row _day] && [dict exists $row _seconds]} {
                            set key [list [expr {wide(ceil([dict get $row _epoch]))}] [dict get $row _day] [expr {double([dict get $row _seconds])}]]
                            dict set ::ashcapture::sample_offsets $key [dict get $row _utc_offset_seconds]
                        }
                    }
                    if {$provider eq "pg" && [dict get $row _epoch]>$::ashcapture::last_epoch} {set ::ashcapture::last_epoch [dict get $row _epoch]}
                }
                lappend rows $row
            }
            set source [dict get {ash chart capture_samples samples capture_stats sqlstats} $name]
            if {$source eq "chart" && $provider ne "pg"} {
                # The native chart can arrive before the raw cursor in this
                # same original poll; annotate only after both have completed.
                set ::ashcapture::pending_chart $rows
            } elseif {$source eq "sqlstats" && $provider ne "pg"} {
                ashstore::append_snapshot ::ashcapture::store $::ashcapture::jobid $source $rows [dict create stats_poll_epoch $::ashcapture::poll_epoch]
            } else {
                ashstore::append ::ashcapture::store $::ashcapture::jobid $source $rows
            }
            if {$name eq "ash"} {update_predicates}
        }
    } on error {message options} {
        set failed "ASH $provider $name transfer failed: $message"
        puts stderr $failed
        set ::public(run) 0
        tsv::set ashcapture error,$statekey $failed
        catch {ashstore::finish ::ashcapture::store $::ashcapture::jobid failed $failed}
    } finally {
        ${ns}::unlock public(thread_actv) ashcapture
    }
}
# Called once by the original monitor after its native cursors have completed.
# Relate each unchanged chart point to the raw source timestamp that produced it;
# this preserves source wall-clock buckets across a SYSTEM timezone DST change.
proc ::ashcapture::after_poll {} {
    variable provider
    variable failed
    variable pending_chart
    variable sample_offsets
    variable statekey
    if {$provider eq "pg" || $failed ne ""} {return}
    try {
        set rows {}
        foreach row $pending_chart {
            set key [list [expr {wide([dict get $row sample_id])}] [dict get $row first_day] [expr {double([dict get $row secs])}]]
            if {[dict exists $sample_offsets $key]} {
                dict set row _sample_utc_offset_seconds [dict get $sample_offsets $key]
            } elseif {$::ashcapture::offset_changed} {
                error "Native chart timestamp cannot be resolved across a server timezone offset change"
            } else {
                dict set row _sample_utc_offset_seconds [dict get $row _utc_offset_seconds]
            }
            lappend rows $row
        }
        ashstore::append ::ashcapture::store $::ashcapture::jobid chart $rows
        set pending_chart {}
        # The unchanged native chart query covers the latest fifteen seconds.
        # Retain a margin while bounding timestamp lookup memory for long Jobs.
        set oldest [expr {$::ashcapture::poll_epoch-120}]
        dict for {key value} $sample_offsets {
            if {[lindex $key 0]<$oldest} {dict unset sample_offsets $key}
        }
    } on error {message options} {
        set failed "ASH chart timestamp transfer failed across a server timezone offset change"
        set ::public(run) 0
        tsv::set ashcapture error,$statekey $failed
        catch {ashstore::finish ::ashcapture::store $::ashcapture::jobid failed $failed}
    }
}

proc ::ashcapture::shutdown {state} {
    variable ns
    variable failed
    variable native_worker
    variable provider
    variable own_event
    variable changed_scheduler
    if {[info exists ::public(run)]} {
        after cancel mon_loop
        if {$failed eq "" && [info exists ::public(handle)]} {
            # Flush via the same dispatcher/native worker before closing either connection.
            before_poll
            if {$failed eq ""} {
                set ::ashcapture::run_end $::ashcapture::poll_epoch
                set timeexpr [expr {$provider eq "pg" ? "EXTRACT(EPOCH FROM ash.ash_time)" : "UNIX_TIMESTAMP(ash.ash_time)"}]
                set ::ashcapture::end_predicate "AND $timeexpr <= $::ashcapture::run_end"
                ashstore::update_metadata ::ashcapture::store $::ashcapture::jobid [dict create run_end $::ashcapture::run_end]
            }
            foreach cursor {capture_samples capture_stats ash} {${ns}::mon_execute $cursor}
            after_poll
            if {$failed eq "" && $state eq "complete"} {
                # Do not declare ASH success for a completed benchmark when the
                # native sampler has produced no rows. The benchmark's timing
                # collection has already ended; this check cannot affect it.
                set jobid $::ashcapture::jobid
                set sample_count [::ashcapture::store onecolumn {
                    SELECT count(*) FROM JOBASH WHERE jobid=$jobid AND source='samples'
                }]
                if {$sample_count == 0} {
                    set failed "ASH $provider collected zero samples during a completed benchmark. Check the native event scheduler and hammerdb_ash.active_session_history on the database."
                    puts stderr $failed
                }
            }
        }
        set ::public(run) 0
    }
    if {$native_worker ne "" && [thread::exists $native_worker]} {
        set driver [expr {$provider eq "maria" ? "maria" : "mysql"}]
        if {[info exists ::public(handle)]} {
            if {$provider eq "pg"} {set close pg_disconnect} else {set close ${driver}::close}
            catch {thread::send $native_worker [list $close $::public(handle)]}
        }
        catch {thread::release $native_worker}
        set native_worker ""
    }
    if {[llength [info commands ::ashcapture::store]]} {
        if {$failed ne ""} {set state failed}
        catch {ashstore::finish ::ashcapture::store $::ashcapture::jobid $state $failed}
        ::ashcapture::store close
    }
    if {$failed ne ""} {error $failed}
}
package provide ashcapture 1.0
