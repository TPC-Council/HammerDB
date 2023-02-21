#!/bin/tclsh
# maintainer: Pooja Jain
print("SETTING CONFIGURATION")
dbset('db','db2')
dbset('bm','TPC-H')

diset ('connection','db2_def_user','db2inst1')
diset ('connection','db2_def_pass','ibmdb2')
diset('connection','db2_def_dbase','db2')

diset('tpch','db2_tpch_user','db2inst1')
diset('tpch','db2_tpch_pass','ibmdb2')
diset('tpch','db2_tpch_dbase','tpch')

print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
