#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-C')

diset('connection','pg_host','localhost')
diset('connection','pg_port','3306')
diset('connection','pg_socket','/tmp/pgdb.sock')

diset('tpcc','pg_user','root')
diset('tpcc','pg_pass','pg')
diset('tpcc','pg_dbase','tpcc')
diset('tpcc','pg_driver','timed')
diset('tpcc','pg_rampup','2')
diset('tpcc','pg_duration','5')
diset('tpcc','pg_allwarehouse','true')
diset('tpcc','pg_timeprofile','true')

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
file_path = os.path.join(tmpdir , "pg_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
