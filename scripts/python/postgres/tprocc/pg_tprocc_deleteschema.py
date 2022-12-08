#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-C')

diset('connection','pg_host','localhost')
diset('connection','pg_port','3306')
diset('connection','pg_socket','/tmp/pgdb.sock')

diset('tpcc','pg_user','root')
diset('tpcc','pg_pass','pg')
diset('tpcc','pg_dbase','tpcc')
print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
