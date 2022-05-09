#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db ora
dbset bm TPC-C

diset connection system_user system
diset connection system_password manager
diset connection instance oracle

diset tpcc tpcc_user tpcc        
diset tpcc tpcc_pass tpcc      
diset tpcc ora_driver timed
diset tpcc total_iterations 1000000
diset tpcc checkpoint true
diset tpcc rampup 2 
diset tpcc duration 5        
diset tpcc ora_timeprofile false

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
# ./hammerdbcli auto sample_scripts/tprocc/ora_tprocc_run.tcl
