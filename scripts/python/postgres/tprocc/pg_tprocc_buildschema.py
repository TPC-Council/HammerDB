#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-C')

diset('connection','pg_host','localhost')
diset('connection','pg_port','3306')
diset('connection','pg_socket','/tmp/pgdb.sock')

vu = tclpy.eval('numberOfCPUs')
warehouse = int(vu) * 5
diset('tpcc','pg_count_ware',warehouse)
diset('tpcc','pg_num_vu',vu)
diset('tpcc','pg_user root')
diset('tpcc','pg_pass pg')
diset('tpcc','pg_dbase tpcc')
diset('tpcc','pg_storage_engine innodb')
if (warehouse >= 200): 
    diset('tpcc','pg_partition','true') 
else:
    diset('tpcc','pg_partition','false') 

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
