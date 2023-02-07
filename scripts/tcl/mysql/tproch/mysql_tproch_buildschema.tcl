#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db mysql
dbset bm TPC-H

diset connection mysql_host localhost
diset connection mysql_port 3306
diset connection mysql_socket /tmp/mysql.sock

diset tpch mysql_scale_fact 1
diset tpch mysql_num_tpch_threads [ numberOfCPUs ]
diset tpch mysql_tpch_user root
diset tpch mysql_tpch_pass mysql
diset tpch mysql_tpch_dbase tpch
diset tpch mysql_tpch_storage_engine innodb
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
