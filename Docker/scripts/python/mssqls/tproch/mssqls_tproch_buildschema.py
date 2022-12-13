#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mssqls')
dbset('bm','TPC-H')

diset('connection','mssqls_linux_server','{localhost}')
diset('connection','mssqls_linux_authent','sql')
diset('connection','mssqls_linux_odbc','{ODBC Driver 18 for SQL Server}')
diset('connection','mssqls_uid','sa')
diset('connection','mssqls_pass','admin')
diset('connection','mssqls_encrypt_connection','true')
diset('connection','mssqls_trust_server_cert','true')
diset('connection','mssqls_tcp','true')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','mssqls_num_tpch_threads',vu)
diset('tpch','mssqls_scale_fact','1')
diset('tpch','mssqls_maxdop','2')
diset('tpch','mssqls_tpch_dbase','tpch')
diset('tpch','mssqls_colstore','false')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
