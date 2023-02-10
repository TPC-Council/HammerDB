#!/bin/tclsh
# maintainer: Pooja Jain

puts "SETTING CONFIGURATION"
dbset db mssqls
dbset bm TPC-C

diset connection mssqls_tcp false
diset connection mssqls_port 1433
diset connection mssqls_azure false
diset connection mssqls_encrypt_connection true
diset connection mssqls_trust_server_cert true
diset connection mssqls_authentication windows
diset connection mssqls_server {(local)}
diset connection mssqls_linux_server {(localhost)}
diset connection mssqls_uid sa
diset connection mssqls_pass admin
diset connection mssqls_linux_authent sql
diset connection mssqls_linux_odbc {ODBC Driver 18 for SQL Server}

set vu [ numberOfCPUs ]
set warehouse [ expr {$vu * 5} ]
diset tpcc mssqls_count_ware $warehouse
diset tpcc mssqls_num_vu $vu
diset tpcc mssqls_dbase tpcc

puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"


