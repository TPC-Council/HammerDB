#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-C

diset connection db2_def_user db2inst1
diset connection db2_def_pass ibmdb2
diset connection db2_def_dbase db2

diset tpcc db2_count_ware 1
diset tpcc db2_num_vu 1
diset tpcc db2_user db2inst1
diset tpcc db2_pass ibmdb2
diset tpcc db2_dbase tpcc
diset tpcc db2_def_tab USERSPACE1
diset tpcc db2_partition true

print dict
vuset logtotemp 1
buildschema
waittocomplete

#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/db2_tprocc_build.tcl

