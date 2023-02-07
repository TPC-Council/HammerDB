#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-H')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

diset(' tpch','maria_tpch_user','root')
diset(' tpch','maria_tpch_pass','maria')
diset(' tpch','maria_tpch_dbase','tpch')
print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
