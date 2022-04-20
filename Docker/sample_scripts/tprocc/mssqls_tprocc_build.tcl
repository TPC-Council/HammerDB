#!/bin/tclsh
# maintainer: Pooja Jain

#Set the path where you want to log results.
export TMP="/tmp"

puts "SETTING CONFIGURATION"
dbset db mssqls
dbset bm TPC-C

diset connection mssqls_host localhost
diset connection mssqls_authentication windows
diset connection mssqls_odbc_driver "ODBC Driver 17 for SQL Server"

diset tpcc mssqls_count_ware 1
diset tpcc mssqls_num_vu 1
diset tpcc mssqls_pass mssqls
diset tpcc mssqls_dbase tpcc

print dict
vuset logtotemp 1
buildschema
waittocomplete

#For Advanced configuration changes, check configuration parameters using command "print dict" in ./hammerdbcli

#Command to run the script
# ./hammerdbcli auto sample_scripts/tprocc/mssqls_tprocc_build.tcl

