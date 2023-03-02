#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','ora')
dbset('bm','TPC-H')

diset('connection','system_user','system')
diset('connection','system_password','manager')
diset('connection','instance','oracle')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','scale_fact','1')
diset('tpch','num_tpch_threads',vu)
diset('tpch','tpch_user','tpch')
diset('tpch','tpch_pass','tpch')
diset('tpch','tpch_def_tab','users')
diset('tpch','tpch_def_temp','temp')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
