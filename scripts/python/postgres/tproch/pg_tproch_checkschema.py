#!/bin/tclsh
# maintainer: Pooja Jain

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-H')

diset('connection','pg_host','localhost')
diset('connection','pg_port','5432')
diset('connection','pg_sslmode','prefer')

diset('tpch','pg_tpch_superuser','postgres')
diset('tpch','pg_tpch_superuserpass','postgres')
diset('tpch','pg_tpch_defaultdbase','postgres')
diset('tpch','pg_tpch_user','tpch')
diset('tpch','pg_tpch_pass','tpch')
diset('tpch','pg_tpch_dbase','tpch')
diset('tpch','pg_tpch_tspace','pg_default')

print("CHECK SCHEMA STARTED")
checkschema()
print("CHECK SCHEMA COMPLETED")
exit()
