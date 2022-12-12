#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','mysql')
dbset('bm','TPC-C')

diset('connection','mysql_host','localhost')
diset('connection','mysql_port','3306')
diset('connection','mysql_socket','/tmp/mysql.sock')

diset('tpcc','mysql_user','root')
diset('tpcc','mysql_pass','mysql')
diset('tpcc','mysql_dbase','tpcc')
diset('tpcc','mysql_driver','timed')
diset('tpcc','mysql_rampup','2')
diset('tpcc','mysql_duration','5')
diset('tpcc','mysql_allwarehouse','true')
diset('tpcc','mysql_timeprofile','true')

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
file_path = os.path.join(tmpdir , "mysql_tprocc" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()
