#VillageSQL metrics.
#
#VillageSQL is MySQL wire-compatible and speaks the same performance_schema
#surface, so its database-metrics implementation is identical to MySQL's. Rather
#than duplicate ~3000 lines, this file reuses the MySQL metrics namespace: it
#sources mysqlmet.tcl (already loaded ahead of us when both engines are present,
#but sourced defensively here so vsql works standalone) and re-exposes the
#namespace under the vsqlmet:: name that the generic layer dispatches to.

namespace eval vsqlmet {}

#Bring mysqlmet:: into existence if it isn't already. In a normal build the
#MySQL engine is loaded ahead of VillageSQL (dbsrclist is keyed alphabetically,
#mysql before vsql) so this is a no-op; we source it here only so VillageSQL
#also works when MySQL is not among the loaded engines. The guard avoids
#re-sourcing (which would reset mysqlmet's connection state, e.g. firstconnect).
if { ![ namespace exists ::mysqlmet ] } {
    source [ file join [ file dirname [ file dirname [ info script ] ] ] mysql mysqlmet.tcl ]
}

namespace eval vsqlmet {
    #Re-export every proc mysqlmet exports so `namespace import vsqlmet::*`
    #(genmetrics.tcl) pulls in the shared metrics/ASH/wait-analysis surface.
    #connect_to_mysql is deliberately EXCLUDED: it is the one proc that reads the
    #MySQL configuration (configmysql, mysql_* connection vars, check_mysql_ssl).
    #We provide a VillageSQL-specific version below that reads configvillagesql
    #and the vsql_* settings instead, then hands off to the shared thread/logon
    #machinery (which is provider-agnostic — it only reads the public(...) array).
    foreach _p [ namespace eval ::mysqlmet { namespace export } ] {
        if { $_p eq "connect_to_mysql" } { continue }
        namespace export $_p
        interp alias {} ::vsqlmet::$_p {} ::mysqlmet::$_p
    }
    unset -nocomplain _p

    #The generic layer calls two names by the vsql prefix. Alias them to the
    #shared MySQL implementations.
    namespace export vsqlmetrics vsql_post_kill_dbmon_cleanup
    interp alias {} ::vsqlmet::vsqlmetrics                {} ::mysqlmet::mysqlmetrics
    interp alias {} ::vsqlmet::vsql_post_kill_dbmon_cleanup {} ::mysqlmet::mysql_post_kill_dbmon_cleanup

    #VillageSQL connection setup: mirrors mysqlmet::connect_to_mysql but reads the
    #VillageSQL configuration (configvillagesql + vsql_* vars) so Metrics connects
    #with the values shown in the VillageSQL dialog, not the MySQL ones. The
    #per-connection public(...) array it fills is consumed by the shared metrics
    #code, so the thread/logon/ASH machinery is reused unchanged.
    namespace export connect_to_mysql
    proc connect_to_mysql {} {
        global public masterthread dbmon_threadID bm vsql_ssl_options
        upvar #0 configvillagesql configvillagesql
        setlocaltcountvars $configvillagesql 1
        if ![ info exists vsql_ssl_options ] { check_vsql_ssl $configvillagesql }
        set public(connected) 0
        set public(host) $vsql_host
        set public(port) $vsql_port
        set public(socket) $vsql_socket
        set public(ssl_options) $vsql_ssl_options
        if { $bm eq "TPC-C" } {
            set public(user) $vsql_user
            set public(user_pw) [ quotemeta $vsql_pass ]
            set public(tproc_db) $vsql_dbase
        } else {
            set public(user) $vsql_tpch_user
            set public(user_pw) [ quotemeta $vsql_tpch_pass ]
            set public(tproc_db) $vsql_tpch_dbase
        }

        if { ! [ info exists dbmon_threadID ] } {
            set public(parent) $masterthread
            ::mysqlmet::mysql_dbmon_thread_init
            #add zipfs paths to thread
            catch {eval [ subst {thread::send $dbmon_threadID {lappend ::auto_path [zipfs root]app/lib}}]}
            catch {eval [ subst {thread::send $dbmon_threadID {::tcl::tm::path add [zipfs root]app/modules modules}}]}
        } else {
            return 1
        }

        #Do logon in thread (shared logon proc, driven by the public(...) values)
        set db_type "default"
        thread::send -async $dbmon_threadID "mysql_logon $public(parent) $public(host) $public(port) {$public(socket)} {$public(ssl_options)} $public(user) $public(user_pw) $public(tproc_db) $db_type"

        test_connect_mysql
        if { [ info exists dbmon_threadID ] } {
            tsv::set application themonitor $dbmon_threadID
        }
    }
}
