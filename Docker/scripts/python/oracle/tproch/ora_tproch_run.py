#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','ora')
dbset('bm','TPC-H')

diset('connection','system_user','system')
diset('connection','system_password','manager')
diset('connection','instance','oracle')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','scale_fact','1')
diset('tpch','num_tpch_threads',vu)
diset('tpch','tpch_user','tpch')
diset('tpch','tpch_pass','tpch')
diset('tpch','tpch_def_tab','users')
diset('tpch','total_querysets','1')
diset('tpch','degree_of_parallel','2')


loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "ora_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()

