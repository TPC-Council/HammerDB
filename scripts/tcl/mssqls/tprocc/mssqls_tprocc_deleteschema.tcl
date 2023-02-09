#!/bin/tclsh
# maintainer: Pooja Jain

dbset db mssqls
dbset bm TPC-C

dbset db mssqls
dbset bm TPC-C

diset connection mssqls_linux_server {localhost}
diset connection mssqls_uid sa
diset connection mssqls_pass admin
diset connection mssqls_linux_authent sql
diset connection mssqls_linux_odbc {ODBC Driver 18 for SQL Server}
diset connection mssqls_encrypt_connection true
diset connection mssqls_trust_server_cert true
diset connection mssqls_tcp true

diset tpcc mssqls_dbase tpcc

puts "DROP SCHEMA STARTED"
deleteschema
puts "DROP SCHEMA COMPLETED"
