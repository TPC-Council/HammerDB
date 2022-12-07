#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-C

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

diset tpcc maria_user root
diset tpcc maria_pass maria
diset tpcc maria_dbase tpcc
diset tpcc maria_driver timed
diset tpcc maria_rampup 0
diset tpcc maria_duration 1
diset tpcc maria_allwarehouse true
diset tpcc maria_timeprofile true


jobs format JSON
loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
tcstart
tcstatus
set jobid [ vurun ]
vudestroy
tcstop
puts "TEST COMPLETE"
set of [ open maria_tprocc.out w ]
puts $of $jobid
close $of

