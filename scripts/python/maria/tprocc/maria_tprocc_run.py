#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-C')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

diset('tpcc','maria_user','root')
diset('tpcc','maria_pass','maria')
diset('tpcc','maria_dbase','tpcc')
diset('tpcc','maria_driver','timed')
diset('tpcc','maria_rampup','2')
diset('tpcc','maria_duration','5')
diset('tpcc','maria_allwarehouse','true')
diset('tpcc','maria_timeprofile','true')

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
file_path = os.path.join(tmpdir , "maria_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
