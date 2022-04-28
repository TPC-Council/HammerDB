#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-C

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_sock /tmp/mariadb.sock

diset tpcc maria_user root
diset tpcc maria_pass maria
diset tpcc maria_dbase tpcc
diset tpcc maria_driver timed
diset tpcc maria_rampup 2
diset tpcc maria_duration 5
diset tpcc maria_timeprofile false

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
# ./hammerdbcli auto sample_scripts/tprocc/maria_tprocc_run.tcl



