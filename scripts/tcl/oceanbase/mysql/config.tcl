# Shared configuration for the independent OceanBase category.
# Credentials come from the environment; use a new OB_DATABASE for each build.
foreach name {OB_HOST OB_TENANT OB_USER OB_PASSWORD OB_DATABASE} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {error "Set $name before running this script"}
}
proc ob_env {name fallback} {
    if {[info exists ::env($name)]} {return $::env($name)}
    return $fallback
}
proc ob_require_success {phase} {
    if {![info exists ::vustatus] || [dict size $::vustatus] == 0} {error "$phase did not run"}
    dict for {vu status} $::vustatus {
        if {$status ne "FINISH SUCCESS"} {error "$phase failed: virtual user $vu ($status)"}
    }
    vudestroy
}
dbset db ob
diset connection ob_compatibility_mode mysql
diset connection ob_host $::env(OB_HOST)
diset connection ob_port [ob_env OB_PORT 2881]
diset connection ob_tenant $::env(OB_TENANT)
diset connection ob_cluster [ob_env OB_CLUSTER {}]
diset connection ob_query_timeout [ob_env OB_QUERY_TIMEOUT 120]
