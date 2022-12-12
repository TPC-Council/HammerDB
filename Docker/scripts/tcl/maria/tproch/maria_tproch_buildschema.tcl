#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-H

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

diset tpch maria_scale_fact 1
diset tpch maria_num_tpch_threads [ numberOfCPUs ]
diset tpch maria_tpch_user root
diset tpch maria_tpch_pass maria
diset tpch maria_tpch_dbase tpch
diset tpch maria_tpch_storage_engine innodb
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
