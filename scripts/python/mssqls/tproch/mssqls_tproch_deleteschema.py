#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mssqls')
dbset('bm','TPC-H')

diset('connection','mssqls_server','(local)')
diset('connection','mssqls_authentication','windows')
diset('connection','mssqls_odbc_driver','"ODBC Driver 18 for SQL Server"')
diset('connection','mssqls_encrypt_connection','true')
diset('connection','mssqls_trust_server_cert','true')

diset('tpch','mssqls_tpch_dbase','tpch')

print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
