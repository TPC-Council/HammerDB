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
puts " CHECK SCHEMA STARTED"
checkschema
puts "CHECK SCHEMA COMPLETED"
