#!/bin/tclsh
# maintainer: Pooja Jain

set tmpdir $::env(TMP)
puts "SETTING CONFIGURATION"
dbset db mssqls
dbset bm TPC-H

diset connection mssqls_tcp false
diset connection mssqls_port 1433
diset connection mssqls_azure false
diset connection mssqls_encrypt_connection true
diset connection mssqls_trust_server_cert true
diset connection mssqls_authentication windows
diset connection mssqls_server {(local)}
diset connection mssqls_linux_server {localhost}
diset connection mssqls_uid sa
diset connection mssqls_pass admin
diset connection mssqls_linux_authent sql
diset connection mssqls_linux_odbc {ODBC Driver 18 for SQL Server}

diset tpch mssqls_scale_fact 1
diset tpch mssqls_maxdop 2
diset tpch mssqls_tpch_dbase tpch
diset tpch mssqls_total_querysets 1

loadscript
puts "TEST STARTED"
vuset vu 1
vucreate
set jobid [ vurun ]
vudestroy
puts "TEST COMPLETE"
set of [ open $tmpdir/mssqls_tproch w ]
puts $of $jobid
close $of

