#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-H

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

diset tpch maria_scale_fact 1
diset tpch maria_tpch_user root
diset tpch maria_tpch_pass maria
diset tpch maria_tpch_dbase tpch
diset tpch maria_tpch_storage_engine innodb

loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
set jobid [ vurun ]
vudestroy
puts "TEST COMPLETE"
set of [ open $tmpdir/maria_tproch w ]
puts $of $jobid
close $of
