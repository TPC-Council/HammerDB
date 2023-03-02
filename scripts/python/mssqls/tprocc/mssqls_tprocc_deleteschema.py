#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mssqls')
dbset('bm','TPC-C')

diset('connection','mssqls_tcp','false')
diset('connection','mssqls_port','1433')
diset('connection','mssqls_azure','false')
diset('connection','mssqls_encrypt_connection','true')
diset('connection','mssqls_trust_server_cert','true')
diset('connection','mssqls_authentication','windows')
diset('connection','mssqls_server','{(local)}')
diset('connection','mssqls_linux_server','{localhost}')
diset('connection','mssqls_linux_authent','sql')
diset('connection','mssqls_linux_odbc','{ODBC Driver 18 for SQL Server}')
diset('connection','mssqls_uid','sa')
diset('connection','mssqls_pass','admin')

diset('tpcc','mssqls_dbase','tpcc')

print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
