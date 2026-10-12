#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-C')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

warehouse = int(tclpy.eval('numberOfWHs'))
vu = int(tclpy.eval('numberOfCPUs'))
if warehouse > 2000:
    max_build_vu = warehouse // 10
    if vu > max_build_vu:
        vu = max_build_vu
diset('tpcc','maria_count_ware',warehouse)
diset('tpcc','maria_num_vu',vu)
diset('tpcc','maria_user','root')
diset('tpcc','maria_pass','maria')
diset('tpcc','maria_dbase','tpcc')
diset('tpcc','maria_storage_engine','innodb')
if (warehouse >= 200): 
    diset('tpcc','maria_partition','true') 
else:
    diset('tpcc','maria_partition','false') 

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
