#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-H')

diset('connection','pg_host','localhost')
diset('connection','pg_port','3306')
diset('connection','pg_socket','/tmp/pgdb.sock')

diset('tpch','pg_scale_fact','1')
diset('tpch','pg_tpch_user','root')
diset('tpch','pg_tpch_pass','pg')
diset('tpch','pg_tpch_dbase','tpch')
diset('tpch','pg_tpch_storage_engine','innodb')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "pg_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
