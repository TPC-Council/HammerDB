# VillageSQL CI harness.
#
# The CI pipeline executor (cisteps in genci.tcl) dispatches each pipeline step
# to a proc named "<rdbms-lowercased>_<step>", i.e. villagesql_clone,
# villagesql_build, ... villagesql_start_tests. VillageSQL is a MySQL 8.4 fork
# driven as a raw mysqld (see the <VillageSQL> block in config/ci.xml), so its
# CI steps are identical to MySQL's.
#
# Every mysql_<step> proc reads its provider config via the global $rdbms
# ("dict get $cidict $rdbms build ...", "find_prefix $rdbms", etc.), so when
# invoked while $rdbms is "VillageSQL" it operates on the VillageSQL provider
# automatically. We therefore alias the villagesql_<step> names to the shared
# mysql_<step> implementations rather than duplicating ~1900 lines.

# Bring the MySQL CI harness into scope if it isn't already. In a normal load the
# MySQL engine is sourced before VillageSQL (dbsrclist is keyed alphabetically:
# mysql before villagesql), so this is a no-op; sourced here only so VillageSQL
# CI also works when MySQL is not among the loaded engines.
if { [ info commands mysql_clone ] eq "" } {
    source [ file join [ file dirname [ file dirname [ info script ] ] ] mysql mysqlci.tcl ]
}

# Alias each pipeline step (and the profile/compare entry points) to the shared
# MySQL implementation. All are $rdbms-driven, so they act on VillageSQL config.
foreach _step {
    clone build package commit_msg install init start ping run_sql start_tests
    profile compare
} {
    if { [ info commands mysql_$_step ] ne "" } {
        interp alias {} villagesql_$_step {} mysql_$_step
    }
}
unset -nocomplain _step
