#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-C

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

set warehouse [ numberOfWHs ]
set vu [ numberOfCPUs ]
if { $warehouse > 2000 } {
    set max_build_vu [ expr { int($warehouse / 10) } ]
    if { $vu > $max_build_vu } {
        set vu $max_build_vu
    }
}
diset tpcc maria_count_ware $warehouse
diset tpcc maria_num_vu $vu
diset tpcc maria_user root
diset tpcc maria_pass maria
diset tpcc maria_dbase tpcc
diset tpcc maria_storage_engine innodb
if { $warehouse >= 200 } { 
diset tpcc maria_partition true 
	} else {
diset tpcc maria_partition false 
	}
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
