#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-C

diset connection db2_def_user db2inst1
diset connection db2_def_pass ibmdb2

diset tpcc db2_user ibmdb2
diset tpcc db2_pass db2
diset tpcc db2_dbase tpcc
diset tpcc db2_total_iterations 10000000
diset tpcc db2_driver timed
diset tpcc db2_rampup 2
diset tpcc db2_duration 5
diset tpcc db2_monreport 0
diset tpcc db2_timeprofile false

print dict
vuset logtotemp 1
loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
tcstart
tcstatus
vurun
runtimer 500
vudestroy
tcstop
puts "TEST COMPLETE"


#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/db2_tprocc_run.tcl

