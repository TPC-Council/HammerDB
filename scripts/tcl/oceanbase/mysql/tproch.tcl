source [file join [file dirname [info script]] config.tcl]
dbset bm TPROC-H
diset tpch ob_tpch_user $::env(OB_USER)
diset tpch ob_tpch_pass $::env(OB_PASSWORD)
diset tpch ob_tpch_dbase $::env(OB_DATABASE)
diset tpch ob_scale_fact [ob_env OB_SCALE_FACTOR 1]
diset tpch ob_num_tpch_threads [ob_env OB_BUILD_USERS 2]
buildschema
ob_require_success Build
checkschema
ob_require_success Check
diset tpch ob_refresh_on true
diset tpch ob_trickle_refresh 0
loadscript
vuset vu 1
vucreate
puts [vurun]
ob_require_success RefreshAndQueries
checkschema
ob_require_success CheckAfterRefresh
