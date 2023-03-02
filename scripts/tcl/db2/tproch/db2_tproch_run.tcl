#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db db2
dbset bm TPC-H

diset connection db2_def_user db2inst1
diset connection db2_def_pass ibmdb2
diset connection db2_def_dbase db2

diset tpch db2_tpch_user db2inst1
diset tpch db2_tpch_pass ibmdb2
diset tpch db2_tpch_dbase tpch

loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
set jobid [ vurun ]
vudestroy
puts "TEST COMPLETE"
set of [ open $tmpdir/db2_tproch w ]
puts $of $jobid
close $of
