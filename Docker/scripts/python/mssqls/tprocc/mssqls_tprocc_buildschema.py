#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mssqls')
dbset('bm','TPC-C')

diset('connection','mssqls_linux_server','localhost')
diset('connection','mssqls_linux_authent','sql')
diset('connection','mssqls_linux_odbc','"ODBC Driver 18 for SQL Server"')
diset('connection','mssqls_uid','sa')
diset('connection','mssqls_pass','admin')
diset('connection','mssqls_encrypt_connection','true')
diset('connection','mssqls_trust_server_cert','true')

vu = tclpy.eval('numberOfCPUs')
warehouse = int(vu) * 5
diset('tpcc','mssqls_count_ware',warehouse)
diset('tpcc','mssqls_num_vu',vu)
diset('tpcc','mssqls_dbase','tpcc')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
