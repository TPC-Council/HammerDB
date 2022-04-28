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

diset tpcc count_ware 1
diset tpcc num_vu 1
diset tpcc tpcc_user tpcc        
diset tpcc tpcc_pass tpcc      
diset tpcc tpcc_def_tab tpcctab  
diset tpcc tpcc_ol_tab tpcctab
diset tpcc tpcc_def_temp temp
diset tpcc partition false
diset tpcc hash_clusters false

print dict
vuset logtotemp 1
buildschema
waittocomplete

#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/ora_tprocc_build.tcl
~

