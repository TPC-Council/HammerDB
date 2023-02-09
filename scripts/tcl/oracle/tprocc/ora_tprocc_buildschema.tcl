#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db ora
dbset bm TPC-C

diset connection system_user system
diset connection system_password manager
diset connection instance oracle

set vu [ numberOfCPUs ]
set warehouse [ expr {$vu * 5} ]
diset tpcc count_ware $warehouse
diset tpcc num_vu $vu
diset tpcc tpcc_user tpcc
diset tpcc tpcc_pass tpcc
diset tpcc tpcc_def_tab users
diset tpcc tpcc_def_temp temp
if { $warehouse >= 200 } { 
diset tpcc partition true 
diset tpcc hash_clusters true
diset tpcc tpcc_ol_tab users
	} else {
diset tpcc partition false 
diset tpcc hash_clusters false
	}

puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"

