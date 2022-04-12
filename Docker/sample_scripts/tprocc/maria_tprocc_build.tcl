#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-C

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_host /tmp/mariadb.sock

diset tpcc maria_count_ware 1
diset tpcc maria_num_vu 1
diset tpcc maria_pass maria
diset tpcc maria_dbase tpcc
diset tpcc maria_storage_engine innodb
diset tpcc maria_partition false 

print dict
vuset logtotemp 1
buildschema
waittocomplete

#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/maria_tprocc_build.tcl

