#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','vsql')
dbset('bm','TPC-H')

diset('connection','vsql_host','localhost')
diset('connection','vsql_port','3306')
diset('connection','vsql_socket','/tmp/villagesql.sock')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','vsql_scale_fact','10')
diset('tpch','vsql_num_tpch_threads',vu)
diset('tpch','vsql_tpch_user','root')
diset('tpch','vsql_tpch_pass','mysql')
diset('tpch','vsql_tpch_dbase','tpch')
diset('tpch','vsql_tpch_storage_engine','innodb')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
