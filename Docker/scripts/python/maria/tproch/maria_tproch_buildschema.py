#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-H')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','maria_scale_fact','1')
diset('tpch','maria_num_tpch_threads',vu)
diset('tpch','maria_tpch_user','root')
diset('tpch','maria_tpch_pass','maria')
diset('tpch','maria_tpch_dbase','tpch')
diset('tpch','maria_tpch_storage_engine','innodb')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
