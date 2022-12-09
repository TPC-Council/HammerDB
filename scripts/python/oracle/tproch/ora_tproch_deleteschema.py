#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','ora')
dbset('bm','TPC-H')

diset('tpch','tpch_user','tpch')
diset('tpch','tpch_pass','tpch')
diset('tpch','tpch_def_tab','users')
diset('tpch','tpch_def_temp','temp')

print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
