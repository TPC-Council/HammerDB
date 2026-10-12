#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','vsql')
dbset('bm','TPC-C')

diset('connection','vsql_host','localhost')
diset('connection','vsql_port','3306')
diset('connection','vsql_socket','/tmp/villagesql.sock')

diset('tpcc','vsql_user','root')
diset('tpcc','vsql_pass','mysql')
diset('tpcc','vsql_dbase','tpcc')
diset('tpcc','vsql_driver','timed')
diset('tpcc','vsql_rampup','2')
diset('tpcc','vsql_duration','5')
diset('tpcc','vsql_allwarehouse','true')
diset('tpcc','vsql_timeprofile','true')

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
file_path = os.path.join(tmpdir , "vsql_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
