#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','db2')
dbset('bm','TPC-C')

diset('tpcc','db2_user','db2inst1')
diset('tpcc','db2_pass','ibmdb2')
diset('tpcc','db2_dbase','tpcc')
diset('tpcc','db2_driver','timed')
diset('tpcc','db2_rampup','2')
diset('tpcc','db2_duration','5')
diset('tpcc','db2_allwarehouse','true')
diset('tpcc','db2_timeprofile','true')

loadscript()
print("TEST STARTED")
vuset('vu','vcpu')
vucreate()
tcstart()
tcstatus()
jobid = tclpy.eval('vurun')
vudestroy()
tcstop()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "db2_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
