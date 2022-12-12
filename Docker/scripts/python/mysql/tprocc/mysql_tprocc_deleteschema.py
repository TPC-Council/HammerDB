#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','mysql')
dbset('bm','TPC-C')

diset('connection','mysql_host','localhost')
diset('connection','mysql_port','3306')
diset('connection','mysql_socket','/tmp/mysql.sock')

diset('tpcc','mysql_user','root')
diset('tpcc','mysql_pass','mysql')
diset('tpcc','mysql_dbase','tpcc')
print("DROP SCHEMA STARTED")
deleteschema()
print("DROP SCHEMA COMPLETED")
exit()
