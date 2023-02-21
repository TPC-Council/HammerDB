#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-C

diset tpcc db2_user db2inst1
diset tpcc db2_pass ibmdb2
diset tpcc db2_dbase tpcc
diset tpcc db2_driver timed
diset tpcc db2_rampup 2
diset tpcc db2_duration 5
diset tpcc db2_allwarehouse true
diset tpcc db2_timeprofile true

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
set of [ open $tmpdir/db2_tprocc w ]
puts $of $jobid
close $of
