#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-C

diset connection db2_def_user db2inst1
diset connection db2_def_pass ibmdb2
diset connection db2_def_dbase db2

diset tpcc db2_user db2inst1
diset tpcc db2_pass ibmdb2
diset tpcc db2_dbase tpcc

puts "CHECK SCHEMA STARTED"
checkschema
puts "CHECK SCHEMA COMPLETED"
