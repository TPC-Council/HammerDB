#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','mysql')
dbset('bm','TPC-H')

diset('connection','mysql_host','localhost')
diset('connection','mysql_port','3306')
diset('connection','mysql_socket','/tmp/mysql.sock')

diset('tpch','mysql_scale_fact','1')
diset('tpch','mysql_tpch_user','root')
diset('tpch','mysql_tpch_pass','mysql')
diset('tpch','mysql_tpch_dbase','tpch')
diset('tpch','mysql_tpch_storage_engine','innodb')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "mysql_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
