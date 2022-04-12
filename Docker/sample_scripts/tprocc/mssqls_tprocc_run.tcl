#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db mssqls
dbset bm TPC-C

diset connection mssqls_host localhost
diset connection mssqls_authentication windows
#How to specify the ODBC driver here, it has spaces, in double quotes?
diset connection mssqls_odbc_driver "ODBC Driver 17 for SQL Server"

diset tpcc mssqls_user root
diset tpcc mssqls_pass mssqls
diset tpcc mssqls_dbase tpcc
diset tpcc mssqls_driver timed
diset tpcc mssqls_total_iterations 10000000
diset tpcc mssqls_checkpoint true
diset tpcc mssqls_rampup 2
diset tpcc mssqls_duration 5
diset tpcc mssqls_timeprofile false

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
# ./hammerdbcli auto sample_scripts/tprocc/mssqls_tprocc_run.tcl


