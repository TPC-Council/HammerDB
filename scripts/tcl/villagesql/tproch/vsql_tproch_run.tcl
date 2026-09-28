#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db vsql
dbset bm TPC-H

diset connection vsql_host localhost
diset connection vsql_port 3306
diset connection vsql_socket /tmp/villagesql.sock

diset tpch vsql_scale_fact 10
diset tpch vsql_tpch_user root
diset tpch vsql_tpch_pass mysql
diset tpch vsql_tpch_dbase tpch
diset tpch vsql_tpch_storage_engine innodb

loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
set jobid [ vurun ]
vudestroy
puts "TEST COMPLETE"
set of [ open $tmpdir/vsql_tproch w ]
puts $of $jobid
close $of
