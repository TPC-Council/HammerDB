#!/bin/tclsh
# maintainer: Pooja Jain

dbset db mssqls
dbset bm TPC-C

dbset db mssqls
dbset bm TPC-C

diset connection mssqls_server (local)
diset connection mssqls_authentication windows
diset connection mssqls_odbc_driver "ODBC Driver 18 for SQL Server"
diset connection mssqls_encrypt_connection true
diset connection mssqls_trust_server_cert true

diset tpcc mssqls_dbase tpcc

puts "DROP SCHEMA STARTED"
deleteschema
puts "DROP SCHEMA COMPLETED"
