#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-H')

diset('connection','pg_host','localhost')
diset('connection','pg_port','3306')
diset('connection','pg_socket','/tmp/pgdb.sock')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','pg_scale_fact','1')
diset('tpch','pg_num_tpch_threads',vu)
diset('tpch','pg_tpch_user','root')
diset('tpch','pg_tpch_pass','pg')
diset('tpch','pg_tpch_dbase','tpch')
diset('tpch','pg_tpch_storage_engine','innodb')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
