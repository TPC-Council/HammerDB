#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','db2')
dbset('bm','TPC-H')

diset('tpch','db2_tpch_user','db2inst1')
diset('tpch','db2_tpch_pass','ibmdb2')
diset('tpch','db2_tpch_dbase','tpch')
diset('tpch','db2_scale_fact','1')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "db2_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
