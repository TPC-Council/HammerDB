#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-H')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

diset('tpch','maria_scale_fact','1')
diset('tpch','maria_tpch_user','root')
diset('tpch','maria_tpch_pass','maria')
diset('tpch','maria_tpch_dbase','tpch')
diset('tpch','maria_tpch_storage_engine','innodb')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "maria_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
