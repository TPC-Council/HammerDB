#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','vsql')
dbset('bm','TPC-C')

diset('connection','vsql_host','localhost')
diset('connection','vsql_port','3306')
diset('connection','vsql_socket','/tmp/villagesql.sock')

diset('tpcc','vsql_user','root')
diset('tpcc','vsql_pass','mysql')
diset('tpcc','vsql_dbase','tpcc')
print("CHECK SCHEMA STARTED")
checkschema()
print("CHECK SCHEMA COMPLETED")
exit()
