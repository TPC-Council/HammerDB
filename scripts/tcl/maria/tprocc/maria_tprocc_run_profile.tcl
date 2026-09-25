#!/bin/tclsh
# maintainer: Pooja Jain

if {![info exists ::env(TMP)] || $::env(TMP) eq ""} {
    set ::env(TMP) "[pwd]/TMP"
    file mkdir $::env(TMP)
    puts "TMP not set — defaulting to $::env(TMP)"
}

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-C

# --- PROFILEID ---
if {![info exists ::env(PROFILEID)]} {
    puts "ERROR: PROFILEID not set in environment (must be explicitly set)"
    exit 1
}
set profileid $::env(PROFILEID)
puts "Using PROFILEID = $profileid"

if {![string is integer -strict $profileid]} {
    puts "ERROR: PROFILEID must be an integer, got: '$profileid'"
    exit 1
}
if {$profileid < 0} {
    puts "ERROR: PROFILEID must be 0 (single run) or > 1 (profile). Got: $profileid"
    exit 1
}
if {$profileid == 1} {
    puts "ERROR: PROFILEID=1 is invalid. Use 0 (single run) or an integer > 1 (profile)."
    exit 1
}

# Set PROFILEID for both single runs (0) and profile runs (>1)
if {[catch { jobs profileid $profileid } jerr]} {
    puts "ERROR: jobs profileid failed: $jerr"
    exit 1
}

set uaw 0
if {[info exists ::env(UAW)]} {
    set uaw_env [string tolower [string trim $::env(UAW)]]
    if {$uaw_env in {"1" "true" "yes" "on"}} {
        set uaw 1
    }
}

giset commandline keepalive_margin 1200
giset timeprofile xt_gather_timeout 1200

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

diset tpcc maria_user root
diset tpcc maria_pass maria
diset tpcc maria_dbase tpcc
diset tpcc maria_driver timed
diset tpcc maria_rampup 2
diset tpcc maria_duration 5
diset tpcc maria_allwarehouse false
if {$uaw} {
    diset tpcc maria_allwarehouse true
}
diset tpcc maria_timeprofile true
diset tpcc maria_purge true

puts "TEST STARTED"

# --- Single run: PROFILEID=0 => run ONCE with VUs = number of vCPUs ---
if {$profileid == 0} {
    loadscript
    vuset vu vcpu
    vuset logtotemp 1
    vucreate
    metstart
    tcstart
    tcstatus
    set jobid [ vurun ]
    metstop
    tcstop
    vudestroy

    puts "Writing to $tmpdir/maria_tprocc_profile.$profileid"
    set of [ open "$tmpdir/maria_tprocc_profile.$profileid" w ]
    puts $of $jobid
    close $of

    puts "TEST COMPLETE"
    exit 0
}

# --- Profile run (PROFILEID > 1) ---
set end_vu  [ expr { [ numberOfCPUs ] + 8 } ]
set vu_list {1}
for {set z 4} {$z <= $end_vu} {incr z 4} { lappend vu_list $z }

    metstart
    tcstart
foreach z $vu_list {
    loadscript
    vuset vu $z
    vuset logtotemp 1
    vucreate
    metstatus
    tcstatus
    set jobid [ vurun ]
    vudestroy
    puts "Writing to $tmpdir/maria_tprocc_profile.$profileid"
    set of [ open "$tmpdir/maria_tprocc_profile.$profileid" a ]
    puts $of $jobid
    close $of
}
    tcstop
    metstop

puts "TEST COMPLETE"
