#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db vsql
dbset bm TPC-H

diset connection vsql_host localhost
diset connection vsql_port 3306
diset connection vsql_socket /tmp/villagesql.sock

diset tpch vsql_scale_fact 10
diset tpch vsql_num_tpch_threads [ numberOfCPUs ]
diset tpch vsql_tpch_user root
diset tpch vsql_tpch_pass mysql
diset tpch vsql_tpch_dbase tpch
diset tpch vsql_tpch_storage_engine innodb
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
