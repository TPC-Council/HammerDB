#!/bin/tclsh

puts "SETTING CONFIGURATION"
dbset db mysql
dbset bm TPC-H

diset connection mysql_host 127.0.0.1
diset connection mysql_port 2881
diset connection mysql_socket /tmp/mysql.sock

diset tpch mysql_scale_fact 1
diset tpch mysql_num_tpch_threads [ numberOfCPUs ]
diset tpch mysql_tpch_user root
diset tpch mysql_tpch_pass 123
diset tpch mysql_tpch_dbase tpch
diset tpch mysql_tpch_obcompat true
diset tpch ob_partition_num 1
diset tpch ob_tenant_name hmdb
diset tpch mysql_tpch_storage_engine innodb
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
