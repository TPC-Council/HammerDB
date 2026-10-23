source [file join [file dirname [info script]] config.tcl]
dbset bm TPROC-C
diset tpcc ob_user $::env(OB_USER)
diset tpcc ob_pass $::env(OB_PASSWORD)
diset tpcc ob_dbase $::env(OB_DATABASE)
diset tpcc ob_count_ware [ob_env OB_WAREHOUSES 2]
diset tpcc ob_num_vu [ob_env OB_BUILD_USERS 2]
diset tpcc ob_driver timed
diset tpcc ob_rampup [ob_env OB_RAMPUP 1]
diset tpcc ob_duration [ob_env OB_DURATION 1]
buildschema
ob_require_success Build
checkschema
ob_require_success Check
loadscript
vuset vu [ob_env OB_USERS 2]
vucreate
puts [vurun]
ob_require_success Run
checkschema
ob_require_success CheckAfterRun
