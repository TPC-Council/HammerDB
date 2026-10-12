#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db vsql
dbset bm TPC-C

diset connection vsql_host localhost
diset connection vsql_port 3306
diset connection vsql_socket /tmp/villagesql.sock

set warehouse [ numberOfWHs ]
set vu [ numberOfCPUs ]
if { $warehouse > 2000 } {
    set max_build_vu [ expr { int($warehouse / 10) } ]
    if { $vu > $max_build_vu } {
        set vu $max_build_vu
    }
}
diset tpcc vsql_count_ware $warehouse
diset tpcc vsql_num_vu $vu
diset tpcc vsql_user root
diset tpcc vsql_pass mysql
diset tpcc vsql_dbase tpcc
diset tpcc vsql_storage_engine innodb
if { $warehouse >= 200 } { 
diset tpcc vsql_partition true 
	} else {
diset tpcc vsql_partition false 
	}
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
