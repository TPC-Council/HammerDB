#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','ora')
dbset('bm','TPC-C')

diset('connection','system_user','system')
diset('connection','system_password','manager')
diset('connection','instance','oracle')

diset('tpcc','tpcc_user','tpcc')
diset('tpcc','tpcc_pass','tpcc')
diset('tpcc','ora_driver','timed')
diset('tpcc','total_iterations','10000000')
diset('tpcc','rampup','2')
diset('tpcc','duration','5')
diset('tpcc','allwarehouse','true')
diset('tpcc','ora_timeprofile','true')
diset('tpcc','checkpoint','false')

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
file_path = os.path.join(tmpdir , "ora_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
