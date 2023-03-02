#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db mysql
dbset bm TPC-C

diset connection mysql_host localhost
diset connection mysql_port 3306
diset connection mysql_socket /tmp/mysql.sock

set vu [ numberOfCPUs ]
set warehouse [ expr {$vu * 5} ]
diset tpcc mysql_count_ware $warehouse
diset tpcc mysql_num_vu $vu
diset tpcc mysql_user root
diset tpcc mysql_pass mysql
diset tpcc mysql_dbase tpcc
diset tpcc mysql_storage_engine innodb
if { $warehouse >= 200 } { 
diset tpcc mysql_partition true 
	} else {
diset tpcc mysql_partition false 
	}
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
