#!/bin/tclsh
# maintainer: Pooja Jain
import os
tmpdir = os.getenv('TMP')

print("SETTING CONFIGURATION")
dbset('db','pg')
dbset('bm','TPC-H')

diset('connection','pg_host','localhost')
diset('connection','pg_port','5432')
diset('connection','pg_sslmode','prefer')

diset('tpch','pg_scale_fact','1')
diset('tpch','pg_tpch_user','tpch')
diset('tpch','pg_tpch_pass','tpch')
diset('tpch','pg_tpch_dbase','tpch')
diset('tpch','pg_total_querysets','1')
diset('tpch','pg_degree_of_parallel','2')

loadscript()
print("TEST STARTED")
vuset('vu','1')
vucreate()
jobid = tclpy.eval('vurun')
vudestroy()
print("TEST COMPLETE")
file_path = os.path.join(tmpdir , "pg_tproch" )
fd = open(file_path, "w")
fd.write(jobid)
fd.close()
exit()


