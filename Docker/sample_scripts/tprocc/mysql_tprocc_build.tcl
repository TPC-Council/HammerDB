#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path for logs directory. By Default logs are logged in /tmp
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db mysql
dbset bm TPC-C

diset connection mysql_host localhost
diset connection mysql_port 3306
diset connection mysql_host /tmp/mysql.sock

diset tpcc mysql_count_ware 1
diset tpcc mysql_num_vu 1
diset tpcc mysql_pass mysql
diset tpcc mysql_dbase tpcc
diset tpcc mysql_storage_engine innodb
diset tpcc mysql_partition false 

print dict
vuset logtotemp 1
buildschema
waittocomplete

#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/mysql_tprocc_build.tcl

