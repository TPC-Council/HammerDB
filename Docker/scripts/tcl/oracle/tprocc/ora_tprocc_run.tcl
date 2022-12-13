#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db ora
dbset bm TPC-C

diset connection system_user system
diset connection system_password manager
diset connection instance oracle

diset tpcc tpcc_user tpcc
diset tpcc tpcc_pass tpcc

diset tpcc ora_driver timed
diset tpcc total_iterations 10000000
diset tpcc rampup 2
diset tpcc duration 5
diset tpcc ora_timeprofile true
diset tpcc allwarehouse true
diset tpcc checkpoint false

loadscript
puts "TEST STARTED"
vuset vu vcpu
vucreate
tcstart
tcstatus
set jobid [ vurun ]
vudestroy
tcstop
puts "TEST COMPLETE"
set of [ open $tmpdir/ora_tprocc w ]
puts $of $jobid
close $of
