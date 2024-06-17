#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','ora')
dbset('bm','TPC-H')

diset('connection','system_user','system')
diset('connection','system_password','manager')
diset('connection','instance','oracle')

diset('tpch','tpch_user','tpch')
diset('tpch','tpch_pass','tpch')
diset('tpch','tpch_def_tab','users')
diset('tpch','tpch_def_temp','temp')

print("CHECK SCHEMA STARTED")
checkschema()
print("CHECK SCHEMA COMPLETED")
exit()
