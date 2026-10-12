#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','vsql')
dbset('bm','TPC-H')

diset('connection','vsql_host','localhost')
diset('connection','vsql_port','3306')
diset('connection','vsql_socket','/tmp/villagesql.sock')

diset('tpch','vsql_tpch_user','root')
diset('tpch','vsql_tpch_pass','mysql')
diset('tpch','vsql_tpch_dbase','tpch')
print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
