#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mysql')
dbset('bm','TPC-H')

diset('connection','mysql_host','localhost')
diset('connection','mysql_port','3306')
diset('connection','mysql_socket','/tmp/mysql.sock')

diset(' tpch','mysql_tpch_user','root')
diset(' tpch','mysql_tpch_pass','mysql')
diset(' tpch','mysql_tpch_dbase','tpch')
print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
