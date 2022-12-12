#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db ora
dbset bm TPC-H

diset connection system_user system
diset connection system_password manager
diset connection instance oracle

diset tpch scale_fact 1
diset tpch num_tpch_threads [ numberOfCPUs ]
diset tpch tpch_user tpch
diset tpch tpch_pass tpch
diset tpch tpch_def_tab users
diset tpch total_querysets 1
diset tpch degree_of_parallel 2

loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
set jobid [ vurun ]
vudestroy
puts "TEST COMPLETE"
set of [ open $tmpdir/ora_tproch w ]
puts $of $jobid
close $of
