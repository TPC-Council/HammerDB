#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-C

diset connection pg_host localhost
diset connection pg_port 5432
diset connection pg_sslmode prefer

diset tpcc pg_superuser postgres
diset tpcc pg_superuserpass postgres
diset tpcc pg_defaultdbase postgres
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc
diset tpcc pg_dbase tpcc
diset tpcc pg_driver timed
diset tpcc pg_total_iterations 10000000
diset tpcc pg_rampup 2
diset tpcc pg_duration 5
diset tpcc pg_vacuum true
diset tpcc pg_timeprofile true
diset tpcc pg_allwarehouse true

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
set of [ open $tmpdir/pg_tprocc w ]
puts $of $jobid
close $of

