#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-C

diset connection db2_def_user db2inst1
diset connection db2_def_pass ibmdb2
diset connection db2_def_dbase db2

set vu [ numberOfCPUs ]
set warehouse [ expr {$vu * 5} ]
diset tpcc db2_count_ware $warehouse
diset tpcc db2_num_vu $vu
diset tpcc db2_user db2inst1
diset tpcc db2_pass ibmdb2
diset tpcc db2_dbase tpcc
diset tpcc db2_def_tab USERSPACE1
diset tpcc db2_tab_list {C "" D "" H "" I "" W "" S "" NO "" OR "" OL ""}

if { $warehouse >= 10 } { 
diset tpcc db2_partition true 
	} else {
diset tpcc db2_partition false 
	}
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
