#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mssqls')
dbset('bm','TPC-H')

diset('connection','mssqls_linux_server','localhost')
diset('connection','mssqls_linux_authent','sql')
diset('connection','mssqls_linux_odbc','"ODBC Driver 18 for SQL Server"')
diset('connection','mssqls_uid','sa')
diset('connection','mssqls_pass','admin')
diset('connection','mssqls_encrypt_connection','true')
diset('connection','mssqls_trust_server_cert','true')

diset('tpch','mssqls_tpch_dbase','tpch')

print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
