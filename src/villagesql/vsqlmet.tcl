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
    #The shared implementation is provider-aware: mysqlmet::connect_to_mysql
    #resolves the config dict and variable prefix from the active $rdbms
    #("VillageSQL" here), so Database Metrics/ASH connect with the VillageSQL
    #configuration. Nothing VillageSQL-specific is needed in this file.
    foreach _p [ namespace eval ::mysqlmet { namespace export } ] {
        namespace export $_p
        interp alias {} ::vsqlmet::$_p {} ::mysqlmet::$_p
    }
    unset -nocomplain _p

    #The generic layer calls two names by the vsql prefix. Alias them to the
    #shared MySQL implementations.
    namespace export vsqlmetrics vsql_post_kill_dbmon_cleanup
    interp alias {} ::vsqlmet::vsqlmetrics                {} ::mysqlmet::mysqlmetrics
    interp alias {} ::vsqlmet::vsql_post_kill_dbmon_cleanup {} ::mysqlmet::mysql_post_kill_dbmon_cleanup
}
