#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db vsql
dbset bm TPC-C

diset connection vsql_host localhost
diset connection vsql_port 3306
diset connection vsql_socket /tmp/villagesql.sock

diset tpcc vsql_user root
diset tpcc vsql_pass mysql
diset tpcc vsql_dbase tpcc
diset tpcc vsql_driver timed
diset tpcc vsql_rampup 2
diset tpcc vsql_duration 5
diset tpcc vsql_allwarehouse true
diset tpcc vsql_timeprofile true

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
set of [ open $tmpdir/vsql_tprocc w ]
puts $of $jobid
close $of
