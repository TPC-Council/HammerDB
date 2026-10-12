#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','vsql')
dbset('bm','TPC-H')

diset('connection','vsql_host','localhost')
diset('connection','vsql_port','3306')
diset('connection','vsql_socket','/tmp/villagesql.sock')

diset('tpch','vsql_scale_fact','10')
diset('tpch','vsql_tpch_user','root')
diset('tpch','vsql_tpch_pass','mysql')
diset('tpch','vsql_tpch_dbase','tpch')
diset('tpch','vsql_tpch_storage_engine','innodb')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "vsql_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
